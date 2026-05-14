-- ============================================================
--  MidnightClient.client.lua  (src/client)
--  Handles the visual side of the Midnight "Overlap" event:
--    - Sepia ColorCorrectionEffect on the camera
--    - Atmosphere property tweens (eerie haze)
--    - Screen vignette fade
-- ============================================================

local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")

local MidnightConfig = require(ReplicatedStorage.Shared.MidnightConfig)
local MidnightEvent: RemoteEvent = ReplicatedStorage.Remotes.MidnightEvent

-- ── Color Correction ─────────────────────────────────────────

local colorCorrection = Instance.new("ColorCorrectionEffect")
colorCorrection.Name       = "OverlapGrade"
colorCorrection.TintColor  = Color3.new(1, 1, 1)
colorCorrection.Brightness = 0
colorCorrection.Contrast   = 0
colorCorrection.Saturation = 0
colorCorrection.Enabled    = true
colorCorrection.Parent     = Lighting

-- ── Atmosphere ───────────────────────────────────────────────

-- Find or create Atmosphere instance
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)

local DEFAULT_ATMOSPHERE = {
	Density   = 0.3,
	Offset    = 0,
	Color     = Color3.fromRGB(199, 199, 199),
	Decay     = Color3.fromRGB(106, 127, 153),
	Glare     = 0,
	Haze      = 0,
}

local OVERLAP_ATMOSPHERE = {
	Density   = 0.7,
	Offset    = 0.5,
	Color     = Color3.fromRGB(180, 150, 100),
	Decay     = Color3.fromRGB(80, 60, 30),
	Glare     = 0,
	Haze      = 2.5,
}

-- ── Transition Logic ─────────────────────────────────────────

local transitionTime = MidnightConfig.TransitionTime
local tweenInfo = TweenInfo.new(transitionTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local function applyOverlap()
	local sep = MidnightConfig.SepiaColorCorrection

	TweenService:Create(colorCorrection, tweenInfo, {
		TintColor  = sep.TintColor,
		Brightness = sep.Brightness,
		Contrast   = sep.Contrast,
		Saturation = sep.Saturation,
	}):Play()

	TweenService:Create(atmosphere, tweenInfo, OVERLAP_ATMOSPHERE):Play()

	-- Subtle ambient light shift
	TweenService:Create(Lighting, tweenInfo, {
		Ambient    = Color3.fromRGB(120, 90, 60),
		Brightness = 0.4,
	}):Play()
end

local function revertOverlap()
	TweenService:Create(colorCorrection, tweenInfo, {
		TintColor  = Color3.new(1, 1, 1),
		Brightness = 0,
		Contrast   = 0,
		Saturation = 0,
	}):Play()

	TweenService:Create(atmosphere, tweenInfo, DEFAULT_ATMOSPHERE):Play()
end

-- ── Listen ───────────────────────────────────────────────────

MidnightEvent.OnClientEvent:Connect(function(isBeginning: boolean)
	if isBeginning then
		applyOverlap()
	else
		revertOverlap()
	end
end)

print("[MidnightClient] Loaded — sepia overlay standing by.")
