-- ============================================================
--  ZoneConfig.lua  (src/shared)
--  Single Source of Truth for all Vibe Zone data.
--  To add a new zone: add one entry here + tag a Part in Studio.
-- ============================================================

export type ZoneData = {
	MusicId     : string,
	MusicVolume : number,
	Ambient     : Color3,
	Brightness  : number,
	FogEnd      : number,
	FogColor    : Color3,
	ReverbPreset: Enum.ReverbType,
}

local ZoneConfig: { [string]: ZoneData } = {

	-- 🎵 The Pulse — Gymnasium / Neon Dance Hall
	ThePulse = {
		MusicId      = "rbxassetid://1836909967", -- synthwave/EDM
		MusicVolume  = 0.9,
		Ambient      = Color3.fromRGB(180, 0, 255),
		Brightness   = 3.5,
		FogEnd       = 80,
		FogColor     = Color3.fromRGB(20, 0, 40),
		ReverbPreset = Enum.ReverbType.Arena,
	},

	-- ☕ The Grind — Cafeteria / Lo-Fi Café
	TheGrind = {
		MusicId      = "rbxassetid://1843671399", -- lo-fi hip-hop
		MusicVolume  = 0.45,
		Ambient      = Color3.fromRGB(255, 180, 80),
		Brightness   = 1.2,
		FogEnd       = 200,
		FogColor     = Color3.fromRGB(30, 20, 10),
		ReverbPreset = Enum.ReverbType.SmallRoom,
	},

	-- 📚 The Archive — Library / Liminal Quiet Zone
	TheArchive = {
		MusicId      = "rbxassetid://1838673291", -- ambient drone
		MusicVolume  = 0.2,
		Ambient      = Color3.fromRGB(160, 200, 255),
		Brightness   = 0.8,
		FogEnd       = 60,
		FogColor     = Color3.fromRGB(10, 10, 20),
		ReverbPreset = Enum.ReverbType.ConcertHall,
	},

	-- 🌌 The Observatory — Rooftop / Stargazing Hub
	TheObservatory = {
		MusicId      = "rbxassetid://1843355799", -- city ambience + lo-fi
		MusicVolume  = 0.5,
		Ambient      = Color3.fromRGB(80, 100, 255),
		Brightness   = 0.5,
		FogEnd       = 500,
		FogColor     = Color3.fromRGB(5, 5, 15),
		ReverbPreset = Enum.ReverbType.NoReverb,
	},

	-- 🕛 The Overlap — Boiler Room / Midnight Liminal Space
	TheOverlap = {
		MusicId      = "rbxassetid://1847323587", -- eerie reversed ambience
		MusicVolume  = 0.35,
		Ambient      = Color3.fromRGB(120, 90, 60),
		Brightness   = 0.4,
		FogEnd       = 30,
		FogColor     = Color3.fromRGB(40, 30, 20),
		ReverbPreset = Enum.ReverbType.Cavern,
	},
}

return ZoneConfig
