# Decision log

Short records of choices that shaped the codebase, so the reasoning is not lost. Add a new entry when you make a decision that someone might later want to reverse. Newest entries go at the bottom.

## 1. Flutter, Riverpod and Drift

**Decision:** Flutter and Dart for the app, Riverpod for state, Drift on SQLite for storage.
**Why:** Taken from the GDD's technology direction. Flutter gives one codebase for Android and iOS; Drift gives typed, reactive, offline-first storage; Riverpod makes dependencies explicit and testable through provider overrides.
**Consequence:** Drift needs code generation (`build_runner`).

## 2. Game rules are pure Dart

**Decision:** Rewards, combat, expeditions, quests and dialogue live in `lib/domain` with no Flutter or database imports.
**Why:** The GDD asks for testable domain logic and deterministic seeds. It also means a future Flame scene or a backend can reuse the same rules.

## 3. Rewards are derived per day, not stored as a running total

**Decision:** The `workouts` table is the source of truth. Each local day's XP and energy is computed from that day's workouts and stored in `reward_grants` with the rules version.
**Why:** Editing or deleting a workout must keep the game consistent without hand-written reversals. Stamping the rules version, and recomputing only touched days, means rebalancing never rewrites untouched history (GDD section 10).
**Alternatives considered:** An append-only reward ledger (harder to keep correct on edit and delete), or recomputing everything on every read (silently rewrites history after a rebalance).
**Consequence:** Energy available is `earned − spent`, clamped at 0, so deleting a workout after spending its energy cannot go negative.

## 4. Daily cap with diminishing returns, no streaks

**Decision:** Full value for the first 20 effort minutes of a day, half for the next 20, nothing after. No streaks, daily login rewards or countdowns.
**Why:** The GDD forbids punishment and compulsion, and warns about overexercise for rewards. A cap bounds the incentive; the half-value band avoids a hard cliff.
**Consequence:** Maximum 120 XP and 6 energy per day. See [Reward rules](REWARD_RULES.md).

## 5. Variants, load and perceived effort never affect rewards

**Decision:** Easier variants earn exactly the same as harder ones, and weight lifted does not matter.
**Why:** "A player doing a smaller or modified workout should still receive meaningful progress" (GDD 5.3), and heavier loads should not be rewarded for their own sake.

## 6. A minimum of 3 effort minutes per entry

**Decision:** Any valid entry is worth at least 3 effort minutes.
**Why:** Two sets of wall push-ups would otherwise be worth almost nothing, which is discouraging for exactly the players the game is for.
**Trade-off:** It is slightly gameable by logging many tiny entries; the daily cap limits the effect. Noted as a known gap.

## 7. Hand-written PRNG

**Decision:** `GameRng` implements mulberry32 instead of using `dart:math` `Random`.
**Why:** The sequence for a seed is guaranteed identical across platforms and Dart versions, so saved seeds and test expectations stay valid.

## 8. Enemy intent is always visible

**Decision:** The UI shows whether the enemy will strike or wind up a heavy blow before the player acts.
**Why:** It makes short fights a readable tactics puzzle on a phone and supports "difficulty through tactics" (GDD 6.3). It also lets guarding feel meaningful.

## 9. Failure keeps rewards; practice is free

**Decision:** Losing or retreating from an expedition keeps XP and coins from battles already won. A free practice duel always exists.
**Why:** Progress without punishment, and something to play on a rest day.

## 10. Combat built with Flutter widgets before Flame

**Decision:** The first combat UI uses ordinary widgets. Flame is not a dependency yet.
**Why:** The loop (logging, rewards, expedition, loot) needed proving before investing in scenes and art. The engine is UI-agnostic, so Flame can be layered on later.

## 11. Generated code is not committed

**Decision:** `*.g.dart` is git-ignored; `dart run build_runner build` regenerates it.
**Why:** Avoids noisy diffs and merge conflicts in generated files.
**Trade-off:** A fresh clone needs one extra command (documented in the README).

## 12. Store metric, display in the player's units

**Decision:** Distance and weight are stored in metres and kilograms; the Settings unit switch only changes input and display.
**Why:** One canonical unit avoids conversion drift and makes data export unambiguous.

## 13. Android and iOS only

**Decision:** Only the Android and iOS platform folders were generated.
**Why:** The GDD targets those two platforms. Other platforms can be added with `flutter create --platforms=...` if needed.
