-- ============================================================
--  BoomboxClient.client.lua  (src/client)
--  Handles the Boombox tool UI and frequency-based music sync.
--  When a player equips the Boombox tool, they can tune a
--  frequency (1-5). Players on the same frequency hear the
--  same track. A particle wave effect pulses from the boombox.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

local BoomboxFrequency: RemoteEvent = ReplicatedStorage.Remotes.BoomboxFrequency
local LocalPlayer = Players.LocalPlayer

-- ── Frequency Track Map ──────────────────────────────────────
local FREQ_TRACKS = {
	[1] = "rbxassetid://1836909967",
	[2] = "rbxassetid://1843671399",
	[3] = "rbxassetid://1838673291",
	[4] = "rbxassetid://1843355799",
	[5] = "rbxassetid://1847323587",
}

-- ── Boombox Sound ────────────────────────────────────────────

local boomboxSound = Instance.new("Sound")
boomboxSound.Name   = "BoomboxSound"
boomboxSound.Volume = 0
boomboxSound.Looped = true
boomboxSound.Parent = SoundService

local myFrequency: number? = nil

local function tuneToFrequency(freq: number)
	boomboxSound.SoundId = FREQ_TRACKS[freq] or FREQ_TRACKS[1]
	boomboxSound:Play()
	TweenService:Create(boomboxSound, TweenInfo.new(1), { Volume = 0.6 }):Play()
	myFrequency = freq
end

local function stopBoombox()
	TweenService:Create(boomboxSound, TweenInfo.new(1), { Volume = 0 }):Play()
	task.delay(1.1, function() boomboxSound:Stop() end)
	myFrequency = nil
end

-- ── UI ───────────────────────────────────────────────────────

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local boomboxGui = Instance.new("ScreenGui")
boomboxGui.Name         = "BoomboxGui"
boomboxGui.ResetOnSpawn = false
boomboxGui.Enabled      = false
boomboxGui.Parent       = playerGui

local panel = Instance.new("Frame")
panel.Name              = "Panel"
panel.Size              = UDim2.new(0, 260, 0, 120)
panel.Position          = UDim2.new(0.5, -130, 1, -150)
panel.BackgroundColor3  = Color3.fromRGB(15, 10, 30)
panel.BackgroundTransparency = 0.25
panel.BorderSizePixel   = 0
panel.Parent            = boomboxGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent       = panel

local title = Instance.new("TextLabel")
title.Size              = UDim2.new(1, 0, 0, 28)
title.BackgroundTransparency = 1
title.Text              = "📻  BOOMBOX"
title.TextColor3        = Color3.fromRGB(255, 200, 80)
title.Font              = Enum.Font.GothamBold
title.TextSize          = 15
title.Parent            = panel

-- Members label
local membersLabel = Instance.new("TextLabel")
membersLabel.Size              = UDim2.new(1, -16, 0, 22)
membersLabel.Position          = UDim2.new(0, 8, 0, 30)
membersLabel.BackgroundTransparency = 1
membersLabel.Text              = "No frequency selected"
membersLabel.TextColor3        = Color3.fromRGB(180, 180, 220)
membersLabel.Font              = Enum.Font.Gotham
membersLabel.TextSize          = 12
membersLabel.TextXAlignment    = Enum.TextXAlignment.Left
membersLabel.Parent            = panel

-- Frequency buttons
local freqRow = Instance.new("Frame")
freqRow.Position = UDim2.new(0, 8, 0, 56)
freqRow.Size     = UDim2.new(1, -16, 0, 32)
freqRow.BackgroundTransparency = 1
freqRow.Parent   = panel

local freqLayout = Instance.new("UIListLayout")
freqLayout.FillDirection = Enum.FillDirection.Horizontal
freqLayout.Padding       = UDim.new(0, 6)
freqLayout.Parent        = freqRow

local freqButtons: { TextButton } = {}
for i = 1, 5 do
	local btn = Instance.new("TextButton")
	btn.Size              = UDim2.new(0, 38, 1, 0)
	btn.BackgroundColor3  = Color3.fromRGB(40, 30, 70)
	btn.TextColor3        = Color3.fromRGB(200, 200, 255)
	btn.Font              = Enum.Font.GothamBold
	btn.TextSize          = 14
	btn.Text              = tostring(i)
	btn.BorderSizePixel   = 0
	btn.Parent            = freqRow

	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 8)
	bc.Parent = btn

	freqButtons[i] = btn

	btn.MouseButton1Click:Connect(function()
		-- Highlight selected
		for j, b in freqButtons do
			b.BackgroundColor3 = if j == i
				then Color3.fromRGB(255, 180, 40)
				else Color3.fromRGB(40, 30, 70)
			b.TextColor3 = if j == i
				then Color3.fromRGB(20, 10, 0)
				else Color3.fromRGB(200, 200, 255)
		end
		BoomboxFrequency:FireServer("SetFreq", i)
	end)
end

-- Clear button
local clearBtn = Instance.new("TextButton")
clearBtn.Size              = UDim2.new(0, 60, 0, 26)
clearBtn.Position          = UDim2.new(0.5, -30, 1, -34)
clearBtn.BackgroundColor3  = Color3.fromRGB(80, 40, 40)
clearBtn.TextColor3        = Color3.new(1, 1, 1)
clearBtn.Font              = Enum.Font.Gotham
clearBtn.TextSize          = 12
clearBtn.Text              = "Off"
clearBtn.BorderSizePixel   = 0
clearBtn.Parent            = panel

local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(0, 8)
cc.Parent = clearBtn

clearBtn.MouseButton1Click:Connect(function()
	BoomboxFrequency:FireServer("ClearFreq")
	for _, b in freqButtons do
		b.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
		b.TextColor3       = Color3.fromRGB(200, 200, 255)
	end
	membersLabel.Text = "No frequency selected"
	stopBoombox()
end)

-- ── Tool Equip / Unequip ─────────────────────────────────────

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local function onCharacterAdded(char: Model)
	character = char
	local backpack = LocalPlayer:WaitForChild("Backpack")

	local function onChildAdded(child: Instance)
		if child.Name == "Boombox" then
			-- Show UI when equipped (tool in character)
			child.AncestryChanged:Connect(function()
				local inChar = child:IsDescendantOf(character)
				boomboxGui.Enabled = inChar
				if not inChar then
					stopBoombox()
					BoomboxFrequency:FireServer("ClearFreq")
				end
			end)
		end
	end

	character.ChildAdded:Connect(onChildAdded)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
onCharacterAdded(character)

-- ── Remote Handler ───────────────────────────────────────────

BoomboxFrequency.OnClientEvent:Connect(function(action: string, ...)
	local args = { ... }

	if action == "FreqSet" then
		local freq = args[1] :: number
		tuneToFrequency(freq)

	elseif action == "FreqUpdate" then
		local freq    = args[1] :: number
		local members = args[2] :: { string }
		if freq == myFrequency then
			membersLabel.Text = "Freq " .. freq .. " • " .. table.concat(members, ", ")
		end

	elseif action == "FreqCleared" then
		stopBoombox()
		membersLabel.Text = "No frequency selected"
	end
end)

print("[BoomboxClient] Loaded — 5 frequencies ready.")
