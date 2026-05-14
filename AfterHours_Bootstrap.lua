-- ============================================================
--  AfterHours_Bootstrap.lua  — v2
--  Paste this entire script into the Roblox Studio Command Bar
--  (View → Command Bar) and press Enter.
--
--  Builds every Part, Tool, RemoteEvent, tag, lighting, and
--  GUI anchor that the AfterHours scripts need.
--  Safe to re-run — checks for duplicates before creating.
--
--  Systems covered:
--    ✅ Zone trigger boxes (5 zones)
--    ✅ RemoteEvents (all 8)
--    ✅ Lighting (night mode, Bloom, ColorCorrection, Atmosphere)
--    ✅ Graffiti Wall
--    ✅ DJ Booth
--    ✅ Boombox Tool (StarterPack)
--    ✅ Boiler Room Door
--    ✅ Payphone
--    ✅ Echo Student anchors
--    ✅ Cafeteria Chalkboard
--    ✅ Rooftop Telescope
--    ✅ Floor scaffold (5 zones)
-- ============================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack       = game:GetService("StarterPack")
local Lighting          = game:GetService("Lighting")

-- ── Utility ──────────────────────────────────────────────────

local function ensure(parent, className, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA(className) then return existing end
	local inst = Instance.new(className)
	inst.Name   = name
	inst.Parent = parent
	return inst
end

local function makeBasePart(parent, name, size, cframe, color, material, transparency, canCollide)
	local p = ensure(parent, "Part", name)
	p.Size         = size         or Vector3.new(4, 4, 4)
	p.CFrame       = cframe       or CFrame.new(0, 3, 0)
	p.Color        = color        or Color3.fromRGB(180, 100, 255)
	p.Material     = material     or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.CanCollide   = canCollide   ~= false
	p.Anchored     = true
	p.CastShadow   = false
	return p
end

local function addProximityPrompt(parent, name, action, obj, dist)
	local pp = ensure(parent, "ProximityPrompt", name)
	pp.ActionText              = action
	pp.ObjectText              = obj
	pp.KeyboardKeyCode         = Enum.KeyCode.E
	pp.MaxActivationDistance   = dist or 10
	return pp
end

local function addBillboardLabel(part, text, color, yOffset)
	local bb = Instance.new("BillboardGui")
	bb.Size          = UDim2.fromOffset(180, 36)
	bb.StudsOffset   = Vector3.new(0, yOffset or 4, 0)
	bb.AlwaysOnTop   = true
	bb.Parent        = part
	local lbl = Instance.new("TextLabel")
	lbl.Size              = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.TextColor3        = color or Color3.new(1, 1, 1)
	lbl.Font              = Enum.Font.GothamBold
	lbl.TextSize          = 15
	lbl.Text              = text
	lbl.Parent            = bb
	return bb
end

print("╔══════════════════════════════════════════╗")
print("║  AfterHours Bootstrap v2 — Starting...  ║")
print("╚══════════════════════════════════════════╝")

-- ──────────────────────────────────────────────────────────────
-- 1. REMOTE EVENTS
-- ──────────────────────────────────────────────────────────────

local Remotes = ensure(ReplicatedStorage, "Folder", "Remotes")
local remoteNames = {
	"ZoneChanged",
	"MidnightEvent",
	"GraffitiUpdated",
	"BoomboxFrequency",
	"DJBooth",
	"EmoteChanged",
	"ClockSync",
	"ChalkboardUpdated",
}
for _, name in remoteNames do
	ensure(Remotes, "RemoteEvent", name)
end
print("✅ [1/12] RemoteEvents created:", #remoteNames, "events in ReplicatedStorage.Remotes")

-- ──────────────────────────────────────────────────────────────
-- 2. LIGHTING
-- ──────────────────────────────────────────────────────────────

Lighting.Ambient         = Color3.fromRGB(60, 40, 90)
Lighting.OutdoorAmbient  = Color3.fromRGB(30, 20, 50)
Lighting.Brightness      = 1.0
Lighting.FogEnd          = 300
Lighting.FogColor        = Color3.fromRGB(15, 10, 25)
Lighting.ClockTime       = 20  -- 8 PM

local atmo = ensure(Lighting, "Atmosphere", "Atmosphere")
atmo.Density  = 0.3
atmo.Haze     = 0
atmo.Color    = Color3.fromRGB(120, 80, 180)
atmo.Decay    = Color3.fromRGB(60, 40, 100)
atmo.Glare    = 0
atmo.Offset   = 0

local cc = ensure(Lighting, "ColorCorrectionEffect", "OverlapGrade")
cc.TintColor  = Color3.new(1, 1, 1)
cc.Brightness = 0
cc.Contrast   = 0
cc.Saturation = 0
cc.Enabled    = true

local bloom = ensure(Lighting, "BloomEffect", "NeonBloom")
bloom.Intensity  = 0.4
bloom.Size       = 24
bloom.Threshold  = 0.95

print("✅ [2/12] Lighting — neon night, Atmosphere, Bloom, ColorCorrection")

-- ──────────────────────────────────────────────────────────────
-- 3. ZONE TRIGGER BOXES
-- ──────────────────────────────────────────────────────────────

local zonesFolder = ensure(workspace, "Folder", "Zones")

local zoneData = {
	-- { Name,            Size,                       Position,                NeonColor }
	{ "ThePulse",       Vector3.new(60, 20, 50),  Vector3.new(0,   10,  0),   Color3.fromRGB(220, 0,  255)  },
	{ "TheGrind",       Vector3.new(50, 15, 40),  Vector3.new(80,  8,   0),   Color3.fromRGB(255, 160, 40)  },
	{ "TheArchive",     Vector3.new(40, 12, 35),  Vector3.new(-80, 7,   0),   Color3.fromRGB(100, 160, 255) },
	{ "TheObservatory", Vector3.new(50, 10, 50),  Vector3.new(0,   50, -80),  Color3.fromRGB(60,  80,  255) },
	{ "TheOverlap",     Vector3.new(30, 12, 30),  Vector3.new(0,   5,  100),  Color3.fromRGB(180, 120, 60)  },
}

for _, zd in zoneData do
	local name, size, pos, color = zd[1], zd[2], zd[3], zd[4]
	local part = makeBasePart(
		zonesFolder, name, size, CFrame.new(pos),
		color, Enum.Material.Neon, 0.85, false
	)
	CollectionService:AddTag(part, "ZoneTrigger")
	addBillboardLabel(part, "📍 " .. name, color, size.Y / 2 + 3)
end

print("✅ [3/12] Zone triggers — 5 boxes tagged 'ZoneTrigger' in workspace.Zones")
print("   ⚠️  Move these to match your actual room positions!")

-- ──────────────────────────────────────────────────────────────
-- 4. GRAFFITI WALL
-- ──────────────────────────────────────────────────────────────

local graffitiWall = makeBasePart(
	workspace, "GraffitiWall",
	Vector3.new(40, 15, 1),
	CFrame.new(30, 8, -20),
	Color3.fromRGB(35, 25, 55),
	Enum.Material.SmoothPlastic, 0, true
)

-- Neon glow strip along top
local glowStrip = makeBasePart(
	workspace, "GraffitiGlowStrip",
	Vector3.new(40, 0.4, 0.3),
	CFrame.new(30, 15.7, -20.6),
	Color3.fromRGB(200, 0, 255),
	Enum.Material.Neon, 0, false
)

addProximityPrompt(graffitiWall, "GraffitiPrompt", "Paint", "Graffiti Wall", 15)
print("✅ [4/12] GraffitiWall at (30, 8, -20)")

-- ──────────────────────────────────────────────────────────────
-- 5. DJ BOOTH
-- ──────────────────────────────────────────────────────────────

local djModel = ensure(workspace, "Model", "DJBooth")

local djBase = makeBasePart(
	djModel, "Base",
	Vector3.new(8, 3, 4), CFrame.new(-30, 1.5, -20),
	Color3.fromRGB(25, 15, 40), Enum.Material.SmoothPlastic, 0, true
)

local djTop = makeBasePart(
	djModel, "DeckTop",
	Vector3.new(7.5, 0.2, 3.5), CFrame.new(-30, 3.1, -20),
	Color3.fromRGB(15, 10, 25), Enum.Material.SmoothPlastic, 0, true
)

makeBasePart(
	djModel, "DJGlow",
	Vector3.new(7.8, 0.3, 0.2), CFrame.new(-30, 2, -22.1),
	Color3.fromRGB(180, 0, 255), Enum.Material.Neon, 0, false
)

djModel.PrimaryPart = djBase
addProximityPrompt(djBase, "DJPrompt", "Claim Deck", "DJ Booth", 12)
addBillboardLabel(djBase, "🎚️  DJ Booth", Color3.fromRGB(200, 100, 255), 4)
print("✅ [5/12] DJ Booth at (-30, 0, -20)")

-- ──────────────────────────────────────────────────────────────
-- 6. CHALKBOARD (Cafeteria — TheGrind zone)
-- ──────────────────────────────────────────────────────────────

local chalkboard = makeBasePart(
	workspace, "Chalkboard",
	Vector3.new(28, 14, 1),
	CFrame.new(80, 8, -18),   -- inside TheGrind scaffold position
	Color3.fromRGB(22, 52, 32),
	Enum.Material.SmoothPlastic, 0, true
)

-- Wooden frame around it
makeBasePart(
	workspace, "ChalkboardFrame",
	Vector3.new(29.5, 15.5, 0.6),
	CFrame.new(80, 8, -17.7),
	Color3.fromRGB(80, 45, 20),
	Enum.Material.WoodPlanks, 0, false
)

-- Chalk tray at the bottom
makeBasePart(
	workspace, "ChalkTray",
	Vector3.new(28, 0.5, 1.5),
	CFrame.new(80, 0.9, -18.5),
	Color3.fromRGB(100, 60, 25),
	Enum.Material.Wood, 0, true
)

addProximityPrompt(chalkboard, "ChalkboardPrompt", "Edit Menu", "Chalkboard", 12)
addBillboardLabel(chalkboard, "☕  Tonight's Menu", Color3.fromRGB(200, 240, 160), 9)
print("✅ [6/12] Chalkboard at (80, 8, -18) — in TheGrind cafeteria")

-- ──────────────────────────────────────────────────────────────
-- 7. ROOFTOP TELESCOPE (TheObservatory zone)
-- ──────────────────────────────────────────────────────────────

local telescopeModel = ensure(workspace, "Model", "Telescope")

local teleBase = makeBasePart(
	telescopeModel, "Base",
	Vector3.new(1.5, 1, 1.5), CFrame.new(10, 51.5, -82),
	Color3.fromRGB(60, 60, 80), Enum.Material.Metal, 0, true
)

local teleTube = makeBasePart(
	telescopeModel, "Tube",
	Vector3.new(0.6, 4, 0.6),
	CFrame.new(10, 53.5, -82) * CFrame.Angles(math.rad(-30), 0, 0),
	Color3.fromRGB(50, 50, 70), Enum.Material.Metal, 0, true
)

local teleLens = makeBasePart(
	telescopeModel, "Lens",
	Vector3.new(0.9, 0.9, 0.9), CFrame.new(10, 55.2, -83.2),
	Color3.fromRGB(80, 180, 255), Enum.Material.Neon, 0.3, false
)

telescopeModel.PrimaryPart = teleBase
addProximityPrompt(teleBase, "TelescopePrompt", "Look Through", "Telescope", 8)
addBillboardLabel(teleBase, "🌌  Telescope", Color3.fromRGB(100, 150, 255), 5)
print("✅ [7/12] Telescope at (10, 51, -82) — on TheObservatory rooftop")

-- ──────────────────────────────────────────────────────────────
-- 8. BOOMBOX TOOL
-- ──────────────────────────────────────────────────────────────

local boombox = ensure(StarterPack, "Tool", "Boombox")
boombox.RequiresHandle = true
boombox.ToolTip        = "Tune a frequency — share music with players on the same channel"

local handle = ensure(boombox, "Part", "Handle")
handle.Size     = Vector3.new(2, 1, 0.6)
handle.Color    = Color3.fromRGB(30, 20, 50)
handle.Material = Enum.Material.SmoothPlastic

-- Speaker grille glow
local grille = ensure(handle, "Part", "Grille")
grille.Size       = Vector3.new(0.8, 0.7, 0.1)
grille.CFrame     = handle.CFrame * CFrame.new(-0.5, 0, 0.35)
grille.Color      = Color3.fromRGB(255, 180, 40)
grille.Material   = Enum.Material.Neon
grille.CanCollide = false

local weld = Instance.new("WeldConstraint")
weld.Part0 = handle; weld.Part1 = grille; weld.Parent = handle

-- Frequency display billboard
local freqBb = Instance.new("BillboardGui")
freqBb.Name        = "FreqDisplay"
freqBb.Size        = UDim2.fromOffset(60, 20)
freqBb.StudsOffset = Vector3.new(0, 1.5, 0)
freqBb.Parent      = handle

local freqLbl = Instance.new("TextLabel")
freqLbl.Size              = UDim2.fromScale(1, 1)
freqLbl.BackgroundTransparency = 1
freqLbl.TextColor3        = Color3.fromRGB(255, 220, 80)
freqLbl.Font              = Enum.Font.GothamBold
freqLbl.TextSize          = 13
freqLbl.Text              = "📻 —"
freqLbl.Parent            = freqBb

print("✅ [8/12] Boombox Tool added to StarterPack")

-- ──────────────────────────────────────────────────────────────
-- 9. BOILER ROOM DOOR
-- ──────────────────────────────────────────────────────────────

local boilerDoor = makeBasePart(
	workspace, "BoilerRoomDoor",
	Vector3.new(6, 10, 1), CFrame.new(0, 5, 100),
	Color3.fromRGB(60, 40, 20), Enum.Material.Brick, 0, true
)
addBillboardLabel(boilerDoor, "🚫  Boiler Room", Color3.fromRGB(200, 100, 60), 7)
print("✅ [9/12] BoilerRoomDoor at (0, 5, 100) — solid until midnight")

-- ──────────────────────────────────────────────────────────────
-- 10. PAYPHONE
-- ──────────────────────────────────────────────────────────────

local payphoneModel = ensure(workspace, "Model", "Payphone")

local payphoneBase = makeBasePart(
	payphoneModel, "Base",
	Vector3.new(1.5, 5, 1.5), CFrame.new(5, 2.5, 110),
	Color3.fromRGB(40, 80, 40), Enum.Material.SmoothPlastic, 0, true
)

local payphoneScreen = makeBasePart(
	payphoneModel, "Screen",
	Vector3.new(0.9, 1.2, 0.1), CFrame.new(5, 3.2, 109.3),
	Color3.fromRGB(20, 180, 80), Enum.Material.Neon, 0.4, false
)

local ringSound = ensure(payphoneBase, "Sound", "Ring")
ringSound.SoundId  = "rbxassetid://0"  -- replace with your ring audio ID
ringSound.Volume   = 0.8
ringSound.Looped   = false
ringSound.RollOffMaxDistance = 40

local phonePrompt = addProximityPrompt(payphoneBase, "AnswerPrompt", "Answer", "Payphone", 8)
phonePrompt.Enabled = false  -- MidnightManager enables this at midnight

payphoneModel.PrimaryPart = payphoneBase
addBillboardLabel(payphoneBase, "☎  Payphone", Color3.fromRGB(80, 200, 100), 5)
print("✅ [10/12] Payphone at (5, 0, 110) — activates at midnight")

-- ──────────────────────────────────────────────────────────────
-- 11. ECHO STUDENT ANCHORS
-- ──────────────────────────────────────────────────────────────

local echoFolder = ensure(workspace, "Folder", "EchoAnchors")

local anchorData = {
	{ "EchoAnchor_DancerPulse",  Vector3.new(0,    0,  10)  },  -- gym dance floor
	{ "EchoAnchor_ReaderGrind",  Vector3.new(80,   0,  10)  },  -- cafeteria table
	{ "EchoAnchor_WatcherRoof",  Vector3.new(5,   50, -85)  },  -- rooftop edge
	{ "EchoAnchor_LockerHall",   Vector3.new(-10,  0,  50)  },  -- hallway
}

for _, ad in anchorData do
	local name, pos = ad[1], ad[2]
	local anchor = makeBasePart(
		echoFolder, name,
		Vector3.new(1, 0.2, 1), CFrame.new(pos),
		Color3.fromRGB(200, 220, 255), Enum.Material.Neon, 1, false
	)
	CollectionService:AddTag(anchor, "EchoAnchor")
end

print("✅ [11/12] Echo Student anchors — 4 parts tagged 'EchoAnchor'")

-- ──────────────────────────────────────────────────────────────
-- 12. FLOOR SCAFFOLD
-- ──────────────────────────────────────────────────────────────

local mapFolder = ensure(workspace, "Folder", "MapScaffold")

local floors = {
	{ "GroundPlate",      Vector3.new(300, 1, 300),  Vector3.new(0,   -0.5,  0),   Color3.fromRGB(20,  15, 30) },
	{ "Floor_Gymnasium",  Vector3.new(60,  1, 50),   Vector3.new(0,   0,     0),   Color3.fromRGB(30,  10, 50) },
	{ "Floor_Cafeteria",  Vector3.new(50,  1, 40),   Vector3.new(80,  0,     0),   Color3.fromRGB(35,  20, 10) },
	{ "Floor_Library",    Vector3.new(40,  1, 35),   Vector3.new(-80, 0,     0),   Color3.fromRGB(10,  15, 30) },
	{ "Floor_Rooftop",    Vector3.new(50,  1, 50),   Vector3.new(0,   50,  -80),   Color3.fromRGB(15,  15, 25) },
	{ "Floor_BoilerRoom", Vector3.new(30,  1, 30),   Vector3.new(0,   0,   100),   Color3.fromRGB(25,  18, 10) },
}

for _, fd in floors do
	local name, size, pos, color = fd[1], fd[2], fd[3], fd[4]
	makeBasePart(mapFolder, name, size, CFrame.new(pos), color,
		Enum.Material.SmoothPlastic, 0, true)
end

print("✅ [12/12] Floor scaffold — 6 plates (replace with your actual builds)")

-- ──────────────────────────────────────────────────────────────
-- DONE
-- ──────────────────────────────────────────────────────────────

print("")
print("╔════════════════════════════════════════════════════════════╗")
print("║  ✅  AfterHours Bootstrap v2 Complete!                    ║")
print("║                                                            ║")
print("║  Created / verified:                                       ║")
print("║   [1]  8 RemoteEvents in ReplicatedStorage.Remotes        ║")
print("║   [2]  Lighting — night, Bloom, ColorCorrection, Atmo     ║")
print("║   [3]  5 Zone trigger boxes (tagged ZoneTrigger)          ║")
print("║   [4]  Graffiti Wall + neon glow strip                    ║")
print("║   [5]  DJ Booth model                                     ║")
print("║   [6]  Cafeteria Chalkboard + frame + chalk tray          ║")
print("║   [7]  Rooftop Telescope model                            ║")
print("║   [8]  Boombox Tool in StarterPack                        ║")
print("║   [9]  Boiler Room Door (solid until midnight)            ║")
print("║  [10]  Payphone (activates at midnight)                   ║")
print("║  [11]  4 Echo Student anchor parts                        ║")
print("║  [12]  Floor scaffold for 5 zones                         ║")
print("║                                                            ║")
print("║  ⚠️  Next steps in Studio:                                 ║")
print("║   1. MOVE zone boxes to match your room layout            ║")
print("║   2. Replace placeholder audio IDs in ZoneConfig.lua     ║")
print("║   3. Replace scaffold floors with your actual builds      ║")
print("║   4. Press G in playtest to open the emote wheel         ║")
print("╚════════════════════════════════════════════════════════════╝")
