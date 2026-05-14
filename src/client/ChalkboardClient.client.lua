-- ============================================================
--  ChalkboardClient.client.lua  (src/client)
--
--  Renders the cafeteria chalkboard as a SurfaceGui showing
--  5 editable menu lines in chalk style. When a player walks
--  within range, a ProximityPrompt lets them pick a line to
--  edit. An edit panel slides up for text input.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local ChalkboardUpdated: RemoteEvent = ReplicatedStorage.Remotes.ChalkboardUpdated
local LocalPlayer = Players.LocalPlayer
local playerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ── Find Chalkboard Part ─────────────────────────────────────

local chalkboard = workspace:WaitForChild("Chalkboard", 10) :: BasePart?
if not chalkboard then
	warn("[ChalkboardClient] 'Chalkboard' Part not found in workspace.")
	return
end

-- ── SurfaceGui — the board display ───────────────────────────

local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Name           = "ChalkboardGui"
surfaceGui.Face           = Enum.NormalId.Front
surfaceGui.CanvasSize     = Vector2.new(800, 500)
surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
surfaceGui.Parent         = chalkboard

-- Dark green chalkboard background
local bg = Instance.new("Frame")
bg.Name              = "Background"
bg.Size              = UDim2.fromScale(1, 1)
bg.BackgroundColor3  = Color3.fromRGB(22, 52, 32)
bg.BorderSizePixel   = 0
bg.Parent            = surfaceGui

-- Wooden frame border
local border = Instance.new("Frame")
border.Name              = "Frame"
border.Size              = UDim2.new(1, -16, 1, -16)
border.Position          = UDim2.fromOffset(8, 8)
border.BackgroundColor3  = Color3.fromRGB(80, 45, 20)
border.BorderSizePixel   = 0
border.ZIndex            = 0
border.Parent            = surfaceGui

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size             = UDim2.new(1, 0, 0, 64)
titleBar.BackgroundTransparency = 1
titleBar.Parent           = bg

local titleText = Instance.new("TextLabel")
titleText.Size              = UDim2.fromScale(1, 1)
titleText.BackgroundTransparency = 1
titleText.TextColor3        = Color3.fromRGB(255, 245, 180)
titleText.Font              = Enum.Font.GothamBold
titleText.TextSize          = 32
titleText.Text              = "☕  The Grind  —  Tonight's Menu"
titleText.Parent            = titleBar

-- Divider line
local divider = Instance.new("Frame")
divider.Size             = UDim2.new(0.85, 0, 0, 2)
divider.Position         = UDim2.new(0.075, 0, 0, 66)
divider.BackgroundColor3 = Color3.fromRGB(200, 230, 180)
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel  = 0
divider.Parent           = bg

-- Line entries
local LINE_HEIGHT   = 72
local LINE_START_Y  = 76
local lineFrames: { { label: TextLabel, value: TextLabel, credit: TextLabel } } = {}

for i = 1, 5 do
	local yPos = LINE_START_Y + (i - 1) * LINE_HEIGHT

	local row = Instance.new("Frame")
	row.Name             = "Line_" .. i
	row.Size             = UDim2.new(1, -40, 0, LINE_HEIGHT - 4)
	row.Position         = UDim2.new(0, 20, 0, yPos)
	row.BackgroundTransparency = 1
	row.Parent           = bg

	local labelText = Instance.new("TextLabel")
	labelText.Name              = "Label"
	labelText.Size              = UDim2.new(0.38, 0, 0.6, 0)
	labelText.BackgroundTransparency = 1
	labelText.TextColor3        = Color3.fromRGB(180, 220, 160)
	labelText.Font              = Enum.Font.GothamBold
	labelText.TextSize          = 22
	labelText.TextXAlignment    = Enum.TextXAlignment.Left
	labelText.Text              = "Loading..."
	labelText.Parent            = row

	local colonLabel = Instance.new("TextLabel")
	colonLabel.Size              = UDim2.new(0.04, 0, 0.6, 0)
	colonLabel.Position          = UDim2.fromScale(0.38, 0)
	colonLabel.BackgroundTransparency = 1
	colonLabel.TextColor3        = Color3.fromRGB(180, 220, 160)
	colonLabel.Font              = Enum.Font.GothamBold
	colonLabel.TextSize          = 22
	colonLabel.Text              = ":"
	colonLabel.Parent            = row

	local valueText = Instance.new("TextLabel")
	valueText.Name              = "Value"
	valueText.Size              = UDim2.new(0.56, 0, 0.6, 0)
	valueText.Position          = UDim2.fromScale(0.42, 0)
	valueText.BackgroundTransparency = 1
	valueText.TextColor3        = Color3.fromRGB(255, 250, 210)
	valueText.Font              = Enum.Font.Gotham
	valueText.TextSize          = 22
	valueText.TextXAlignment    = Enum.TextXAlignment.Left
	valueText.Text              = "..."
	valueText.Parent            = row

	local creditText = Instance.new("TextLabel")
	creditText.Name              = "Credit"
	creditText.Size              = UDim2.new(1, 0, 0.38, 0)
	creditText.Position          = UDim2.fromScale(0, 0.62)
	creditText.BackgroundTransparency = 1
	creditText.TextColor3        = Color3.fromRGB(140, 180, 130)
	creditText.Font              = Enum.Font.Gotham
	creditText.TextSize          = 14
	creditText.TextXAlignment    = Enum.TextXAlignment.Left
	creditText.Text              = ""
	creditText.Parent            = row

	lineFrames[i] = {
		label  = labelText,
		value  = valueText,
		credit = creditText,
	}
end

-- ── Apply board state ────────────────────────────────────────

local function applySnapshot(snapshot: { { label: string, value: string, editedBy: string? } })
	for i, data in snapshot do
		if not lineFrames[i] then continue end
		local row = lineFrames[i]

		-- Chalk-flicker tween on value change
		TweenService:Create(row.value, TweenInfo.new(0.1), { TextTransparency = 0.6 }):Play()
		task.delay(0.1, function()
			row.label.Text  = data.label
			row.value.Text  = data.value
			row.credit.Text = data.editedBy and ("— " .. data.editedBy) or ""
			TweenService:Create(row.value, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
		end)
	end
end

ChalkboardUpdated.OnClientEvent:Connect(function(action: string, snapshot)
	if action == "Update" then
		applySnapshot(snapshot)
	end
end)

-- ── Edit Panel UI ─────────────────────────────────────────────

local editGui = Instance.new("ScreenGui")
editGui.Name         = "ChalkboardEdit"
editGui.ResetOnSpawn = false
editGui.DisplayOrder = 8
editGui.Enabled      = false
editGui.Parent       = playerGui

local panel = Instance.new("Frame")
panel.Name              = "EditPanel"
panel.Size              = UDim2.fromOffset(460, 220)
panel.AnchorPoint       = Vector2.new(0.5, 1)
panel.Position          = UDim2.new(0.5, 0, 1, 0)  -- starts off-screen below
panel.BackgroundColor3  = Color3.fromRGB(18, 42, 24)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel   = 0
panel.Parent            = editGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 18)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color     = Color3.fromRGB(120, 200, 100)
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.5
panelStroke.Parent    = panel

-- Title
local editTitle = Instance.new("TextLabel")
editTitle.Name              = "Title"
editTitle.Size              = UDim2.new(1, -20, 0, 36)
editTitle.Position          = UDim2.fromOffset(10, 10)
editTitle.BackgroundTransparency = 1
editTitle.TextColor3        = Color3.fromRGB(200, 240, 170)
editTitle.Font              = Enum.Font.GothamBold
editTitle.TextSize          = 17
editTitle.TextXAlignment    = Enum.TextXAlignment.Left
editTitle.Text              = "✏️  Edit Line"
editTitle.Parent            = panel

-- Line selector buttons (5 numbered pills)
local selectorRow = Instance.new("Frame")
selectorRow.Size     = UDim2.new(1, -20, 0, 34)
selectorRow.Position = UDim2.fromOffset(10, 50)
selectorRow.BackgroundTransparency = 1
selectorRow.Parent   = panel

local selectorLayout = Instance.new("UIListLayout")
selectorLayout.FillDirection = Enum.FillDirection.Horizontal
selectorLayout.Padding       = UDim.new(0, 8)
selectorLayout.Parent        = selectorRow

local selectedLine = 1
local selectorBtns: { TextButton } = {}

local function updateSelectorHighlight()
	for i, btn in selectorBtns do
		btn.BackgroundColor3 = if i == selectedLine
			then Color3.fromRGB(80, 160, 60)
			else Color3.fromRGB(30, 60, 25)
	end
end

for i = 1, 5 do
	local btn = Instance.new("TextButton")
	btn.Size              = UDim2.fromOffset(60, 34)
	btn.BackgroundColor3  = Color3.fromRGB(30, 60, 25)
	btn.TextColor3        = Color3.fromRGB(220, 255, 200)
	btn.Font              = Enum.Font.GothamBold
	btn.TextSize          = 13
	btn.Text              = "Line " .. i
	btn.BorderSizePixel   = 0
	btn.Parent            = selectorRow

	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(0, 8)
	sc.Parent = btn

	selectorBtns[i] = btn

	btn.MouseButton1Click:Connect(function()
		selectedLine = i
		updateSelectorHighlight()
		-- Show current value in textbox
		local currentValue = lineFrames[i] and lineFrames[i].value.Text or ""
		editTitle.Text = "✏️  Editing: " .. (lineFrames[i] and lineFrames[i].label.Text or ("Line " .. i))
	end)
end
updateSelectorHighlight()

-- TextBox
local textBox = Instance.new("TextBox")
textBox.Name              = "Input"
textBox.Size              = UDim2.new(1, -20, 0, 44)
textBox.Position          = UDim2.fromOffset(10, 96)
textBox.BackgroundColor3  = Color3.fromRGB(10, 30, 14)
textBox.BackgroundTransparency = 0.2
textBox.TextColor3        = Color3.fromRGB(255, 255, 210)
textBox.PlaceholderText   = "Type here... (max 32 chars)"
textBox.PlaceholderColor3 = Color3.fromRGB(120, 150, 110)
textBox.Font              = Enum.Font.Gotham
textBox.TextSize          = 18
textBox.ClearTextOnFocus  = false
textBox.BorderSizePixel   = 0
textBox.MaxVisibleGraphemes = 32
textBox.Parent            = panel

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 10)
tbCorner.Parent = textBox

-- Char counter
local charCount = Instance.new("TextLabel")
charCount.Size              = UDim2.fromOffset(50, 20)
charCount.Position          = UDim2.new(1, -60, 0, 100)
charCount.BackgroundTransparency = 1
charCount.TextColor3        = Color3.fromRGB(140, 180, 120)
charCount.Font              = Enum.Font.Gotham
charCount.TextSize          = 12
charCount.Text              = "0/32"
charCount.Parent            = panel

textBox:GetPropertyChangedSignal("Text"):Connect(function()
	local t = textBox.Text:sub(1, 32)
	textBox.Text    = t
	charCount.Text  = #t .. "/32"
end)

-- Submit / Cancel buttons
local submitBtn = Instance.new("TextButton")
submitBtn.Size              = UDim2.fromOffset(140, 38)
submitBtn.Position          = UDim2.new(0.5, -150, 1, -52)
submitBtn.BackgroundColor3  = Color3.fromRGB(60, 160, 50)
submitBtn.TextColor3        = Color3.new(1, 1, 1)
submitBtn.Font              = Enum.Font.GothamBold
submitBtn.TextSize          = 15
submitBtn.Text              = "✓  Post It"
submitBtn.BorderSizePixel   = 0
submitBtn.Parent            = panel

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size              = UDim2.fromOffset(100, 38)
cancelBtn.Position          = UDim2.new(0.5, 20, 1, -52)
cancelBtn.BackgroundColor3  = Color3.fromRGB(60, 40, 40)
cancelBtn.TextColor3        = Color3.new(1, 1, 1)
cancelBtn.Font              = Enum.Font.GothamBold
cancelBtn.TextSize          = 15
cancelBtn.Text              = "Cancel"
cancelBtn.BorderSizePixel   = 0
cancelBtn.Parent            = panel

for _, btn in { submitBtn, cancelBtn } do
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 10)
	bc.Parent = btn
end

-- ── Panel slide helpers ───────────────────────────────────────

local slideIn  = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local slideOut = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local function openPanel()
	editGui.Enabled = true
	TweenService:Create(panel, slideIn, {
		Position = UDim2.new(0.5, 0, 1, -24)
	}):Play()
	updateSelectorHighlight()
	textBox:CaptureFocus()
end

local function closePanel()
	TweenService:Create(panel, slideOut, {
		Position = UDim2.new(0.5, 0, 1, 0)
	}):Play()
	task.delay(0.26, function()
		editGui.Enabled = false
		textBox.Text    = ""
		charCount.Text  = "0/32"
		editTitle.Text  = "✏️  Edit Line"
	end)
end

submitBtn.MouseButton1Click:Connect(function()
	local value = textBox.Text:match("^%s*(.-)%s*$")
	if value and #value > 0 then
		ChalkboardUpdated:FireServer(selectedLine, value)
	end
	closePanel()
end)

cancelBtn.MouseButton1Click:Connect(function()
	closePanel()
end)

-- Submit on Enter
UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Escape and editGui.Enabled then
		closePanel()
	end
end)

textBox.FocusLost:Connect(function(enterPressed: boolean)
	if enterPressed then
		submitBtn.MouseButton1Click:Fire()
	end
end)

-- ── ProximityPrompt handler ───────────────────────────────────

local prompt = chalkboard:FindFirstChildOfClass("ProximityPrompt")
	or chalkboard:FindFirstChild("ChalkboardPrompt", true) :: ProximityPrompt?

if prompt then
	prompt.Triggered:Connect(function(player: Player)
		if player ~= LocalPlayer then return end
		if editGui.Enabled then
			closePanel()
		else
			openPanel()
		end
	end)
end

print("[ChalkboardClient] Loaded — 5-line board rendering on 'Chalkboard' Part.")
