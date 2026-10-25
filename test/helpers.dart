import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:i_am_chad/app/ads.dart';
import 'package:i_am_chad/app/app.dart';
import 'package:i_am_chad/app/feedback.dart';
import 'package:i_am_chad/app/content_packs.dart';
import 'package:i_am_chad/app/providers.dart';
import 'package:i_am_chad/app/reminders.dart';
import 'package:i_am_chad/app/store.dart';
import 'package:i_am_chad/data/database.dart';
import 'package:i_am_chad/domain/player_state.dart';
import '../tool/story_content/content.dart';

/// The packs as they would be published, by season.
Map<int, String> publishedPacks() => {
      for (final e in StoryContent.files().entries)
        if (e.key != 'manifest.json') int.parse(RegExp(r'\d+').firstMatch(e.key)!.group(0)!): e.value,
    };

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
  bool storyOffers = false,
  StoreGateway? store,

  /// The pretend ad system. By default a test never reaches Google, and there is
  /// always an ad available to "show".
  AdGateway? ads,

  /// Leave the sound, vibration and settings providers to [overrides], so a test
  /// can run the real feedback pipeline instead of the silent one.
  bool liveFeedback = false,

  /// Show the title screen a returning player sees on launch. Off by default so
  /// tests go straight to the hall.
  bool showTitle = false,

  /// Turn the in-app Reduce Motion setting on (the default, so scenes finish each
  /// animation in one frame) or off, to run the real animations.
  bool reducedMotion = true,

  /// The pretend notification service. By default a test runs on a platform that
  /// cannot send reminders, so Settings does not offer them.
  ReminderGateway? reminders,

  /// Where the later story seasons are downloaded from, and where they are kept.
  /// By default every season is already on the phone, so a test can read any
  /// chapter; pass an empty [packStore] to start with none downloaded.
  PackSource? packSource,
  PackStore? packStore,
}) async {
  final clock = now ?? DateTime(2026, 10, 22, 10);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      clockProvider.overrideWithValue(() => clock),
      if (!liveFeedback) feedbackProvider.overrideWithValue(GameFeedback.silent()),
      if (!liveFeedback) prefsProvider.overrideWithValue(AppPrefs(reducedMotion: reducedMotion)),
      showTitleOnLaunchProvider.overrideWithValue(showTitle),
      // The hall would otherwise offer story chapters over every test.
      storyAutoOfferProvider.overrideWithValue(storyOffers),
      // Never reach a real store from a test.
      storeGatewayProvider.overrideWithValue(store ?? TestStoreGateway()),
      adGatewayProvider.overrideWithValue(ads ?? TestAdGateway()),
      if (reminders != null) reminderGatewayProvider.overrideWithValue(reminders),
      packSourceProvider.overrideWithValue(packSource ?? TestPackSource(packs: publishedPacks())),
      packStoreProvider.overrideWithValue(packStore ?? MemoryPackStore(publishedPacks())),
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
  // The search box also contains this text, so only look at card titles. With a journal, the
  // "Do It Again" shelf above the cards may name it too, so take the last (the card).
  final card = find.byWidgetPredicate((w) => w is Text && w.data == name).last;
  await tester.ensureVisible(card);
  await settle(tester, frames: 3);
  await tester.tap(card);
  await settle(tester);
}
