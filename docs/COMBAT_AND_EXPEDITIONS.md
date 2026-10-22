# Combat and expeditions

Combat is short, turn-based and readable on a phone. The rules are in [`lib/domain/combat.dart`](../lib/domain/combat.dart) and [`lib/domain/expedition.dart`](../lib/domain/expedition.dart); the UI is [`expedition_screen.dart`](../lib/features/adventure/expedition_screen.dart).

## Hero stats

Stats come from the hero's level and any equipped items (`Progression` in `lib/domain/hero.dart`).

```
softLevel(L) = L × 30 / (L + 30)
HP      = 40 + 6.0 × softLevel(L)
Attack  =  8 + 1.6 × softLevel(L)
Defense =  4 + 0.9 × softLevel(L)
```

`softLevel` flattens as the level rises, which is the GDD's "soft cap to prevent runaway power". Equipment adds small flat bonuses (a few points at most).

| Level | XP needed (total) | HP | Attack | Defense |
| --- | --- | --- | --- | --- |
| 1 | 0 | 46 | 10 | 5 |
| 2 | 60 | 51 | 11 | 6 |
| 5 | 551 | 66 | 15 | 8 |
| 10 | 2,018 | 85 | 20 | 11 |
| 20 | 6,670 | 112 | 27 | 15 |
| 50 | 30,371 | 153 | 38 | 21 |
| 99 (cap) | 92,069 | 178 | 45 | 25 |

Level XP is `60 × (level − 1)^1.6`. XP comes from workouts (derived) and from expeditions.

## Turn structure

Each turn the player picks one action, then the enemy answers. **The enemy's next move is always shown**, so combat is a tactics puzzle rather than a guessing game.

| Action | Effect |
| --- | --- |
| Attack | Strike for normal damage. +1 focus. |
| Guard | Halve (rounded up) the damage taken this turn. +1 focus. |
| Power Strike | Costs 2 focus. About double damage, plus 1. |
| Potion | Heal one third of max HP. Uses a potion (2 per expedition). Only usable when hurt. |

- Focus is capped at 5 and resets between battles.
- Damage: `max(1, attack − defense ÷ 2) + random(0..2)`, then multiplied (Power Strike ×2, enemy heavy blow ×1.6), minimum 1.
- Enemy intent each turn: a regular strike (75%) or a **heavy blow** (25%) announced as "winding up". Guarding on a wind-up is the intended counter.
- A battle ends when either side reaches 0 HP.

## Expeditions

A reward-bearing expedition costs **2 adventure energy** (spent when you set out) and has this fixed shape:

```
Battle (regular) → Event → Battle (regular) → Battle (boss)
```

`Expedition.generate(seed, heroLevel)` builds it deterministically:

- Two different regular enemies drawn from a pool of 6 (shuffled by the seed).
- One boss from a pool of 2.
- One event from a pool of 3.
- A loot item from the 8-item catalog, awarded on victory.

Enemies scale with the hero's level using the same soft-capped curve as the hero, multiplied by a per-enemy template (for example Snooze Slime has 0.55× HP). Difficulty is meant to come from enemy variety and tactics, not from stat inflation.

### Events

| Event | Effect |
| --- | --- |
| A traveling apothecary | +1 potion |
| A quiet campfire | Recover 40% of max HP |
| Chad's "secret" stash | +8 coins |

### Rewards

| Source | XP | Coins |
| --- | --- | --- |
| Regular battle won | 15 | 5 |
| Boss battle won | 30 | 12 |
| Full clear (2 regular + boss) | 60 | 22 (+8 with the stash event) |
| Loot (on full clear) | One item, or **10 coins** if already owned | |
| Practice duel win | 0 | 3 |

### Failure is gentle

- Being knocked out ends the run but **keeps the XP and coins from battles already won**. There is no loss of progress, gear or energy beyond the 2 energy already spent.
- Retreating from the pause dialog behaves the same way: rewards so far are kept, no loot.
- The **practice duel** is always free. It exists so rest days still have something to play (GDD pillar: progress without punishment).

## Roster

Regular enemies: Snooze Slime, Fog Imp, Rusty Gear Golem, Cobweb Wisp, Pebble Gremlin, Mist Wisp.
Bosses: Grumbling Treant, Chad's Old Rival Brad.

Enemies are intentionally whimsical obstacles, not insults aimed at the player. See [Content guidelines](CONTENT_GUIDELINES.md).

## Equipment

Eight pieces across four slots (head, body, weapon, trinket), one worn per slot. Bonuses are tiny (+1 to +6) and there is no way to buy them. Duplicates convert to coins.

## Balance status

A scripted "sensible player" (guards against heavy blows when hurt, uses Power Strike when available, drinks a potion below 35% HP) clears 500 seeded expeditions at these rates:

| Hero level | Win rate |
| --- | --- |
| 1 | about 90% |
| 3 to 40 | about 98 to 99% |

That is deliberately friendly for a first prototype, and probably too easy at higher levels. It is a regression guard, not proof of fun: the test only requires 75% or better. Real playtesting should drive the next tuning pass (see the [roadmap](ROADMAP.md)).

## Extending

- **New enemy:** add an `EnemyTemplate` to `EnemyPool.regular` or `bosses`. Existing seeds will map to different enemies afterwards, which is fine because expeditions are not stored, only their results.
- **New item:** add to `ItemCatalog.all`. Never rename or reuse an `id`; it is persisted in the inventory.
- **New action or status effect:** extend `BattleAction` and `BattleEngine.act`, then add tests alongside the existing ones in `test/domain/combat_test.dart`.
- **Flame scene:** drive `BattleEngine` from the scene and keep all rules in the domain layer.
