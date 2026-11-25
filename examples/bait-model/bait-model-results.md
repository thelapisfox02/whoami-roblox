# Bait pricing model: results (run 2026-11-21, Fish In A Pond development place)

Script: `bait-model.luau` (same folder). Read-only; reads the place's real pool, mutation and bait data.
Reduced run: 20,000-cast Monte Carlo cross-check, 200,000 weight draws. Expected value is solved exactly, so the
table below is not sampling noise.

## Validation (analytic vs simulated, base value per cast)
| Luck | Analytic | Monte Carlo (20k casts) |
|---|---|---|
| 0.75 | 39.00 | 38.02 |
| 5.50 | 1,522.57 | 1,520.21 |

## Components
- Mutations: expected multiplier 1.6342; 20.47% of catches carry at least one.
- Weight factor on value: 1.1504.
- Expected value per cast at luck 0: **35.11**.

## Per bait (additive luck, timed)
| Bait | Price | Luck | Seconds | EV / cast | Gain / cast | Casts to break even |
|---|---|---|---|---|---|---|
| PondMuck | 10 | 0.20 | 30 | 41.9 | 6.8 | 1.5 |
| CrumbChunk | 50 | 0.20 | 120 | 41.9 | 6.8 | 7.4 |
| GooNibble | 150 | 0.20 | 300 | 41.9 | 6.8 | 22.2 |
| BeetleBits | 500 | 0.75 | 30 | 73.3 | 38.2 | 13.1 |
| LeafyLure | 1,000 | 0.75 | 120 | 73.3 | 38.2 | 26.2 |
| SapCrunch | 2,000 | 0.75 | 300 | 73.3 | 38.2 | 52.3 |
| Bubbleberry | 3,500 | 2.00 | 30 | 233.4 | 198.3 | 17.6 |
| SnowNibble | 6,000 | 2.00 | 120 | 233.4 | 198.3 | 30.3 |
| ZaprootMorsel | 7,500 | 2.00 | 300 | 233.4 | 198.3 | 37.8 |
| WaffleWorm | 11,000 | 3.50 | 30 | 752.9 | 717.8 | 15.3 |
| RioGrandeBite | 25,000 | 3.50 | 120 | 752.9 | 717.8 | 34.8 |
| FlamebeetCore | 200,000 | 3.50 | 300 | 752.9 | 717.8 | 278.6 |
| Gemslug | 700,000 | 5.50 | 30 | 2,862.5 | 2,827.4 | 247.6 |
| Whisperegg | 1,000,000 | 5.50 | 120 | 2,862.5 | 2,827.4 | 353.7 |
| GoldenNibble | 2,500,000 | 5.50 | 300 | 2,862.5 | 2,827.4 | 884.2 |

## Payback inside the bait's own time window
Break-even casts (table above) say nothing until compared with how many casts a window holds. From the server rod
script: one cycle is at least a 3 s bite wait plus 0.75 s reel-in = 3.75 s, before the casting animation. The
upgrade tree can shorten bite wait by 15% and reel-in by 30% (cycle about 3.1 s) and lengthen bait time by 20%.

Payback ratio = expected fish value earned during the window / bait price. Below 1.0 the bait loses doubloons even
if the player fishes the entire window.

| Bait | Price | Window s | 3.75 s/cast | 6 s/cast | 10 s/cast | Upgrades maxed |
|---|---|---|---|---|---|---|
| PondMuck | 10 | 30 | 5.44 | 3.40 | 2.04 | 7.96 |
| CrumbChunk | 50 | 120 | 4.35 | 2.72 | 1.63 | 6.37 |
| GooNibble | 150 | 300 | 3.63 | 2.27 | 1.36 | 5.31 |
| BeetleBits | 500 | 30 | 0.61 | 0.38 | 0.23 | 0.89 |
| LeafyLure | 1,000 | 120 | 1.22 | 0.76 | 0.46 | 1.79 |
| SapCrunch | 2,000 | 300 | 1.53 | 0.96 | 0.57 | 2.24 |
| Bubbleberry | 3,500 | 30 | 0.45 | 0.28 | 0.17 | 0.66 |
| SnowNibble | 6,000 | 120 | 1.06 | 0.66 | 0.40 | 1.55 |
| ZaprootMorsel | 7,500 | 300 | 2.12 | 1.32 | 0.79 | 3.10 |
| WaffleWorm | 11,000 | 30 | 0.52 | 0.33 | 0.20 | 0.76 |
| RioGrandeBite | 25,000 | 120 | 0.92 | 0.57 | 0.34 | 1.34 |
| FlamebeetCore | 200,000 | 300 | 0.29 | 0.18 | 0.11 | 0.42 |
| Gemslug | 700,000 | 30 | 0.03 | 0.02 | 0.01 | 0.05 |
| Whisperegg | 1,000,000 | 120 | 0.09 | 0.06 | 0.03 | 0.13 |
| GoldenNibble | 2,500,000 | 300 | 0.09 | 0.06 | 0.03 | 0.13 |

- Seven of fifteen baits lose doubloons even with every relevant upgrade bought: BeetleBits, Bubbleberry, WaffleWorm,
  FlamebeetCore, Gemslug, Whisperegg, GoldenNibble. At luck 0.75, 2 and 5.5 the 30 s bait is the weakest of its tier;
  at luck 3.5 it is the 300 s FlamebeetCore.
- Gemslug, Whisperegg and GoldenNibble return 5 to 13 cents per doubloon at best, FlamebeetCore 42. Selling bonuses
  do not rescue them: payout is value x (1 + friends on server / 10) x 1.15 for VIP x the MoneyStacker multiplier,
  so the three would need a combined bonus of about 8x to 20x and FlamebeetCore about 2.4x.
- Healthy even at 6 s per cast: the whole luck-0.2 tier (2.3 to 3.4) and ZaprootMorsel (1.3). Marginal at the 3.75 s
  floor, below 1.0 at 6 s: LeafyLure, SapCrunch, SnowNibble. RioGrandeBite is below 1.0 even at the floor.
- Not measured: real casts per second (casting animation and charge time are client-side and not in this model).
  The 6 s and 10 s columns are sensitivity cases, not observations.

## Repricing lever (a design option, not a recommendation)
Price = k x casts in window (at 6 s/cast) x gain per cast, where k is the share of expected earnings the bait costs.
| Bait | Now | k = 0.25 | k = 0.5 | k = 0.75 |
|---|---|---|---|---|
| PondMuck | 10 | 8 | 17 | 26 |
| CrumbChunk | 50 | 34 | 68 | 102 |
| GooNibble | 150 | 85 | 170 | 255 |
| BeetleBits | 500 | 48 | 96 | 143 |
| LeafyLure | 1,000 | 191 | 382 | 573 |
| SapCrunch | 2,000 | 478 | 955 | 1,433 |
| Bubbleberry | 3,500 | 248 | 496 | 744 |
| SnowNibble | 6,000 | 992 | 1,983 | 2,974 |
| ZaprootMorsel | 7,500 | 2,479 | 4,958 | 7,436 |
| WaffleWorm | 11,000 | 897 | 1,794 | 2,692 |
| RioGrandeBite | 25,000 | 3,589 | 7,178 | 10,767 |
| FlamebeetCore | 200,000 | 8,972 | 17,945 | 26,918 |
| Gemslug | 700,000 | 3,534 | 7,068 | 10,603 |
| Whisperegg | 1,000,000 | 14,137 | 28,274 | 42,411 |
| GoldenNibble | 2,500,000 | 35,342 | 70,685 | 106,028 |

Before changing anything, check what these baits are for. Every bait has a Robux developer product, so the doubloon
price may be a deliberate sink that nudges purchases toward Robux. Repricing would change revenue as well as
balance. The analytics events already logged (bait used, economy sink events) can show how often each bait is
actually bought with doubloons.

## Other readings
- The old `STUDIO_ONLY.Simulations` script priced a bait at 80% of one cast's gain. That fits a one-cast bait. Live
  baits are timed, so the rule no longer matches. The old script also reads fields that no longer exist
  (`Chance` on fish entries, rod attributes, a numeric `bait.Luck`), so it errors on its first roll.
- Different bait tiers use different luck ids and add together; the same id extends time instead. A player holding
  two tiers has more luck than any row above. This model values one bait at a time.

## Assumptions and limits
1. Pond: `NormalPondFish` (24 fish). Rain and night pools not modelled.
2. Base luck 0 (player template). Permanent luck sources or other timed luck would shift every row.
3. Default bobber (no weight-chance bonus). Fish value is `CalculateWorth`; sale bonuses described above are not in
   the tables.
4. Weight factor is a seeded Monte Carlo (200,000 draws); everything else is exact. Payback tables are arithmetic on
   those numbers (gain per cast x casts per window / price).
5. Only fishing income is counted. Quests, gifts and daily rewards also add doubloons.
