-- ============================================================
--  MidnightConfig.lua  (src/shared)
--  Data for the Midnight "Overlap" event — lore fragments,
--  echo student anchors, and timing constants.
-- ============================================================

local MidnightConfig = {

	-- How many real-world seconds = 1 in-game hour
	-- Default: 1 real minute = 1 in-game hour (24 min full day)
	SecondsPerHour = 60,

	-- Hour (0-23) at which the Overlap begins
	OverlapHour = 0,

	-- Duration of the sepia/ghost fade transition (seconds)
	TransitionTime = 8,

	-- How long the Overlap lasts before fading back (seconds)
	OverlapDuration = 300, -- 5 minutes

	-- Payphone lore fragments — one played randomly each midnight
	PayphoneLore = {
		[1] = "rbxassetid://0", -- placeholder — replace with actual audio IDs
		[2] = "rbxassetid://0",
		[3] = "rbxassetid://0",
		[4] = "rbxassetid://0",
		[5] = "rbxassetid://0",
	},

	-- Color grading for the sepia overlay during the Overlap
	SepiaColorCorrection = {
		TintColor   = Color3.fromRGB(210, 170, 110),
		Brightness  = -0.08,
		Contrast    = 0.15,
		Saturation  = -0.6,
	},

	-- NPC echo student spawn anchor names (Parts tagged "EchoAnchor" in Studio)
	EchoAnchors = {
		"EchoAnchor_DancerPulse",
		"EchoAnchor_ReaderGrind",
		"EchoAnchor_WatcherRoof",
		"EchoAnchor_LockerHall",
	},
}

return MidnightConfig
