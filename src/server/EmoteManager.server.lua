-- ============================================================
--  EmoteManager.server.lua  (src/server)
--  Receives emote requests from clients, validates them,
--  then replicates to all other players so animations play
--  on the correct character on every client.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EmoteConfig = require(ReplicatedStorage.Shared.EmoteConfig)
local EmoteChanged: RemoteEvent = ReplicatedStorage.Remotes.EmoteChanged

-- Rate limit: 1 emote per 1.5 seconds per player
local COOLDOWN = 1.5
local lastEmoteTime: { [Player]: number } = {}

-- Track active looping emote per player (so we can stop them)
local activeEmote: { [Player]: string? } = {}

local function isValidEmote(name: string): boolean
	return EmoteConfig[name] ~= nil and not name:sub(1, 1):match("_")
end

EmoteChanged.OnServerEvent:Connect(function(player: Player, action: string, emoteName: string?)
	local now = os.clock()

	if action == "Play" then
		if not emoteName or not isValidEmote(emoteName) then return end

		-- Rate limit
		local last = lastEmoteTime[player] or 0
		if now - last < COOLDOWN then return end
		lastEmoteTime[player] = now

		activeEmote[player] = emoteName

		-- Fire to ALL clients (including sender so their local anim plays cleanly)
		EmoteChanged:FireAllClients(player, "Play", emoteName)

	elseif action == "Stop" then
		activeEmote[player] = nil
		EmoteChanged:FireAllClients(player, "Stop", nil)
	end
end)

-- Stop emote when player dies or leaves
local function onCharacterAdded(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	humanoid.Died:Connect(function()
		-- find which player this belongs to
		for _, p in Players:GetPlayers() do
			if p.Character == character then
				activeEmote[p] = nil
				EmoteChanged:FireAllClients(p, "Stop", nil)
				break
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastEmoteTime[player] = nil
	activeEmote[player]   = nil
end)

print("[EmoteManager] Loaded —", (function()
	local count = 0
	for k, v in EmoteConfig do
		if type(k) ~= "string" or k:sub(1,1) == "_" then continue end
		if type(v) == "table" then count += 1 end
	end
	return count
end)(), "emotes registered.")
