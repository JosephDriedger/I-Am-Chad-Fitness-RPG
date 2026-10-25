# Data model

Everything is stored locally in a single SQLite database through [Drift](https://drift.simonbinder.eu/). The game data never leaves the device: the only network use is the platform store, the one ad at the start of a story chapter (see [Monetization](MONETIZATION.md)), and the one-time download of a later story season (see [Content packs](CONTENT_PACKS.md)). Table definitions are in [`lib/data/database.dart`](../lib/data/database.dart).

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
| `cape`, `hair_dye` | The chosen cape and hair dye, as ids from `Cosmetics` (`classic` and `''` by default; schema v8). Looks only. A look the player does not have access to is drawn as the default, never as an error |
| `weekly_goal_days` | Days a week the player chose to aim for, 1 to 7; 0 means "use the suggestion for their experience" (schema v9) |
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

### `story_progress` and `story_choices`

`story_progress` has one row per chapter the player has finished or skipped: `chapter` (primary key; 0 is the prologue) and `read_at`. `story_choices` has one row per remembered answer: `key` (primary key, such as `motivation`) and `option` (the index picked). Replaying a chapter and answering again replaces the row. Which chapters are *open* is never stored: it is derived from the hero's level (see [Story](STORY.md)). Both tables are in the export and are cleared by `deleteEverything()`.

### `purchase_receipts`

One row per purchase made through the app store (schema v8): `key` (primary key), `product_id` and `granted_at`. The key is the product id for the one-time Patron Pack, so a restore or a repeated delivery can never create a second copy, and `tip:<transaction id>` for a tip, so each tip counts once. Rows are written in the same step that precedes confirming the purchase to the store. `Entitlements.fromReceipts` turns them into what the player owns; unknown product ids are ignored. Nothing here can change XP, energy, coins or any stat. The export lists `productId` and `grantedAt` only, never a transaction id, and `deleteEverything()` clears the table (the pack returns with Restore Purchases, because it belongs to the store account). See [Monetization](MONETIZATION.md).

### `active_expeditions`

At most one row (`id = 1`): the expedition in progress, if any. Columns: `seed`, `hero_level`, `step_index`, `hero_hp`, `potions`, `battles_won`, `xp`, `coins`. The row is written when an expedition starts (in the same transaction that spends the energy) and at the start of each step, and deleted when the run is recorded or abandoned. The map, enemies and loot are regenerated from `seed` and `hero_level`, never stored. `deleteEverything()` clears it too.

### `app_settings`

A single row with `id = 1`: `use_metric`, `reduced_motion`, `quiet_chad`, `sound_on`, `haptics_on`, `music_on` (schema v10). When the row is missing the app uses defaults (metric, motion on, Chad chatty, sound and vibration on, **music off**).

## Derived values (never stored)

| Value | Definition |
| --- | --- |
| Total XP | `sum(reward_grants.xp) + heroes.adventure_xp` |
| Level | `Progression.levelForXp(totalXp)` |
| Energy earned | `sum(reward_grants.energy)` |
| Energy available | `max(0, energy earned − heroes.energy_spent)` |
| Weekly goal progress | Distinct active days in the current Monday to Sunday week, against `HeroProfile.weeklyGoalTarget` (the chosen days, else the suggestion). The week edges are calendar midnights, so a clock change cannot move them |
| Personal bests | `PersonalBests.of(workouts)`: heaviest, most reps in a set, longest and farthest per exercise, newest first. Never stored, never rewarded |
| Quest completion | Whether an entry for the suggested activity exists today |
| Open story chapters | Chapters whose unlock level is at or below the hero's level |

Keeping these derived means editing or deleting a workout automatically keeps the whole game state consistent.

## Privacy features

- **Export:** `GameRepository.exportJson()` produces a readable JSON summary with workouts, reward grants, hero, story and purchases, for looking at or using elsewhere; it is not enough to restore from, which is what the full backup below is for. The Settings screen copies it to the clipboard.
- **Spreadsheet:** `WorkoutCsv` (`lib/data/workout_csv.dart`) turns the journal into a CSV file, one row a workout, oldest first, for a spreadsheet or a coach: date, time, exercise, variant, sets, reps, minutes, kilometres, kilograms, how it felt, the note, whether it counted for rewards and whether the camera counted it. Units are always metric and named in the headings. It holds nothing but workouts, so it cannot be restored from. Cells that a spreadsheet could read as a formula get a leading apostrophe. Settings has "Save Workouts as a Spreadsheet": the share sheet where there is one, otherwise the clipboard.
- **Backup and restore:** `GameRepository.backupJson()` writes a **full** backup: every row of every table about the player (hero, workouts, reward grants, gear, expeditions, story progress and choices, streak rewards, purchase receipts and the saved expedition), by table and column name, with the database version. The device's own preferences (`app_settings`: units, sound, reminders) are left out on purpose, so a restore never switches a reminder on or changes how the phone behaves. Settings has "Save or Send a Backup" (the phone's share sheet, with a plain `.txt` file named for the day, for Files, a drive or an email to oneself), "Copy a Full Backup" (the clipboard), and "Restore From a Backup", which can "Choose a Backup File" or take pasted text. The share sheet and file chooser sit behind `BackupFiles` (`lib/app/backup_files.dart`, `share_plus` and `file_picker`), which is only installed on Android and iOS; elsewhere only copy and paste are offered. Reading is strict (`lib/data/backup.dart`): the file must say it is this game's, must not be from a newer version, and may hold only known tables and columns with plain values of the right kind, or it is refused before anything changes. A backup from an earlier version restores with newer columns left at their defaults. Restoring is two steps (see what it holds, then confirm) and is all or nothing: the player's data is replaced in one transaction, everything is read back, and any failure rolls the lot back. `test/data/backup_test.dart` fails if a new table is not backed up or named as a device table.
- **Delete:** `GameRepository.deleteEverything()` empties every table in one transaction. Settings asks for confirmation first.

No account and no analytics exist in the app. The only network calls are the store, the chapter ad and the story-season download, and none of them is sent any of the data above. Downloaded seasons are kept as files in the app's private folder (`story_packs/`), not in the database, because they are content rather than the player's data; Delete All My Data leaves them in place.

## Migrations

`schemaVersion` is currently **12**. Version 12 added `app_settings.reminder_on` (default off), `reminder_hour` (default 18) and `reminder_days` (a bitmask, Monday as bit 0, default Monday, Wednesday and Friday); `test/data/migration_v12_test.dart` proves a v11 save keeps its settings and starts with reminders off. Version 11 added `active_expeditions.tier` and `focus`. Version 10 added `app_settings.music_on` (`test/data/migration_v10_test.dart`). Version 9 added `heroes.weekly_goal_days` (`test/data/migration_v9_test.dart`). Version 8 added `purchase_receipts`, `heroes.cape` and `heroes.hair_dye` (`test/data/migration_v8_test.dart`). Version 7 added the `story_progress` and `story_choices` tables; `test/data/story_progress_test.dart` proves a v6 save keeps its workouts and hero. Version 6 added `workouts.logged_at` and `heroes.potion_stock`; `test/data/shop_test.dart` proves a v5 save keeps its workouts, rewards and hero. Version 5 added the `streak_rewards` table and `heroes.streak_xp`; `test/data/streak_rewards_test.dart` proves a v4 save keeps its workouts and hero. Version 4 added `workouts.camera_counted`; `test/data/migration_v4_test.dart` proves a v3 save keeps every workout. Version 2 added `heroes.appearance_skin`, `app_settings.sound_on` and `app_settings.haptics_on`; `onUpgrade` adds the columns with their defaults and `test/data/migration_test.dart` proves a v1 save survives. Version 3 added the `active_expeditions` table; `test/data/migration_v3_test.dart` proves a v2 save survives, and the upgrade was also confirmed on an Android emulator with an existing save. When changing a table:

1. Edit the table in `database.dart` and bump `schemaVersion`.
2. Add the matching step in `MigrationStrategy.onUpgrade`.
3. Run `dart run build_runner build` to regenerate `database.g.dart`.
4. Add a repository test that opens an old-shape database and checks that workouts survive.

Workout rows must always survive an upgrade. They are the player's real exercise history.

## Future: sync

Cloud sync is out of scope for the MVP. Before enabling multi-device accounts, design conflict resolution (the GDD calls this out explicitly). The per-day derived grants and append-only expedition history were chosen partly to make merging tractable.
