-- ============================================================
--  DJBoothManager.server.lua  (src/server)
--  Manages the shared DJ Booth interaction.
--  Up to 4 players can each claim a "deck slot" and control
--  one layer of the music. Changes are broadcast server-wide.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DJBooth: RemoteEvent = ReplicatedStorage.Remotes.DJBooth

-- Deck state: 4 slots, each holds a track selection (1-8) and volume (0-1)
local NUM_SLOTS = 4
export type SlotState = { player: string?, track: number, volume: number }
local slots: { SlotState } = {}
for i = 1, NUM_SLOTS do
	slots[i] = { player = nil, track = 1, volume = 0.5 }
end

-- Map player → claimed slot index
local playerSlot: { [Player]: number } = {}

local function broadcastState()
	local snapshot = {}
	for i, slot in slots do
		snapshot[i] = {
			player = slot.player,
			track  = slot.track,
			volume = slot.volume,
		}
	end
	for _, p in Players:GetPlayers() do
		DJBooth:FireClient(p, "StateUpdate", snapshot)
	end
end

local function releaseSlot(player: Player)
	local idx = playerSlot[player]
	if not idx then return end
	slots[idx].player = nil
	playerSlot[player] = nil
	broadcastState()
end

-- ── Remote Handler ───────────────────────────────────────────
-- Actions: "Claim", "Release", "SetTrack", "SetVolume"

DJBooth.OnServerEvent:Connect(function(player: Player, action: string, ...)
	local args = { ... }

	if action == "Claim" then
		if playerSlot[player] then return end -- already holding a slot
		-- Find first free slot
		for i, slot in slots do
			if slot.player == nil then
				slots[i].player = player.DisplayName
				playerSlot[player] = i
				broadcastState()
				return
			end
		end
		-- All slots taken — notify player
		DJBooth:FireClient(player, "SlotsFull")

	elseif action == "Release" then
		releaseSlot(player)

	elseif action == "SetTrack" then
		local idx = playerSlot[player]
		if not idx then return end
		local track = math.clamp(math.floor(tonumber(args[1]) or 1), 1, 8)
		slots[idx].track = track
		broadcastState()

	elseif action == "SetVolume" then
		local idx = playerSlot[player]
		if not idx then return end
		local vol = math.clamp(tonumber(args[1]) or 0.5, 0, 1)
		slots[idx].volume = vol
		broadcastState()
	end
end)

Players.PlayerRemoving:Connect(releaseSlot)

-- Send current state to new players
Players.PlayerAdded:Connect(function(player: Player)
	task.wait(2)
	broadcastState()
end)

print("[DJBoothManager] Loaded —", NUM_SLOTS, "deck slots ready.")
