# Bait model

A case study from Fish In A Pond. The question was whether each timed luck bait pays for itself.

Built with AI tooling, directed and checked by me. The script is read-only: it requires the place's own data modules, solves the expected value of a cast exactly, and writes nothing to the datamodel. Run it in Studio (Edit) in the place it was written for.

## Files

- `bait-model.luau` is the script.
- `bait-model-results.md` has the run of 2026-11-21: validation, per-bait table, assumptions and a pricing lever table.

## What it found

- The model rebuilds the live catch logic: a rarity ladder, eight mutations with exclusion rules, and a weight roll.
- A 20,000-cast simulation agrees with the exact result (1,522.6 against 1,520.2 at luck 5.5, and 39.0 against 38.0 at luck 0.75).
- Expected fish value per cast rises from 35 with no luck to 73, 233, 753 and 2,863 at luck 0.75, 2, 3.5 and 5.5.
- Set against each bait's own time window, seven of the fifteen baits cost more than a player can earn from them, even with every upgrade bought. No prices were changed: every bait also has a Robux product, so the doubloon price may be a deliberate sink.

The older pricing script predated timed baits and referenced fields that no longer exist, which is why this one replaces it.
