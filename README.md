# I Am Chad: Fitness RPG

A cross-platform mobile fitness RPG that turns real-world exercise into fantasy adventures. Complete workouts, develop your character, battle enemies, and embark on endless quests while building healthy fitness habits. Every hero starts somewhere!

> **Status:** early prototype (pre-alpha). The core loop is playable end to end: onboarding, workout logging, derived rewards, a turn-based expedition, and a local save. Art is placeholder. "I Am Chad" is a working title pending trademark clearance.

## The idea

You log real workouts at your own level. The game turns them into XP and **adventure energy** with transparent, capped rules, and you spend that energy on short turn-based expeditions run by Chad, a theatrical and slightly unreliable guildmaster.

Design pillars (full detail in the [Game Design Document](docs/I_Am_Chad_Fitness_RPG_GDD.pdf)):

- **Fitness first.** A useful workout log and history, even if you ignore the RPG.
- **Beginner friendly.** Easier versions of an exercise earn exactly the same as harder ones.
- **Progress without punishment.** No streaks. Rest days are valid. Missed days cost nothing.
- **Adventure with agency.** You are the hero, and Chad is the mentor.
- **Trustworthy.** Transparent rewards, offline-first, data stays on your device, no pay-to-win.

## What works today

| Area | Status |
| --- | --- |
| Onboarding and character creation | Done (name, look, experience level, preferences) |
| Workout logging (bodyweight, cardio, resistance, mobility) | Done, with edit, delete, timer and unit settings |
| Reward rules (XP and energy, daily cap, diminishing returns) | Done, versioned, explained to the player after each log |
| History and 7-day effort chart | Done |
| Quests (daily suggestions, flexible weekly goal) | Done |
| Turn-based combat, seeded expeditions, loot | Done (Flutter widgets, placeholder visuals) |
| Equipment and character screen | Done |
| Settings, local JSON export, delete all data | Done |
| Flame-based combat scenes, real art and audio | Not started |
| Health integrations, cloud sync, social features | Out of scope for the MVP |

See the [roadmap](docs/ROADMAP.md) for what comes next.

## Tech stack

Flutter and Dart, Riverpod for state, Drift (SQLite) for offline-first persistence. Game rules are pure Dart with no Flutter imports, so they are unit-testable and deterministic. Flame is planned for combat scenes but is not a dependency yet.

## Getting started

Prerequisites: [Flutter](https://docs.flutter.dev/get-started/install) 3.44 or newer (Dart 3.12+), plus the Android SDK or Xcode if you want to run on a device or emulator.

```bash
flutter pub get
```

```bash
dart run build_runner build
```

```bash
flutter run
```

The second command generates the Drift database code (`lib/data/database.g.dart`), which is not committed. Run it after a fresh clone and whenever you change `lib/data/database.dart`.

Run the checks:

```bash
flutter analyze
```

```bash
flutter test
```

More detail is in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Project layout

```
lib/
  domain/     Pure Dart game rules: activities, rewards, combat, expeditions, quests, dialogue
  data/       Drift database and the repository (single access point for saved data)
  app/        App shell, Riverpod providers, theme, shared widgets
  features/   One folder per screen: onboarding, guild, workout, history, adventure, character, settings
test/         Unit tests (domain, data) and widget flow tests
docs/         Design and engineering documentation
```

## Documentation

| Document | Contents |
| --- | --- |
| [Game Design Document](docs/I_Am_Chad_Fitness_RPG_GDD.pdf) ([.docx](docs/I_Am_Chad_Fitness_RPG_GDD.docx)) | The original concept-level design |
| [Architecture](docs/ARCHITECTURE.md) | Layers, data flow, key design rules |
| [Reward rules](docs/REWARD_RULES.md) | Exactly how workouts become XP and energy |
| [Combat and expeditions](docs/COMBAT_AND_EXPEDITIONS.md) | Battle mechanics, stats, expedition structure, balance |
| [Data model](docs/DATA_MODEL.md) | Tables, derived data, migrations |
| [Development guide](docs/DEVELOPMENT.md) | Setup, code generation, testing, conventions |
| [Content guidelines](docs/CONTENT_GUIDELINES.md) | Tone, safety and accessibility rules for writing and design |
| [Roadmap](docs/ROADMAP.md) | Milestone status against the GDD plan |
| [Decision log](docs/DECISIONS.md) | Why things are the way they are, and open questions |

## Safety

This is a game, not medical advice. It cannot verify the workouts you log. Move at your own level, stop if anything hurts, and talk to a qualified professional if you are unsure whether an activity is right for you.
