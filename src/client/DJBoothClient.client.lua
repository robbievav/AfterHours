-- ============================================================
--  DJBoothClient.client.lua  (src/client)
--  Handles the local DJ Booth UI and audio layer mixing.
--  When a player claims a slot they see their deck controls.
--  All slots' audio layers are mixed locally via Sound objects.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local RunService        = game:GetService("RunService")

local DJBooth: RemoteEvent = ReplicatedStorage.Remotes.DJBooth
local LocalPlayer = Players.LocalPlayer

-- ── Track Library ────────────────────────────────────────────
-- 8 selectable tracks (replace asset IDs with your own)
local TRACKS = {
	"rbxassetid://1836909967", -- beat layer 1
	"rbxassetid://1843671399", -- beat layer 2
	"rbxassetid://1838673291", -- melody layer 1
	"rbxassetid://1843355799", -- melody layer 2
	"rbxassetid://1847323587", -- bass layer
	"rbxassetid://1836909967", -- FX layer 1
	"rbxassetid://1843671399", -- FX layer 2
	"rbxassetid://1838673291", -- ambience layer
}

local NUM_SLOTS = 4

-- ── Audio Slots ───────────────────────────────────────────────

local slotSounds: { Sound } = {}
for i = 1, NUM_SLOTS do
	local s = Instance.new("Sound")
	s.Name   = "DJSlot_" .. i
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	slotSounds[i] = s
end

local function applySlotState(slotIndex: number, track: number, volume: number)
	local sound = slotSounds[slotIndex]
	local newId = TRACKS[track] or TRACKS[1]
	if sound.SoundId ~= newId then
		sound.SoundId = newId
		sound:Play()
	end
	TweenService:Create(sound, TweenInfo.new(1), { Volume = volume }):Play()
end

-- ── UI ───────────────────────────────────────────────────────

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local djGui = Instance.new("ScreenGui")
djGui.Name         = "DJBoothGui"
djGui.ResetOnSpawn = false
djGui.Enabled      = false
djGui.Parent       = playerGui

-- Main panel
local panel = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, 380, 0, 200)
panel.Position          = UDim2.new(0.5, -190, 1, -220)
panel.BackgroundColor3  = Color3.fromRGB(15, 10, 30)
panel.BackgroundTransparency = 0.2
panel.BorderSizePixel   = 0
panel.Parent            = djGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent       = panel

-- Title
local title = Instance.new("TextLabel")
title.Size              = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text              = "🎚️  DJ BOOTH"
title.TextColor3        = Color3.fromRGB(200, 150, 255)
title.Font              = Enum.Font.GothamBold
title.TextSize          = 16
title.Parent            = panel

-- Slot display (shows who's on each slot)
local slotList = Instance.new("Frame")
slotList.Position = UDim2.new(0, 10, 0, 35)
slotList.Size     = UDim2.new(1, -20, 0, 60)
slotList.BackgroundTransparency = 1
slotList.Parent   = panel

local slotLayout = Instance.new("UIListLayout")
slotLayout.FillDirection = Enum.FillDirection.Horizontal
slotLayout.Padding       = UDim.new(0, 8)
slotLayout.Parent        = slotList

local slotLabels: { TextLabel } = {}
for i = 1, NUM_SLOTS do
	local lbl = Instance.new("TextLabel")
	lbl.Size              = UDim2.new(0.23, 0, 1, 0)
	lbl.BackgroundColor3  = Color3.fromRGB(30, 20, 50)
	lbl.BorderSizePixel   = 0
	lbl.TextColor3        = Color3.fromRGB(180, 180, 200)
	lbl.Font              = Enum.Font.Gotham
	lbl.TextSize          = 11
	lbl.Text              = "Slot " .. i .. "\n—"
	lbl.TextWrapped       = true
	lbl.Parent            = slotList
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = lbl
	slotLabels[i] = lbl
end

-- Claim / Release buttons
local claimBtn = Instance.new("TextButton")
claimBtn.Size              = UDim2.new(0, 120, 0, 34)
claimBtn.Position          = UDim2.new(0.5, -130, 1, -50)
claimBtn.BackgroundColor3  = Color3.fromRGB(160, 80, 255)
claimBtn.TextColor3        = Color3.new(1, 1, 1)
claimBtn.Font              = Enum.Font.GothamBold
claimBtn.TextSize          = 13
claimBtn.Text              = "Claim Deck"
claimBtn.BorderSizePixel   = 0
claimBtn.Parent            = panel

local releaseBtn = Instance.new("TextButton")
releaseBtn.Size              = UDim2.new(0, 120, 0, 34)
releaseBtn.Position          = UDim2.new(0.5, 10, 1, -50)
releaseBtn.BackgroundColor3  = Color3.fromRGB(80, 60, 120)
releaseBtn.TextColor3        = Color3.new(1, 1, 1)
releaseBtn.Font              = Enum.Font.GothamBold
releaseBtn.TextSize          = 13
releaseBtn.Text              = "Release"
releaseBtn.BorderSizePixel   = 0
releaseBtn.Visible           = false
releaseBtn.Parent            = panel

for _, btn in { claimBtn, releaseBtn } do
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 10)
	bc.Parent = btn
end

claimBtn.MouseButton1Click:Connect(function()
	DJBooth:FireServer("Claim")
end)

releaseBtn.MouseButton1Click:Connect(function()
	DJBooth:FireServer("Release")
	claimBtn.Visible   = true
	releaseBtn.Visible = false
end)

-- ── Remote Handler ───────────────────────────────────────────

local mySlot: number? = nil

DJBooth.OnClientEvent:Connect(function(action: string, data)
	if action == "StateUpdate" then
		local slots: { { player: string?, track: number, volume: number } } = data
		for i, slot in slots do
			local label = "Slot " .. i .. "\n" .. (slot.player or "—")
			slotLabels[i].Text = label
			slotLabels[i].TextColor3 = if slot.player
				then Color3.fromRGB(180, 255, 180)
				else Color3.fromRGB(180, 180, 200)

			applySlotState(i, slot.track, slot.volume)

			-- If this is our slot, show release button
			if slot.player == LocalPlayer.DisplayName then
				mySlot           = i
				claimBtn.Visible  = false
				releaseBtn.Visible = true
			end
		end

	elseif action == "SlotsFull" then
		claimBtn.Text = "Booth Full!"
		task.delay(2, function() claimBtn.Text = "Claim Deck" end)
	end
end)

-- ── Proximity Detection ──────────────────────────────────────

local djBoothPart = workspace:FindFirstChild("DJBooth", true)
local INTERACT_DISTANCE = 12

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char or not djBoothPart then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	local dist = (root.Position - (djBoothPart :: BasePart).Position).Magnitude
	djGui.Enabled = dist <= INTERACT_DISTANCE
end)

print("[DJBoothClient] Loaded — audio mixer ready.")
