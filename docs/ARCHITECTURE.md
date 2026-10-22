# Architecture

This document describes how the code is organised and the rules that keep it that way. For the product-level view see the [Game Design Document](I_Am_Chad_Fitness_RPG_GDD.pdf) (section 10).

## Layers

```
┌──────────────────────────────────────────────┐
│ features/   Screens (Flutter widgets)         │
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
| App | `lib/app` | domain, data, Flutter, Riverpod | Providers combine repository streams into UI-ready state. |
| Features | `lib/features` | everything above | One folder per screen. No SQL, no game maths. |

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
- `BattleEngine.act` is a pure function of `(state, action, rng)`.
- `Expedition.generate(seed, heroLevel)` always returns the same expedition.
- Tests replay seeds, including a 200-seed balance check per level.

## Navigation and app start

`IAmChadApp` shows `OnboardingScreen` until a hero row exists, then `HomeShell` with five tabs (Guild, Workout, Adventure, Hero, History). Quests and Settings are pushed from the Guild screen. Creating the hero is the only thing that moves the player out of onboarding; the gate reacts to the `heroProvider` stream.

## Accessibility hooks

- `MediaQuery.disableAnimations` is forced on when the in-app "Reduce motion" setting is enabled.
- Progress bars and charts always print their numbers; nothing is conveyed by colour alone (enemy intent also uses an icon and text).
- Interactive stat widgets expose `Semantics` labels; the battle log is a live region.
- Text size follows the OS setting; layouts scroll rather than clip.

## Testing strategy

| Kind | Location | What it covers |
| --- | --- | --- |
| Domain unit tests | `test/domain` | Reward maths, level curve, RNG, combat, expeditions, quests, dialogue lint |
| Repository tests | `test/data` | Real Drift queries against an in-memory SQLite database |
| Widget flow tests | `test/app_flow_test.dart`, `test/adventure_flow_test.dart` | Onboarding to first logged workout, and earning energy to finishing an expedition |

## Planned extensions

- **Flame** for combat scenes. The domain engine already separates rules from presentation, so a Flame scene can drive the same `BattleEngine`.
- **Health integrations and cloud sync** are deliberately absent. Before multi-device accounts, sync conflict resolution must be designed (GDD section 10).
