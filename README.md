# I Am Chad: Fitness RPG

A cross-platform mobile fitness RPG that turns real-world exercise into fantasy adventures. Complete workouts, develop your character, battle enemies, and embark on endless quests while building healthy fitness habits. Every hero starts somewhere!

> **Status:** early prototype (pre-alpha). The core loop is playable end to end and has been played through on an Android emulator, and it looks and feels like a game: you walk around an animated guild hall, battles play out as animated scenes with effects and sound, and loot comes out of a chest. All art is drawn in code and all sound is synthesized, so nothing is borrowed. "I Am Chad" is a working title pending trademark clearance.

## The idea

You log real workouts at your own level. The game turns them into XP and **adventure energy** with transparent, capped rules, and you spend that energy on short turn-based expeditions run by Chad, a theatrical and slightly unreliable guildmaster. Exercise in real life is the only thing that powers the adventure; the battles themselves are play.

Design pillars (full detail in the [Game Design Document](docs/I_Am_Chad_Fitness_RPG_GDD.pdf)):

- **Fitness first.** A useful workout log and history, even if you ignore the RPG.
- **Beginner friendly.** Easier versions of an exercise earn exactly the same as harder ones.
- **Progress without punishment.** Streaks are gentle: rest days are built in, nothing is ever taken away, and a missed stretch just starts a fresh run. Missed days cost nothing.
- **Adventure with agency.** You are the hero, and Chad is the mentor.
- **Trustworthy.** Transparent rewards, offline-first, data stays on your device, no pay-to-win.

## What works today

| Area | Status |
| --- | --- |
| Guild hall (Flame scene) | Done. Tap the quest board, bookshelf, gate, training dummy or armour stand; the hero walks over and the screen opens. Day and night lighting, and Chad reacts to your day |
| Onboarding and character creation | Done (name, hair style, outfit colour, skin tone, experience level, preferences) |
| Workout logging (bodyweight, cardio, resistance, mobility) | Done, with edit, delete, timer and unit settings |
| Exercise catalog | Done. **79 exercises** in 6 categories (Bodyweight, Core, Cardio, Resistance, Mobility & Recovery, Sports & Play), searchable and filterable, with an "At Home Only" switch. See the [exercise catalog](docs/EXERCISE_CATALOG.md) |
| Exercise demonstrations | Done. Every exercise has a looping animated figure with step-by-step cues, props (bars, benches, machines, bikes, water) and easier variants (wall, incline and knee push-ups, chair squats, small crunches, and more) |
| Camera rep counting (push-ups and squats) | First version built and run on an Android emulator, **not yet tried on a real person**. Needs a phone stand; counts reps on-device with generous leeway for beginners, never saves video, and is optional. See [camera notes](docs/ROADMAP.md#camera-rep-checking) |
| Guild Shop | Done. Spend coins on gear and healing potions (a pouch of up to 5, with up to 3 taken on each expedition and unused ones returned) |
| Back-dating | Done. Past workouts can be logged for the journal but earn no rewards, streaks or quest credit |
| Streaks | Done. Days active in a row, with rest days built in. Milestone rewards of coins and XP from 3 days up to a year, shown on the hall HUD and the quest board. Never a countdown, never lost |
| Honesty check on implausible entries | Done. A friendly warning, never a lock |
| Expedition resume | Done. Leave mid-run and pick it up later |
| Reward rules (XP and energy, daily cap, diminishing returns) | Done, versioned, explained to the player after each log |
| History and 7-day effort chart | Done |
| Quests (daily suggestions, flexible weekly goal) | Done |
| Turn-based combat, seeded expeditions, loot | Done, as animated Flame battle scenes: lunges, slashes, hit flashes, screen shake, damage numbers, enemy heavy-blow telegraphs, a campfire event and a chest-opening finale |
| Juice | XP, energy and coin popups and a level-up celebration when you return to the hall; haptics; eleven synthesized sound effects |
| Equipment and character screen | Done. Equipped gear is drawn on your hero everywhere |
| Settings, local JSON export, delete all data | Done |
| Final hand-made art, music, more enemies and biomes | Not started (all current art is procedural) |
| Health integrations, cloud sync, social features | Out of scope for the MVP |

See the [roadmap](docs/ROADMAP.md) for what comes next.

## Tech stack

Flutter and Dart, Riverpod for state, Drift (SQLite) for offline-first persistence, and [Flame](https://flame-engine.org/) for the game scenes. Game rules are pure Dart with no Flutter imports, so they are unit-testable and deterministic; scenes only draw and animate what the rules decided.

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
  game/       Flame scenes (guild hall, battle) and all procedural character art
  app/        App shell, Riverpod providers, theme, shared widgets, sound and haptics
  features/   One folder per screen: onboarding, home (the hall), workout, history, adventure, character, settings
assets/audio/ Synthesized sound effects (generated by tool/gen_sfx.mjs)
test/         Unit tests (domain, data, art) and widget flow tests
docs/         Design and engineering documentation
```

## Documentation

| Document | Contents |
| --- | --- |
| [Game Design Document](docs/I_Am_Chad_Fitness_RPG_GDD.pdf) ([.docx](docs/I_Am_Chad_Fitness_RPG_GDD.docx)) | The original concept-level design |
| [Architecture](docs/ARCHITECTURE.md) | Layers, data flow, key design rules |
| [Reward rules](docs/REWARD_RULES.md) | Exactly how workouts become XP and energy |
| [Combat and expeditions](docs/COMBAT_AND_EXPEDITIONS.md) | Battle mechanics, stats, expedition structure, balance |
| [Game scenes](docs/GAME_SCENES.md) | The guild hall and battle scenes, art, sound, previews |
| [Data model](docs/DATA_MODEL.md) | Tables, derived data, migrations |
| [Development guide](docs/DEVELOPMENT.md) | Setup, code generation, testing, conventions |
| [Content guidelines](docs/CONTENT_GUIDELINES.md) | Tone, safety and accessibility rules for writing and design |
| [Roadmap](docs/ROADMAP.md) | Milestone status against the GDD plan |
| [Decision log](docs/DECISIONS.md) | Why things are the way they are, and open questions |

## Safety

This is a game, not medical advice. It cannot verify the workouts you log. Move at your own level, stop if anything hurts, and talk to a qualified professional if you are unsure whether an activity is right for you.
