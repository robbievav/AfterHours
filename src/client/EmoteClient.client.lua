-- ============================================================
--  EmoteClient.client.lua  (src/client)
--
--  Press G to open/close the radial emote wheel.
--  Click an emote to play it. Click again (or press G) to stop.
--  Remote plays/stops are replicated so other players see them.
-- ============================================================

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService       = game:GetService("RunService")

local EmoteConfig  = require(ReplicatedStorage.Shared.EmoteConfig)
local Remotes     = ReplicatedStorage:WaitForChild("Remotes")
local EmoteChanged: RemoteEvent = Remotes:WaitForChild("EmoteChanged")

local LocalPlayer  = Players.LocalPlayer
local playerGui    = LocalPlayer:WaitForChild("PlayerGui")

-- ── Animation tracking ───────────────────────────────────────

-- Map: Player → currently playing Animation track
local activeTracks: { [Player]: AnimationTrack? } = {}

local function stopTrack(player: Player)
	local track = activeTracks[player]
	if track and track.IsPlaying then
		track:Stop(0.3)
	end
	activeTracks[player] = nil
end

local function playEmoteOnCharacter(player: Player, emoteName: string)
	local emote = EmoteConfig[emoteName]
	if not emote then return end

	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	stopTrack(player)

	local anim = Instance.new("Animation")
	anim.AnimationId = emote.AnimationId

	local track = animator:LoadAnimation(anim)
	track.Looped = emote.Looped
	track:Play(0.2)
	activeTracks[player] = track

	-- Auto-stop non-looped emotes
	if not emote.Looped then
		track.Stopped:Connect(function()
			if activeTracks[player] == track then
				activeTracks[player] = nil
			end
		end)
	end
end

-- ── Remote listener (plays emotes on OTHER players) ──────────

EmoteChanged.OnClientEvent:Connect(function(player: Player, action: string, emoteName: string?)
	if action == "Play" and emoteName then
		playEmoteOnCharacter(player, emoteName)
	elseif action == "Stop" then
		stopTrack(player)
	end
end)

-- ── Wheel UI ─────────────────────────────────────────────────

local WHEEL_RADIUS  = 130  -- px from center to button center
local BTN_SIZE      = 68   -- px per button
local OPEN_KEY      = Enum.KeyCode.G

local wheelGui = Instance.new("ScreenGui")
wheelGui.Name         = "EmoteWheel"
wheelGui.ResetOnSpawn = false
wheelGui.DisplayOrder = 10
wheelGui.Enabled      = false
wheelGui.Parent       = playerGui

-- Dark backdrop
local backdrop = Instance.new("Frame")
backdrop.Name              = "Backdrop"
backdrop.Size              = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3  = Color3.new(0, 0, 0)
backdrop.BackgroundTransparency = 0.55
backdrop.BorderSizePixel   = 0
backdrop.Parent            = wheelGui

-- Center ring
local centerFrame = Instance.new("Frame")
centerFrame.Name              = "Center"
centerFrame.Size              = UDim2.fromOffset(90, 90)
centerFrame.AnchorPoint       = Vector2.new(0.5, 0.5)
centerFrame.Position          = UDim2.fromScale(0.5, 0.5)
centerFrame.BackgroundColor3  = Color3.fromRGB(20, 15, 40)
centerFrame.BackgroundTransparency = 0.2
centerFrame.BorderSizePixel   = 0
centerFrame.Parent            = wheelGui

local centerCorner = Instance.new("UICorner")
centerCorner.CornerRadius = UDim.new(1, 0)
centerCorner.Parent       = centerFrame

local centerLabel = Instance.new("TextLabel")
centerLabel.Size              = UDim2.fromScale(1, 1)
centerLabel.BackgroundTransparency = 1
centerLabel.TextColor3        = Color3.fromRGB(200, 180, 255)
centerLabel.Font              = Enum.Font.GothamBold
centerLabel.TextSize          = 11
centerLabel.Text              = "EMOTES\n[G]"
centerLabel.Parent            = centerFrame

-- ── Build emote buttons ──────────────────────────────────────

-- Gather emotes into ordered list
local emoteList = {}
for key, data in EmoteConfig do
	if key:sub(1, 1) == "_" then continue end  -- skip _categories and similar meta-keys
	if type(data) ~= "table" or not data.DisplayName then continue end
	table.insert(emoteList, { key = key, data = data })
end
-- Sort alphabetically within category for consistent layout
table.sort(emoteList, function(a, b)
	if a.data.Category ~= b.data.Category then
		return a.data.Category < b.data.Category
	end
	return a.data.DisplayName < b.data.DisplayName
end)

local totalEmotes = #emoteList
local angleStep   = (2 * math.pi) / totalEmotes

-- Category color map
local catColors = {
	Chill = Color3.fromRGB(80, 160, 255),
	Dance = Color3.fromRGB(220, 80, 255),
	Hype  = Color3.fromRGB(255, 160, 40),
	Music = Color3.fromRGB(80, 255, 180),
}

local emoteButtons: { { button: Frame, key: string } } = {}
local selectedEmote: string? = nil

for i, entry in emoteList do
	local angle = (i - 1) * angleStep - math.pi / 2  -- start from top
	local bx = math.cos(angle) * WHEEL_RADIUS
	local by = math.sin(angle) * WHEEL_RADIUS

	local catColor = catColors[entry.data.Category] or Color3.fromRGB(200, 200, 200)

	-- Button container
	local btn = Instance.new("TextButton")
	btn.Name              = entry.key
	btn.Size              = UDim2.fromOffset(BTN_SIZE, BTN_SIZE)
	btn.AnchorPoint       = Vector2.new(0.5, 0.5)
	btn.Position          = UDim2.new(0.5, bx, 0.5, by)
	btn.BackgroundColor3  = Color3.fromRGB(18, 12, 35)
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel   = 0
	btn.AutoButtonColor   = false
	btn.Parent            = wheelGui

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 14)
	btnCorner.Parent       = btn

	-- Colored accent border via UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color     = catColor
	stroke.Thickness = 2
	stroke.Transparency = 0.4
	stroke.Parent    = btn

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Size              = UDim2.new(1, 0, 0.55, 0)
	icon.BackgroundTransparency = 1
	icon.TextColor3        = Color3.new(1, 1, 1)
	icon.Font              = Enum.Font.GothamBold
	icon.TextSize          = 26
	icon.Text              = entry.data.Icon
	icon.Parent            = btn

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size              = UDim2.new(1, -4, 0.42, 0)
	nameLabel.Position          = UDim2.new(0, 2, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3        = catColor
	nameLabel.Font              = Enum.Font.Gotham
	nameLabel.TextSize          = 9
	nameLabel.Text              = entry.data.DisplayName
	nameLabel.TextWrapped       = true
	nameLabel.Parent            = btn

	table.insert(emoteButtons, { button = btn, key = entry.key })

	-- Hover glow
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.fromRGB(40, 25, 65),
			Size = UDim2.fromOffset(BTN_SIZE + 6, BTN_SIZE + 6),
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.12), { Transparency = 0 }):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.12), {
			BackgroundColor3 = Color3.fromRGB(18, 12, 35),
			Size = UDim2.fromOffset(BTN_SIZE, BTN_SIZE),
		}):Play()
		TweenService:Create(stroke, TweenInfo.new(0.12), { Transparency = 0.4 }):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		if selectedEmote == entry.key then
			-- Already playing — stop it
			selectedEmote = nil
			EmoteChanged:FireServer("Stop", nil)
			centerLabel.Text = "EMOTES\n[G]"
			-- Reset all button backgrounds
			for _, eb in emoteButtons do
				eb.button.BackgroundColor3 = Color3.fromRGB(18, 12, 35)
			end
		else
			selectedEmote = entry.key
			EmoteChanged:FireServer("Play", entry.key)
			centerLabel.Text = entry.data.Icon .. "\n" .. entry.data.DisplayName

			-- Highlight selected
			for _, eb in emoteButtons do
				eb.button.BackgroundColor3 = if eb.key == entry.key
					then Color3.fromRGB(60, 30, 100)
					else Color3.fromRGB(18, 12, 35)
			end
		end

		-- Close wheel after selection
		task.delay(0.15, function()
			wheelGui.Enabled = false
		end)
	end)
end

-- ── Open/Close Wheel ─────────────────────────────────────────

local isOpen = false

local function setWheelOpen(open: boolean)
	isOpen = open
	wheelGui.Enabled = open

	if open then
		-- Animate buttons in
		for i, eb in emoteButtons do
			eb.button.BackgroundTransparency = 1
			task.delay((i - 1) * 0.03, function()
				TweenService:Create(eb.button, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
					BackgroundTransparency = if eb.key == selectedEmote then 0.0 else 0.15,
				}):Play()
			end)
		end
	end
end

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if input.KeyCode == OPEN_KEY then
		setWheelOpen(not isOpen)
	end
end)

-- Close on click outside
backdrop.InputBegan:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		setWheelOpen(false)
	end
end)

-- Stop emote when character respawns
LocalPlayer.CharacterAdded:Connect(function()
	selectedEmote  = nil
	centerLabel.Text = "EMOTES\n[G]"
	for _, eb in emoteButtons do
		eb.button.BackgroundColor3 = Color3.fromRGB(18, 12, 35)
	end
end)

print("[EmoteClient] Loaded —", #emoteButtons, "emotes in wheel. Press G to open.")
