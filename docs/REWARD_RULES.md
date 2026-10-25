# Reward rules (version 2)

How a logged workout becomes **XP** and **adventure energy**. The code is `RewardRules` in [`lib/domain/rewards.dart`](../lib/domain/rewards.dart); the numbers below are the `RewardRules.v1` defaults.

The GDD lists the exact formula and caps as an open decision ("test for fairness across abilities"). These are the current proposal, built to be easy to retune.

## Goals

- A beginner doing something small should still feel meaningful progress.
- Nobody should be pushed to do more by the reward system. Rewards are capped per day.
- The player must be able to see *why* they earned what they did.
- Honest play is assumed. The game does not verify workouts and does not pretend to.

## Step 1: entry to effort minutes

Every entry is converted to **effort minutes**, a common currency across activities.

| Entry has | Effort minutes |
| --- | --- |
| Duration | `minutes × activity factor`, multiplied by sets for timed holds such as plank |
| Reps (no duration) | `(sets × reps × seconds per rep + 45 s × (sets − 1)) / 60 × factor` |
| Distance only | `km × minutes per km × factor` |
| None of these | 0 (the entry cannot be saved) |

Each entry is worth **at least 3 effort minutes**, so showing up counts. In version 2 this minimum is given to the **first 3 short entries of a day** (oldest first). A fourth or later entry under 3 minutes counts for its real length. Entries of 3 minutes or more are never affected, and an honest small day (three short moves and a walk) earns exactly what it did before.

Activity factors:

| Activity | Factor | Seconds per rep |
| --- | --- | --- |
| Walking | 1.0 | n/a |
| Running / jogging | 1.25 | n/a |
| Stretching, light mobility | 0.6 | n/a |
| Bodyweight and resistance (sets and reps) | 1.0 | 6 |

### Things that deliberately do *not* change rewards

- **Exercise variant** (wall vs. standard push-up). An easier version earns exactly the same.
- **Weight lifted.** Heavier is not rewarded more, which avoids pushing people to lift beyond their level.
- **Perceived effort rating.** Recorded for the player's own insight only.
- **Pace or distance when a duration is given.**

## Step 2: daily diminishing returns

All of a local day's effort minutes are summed, then passed through a curve:

| Day's effort minutes | Credited at |
| --- | --- |
| First 20 | 100% |
| Next 20 (20 to 40) | 50% |
| Beyond 40 | 0% |

So credited minutes are at most **30** per day, no matter how much is logged.

## Step 3: credited minutes to rewards

- **XP** = `credited minutes × 4` (rounded). Maximum **120 XP per day**.
- **Energy** = `ceil(credited minutes / 5)`. Maximum **6 energy per day**. Any credited effort gives at least 1.

An expedition costs 2 energy, so a maximum-effort day funds three expeditions. Most players will be nowhere near that, and the free practice duel is always available.

## Worked examples

| What the player logged | Effort min | Credited | XP | Energy |
| --- | --- | --- | --- | --- |
| 10-minute walk | 10 | 10 | 40 | 2 |
| 2 sets of 8 wall push-ups (about 2.4, lifted to the 3-minute floor) | 3 | 3 | 12 | 1 |
| Wall push-ups plus a 10-minute walk (the GDD example) | 13 | 13 | 52 | 3 |
| 30-minute run | 37.5 | 28.75 | 115 | 6 |
| 60-minute run | 75 | 30 | 120 | 6 |
| 5-minute stretch | 3 | 3 | 12 | 1 |

## Explaining rewards

After each save the player sees the day's XP and energy plus `RewardRules.explain`, for example:

> Today's activity counts as 13 effort minutes. 13 of them are credited (13 is within the full-value range).

When the cap is reached the message says so, and Chad reminds the player that resting is part of training.

## Honesty check

The game cannot verify a workout, so it asks the player to be honest instead. `lib/domain/honesty.dart` looks at each entry and raises a gentle note when the numbers are unlikely to be real:

| Concern | Trigger |
| --- | --- |
| Pace | Distance and time (at least 30 s) imply a speed above the activity's limit: 10 km/h walking, 25 km/h running |
| Reps | More reps in one set than almost anyone can do, for example over 80 push-ups, 120 squats or sit-ups, 40 dumbbell reps or 30 barbell squats |
| Very quick | Under 20 seconds of real effort, before the 3-minute floor lifts it |
| Tiny entries | The fourth or later entry in one day that is under a minute of effort |

The note appears live under the effort fields while the player types, and again in a "Quick Honesty Check" dialog when they save, with "Let Me Fix It" and "It's Accurate" buttons. Rules for the check:

- **It never blocks and never changes a reward.** Choosing "It's Accurate" saves exactly what was entered with the normal rewards. A typo should never cost anything, and the game does not punish.
- **It never accuses.** The wording says the numbers look unusual and that only the player knows. Limits are deliberately generous, so honest players, including beginners and people doing very gentle activity, are not flagged.
- Reps counted by the phone camera need no second opinion, so those entries skip the check. They earn exactly the same rewards as typed entries.
- Thresholds live on `ActivityType` (`plausibleRepsPerSet`, `plausibleKmh`) and in `HonestyCheck`, and `test/domain/honesty_test.dart` covers them.

## Streaks

Added after the original design, in a form that fits the rest of this document. The rules are in `lib/domain/streaks.dart`.

- **What counts.** A streak is the number of *active days* in a row, where any logged movement makes a day active. Several workouts in one day count once.
- **Rest is built in.** The streak survives quiet days in between, up to a limit by experience: **3** for Just Starting, **2** for Getting Back Into It and Already Active. Two quiet days always covers a weekend off. Go past the limit and the next active day simply starts a fresh run.
- **Nothing is taken away.** A lapse never removes coins, XP or items already earned. The best run is remembered ("Best 12") and shown. The wording is always kind: a fresh start, never a loss, and there is no countdown or "don't break it" message.
- **Rewards are one-time milestones**, paid when the streak first reaches them:

| Active days | Reward | Coins | XP |
| --- | --- | --- | --- |
| 3 | Getting Started | 15 | 20 |
| 5 | On a Roll | 25 | 30 |
| 7 | A Heroic Week | 40 | 50 |
| 10 | Ten Strong | 50 | 60 |
| 14 | Fortnight of Might | 80 | 100 |
| 21 | Three Weeks Strong | 100 | 120 |
| 30 | Month of Might | 150 | 200 |
| 45 | Steady as Stone | 180 | 240 |
| 60 | Two Months Strong | 220 | 300 |
| 90 | Season of Strength | 300 | 400 |
| 120 | Four Months Strong | 350 | 450 |
| 180 | Half-Year Hero | 450 | 600 |
| 270 | Nine Months Strong | 600 | 800 |
| 365 | Year of the Hero | 800 | 1000 |
| every 100 after | Legendary Run | 500 | 600 |

- **They reward consistency, not volume.** A milestone is reached by being active on enough days, which any amount of movement satisfies, so it never pushes anyone to do more in a day. The daily XP and energy cap is untouched, and streak XP is paid on top as a small, occasional extra (the early ones are well under one day's maximum of 120).
- **Paid once, never revoked.** Rewards go into `streak_rewards` in the same transaction that adds the coins and XP. If a workout is deleted afterwards the reward stays, and rebuilding the same streak does not pay again. Only workouts logged on the day they happened count toward a streak, so a streak cannot be built by back-dating (see [back-dated workouts](#back-dated-workouts)).
- **Where it shows.** A flame and count on the hall HUD, a Streak panel on the quest board (current, best, progress to the next reward, and the rest-day rule), the "Streak Reward!" card in the workout-saved dialog, and a "From Streaks" line in the hero's records.

## Back-dated workouts

A workout can be logged for a day that has already passed, so the journal stays honest and complete. But rewards are for what you do **now**, so a back-dated workout earns nothing.

- **The rule.** A workout counts for rewards only if it was *logged on the day it happened*, or within **6 hours** after it (so a late-night session logged just after midnight still counts). Anything dated in the future never counts. The check is `WorkoutEntry.countsForRewards`, from the time the workout happened and the time it was entered (`logged_at`).
- **What it covers.** XP and energy for the day, the streak and its milestone rewards, quest completion and the weekly goal. A back-dated entry is still in the journal (tagged "Journal Only"), the history totals and the export.
- **Edits cannot get around it.** The logged-at time is set once and never changes. Moving a real workout to an earlier day turns it into a back-dated one and removes its reward; moving it back restores it. Older entries from before logged-at times were kept count as logged when they were performed.
- **The player is told.** Picking an earlier day on the log screen shows "Back-dated: this goes in your journal but earns no rewards", and saving shows "Saved to Your Journal" instead of a reward.
- **What it does not stop.** The game runs offline, so someone can still change their phone's clock. It cannot be prevented without a server, and it is a single-player game.

## Coins and the shop

Coins come from expeditions (about 5 to 10 per battle), duplicate loot (10), and streak milestones. Practice duels pay nothing. The **Guild Shop** (`lib/domain/shop.dart`) is where they are spent. Nothing in it is random, nothing costs real money, and there is no way to buy XP, energy or coins, with money or otherwise. Real money buys only cosmetics and thanks, in a separate place (see [Monetization](MONETIZATION.md)), and never changes a reward.

| For sale | Price | Notes |
| --- | --- | --- |
| Starter gear: Hero's Sweatband, Guild Tunic, Practice Sword | 60 | Small bonuses |
| Lucky Pebble | 70 | |
| Upgrade gear: Wayfarer Cap, Trailblazer Vest | 220 | |
| Upgrade gear: Iron Blade, Stopwatch Charm | 240 | |
| Gullhaven Coast gear (4 pieces) | 460 to 520 | Found in region 2, or bought |
| Glimmer Caverns gear (4 pieces) | 780 to 880 | Found in region 3, or bought |
| Frostpeak Pass gear (4 pieces) | 1,200 to 1,350 | Found in region 4, or bought |
| Thunder Heights gear (4 pieces) | 1,900 to 2,100 | Found in region 5, or bought |
| Sunstone Dunes gear (4 pieces) | 2,600 to 3,000 | Found in region 6, or bought |
| Starlit Isles gear (4 pieces) | 3,500 to 4,000 | Found in region 7, or bought |
| Healing Potion | 25 each | Up to 5 in the pouch |

- **Gear** is also found as expedition loot, so buying is never the only way, and a duplicate drop pays 10 coins back. The bonuses are deliberately small and unchanged.
- **Potions.** Every expedition starts with 2 free potions. Up to **3** more come from the pouch, on top. Pouch potions are used last, so any that are not needed come home again when the expedition ends (including after a retreat or an abandon). Potions are taken from the pouch and the expedition saved in one step, so closing the app can never lose them.
- **Purchases are atomic.** Coins are only taken if the item is actually bought, and you cannot buy what you own or overfill the pouch.

## Versioning and history

- `RewardRules.version` is stored on each day's row in `reward_grants`.  Version 1 days (before the floor limit) keep their rewards; only days touched later are recomputed under version 2.
- A day is recomputed (with the *current* rules) only when its workouts are added, edited or deleted. Untouched days keep the rules they were granted under.
- Balance changes therefore never alter anyone's recorded exercise, and never retroactively change days they did not touch.
- To change the numbers: add a new `RewardRules` constant with a bumped `version`, switch `GameRepository`'s default, and update this document and the tests.

## Edge cases

| Situation | Behaviour |
| --- | --- |
| Workout edited or moved to another day | Both the old and new day are recomputed |
| Last workout of a day deleted | That day's grant row is removed |
| A workout is deleted after its energy was spent | Energy shows as 0, never negative; XP from adventures is kept |
| Entry for an activity id this version does not know | Stored and shown as "Unknown activity", earns nothing, never crashes |
| Rest day | No entry, no reward, no penalty |

## Known gaps and ideas

- The 3-minute floor used to let someone log many tiny entries to reach the cap quickly. Version 2 limits the floor to 3 entries a day ([decision 43](DECISIONS.md#43-the-minimum-effort-floor-applies-to-three-short-entries-a-day)); the [honesty check](#honesty-check) still flags the pattern.
- Camera-based rep recognition could verify reps, but it has real privacy, accessibility and accuracy costs. See the [roadmap](ROADMAP.md).
- Weekly or personal-baseline scaling ("rewards recognise consistency relative to personal baseline") is not implemented yet. See the [roadmap](ROADMAP.md).

## Personal bests

`lib/domain/records.dart` works out the player's own best marks from the journal: heaviest weight (with the reps done at it), most reps in one set, longest time and farthest distance, for each exercise. They appear in a **Personal Bests** panel in the journal, and the "Workout Saved!" dialog says so when a workout beats an earlier mark.

- **They never change a reward.** Weight and pace still earn nothing extra (see above), so there is no pull toward lifting heavier or pushing harder than is right for the player. The panel and the dialog both say this.
- **The first time is not a record.** Only a mark that already had a holder can be beaten, and matching a mark does not count. A tie keeps the earlier one.
- **Editing is safe.** An entry being edited is not measured against its old self, and a typo is fixed by editing or deleting the entry, after which the marks are recalculated from the journal.
- **Nothing is stored.** The marks are derived each time, so they can never disagree with the journal.
- **Progress lines.** Tapping a personal best in the journal opens a small chart of how that mark has moved: one dot per day it was done (that day's best), the latest 24 days, with the first, latest and best marks written out (`MarkHistory` in `records.dart`, `mark_progress.dart`). The line goes down as well as up and the card says so. It never shows a target, a percentage, a streak or a comparison, it never changes a reward, and like the bests it is derived from the journal, so nothing is stored.

## Weekly goal

The weekly goal is the number of days in a Monday to Sunday week with any logged movement. It starts at the suggestion for the player's experience (2, 3 or 4 days) and the quest board lets them choose any number from 1 to 7, or hand the choice back by tapping the suggested number. It is only a target to look at: missing it takes nothing away and changes no reward. The week's edges are calendar midnights, so a daylight-saving change cannot shift a workout into the wrong week.
