-- ============================================================
--  BoomboxManager.server.lua  (src/server)
--  Manages the Boombox Relay frequency system.
--  Players on the same frequency (1-5) share the same
--  ambient music track. Server validates and syncs freq changes.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BoomboxFrequency: RemoteEvent = ReplicatedStorage.Remotes.BoomboxFrequency

local MIN_FREQ = 1
local MAX_FREQ = 5

-- Map: player → frequency (nil = no boombox equipped)
local playerFreq: { [Player]: number? } = {}

-- Map: frequency → list of players on it
local freqPlayers: { [number]: { Player } } = {}
for i = MIN_FREQ, MAX_FREQ do
	freqPlayers[i] = {}
end

local function removeFromFreq(player: Player)
	local freq = playerFreq[player]
	if not freq then return end
	local list = freqPlayers[freq]
	for i, p in list do
		if p == player then
			table.remove(list, i)
			break
		end
	end
	playerFreq[player] = nil
end

local function broadcastFreqUpdate(freq: number)
	local names = {}
	for _, p in freqPlayers[freq] do
		table.insert(names, p.DisplayName)
	end
	for _, p in freqPlayers[freq] do
		BoomboxFrequency:FireClient(p, "FreqUpdate", freq, names)
	end
end

-- ── Remote Handler ───────────────────────────────────────────
-- Actions: "SetFreq" (number 1-5), "ClearFreq"

BoomboxFrequency.OnServerEvent:Connect(function(player: Player, action: string, ...)
	local args = { ... }

	if action == "SetFreq" then
		local newFreq = math.clamp(math.floor(tonumber(args[1]) or 1), MIN_FREQ, MAX_FREQ)
		local oldFreq = playerFreq[player]

		if oldFreq == newFreq then return end -- no change

		-- Leave old frequency
		if oldFreq then
			removeFromFreq(player)
			broadcastFreqUpdate(oldFreq)
		end

		-- Join new frequency
		playerFreq[player] = newFreq
		table.insert(freqPlayers[newFreq], player)
		broadcastFreqUpdate(newFreq)

		-- Confirm to the setting player
		BoomboxFrequency:FireClient(player, "FreqSet", newFreq)

	elseif action == "ClearFreq" then
		local oldFreq = playerFreq[player]
		if oldFreq then
			removeFromFreq(player)
			broadcastFreqUpdate(oldFreq)
		end
		BoomboxFrequency:FireClient(player, "FreqCleared")
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	local oldFreq = playerFreq[player]
	removeFromFreq(player)
	if oldFreq then
		broadcastFreqUpdate(oldFreq)
	end
end)

print("[BoomboxManager] Loaded — frequencies", MIN_FREQ, "through", MAX_FREQ, "active.")
