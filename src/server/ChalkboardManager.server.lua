-- ============================================================
--  ChalkboardManager.server.lua  (src/server)
--  Manages the cafeteria chalkboard — a shared 5-line "menu"
--  any player can edit. Changes are validated and broadcast
--  to all clients in real time.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ChalkboardUpdated: RemoteEvent = ReplicatedStorage.Remotes.ChalkboardUpdated

-- ── Board State ──────────────────────────────────────────────
-- 5 editable lines. Labels are fixed; values are player-written.

export type LineState = {
	label    : string,
	value    : string,
	editedBy : string?,
}

local boardLines: { LineState } = {
	{ label = "Today's Special",  value = "??",          editedBy = nil },
	{ label = "Now Playing",      value = "lo-fi vibes", editedBy = nil },
	{ label = "Tonight's Vibe",   value = "chill",       editedBy = nil },
	{ label = "Message",          value = "...",         editedBy = nil },
	{ label = "Secret Menu",      value = "ask nicely",  editedBy = nil },
}

-- ── Validation ───────────────────────────────────────────────

local MAX_LENGTH      = 32
local COOLDOWN        = 3  -- seconds between edits per player
local lastEditTime: { [Player]: number } = {}

local BANNED_PATTERNS = {
	"https?://",   -- no URLs
	"discord%.gg", -- no invite links
}

local function isSafe(text: string): boolean
	local lower = text:lower()
	for _, pattern in BANNED_PATTERNS do
		if lower:match(pattern) then return false end
	end
	return true
end

local function isRateLimited(player: Player): boolean
	local now  = os.clock()
	local last = lastEditTime[player] or 0
	if now - last < COOLDOWN then return true end
	lastEditTime[player] = now
	return false
end

-- ── Remote Handler ───────────────────────────────────────────
-- Client sends: (lineIndex: number, newValue: string)

ChalkboardUpdated.OnServerEvent:Connect(function(
	player   : Player,
	lineIndex: number,
	newValue : string
)
	-- Validate index
	if type(lineIndex) ~= "number" then return end
	lineIndex = math.floor(lineIndex)
	if lineIndex < 1 or lineIndex > #boardLines then return end

	-- Validate value
	if type(newValue) ~= "string" then return end
	newValue = newValue:sub(1, MAX_LENGTH)        -- enforce max length
	newValue = newValue:gsub("[\n\r\t]", " ")     -- strip newlines
	newValue = newValue:match("^%s*(.-)%s*$")     -- trim whitespace
	if newValue == "" then return end
	if not isSafe(newValue) then return end

	-- Rate limit
	if isRateLimited(player) then return end

	-- Apply
	boardLines[lineIndex].value    = newValue
	boardLines[lineIndex].editedBy = player.DisplayName

	-- Broadcast full board state to everyone
	local snapshot = {}
	for i, line in boardLines do
		snapshot[i] = {
			label    = line.label,
			value    = line.value,
			editedBy = line.editedBy,
		}
	end
	ChalkboardUpdated:FireAllClients("Update", snapshot)

	print(string.format(
		"[ChalkboardManager] %s edited line %d: '%s'",
		player.DisplayName, lineIndex, newValue
	))
end)

-- Send current state to newly-joining players
Players.PlayerAdded:Connect(function(player: Player)
	task.wait(2)
	local snapshot = {}
	for i, line in boardLines do
		snapshot[i] = {
			label    = line.label,
			value    = line.value,
			editedBy = line.editedBy,
		}
	end
	ChalkboardUpdated:FireClient(player, "Update", snapshot)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	lastEditTime[player] = nil
end)

print("[ChalkboardManager] Loaded — 5-line board ready.")
