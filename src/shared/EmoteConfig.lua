-- ============================================================
--  EmoteConfig.lua  (src/shared)
--  All emote data in one place. Add new emotes here only.
--  AnimationIds are Roblox catalog animation asset IDs.
-- ============================================================

export type EmoteData = {
	DisplayName : string,
	Icon        : string,   -- emoji or rbxassetid image
	AnimationId : string,
	Looped      : boolean,
	Category    : string,
}

local EmoteConfig: { [string]: EmoteData } = {

	-- ── Chill ─────────────────────────────────────────────────
	Wave = {
		DisplayName = "Wave",
		Icon        = "👋",
		AnimationId = "rbxassetid://507770239",  -- Roblox default wave
		Looped      = false,
		Category    = "Chill",
	},
	Sit = {
		DisplayName = "Sit",
		Icon        = "🪑",
		AnimationId = "rbxassetid://2506281703", -- sit
		Looped      = true,
		Category    = "Chill",
	},
	Lean = {
		DisplayName = "Lean",
		Icon        = "😎",
		AnimationId = "rbxassetid://507770239",  -- placeholder (replace)
		Looped      = true,
		Category    = "Chill",
	},
	Think = {
		DisplayName = "Think",
		Icon        = "🤔",
		AnimationId = "rbxassetid://507770453",  -- Roblox default think
		Looped      = false,
		Category    = "Chill",
	},

	-- ── Dance ─────────────────────────────────────────────────
	Dance = {
		DisplayName = "Dance",
		Icon        = "💃",
		AnimationId = "rbxassetid://507771019",  -- Roblox default dance
		Looped      = true,
		Category    = "Dance",
	},
	Dance2 = {
		DisplayName = "Dance 2",
		Icon        = "🕺",
		AnimationId = "rbxassetid://507776043",  -- Roblox default dance2
		Looped      = true,
		Category    = "Dance",
	},
	Dance3 = {
		DisplayName = "Dance 3",
		Icon        = "🎉",
		AnimationId = "rbxassetid://507777268",  -- Roblox default dance3
		Looped      = true,
		Category    = "Dance",
	},

	-- ── Hype ──────────────────────────────────────────────────
	Cheer = {
		DisplayName = "Cheer",
		Icon        = "🙌",
		AnimationId = "rbxassetid://507770677",  -- Roblox default cheer
		Looped      = false,
		Category    = "Hype",
	},
	Point = {
		DisplayName = "Point",
		Icon        = "👆",
		AnimationId = "rbxassetid://507770453",  -- placeholder (replace)
		Looped      = false,
		Category    = "Hype",
	},
	Laugh = {
		DisplayName = "Laugh",
		Icon        = "😂",
		AnimationId = "rbxassetid://3576968026", -- laugh
		Looped      = false,
		Category    = "Hype",
	},

	-- ── Music ─────────────────────────────────────────────────
	AirGuitar = {
		DisplayName = "Air Guitar",
		Icon        = "🎸",
		AnimationId = "rbxassetid://507763720",  -- placeholder (replace)
		Looped      = true,
		Category    = "Music",
	},
	Nod = {
		DisplayName = "Head Nod",
		Icon        = "🎵",
		AnimationId = "rbxassetid://507770239",  -- placeholder (replace)
		Looped      = true,
		Category    = "Music",
	},
}

-- Ordered category list for the wheel layout
EmoteConfig._categories = { "Chill", "Dance", "Hype", "Music" }

return EmoteConfig
