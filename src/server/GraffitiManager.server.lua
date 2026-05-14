-- ============================================================
--  GraffitiManager.server.lua  (src/server)
--  Handles persistent graffiti wall state for the session.
--  Clients send their stroke data; server validates and
--  broadcasts to all other clients.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GraffitiUpdated: RemoteEvent = ReplicatedStorage.Remotes.GraffitiUpdated

-- Max strokes stored per session (prevents memory bloat)
local MAX_STROKES = 300

-- Session stroke log: { player: string, color: Color3, size: number, position: Vector2 }[]
local strokeLog: { { player: string, color: Color3, size: number, position: Vector2 } } = {}

-- ── Validation ───────────────────────────────────────────────

local VALID_SIZES   = { 1, 2, 3, 4, 5, 6 }
local MAX_STROKES_PER_SECOND = 5

-- Rate-limit table: player → { count, resetTime }
local rateLimits: { [Player]: { count: number, resetTime: number } } = {}

local function isRateLimited(player: Player): boolean
	local now  = os.clock()
	local data = rateLimits[player]
	if not data or now >= data.resetTime then
		rateLimits[player] = { count = 1, resetTime = now + 1 }
		return false
	end
	data.count += 1
	return data.count > MAX_STROKES_PER_SECOND
end

local function isValidSize(size: number): boolean
	for _, v in VALID_SIZES do
		if v == size then return true end
	end
	return false
end

-- ── Remote Handler ───────────────────────────────────────────

GraffitiUpdated.OnServerEvent:Connect(function(
	player  : Player,
	color   : Color3,
	size    : number,
	posX    : number,
	posY    : number
)
	-- Validate
	if isRateLimited(player) then return end
	if not isValidSize(size) then return end
	if typeof(color) ~= "Color3" then return end
	if type(posX) ~= "number" or type(posY) ~= "number" then return end
	posX = math.clamp(posX, 0, 1)
	posY = math.clamp(posY, 0, 1)

	-- Store
	if #strokeLog >= MAX_STROKES then
		table.remove(strokeLog, 1) -- rolling window
	end
	table.insert(strokeLog, {
		player   = player.DisplayName,
		color    = color,
		size     = size,
		position = Vector2.new(posX, posY),
	})

	-- Broadcast to all other clients
	for _, p in Players:GetPlayers() do
		if p ~= player then
			GraffitiUpdated:FireClient(p, player.DisplayName, color, size, posX, posY)
		end
	end
end)

-- Send existing strokes to newly-joining players
Players.PlayerAdded:Connect(function(player: Player)
	task.wait(2) -- wait for client to load
	for _, stroke in strokeLog do
		GraffitiUpdated:FireClient(
			player,
			stroke.player,
			stroke.color,
			stroke.size,
			stroke.position.X,
			stroke.position.Y
		)
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	rateLimits[player] = nil
end)

print("[GraffitiManager] Loaded.")
