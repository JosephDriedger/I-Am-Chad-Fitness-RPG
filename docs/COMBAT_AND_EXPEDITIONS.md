# Combat and expeditions

Combat is short, turn-based and readable on a phone. The rules are in [`lib/domain/combat.dart`](../lib/domain/combat.dart), [`lib/domain/expedition.dart`](../lib/domain/expedition.dart) and [`lib/domain/difficulty.dart`](../lib/domain/difficulty.dart); the UI is [`expedition_screen.dart`](../lib/features/adventure/expedition_screen.dart).

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
| 99 | 92,069 | 178 | 45 | 25 |
| 120 (cap) | 125,611 | 184 | 46 | 26 |

Level XP is `60 × (level − 1)^1.6`. XP comes from workouts (derived) and from expeditions.

## Turn structure

Each turn the player picks one action, then the enemy answers. **The enemy's next move is always shown**, so combat is a tactics puzzle rather than a guessing game.

| Action | Effect |
| --- | --- |
| Attack | Strike for normal damage. +1 focus. |
| Guard | Halve (rounded up) the damage taken this turn. +1 focus. |
| Power Strike | Costs 2 focus. About double damage, plus 1. |
| Potion | Heal one third of max HP. Uses a potion (2 per expedition, plus up to 3 from the pouch). Only usable when hurt. |

- Focus is capped at 5 and resets between battles (a bard's tune starts the next one with 2).
- Damage: `max(1, attack − defense ÷ 2) + random(0..2)`, then multiplied, minimum 1.
- A battle ends when either side reaches 0 HP.

### Enemy moves

Every enemy has a **behaviour**: the chance of each move it can pick, out of 1. Whatever is left over is a plain strike. The first region's enemies only strike or wind up; the later regions add the rest, one idea at a time.

| Move | What it does | The answer |
| --- | --- | --- |
| Strike | A normal blow. | Anything. |
| Heavy blow ("winding up") | ×1.6 damage. | Guard. |
| Flurry ("getting ready to strike twice") | Two blows at ×0.65 each. Guarding halves both. | Guard when hurt. |
| Brace | The player's next blow lands at half strength, and the enemy answers with a light counter (×0.5). | Don't spend a Power Strike. Build focus, guard or heal. |
| Mend | Heals 15% of max HP instead of attacking. Only picked when it is hurt. | Hit hard first. |

A **boss** can also get **fired up**: once it drops below a set share of its health (35 to 45%) it hits 25% harder for the rest of the fight. The log and the scene both say so.

## Regions

The world is eight regions, defined in `difficulty.dart`. Each opens at a hero level, has its own enemies, bosses, scenery, camp events and loot, and is a little tougher than the one before. **A region stays open for good**, so the player can always go back to an easier one, and a picker on the Adventure screen chooses where to set out. The toughest open region is the default.

| # | Region | Opens at | Steps | Scenery | Bonus per battle (XP / coins) |
| --- | --- | --- | --- | --- | --- |
| 1 | Meadowmere | Level 1 | 4 | Meadow, forest | none |
| 2 | The Gullhaven Coast | Level 5 | 4 | Coast | +2 / +1 |
| 3 | The Glimmer Caverns | Level 10 | 5 | Crystal caves | +4 / +2 |
| 4 | Frostpeak Pass | Level 16 | 5 | Snowy peak, cave | +6 / +3 |
| 5 | Thunder Heights | Level 24 | 6 | Storm, peak | +8 / +4 |
| 6 | The Sunstone Dunes | Level 36 | 6 | Desert dunes | +10 / +5 |
| 7 | The Starlit Isles | Level 50 | 6 | Floating islands, night sky | +12 / +6 |
| 8 | The Ember Deeps | Level 66 | 6 | Lava caverns, glowing forges | +14 / +7 |

An enemy's HP, attack and defense are the hero's stats at that level, times the enemy's own build, times the region's three dials (`hpScale`, `attackScale`, `defenseScale`). The later regions' attack dials are below 1 on purpose: enemies hit a little less, but fights last longer and the tactics matter more. A boss's bonus is doubled. Difficulty is meant to come from enemy variety and tactics, not from stat inflation.

## Expeditions

A reward-bearing expedition costs **2 adventure energy** (spent when you set out). Its shape depends on the region (`b` battle, `e` camp, `B` boss):

| Region | Shape |
| --- | --- |
| 1 and 2 | `b e b B` |
| 3 | `b e b b B` |
| 4 | `b b e b B` |
| 5 | `b b e b e B` |
| 6, 7 and 8 | `b b e b b B` |

`Expedition.generate(seed, heroLevel, tier)` builds it deterministically:

- Regular enemies drawn without repeats from the region's own pool plus the region before it (never a tougher one).
- One of the region's two bosses.
- Camp events drawn from the pool: the first region only meets the first three, and each later region adds the other two, a fork in the road, and a few camps of its own.
- A loot item: 65% from the region's own gear, otherwise from an earlier region, so nothing is ever out of reach.

A saved run remembers its region. A run saved before regions existed resumes in the toughest region open at its level.

### Events

| Event | Effect | Where |
| --- | --- | --- |
| A traveling apothecary | +1 potion | All |
| A quiet campfire | Recover 40% of max HP | All |
| Chad's "secret" stash | 8 coins, plus 4 per region above the first | All |
| A wandering bard | The next fight starts with 2 focus | Region 2 and up |
| A quiet spring | Recover 25% of max HP | Region 2 and up |

From region 2 up there is also **a fork in the road**: a camp with a signpost where the player picks one of two ways, each of which has the effect of an ordinary camp (the general one offers the sunny path, which starts the next fight with focus, or the shady path, which heals; every region adds one of its own, such as "Tide or Cliff" or "Oasis or Dunes"). Neither way is better, and no new rules are needed: `ExpeditionRun.resolveEvent(choice:)` applies the camp the chosen way names. From region 2 up each region also has camps of its own (a tide-pool picnic on the coast, a glowcap grotto in the caves, a hut at the snow line, a sheltered alcove in the storm, an oasis in the dunes, and so on). They work exactly like the general camp of the same kind and only change the place and the words, so no new rules are needed. See `ExpeditionEvent.regional`.

### Rewards

| Source | XP | Coins |
| --- | --- | --- |
| Regular battle won | 15 + region bonus | 5 + region bonus |
| Boss battle won | 30 + double the region bonus | 12 + double the region bonus |
| Loot (on full clear) | One item, or **10 × region** coins if already owned | |
| Practice duel win | 0 | 0 |

### Failure is gentle

- Being knocked out ends the run but **keeps the XP and coins from battles already won**. There is no loss of progress, gear or energy beyond the 2 energy already spent.
- Retreating from the pause dialog behaves the same way: rewards so far are kept, no loot.
- The **practice duel** is always free, always against the first region's gentle enemies, and pays nothing. It exists so rest days still have something to play (GDD pillar: progress without punishment).

## Presentation

Each action also returns structured `BattleEvent`s (`PlayerAttacked`, `PlayerGuarded`, `EnemyAttacked`, `EnemyBraced`, `EnemyMended`, `EnemyEnraged`, `EnemyDefeated`, ...). The animated Flame battle scene plays them back in order; see [Game scenes](GAME_SCENES.md). The scene can only display results, never change them.

## Roster

| Region | Regular enemies | Bosses |
| --- | --- | --- |
| Meadowmere | Snooze Slime, Fog Imp, Rusty Gear Golem, Cobweb Wisp, Pebble Gremlin, Mist Wisp | Grumbling Treant, Chad's Old Rival, Brad |
| The Gullhaven Coast | Sand Crab (braces), Tide Jelly (mends), Gull Bandit (flurries) | Captain Barnacle, The Gull King |
| The Glimmer Caverns | Crystal Beetle (braces), Glowcap Shroom (mends), Echo Bat (flurries) | Crystal Colossus, Mother Glowcap |
| Frostpeak Pass | Frost Sprite (flurries), Snow Yeti (heavy blows), Icicle Golem (braces) | The Avalanche Matron, Old Man Winter |
| Thunder Heights | Thunder Cloud (flurries), Gale Hawk (flurries), Static Imp (braces and mends) | The Thunderhead, Stormcaller Skarn |
| The Sunstone Dunes | Dust Devil (flurries), Cactus Knight (heavy blows, braces), Scarab Roller (braces and mends) | The Great Dune Worm, The Riddling Sphinx |
| The Starlit Isles | Lantern Moth (flurries, mends), Comet Cat (flurries), Star Turtle (braces and mends) | The Comet King, Nova, the Very Bright |
| The Ember Deeps | Cinder Sprite (flurries, heavy blows), Anvil Golem (braces, heavy blows), Magma Slug (mends, braces) | Forgemaster Brun, Magmara, the Slow Simmer |

Chad teaches each region's enemy moves when you set out: `ChadDialogue.adventureLine` mixes his usual send-offs with tips for that region, and a test requires tips for every region. Enemies are intentionally whimsical obstacles, not insults aimed at the player. See [Content guidelines](CONTENT_GUIDELINES.md). The enemy art is in [`enemy_art.dart`](../lib/game/art/enemy_art.dart); several bosses are a recoloured or crowned version of a regular enemy's drawing.

## Equipment

Thirty-six pieces across four slots (head, body, weapon, trinket), one worn per slot: the original eight, and four from each later region. Bonuses stay small, from +1 on the first pieces to +9 at the top, and each region's pieces are a little stronger than the last one's. Gear is found as loot and also sold in the Guild Shop for coins (see [Reward rules](REWARD_RULES.md#coins-and-the-shop)), at prices that rise with the region. Duplicates convert to coins. The pieces from later regions have no hand-drawn art of their own and are drawn on the hero in the colour in their `accent` field.

## Balance status

`test/domain/balance_test.dart` plays 250 seeded expeditions per case with a scripted "sensible" player: no gear, drinks a potion below 35% HP, guards against heavy blows and flurries when hurt, guards instead of wasting a Power Strike on a brace, and uses Power Strike otherwise. At a fork in the road it heals when hurt and takes the bonus otherwise. Win rates at three levels in each region (where it opens, a little later, and well past):

| Region | Win rate at those levels |
| --- | --- |
| 1 | 84%, 93%, 98% |
| 2 | 83%, 88%, 84% |
| 3 | 77%, 70%, 87% |
| 4 | 58%, 75%, 77% |
| 5 | 68%, 61%, 64% |
| 6 | 57%, 52%, 66% |
| 7 | 47%, 63%, 57% |
| 8 | 48%, 56%, 54% |

Real players will have gear (a few points of attack, defense and HP), can read the intent line better than a script, and can drop back to an easier region. The tests only guard the shape: the first region is gentle, no region is a wall (every case above 45%), each region is harder than the one before on average, each step is a noticeable but small drop, and no battle runs past 30 turns. They are a regression guard, not proof of fun. Real playtesting should drive the next tuning pass (see the [roadmap](ROADMAP.md)).

## Extending

- **New enemy:** add an `EnemyTemplate` to `EnemyPool.regular` or `bosses` with the `tier` of its region and a `behavior`, then draw it in `enemy_art.dart` and register the painter. Existing seeds will map to different enemies afterwards, which is fine because only the results of expeditions are stored.
- **New region:** (the Ember Deeps is a worked example) add a `Region` to `Difficulty.regions` (and a `Terrain` and `Biome` if it needs new scenery), give it two bosses, at least three regular enemies and four pieces of gear, a shape in `_shapeFor`, and a shop price for each piece. Check `balance_test.dart` still passes, or extend its table.
- **New item:** add to `ItemCatalog.all`. Never rename or reuse an `id`; it is persisted in the inventory.
- **New action or status effect:** extend `BattleAction` and `BattleEngine.act`, then add tests alongside the existing ones in `test/domain/combat_test.dart`.
- **New visual for an action:** add a `BattleEvent` type in the engine, emit it from `act`, and handle it in `BattleScene.play`. Add a test next to the existing event tests.
