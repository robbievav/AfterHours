-- ============================================================
--  ZoneManager.server.lua  (src/server)
--  Detects which Vibe Zone each player is standing in using
--  CollectionService-tagged trigger parts, then fires the
--  ZoneChanged RemoteEvent to that player's client.
-- ============================================================

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local ZoneChanged: RemoteEvent = ReplicatedStorage.Remotes.ZoneChanged

-- Map: Player → current zone name (string | nil)
local playerZones: { [Player]: string? } = {}

-- ── helpers ──────────────────────────────────────────────────

--[[
	Returns true if `point` is inside the OBB of `part`.
	Works even if the part is rotated.
]]
local function isInsidePart(part: BasePart, point: Vector3): boolean
	local localPoint = part.CFrame:PointToObjectSpace(point)
	local half       = part.Size * 0.5
	return math.abs(localPoint.X) <= half.X
		and math.abs(localPoint.Y) <= half.Y
		and math.abs(localPoint.Z) <= half.Z
end

--[[
	Returns the name of the zone the player's root part is inside,
	or nil if they are not in any tagged zone.
	Priority is determined by CollectionService tag order.
]]
local function detectZone(character: Model): string?
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return nil end

	for _, zonePart in CollectionService:GetTagged("ZoneTrigger") do
		if isInsidePart(zonePart, root.Position) then
			return zonePart.Name
		end
	end
	return nil
end

-- ── main loop ────────────────────────────────────────────────

-- Poll every 0.5 seconds. Sufficient for room-scale zones.
local accumulator = 0
RunService.Heartbeat:Connect(function(dt: number)
	accumulator += dt
	if accumulator < 0.5 then return end
	accumulator = 0

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then continue end

		local newZone = detectZone(character)
		if newZone ~= playerZones[player] then
			playerZones[player] = newZone
			ZoneChanged:FireClient(player, newZone)
		end
	end
end)

-- Clean up on player leave
Players.PlayerRemoving:Connect(function(player: Player)
	playerZones[player] = nil
end)

print("[ZoneManager] Loaded — monitoring", #CollectionService:GetTagged("ZoneTrigger"), "zone triggers.")
