# Reward rules (version 1)

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

Each entry is worth **at least 3 effort minutes**, so showing up always counts.

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
- **Paid once, never revoked.** Rewards go into `streak_rewards` in the same transaction that adds the coins and XP. If a workout is deleted afterwards the reward stays, and rebuilding the same streak does not pay again. The cost is that someone could back-date a workout to claim a reward; since the game is single-player and the rewards are small, that is accepted (the [honesty check](#honesty-check) still applies).
- **Where it shows.** A flame and count on the hall HUD, a Streak panel on the quest board (current, best, progress to the next reward, and the rest-day rule), the "Streak Reward!" card in the workout-saved dialog, and a "From Streaks" line in the hero's records.

## Versioning and history

- `RewardRules.version` is stored on each day's row in `reward_grants`.
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

- The 3-minute floor lets someone log many tiny entries to reach the cap quickly. The cap bounds the damage and the game is single-player, and the [honesty check](#honesty-check) now flags the pattern, but a per-day limit on floored entries is a possible tightening.
- Camera-based rep recognition could verify reps, but it has real privacy, accessibility and accuracy costs. See the [roadmap](ROADMAP.md).
- Weekly or personal-baseline scaling ("rewards recognise consistency relative to personal baseline") is not implemented yet. See the [roadmap](ROADMAP.md).
