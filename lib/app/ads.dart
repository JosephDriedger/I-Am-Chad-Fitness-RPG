/// The only advertising in the game: one full-screen ad at the start of each
/// story chapter, which Premium removes for good. Nothing else ever shows an
/// ad: not workouts, rewards, battles, the shop or the hall. See
/// docs/MONETIZATION.md for the promises and the set-up.
///
/// Everything that talks to Google is behind [AdGateway], like the store is
/// behind `StoreGateway`, so tests and previews use a pretend one and the story
/// never waits on, or breaks because of, an ad.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// When a chapter-start ad may be shown. Pure, so the rules are tested.
class AdPolicy {
  const AdPolicy._();

  /// Reading a chapter again never shows an ad. Flip this to show one on every
  /// opening.
  static const showOnReread = false;

  /// How long the story waits to learn whether the player has Premium. If it
  /// has not been learned by then, no ad is shown: someone who paid is never
  /// shown one by mistake.
  static const entitlementWait = Duration(seconds: 2);

  static bool shouldShowChapterAd({
    required bool premiumKnown,
    required bool premium,
    required bool chapterAlreadyRead,
  }) {
    if (!premiumKnown || premium) return false;
    if (chapterAlreadyRead && !showOnReread) return false;
    return true;
  }
}

abstract class AdGateway {
  /// Asks for the player's ad choices where the law requires it, then shows one
  /// full-screen ad. Completes when the ad is closed, or straight away with
  /// false if there is nothing to show (offline, no consent, no ad). Never
  /// throws, and never waits longer than a few seconds for an ad to load.
  Future<bool> showChapterAd();

  /// Whether the player has an ad-privacy choice to revisit (required in some
  /// regions).
  Future<bool> privacyOptionsRequired();

  /// Reopens the ad-privacy choices.
  Future<void> showPrivacyOptions();
}

/// The real thing: Google AdMob on Android and iOS.
///
/// The ids below are Google's public **test** ids, which only ever show test
/// ads. They must be replaced with the real ones from an AdMob account before
/// release (and the matching app ids in AndroidManifest.xml and Info.plist).
/// Ads are requested non-personalized and limited to family-friendly (G) content.
class AdMobGateway implements AdGateway {
  static const androidChapterUnit = 'ca-app-pub-3940256099942544/1033173712';
  static const iosChapterUnit = 'ca-app-pub-3940256099942544/4411468910';

  static const loadWait = Duration(seconds: 6);
  static const consentWait = Duration(seconds: 90);

  bool _started = false;

  String get _unit => defaultTargetPlatform == TargetPlatform.iOS ? iosChapterUnit : androidChapterUnit;

  /// Gets the player's choices where required, and starts the ad system once
  /// they allow ads. False means no ad should be requested.
  Future<bool> _ready() async {
    try {
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {
            if (!done.isCompleted) done.complete();
          });
        },
        (_) {
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(consentWait);
      if (!await ConsentInformation.instance.canRequestAds()) return false;
      if (!_started) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(maxAdContentRating: MaxAdContentRating.g),
        );
        await MobileAds.instance.initialize();
        _started = true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> showChapterAd() async {
    try {
      if (!await _ready()) return false;
      final loaded = Completer<InterstitialAd?>();
      var abandoned = false;
      await InterstitialAd.load(
        adUnitId: _unit,
        request: const AdRequest(nonPersonalizedAds: true),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            // Too late: the story has moved on without it.
            if (abandoned) {
              ad.dispose();
            } else if (!loaded.isCompleted) {
              loaded.complete(ad);
            }
          },
          onAdFailedToLoad: (_) {
            if (!loaded.isCompleted) loaded.complete(null);
          },
        ),
      );
      final ad = await loaded.future.timeout(loadWait, onTimeout: () {
        abandoned = true;
        return null;
      });
      if (ad == null) return false;

      final closed = Completer<bool>();
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          if (!closed.isCompleted) closed.complete(true);
        },
        onAdFailedToShowFullScreenContent: (ad, _) {
          ad.dispose();
          if (!closed.isCompleted) closed.complete(false);
        },
      );
      await ad.show();
      return await closed.future;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {});
    } catch (_) {
      // Nothing to change if the form cannot open.
    }
  }
}

/// For platforms without ads (the browser preview, desktop): no ad ever.
class NoAdGateway implements AdGateway {
  const NoAdGateway();

  @override
  Future<bool> showChapterAd() async => false;

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}

/// A pretend ad system for tests: it counts what was asked and can be told to
/// have nothing to show.
class TestAdGateway implements AdGateway {
  TestAdGateway({this.available = true, this.privacyRequired = false, this.delay = Duration.zero});

  /// Whether there is an ad to show.
  bool available;
  bool privacyRequired;

  /// How long the pretend ad "plays".
  Duration delay;

  /// How many chapter ads were shown, and how many times privacy choices opened.
  int shown = 0;
  int privacyOpened = 0;

  @override
  Future<bool> showChapterAd() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (!available) return false;
    shown++;
    return true;
  }

  @override
  Future<bool> privacyOptionsRequired() async => privacyRequired;

  @override
  Future<void> showPrivacyOptions() async => privacyOpened++;
}

/// The ad system the app uses. Tests override it with a [TestAdGateway].
final adGatewayProvider = Provider<AdGateway>((ref) {
  final supported = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  return supported ? AdMobGateway() : const NoAdGateway();
});
