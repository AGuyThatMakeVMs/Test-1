--[[
  CLASSIC ROUND SYSTEM - server script
  Keep the RoundSystem model inside Workspace. Settings live in
  RoundSystem > Config (see the README script).
]]

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")

------------------------------------------------------------------
-- SETTINGS (read from RoundSystem > Config, with safe defaults)
------------------------------------------------------------------
local pack = script.Parent
local config = pack:FindFirstChild("Config")
local advanced = pack:FindFirstChild("Advanced")

local function advancedSetting(name, default)
	local obj = advanced and advanced:FindFirstChild(name)
	if obj and obj:IsA("ValueBase") then
		return obj.Value
	end
	return default
end

local function setting(name, default)
	local obj = config and config:FindFirstChild(name)
	if obj and obj:IsA("ValueBase") then
		return obj.Value
	end
	return default
end

------------------------------------------------------------------
-- AUTOMATIC INSTALL
------------------------------------------------------------------
local Maps = SS:FindFirstChild("Maps")
local packMaps = pack:FindFirstChild("Maps")
if packMaps then
	if Maps then
		for _, m in ipairs(packMaps:GetChildren()) do
			m.Parent = Maps
		end
	else
		packMaps.Parent = SS
		Maps = packMaps
	end
end
if not Maps then
	Maps = Instance.new("Folder")
	Maps.Name = "Maps"
	Maps.Parent = SS
end

local guiTemplate = SS:FindFirstChild("RoundGuiTemplate")
if not guiTemplate then
	local g = pack:FindFirstChild("RoundGui")
	if g then
		g.Name = "RoundGuiTemplate"
		g.Parent = SS
		guiTemplate = g
	end
end

local function giveGui(player)
	if not guiTemplate then
		return
	end
	local playerGui = player:WaitForChild("PlayerGui")
	if not playerGui:FindFirstChild("RoundGui") then
		local g = guiTemplate:Clone()
		g.Name = "RoundGui"
		g.Parent = playerGui
	end
end

Players.PlayerAdded:Connect(giveGui)
for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(giveGui, p)
end

local leftover = workspace:FindFirstChild("CurrentMap")
if leftover then
	leftover:Destroy()
end

------------------------------------------------------------------
-- VALUES READ BY THE INTERFACE
------------------------------------------------------------------
local function newValue(class, name, default)
	local old = RS:FindFirstChild(name)
	if old then
		old:Destroy()
	end
	local v = Instance.new(class)
	v.Name = name
	v.Value = default
	v.Parent = RS
	return v
end

local StatusValue = newValue("StringValue", "RoundStatus", "Waiting for players...")
local TimerValue = newValue("IntValue", "RoundTimer", 0)
local MapValue = newValue("StringValue", "RoundMap", "")
local AliveValue = newValue("IntValue", "RoundAlive", 0)

local function setStatus(text, t)
	StatusValue.Value = text
	TimerValue.Value = t or 0
end

------------------------------------------------------------------
-- LOBBY (only built if the place has no SpawnLocation)
------------------------------------------------------------------
if not workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = workspace

	local base = Instance.new("Part")
	base.Name = "LobbyBase"
	base.Anchored = true
	base.Size = Vector3.new(60, 2, 60)
	base.Position = Vector3.new(0, 50, 0)
	base.BrickColor = BrickColor.new("Medium stone grey")
	base.Parent = lobby

	local sp = Instance.new("SpawnLocation")
	sp.Anchored = true
	sp.Size = Vector3.new(12, 1, 12)
	sp.Position = Vector3.new(0, 51.5, 0)
	sp.Neutral = true
	sp.Parent = lobby
end

------------------------------------------------------------------
-- MAP LIST
------------------------------------------------------------------
local function getValidMaps()
	local list = {}
	for _, m in ipairs(Maps:GetChildren()) do
		if m:IsA("Model") or m:IsA("Folder") then
			table.insert(list, m)
		end
	end
	return list
end

-- two test maps (only when the Maps folder has no maps at all)
if #getValidMaps() == 0 and advancedSetting("AutoCreateDemoMaps", true) then
	local demos = {
		{ name = "Test Map A", color = "Bright green", x = 300 },
		{ name = "Test Map B", color = "Bright blue", x = -300 },
	}
	for _, d in ipairs(demos) do
		local m = Instance.new("Model")
		m.Name = d.name

		local floor = Instance.new("Part")
		floor.Name = "Floor"
		floor.Anchored = true
		floor.Size = Vector3.new(120, 2, 120)
		floor.Position = Vector3.new(d.x, 0, 0)
		floor.BrickColor = BrickColor.new(d.color)
		floor.Parent = m

		for i = 1, 6 do
			local s = Instance.new("Part")
			s.Name = "SpawnPoint"
			s.Anchored = true
			s.Size = Vector3.new(6, 1, 6)
			s.Position = Vector3.new(d.x + math.cos(i * 1.05) * 40, 2, math.sin(i * 1.05) * 40)
			s.Parent = m
		end
		m.Parent = Maps
	end
end

local lastMap = nil

-- picks a RANDOM map, never the same one twice in a row (if 2+ maps)
local function pickMap()
	local list = getValidMaps()
	if #list == 0 then
		return nil
	end
	if advancedSetting("AvoidRepeatingMaps", true) and #list > 1 and lastMap then
		local filtered = {}
		for _, m in ipairs(list) do
			if m ~= lastMap then
				table.insert(filtered, m)
			end
		end
		list = filtered
	end
	local chosen = list[math.random(#list)]
	lastMap = chosen
	return chosen
end

-- returns the SpawnPoints of a map in RANDOM order
local function getSpawns(map)
	local list = {}
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") and d.Name == "SpawnPoint" then
			d.Transparency = 1
			d.CanCollide = false
			table.insert(list, d)
		end
	end
	if #list == 0 then
		for _, d in ipairs(map:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(list, d)
				break
			end
		end
	end
	if advancedSetting("RandomizeSpawns", true) then
		for i = #list, 2, -1 do
			local j = math.random(i)
			list[i], list[j] = list[j], list[i]
		end
	end
	return list
end

------------------------------------------------------------------
-- ROUND STATE
------------------------------------------------------------------
local alive = {}

local function countAlive()
	local n = 0
	for _ in pairs(alive) do
		n = n + 1
	end
	return n
end

local function updateAlive()
	AliveValue.Value = countAlive()
end

local function sendToSpawn(player, spawn)
	local char = player.Character
	if not char then
		return false
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp or hum.Health <= 0 then
		return false
	end

	local offset = advancedSetting("SpawnHeightOffset", 3.5)
	local pos = spawn.Position + Vector3.new(0, spawn.Size.Y / 2 + math.clamp(offset, 1, 20), 0)
	char:PivotTo(CFrame.new(pos))

	alive[player] = true
	hum.Died:Once(function()
		alive[player] = nil
		updateAlive()
	end)
	return true
end

Players.PlayerRemoving:Connect(function(p)
	alive[p] = nil
	updateAlive()
end)

local function runRound()
	local template = pickMap()
	if not template then
		warn("[RoundSystem] No maps found in the Maps folder.")
		task.wait(5)
		return
	end

	local map = template:Clone()
	map.Name = "CurrentMap"
	map.Parent = workspace

	local spawns = getSpawns(map)
	if #spawns == 0 then
		warn("[RoundSystem] Map '" .. template.Name .. "' has no parts. Skipping it.")
		map:Destroy()
		task.wait(5)
		return
	end

	MapValue.Value = template.Name
	alive = {}

	local started = 0
	for i, p in ipairs(Players:GetPlayers()) do
		local spawn = spawns[((i - 1) % #spawns) + 1]
		if sendToSpawn(p, spawn) then
			started = started + 1
		end
	end
	updateAlive()

	local endWhenOneLeft = setting("EndWhenOneLeft", false)
	for t = setting("RoundTime", 120), 1, -1 do
		setStatus("Round in progress", t)
		task.wait(1)

		local n = countAlive()
		if n == 0 or #Players:GetPlayers() == 0 then
			break
		end
		if endWhenOneLeft and started >= 2 and n <= 1 then
			break
		end
	end

	-- round over
	local n = countAlive()
	local text
	if n == 1 and started >= 2 then
		local winner
		for p in pairs(alive) do
			winner = p
		end
		text = "Round over! Winner: " .. (winner and winner.Name or "?")
	elseif n == 0 then
		text = "Round over! Nobody survived."
	else
		text = "Round over! Survivors: " .. n
	end
	setStatus(text, 0)
	task.wait(setting("EndScreenTime", 5))

	-- everyone back to the lobby, then remove the map
	alive = {}
	updateAlive()
	if advancedSetting("ReturnPlayersToLobby", true) then
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(function()
				p:LoadCharacter()
			end)
		end
	end
	map:Destroy()
	MapValue.Value = ""
end

------------------------------------------------------------------
-- MAIN LOOP
------------------------------------------------------------------
while true do
	while #Players:GetPlayers() < setting("MinPlayers", 1) do
		setStatus("Waiting for players...", 0)
		task.wait(1)
	end

	for i = setting("IntermissionTime", 15), 1, -1 do
		setStatus("Intermission", i)
		task.wait(1)
		if #Players:GetPlayers() < setting("MinPlayers", 1) then
			break
		end
	end

	if #Players:GetPlayers() >= setting("MinPlayers", 1) then
		runRound()
	end
end
