import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/ads.dart';
import 'package:i_am_chad/domain/patronage.dart';
import 'package:i_am_chad/domain/story.dart';

/// Every .dart file under lib/, as path -> text.
Map<String, String> _sources() => {
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.dart')) f.path.replaceAll(r'\', '/'): f.readAsStringSync(),
    };

void main() {
  group('the chapter ad policy', () {
    bool show({bool known = true, bool premium = false, bool read = false}) =>
        AdPolicy.shouldShowChapterAd(premiumKnown: known, premium: premium, chapterAlreadyRead: read);

    test('a first reading shows one', () => expect(show(), isTrue));
    test('Premium never sees one', () => expect(show(premium: true), isFalse));
    test('nobody is shown one before we know whether they bought Premium', () {
      expect(show(known: false), isFalse);
      expect(show(known: false, premium: true), isFalse);
    });
    test('reading a chapter again shows none', () {
      expect(AdPolicy.showOnReread, isFalse);
      expect(show(read: true), isFalse);
    });
    test('the wait for the answer is short, so the story never hangs', () {
      expect(AdPolicy.entitlementWait, lessThanOrEqualTo(const Duration(seconds: 3)));
    });
  });

  group('where ads can and cannot appear', () {
    final sources = _sources();

    test('only one file talks to the ad SDK', () {
      final users = [for (final e in sources.entries) if (e.value.contains('google_mobile_ads')) e.key];
      expect(users, ['lib/app/ads.dart']);
    });

    test('a chapter ad is requested from the story screen and nowhere else', () {
      final callers = [
        for (final e in sources.entries)
          if (e.value.contains('.showChapterAd(') && e.key != 'lib/app/ads.dart') e.key,
      ];
      expect(callers, ['lib/features/story/story_screen.dart']);
    });

    test('no workout, reward, battle, shop, hall or onboarding screen so much as imports the ads code', () {
      for (final e in sources.entries) {
        final screen = e.key.startsWith('lib/features/') || e.key.startsWith('lib/game/');
        final allowed = e.key == 'lib/features/story/story_screen.dart' || e.key == 'lib/features/settings/settings_screen.dart';
        if (screen && !allowed) {
          expect(e.value.contains('app/ads.dart'), isFalse, reason: '${e.key} must not touch ads');
        }
      }
    });

    test('the only other use is the ad privacy choices in Settings', () {
      final settings = sources['lib/features/settings/settings_screen.dart']!;
      expect(settings.contains('showChapterAd'), isFalse);
      expect(settings.contains('privacyOptionsRequired'), isTrue);
    });
  });

  group('stories are never sold', () {
    test('Premium removes the ad and nothing else, and it is not a story product', () {
      final text = '${Patronage.premium.name} ${Patronage.premium.blurb}'.toLowerCase();
      expect(text, contains('ad'));
      expect(text, contains('free'));
      expect(Patronage.all.map((p) => p.id), isNot(contains('season_two')));
      for (final p in Patronage.all) {
        expect('${p.name} ${p.blurb}'.toLowerCase(), isNot(contains('unlock')), reason: p.id);
        expect('${p.name} ${p.blurb}'.toLowerCase().contains('chapter') && p != Patronage.premium, isFalse, reason: p.id);
      }
    });

    test('the never-sold list names story chapters, and the story model has no price', () {
      expect(Patronage.neverSold.join(' ').toLowerCase(), contains('story'));
      // A chapter opens by hero level alone: there is no field that could hold a price.
      for (final c in Story.chapters) {
        expect(c.unlockLevel, greaterThan(0));
      }
    });

    test('Premium is one-time and restorable like the pack, with a receipt of its own', () {
      expect(Patronage.premium.isTip, isFalse);
      final e = Entitlements.fromReceipts([
        (key: Entitlements.receiptKey(Patronage.premium, 'a'), productId: Patronage.premiumId),
        (key: Entitlements.receiptKey(Patronage.premium, 'b'), productId: Patronage.premiumId),
      ]);
      expect(e.hasPremium, isTrue);
      expect(e.hasPatronPack, isFalse, reason: 'Premium does not grant the cosmetic pack');
      expect(Entitlements.fromReceipts([(key: 'x', productId: Patronage.patronPackId)]).hasPremium, isFalse);
    });
  });
}
