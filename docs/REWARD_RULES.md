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

- The 3-minute floor lets someone log many tiny entries to reach the cap quickly. The cap bounds the damage and the game is single-player, but a per-day limit on floored entries is a possible tightening.
- Weekly or personal-baseline scaling ("rewards recognise consistency relative to personal baseline") is not implemented yet. See the [roadmap](ROADMAP.md).
