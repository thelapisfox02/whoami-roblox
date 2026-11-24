# LimitedEventCoinsService

The server side of a limited-time event in a client commission. Players collect five coins from two activities. The fifth coin unlocks a cart reward, and a staff member at the venue later records the hand-over of the physical prize by pressing Redeem in a GUI. The service decides what is allowed; the client only asks.

Written by hand, in strict Luau. The client and event names are replaced (the client appears as AmusementPark, the event as LimitedEvent). This copy is shown for review and is not licensed for reuse.

## What to look at

- `Verify` is a pure check that all five slots hold a valid coin. `Redeem` calls it again before it sets the flag, so a forged request from a player who has not collected the coins is rejected. The flag is permanent and nothing in the file ever sets it back to false.
- Coins are stored as `way_timestamp` strings. `Normalize` rebuilds the saved table on every call, so malformed entries and coins from a way that was later removed are scrubbed instead of trusted. It also reads string keys ("1", "2") as a fallback.
- `AddCoin` and `CanAddCoin` enforce an empty slot and a per-way cooldown on the server. `AwardCoin` is the one place a coin is granted, so both sources go through the same checks, and both accepted and rejected attempts are logged. The funnel steps are driven by the resulting total, not by which way granted the coin.
- The cart reward is granted when the fifth coin is gained, and granting it is idempotent: a player who lands there twice does not get a duplicate entry. Redeem grants nothing.
- Analytics are a three-step funnel (PlayerJoined, FirstCoin, LastCoin), keyed by the player's join time so each visit is its own run.

## Not included

`ReplicatedStorage.LimitedEventInfo` (the config: `Ways`, `MaxCoins`, `DefaultCooldown`) and the profile object, which needs `GetData`, `SetBooleanValue` and `InsertToArray`. The file is a single module, so it will not run on its own.

There are no automated tests for this file.
