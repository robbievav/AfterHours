-- ============================================================
--  MidnightManager.server.lua  (src/server)
--  Runs a server-side game clock. At midnight (hour 0) it:
--    1. Fires MidnightEvent to all clients (triggers visual FX)
--    2. Unlocks the Boiler Room door
--    3. Spawns Echo Student NPCs at tagged anchor parts
--    4. Activates the payphone with a random lore fragment
--  After OverlapDuration seconds, reverses everything.
-- ============================================================

local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local MidnightConfig = require(ReplicatedStorage.Shared.MidnightConfig)
local MidnightEvent: RemoteEvent = ReplicatedStorage.Remotes.MidnightEvent

-- ── Game Clock ───────────────────────────────────────────────

local gameHour   = 20  -- start at 8 PM in-game
local gameMinute = 0
local clockAccum = 0   -- accumulator in real seconds
local overlapActive = false
local overlapTimer  = 0

local function advanceClock(dt: number)
	clockAccum += dt
	local realSecondsPerMinute = MidnightConfig.SecondsPerHour / 60
	while clockAccum >= realSecondsPerMinute do
		clockAccum -= realSecondsPerMinute
		gameMinute += 1
		if gameMinute >= 60 then
			gameMinute = 0
			gameHour = (gameHour + 1) % 24
		end
	end
end

-- ── Echo Students ────────────────────────────────────────────

local spawnedEchoes: { Model } = {}

local function spawnEchoStudents()
	for _, anchorName in MidnightConfig.EchoAnchors do
		local anchor = workspace:FindFirstChild(anchorName, true)
		if not anchor then continue end

		-- Build a simple translucent mannequin
		local echo = Instance.new("Model")
		echo.Name  = "EchoStudent_" .. anchorName

		local body = Instance.new("Part")
		body.Name         = "HumanoidRootPart"
		body.Size         = Vector3.new(2, 5, 1)
		body.CFrame       = (anchor :: BasePart).CFrame
		body.Anchored     = true
		body.CanCollide   = false
		body.CastShadow   = false
		body.Material     = Enum.Material.Glass
		body.Color        = Color3.fromRGB(200, 220, 255)
		body.Transparency = 0.65
		body.Parent       = echo

		echo.PrimaryPart = body
		echo.Parent      = workspace
		table.insert(spawnedEchoes, echo)
	end
end

local function removeEchoStudents()
	for _, echo in spawnedEchoes do
		echo:Destroy()
	end
	table.clear(spawnedEchoes)
end

-- ── Boiler Room Door ─────────────────────────────────────────
-- The door Part should be named "BoilerRoomDoor" in the workspace
-- and have CanCollide = true during normal hours.

local function setBoilerRoomOpen(open: boolean)
	local door = workspace:FindFirstChild("BoilerRoomDoor", true)
	if door and door:IsA("BasePart") then
		door.CanCollide  = not open
		door.Transparency = open and 1 or 0
	end
end

-- ── Payphone ─────────────────────────────────────────────────

local function activatePayphone()
	local payphone = workspace:FindFirstChild("Payphone", true)
	if not payphone then return end

	-- Pick a random lore fragment
	local loreIds  = MidnightConfig.PayphoneLore
	local randomId = loreIds[math.random(1, #loreIds)]

	local ring = payphone:FindFirstChild("Ring") :: Sound?
	if ring then
		ring.SoundId = randomId
		ring:Play()
	end
end

-- ── Overlap Begin / End ──────────────────────────────────────

local function beginOverlap()
	if overlapActive then return end
	overlapActive = true
	overlapTimer  = 0

	print("[MidnightManager] ⏰ Midnight — The Overlap begins.")

	-- Notify all clients to apply sepia FX
	MidnightEvent:FireAllClients(true)

	-- Server-side world changes
	setBoilerRoomOpen(true)
	spawnEchoStudents()
	activatePayphone()
end

local function endOverlap()
	if not overlapActive then return end
	overlapActive = false

	print("[MidnightManager] 🌅 Overlap ended — world restored.")

	MidnightEvent:FireAllClients(false)
	setBoilerRoomOpen(false)
	removeEchoStudents()
end

-- ── Main Loop ────────────────────────────────────────────────

RunService.Heartbeat:Connect(function(dt: number)
	advanceClock(dt)

	if overlapActive then
		overlapTimer += dt
		if overlapTimer >= MidnightConfig.OverlapDuration then
			endOverlap()
		end
	else
		if gameHour == MidnightConfig.OverlapHour and gameMinute == 0 then
			beginOverlap()
		end
	end
end)

print(string.format(
	"[MidnightManager] Loaded — game clock starts at %02d:%02d. Overlap at hour %d.",
	gameHour, gameMinute, MidnightConfig.OverlapHour
))
