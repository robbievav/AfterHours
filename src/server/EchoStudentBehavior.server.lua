-- ============================================================
--  EchoStudentBehavior.server.lua  (src/server)
--  Gives Echo Students a subtle "awareness" behavior —
--  they slowly turn their head toward the nearest player,
--  then look away when that player gets too close.
--  Runs only during the Midnight Overlap.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local MidnightEvent: RemoteEvent = ReplicatedStorage.Remotes.MidnightEvent

local NOTICE_RANGE  = 30  -- studs — echo "notices" player within this range
local FEAR_RANGE    = 6   -- studs — echo looks away if player gets this close
local TURN_SPEED    = 0.04 -- CFrame lerp alpha per heartbeat tick (smooth)
local UPDATE_RATE   = 0.1  -- seconds between position checks

local overlapActive = false
local echoStudents: { Model } = {}
local accumulator   = 0

-- ── Collect spawned echoes ────────────────────────────────────
-- MidnightManager parents echoes to workspace with name "EchoStudent_*"

local function refreshEchoList()
	table.clear(echoStudents)
	for _, obj in workspace:GetChildren() do
		if obj:IsA("Model") and obj.Name:sub(1, 12) == "EchoStudent_" then
			table.insert(echoStudents, obj)
		end
	end
end

-- ── Per-frame update ─────────────────────────────────────────

RunService.Heartbeat:Connect(function(dt: number)
	if not overlapActive then return end

	accumulator += dt
	if accumulator < UPDATE_RATE then return end
	accumulator = 0

	for _, echo in echoStudents do
		local root = echo:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then continue end

		local echoPos   = root.Position
		local bestDist  = math.huge
		local bestPos   : Vector3? = nil

		-- Find nearest player root
		for _, player in Players:GetPlayers() do
			local char = player.Character
			if not char then continue end
			local pRoot = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not pRoot then continue end

			local dist = (pRoot.Position - echoPos).Magnitude
			if dist < bestDist then
				bestDist = dist
				bestPos  = pRoot.Position
			end
		end

		if bestPos and bestDist <= NOTICE_RANGE then
			local targetCFrame: CFrame

			if bestDist <= FEAR_RANGE then
				-- Player too close — look away (rotate 180°)
				local awayDir = (echoPos - bestPos).Unit
				targetCFrame  = CFrame.lookAt(echoPos, echoPos + awayDir)
			else
				-- Look toward player
				local toPlayer = (bestPos - echoPos).Unit
				-- Keep Y flat so the echo doesn't tilt
				toPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z).Unit
				targetCFrame = CFrame.lookAt(echoPos, echoPos + toPlayer)
			end

			-- Smooth lerp
			root.CFrame = root.CFrame:Lerp(targetCFrame, TURN_SPEED)

			-- Flicker transparency slightly — "noticing" effect
			local flicker = 0.65 + math.sin(os.clock() * 3) * 0.05
			root.Transparency = math.clamp(flicker, 0.55, 0.75)
		else
			-- No players in range — drift back to resting transparency
			root.Transparency = root.Transparency + (0.65 - root.Transparency) * 0.02
		end
	end
end)

-- ── Listen for Overlap start/end ─────────────────────────────

MidnightEvent.OnServerEvent:Connect(function() end) -- not used server-side here

-- Since MidnightEvent fires clients, we watch workspace for echo spawns instead
workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child.Name:sub(1, 12) == "EchoStudent_" then
		overlapActive = true
		task.delay(0.5, refreshEchoList)
	end
end)

workspace.ChildRemoved:Connect(function(child)
	if child:IsA("Model") and child.Name:sub(1, 12) == "EchoStudent_" then
		task.delay(0.5, function()
			refreshEchoList()
			if #echoStudents == 0 then
				overlapActive = false
			end
		end)
	end
end)

print("[EchoStudentBehavior] Loaded — watching for Echo Student spawns.")
