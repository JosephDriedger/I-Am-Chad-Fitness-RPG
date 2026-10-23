# Architecture

This document describes how the code is organised and the rules that keep it that way. For the product-level view see the [Game Design Document](I_Am_Chad_Fitness_RPG_GDD.pdf) (section 10).

## Layers

```
┌──────────────────────────────────────────────┐
│ features/   Screens (Flutter widgets)         │
│ game/       Flame scenes and procedural art   │
│ app/        App shell, providers, theme       │
├──────────────────────────────────────────────┤
│ data/       Drift database + GameRepository   │
├──────────────────────────────────────────────┤
│ domain/     Pure Dart rules and value types   │
└──────────────────────────────────────────────┘
        dependencies point downwards only
```

| Layer | Path | May import | Notes |
| --- | --- | --- | --- |
| Domain | `lib/domain` | Dart core only | No Flutter, no Drift. Everything here is deterministic and unit tested. |
| Data | `lib/data` | domain, Drift | The only place that touches SQLite. Maps rows to domain types. |
| App | `lib/app` | domain, data, Flutter, Riverpod | Providers combine repository streams into UI-ready state. `feedback.dart` wires sound and haptics to settings. `game_ui.dart` is the shared kit (panels, buttons, dialogs, route transitions) behind every non-scene screen, and `theme.dart` holds the single game theme. |
| Game | `lib/game` | domain, Flame | The guild hall and battle scenes plus all character art. Plain data in, callbacks out: scenes never touch providers or the database. See [Game scenes](GAME_SCENES.md). |
| Features | `lib/features` | everything above | One folder per screen. No SQL, no game maths. `HubScreen` and `ExpeditionScreen` host the Flame scenes. Camera counting is split in two: `domain/pose.dart` and `domain/rep_counter.dart` hold all the maths (pure, unit tested), while `features/workout/pose_camera.dart` is a thin interface over the camera and ML Kit (`ml_kit_pose_camera.dart`) that tests replace with a fake. |

The story follows the same split: the script, the unlock rules and the conditions on remembered choices are pure Dart in `domain/story.dart`; the backdrops and characters are painted in `game/art/story_art.dart`; and `features/story` holds the reading screen and the Chronicle.

If a rule decides how the game plays (rewards, damage, quests, level curves), it lives in `domain/`. If you find yourself writing it in a widget, move it.

## Source of truth

> Workout data is the source of truth. The RPG consumes derived, versioned rewards.

```
 Workouts table  ──derive──▶  RewardGrants (per day, stamped with rules version)
      ▲                               │
      │ edit / delete                 ▼
   player                    PlayerStatus  (XP, energy, level)
```

- Rewards are **derived** from workouts and never written back to them.
- Each local day has one grant row. It is recomputed only when that day's workouts change, so releasing new balance rules never silently rewrites days the player did not touch (see [Reward rules](REWARD_RULES.md)).
- Adventure XP, coins, spent energy and inventory are stored on the hero and inventory tables, because they come from play rather than from exercise.
- `PlayerStatus` combines both: `totalXp = sum(grants.xp) + hero.adventureXp`, and `energy = max(0, sum(grants.energy) - hero.energySpent)`.

## Data flow

1. A screen calls a `GameRepository` method (for example `addWorkout`).
2. The repository writes inside a transaction and recomputes the affected day's grant.
3. Drift's table streams emit; the `StreamProvider`s in `lib/app/providers.dart` update.
4. `playerProvider` recombines the hero, grants and items into a `PlayerStatus`.
5. Widgets watching those providers rebuild.

Screens never hold their own copy of saved data. The only local state is form input and the in-progress expedition.

## State management

Riverpod 3. All providers live in `lib/app/providers.dart`:

| Provider | Type | Purpose |
| --- | --- | --- |
| `databaseProvider` | `Provider<AppDatabase>` | Opens the SQLite file. Overridden with an in-memory DB in tests. |
| `repositoryProvider` | `Provider<GameRepository>` | The single data access point. |
| `clockProvider` | `Provider<DateTime Function()>` | Injectable "now" so date-dependent screens are testable. |
| `workoutsProvider`, `grantsProvider`, `heroProvider`, `itemsProvider`, `settingsProvider` | `StreamProvider` | Live views of stored data. |
| `prefsProvider` | `Provider<AppPrefs>` | Settings with defaults while loading. |
| `playerProvider` | `Provider<PlayerStatus?>` | Hero plus derived XP and energy. `null` until loaded or before onboarding. |

## Determinism

Combat and expeditions must be reproducible from a seed:

- `GameRng` (`lib/domain/rng.dart`) is a hand-written mulberry32 PRNG rather than `dart:math` `Random`, so a seed gives the same result on every platform and Dart version.
- `BattleEngine.act` is a pure function of `(state, action, rng)`. It returns structured `BattleEvent`s alongside the text log so a scene can animate each beat without being able to change the result.
- `Expedition.generate(seed, heroLevel)` always returns the same expedition.
- Tests replay seeds, including a 200-seed balance check per level.

## Navigation and app start

`IAmChadApp` shows `OnboardingScreen` until a hero exists, then `HomeShell`, which hosts `HubScreen`: the Flame guild hall with a HUD and menu bar. Train, Quests, Adventure, Hero and Journal open as pages on top of the hall (and Settings from the HUD gear). When a page closes, the hall compares the player's XP, energy, coins and level before and after and plays the matching celebration. Creating the hero is the only thing that moves the player out of onboarding; the gate reacts to the `heroProvider` stream.

## Accessibility hooks

- `MediaQuery.disableAnimations` is forced on when the in-app "Reduce motion" setting is enabled.
- Progress bars and charts always print their numbers; nothing is conveyed by colour alone (enemy intent also uses an icon and text).
- Interactive stat widgets expose `Semantics` labels; the battle log is a live region.
- Text size follows the OS setting; layouts scroll rather than clip.
- The Flame canvas is decorative on top of Flutter widgets: every destination is also a labelled menu button, and battle actions are Flutter buttons with semantic labels.

## Testing strategy

| Kind | Location | What it covers |
| --- | --- | --- |
| Domain unit tests | `test/domain` | Reward maths, level curve, RNG, combat, expeditions, quests, dialogue lint |
| Repository tests | `test/data` | Real Drift queries against an in-memory SQLite database |
| Widget flow tests | `test/app_flow_test.dart`, `test/adventure_flow_test.dart` | Onboarding to the guild hall and a first logged workout, and earning energy to finishing an expedition through the Flame battle scene. Shared setup is in `test/helpers.dart` (fixed clock, silent feedback, reduced motion) |
| Migration test | `test/data/migration_test.dart` | A schema v1 database with real rows upgrades to v2 intact |

## Planned extensions

- **Health integrations and cloud sync** are deliberately absent. Before multi-device accounts, sync conflict resolution must be designed (GDD section 10).
