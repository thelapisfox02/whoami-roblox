--!strict
-- REDACTED COPY for portfolio use. Client and event names are replaced (AmusementPark / LimitedEvent).
-- External dependencies, not included here: ReplicatedStorage.LimitedEventInfo (config: Ways, MaxCoins,
-- DefaultCooldown) and a profile object exposing GetData / SetBooleanValue / InsertToArray.
--
-- Backend helpers for LimitedEvent collectible coins.
-- LimitedEventCompleted means REDEEMED -- a venue staff member pressed "Redeem" in the GUI and
-- handed the prize over. It does NOT mean "has 5 coins": that is Verify, a pure check.
-- Only Redeem sets the flag, and it is permanent -- nothing here ever sets it false.
-- If a way is removed from LimitedEventInfo.Ways later, Normalize scrubs those coins but
-- will not un-redeem players who already collected their prize.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

local LimitedEventInfo = require(ReplicatedStorage:WaitForChild("LimitedEventInfo"))

local LimitedEventCoinsService = {}

-- Funnel: PlayerJoined -> FirstCoin -> LastCoin. Session id is the player's join
-- timestamp, matching the "Rewards" funnel, so each visit is its own funnel run.
local FUNNEL_NAME = "EventCoins"
local FUNNEL_STEPS = {
	PlayerJoined = 1,
	FirstCoin = 2,
	LastCoin = 3,
}

local function logFunnelStep(player: Player, stepName: string)
	local step = FUNNEL_STEPS[stepName]
	if not step then
		return
	end

	local sessionId = player:GetAttribute("_JOIN_TIME")
	local ok, err = pcall(function()
		AnalyticsService:LogFunnelStepEvent(player, FUNNEL_NAME, tostring(sessionId), step, stepName)
	end)
	if not ok then
		warn(`[LimitedEventCoinsService] > Funnel step {stepName} failed for {player}: {err}`)
	end
end

-- Step 1. Called once per session from the join callback.
function LimitedEventCoinsService.LogJoinFunnelStep(player: Player)
	logFunnelStep(player, "PlayerJoined")
end

-- Collecting the fifth coin is what pays out the cart skin -- redeeming deliberately
-- grants nothing, it is only the staff hand-over of the physical prize.
local REWARD_CART_ID = "LimitedEventCart"

local function parseCoin(value: any): (string?, number?)
	if type(value) ~= "string" then
		return nil, nil
	end

	local way, timestamp = value:match("^(.+)_(%d+)$")
	if not way or not timestamp then
		return nil, nil
	end

	if not LimitedEventInfo.Ways[way] then
		return nil, nil
	end

	return way, tonumber(timestamp)
end

local function isValidCoin(value: any): boolean
	local way, timestamp = parseCoin(value)
	return way ~= nil and timestamp ~= nil
end

local function getCooldownRemainingFromCoins(coins, way: string): number
	local latest = nil
	for i = 1, LimitedEventInfo.MaxCoins do
		local slotWay, timestamp = parseCoin(coins[i])
		if slotWay == way and timestamp and (not latest or timestamp > latest) then
			latest = timestamp
		end
	end

	if not latest then
		return 0
	end

	local cooldown = LimitedEventInfo.Ways[way].Cooldown or LimitedEventInfo.DefaultCooldown
	local elapsed = os.time() - latest
	if elapsed >= cooldown then
		return 0
	end

	return cooldown - elapsed
end

function LimitedEventCoinsService.Normalize(profile)
	local data = profile:GetData()
	local coins = data.LimitedEventCoins
	if type(coins) ~= "table" then
		coins = {}
	end

	local rebuilt = {}
	for i = 1, LimitedEventInfo.MaxCoins do
		local value = coins[i]
		if value == nil then
			value = coins[tostring(i)]
		end

		if isValidCoin(value) then
			rebuilt[i] = value
		else
			rebuilt[i] = false
		end
	end

	data.LimitedEventCoins = rebuilt
	return rebuilt
end

function LimitedEventCoinsService.GetCoins(profile)
	local coins = LimitedEventCoinsService.Normalize(profile)
	local copy = {}
	for i = 1, LimitedEventInfo.MaxCoins do
		copy[i] = coins[i]
	end
	return copy
end

function LimitedEventCoinsService.CountCoins(profile): number
	local coins = LimitedEventCoinsService.Normalize(profile)
	local count = 0
	for i = 1, LimitedEventInfo.MaxCoins do
		if type(coins[i]) == "string" then
			count += 1
		end
	end
	return count
end

function LimitedEventCoinsService.IsCompleted(profile): boolean
	local data = profile:GetData()
	LimitedEventCoinsService.Normalize(profile)
	return data.LimitedEventCompleted == true
end

function LimitedEventCoinsService.GetCooldownRemaining(profile, way: string): number
	local coins = LimitedEventCoinsService.Normalize(profile)
	if type(way) ~= "string" or not LimitedEventInfo.Ways[way] then
		return 0
	end

	return getCooldownRemainingFromCoins(coins, way)
end

function LimitedEventCoinsService.CanAddCoin(profile, way: string): (boolean, string?)
	local coins = LimitedEventCoinsService.Normalize(profile)
	if type(way) ~= "string" or not LimitedEventInfo.Ways[way] then
		return false, "INVALID_WAY"
	end

	local hasEmptySlot = false
	for i = 1, LimitedEventInfo.MaxCoins do
		if coins[i] == false then
			hasEmptySlot = true
			break
		end
	end

	if not hasEmptySlot then
		return false, "FULL"
	end

	if getCooldownRemainingFromCoins(coins, way) > 0 then
		return false, "COOLDOWN"
	end

	return true
end

function LimitedEventCoinsService.AddCoin(profile, way: string): (boolean, any, number?)
	local coins = LimitedEventCoinsService.Normalize(profile)
	if type(way) ~= "string" or not LimitedEventInfo.Ways[way] then
		return false, "INVALID_WAY"
	end

	local emptyIndex = nil
	for i = 1, LimitedEventInfo.MaxCoins do
		if coins[i] == false then
			emptyIndex = i
			break
		end
	end

	if not emptyIndex then
		return false, "FULL"
	end

	local remaining = getCooldownRemainingFromCoins(coins, way)
	if remaining > 0 then
		return false, "COOLDOWN", remaining
	end

	coins[emptyIndex] = way .. "_" .. os.time()
	return true, emptyIndex
end

function LimitedEventCoinsService.RemoveCoin(profile, target: any): (boolean, any, any?)
	local coins = LimitedEventCoinsService.Normalize(profile)
	local index = nil

	if type(target) == "number" then
		if target % 1 ~= 0 or target < 1 or target > LimitedEventInfo.MaxCoins then
			return false, "OUT_OF_RANGE"
		end

		if type(coins[target]) ~= "string" then
			return false, "EMPTY"
		end

		index = target
	elseif type(target) == "string" then
		for i = 1, LimitedEventInfo.MaxCoins do
			if coins[i] == target then
				index = i
				break
			end
		end

		if not index then
			local latest = nil
			for i = 1, LimitedEventInfo.MaxCoins do
				local way, timestamp = parseCoin(coins[i])
				if way == target and timestamp and (not latest or timestamp > latest) then
					latest = timestamp
					index = i
				end
			end
		end

		if not index then
			return false, "NOT_FOUND"
		end
	else
		return false, "NOT_FOUND"
	end

	local removedValue = coins[index]
	coins[index] = false
	return true, index, removedValue
end

-- True when all five slots hold a coin from an accepted way. Does not mutate anything
-- beyond Normalize's scrubbing -- this is the gate Redeem checks, not a state change.
function LimitedEventCoinsService.Verify(profile): boolean
	local coins = LimitedEventCoinsService.Normalize(profile)
	for i = 1, LimitedEventInfo.MaxCoins do
		if not isValidCoin(coins[i]) then
			return false
		end
	end

	return true
end

-- Marks the collection as redeemed. Server-authoritative: the client may ask, but the
-- five coins are re-checked here, so a forged request from a player who has not
-- collected them all is rejected.
function LimitedEventCoinsService.Redeem(profile): (boolean, string?)
	local data = profile:GetData()

	if data.LimitedEventCompleted == true then
		return false, "ALREADY_REDEEMED"
	end

	if not LimitedEventCoinsService.Verify(profile) then
		return false, "INCOMPLETE"
	end

	profile:SetBooleanValue("LimitedEventCompleted", true)
	return true
end

-- Mirrors the coin total onto the player so the HUD counter can follow it live without
-- polling the RemoteFunction. Call this whenever the count can have changed.
function LimitedEventCoinsService.PublishCount(player: Player, profile)
	player:SetAttribute("LimitedEventCoinCount", LimitedEventCoinsService.CountCoins(profile))
end

-- Redeeming is permanent, so this attribute only ever goes false -> true. Published so the
-- client can retire the LimitedEvent event props for a player whose prize has been handed over.
-- Call it on join and after every successful Redeem.
function LimitedEventCoinsService.PublishCompleted(player: Player, profile)
	player:SetAttribute("LimitedEventCompleted", LimitedEventCoinsService.IsCompleted(profile))
end

-- Fired the moment the collection is completed by gaining a coin, so the client can show
-- the two completion popups. Granting the cart is idempotent: a player who somehow lands
-- here twice does not end up with a duplicate entry in OwnedVehicles.
local function grantCompletionReward(player: Player, profile)
	local owned = profile:GetData().OwnedVehicles
	if type(owned) == "table" and not table.find(owned, REWARD_CART_ID) then
		profile:InsertToArray("OwnedVehicles", REWARD_CART_ID)
	end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local remote = remotes and remotes:FindFirstChild("LimitedEventCollectionComplete")
	if remote and remote:IsA("RemoteEvent") then
		remote:FireClient(player, REWARD_CART_ID)
	else
		warn("[LimitedEventCoinsService] > Missing ReplicatedStorage.Remotes.LimitedEventCollectionComplete")
	end
end

-- The single place a coin is granted. Both gain sources (PARKOUR, SURVEY) go through here so
-- the analytics event is emitted exactly once per attempt, successful or not.
-- Returns the same tuple as AddCoin: (ok, indexOrReason, cooldownRemaining?)
function LimitedEventCoinsService.AwardCoin(player: Player, profile, way: string): (boolean, any, number?)
	local ok, indexOrReason, remaining = LimitedEventCoinsService.AddCoin(profile, way)

	if ok then
		local total = LimitedEventCoinsService.CountCoins(profile)
		player:SetAttribute("LimitedEventCoinCount", total)
		AnalyticsService:LogCustomEvent(player, "LimitedEvent Coin Gained", 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = way,
			[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = tostring(total),
		})

		-- Funnel steps are driven by the resulting total, so they fire exactly once
		-- each no matter which way granted the coin.
		if total == 1 then
			logFunnelStep(player, "FirstCoin")
		end

		if total >= LimitedEventInfo.MaxCoins then
			logFunnelStep(player, "LastCoin")
			grantCompletionReward(player, profile)
		end
	else
		warn(`[LimitedEventCoinsService] > Coin not awarded to {player}: {way} / {indexOrReason}`)
		AnalyticsService:LogCustomEvent(player, "LimitedEvent Coin Rejected", 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = way,
			[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = tostring(indexOrReason),
		})
	end

	return ok, indexOrReason, remaining
end

return LimitedEventCoinsService
