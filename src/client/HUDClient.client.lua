-- ============================================================
--  HUDClient.client.lua  (src/client)
--
--  Displays:
--   • Top-center: In-game clock (synced from server)
--   • Bottom-left: Current Vibe Zone name (fades in on change)
--   • Bottom-right: Boombox frequency + who's on it
--   • Top-right:    Player count
--   • Center-screen: Zone transition title card (brief pop)
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local ZoneChanged: RemoteEvent  = ReplicatedStorage.Remotes.ZoneChanged
local ClockSync: RemoteEvent    = ReplicatedStorage.Remotes.ClockSync
local BoomboxFreq: RemoteEvent  = ReplicatedStorage.Remotes.BoomboxFrequency
local MidnightEvent: RemoteEvent = ReplicatedStorage.Remotes.MidnightEvent

local LocalPlayer = Players.LocalPlayer
local playerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ── Zone display names + icons ────────────────────────────────
local ZONE_INFO = {
	ThePulse       = { name = "The Pulse",       icon = "🎵", color = Color3.fromRGB(220, 80,  255) },
	TheGrind       = { name = "The Grind",        icon = "☕", color = Color3.fromRGB(255, 160, 60)  },
	TheArchive     = { name = "The Archive",      icon = "📚", color = Color3.fromRGB(120, 180, 255) },
	TheObservatory = { name = "The Observatory",  icon = "🌌", color = Color3.fromRGB(80,  120, 255) },
	TheOverlap     = { name = "The Overlap",      icon = "👻", color = Color3.fromRGB(200, 160, 80)  },
}

-- ── Create ScreenGui ─────────────────────────────────────────
local hudGui = Instance.new("ScreenGui")
hudGui.Name            = "AfterHoursHUD"
hudGui.ResetOnSpawn    = false
hudGui.DisplayOrder    = 5
hudGui.IgnoreGuiInset  = false
hudGui.Parent          = playerGui

-- ── Helper: glassmorphism panel ──────────────────────────────
local function makePanel(name, size, pos, anchor)
	local f = Instance.new("Frame")
	f.Name              = name
	f.Size              = size
	f.Position          = pos
	f.AnchorPoint       = anchor or Vector2.new(0, 0)
	f.BackgroundColor3  = Color3.fromRGB(10, 6, 22)
	f.BackgroundTransparency = 0.35
	f.BorderSizePixel   = 0
	f.Parent            = hudGui

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = f

	local s = Instance.new("UIStroke")
	s.Color       = Color3.fromRGB(120, 80, 200)
	s.Thickness   = 1
	s.Transparency = 0.6
	s.Parent      = f

	return f
end

local function makeLabel(parent, name, text, size, color, font, xAlign)
	local l = Instance.new("TextLabel")
	l.Name              = name
	l.Size              = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.TextColor3        = color or Color3.new(1, 1, 1)
	l.Font              = font  or Enum.Font.GothamBold
	l.TextSize          = size  or 14
	l.Text              = text  or ""
	l.TextXAlignment    = xAlign or Enum.TextXAlignment.Center
	l.Parent            = parent
	return l
end

-- ── 1. Clock (top-center) ─────────────────────────────────────

local clockPanel = makePanel("Clock",
	UDim2.fromOffset(120, 38),
	UDim2.new(0.5, -60, 0, 12),
	Vector2.new(0, 0)
)

local clockLabel = makeLabel(clockPanel, "Time", "20:00",
	18, Color3.fromRGB(220, 200, 255), Enum.Font.GothamBold)

local clockSuffix = makeLabel(clockPanel, "Suffix", "PM",
	11, Color3.fromRGB(160, 140, 200), Enum.Font.Gotham)
clockSuffix.Position = UDim2.new(0, 0, 0.55, 0)
clockSuffix.Size     = UDim2.fromScale(1, 0.45)

-- Local clock tick — interpolates between server syncs
local localHour   = 20
local localMinute = 0
local clockAccum  = 0
local SECONDS_PER_INGAME_MINUTE = 1  -- 1 real second = 1 in-game minute

RunService.RenderStepped:Connect(function(dt: number)
	clockAccum += dt
	while clockAccum >= SECONDS_PER_INGAME_MINUTE do
		clockAccum -= SECONDS_PER_INGAME_MINUTE
		localMinute += 1
		if localMinute >= 60 then
			localMinute = 0
			localHour = (localHour + 1) % 24
		end
	end

	local displayHour = localHour % 12
	if displayHour == 0 then displayHour = 12 end
	local suffix = localHour >= 12 and "PM" or "AM"
	clockLabel.Text  = string.format("%d:%02d", displayHour, localMinute)
	clockSuffix.Text = suffix
end)

ClockSync.OnClientEvent:Connect(function(hour: number, minute: number)
	localHour   = hour
	localMinute = minute
end)

-- ── 2. Zone indicator (bottom-left) ───────────────────────────

local zonePanel = makePanel("ZonePanel",
	UDim2.fromOffset(200, 44),
	UDim2.new(0, 16, 1, -60),
	Vector2.new(0, 0)
)
zonePanel.BackgroundTransparency = 1  -- starts invisible

local zoneLabel = makeLabel(zonePanel, "ZoneLabel", "🌙  After Hours",
	14, Color3.fromRGB(200, 180, 255), Enum.Font.GothamBold, Enum.TextXAlignment.Left)
zoneLabel.Position = UDim2.fromOffset(12, 0)
zoneLabel.Size     = UDim2.new(1, -12, 1, 0)

local zoneStroke = zonePanel:FindFirstChildOfClass("UIStroke")

local function showZoneBadge(zoneName: string?)
	local info = zoneName and ZONE_INFO[zoneName]
	local displayText = info and (info.icon .. "  " .. info.name) or "🌙  After Hours"
	local displayColor = info and info.color or Color3.fromRGB(180, 160, 255)

	zoneLabel.Text       = displayText
	zoneLabel.TextColor3 = displayColor
	if zoneStroke then zoneStroke.Color = displayColor end

	-- Fade in, hold, fade out
	zonePanel.BackgroundTransparency = 0.35
	TweenService:Create(zonePanel, TweenInfo.new(0.4), { BackgroundTransparency = 0.35 }):Play()
	TweenService:Create(zoneLabel, TweenInfo.new(0.4), { TextTransparency = 0 }):Play()

	task.delay(4, function()
		TweenService:Create(zoneLabel, TweenInfo.new(1.2), { TextTransparency = 0.55 }):Play()
		TweenService:Create(zonePanel, TweenInfo.new(1.2), { BackgroundTransparency = 0.85 }):Play()
	end)
end

ZoneChanged.OnClientEvent:Connect(function(zoneName: string?)
	showZoneBadge(zoneName)
end)

-- ── 3. Zone title card (center, brief pop-in) ─────────────────

local titleCard = Instance.new("Frame")
titleCard.Name              = "ZoneTitleCard"
titleCard.Size              = UDim2.fromOffset(340, 70)
titleCard.AnchorPoint       = Vector2.new(0.5, 0.5)
titleCard.Position          = UDim2.new(0.5, 0, 0.38, 0)
titleCard.BackgroundColor3  = Color3.fromRGB(10, 6, 22)
titleCard.BackgroundTransparency = 1
titleCard.BorderSizePixel   = 0
titleCard.Parent            = hudGui

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 18)
titleCorner.Parent = titleCard

local titleMain = Instance.new("TextLabel")
titleMain.Name              = "Main"
titleMain.Size              = UDim2.new(1, 0, 0.6, 0)
titleMain.BackgroundTransparency = 1
titleMain.TextColor3        = Color3.new(1, 1, 1)
titleMain.TextTransparency  = 1
titleMain.Font              = Enum.Font.GothamBold
titleMain.TextSize          = 28
titleMain.Parent            = titleCard

local titleSub = Instance.new("TextLabel")
titleSub.Name              = "Sub"
titleSub.Size              = UDim2.new(1, 0, 0.4, 0)
titleSub.Position          = UDim2.fromScale(0, 0.6)
titleSub.BackgroundTransparency = 1
titleSub.TextColor3        = Color3.fromRGB(180, 160, 255)
titleSub.TextTransparency  = 1
titleSub.Font              = Enum.Font.Gotham
titleSub.TextSize          = 14
titleSub.Text              = "Vibe Zone"
titleSub.Parent            = titleCard

local ZONE_SUBTITLES = {
	ThePulse       = "Neon Dance Hall",
	TheGrind       = "Lo-Fi Café",
	TheArchive     = "The Quiet Room",
	TheObservatory = "Rooftop Stargazing",
	TheOverlap     = "Something is wrong here...",
}

local function showTitleCard(zoneName: string?)
	if not zoneName then return end
	local info = ZONE_INFO[zoneName]
	if not info then return end

	titleMain.Text       = info.icon .. "  " .. info.name
	titleMain.TextColor3 = info.color
	titleSub.Text        = ZONE_SUBTITLES[zoneName] or "Vibe Zone"

	-- Pop in
	titleCard.BackgroundTransparency = 0.4
	local t1 = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(titleMain, t1, { TextTransparency = 0 }):Play()
	TweenService:Create(titleSub,  t1, { TextTransparency = 0 }):Play()

	-- Hold then fade out
	task.delay(2.5, function()
		local t2 = TweenInfo.new(0.6, Enum.EasingStyle.Sine)
		TweenService:Create(titleMain, t2, { TextTransparency = 1 }):Play()
		TweenService:Create(titleSub,  t2, { TextTransparency = 1 }):Play()
		TweenService:Create(titleCard, t2, { BackgroundTransparency = 1 }):Play()
	end)
end

ZoneChanged.OnClientEvent:Connect(showTitleCard)

-- ── 4. Player count (top-right) ───────────────────────────────

local playerCountPanel = makePanel("PlayerCount",
	UDim2.fromOffset(110, 32),
	UDim2.new(1, -126, 0, 12),
	Vector2.new(0, 0)
)

local playerCountLabel = makeLabel(playerCountPanel, "Count",
	"👥  1", 13, Color3.fromRGB(180, 200, 255))

local function updatePlayerCount()
	local count = #Players:GetPlayers()
	playerCountLabel.Text = "👥  " .. count
end

Players.PlayerAdded:Connect(updatePlayerCount)
Players.PlayerRemoving:Connect(function()
	task.wait()
	updatePlayerCount()
end)
updatePlayerCount()

-- ── 5. Boombox indicator (bottom-right) ───────────────────────

local boomboxPanel = makePanel("BoomboxPanel",
	UDim2.fromOffset(200, 44),
	UDim2.new(1, -216, 1, -60),
	Vector2.new(0, 0)
)
boomboxPanel.BackgroundTransparency = 0.85
boomboxPanel.Visible = false

local boomboxLabel = makeLabel(boomboxPanel, "FreqLabel",
	"📻  Freq 1", 13, Color3.fromRGB(255, 210, 80),
	Enum.Font.GothamBold, Enum.TextXAlignment.Left)
boomboxLabel.Position = UDim2.fromOffset(12, 0)
boomboxLabel.Size     = UDim2.new(1, -12, 0.5, 0)

local boomboxMembersLabel = makeLabel(boomboxPanel, "Members",
	"", 11, Color3.fromRGB(200, 200, 200),
	Enum.Font.Gotham, Enum.TextXAlignment.Left)
boomboxMembersLabel.Position = UDim2.new(0, 12, 0.5, 0)
boomboxMembersLabel.Size     = UDim2.new(1, -12, 0.5, 0)

BoomboxFreq.OnClientEvent:Connect(function(action: string, ...)
	local args = { ... }
	if action == "FreqSet" then
		local freq = args[1] :: number
		boomboxLabel.Text = "📻  Frequency " .. freq
		boomboxPanel.Visible = true
		boomboxPanel.BackgroundTransparency = 0.35

	elseif action == "FreqUpdate" then
		local freq    = args[1] :: number
		local members = args[2] :: { string }
		boomboxLabel.Text   = "📻  Frequency " .. freq
		boomboxMembersLabel.Text = table.concat(members, " · ")

	elseif action == "FreqCleared" then
		boomboxPanel.Visible = false
	end
end)

-- ── 6. Midnight overlay message ───────────────────────────────

local midnightBanner = Instance.new("Frame")
midnightBanner.Name              = "MidnightBanner"
midnightBanner.Size              = UDim2.new(1, 0, 0, 60)
midnightBanner.AnchorPoint       = Vector2.new(0.5, 0)
midnightBanner.Position          = UDim2.new(0.5, 0, 0, -70) -- starts offscreen
midnightBanner.BackgroundColor3  = Color3.fromRGB(30, 20, 10)
midnightBanner.BackgroundTransparency = 0.2
midnightBanner.BorderSizePixel   = 0
midnightBanner.Parent            = hudGui

local midnightLabel = Instance.new("TextLabel")
midnightLabel.Size              = UDim2.fromScale(1, 1)
midnightLabel.BackgroundTransparency = 1
midnightLabel.TextColor3        = Color3.fromRGB(220, 180, 100)
midnightLabel.Font              = Enum.Font.GothamBold
midnightLabel.TextSize          = 18
midnightLabel.Text              = "🕛  The Overlap begins... something stirs in the boiler room."
midnightLabel.Parent            = midnightBanner

local slideIn  = TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local slideOut = TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

MidnightEvent.OnClientEvent:Connect(function(isBeginning: boolean)
	if isBeginning then
		TweenService:Create(midnightBanner, slideIn, {
			Position = UDim2.new(0.5, 0, 0, 0)
		}):Play()
		task.delay(6, function()
			TweenService:Create(midnightBanner, slideOut, {
				Position = UDim2.new(0.5, 0, 0, -70)
			}):Play()
		end)
	else
		-- Overlap ended
		midnightLabel.Text = "🌅  The Overlap fades... for now."
		TweenService:Create(midnightBanner, slideIn, {
			Position = UDim2.new(0.5, 0, 0, 0)
		}):Play()
		task.delay(4, function()
			TweenService:Create(midnightBanner, slideOut, {
				Position = UDim2.new(0.5, 0, 0, -70)
			}):Play()
			task.delay(0.6, function()
				midnightLabel.Text = "🕛  The Overlap begins... something stirs in the boiler room."
			end)
		end)
	end
end)

print("[HUDClient] Loaded — clock, zone badge, title card, player count, boombox panel, midnight banner.")
