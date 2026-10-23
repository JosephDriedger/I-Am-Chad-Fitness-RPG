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
| `logged_at` | datetime? | When it was entered (schema v6). Null for older entries, which count as logged when performed. Never changes when an entry is edited. A workout only earns rewards if logged on the day it happened (see [Reward rules](REWARD_RULES.md#back-dated-workouts)). |

`camera_counted` (bool, default false) marks entries whose reps were counted by the phone camera. It is cleared if the player changes the numbers afterwards. It never changes rewards.

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
| `streak_xp` | XP paid out for streak milestones (schema v5) |
| `potion_stock` | Healing potions in the pouch, bought in the shop (schema v6) |
| `created_at` | |

### `owned_items`

| Column | Notes |
| --- | --- |
| `item_id` PK | Id from `ItemCatalog` |
| `acquired_at` | |
| `equipped` | Only one per slot is ever true (enforced in `GameRepository.setEquipped`) |

### `expedition_runs`

An append-only history of finished runs: `seed`, `finished_at`, `victory`, `battles_won`, `xp`, `coins`, `loot_item_id`. Expeditions themselves are regenerated from a seed and level, so the full sequence is never stored.

### `streak_rewards`

One row per streak milestone the player has been paid for: `days` (primary key), `claimed_at`, `coins`, `xp`. A row is written in the same transaction that adds the coins and `heroes.streak_xp`, so a milestone is paid exactly once. Rows are never deleted when workouts are later edited or removed, so nothing already earned is taken back. `deleteEverything()` clears it.

### `active_expeditions`

At most one row (`id = 1`): the expedition in progress, if any. Columns: `seed`, `hero_level`, `step_index`, `hero_hp`, `potions`, `battles_won`, `xp`, `coins`. The row is written when an expedition starts (in the same transaction that spends the energy) and at the start of each step, and deleted when the run is recorded or abandoned. The map, enemies and loot are regenerated from `seed` and `hero_level`, never stored. `deleteEverything()` clears it too.

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

`schemaVersion` is currently **6**. Version 6 added `workouts.logged_at` and `heroes.potion_stock`; `test/data/shop_test.dart` proves a v5 save keeps its workouts, rewards and hero. Version 5 added the `streak_rewards` table and `heroes.streak_xp`; `test/data/streak_rewards_test.dart` proves a v4 save keeps its workouts and hero. Version 4 added `workouts.camera_counted`; `test/data/migration_v4_test.dart` proves a v3 save keeps every workout. Version 2 added `heroes.appearance_skin`, `app_settings.sound_on` and `app_settings.haptics_on`; `onUpgrade` adds the columns with their defaults and `test/data/migration_test.dart` proves a v1 save survives. Version 3 added the `active_expeditions` table; `test/data/migration_v3_test.dart` proves a v2 save survives, and the upgrade was also confirmed on an Android emulator with an existing save. When changing a table:

1. Edit the table in `database.dart` and bump `schemaVersion`.
2. Add the matching step in `MigrationStrategy.onUpgrade`.
3. Run `dart run build_runner build` to regenerate `database.g.dart`.
4. Add a repository test that opens an old-shape database and checks that workouts survive.

Workout rows must always survive an upgrade. They are the player's real exercise history.

## Future: sync

Cloud sync is out of scope for the MVP. Before enabling multi-device accounts, design conflict resolution (the GDD calls this out explicitly). The per-day derived grants and append-only expedition history were chosen partly to make merging tractable.
