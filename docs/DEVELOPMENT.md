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

The files in `assets/audio` are synthesized, not recorded. Edit `tool/gen_sfx.mjs` and run `node tool/gen_sfx.mjs` to regenerate them. Each file name must match an `Sfx` value in `lib/game/core.dart` (a test checks this).

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
- **No shame, no streak pressure.** Read the [Content guidelines](CONTENT_GUIDELINES.md) before adding text or mechanics.
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

## Known environment notes

- Platforms enabled: Android and iOS (per the GDD), plus web for development previews only. Desktop is not set up, so `flutter run -d windows` will not work without adding that platform.
- The generated Android/iOS application id is the placeholder `com.iamchad.i_am_chad`. Change it before any store submission.
- On Windows without the Android toolchain, only analysis and tests can be run.

## Commits

Use short, imperative commit messages that describe the change ("Add reward explanation dialog"). Keep generated code (`*.g.dart`) out of commits. `pubspec.lock` is committed because this is an application.
