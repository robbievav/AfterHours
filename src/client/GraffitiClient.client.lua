-- ============================================================
--  GraffitiClient.client.lua  (src/client)
--  Handles the Graffiti Wall UI and renders strokes locally.
--  Players can paint on a Canvas SurfaceGui attached to the
--  wall Part named "GraffitiWall" in the workspace.
-- ============================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local GraffitiUpdated: RemoteEvent = ReplicatedStorage.Remotes.GraffitiUpdated
local LocalPlayer = Players.LocalPlayer

-- ── Configuration ────────────────────────────────────────────

local COLORS = {
	Color3.fromRGB(255,  80, 200), -- neon pink
	Color3.fromRGB( 80, 220, 255), -- cyan
	Color3.fromRGB(255, 220,  50), -- yellow
	Color3.fromRGB(120, 255, 120), -- green
	Color3.fromRGB(255, 140,  40), -- orange
	Color3.fromRGB(200, 100, 255), -- purple
	Color3.fromRGB(255, 255, 255), -- white
}

local BRUSH_SIZES = { 8, 14, 22, 32, 44, 58 } -- pixel sizes

-- ── Canvas Setup ─────────────────────────────────────────────

local graffitiWall = workspace:WaitForChild("GraffitiWall", 10) :: BasePart?
if not graffitiWall then
	warn("[GraffitiClient] GraffitiWall part not found in workspace.")
	return
end

-- Build SurfaceGui on the wall
local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Name        = "GraffitiCanvas"
surfaceGui.Face        = Enum.NormalId.Front
surfaceGui.CanvasSize  = Vector2.new(1024, 512)
surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
surfaceGui.Parent      = graffitiWall

local canvas = Instance.new("Frame")
canvas.Name            = "Canvas"
canvas.Size            = UDim2.fromScale(1, 1)
canvas.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
canvas.BorderSizePixel = 0
canvas.ClipsDescendants = true
canvas.Parent          = surfaceGui

-- ── Brush State ───────────────────────────────────────────────

local selectedColor = COLORS[1]
local selectedSize  = BRUSH_SIZES[1]
local isPainting    = false

-- ── Stroke Rendering ─────────────────────────────────────────

local function paintDot(normalX: number, normalY: number, color: Color3, size: number, label: string?)
	local dot = Instance.new("Frame")
	dot.AnchorPoint       = Vector2.new(0.5, 0.5)
	dot.Position          = UDim2.fromScale(normalX, normalY)
	dot.Size              = UDim2.fromOffset(size, size)
	dot.BackgroundColor3  = color
	dot.BorderSizePixel   = 0
	dot.ZIndex            = 2
	dot.Parent            = canvas

	-- Round corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent       = dot

	-- Username tooltip
	if label then
		local tag = Instance.new("TextLabel")
		tag.Size              = UDim2.new(0, 80, 0, 16)
		tag.Position          = UDim2.new(0.5, 0, 0, -20)
		tag.AnchorPoint       = Vector2.new(0.5, 1)
		tag.BackgroundTransparency = 1
		tag.TextColor3        = Color3.new(1, 1, 1)
		tag.TextSize          = 10
		tag.Font              = Enum.Font.GothamBold
		tag.Text              = label
		tag.ZIndex            = 3
		tag.Parent            = dot

		-- Fade tag after 3s
		task.delay(3, function()
			for i = 0, 10 do
				tag.TextTransparency = i / 10
				task.wait(0.05)
			end
			tag:Destroy()
		end)
	end
end

-- ── Toolbar UI ───────────────────────────────────────────────

local playerGui = LocalPlayer:WaitForChild("PlayerGui")

local toolbarGui = Instance.new("ScreenGui")
toolbarGui.Name            = "GraffitiToolbar"
toolbarGui.ResetOnSpawn    = false
toolbarGui.Enabled         = false -- shown only near the wall
toolbarGui.Parent          = playerGui

local toolbar = Instance.new("Frame")
toolbar.Name              = "Toolbar"
toolbar.Size              = UDim2.new(0, 320, 0, 60)
toolbar.Position          = UDim2.new(0.5, -160, 1, -80)
toolbar.BackgroundColor3  = Color3.fromRGB(20, 15, 40)
toolbar.BackgroundTransparency = 0.3
toolbar.BorderSizePixel   = 0
toolbar.Parent            = toolbarGui

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 12)
tbCorner.Parent       = toolbar

local tbLayout = Instance.new("UIListLayout")
tbLayout.FillDirection  = Enum.FillDirection.Horizontal
tbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tbLayout.Padding        = UDim.new(0, 6)
tbLayout.Parent         = toolbar

local tbPadding = Instance.new("UIPadding")
tbPadding.PaddingLeft  = UDim.new(0, 8)
tbPadding.PaddingRight = UDim.new(0, 8)
tbPadding.Parent       = toolbar

-- Color swatches
for _, col in COLORS do
	local swatch = Instance.new("TextButton")
	swatch.Size              = UDim2.new(0, 28, 0, 28)
	swatch.BackgroundColor3  = col
	swatch.BorderSizePixel   = 0
	swatch.Text              = ""
	swatch.Parent            = toolbar

	local sc = Instance.new("UICorner")
	sc.CornerRadius = UDim.new(1, 0)
	sc.Parent = swatch

	swatch.MouseButton1Click:Connect(function()
		selectedColor = col
	end)
end

-- ── Proximity Detection ──────────────────────────────────────
-- Show toolbar when player is within 15 studs of the wall

local INTERACT_DISTANCE = 15

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not graffitiWall then return end

	local dist = (root.Position - graffitiWall.Position).Magnitude
	toolbarGui.Enabled = dist <= INTERACT_DISTANCE
end)

-- ── Input Handling ───────────────────────────────────────────
-- Painting is done via click on the SurfaceGui canvas

canvas.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isPainting = true
	end
end)

canvas.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		isPainting = false
	end
end)

canvas.InputChanged:Connect(function(input)
	if not isPainting then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

	-- Normalize position to [0,1] within canvas
	local canvasSize = canvas.AbsoluteSize
	local relPos     = input.Position - Vector2.new(canvas.AbsolutePosition.X, canvas.AbsolutePosition.Y)
	local nx = math.clamp(relPos.X / canvasSize.X, 0, 1)
	local ny = math.clamp(relPos.Y / canvasSize.Y, 0, 1)

	-- Paint locally
	paintDot(nx, ny, selectedColor, selectedSize, LocalPlayer.DisplayName)

	-- Send to server
	GraffitiUpdated:FireServer(selectedColor, selectedSize, nx, ny)
end)

-- ── Receive Remote Strokes ───────────────────────────────────

GraffitiUpdated.OnClientEvent:Connect(function(
	playerName : string,
	color      : Color3,
	size       : number,
	nx         : number,
	ny         : number
)
	paintDot(nx, ny, color, size, playerName)
end)

print("[GraffitiClient] Loaded — canvas ready on GraffitiWall.")
