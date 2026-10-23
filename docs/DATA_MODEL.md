# Data model

Everything is stored locally in a single SQLite database through [Drift](https://drift.simonbinder.eu/). There is no network access. Table definitions are in [`lib/data/database.dart`](../lib/data/database.dart).

Dates are stored by Drift as UTC Unix seconds and read back as local `DateTime`s. Distances and weights are stored **metric** (metres, kilograms) and converted for display according to the units setting.

## Tables

### `workouts` (source of truth)

One row per logged activity. Fully editable and deletable by the player.

| Column | Type | Notes |
| --- | --- | --- |
| `id` | int PK | auto increment |
| `activity_id` | text | Stable id from `ActivityCatalog` (for example `push_up`). Never rename. |
| `performed_at` | datetime | When it happened; the local day groups rewards |
| `variant` | text? | For example "Wall"; has no effect on rewards |
| `sets`, `reps` | int? | Reps are per set |
| `duration_seconds` | int? | |
| `distance_meters` | real? | |
| `load_kg` | real? | |
| `perceived_effort` | int? | 1 to 5, informational only |
| `notes` | text? | |

### `reward_grants` (derived)

One row per local day with workouts. Rebuilt from `workouts` whenever that day changes.

| Column | Type | Notes |
| --- | --- | --- |
| `day` | text PK | `yyyy-MM-dd` in local time |
| `effort_minutes` | real | Raw total before the daily curve |
| `credited_minutes` | real | After diminishing returns |
| `xp`, `energy` | int | |
| `rules_version` | int | `RewardRules.version` used for this row |

### `heroes`

A single row with `id = 1`.

| Column | Notes |
| --- | --- |
| `name`, `appearance_style`, `appearance_color`, `appearance_skin` | Cosmetic, editable. Style is the hair or hood, colour is the outfit, skin is one of six tones |
| `experience` | `ExperienceLevel` name (`starting`, `returning`, `regular`) |
| `preferred_categories` | Comma-separated `ActivityCategory` names |
| `has_dumbbells` | Filters equipment-based suggestions |
| `energy_spent` | Lifetime energy spent on expeditions |
| `adventure_xp`, `coins`, `victories` | Earned through play |
| `created_at` | |

### `owned_items`

| Column | Notes |
| --- | --- |
| `item_id` PK | Id from `ItemCatalog` |
| `acquired_at` | |
| `equipped` | Only one per slot is ever true (enforced in `GameRepository.setEquipped`) |

### `expedition_runs`

An append-only history of finished runs: `seed`, `finished_at`, `victory`, `battles_won`, `xp`, `coins`, `loot_item_id`. Expeditions themselves are regenerated from a seed and level, so the full sequence is never stored.

### `app_settings`

A single row with `id = 1`: `use_metric`, `reduced_motion`, `quiet_chad`, `sound_on`, `haptics_on`. When the row is missing the app uses defaults (metric, motion on, Chad chatty, sound and vibration on).

## Derived values (never stored)

| Value | Definition |
| --- | --- |
| Total XP | `sum(reward_grants.xp) + heroes.adventure_xp` |
| Level | `Progression.levelForXp(totalXp)` |
| Energy earned | `sum(reward_grants.energy)` |
| Energy available | `max(0, energy earned − heroes.energy_spent)` |
| Weekly goal progress | Distinct active days in the current Monday to Sunday week |
| Quest completion | Whether an entry for the suggested activity exists today |

Keeping these derived means editing or deleting a workout automatically keeps the whole game state consistent.

## Privacy features

- **Export:** `GameRepository.exportJson()` produces a JSON document with workouts, reward grants and basic hero info. The Settings screen copies it to the clipboard.
- **Delete:** `GameRepository.deleteEverything()` empties every table in one transaction. Settings asks for confirmation first.

No account, analytics or network calls exist in the app.

## Migrations

`schemaVersion` is currently **2**. Version 2 added `heroes.appearance_skin`, `app_settings.sound_on` and `app_settings.haptics_on`; `onUpgrade` adds the columns with their defaults and `test/data/migration_test.dart` proves a v1 save survives. When changing a table:

1. Edit the table in `database.dart` and bump `schemaVersion`.
2. Add the matching step in `MigrationStrategy.onUpgrade`.
3. Run `dart run build_runner build` to regenerate `database.g.dart`.
4. Add a repository test that opens an old-shape database and checks that workouts survive.

Workout rows must always survive an upgrade. They are the player's real exercise history.

## Future: sync

Cloud sync is out of scope for the MVP. Before enabling multi-device accounts, design conflict resolution (the GDD calls this out explicitly). The per-day derived grants and append-only expedition history were chosen partly to make merging tractable.
