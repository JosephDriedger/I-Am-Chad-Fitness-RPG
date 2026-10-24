import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/game_ui.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/data/repository.dart';
import 'package:i_am_chad/domain/hero.dart';

import 'helpers.dart';

/// Every dialog that asks the player something, opened at the awkward sizes. Each
/// dialog scrolls, so what matters is that nothing throws and that every button in
/// it can be brought into view and pressed.
class _Setup {
  const _Setup(this.name, this.width, this.height, this.textScale);

  final String name;
  final double width;
  final double height;
  final double textScale;
}

const _setups = [
  _Setup('smallest phone, largest text', 320, 568, 2.0),
  _Setup('small phone, big text', 360, 640, 1.5),
  _Setup('phone on its side, big text', 640, 360, 1.5),
];

void _noProblem(WidgetTester tester, String step) {
  final problem = tester.takeException();
  if (problem != null) fail('$step threw: ${problem is FlutterError ? problem.toStringDeep() : problem}');
}

/// Brings [target] fully on screen, in a list or a dialog, however long it is.
Future<void> _reveal(WidgetTester tester, Finder target, {bool first = false}) async {
  // Scroll until something matching can actually be tapped, down first and then back
  // up. (scrollUntilVisible wants exactly one match, and a widget that is built but
  // scrolled out of view does not count.)
  for (final dy in const [-250.0, 250.0]) {
    for (var i = 0; i < 60 && target.hitTestable().evaluate().isEmpty; i++) {
      await tester.drag(find.byType(Scrollable).first, Offset(0, dy));
      // Let the list finish coasting before looking again, or it drifts off afterwards.
      await tester.pump(const Duration(seconds: 1));
    }
  }
  final f = first ? target.first : target;
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.ensureVisible(f);
  await tester.pump();
}

/// Opens a dialog with [open], checks each label in [buttons] is on screen and can be
/// pressed, then closes it by pressing [close].
Future<void> _checkDialog(
  WidgetTester tester, {
  required String name,
  required Future<void> Function() open,
  required List<String> buttons,
  required String close,
}) async {
  await open();
  await settle(tester, frames: 20);
  _noProblem(tester, 'opening $name');
  for (final b in buttons) {
    final f = find.text(b).last;
    expect(f, findsOneWidget, reason: '"$b" in $name');
    await tester.ensureVisible(f);
    await tester.pump();
    await tester.ensureVisible(f);
    _noProblem(tester, 'showing "$b" in $name');
    // It really is on screen, not just built.
    final r = tester.getRect(f);
    final size = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(r.top, greaterThanOrEqualTo(0), reason: '"$b" in $name is above the screen');
    expect(r.bottom, lessThanOrEqualTo(size.height + 1), reason: '"$b" in $name is below the screen');
  }
  await tester.tap(find.text(close).last);
  await settle(tester, frames: 20);
  _noProblem(tester, 'closing $name');
}

void main() {
  for (final s in _setups) {
    testWidgets('every dialog fits: ${s.name}', (tester) async {
      tester.view.physicalSize = Size(s.width * 2, s.height * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = s.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.runAsync(() async {
        final repo = GameRepository(db);
        await repo.createHero(const HeroProfile(
          name: 'Ada the Very Long Named',
          appearanceStyle: 0,
          appearanceColor: 0,
          experience: ExperienceLevel.starting,
          preferredCategories: {},
          hasDumbbells: false,
        ));
        await repo.addCoins(5000);
      });
      // The hall offers an unread chapter at launch, which is the first dialog.
      await bootApp(tester, db, storyOffers: true);
      await settle(tester, frames: 20);
      _noProblem(tester, 'launching');
      expect(find.text('A New Chapter!'), findsOneWidget);
      await _checkDialog(tester, name: 'the story offer', open: () async {}, buttons: ['Read Now', 'Later'], close: 'Later');

      // The Guild Shop: buying an item.
      await tester.tap(find.text('Adventure'));
      await settle(tester, frames: 30);
      await _reveal(tester, find.text('Visit the Shop'));
      await tester.tap(find.text('Visit the Shop'));
      await settle(tester, frames: 30);
      // A piece of gear asks first; the 25-coin potion is bought straight away.
      final buy = find.byWidgetPredicate((w) => w is GameButton && w.label.endsWith(' Coins') && w.label != '25 Coins' && w.onPressed != null);
      await _reveal(tester, buy, first: true);
      await _checkDialog(
        tester,
        name: 'the shop purchase',
        open: () async => tester.tap(buy.first),
        buttons: ['Buy', 'Not Now'],
        close: 'Not Now',
      );
      await tester.pageBack();
      await settle(tester, frames: 15);
      await tester.pageBack();
      await settle(tester, frames: 15);

      // Settings: deleting everything, and the Patron's Hall purchases.
      await tester.tap(find.byTooltip('Settings'));
      await settle(tester, frames: 30);
      await _reveal(tester, find.text('Delete All My Data'));
      await _checkDialog(
        tester,
        name: 'delete everything',
        open: () async => tester.tap(find.text('Delete All My Data')),
        buttons: ['Cancel', 'Delete Everything'],
        close: 'Cancel',
      );
      await _reveal(tester, find.text("Open the Patron's Hall"));
      await tester.tap(find.text("Open the Patron's Hall"));
      await settle(tester, frames: 30);
      _noProblem(tester, "the Patron's Hall");

      // Each thing that can be bought asks first: three tips, the pack and Premium.
      for (final label in [r'$1.99', r'$4.99', r'$9.99', r'Get It · $3.99', r'Remove Ads · $2.99']) {
        final button = find.widgetWithText(GameButton, label);
        await _reveal(tester, button);
        await _checkDialog(
          tester,
          name: "the $label purchase in the Patron's Hall",
          open: () async => tester.tap(button),
          buttons: ['Not Now'],
          close: 'Not Now',
        );
      }
      // Back to the hall, then Customise: a locked look and an earned one explain themselves.
      await tester.pageBack();
      await settle(tester, frames: 15);
      await tester.pageBack();
      await settle(tester, frames: 15);
      await tester.tap(find.text('Hero'));
      await settle(tester, frames: 30);
      await _reveal(tester, find.text('Customise'));
      await tester.tap(find.text('Customise'));
      await settle(tester, frames: 30);
      await _reveal(tester, find.text('Crimson Mantle'));
      await _checkDialog(
        tester,
        name: 'a patron look in the wardrobe',
        open: () async => tester.tap(find.text('Crimson Mantle')),
        buttons: ['Not Now'],
        close: 'Not Now',
      );
      await _reveal(tester, find.text('Sunrise'));
      await _checkDialog(
        tester,
        name: 'an earned look in the wardrobe',
        open: () async => tester.tap(find.text('Sunrise')),
        buttons: ['Got It'],
        close: 'Got It',
      );
      await shutDown(tester, db);
    });
  }
}
