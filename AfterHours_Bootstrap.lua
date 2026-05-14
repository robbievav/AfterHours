-- ============================================================
--  AfterHours_Bootstrap.lua
--  Paste this entire script into the Roblox Studio Command Bar
--  (View → Command Bar) and press Enter.
--
--  It will build every Part, Tool, RemoteEvent, tag, and
--  lighting instance that the AfterHours scripts expect.
--  Run it ONCE on a fresh place. Safe to re-run — it checks
--  before creating duplicates.
-- ============================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack       = game:GetService("StarterPack")
local Lighting          = game:GetService("Lighting")
local Players           = game:GetService("Players")

-- ── Utility ──────────────────────────────────────────────────

local function ensure(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA(className) then return existing end
	local inst = Instance.new(className)
	inst.Name   = name
	inst.Parent = parent
	return inst
end

local function makePart(parent, name, size, cframe, color, transparency, anchored)
	local p = ensure(parent, "Part", name)
	p.Size         = size         or Vector3.new(4, 4, 4)
	p.CFrame       = cframe       or CFrame.new(0, 3, 0)
	p.Color        = color        or Color3.fromRGB(180, 100, 255)
	p.Transparency = transparency or 0.8
	p.Anchored     = anchored     ~= false
	p.CanCollide   = false
	p.CastShadow   = false
	p.Material     = Enum.Material.Neon
	return p
end

print("╔══════════════════════════════════════╗")
print("║  AfterHours Bootstrap — Starting...  ║")
print("╚══════════════════════════════════════╝")

-- ── 1. ReplicatedStorage Remotes ─────────────────────────────

local Remotes = ensure(ReplicatedStorage, "Folder", "Remotes")
local remoteNames = {
	"ZoneChanged",
	"MidnightEvent",
	"GraffitiUpdated",
	"BoomboxFrequency",
	"DJBooth",
}
for _, name in remoteNames do
	ensure(Remotes, "RemoteEvent", name)
end
print("✅ RemoteEvents created in ReplicatedStorage.Remotes")

-- ── 2. Lighting Setup ─────────────────────────────────────────

Lighting.Ambient         = Color3.fromRGB(60, 40, 90)
Lighting.OutdoorAmbient  = Color3.fromRGB(30, 20, 50)
Lighting.Brightness      = 1.0
Lighting.FogEnd          = 300
Lighting.FogColor        = Color3.fromRGB(15, 10, 25)
Lighting.ClockTime       = 20  -- start at 8 PM visually

-- Atmosphere
local atmo = ensure(Lighting, "Atmosphere", "Atmosphere")
atmo.Density  = 0.3
atmo.Haze     = 0
atmo.Color    = Color3.fromRGB(120, 80, 180)
atmo.Decay    = Color3.fromRGB(60, 40, 100)
atmo.Glare    = 0
atmo.Offset   = 0

-- Color correction (starts neutral; MidnightClient tweens it)
local cc = ensure(Lighting, "ColorCorrectionEffect", "OverlapGrade")
cc.TintColor  = Color3.new(1, 1, 1)
cc.Brightness = 0
cc.Contrast   = 0
cc.Saturation = 0
cc.Enabled    = true

-- Bloom for neon glow
local bloom = ensure(Lighting, "BloomEffect", "NeonBloom")
bloom.Intensity   = 0.4
bloom.Size        = 24
bloom.Threshold   = 0.95

print("✅ Lighting configured (8 PM neon night, Atmosphere, Bloom, ColorCorrection)")

-- ── 3. Zone Trigger Parts ─────────────────────────────────────
--  These are large invisible boxes placed at placeholder positions.
--  Move them in Studio to match your actual room layouts!

local zonesFolder = ensure(workspace, "Folder", "Zones")

local zoneData = {
	-- { Name, Size, Position, NeonColor }
	{ "ThePulse",       Vector3.new(60, 20, 50),  Vector3.new(0,   10,  0),   Color3.fromRGB(220, 0, 255)  },
	{ "TheGrind",       Vector3.new(50, 15, 40),  Vector3.new(80,  8,   0),   Color3.fromRGB(255, 160, 40) },
	{ "TheArchive",     Vector3.new(40, 12, 35),  Vector3.new(-80, 7,   0),   Color3.fromRGB(100, 160, 255)},
	{ "TheObservatory", Vector3.new(50, 10, 50),  Vector3.new(0,   50, -80),  Color3.fromRGB(60, 80, 255)  },
	{ "TheOverlap",     Vector3.new(30, 12, 30),  Vector3.new(0,   5,  100),  Color3.fromRGB(180, 120, 60) },
}

for _, zd in zoneData do
	local name, size, pos, color = zd[1], zd[2], zd[3], zd[4]
	local part = makePart(
		zonesFolder,
		name,
		size,
		CFrame.new(pos),
		color,
		0.85,
		true
	)
	-- Tag for ZoneManager detection
	CollectionService:AddTag(part, "ZoneTrigger")

	-- Visual label
	local billboard = Instance.new("BillboardGui")
	billboard.Size              = UDim2.new(0, 160, 0, 40)
	billboard.StudsOffset       = Vector3.new(0, size.Y / 2 + 3, 0)
	billboard.AlwaysOnTop       = true
	billboard.Parent            = part

	local label = Instance.new("TextLabel")
	label.Size              = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3        = color
	label.Font              = Enum.Font.GothamBold
	label.TextSize          = 16
	label.Text              = "📍 " .. name
	label.Parent            = billboard
end

print("✅ Zone trigger parts created in workspace.Zones (tagged 'ZoneTrigger')")
print("   ⚠️  Move these boxes to match your actual room positions!")

-- ── 4. Graffiti Wall ─────────────────────────────────────────

local graffitiWall = ensure(workspace, "Part", "GraffitiWall")
graffitiWall.Size         = Vector3.new(40, 15, 1)
graffitiWall.CFrame       = CFrame.new(30, 8, -20)
graffitiWall.Color        = Color3.fromRGB(35, 25, 55)
graffitiWall.Material     = Enum.Material.SmoothPlastic
graffitiWall.Anchored     = true
graffitiWall.CanCollide   = true
graffitiWall.Transparency = 0

-- Neon border glow strip along the top
local glowStrip = ensure(graffitiWall, "Part", "GlowStrip")
if not glowStrip.Parent or glowStrip.Parent ~= graffitiWall then
	glowStrip = Instance.new("Part")
	glowStrip.Name   = "GlowStrip"
	glowStrip.Parent = graffitiWall
end
glowStrip.Size         = Vector3.new(40, 0.4, 0.3)
glowStrip.CFrame       = graffitiWall.CFrame * CFrame.new(0, 7.7, -0.6)
glowStrip.Color        = Color3.fromRGB(200, 0, 255)
glowStrip.Material     = Enum.Material.Neon
glowStrip.Anchored     = true
glowStrip.CanCollide   = false

-- Proximity prompt so players know to walk up
local prox = ensure(graffitiWall, "ProximityPrompt", "GraffitiPrompt")
prox.ActionText     = "Paint"
prox.ObjectText     = "Graffiti Wall"
prox.KeyboardKeyCode = Enum.KeyCode.E
prox.MaxActivationDistance = 15

print("✅ GraffitiWall placed at (30, 8, -20) — move it to your hallway/cafeteria wall")

-- ── 5. DJ Booth ──────────────────────────────────────────────

local djModel = ensure(workspace, "Model", "DJBooth")

local djBase = ensure(djModel, "Part", "Base")
djBase.Size       = Vector3.new(8, 3, 4)
djBase.CFrame     = CFrame.new(-30, 1.5, -20)
djBase.Color      = Color3.fromRGB(25, 15, 40)
djBase.Material   = Enum.Material.SmoothPlastic
djBase.Anchored   = true

local djTop = ensure(djModel, "Part", "DeckTop")
djTop.Size        = Vector3.new(7.5, 0.2, 3.5)
djTop.CFrame      = CFrame.new(-30, 3.1, -20)
djTop.Color       = Color3.fromRGB(15, 10, 25)
djTop.Material    = Enum.Material.SmoothPlastic
djTop.Anchored    = true

-- Neon accent strip on front
local djGlow = ensure(djModel, "Part", "DJGlow")
djGlow.Size       = Vector3.new(7.8, 0.3, 0.2)
djGlow.CFrame     = CFrame.new(-30, 2, -22.1)
djGlow.Color      = Color3.fromRGB(180, 0, 255)
djGlow.Material   = Enum.Material.Neon
djGlow.Anchored   = true
djGlow.CanCollide = false

-- Proximity prompt
local djProx = ensure(djBase, "ProximityPrompt", "DJPrompt")
djProx.ActionText    = "Claim Deck"
djProx.ObjectText    = "DJ Booth"
djProx.MaxActivationDistance = 12

djModel.PrimaryPart = djBase
print("✅ DJ Booth model placed at (-30, 0, -20)")

-- ── 6. Boombox Tool ──────────────────────────────────────────

local boombox = ensure(StarterPack, "Tool", "Boombox")
boombox.RequiresHandle = true
boombox.ToolTip        = "Tune a frequency and share music with nearby players"

-- Handle (the physical boombox body)
local handle = ensure(boombox, "Part", "Handle")
handle.Size     = Vector3.new(2, 1, 0.6)
handle.Color    = Color3.fromRGB(30, 20, 50)
handle.Material = Enum.Material.SmoothPlastic

-- Neon speaker grilles
local grille = ensure(handle, "Part", "Grille")
grille.Size       = Vector3.new(0.8, 0.7, 0.1)
grille.CFrame     = handle.CFrame * CFrame.new(-0.5, 0, 0.35)
grille.Color      = Color3.fromRGB(255, 180, 40)
grille.Material   = Enum.Material.Neon
grille.CanCollide = false
local weld1 = Instance.new("WeldConstraint")
weld1.Part0 = handle; weld1.Part1 = grille; weld1.Parent = handle

-- BillboardGui showing frequency
local freqBillboard = Instance.new("BillboardGui")
freqBillboard.Name        = "FreqDisplay"
freqBillboard.Size        = UDim2.new(0, 60, 0, 20)
freqBillboard.StudsOffset = Vector3.new(0, 1.5, 0)
freqBillboard.AlwaysOnTop = false
freqBillboard.Parent      = handle

local freqLabel = Instance.new("TextLabel")
freqLabel.Size              = UDim2.fromScale(1, 1)
freqLabel.BackgroundTransparency = 1
freqLabel.TextColor3        = Color3.fromRGB(255, 220, 80)
freqLabel.Font              = Enum.Font.GothamBold
freqLabel.TextSize          = 13
freqLabel.Text              = "📻 —"
freqLabel.Parent            = freqBillboard

print("✅ Boombox tool added to StarterPack")

-- ── 7. Boiler Room Door ───────────────────────────────────────

local boilerDoor = ensure(workspace, "Part", "BoilerRoomDoor")
boilerDoor.Size         = Vector3.new(6, 10, 1)
boilerDoor.CFrame       = CFrame.new(0, 5, 100)
boilerDoor.Color        = Color3.fromRGB(60, 40, 20)
boilerDoor.Material     = Enum.Material.Brick
boilerDoor.Anchored     = true
boilerDoor.CanCollide   = true  -- MidnightManager sets this to false at midnight
boilerDoor.Transparency = 0

-- Creepy "Do Not Enter" decal placeholder
local decal = ensure(boilerDoor, "Decal", "BoilerSign")
decal.Face    = Enum.NormalId.Front
decal.Texture = "rbxassetid://0" -- replace with a "Do Not Enter" decal ID

print("✅ BoilerRoomDoor placed at (0, 5, 100) — only passable at midnight")

-- ── 8. Payphone ───────────────────────────────────────────────

local payphoneModel = ensure(workspace, "Model", "Payphone")

local payphoneBase = ensure(payphoneModel, "Part", "Base")
payphoneBase.Size     = Vector3.new(1.5, 5, 1.5)
payphoneBase.CFrame   = CFrame.new(5, 2.5, 110)
payphoneBase.Color    = Color3.fromRGB(40, 80, 40)
payphoneBase.Material = Enum.Material.SmoothPlastic
payphoneBase.Anchored = true

-- The ring sound (MidnightManager sets SoundId at runtime)
local ringSound = ensure(payphoneBase, "Sound", "Ring")
ringSound.SoundId  = "rbxassetid://0"
ringSound.Volume   = 0.8
ringSound.Looped   = false
ringSound.RollOffMaxDistance = 40

-- Proximity prompt to "answer" the phone
local phoneProx = ensure(payphoneBase, "ProximityPrompt", "AnswerPrompt")
phoneProx.ActionText    = "Answer"
phoneProx.ObjectText    = "Payphone"
phoneProx.MaxActivationDistance = 8
phoneProx.Enabled       = false  -- MidnightManager enables this at midnight

payphoneModel.PrimaryPart = payphoneBase
print("✅ Payphone placed at (5, 0, 110) inside Boiler Room area")

-- ── 9. Echo Student Anchors ───────────────────────────────────

local echoFolder = ensure(workspace, "Folder", "EchoAnchors")

local anchorData = {
	{ "EchoAnchor_DancerPulse",  Vector3.new(0,   0,  0)   }, -- inside The Pulse
	{ "EchoAnchor_ReaderGrind",  Vector3.new(80,  0,  10)  }, -- cafeteria table
	{ "EchoAnchor_WatcherRoof",  Vector3.new(5,   50, -85) }, -- rooftop edge
	{ "EchoAnchor_LockerHall",   Vector3.new(-10, 0,  50)  }, -- hallway
}

for _, ad in anchorData do
	local name, pos = ad[1], ad[2]
	local anchor = ensure(echoFolder, "Part", name)
	anchor.Size         = Vector3.new(1, 0.2, 1)
	anchor.CFrame       = CFrame.new(pos)
	anchor.Anchored     = true
	anchor.CanCollide   = false
	anchor.Transparency = 1
	CollectionService:AddTag(anchor, "EchoAnchor")
end

print("✅ Echo Student anchor parts placed (4 anchors, tagged 'EchoAnchor')")

-- ── 10. Basic School Geometry Scaffold ────────────────────────
--  A minimal block layout so you have something to walk around.
--  Replace these with your actual Studio models!

local mapFolder = ensure(workspace, "Folder", "MapScaffold")

local function makeFloor(name, size, pos, color)
	local f = ensure(mapFolder, "Part", name)
	f.Size       = size
	f.CFrame     = CFrame.new(pos)
	f.Color      = color
	f.Material   = Enum.Material.SmoothPlastic
	f.Anchored   = true
	f.CanCollide = true
	return f
end

makeFloor("GroundPlate",      Vector3.new(300, 1, 300),  Vector3.new(0, -0.5, 0),    Color3.fromRGB(20, 15, 30))
makeFloor("Floor_Gymnasium",  Vector3.new(60, 1, 50),    Vector3.new(0, 0, 0),        Color3.fromRGB(30, 10, 50))
makeFloor("Floor_Cafeteria",  Vector3.new(50, 1, 40),    Vector3.new(80, 0, 0),       Color3.fromRGB(35, 20, 10))
makeFloor("Floor_Library",    Vector3.new(40, 1, 35),    Vector3.new(-80, 0, 0),      Color3.fromRGB(10, 15, 30))
makeFloor("Floor_Rooftop",    Vector3.new(50, 1, 50),    Vector3.new(0, 50, -80),     Color3.fromRGB(15, 15, 25))
makeFloor("Floor_BoilerRoom", Vector3.new(30, 1, 30),    Vector3.new(0, 0, 100),      Color3.fromRGB(25, 18, 10))

print("✅ Map scaffold plates placed (replace with your actual Studio builds)")

-- ── Done ─────────────────────────────────────────────────────

print("")
print("╔══════════════════════════════════════════════════════════╗")
print("║  ✅  AfterHours Bootstrap Complete!                      ║")
print("║                                                          ║")
print("║  What was created:                                       ║")
print("║  • 5 RemoteEvents in ReplicatedStorage.Remotes          ║")
print("║  • Lighting (night mode, Bloom, ColorCorrection)        ║")
print("║  • 5 Zone trigger parts (tagged ZoneTrigger)            ║")
print("║  • GraffitiWall (with ProximityPrompt)                  ║")
print("║  • DJBooth model (with ProximityPrompt)                 ║")
print("║  • Boombox Tool in StarterPack                          ║")
print("║  • BoilerRoomDoor (solid until midnight)                ║")
print("║  • Payphone model (activates at midnight)               ║")
print("║  • 4 Echo Student anchor parts                          ║")
print("║  • Basic floor scaffold for 5 zones                     ║")
print("║                                                          ║")
print("║  ⚠️  Next steps:                                         ║")
print("║  1. Move Zone boxes to match your room layout           ║")
print("║  2. Replace placeholder audio IDs in ZoneConfig.lua    ║")
print("║  3. Replace scaffold floors with your actual builds     ║")
print("╚══════════════════════════════════════════════════════════╝")
