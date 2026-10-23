import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/app.dart';
import 'package:i_am_chad/app/feedback.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/domain/player_state.dart';

/// Drift streams and Flame scenes both advance on frames; pump a few.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Boots the real app on [db] with a fixed clock, silent feedback and reduced
/// motion (scenes complete each animation in a frame, so tests stay fast).
Future<void> bootApp(
  WidgetTester tester,
  AppDatabase db, {
  DateTime? now,
  List<Override> overrides = const [],
}) async {
  final clock = now ?? DateTime(2026, 10, 22, 10);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => clock),
      feedbackProvider.overrideWithValue(GameFeedback.silent()),
      prefsProvider.overrideWithValue(const AppPrefs(reducedMotion: true)),
      showTitleOnLaunchProvider.overrideWithValue(false),
      ...overrides,
    ],
    child: const IAmChadApp(),
  ));
  await settle(tester);
}

/// Ends a widget test cleanly: dispose the tree, let timers run out, close.
Future<void> shutDown(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
  await tester.runAsync(db.close);
}

/// A phone-sized, tall test surface.
void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 1900);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

/// Opens an exercise from the Train list the way a player does: search for it,
/// then tap the card. The list is long, so a card is not always on screen.
Future<void> openExercise(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField).first, name);
  await settle(tester);
  // The search box also contains this text, so only look at card titles.
  await tester.tap(find.byWidgetPredicate((w) => w is Text && w.data == name));
  await settle(tester);
}
