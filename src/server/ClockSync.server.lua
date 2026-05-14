-- ============================================================
--  ClockSync.server.lua  (src/server)
--  Sends the current in-game hour/minute to clients every
--  30 seconds so HUD clocks stay in sync without each client
--  running its own independent clock drift.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local MidnightConfig = require(ReplicatedStorage.Shared.MidnightConfig)
local ClockSync: RemoteEvent = ReplicatedStorage.Remotes.ClockSync

-- Mirror the same clock state from MidnightManager
-- We expose a module-level table that MidnightManager writes to.
-- Since both scripts run in the same VM, we share via a BindableEvent
-- approach instead — ClockSync just reads Lighting.ClockTime which
-- MidnightManager keeps updated.

local SYNC_INTERVAL = 30  -- seconds between full syncs

local syncAccum = 0

RunService.Heartbeat:Connect(function(dt: number)
	syncAccum += dt
	if syncAccum < SYNC_INTERVAL then return end
	syncAccum = 0

	-- Lighting.ClockTime is 0–24 (set by MidnightManager)
	local clockTime = game.Lighting.ClockTime  -- e.g. 20.5 = 8:30 PM
	local hour      = math.floor(clockTime)
	local minute    = math.floor((clockTime - hour) * 60)

	ClockSync:FireAllClients(hour, minute)
end)

-- Also sync immediately when a player joins
Players.PlayerAdded:Connect(function(player: Player)
	task.wait(3) -- wait for client to load
	local clockTime = game.Lighting.ClockTime
	local hour      = math.floor(clockTime)
	local minute    = math.floor((clockTime - hour) * 60)
	ClockSync:FireClient(player, hour, minute)
end)

print("[ClockSync] Loaded — syncing every", SYNC_INTERVAL, "seconds.")
