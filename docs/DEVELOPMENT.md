# Development guide

## Prerequisites

- Flutter 3.44 or newer (Dart 3.12+). Check with `flutter --version`.
- For running the app: the Android SDK with command-line tools and accepted licenses (for Android), or Xcode on macOS (for iOS). `flutter doctor` shows what is missing.
- Unit and widget tests do **not** need an emulator or SDK; they run on the host.

## First run

```bash
flutter pub get
```

```bash
dart run build_runner build
```

```bash
flutter run
```

`build_runner` generates `lib/data/database.g.dart` from the Drift tables. Generated files (`*.g.dart`) are git-ignored, so repeat this step after a fresh clone and whenever `lib/data/database.dart` changes. For a watch mode while editing tables:

```bash
dart run build_runner watch
```

## Previewing scenes in a browser

The game scenes can be viewed in Chrome without a phone or emulator. Web is a development convenience only; the shipped targets are Android and iOS.

```bash
flutter run -d chrome --dart-define=PREVIEW=hub
```

Modes: `cast` (every character), `hub`, `duel`, `expedition`, `boss`, `event`, `chest`. Preview modes seed a hero, skip animation and sound, and persist to the browser's own storage (via `web/sqlite3.wasm` and `web/drift_worker.js`). Without `PREVIEW` the app runs normally. See [Game scenes](GAME_SCENES.md).

If `web/drift_worker.js` is missing, rebuild it with `dart compile js -O4 web/drift_worker.dart -o web/drift_worker.js`.

## Sound effects

The files in `assets/audio` are synthesized, not recorded. Edit `tool/gen_sfx.mjs` and run `node tool/gen_sfx.mjs` to regenerate the effects; each file name must match an `Sfx` value in `lib/game/core.dart` (a test checks this). The two music loops come from `tool/gen_music.mjs` the same way (`node tool/gen_music.mjs`), and their file names are in `MusicTrack` in `lib/app/music.dart`. Both scripts are deterministic, so running them again rewrites identical files.

## Everyday commands

| Task | Command |
| --- | --- |
| Static analysis | `flutter analyze` |
| All tests | `flutter test` |
| One file | `flutter test test/domain/rewards_test.dart` |
| Format | `dart format lib test` |

Before committing, `flutter analyze` should report no issues and `flutter test` should pass.

## Project conventions

- **Domain stays pure.** No Flutter, Drift or `dart:io` imports under `lib/domain`. See [Architecture](ARCHITECTURE.md).
- **Persisted ids are forever.** Activity ids, item ids and enum names stored in the database must never be renamed or reused.
- **Rules live in the domain layer.** Widgets display results; they do not compute rewards, damage or quests.
- **Everything the game does should be explainable.** If a reward or outcome would surprise the player, show why.
- **No shame, no streak pressure** (streaks exist, but only in the forgiving form described in the guidelines). Read the [Content guidelines](CONTENT_GUIDELINES.md) before adding text or mechanics.
- **Determinism.** Use `GameRng` with explicit seeds for anything random in game logic. Do not use `Random()` in the domain layer.
- **Lints.** The project uses `flutter_lints`. Fix findings rather than silencing them.

## Writing tests

- Put pure rules tests under `test/domain` and use plain `test()`.
- Repository tests use an in-memory database:

  ```dart
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final repo = GameRepository(db);
  ```

- Widget tests override providers instead of mocking the repository:

  ```dart
  ProviderScope(overrides: [
    databaseProvider.overrideWithValue(db),
    clockProvider.overrideWithValue(() => DateTime(2026, 10, 22, 10)),
  ], child: const IAmChadApp())
  ```

- Use the helpers in `test/helpers.dart`: `bootApp` (fixed clock, silent feedback, reduced motion so scenes finish each animation in one frame), `settle`, `usePhone` and `shutDown`.
- Inside `testWidgets`, wrap direct database calls in `tester.runAsync(...)`. Awaiting them in the fake-async zone hangs the test. Calls triggered by the UI itself are fine.
- Drift streams use timers. End widget tests by pumping `SizedBox()` and advancing a second before closing the database, as the existing flow tests do.

## Adding things

| To add | Do this |
| --- | --- |
| An activity | Add an `ActivityType` to `ActivityCatalog` in `lib/domain/activity.dart` and to `all`. Add a reward test if it has a new unit of effort. |
| A quest | Add to the right list in `QuestBoard` in `lib/domain/quests.dart`. Tests check it references a real activity and that beginner quests stay gentle. |
| A Chad line | Add to `ChadDialogue` in `lib/domain/chad.dart`. A test checks for shaming vocabulary. |
| A setting | Add a column to `AppSettings`, a field on `AppPrefs`, map it in the repository, expose it in the Settings screen, bump the schema. |
| A screen | Create `lib/features/<name>/` and read state through providers. |

## Purchases and the test store

The Patron's Hall talks to the platform store through `StoreGateway` (`lib/app/store.dart`). Widget tests and the browser preview use `TestStoreGateway`, a pretend store with made-up prices, so no test or preview ever reaches a real store or spends real money. `bootApp` in `test/helpers.dart` installs one by default and accepts your own (`bootApp(tester, db, store: myGateway)`) to script a cancel, a failure, a pending purchase, an offline store, or a purchase delivered at launch (`store.deliver(...)`). The preview modes `wardrobe` (every cape and hair dye) and `patron` (a hall with the Patron Pack and several pennants earned) show the cosmetics.

Real checkout needs the application id replaced and the products created in both store consoles first; the steps are in [Monetization](MONETIZATION.md#setting-it-up-in-the-stores). Never hard-code a price in the app: prices come from the store. Product ids are persisted and never renamed.

## Known environment notes

- Platforms enabled: Android and iOS (per the GDD), plus web for development previews only. Desktop is not set up, so `flutter run -d windows` will not work without adding that platform.
- The generated Android/iOS application id is the placeholder `com.iamchad.i_am_chad`. Change it before any store submission.
- `android/gradle.properties` sets `kotlin.incremental=false`. When the project and the Flutter package cache are on different drives, plugin Kotlin compiles otherwise fail with "Could not close incremental caches".
- To run on an emulator: `flutter emulators --launch <id>`, then `flutter run -d <device>`. Analysis and tests need no emulator.
- **Camera counting** (`lib/features/workout/`) uses the `camera` and `google_mlkit_pose_detection` plugins. Tests never touch them: they override `poseCameraFactoryProvider` with a fake camera that emits synthetic poses. On an Android emulator the camera shows its virtual scene (no person), so you can check the permission prompt, preview, overlay and set-up screens but not real counting; grant the permission without the prompt with `adb shell pm grant com.iamchad.i_am_chad android.permission.CAMERA`. Real counting needs a physical phone and a person. ML Kit needs iOS 15.5 or later (the Xcode project is set to 15.5 but has not been built, since there is no Mac here), and the iOS camera description is in `ios/Runner/Info.plist`.
- **Enemies, camps and props** are checked by eye with `ENEMY_SHEET=<folder> flutter test test/tool/enemy_sheet_test.dart`, which draws every enemy in its region's scenery. To see the actual win rates behind a balance change, run a copy of `test/domain/balance_test.dart` that prints `rates` (enemy attack is rounded to whole numbers, so a dial can jump a whole point and move a win rate by 15 points or more; use the HP dial for fine adjustment).
- **Exercise demos** are checked by eye with a contact sheet: `DEMO_SHEET=<folder> flutter test test/tool/demo_sheet_test.dart` (add `DEMO_IDS=lunge,burpee` for a few). Story scenes are checked the same way with `STORY_SHEET=<folder> flutter test test/tool/story_sheet_test.dart` (see [Story](STORY.md)). The exercise catalog document is generated with `CATALOG_DOC=docs/EXERCISE_CATALOG.md flutter test test/tool/catalog_doc_test.dart`. See [Exercise catalog](EXERCISE_CATALOG.md).
- Rep counting thresholds live in `lib/domain/rep_counter.dart` (`RepProfile.forActivity`), with the leniency chosen from the hero's experience level. They are the numbers to tune after real-world testing, and `test/domain/rep_counter_test.dart` shows what each level accepts.

## Commits

Use short, imperative commit messages that describe the change ("Add reward explanation dialog"). Keep generated code (`*.g.dart`) out of commits. `pubspec.lock` is committed because this is an application.

## Random-play tests

`test/domain/fuzz_test.dart` throws thousands of random days, streaks and battles at the rules and checks the promises they make (caps never exceeded, logging more never earns less, battles always end). `test/monkey_test.dart` taps, types, scrolls and goes back at random through the real app, twelve seeds of 160 steps each, and fails on any exception, printing the seed, the step and the last actions so the run can be replayed. When either finds a bug, fix it and keep a small test for that case beside it, as `test/double_tap_test.dart` and `test/save_failure_test.dart` do.

`test/layout_tour_test.dart` opens every main screen and dialog (hall menu, Train with the warm-up and an exercise's log screen with its honesty check and saved dialog, Quests, Adventure with the shop and a duel, Hero with Customise, Journal, Settings with the in-game guide, and the Patron's Hall) on a 320 x 568 phone at 2x text, a 360 x 640 phone at 1.5x, and a wide screen, and fails on any overflow. `test/monkey_test.dart` also runs on those small, large-text setups. It scrolls each list screen (Quests, Adventure, Hero, Journal, Train, the Shop, Settings, the guide, the Patron's Hall and the Chronicle) from top to bottom a screenful at a time, because lists build their panels lazily and a bug in the lower half of a screen only shows when it is scrolled to. They found and fixed overflows in the hero header, records, exercise filter row, battle action buttons, journal chart, shop rows, exercise demo card, reward badges, streak reward card, the week tokens on the quest board, the Journal's chart bars, personal bests and day headers, and the Chronicle's chapter cards.

Nearly every test runs with Reduce Motion on, so scenes finish each animation in one frame. `test/motion_on_test.dart` runs the real animations instead (`bootApp(..., reducedMotion: false)`): the animated logo and pulsing button, the hall and its walks to each destination, a practice duel and a full expedition, on a normal phone and the smallest one. `test/monkey_test.dart` also has a few random-play runs with motion on.

`test/onboarding_layout_test.dart` does the same for what every player sees first: the three onboarding steps, and the title screen a returning player sees on launch, each scrolled top to bottom on the smallest phone at the largest text, a small phone at big text and a phone on its side. It found the logo breaking "CHAD" over four lines, the title screen overflowing on a phone held sideways, and a crash on closing the title screen with Reduce Motion on.

`test/expedition_layout_test.dart` covers the expedition screens at the awkward sizes: a fork in the road, a camp with a long description, a battle with its four actions and the result panel. It found that the panel under the scene overflowed on a phone held sideways, so the screen now puts the scene and the panel side by side in landscape, caps the panel at about half the height when upright, and keeps it scrolled to its buttons so the way on is always in view.

`test/story_layout_test.dart` reads whole chapters (the one with the most choices in each season, and the one with the longest line) at the same awkward sizes, answering every choice and checking each option can be reached. It found the chapter title card overflowing at every small size, the question above the answers pushing past the panel at large text, and the "carry on" arrow taking a row of its own, so a phone held sideways now shows the picture and the text side by side.

`test/new_player_layout_test.dart` visits every main screen as a brand-new player sees it (no workouts, no energy, nothing earned), because the "nothing yet" pages never appear to the hero the main tour uses; it found the empty Journal overflowing on a short screen. `test/hall_layout_test.dart` checks the hall's menu: a bar along the bottom upright, and a rail down the right-hand side when the phone is held sideways, where the room has the whole height.

`test/dialogs_layout_test.dart` opens every dialog that asks the player something (the story offer, buying gear, a locked or earned look, delete everything, and each purchase in the Patron's Hall) at the awkward sizes and checks every button is on screen and can be pressed. It found the shop's "Your Coins" header overflowing at large text. (When scripting a list in a test, let each drag finish coasting before looking again, or the list drifts away from the widget you found.)

`test/accessibility_test.dart` runs Flutter's own accessibility checks (tap targets at least 48 x 48, every control named for a screen reader, text contrast) on each main screen. The layout tour also covers a phone on its side.

## Ads in development

Real ads need an AdMob account, so the app ships Google's public **test** ids (in `lib/app/ads.dart`, `AndroidManifest.xml` and `Info.plist`). A non-Premium player opening an unread chapter on Android or iOS then sees Google's labelled test ad; web and desktop show none. Tests never reach Google: `bootApp` swaps in `TestAdGateway`, and `test/ads_promise_test.dart` keeps ad code out of everywhere except the story screen. See [Monetization](MONETIZATION.md#setting-it-up-in-the-stores) before release.
