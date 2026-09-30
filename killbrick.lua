task.wait(4)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local KillBrickState = {
	Tracked = setmetatable({}, { __mode = "k" }),
	Originals = setmetatable({}, { __mode = "k" }),
	Signals = setmetatable({}, { __mode = "k" }),
	Connections = {},
	Enabled = false,
	LastCleanup = 0,
	Stats = { PartsProtected = 0, AttemptsBlocked = 0, LastReset = tick() },
}
local KillBrickConfig = {
	CleanupInterval = 30,
	UseHeartbeat = false,
	ProtectAccessories = true,
	ProtectTools = true,
	WhitelistedParts = {},
	DebugMode = false,
}
local function getLocalPlayer()
	return Players.LocalPlayer
end
local function debugLog(message)
	if KillBrickConfig.DebugMode then
		print("[KillBrick Debug]", message)
	end
end
local function cleanupAntiKillbrick()
	local state = KillBrickState
	debugLog("Starting cleanup...")
	for i = #state.Connections, 1, -1 do
		local conn = state.Connections[i]
		if conn and typeof(conn) == "RBXScriptConnection" then
			pcall(function()
				conn:Disconnect()
			end)
		end
		state.Connections[i] = nil
	end
	for part, signalTable in pairs(state.Signals) do
		if signalTable then
			for i = #signalTable, 1, -1 do
				local conn = signalTable[i]
				if conn and typeof(conn) == "RBXScriptConnection" then
					pcall(function()
						conn:Disconnect()
					end)
				end
				signalTable[i] = nil
			end
		end
	end
	for part, originalValue in pairs(state.Originals) do
		if typeof(part) == "Instance" and part:IsA("BasePart") then
			pcall(function()
				part.CanTouch = originalValue
			end)
		end
	end
	table.clear(state.Signals)
	table.clear(state.Tracked)
	table.clear(state.Originals)
	state.LastCleanup = tick()
	debugLog("Cleanup completed")
end
local function isPartWhitelisted(part)
	for _, whitelistedPart in ipairs(KillBrickConfig.WhitelistedParts) do
		if part == whitelistedPart or part:IsDescendantOf(whitelistedPart) then
			return true
		end
	end
	return false
end
local function shouldProtectPart(part)
	if not (part and typeof(part) == "Instance" and part:IsA("BasePart")) then
		return false
	end
	if isPartWhitelisted(part) then
		return false
	end
	local localPlayer = getLocalPlayer()
	if not localPlayer then
		return false
	end
	local character = localPlayer.Character
	if not character then
		return false
	end
	if not part:IsDescendantOf(character) then
		return false
	end
	if not KillBrickConfig.ProtectAccessories and part:FindFirstAncestorOfClass("Accessory") then
		return false
	end
	if not KillBrickConfig.ProtectTools and part:FindFirstAncestorOfClass("Tool") then
		return false
	end
	return true
end
local function applyProtection(part)
	local state = KillBrickState
	if not shouldProtectPart(part) then
		return
	end
	if state.Originals[part] == nil then
		state.Originals[part] = part.CanTouch
	end
	local success = pcall(function()
		part.CanTouch = false
	end)
	if not success then
		debugLog("Failed to protect part: " .. tostring(part))
		return
	end
	state.Tracked[part] = true
	state.Stats.PartsProtected = state.Stats.PartsProtected + 1
	if not state.Signals[part] then
		local connection = part:GetPropertyChangedSignal("CanTouch"):Connect(function()
			if not state.Enabled then
				return
			end
			if part.CanTouch ~= false then
				pcall(function()
					part.CanTouch = false
					state.Stats.AttemptsBlocked = state.Stats.AttemptsBlocked + 1
					debugLog("Blocked CanTouch change on: " .. tostring(part))
				end)
			end
		end)
		state.Signals[part] = { connection }
	end
end
local function setupCharacter(character)
	if not character then
		return
	end
	local state = KillBrickState
	debugLog("Setting up character: " .. tostring(character))
	for _, descendant in ipairs(character:GetDescendants()) do
		applyProtection(descendant)
	end
	local addedConnection = character.DescendantAdded:Connect(function(descendant)
		if state.Enabled then
			task.defer(applyProtection, descendant)
		end
	end)
	table.insert(state.Connections, addedConnection)
	local removingConnection = character.DescendantRemoving:Connect(function(descendant)
		if state.Signals[descendant] then
			for _, conn in ipairs(state.Signals[descendant]) do
				pcall(function()
					conn:Disconnect()
				end)
			end
			state.Signals[descendant] = nil
		end
		state.Tracked[descendant] = nil
		state.Originals[descendant] = nil
	end)
	table.insert(state.Connections, removingConnection)
end
local function onCharacterAdded(character)
	debugLog("Character added, reinitializing...")
	task.wait(0.1)
	cleanupAntiKillbrick()
	if KillBrickState.Enabled then
		setupCharacter(character)
	end
end
local function EnableKillBrick()
	local state = KillBrickState
	if state.Enabled then
		warn("[KillBrick] Already enabled")
		return
	end
	local localPlayer = getLocalPlayer()
	if not localPlayer then
		warn("[KillBrick] LocalPlayer is not available yet.")
		return
	end
	state.Enabled = true
	state.Stats.LastReset = tick()
	cleanupAntiKillbrick()
	local character = localPlayer.Character
	if character then
		setupCharacter(character)
	end
	local characterAddedConnection = localPlayer.CharacterAdded:Connect(onCharacterAdded)
	table.insert(state.Connections, characterAddedConnection)
	local characterRemovingConnection = localPlayer.CharacterRemoving:Connect(function()
		debugLog("Character removing...")
	end)
	table.insert(state.Connections, characterRemovingConnection)
	local updateEvent
	if KillBrickConfig.UseHeartbeat then
		updateEvent = RunService.Heartbeat
	else
		updateEvent = RunService.Stepped
	end
	local updateConnection = updateEvent:Connect(function()
		if not state.Enabled then
			return
		end
		local currentCharacter = localPlayer.Character
		if not currentCharacter then
			return
		end
		if tick() - state.LastCleanup > KillBrickConfig.CleanupInterval then
			for part in pairs(state.Tracked) do
				if not (typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent) then
					state.Tracked[part] = nil
					state.Originals[part] = nil
					if state.Signals[part] then
						for _, conn in ipairs(state.Signals[part]) do
							pcall(function()
								conn:Disconnect()
							end)
						end
						state.Signals[part] = nil
					end
				end
			end
			state.LastCleanup = tick()
		end
		for part in pairs(state.Tracked) do
			if typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
				if part.CanTouch ~= false then
					pcall(function()
						part.CanTouch = false
						state.Stats.AttemptsBlocked = state.Stats.AttemptsBlocked + 1
					end)
				end
			end
		end
	end)
	table.insert(state.Connections, updateConnection)
	debugLog("Protection enabled with " .. tostring(state.Stats.PartsProtected) .. " parts")
end
local function DisableKillBrick()
	local state = KillBrickState
	if not state.Enabled then
		warn("[KillBrick] Already disabled")
		return
	end
	state.Enabled = false
	cleanupAntiKillbrick()
	debugLog("Protection disabled")
end
local function ToggleKillBrick()
	if KillBrickState.Enabled then
		DisableKillBrick()
	else
		EnableKillBrick()
	end
end
EnableKillBrick()
