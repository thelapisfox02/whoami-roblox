--!nonstrict
-- Case study: exact expected-value model of the live catch logic, used to check bait pricing.
-- Read-only: requires the place's own data modules and computes. Writes nothing to the datamodel.
-- Run in Studio (Edit) via execute_luau in the Fish In A Pond development place.
--
-- Mirrors StarterPack.rodTool.FishingRod_Server (RandomFish, GetRandomMutations, weight roll)
-- and FishFunctions:CalculateWorth. Assumptions are listed in bait-model-results.md.

local RS = game:GetService("ReplicatedStorage")
local Pools = require(RS.CurrentPools)
local pool = Pools:GetPool("NormalPondFish")
local Mut = require(RS.Dictionaries.FishSkinThemes)
local baits = Pools:GetPool("BaitShop")
local N = #pool
local out = {}

-- Fish ladder, exact. Live code walks the pool in order; fish i passes if a coin flip succeeds
-- OR random()*(i-1) <= luck; the walk stops at the first failure and the last pass is the catch.
-- P(pass j) = 0.5 + 0.5 * min(1, L/(j-1)); fish 1 always passes.
local function ladder(L)
	local P, reach = {}, 1
	for i = 1, N do
		local pnext = (i < N) and (0.5 + 0.5 * math.min(1, L / i)) or 0
		P[i] = reach * (1 - pnext)
		reach *= pnext
	end
	return P
end

-- Mutations, exact over all 2^8 subsets. Each mutation hits when a geometric "roll" >= Rarity,
-- which has probability 0.5^(Rarity-1). Exclusion cleaning is a copy of the live function.
local ids = {}
for id in pairs(Mut) do ids[#ids + 1] = id end
table.sort(ids)

local function clean(list)
	local best = {}
	for _, id in ipairs(list) do if Mut[id] then best[id] = true end end
	for a in pairs(best) do
		for b in pairs(best) do
			if a ~= b then
				local A, B = Mut[a], Mut[b]
				if table.find(A.Exludes, b) or table.find(B.Exludes, a) then
					if A.Multiplier > B.Multiplier then best[b] = nil
					elseif B.Multiplier > A.Multiplier then best[a] = nil
					else best[b] = nil end
				end
			end
		end
	end
	local k = {}
	for id in pairs(best) do k[#k + 1] = id end
	return k
end

local Emult, Pany = 0, 0
for mask = 0, (2 ^ #ids) - 1 do
	local p, chosen = 1, {}
	for bit, id in ipairs(ids) do
		local pi = 0.5 ^ (Mut[id].Rarity - 1)
		if math.floor(mask / 2 ^ (bit - 1)) % 2 == 1 then p *= pi chosen[#chosen + 1] = id else p *= (1 - pi) end
	end
	local kept = clean(chosen)
	local s = 1
	for _, id in ipairs(kept) do s += Mut[id].Multiplier end
	Emult += p * s
	if #kept > 0 then Pany += p end
end
out[#out + 1] = string.format("E[mutation multiplier]=%.4f  P(any mutation)=%.4f", Emult, Pany)

-- Weight factor: Monte Carlo, seeded so the run is reproducible.
local rng = Random.new(20261121)
local function wmult()
	local sign = (rng:NextInteger(0, 1) == 1) and 1 or -1
	local W = math.max((sign * rng:NextNumber() + 0.55 + 1) * ((rng:NextNumber() < 0.005) and rng:NextNumber() * 2 or 1), 0.4)
	return math.max(1, W * 0.25 + 0.75) -- CalculateWorth: max(1, (Weight/BaseWeight)*.25 + .75)
end
local sw, M = 0, 200000
for _ = 1, M do sw += wmult() end
local Ew = sw / M
out[#out + 1] = string.format("E[weight value factor]=%.4f (%d draws)", Ew, M)

-- Value = BaseValue * (1 + sum(mutation mult)) * weightFactor; the three are independent,
-- so the expectation is the product of expectations.
local function EV(L)
	local P = ladder(L)
	local s = 0
	for i = 1, N do s += P[i] * pool[i].BaseValue end
	return s * Emult * Ew, P
end

-- Cross-check: simulate the ladder exactly as the live code does, 20,000 casts.
local function mcLadder(L, casts)
	local sum = 0
	for _ = 1, casts do
		local prev
		for i = 1, N do
			local checkPassed = rng:NextInteger(0, 1) == 1
			local luckPassed = rng:NextNumber() * (i - 1) <= L
			if not checkPassed and not luckPassed then break end
			prev = i
		end
		sum += pool[prev].BaseValue
	end
	return sum / casts
end

for _, L in ipairs({ 0.75, 5.5 }) do
	local _, P = EV(L)
	local analytic = 0
	for i = 1, N do analytic += P[i] * pool[i].BaseValue end
	out[#out + 1] = string.format("LADDER CHECK L=%.2f analytic=%.2f MC(20k)=%.2f", L, analytic, mcLadder(L, 20000))
	task.wait()
end

local ev0 = EV(0)
out[#out + 1] = string.format("EV per cast, luck 0 = %.2f", ev0)
out[#out + 1] = "bait | price | luck | secs | EV/cast | gain/cast | breakeven casts"
for _, b in ipairs(baits) do
	local L = b.Luck.Amount
	local gain = EV(L) - ev0
	out[#out + 1] = string.format("%-13s %8d %4.2f %4d %9.1f %9.1f %8.1f", b.Id, b.Price, L, b.Luck.Time, EV(L), gain, b.Price / gain)
end
return table.concat(out, "\n")
