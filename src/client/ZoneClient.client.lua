-- ============================================================
--  ZoneClient.client.lua  (src/client)
--  Listens for ZoneChanged events and smoothly crossfades
--  music (A/B swap) and tweens Lighting properties.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")

local ZoneConfig  = require(ReplicatedStorage.Shared.ZoneConfig)
local ZoneChanged: RemoteEvent = ReplicatedStorage.Remotes.ZoneChanged

-- ── Constants ────────────────────────────────────────────────

local TWEEN_TIME = 2.5
local tweenInfo  = TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- ── A/B Music Crossfade Setup ────────────────────────────────

local soundA = Instance.new("Sound")
soundA.Name   = "ZoneSoundA"
soundA.Volume = 0
soundA.Looped = true
soundA.Parent = SoundService

local soundB = Instance.new("Sound")
soundB.Name   = "ZoneSoundB"
soundB.Volume = 0
soundB.Looped = true
soundB.Parent = SoundService

local activeSlot = "A" -- which slot is currently audible

local function getSlots(): (Sound, Sound)
	return if activeSlot == "A" then (soundA :: Sound), (soundB :: Sound)
	       else (soundB :: Sound), (soundA :: Sound)
end

-- ── Reverb Effect ────────────────────────────────────────────

local reverbEffect = Instance.new("ReverbSoundEffect")
reverbEffect.Parent = SoundService

local function setReverb(preset: Enum.ReverbType)
	TweenService:Create(reverbEffect, tweenInfo, {
		DecayTime = if preset == Enum.ReverbType.Arena then 2.5
		            elseif preset == Enum.ReverbType.ConcertHall then 3.5
		            elseif preset == Enum.ReverbType.Cavern then 4.0
		            elseif preset == Enum.ReverbType.SmallRoom then 0.8
		            else 0.5
	}):Play()
end

-- ── Zone Transition ──────────────────────────────────────────

local currentTweens: { Tween } = {}

local function cancelCurrentTweens()
	for _, t in currentTweens do
		t:Cancel()
	end
	table.clear(currentTweens)
end

local function crossfadeTo(config: typeof(ZoneConfig.ThePulse)?)
	cancelCurrentTweens()
	local activeSound, inactiveSound = getSlots()

	if config == nil then
		-- No zone — fade to silence, restore default lighting
		local t1 = TweenService:Create(activeSound, tweenInfo, { Volume = 0 })
		t1:Play()
		table.insert(currentTweens, t1)

		local t2 = TweenService:Create(game.Lighting, tweenInfo, {
			Ambient    = Color3.fromRGB(100, 100, 120),
			Brightness = 1.0,
			FogEnd     = 300,
			FogColor   = Color3.fromRGB(15, 10, 25),
		})
		t2:Play()
		table.insert(currentTweens, t2)
		return
	end

	-- Load new track into inactive slot
	inactiveSound.SoundId = config.MusicId
	inactiveSound.Volume  = 0
	inactiveSound:Play()

	-- Crossfade audio
	local t1 = TweenService:Create(activeSound,   tweenInfo, { Volume = 0 })
	local t2 = TweenService:Create(inactiveSound, tweenInfo, { Volume = config.MusicVolume })
	t1:Play(); t2:Play()
	table.insert(currentTweens, t1)
	table.insert(currentTweens, t2)

	-- Stop the old track after fade completes
	t1.Completed:Once(function()
		activeSound:Stop()
	end)

	-- Swap active slot
	activeSlot = if activeSlot == "A" then "B" else "A"

	-- Tween lighting
	local t3 = TweenService:Create(game.Lighting, tweenInfo, {
		Ambient    = config.Ambient,
		Brightness = config.Brightness,
		FogEnd     = config.FogEnd,
		FogColor   = config.FogColor,
	})
	t3:Play()
	table.insert(currentTweens, t3)

	setReverb(config.ReverbPreset)
end

-- ── Listen ───────────────────────────────────────────────────

ZoneChanged.OnClientEvent:Connect(function(zoneName: string?)
	local config = if zoneName then ZoneConfig[zoneName] else nil
	crossfadeTo(config)
end)

print("[ZoneClient] Loaded — A/B crossfade ready.")
