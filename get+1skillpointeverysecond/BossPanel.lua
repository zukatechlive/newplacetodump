local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local workspace = game:GetService("Workspace")
local CFG = {
	Title = "Better Auto Farmer",
	BossesFolder = "Bosses",   -- change this if the folder has a different name
	RefreshRate = 1.5,
	PanelW = 320,
	ItemHeight = 50,
	MaxVisible = 6,
	ToggleKey = Enum.KeyCode.RightBracket,
	AttachOffset = CFrame.new(0, 0, 4),
	CycleDwell = 5,
	OrbitRadius = 6,
	OrbitSpeed = 1.2,
	HpAlertThreshold = 0.25,
	AlertCooldown = 10,
	AccentColor = Color3.fromRGB(0, 188, 212),
	BgColor = Color3.fromRGB(10, 10, 14),
	SurfaceColor = Color3.fromRGB(16, 16, 22),
	TextColor = Color3.fromRGB(220, 220, 235),
	SubTextColor = Color3.fromRGB(90, 90, 115),
	BorderColor = Color3.fromRGB(38, 38, 52),
	BtnTP = Color3.fromRGB(18, 58, 90),
	BtnAttach = Color3.fromRGB(10, 68, 58),
	BtnAttachON = Color3.fromRGB(160, 100, 0),
	BtnIgnore = Color3.fromRGB(30, 30, 44),
	BtnIgnoreON = Color3.fromRGB(100, 18, 18),
	HpBarFull = Color3.fromRGB(0, 200, 83),
	HpBarMid = Color3.fromRGB(255, 160, 0),
	HpBarLow = Color3.fromRGB(213, 0, 0),
	HpBarBg = Color3.fromRGB(20, 6, 6),
	EspFill = Color3.fromRGB(0, 188, 212),
	EspOutline = Color3.fromRGB(255, 255, 255),
	IgnoreSurface = Color3.fromRGB(18, 8, 8),
	-- FX outline modes: "off" | "rainbow" | "pulse" | "glow"
	FxMode        = "rainbow",
	FxThickness   = 1.5,
	FxSpeed       = 1,
	FxPulseColor  = Color3.fromRGB(0, 200, 200),
	FxGlowColor   = Color3.fromRGB(0, 188, 212),
	CycleColor = Color3.fromRGB(100, 60, 220),
	OrbitColor = Color3.fromRGB(0, 172, 193),
	TagColors = {
		hard = Color3.fromRGB(220, 60, 60),
		farming = Color3.fromRGB(60, 180, 80),
		avoid = Color3.fromRGB(220, 140, 20),
		easy = Color3.fromRGB(80, 140, 220),
	},
}
_G._bossPanelAttachConn = _G._bossPanelAttachConn or nil
_G._bossPanelAttachTarget = _G._bossPanelAttachTarget or nil
_G._bossPanelReattachName = _G._bossPanelReattachName or nil
local ignoredSet = {}
local bossTags = {}
local espHighlights = {}
local hpAlertTimes = {}
local espEnabled = false
local sortByDist = false
local searchQuery = ""
local isOpen = false
local guiVisible = true
local isMinimized = false
local activeAttachBtn = nil
local attachMode = "behind"
local cycleEnabled = false
local cycleConn = nil
local cycleIndex = 1
local cycleTimer = 0
local alertsEnabled = false
local orbitAngle = 0
local reattachWatchConn = nil
local currentItems = {}
local function notify(msg, dur)
	if getgenv and getgenv().DoNotif then
		pcall(getgenv().DoNotif, msg, dur or 3)
	end
end
local function getRootPart(obj)
	if not obj or not obj.Parent then
		return nil
	end
	if obj:IsA("BasePart") then
		return obj
	end
	if obj:IsA("Model") then
		if obj.PrimaryPart then
			return obj.PrimaryPart
		end
		local hrp = obj:FindFirstChild("HumanoidRootPart")
		if hrp then
			return hrp
		end
		return obj:FindFirstChildWhichIsA("BasePart", true)
	end
	if obj:IsA("Humanoid") then
		local model = obj.Parent
		if model and model:IsA("Model") then
			if model.PrimaryPart then
				return model.PrimaryPart
			end
			local hrp = model:FindFirstChild("HumanoidRootPart")
			if hrp then
				return hrp
			end
			return model:FindFirstChildWhichIsA("BasePart", true)
		end
	end
	return nil
end
local function getHumanoid(obj)
	if obj:IsA("Model") then
		return obj:FindFirstChildWhichIsA("Humanoid", true)
	end
	return nil
end
local function getDistance(root)
	local char = plr.Character
	local myHRP = char and char:FindFirstChild("HumanoidRootPart")
	if not myHRP or not root or not root.Parent then
		return math.huge
	end
	return math.floor((myHRP.Position - root.Position).Magnitude)
end
local function getHpColor(ratio)
	if ratio > 0.5 then
		return CFG.HpBarFull:Lerp(CFG.HpBarMid, (1 - ratio) * 2)
	else
		return CFG.HpBarMid:Lerp(CFG.HpBarLow, (0.5 - ratio) * 2)
	end
end
local function getBossChildren()
	local folder = workspace:FindFirstChild(CFG.BossesFolder)
	return folder and folder:GetChildren() or {}
end
local function getFilteredSorted()
	local children = getBossChildren()
	local q = searchQuery:lower()
	local filtered = {}
	for _, c in ipairs(children) do
		if not ignoredSet[c.Name] then
			if q == "" or c.Name:lower():find(q, 1, true) then
				table.insert(filtered, c)
			end
		end
	end
	if sortByDist then
		table.sort(filtered, function(a, b)
			return getDistance(getRootPart(a)) < getDistance(getRootPart(b))
		end)
	else
		table.sort(filtered, function(a, b)
			return a.Name < b.Name
		end)
	end
	return filtered
end
local function addEsp(bossObj)
	local name = bossObj.Name
	local root = getRootPart(bossObj)
	-- If entry exists but adornee is dead (boss respawned), remove and re-add
	if espHighlights[name] then
		local entry = espHighlights[name]
		local h = entry.highlight
		if h and h.Parent and h.Adornee and h.Adornee.Parent then
			return -- still valid
		end
		removeEsp(name) -- stale, rebuild below
	end
	-- Highlight (fill + outline glow)
	local h = Instance.new("Highlight")
	h.Name = "_BossPanelESP"
	h.FillColor = CFG.EspFill
	h.OutlineColor = CFG.EspOutline
	h.FillTransparency = 0.55
	h.OutlineTransparency = 0
	h.Adornee = bossObj
	h.Parent = playerGui -- parent to playerGui so it survives boss model changes
	-- BillboardGui label above the boss
	local root = getRootPart(bossObj)
	local bb = Instance.new("BillboardGui")
	bb.Name = "_BossPanelESPLabel"
	bb.Size = UDim2.new(0, 130, 0, 52)
	bb.StudsOffset = Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = root or bossObj
	bb.Parent = playerGui
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = CFG.EspFill
	nameLbl.Font = Enum.Font.Code
	nameLbl.TextSize = 13
	nameLbl.TextStrokeTransparency = 0
	nameLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	nameLbl.TextScaled = false
	nameLbl.ZIndex = 2
	nameLbl.Parent = bb
	-- HP sub-label
	local hum = getHumanoid(bossObj)
	local hpLbl = Instance.new("TextLabel")
	hpLbl.Name = "_hpLbl"
	hpLbl.Size = UDim2.new(0.6, 0, 0.3, 0)
	hpLbl.Position = UDim2.new(0, 0, 0.5, 0)
	hpLbl.BackgroundTransparency = 1
	hpLbl.Text = hum and (math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) or "?"
	hpLbl.TextColor3 = hum and getHpColor(hum.MaxHealth > 0 and math.clamp(hum.Health/hum.MaxHealth,0,1) or 0) or CFG.SubTextColor
	hpLbl.Font = Enum.Font.Code
	hpLbl.TextSize = 10
	hpLbl.TextStrokeTransparency = 0
	hpLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	hpLbl.ZIndex = 2
	hpLbl.Parent = bb
	-- Distance sub-label
	local distLbl = Instance.new("TextLabel")
	distLbl.Name = "_distLbl"
	distLbl.Size = UDim2.new(0.4, 0, 0.3, 0)
	distLbl.Position = UDim2.new(0.6, 0, 0.5, 0)
	distLbl.BackgroundTransparency = 1
	distLbl.Text = root and (tostring(getDistance(root)) .. " st") or "?"
	distLbl.TextColor3 = Color3.fromRGB(100, 180, 255)
	distLbl.Font = Enum.Font.Code
	distLbl.TextSize = 10
	distLbl.TextStrokeTransparency = 0
	distLbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	distLbl.TextXAlignment = Enum.TextXAlignment.Right
	distLbl.ZIndex = 2
	distLbl.Parent = bb
	espHighlights[name] = { highlight = h, billboard = bb }
end
local function removeEsp(name)
	if espHighlights[name] then
		pcall(function()
			if espHighlights[name].highlight then
				espHighlights[name].highlight:Destroy()
			end
			if espHighlights[name].billboard then
				espHighlights[name].billboard:Destroy()
			end
		end)
		espHighlights[name] = nil
	end
end
local function clearAllEsp()
	local names = {}
	for name in pairs(espHighlights) do
		table.insert(names, name)
	end
	for _, name in ipairs(names) do
		removeEsp(name)
	end
end
local function syncEsp(children)
	if not espEnabled then
		clearAllEsp()
		return
	end
	local existing = {}
	for _, c in ipairs(children) do
		existing[c.Name] = c
	end
	for name in pairs(espHighlights) do
		if not existing[name] then
			removeEsp(name)
		end
	end
	for _, c in ipairs(children) do
		if not ignoredSet[c.Name] then
			addEsp(c)
		else
			removeEsp(c.Name)
		end
	end
end
local function stopAttach()
	if _G._bossPanelAttachConn then
		pcall(function()
			_G._bossPanelAttachConn:Disconnect()
		end)
		_G._bossPanelAttachConn = nil
		_G._bossPanelAttachTarget = nil
	end
end
local function clearActiveAttach()
	if activeAttachBtn then
		activeAttachBtn.BackgroundColor3 = CFG.BtnAttach
		activeAttachBtn.Text = "ATT"
		activeAttachBtn = nil
	end
end
local function startAttach(targetRoot, bossName)
	stopAttach()
	_G._bossPanelAttachTarget = targetRoot
	if bossName then
		_G._bossPanelReattachName = bossName
	end
	orbitAngle = 0
	_G._bossPanelAttachConn = RunService.Heartbeat:Connect(function(dt)
		local char = plr.Character
		local myHRP = char and char:FindFirstChild("HumanoidRootPart")
		if not myHRP then
			return
		end
		if not targetRoot or not targetRoot.Parent then
			local deadName = _G._bossPanelReattachName
			stopAttach()
			if deadName and not cycleEnabled then
				notify("[!] " .. deadName .. " gone -- watching for respawn", 3)
				startReattachWatch(deadName)
			elseif deadName and cycleEnabled then
				notify("[!] " .. deadName .. " gone -- cycling next", 2)
				task.defer(function()
					local bosses = getFilteredSorted()
					if #bosses == 0 then
						return
					end
					cycleIndex = cycleIndex % #bosses + 1
					local next = bosses[cycleIndex]
					if next then
						local root = getRootPart(next)
						if root then
							startAttach(root, next.Name)
							startReattachWatch(next.Name)
							notify("Cycle [skip] -> " .. next.Name, 2)
							if isOpen then
								task.defer(refreshAll)
							end
						end
					end
				end)
			end
			return
		end
		pcall(function()
			if attachMode == "behind" then
				myHRP.CFrame = targetRoot.CFrame * CFG.AttachOffset
			elseif attachMode == "ontop" then
				myHRP.CFrame = targetRoot.CFrame
			elseif attachMode == "orbit" then
				orbitAngle = orbitAngle + CFG.OrbitSpeed * dt
				local x = math.cos(orbitAngle) * CFG.OrbitRadius
				local z = math.sin(orbitAngle) * CFG.OrbitRadius
				local offset = CFrame.new(x, 0, z)
				myHRP.CFrame = (targetRoot.CFrame * offset) * CFrame.Angles(0, math.pi + orbitAngle, 0)
			end
		end)
	end)
end
local function doTP(targetRoot)
	local char = plr.Character
	local myHRP = char and char:FindFirstChild("HumanoidRootPart")
	if not myHRP or not targetRoot or not targetRoot.Parent then
		return
	end
	pcall(function()
		myHRP.CFrame = targetRoot.CFrame * CFG.AttachOffset
	end)
end
local function stopReattachWatch()
	if reattachWatchConn then
		pcall(function()
			reattachWatchConn:Disconnect()
		end)
		reattachWatchConn = nil
	end
	_G._bossPanelReattachName = nil
end
local function startReattachWatch(bossName)
	_G._bossPanelReattachName = bossName
	if reattachWatchConn then
		pcall(function()
			reattachWatchConn:Disconnect()
		end)
	end
	local folder = workspace:FindFirstChild(CFG.BossesFolder)
	if not folder then
		return
	end
	reattachWatchConn = folder.ChildAdded:Connect(function(child)
		if child.Name == _G._bossPanelReattachName then
			task.wait(0.25)
			local root = getRootPart(child)
			if root then
				startAttach(root, child.Name)
				notify("[+] Re-attached -> " .. child.Name, 3)
				if isOpen then
					task.defer(refreshAll)
				end
			end
		end
	end)
end
local refreshAll
local function stopCycle()
	cycleEnabled = false
	if cycleConn then
		pcall(function()
			cycleConn:Disconnect()
		end)
		cycleConn = nil
	end
	cycleTimer = 0
end
local function startCycle()
	stopCycle()
	stopReattachWatch()
	cycleEnabled = true
	cycleIndex = 1
	cycleTimer = 0
	cycleConn = RunService.Heartbeat:Connect(function(dt)
		if not cycleEnabled then
			return
		end
		local bosses = getFilteredSorted()
		if #bosses == 0 then
			return
		end
		cycleTimer = cycleTimer + dt
		if cycleTimer >= CFG.CycleDwell then
			cycleTimer = 0
			cycleIndex = cycleIndex % #bosses + 1
			local boss = bosses[cycleIndex]
			local root = getRootPart(boss)
			if root then
				clearActiveAttach()
				startAttach(root, boss.Name)
				startReattachWatch(boss.Name)
				notify("Cycle -> " .. boss.Name, 2)
				if isOpen then
					task.defer(refreshAll)
				end
			end
		end
	end)
	local bosses = getFilteredSorted()
	if #bosses > 0 then
		local root = getRootPart(bosses[1])
		if root then
			clearActiveAttach()
			startAttach(root, bosses[1].Name)
			startReattachWatch(bosses[1].Name)
			notify("Auto-Cycle: ON -> " .. bosses[1].Name, 3)
		end
	end
end
local bossAlertConn = nil
local function stopAlerts()
	alertsEnabled = false
	if bossAlertConn then
		pcall(function()
			bossAlertConn:Disconnect()
		end)
		bossAlertConn = nil
	end
end
local function startAlerts()
	stopAlerts()
	alertsEnabled = true
	local folder = workspace:FindFirstChild(CFG.BossesFolder)
	if not folder then
		return
	end
	bossAlertConn = folder.ChildAdded:Connect(function(child)
		if child.Name ~= _G._bossPanelReattachName then
			notify("[!] Boss spawned: " .. child.Name, 4)
		end
	end)
end
local function checkHpAlerts(children)
	local now = tick()
	for _, child in ipairs(children) do
		if not ignoredSet[child.Name] then
			local hum = getHumanoid(child)
			if hum and hum.MaxHealth > 0 then
				local ratio = hum.Health / hum.MaxHealth
				if ratio <= CFG.HpAlertThreshold and ratio > 0 then
					local last = hpAlertTimes[child.Name] or 0
					if now - last >= CFG.AlertCooldown then
						hpAlertTimes[child.Name] = now
						notify("[!] " .. child.Name .. " LOW HP (" .. math.floor(ratio * 100) .. "%)", 4)
					end
				end
			end
		end
	end
end
local function printSnapshot(bossObj)
	print("info: " .. bossObj:GetFullName() .. " ──")
	local function recurse(obj, indent)
		for _, child in ipairs(obj:GetChildren()) do
			local info = child.Name .. "  [" .. child.ClassName .. "]"
			if child:IsA("BasePart") then
				info = info
					.. "  size="
					.. tostring(child.Size)
					.. "  pos="
					.. tostring(math.floor(child.Position.X))
					.. ","
					.. tostring(math.floor(child.Position.Y))
					.. ","
					.. tostring(math.floor(child.Position.Z))
			elseif child:IsA("Humanoid") then
				info = info .. "  HP=" .. math.floor(child.Health) .. "/" .. math.floor(child.MaxHealth)
			elseif
				child:IsA("NumberValue")
				or child:IsA("IntValue")
				or child:IsA("StringValue")
				or child:IsA("BoolValue")
			then
				info = info .. "  val=" .. tostring(child.Value)
			end
			print(indent .. info)
			recurse(child, indent .. "  ")
		end
	end
	recurse(bossObj, "  ")
	notify("Snapshot printed: " .. bossObj.Name, 2)
end
if playerGui:FindFirstChild("BossesPanelGui") then
	playerGui.BossesPanelGui:Destroy()
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BossesPanelGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 99
ScreenGui.Parent = playerGui
local MiniBtn = Instance.new("TextButton")
MiniBtn.Name = "MiniBtn"
MiniBtn.Size = UDim2.new(0, 40, 0, 22)
MiniBtn.Position = UDim2.new(0, 24, 0, 24)
MiniBtn.BackgroundColor3 = CFG.AccentColor
MiniBtn.Text = "BOSS"
MiniBtn.TextColor3 = Color3.new(1, 1, 1)
MiniBtn.Font = Enum.Font.Code
MiniBtn.TextSize = 10
MiniBtn.BorderSizePixel = 0
MiniBtn.ZIndex = 10
MiniBtn.Visible = false
MiniBtn.Parent = ScreenGui
do
	local s = Instance.new("UIStroke")
	s.Color = CFG.BorderColor
	s.Thickness = 1
	s.Parent = MiniBtn
end
local miniDragging, miniDragStart, miniStartPos = false, nil, nil
local miniDidDrag = false
MiniBtn.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		miniDragging = true
		miniDidDrag = false
		miniDragStart = inp.Position
		miniStartPos = MiniBtn.Position
	end
end)
MiniBtn.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		miniDragging = false
	end
end)
-- ── Outline FX stubs (implementations filled in after MainFrame is created) ──
local fxConn1, fxConn2, fxStroke1, fxStroke2
local stopFx, startRainbow, startPulse, startGlow, applyFx
local FX_MODES  = { "rainbow", "pulse", "glow", "off" }
local fxModeIdx = 1


local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, CFG.PanelW, 0, 40)
MainFrame.Position = UDim2.new(0, 24, 0, 24)
MainFrame.BackgroundColor3 = CFG.BgColor
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(0, 2, 1, 0)
AccentBar.BackgroundColor3 = CFG.AccentColor
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex = 2
AccentBar.Parent = MainFrame
-- ── Outline FX implementations (now MainFrame exists) ────────────────────────
stopFx = function()
	if fxConn1 then pcall(function() fxConn1:Disconnect() end); fxConn1 = nil end
	if fxConn2 then pcall(function() fxConn2:Disconnect() end); fxConn2 = nil end
	if fxStroke1 then pcall(function() fxStroke1:Destroy() end); fxStroke1 = nil end
	if fxStroke2 then pcall(function() fxStroke2:Destroy() end); fxStroke2 = nil end
end

startRainbow = function()
	stopFx()
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = CFG.FxThickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = MainFrame
	fxStroke1 = stroke
	local hue = 0
	fxConn1 = RunService.Heartbeat:Connect(function(dt)
		hue = (hue + dt * CFG.FxSpeed * 0.2) % 1
		stroke.Color = Color3.fromHSV(hue, 1, 1)
	end)
end

startPulse = function()
	stopFx()
	local stroke = Instance.new("UIStroke")
	stroke.Color = CFG.FxPulseColor
	stroke.Thickness = CFG.FxThickness
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = MainFrame
	fxStroke1 = stroke
	local running = true
	fxConn1 = RunService.Heartbeat:Connect(function() end)
	task.spawn(function()
		while running and fxStroke1 and fxStroke1.Parent do
			TweenService:Create(stroke, TweenInfo.new(CFG.FxSpeed * 0.5, Enum.EasingStyle.Sine), {
				Thickness = CFG.FxThickness * 3.5, Transparency = 0.5,
			}):Play()
			task.wait(CFG.FxSpeed * 0.5)
			TweenService:Create(stroke, TweenInfo.new(CFG.FxSpeed * 0.5, Enum.EasingStyle.Sine), {
				Thickness = CFG.FxThickness, Transparency = 0,
			}):Play()
			task.wait(CFG.FxSpeed * 0.5)
		end
	end)
	stroke.AncestryChanged:Connect(function()
		if not stroke.Parent then running = false end
	end)
end

startGlow = function()
	stopFx()
	local glow = Instance.new("UIStroke")
	glow.Color = CFG.FxGlowColor
	glow.Thickness = CFG.FxThickness * 3
	glow.Transparency = 0.7
	glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	glow.Parent = MainFrame
	fxStroke2 = glow
	local inner = Instance.new("UIStroke")
	inner.Color = CFG.FxGlowColor
	inner.Thickness = CFG.FxThickness
	inner.Transparency = 0
	inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	inner.Parent = MainFrame
	fxStroke1 = inner
	local running = true
	task.spawn(function()
		while running and fxStroke2 and fxStroke2.Parent do
			TweenService:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.35,
			}):Play()
			task.wait(1.2)
			TweenService:Create(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.75,
			}):Play()
			task.wait(1.2)
		end
	end)
	glow.AncestryChanged:Connect(function()
		if not glow.Parent then running = false end
	end)
end
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1
Header.ZIndex = 3
Header.Parent = MainFrame
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -200, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "[ " .. CFG.Title .. " ]"
TitleLabel.TextColor3 = CFG.TextColor
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 4
TitleLabel.Parent = Header
local function makeHeaderBtn(text, xOff, w, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, w, 0, 20)
	b.Position = UDim2.new(1, xOff, 0.5, -10)
	b.BackgroundColor3 = color or Color3.fromRGB(50, 50, 65)
	b.Text = text
	b.TextColor3 = CFG.SubTextColor
	b.Font = Enum.Font.Code
	b.TextSize = 10
	b.BorderSizePixel = 0
	b.ZIndex = 6
	b.Parent = Header
	return b
end
local EspBtn    = makeHeaderBtn("ESP",  -198, 32)
local DstBtn    = makeHeaderBtn("DST",  -162, 32)
local AlertBtn  = makeHeaderBtn("ALT",  -126, 32)
local FxBtn     = makeHeaderBtn("FX",    -90, 32)
local MinimizeBtn = makeHeaderBtn("──",  -54, 32)
local CountBadge = Instance.new("TextLabel")
CountBadge.Size = UDim2.new(0, 24, 0, 18)
CountBadge.Position = UDim2.new(1, -224, 0.5, -9)
CountBadge.BackgroundColor3 = CFG.AccentColor
CountBadge.Text = "0"
CountBadge.TextColor3 = Color3.new(1, 1, 1)
CountBadge.Font = Enum.Font.Code
CountBadge.TextSize = 10
CountBadge.ZIndex = 4
CountBadge.Parent = Header
local Chevron = Instance.new("TextLabel")
Chevron.Size = UDim2.new(0, 18, 0, 20)
Chevron.Position = UDim2.new(1, -18, 0.5, -10)
Chevron.BackgroundTransparency = 1
Chevron.Text = "v"
Chevron.TextColor3 = CFG.SubTextColor
Chevron.Font = Enum.Font.Code
Chevron.TextSize = 11
Chevron.ZIndex = 4
Chevron.Parent = Header
local ToolbarH = 32
local Toolbar = Instance.new("Frame")
Toolbar.Name = "Toolbar"
Toolbar.Size = UDim2.new(1, 0, 0, ToolbarH)
Toolbar.Position = UDim2.new(0, 0, 0, 40)
Toolbar.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
Toolbar.BorderSizePixel = 0
Toolbar.ZIndex = 3
Toolbar.Visible = false
Toolbar.Parent = MainFrame
local function makeToolbarBtn(text, xOff, w, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, w, 0, 22)
	b.Position = UDim2.new(0, xOff, 0.5, -11)
	b.BackgroundColor3 = color or Color3.fromRGB(40, 40, 52)
	b.Text = text
	b.TextColor3 = CFG.SubTextColor
	b.Font = Enum.Font.Code
	b.TextSize = 10
	b.BorderSizePixel = 0
	b.ZIndex = 5
	b.Parent = Toolbar
	return b
end
local CycleBtn = makeToolbarBtn("[>] CYCLE", 6, 68)
local ModeBtn = makeToolbarBtn("BEHIND", 78, 54)
local SkipBtn = makeToolbarBtn("SKIP ▶", 136, 50)
local SearchBox
local CycleBarBg = Instance.new("Frame")
CycleBarBg.Size = UDim2.new(0, 68, 0, 3)
CycleBarBg.Position = UDim2.new(0, 6, 1, -5)
CycleBarBg.BackgroundColor3 = Color3.fromRGB(50, 30, 70)
CycleBarBg.BorderSizePixel = 0
CycleBarBg.ZIndex = 6
CycleBarBg.Visible = false
CycleBarBg.Parent = Toolbar
local CycleBarFill = Instance.new("Frame")
CycleBarFill.Size = UDim2.new(0, 0, 1, 0)
CycleBarFill.BackgroundColor3 = CFG.CycleColor
CycleBarFill.BorderSizePixel = 0
CycleBarFill.ZIndex = 7
CycleBarFill.Parent = CycleBarBg
local SearchFrame = Instance.new("Frame")
SearchFrame.Size = UDim2.new(1, -196, 0, 22)
SearchFrame.Position = UDim2.new(0, 191, 0.5, -11)
SearchFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
SearchFrame.BorderSizePixel = 0
SearchFrame.ZIndex = 5
SearchFrame.Parent = Toolbar
do
	local s = Instance.new("UIStroke")
	s.Color = CFG.BorderColor
	s.Thickness = 1
	s.Parent = SearchFrame
end
local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 18, 1, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = "/"
SearchIcon.TextSize = 10
SearchIcon.Font = Enum.Font.Code
SearchIcon.ZIndex = 6
SearchIcon.Parent = SearchFrame
SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -20, 1, 0)
SearchBox.Position = UDim2.new(0, 18, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Search…"
SearchBox.PlaceholderColor3 = CFG.SubTextColor
SearchBox.Text = ""
SearchBox.TextColor3 = CFG.TextColor
SearchBox.Font = Enum.Font.Code
SearchBox.TextSize = 10
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 7
SearchBox.Parent = SearchFrame
local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, -14, 0, 1)
Separator.Position = UDim2.new(0, 7, 0, 40)
Separator.BackgroundColor3 = CFG.BorderColor
Separator.BorderSizePixel = 0
Separator.ZIndex = 3
Separator.Parent = MainFrame
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 0, 0)
ScrollFrame.Position = UDim2.new(0, 0, 0, 41)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 3
ScrollFrame.ScrollBarImageColor3 = CFG.AccentColor
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ZIndex = 3
ScrollFrame.ClipsDescendants = true
ScrollFrame.Parent = MainFrame
local ListLayout = Instance.new("UIListLayout")
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 2)
ListLayout.Parent = ScrollFrame
do
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, 4)
	p.PaddingBottom = UDim.new(0, 4)
	p.PaddingLeft = UDim.new(0, 6)
	p.PaddingRight = UDim.new(0, 6)
	p.Parent = ScrollFrame
end
local IgnoreSep = Instance.new("Frame")
IgnoreSep.Size = UDim2.new(1, -14, 0, 1)
IgnoreSep.BackgroundColor3 = CFG.BorderColor
IgnoreSep.BorderSizePixel = 0
IgnoreSep.ZIndex = 3
IgnoreSep.Visible = false
IgnoreSep.Parent = MainFrame
local IgnoreHeader = Instance.new("Frame")
IgnoreHeader.Size = UDim2.new(1, 0, 0, 28)
IgnoreHeader.BackgroundTransparency = 1
IgnoreHeader.ZIndex = 3
IgnoreHeader.Visible = false
IgnoreHeader.Parent = MainFrame
local IgnoreTitle = Instance.new("TextLabel")
IgnoreTitle.Size = UDim2.new(1, -80, 1, 0)
IgnoreTitle.Position = UDim2.new(0, 14, 0, 0)
IgnoreTitle.BackgroundTransparency = 1
IgnoreTitle.Text = "-- ignored"
IgnoreTitle.TextColor3 = CFG.SubTextColor
IgnoreTitle.Font = Enum.Font.Code
IgnoreTitle.TextSize = 11
IgnoreTitle.TextXAlignment = Enum.TextXAlignment.Left
IgnoreTitle.ZIndex = 4
IgnoreTitle.Parent = IgnoreHeader
local ClearAllBtn = Instance.new("TextButton")
ClearAllBtn.Size = UDim2.new(0, 60, 0, 18)
ClearAllBtn.Position = UDim2.new(1, -68, 0.5, -9)
ClearAllBtn.BackgroundColor3 = Color3.fromRGB(60, 16, 16)
ClearAllBtn.Text = "Clear All"
ClearAllBtn.TextColor3 = Color3.fromRGB(230, 150, 150)
ClearAllBtn.Font = Enum.Font.Code
ClearAllBtn.TextSize = 9
ClearAllBtn.BorderSizePixel = 0
ClearAllBtn.ZIndex = 5
ClearAllBtn.Parent = IgnoreHeader
local IgnoreScroll = Instance.new("ScrollingFrame")
IgnoreScroll.Size = UDim2.new(1, 0, 0, 0)
IgnoreScroll.BackgroundTransparency = 1
IgnoreScroll.BorderSizePixel = 0
IgnoreScroll.ScrollBarThickness = 2
IgnoreScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 40, 40)
IgnoreScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
IgnoreScroll.ZIndex = 3
IgnoreScroll.ClipsDescendants = true
IgnoreScroll.Visible = false
IgnoreScroll.Parent = MainFrame
local IgnoreLayout = Instance.new("UIListLayout")
IgnoreLayout.FillDirection = Enum.FillDirection.Vertical
IgnoreLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
IgnoreLayout.SortOrder = Enum.SortOrder.Name
IgnoreLayout.Padding = UDim.new(0, 2)
IgnoreLayout.Parent = IgnoreScroll
do
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, 2)
	p.PaddingBottom = UDim.new(0, 4)
	p.PaddingLeft = UDim.new(0, 6)
	p.PaddingRight = UDim.new(0, 6)
	p.Parent = IgnoreScroll
end
local TagPopup = Instance.new("Frame")
TagPopup.Name = "TagPopup"
TagPopup.Size = UDim2.new(0, 160, 0, 0)
TagPopup.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
TagPopup.BorderSizePixel = 0
TagPopup.ZIndex = 20
TagPopup.Visible = false
TagPopup.ClipsDescendants = true
TagPopup.Parent = ScreenGui
do
	local s = Instance.new("UIStroke")
	s.Color = CFG.BorderColor
	s.Thickness = 1
	s.Parent = TagPopup
end
local TagLayout = Instance.new("UIListLayout")
TagLayout.FillDirection = Enum.FillDirection.Vertical
TagLayout.Padding = UDim.new(0, 2)
TagLayout.Parent = TagPopup
do
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, 4)
	p.PaddingBottom = UDim.new(0, 4)
	p.PaddingLeft = UDim.new(0, 6)
	p.PaddingRight = UDim.new(0, 6)
	p.Parent = TagPopup
end
local currentTagTarget = nil
local function closeTagPopup()
	TagPopup.Visible = false
	currentTagTarget = nil
end
local function openTagPopup(bossName, screenPos)
	currentTagTarget = bossName
	for _, c in ipairs(TagPopup:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local tags = { "hard", "farming", "avoid", "easy", "(clear)" }
	for _, tag in ipairs(tags) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 22)
		btn.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.Code
		btn.TextSize = 11
		btn.ZIndex = 21
		btn.Parent = TagPopup
		if tag == "(clear)" then
			btn.Text = "x  none"
			btn.TextColor3 = CFG.SubTextColor
		else
			btn.Text = "> " .. tag
			btn.TextColor3 = CFG.TagColors[tag] or CFG.TextColor
		end
		btn.MouseButton1Click:Connect(function()
			if tag == "(clear)" then
				bossTags[bossName] = nil
			else
				bossTags[bossName] = tag
			end
			closeTagPopup()
			if isOpen then
				refreshAll()
			end
		end)
	end
	local popH = #tags * 24 + 8
	TagPopup.Size = UDim2.new(0, 160, 0, popH)
	TagPopup.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
	TagPopup.Visible = true
end
UserInputService.InputBegan:Connect(function(inp, gpe)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 and TagPopup.Visible then
		task.defer(closeTagPopup)
	end
end)
local function makeBtn(parent, text, bgColor, absX, w)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, w, 0, 20)
	btn.Position = UDim2.new(1, absX, 0.5, -10)
	btn.BackgroundColor3 = bgColor
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.Code
	btn.TextSize = 9
	btn.BorderSizePixel = 0
	btn.ZIndex = 6
	btn.Parent = parent
	return btn
end
local function makeItem(bossObj, layoutOrder)
	local name = bossObj.Name
	local isIgnored = ignoredSet[name] == true
	local humanoid = getHumanoid(bossObj)
	local root = getRootPart(bossObj)
	local hp = humanoid and humanoid.Health or 0
	local maxHp = humanoid and humanoid.MaxHealth or 0
	local hpRatio = (maxHp > 0) and math.clamp(hp / maxHp, 0, 1) or 0
	local dist = root and getDistance(root) or 0
	local tag = bossTags[name]
	local tagColor = tag and (CFG.TagColors[tag] or CFG.SubTextColor) or nil
	local isCycleActive = cycleEnabled and _G._bossPanelAttachTarget == root
	local rowBg = isIgnored and CFG.IgnoreSurface or (isCycleActive and Color3.fromRGB(28, 22, 38)) or CFG.SurfaceColor
	local row = Instance.new("Frame")
	row.Name = "Item_" .. name
	row.Size = UDim2.new(1, 0, 0, CFG.ItemHeight)
	row.BackgroundColor3 = rowBg
	row.BorderSizePixel = 0
	row.ZIndex = 4
	row.LayoutOrder = layoutOrder or 0
	if isCycleActive then
		local s = Instance.new("UIStroke")
		s.Color = CFG.CycleColor
		s.Thickness = 1
		s.Parent = row
	end
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(0, 8, 0, 8)
	dot.BackgroundColor3 = isIgnored and Color3.fromRGB(100, 40, 40) or CFG.AccentColor
	dot.BorderSizePixel = 0
	dot.ZIndex = 5
	dot.Parent = row
	local nameXOff = 20
	if tag then
		local badge = Instance.new("TextLabel")
		badge.Size = UDim2.new(0, 40, 0, 14)
		badge.Position = UDim2.new(0, nameXOff, 0, 5)
		badge.BackgroundColor3 = tagColor
		badge.BackgroundTransparency = 0.6
		badge.Text = tag
		badge.TextColor3 = Color3.new(1, 1, 1)
		badge.Font = Enum.Font.Code
		badge.TextSize = 8
		badge.ZIndex = 6
		badge.Parent = row
		nameXOff = 64
	end
	local nameBtn = Instance.new("TextButton")
	nameBtn.Size = UDim2.new(1, -162, 0, 20)
	nameBtn.Position = UDim2.new(0, nameXOff, 0, 4)
	nameBtn.BackgroundTransparency = 1
	nameBtn.Text = name
	nameBtn.TextColor3 = isIgnored and CFG.SubTextColor or CFG.TextColor
	nameBtn.Font = Enum.Font.Code
	nameBtn.TextSize = 11
	nameBtn.TextXAlignment = Enum.TextXAlignment.Left
	nameBtn.TextTruncate = Enum.TextTruncate.AtEnd
	nameBtn.ZIndex = 6
	nameBtn.Parent = row
	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(0, 50, 0, 12)
	distLabel.Position = UDim2.new(0, 20, 0, 26)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = root and (tostring(dist) .. " st") or "N/A"
	distLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
	distLabel.Font = Enum.Font.Code
	distLabel.TextSize = 9
	distLabel.TextXAlignment = Enum.TextXAlignment.Left
	distLabel.ZIndex = 5
	distLabel.Parent = row
	-- HP bar: lives in left info zone, ends before button strip
	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(1, -162, 0, 5)
	hpBg.Position = UDim2.new(0, 74, 0, 30)
	hpBg.BackgroundColor3 = CFG.HpBarBg
	hpBg.BorderSizePixel = 0
	hpBg.ZIndex = 5
	hpBg.Parent = row
	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.new(hpRatio, 0, 1, 0)
	hpFill.BackgroundColor3 = humanoid and getHpColor(hpRatio) or CFG.SubTextColor
	hpFill.BorderSizePixel = 0
	hpFill.ZIndex = 6
	hpFill.Parent = hpBg
	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(0, 80, 0, 12)
	hpLabel.Position = UDim2.new(0, 74, 0, 16)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = humanoid and (math.floor(hp) .. "/" .. math.floor(maxHp)) or "No Humanoid"
	hpLabel.TextColor3 = humanoid and getHpColor(hpRatio) or CFG.SubTextColor
	hpLabel.Font = Enum.Font.Code
	hpLabel.TextSize = 9
	hpLabel.TextXAlignment = Enum.TextXAlignment.Left
	hpLabel.ZIndex = 5
	hpLabel.Parent = row
	-- Button strip: 4 buttons packed into the right 156px, 6px gap from edge
	-- Layout from right: [SN 30] [IGN 38] [ATT 34] [TP 30] with 4px gaps
	-- Total = 30+4+38+4+34+4+30 = 144px, strip starts at 320-150 = 170
	local tpBtn  = makeBtn(row, "TP",  CFG.BtnTP,     -152, 30)
	local attBtn = makeBtn(row, "ATT", CFG.BtnAttach, -114, 34)
	local ignBtn = makeBtn(row, isIgnored and "UNIGN" or "IGN",
		isIgnored and CFG.BtnIgnoreON or CFG.BtnIgnore, -76, 38)
	local snapBtn = makeBtn(row, "SN", Color3.fromRGB(50, 50, 65), -34, 28)
	if _G._bossPanelAttachTarget and root and _G._bossPanelAttachTarget == root then
		attBtn.BackgroundColor3 = cycleEnabled and CFG.CycleColor or CFG.BtnAttachON
		attBtn.Text = cycleEnabled and "CYC" or "STOP"
		if not cycleEnabled then
			activeAttachBtn = attBtn
		end
	end
	local tweenIn = TweenService:Create(row, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(22, 22, 32) })
	local tweenOut = TweenService:Create(row, TweenInfo.new(0.1), { BackgroundColor3 = rowBg })
	row.MouseEnter:Connect(function()
		if not isIgnored then
			tweenIn:Play()
		end
	end)
	row.MouseLeave:Connect(function()
		tweenOut:Play()
	end)
	nameBtn.MouseButton1Click:Connect(function()
		if ignoredSet[name] then
			return
		end
		local r = getRootPart(bossObj)
		if r then
			doTP(r)
			notify("TP → " .. name, 2)
		end
	end)
	nameBtn.MouseButton2Click:Connect(function()
		local mp = UserInputService:GetMouseLocation()
		openTagPopup(name, mp)
	end)
	tpBtn.MouseButton1Click:Connect(function()
		if ignoredSet[name] then
			return
		end
		local r = getRootPart(bossObj)
		if r then
			doTP(r)
			notify("TP → " .. name, 2)
		end
	end)
	attBtn.MouseButton1Click:Connect(function()
		if ignoredSet[name] then
			return
		end
		if cycleEnabled then
			stopCycle()
			CycleBtn.Text = "[>] CYCLE"
			CycleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
			CycleBtn.TextColor3 = CFG.SubTextColor
			CycleBarBg.Visible = false
		end
		local r = getRootPart(bossObj)
		if not r then
			return
		end
		if _G._bossPanelAttachTarget == r then
			stopAttach()
			clearActiveAttach()
			stopReattachWatch()
			notify("Attach: OFF", 2)
		else
			clearActiveAttach()
			startAttach(r, name)
			startReattachWatch(name)
			attBtn.BackgroundColor3 = CFG.BtnAttachON
			attBtn.Text = "STOP"
			activeAttachBtn = attBtn
			notify("Attaching -> " .. name, 3)
		end
	end)
	ignBtn.MouseButton1Click:Connect(function()
		if ignoredSet[name] then
			ignoredSet[name] = nil
		else
			ignoredSet[name] = true
			local r = getRootPart(bossObj)
			if r and _G._bossPanelAttachTarget == r then
				stopAttach()
				clearActiveAttach()
				stopReattachWatch()
			end
			if espEnabled then
				removeEsp(name)
			end
		end
		refreshAll()
	end)
	snapBtn.MouseButton1Click:Connect(function()
		printSnapshot(bossObj)
	end)
	return row
end
local function makeIgnoreRow(name)
	local row = Instance.new("Frame")
	row.Name = "IGN_" .. name
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundColor3 = Color3.fromRGB(20, 10, 10)
	row.BorderSizePixel = 0
	row.ZIndex = 4
	row.Parent = IgnoreScroll
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "  " .. name
	lbl.TextColor3 = Color3.fromRGB(200, 100, 100)
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 5
	lbl.Parent = row
	local unBtn = Instance.new("TextButton")
	unBtn.Size = UDim2.new(0, 44, 0, 16)
	unBtn.Position = UDim2.new(1, -50, 0.5, -8)
	unBtn.BackgroundColor3 = Color3.fromRGB(42, 18, 18)
	unBtn.Text = "Unign"
	unBtn.TextColor3 = Color3.fromRGB(240, 160, 160)
	unBtn.Font = Enum.Font.Code
	unBtn.TextSize = 9
	unBtn.BorderSizePixel = 0
	unBtn.ZIndex = 6
	unBtn.Parent = row
	unBtn.MouseButton1Click:Connect(function()
		ignoredSet[name] = nil
		refreshAll()
	end)
	return row
end
local HEADER_H = 40
local TOOLBAR_H = ToolbarH
local SEP_H = 1
local function getListTop()
	return HEADER_H + SEP_H + (isOpen and TOOLBAR_H or 0)
end
refreshAll = function()
	for _, c in ipairs(ScrollFrame:GetChildren()) do
		if c:IsA("Frame") or (c:IsA("TextLabel") and c.Name == "Item_EMPTY") then
			c:Destroy()
		end
	end
	currentItems = {}
	for _, c in ipairs(IgnoreScroll:GetChildren()) do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local folder = workspace:FindFirstChild(CFG.BossesFolder)
	if not folder then
		CountBadge.Text = "!"
		CountBadge.BackgroundColor3 = Color3.fromRGB(180, 80, 40)
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Item_EMPTY"
		lbl.Size = UDim2.new(1, 0, 0, CFG.ItemHeight)
		lbl.BackgroundTransparency = 1
		lbl.Text = "workspace.Bosses not found"
		lbl.TextColor3 = CFG.SubTextColor
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 11
		lbl.ZIndex = 4
		lbl.Parent = ScrollFrame
		table.insert(currentItems, lbl)
		IgnoreSep.Visible = false
		IgnoreHeader.Visible = false
		IgnoreScroll.Visible = false
		return
	end
	local allChildren = folder:GetChildren()
	CountBadge.BackgroundColor3 = CFG.AccentColor
	CountBadge.Text = tostring(#allChildren)
	syncEsp(allChildren)
	checkHpAlerts(allChildren)
	local filtered = getFilteredSorted()
	if #filtered == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Item_EMPTY"
		lbl.Size = UDim2.new(1, 0, 0, CFG.ItemHeight)
		lbl.BackgroundTransparency = 1
		lbl.Text = #allChildren == 0 and "No bosses found" or "No results"
		lbl.TextColor3 = CFG.SubTextColor
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 11
		lbl.ZIndex = 4
		lbl.Parent = ScrollFrame
		table.insert(currentItems, lbl)
	else
		for i, child in ipairs(filtered) do
			local item = makeItem(child, i)
			item.Parent = ScrollFrame
			table.insert(currentItems, item)
		end
	end
	local ignoredNames = {}
	for k in pairs(ignoredSet) do
		table.insert(ignoredNames, k)
	end
	table.sort(ignoredNames)
	local hasIgn = #ignoredNames > 0
	IgnoreSep.Visible = hasIgn
	IgnoreHeader.Visible = hasIgn
	IgnoreScroll.Visible = hasIgn
	for _, n in ipairs(ignoredNames) do
		makeIgnoreRow(n)
	end
end
getfenv().refreshAll = refreshAll
local function updatePanelHeight()
	local listTop = getListTop()
	local contentH = ListLayout.AbsoluteContentSize.Y + 8
	local cappedH = math.min(contentH, CFG.ItemHeight * CFG.MaxVisible + 8)
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentH)
	ScrollFrame.Position = UDim2.new(0, 0, 0, listTop)
	Toolbar.Visible = isOpen
	Toolbar.Position = UDim2.new(0, 0, 0, HEADER_H)
	Separator.Position = UDim2.new(0, 7, 0, HEADER_H + (isOpen and TOOLBAR_H or 0))
	local ignContentH = IgnoreLayout.AbsoluteContentSize.Y + 6
	local ignCapped = math.min(ignContentH, 24 * 4 + 6)
	IgnoreScroll.CanvasSize = UDim2.new(0, 0, 0, ignContentH)
	local hasIgn = IgnoreScroll.Visible
	local ignBlockH = hasIgn and (SEP_H + 28 + ignCapped) or 0
	if isOpen then
		TweenService:Create(
			ScrollFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ Size = UDim2.new(1, 0, 0, cappedH) }
		):Play()
	else
		ScrollFrame.Size = UDim2.new(1, 0, 0, 0)
	end
	local ignY = listTop + cappedH
	IgnoreSep.Position = UDim2.new(0, 7, 0, ignY)
	IgnoreHeader.Position = UDim2.new(0, 0, 0, ignY + SEP_H)
	IgnoreScroll.Position = UDim2.new(0, 0, 0, ignY + SEP_H + 28)
	IgnoreScroll.Size = UDim2.new(1, 0, 0, ignCapped)
	local totalH = isOpen and (listTop + cappedH + ignBlockH) or HEADER_H
	TweenService:Create(
		MainFrame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, CFG.PanelW, 0, totalH) }
	):Play()
end
RunService.Heartbeat:Connect(function()
	if cycleEnabled and CycleBarBg.Visible then
		local ratio = math.clamp(cycleTimer / CFG.CycleDwell, 0, 1)
		CycleBarFill.Size = UDim2.new(ratio, 0, 1, 0)
	end
	-- update ESP hp labels live
	if espEnabled then
		for name, entry in pairs(espHighlights) do
			local bb = entry.billboard
			if bb and bb.Parent then
				local hpLbl = bb:FindFirstChild("_hpLbl")
				-- find the boss object to get fresh HP
				local folder = workspace:FindFirstChild(CFG.BossesFolder)
				local bossObj = folder and folder:FindFirstChild(name)
				if bossObj and hpLbl then
					local hum = getHumanoid(bossObj)
					if hum and hum.MaxHealth > 0 then
						local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
						hpLbl.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
						hpLbl.TextColor3 = getHpColor(ratio)
					end
					local distLbl = bb:FindFirstChild("_distLbl")
					local root2 = getRootPart(bossObj)
					if distLbl and root2 then
						distLbl.Text = tostring(getDistance(root2)) .. " st"
					end
				end
			end
		end
	end
end)
local function togglePanel()
	isOpen = not isOpen
	Chevron.Text = isOpen and "^" or "v"
	if isOpen then
		refreshAll()
	end
	updatePanelHeight()
end
local headerBtn = Instance.new("TextButton")
headerBtn.Size = UDim2.new(1, -210, 0, 40)
headerBtn.BackgroundTransparency = 1
headerBtn.Text = ""
headerBtn.ZIndex = 5
headerBtn.Parent = Header
headerBtn.MouseButton1Click:Connect(togglePanel)
local dragging, dragStart, startPos = false, nil, nil
headerBtn.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = inp.Position
		startPos = MainFrame.Position
	end
end)
headerBtn.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseMovement then
		if dragging then
			local d = inp.Position - dragStart
			MainFrame.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			MiniBtn.Position = MainFrame.Position
		end
		if miniDragging then
			local d = inp.Position - miniDragStart
			if math.abs(d.X) > 3 or math.abs(d.Y) > 3 then
				miniDidDrag = true
			end
			MiniBtn.Position = UDim2.new(
				miniStartPos.X.Scale,
				miniStartPos.X.Offset + d.X,
				miniStartPos.Y.Scale,
				miniStartPos.Y.Offset + d.Y
			)
			MainFrame.Position = MiniBtn.Position
		end
	end
end)
MinimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = true
	MainFrame.Visible = false
	MiniBtn.Visible = true
	MiniBtn.Position = MainFrame.Position
end)
MiniBtn.MouseButton1Click:Connect(function()
	if miniDidDrag then
		miniDidDrag = false
		return
	end
	isMinimized = false
	MiniBtn.Visible = false
	MainFrame.Visible = true
	MainFrame.Position = MiniBtn.Position
end)
FxBtn.MouseButton1Click:Connect(function()
	fxModeIdx = (fxModeIdx % #FX_MODES) + 1
	applyFx(FX_MODES[fxModeIdx])
	notify("FX: " .. FX_MODES[fxModeIdx]:upper(), 2)
end)
-- applyFx defined here so FxBtn is in scope
applyFx = function(mode)
	CFG.FxMode = mode
	if     mode == "rainbow" then startRainbow()
	elseif mode == "pulse"   then startPulse()
	elseif mode == "glow"    then startGlow()
	else                          stopFx()
	end
	FxBtn.Text = mode == "off" and "FX" or mode:upper()
	FxBtn.BackgroundColor3 = mode == "off"
		and Color3.fromRGB(50, 50, 65)
		or  CFG.AccentColor
	FxBtn.TextColor3 = mode == "off"
		and CFG.SubTextColor
		or  Color3.new(1, 1, 1)
end
EspBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	EspBtn.BackgroundColor3 = espEnabled and CFG.AccentColor or Color3.fromRGB(50, 50, 65)
	EspBtn.TextColor3 = espEnabled and Color3.new(1, 1, 1) or CFG.SubTextColor
	if not espEnabled then
		clearAllEsp()
	else
		syncEsp(getBossChildren())
	end
	notify("ESP: " .. (espEnabled and "ON" or "OFF"), 2)
end)
DstBtn.MouseButton1Click:Connect(function()
	sortByDist = not sortByDist
	DstBtn.BackgroundColor3 = sortByDist and Color3.fromRGB(40, 110, 200) or Color3.fromRGB(50, 50, 65)
	DstBtn.TextColor3 = sortByDist and Color3.new(1, 1, 1) or CFG.SubTextColor
	if isOpen then
		refreshAll()
		updatePanelHeight()
	end
end)
AlertBtn.MouseButton1Click:Connect(function()
	if alertsEnabled then
		stopAlerts()
		AlertBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
		AlertBtn.TextColor3 = CFG.SubTextColor
		notify("Boss Alerts: OFF", 2)
	else
		startAlerts()
		AlertBtn.BackgroundColor3 = Color3.fromRGB(220, 140, 20)
		AlertBtn.TextColor3 = Color3.new(1, 1, 1)
		notify("Boss Alerts: ON", 2)
	end
end)
CycleBtn.MouseButton1Click:Connect(function()
	if cycleEnabled then
		stopCycle()
		stopAttach()
		clearActiveAttach()
		CycleBtn.Text = "[>] CYCLE"
		CycleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
		CycleBtn.TextColor3 = CFG.SubTextColor
		CycleBarBg.Visible = false
		notify("Auto-Cycle: OFF", 2)
	else
		startCycle()
		CycleBtn.Text = "[.] CYCLE"
		CycleBtn.BackgroundColor3 = CFG.CycleColor
		CycleBtn.TextColor3 = Color3.new(1, 1, 1)
		CycleBarBg.Visible = true
	end
	if isOpen then
		refreshAll()
		updatePanelHeight()
	end
end)
SkipBtn.MouseButton1Click:Connect(function()
	if not cycleEnabled then
		return
	end
	local bosses = getFilteredSorted()
	if #bosses == 0 then
		return
	end
	cycleTimer = CFG.CycleDwell
	cycleIndex = cycleIndex % #bosses + 1
	local boss = bosses[cycleIndex]
	local root = getRootPart(boss)
	if root then
		clearActiveAttach()
		startAttach(root, boss.Name)
		startReattachWatch(boss.Name)
		notify("Skip -> " .. boss.Name, 2)
		if isOpen then
			refreshAll()
		end
	end
end)
local MODES = { "behind", "ontop", "orbit" }
local MODELABELS = { behind = "BEHIND", ontop = "ON TOP", orbit = "ORBIT" }
local MODECOLORS = {
	behind = Color3.fromRGB(40, 40, 52),
	ontop = Color3.fromRGB(40, 110, 210),
	orbit = CFG.OrbitColor,
}
local function applyModeBtn()
	ModeBtn.Text = MODELABELS[attachMode]
	ModeBtn.BackgroundColor3 = MODECOLORS[attachMode]
	ModeBtn.TextColor3 = attachMode == "behind" and CFG.SubTextColor or Color3.new(1, 1, 1)
end
applyModeBtn()
ModeBtn.MouseButton1Click:Connect(function()
	local idx = table.find(MODES, attachMode) or 1
	attachMode = MODES[(idx % #MODES) + 1]
	applyModeBtn()
	if _G._bossPanelAttachTarget then
		startAttach(_G._bossPanelAttachTarget, _G._bossPanelReattachName)
	end
	notify("Attach Mode: " .. MODELABELS[attachMode], 2)
end)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = SearchBox.Text
	if isOpen then
		refreshAll()
		updatePanelHeight()
	end
end)
ClearAllBtn.MouseButton1Click:Connect(function()
	ignoredSet = {}
	refreshAll()
	updatePanelHeight()
end)
UserInputService.InputBegan:Connect(function(inp, gpe)
	if gpe then
		return
	end
	if inp.KeyCode == CFG.ToggleKey then
		if isMinimized then
			isMinimized = false
			MiniBtn.Visible = false
			MainFrame.Visible = true
		else
			guiVisible = not guiVisible
			MainFrame.Visible = guiVisible
		end
		notify("BossPanel: " .. (MainFrame.Visible and "SHOWN" or "HIDDEN"), 1)
	end
end)
task.spawn(function()
	while task.wait(CFG.RefreshRate) do
		if isOpen then
			refreshAll()
			updatePanelHeight()
		end
	end
end)
applyFx(CFG.FxMode)
refreshAll()
print(
	string.format("[BossesPanel v4.1] Loaded — toggle key: %s | open panel to expand", tostring(CFG.ToggleKey.Name))
) -- end


-- auto answer math questions addon
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local MathQuizQuestion = ReplicatedStorage:WaitForChild("MathQuizQuestion")
local MathQuizWinner = ReplicatedStorage:WaitForChild("MathQuizWinner")


local ANSWER_DELAY = 1.7
local quizActive = false


local function solveEquation(question)
	local q = question
	q = q:gsub("\195\151", "*")
	q = q:gsub("\195\183", "/")
	q = q:gsub("[xX]", "*")
	q = q:gsub("[%(%)%[%]]", "")
	q = q:gsub("%s+", " "):match("^%s*(.-)%s*$")
	-- tokenize into numbers and operators
	local tokens = {}
	for tok in q:gmatch("[%+%-%*/]?%s*%-?%d+%.?%d*") do
		local op, num = tok:match("^([%+%-%*/])%s*(%-?%d+%.?%d*)$")
		if op and num then
			table.insert(tokens, op)
			table.insert(tokens, tonumber(num))
		else
			local n = tonumber(tok:match("%-?%d+%.?%d*"))
			if n then
				table.insert(tokens, n)
			end
		end
	end
	if #tokens == 0 then return nil end
	if type(tokens[1]) ~= "number" then return nil end
	-- pass 1: resolve * and / in-place
	local i = 2
	while i <= #tokens do
		local op = tokens[i]
		if op == "*" or op == "/" then
			local lhs = tokens[i - 1]
			local rhs = tokens[i + 1]
			if type(lhs) ~= "number" or type(rhs) ~= "number" then break end
			if op == "/" and rhs == 0 then return nil end
			local val = op == "*" and lhs * rhs or lhs / rhs
			-- replace the 3 slots (lhs, op, rhs) with the result
			table.remove(tokens, i + 1)
			table.remove(tokens, i)
			tokens[i - 1] = val
			-- don't advance i, recheck same position
		else
			i = i + 2
		end
	end
	-- pass 2: resolve + and -
	local result = tokens[1]
	i = 2
	while i <= #tokens do
		local op = tokens[i]
		local rhs = tokens[i + 1]
		if type(op) ~= "string" or type(rhs) ~= "number" then break end
		if op == "+" then
			result = result + rhs
		elseif op == "-" then
			result = result - rhs
		end
		i = i + 2
	end
	local rounded = math.round(result)
	return (math.abs(result - rounded) < 0.0001) and rounded or result
end
MathQuizQuestion.OnClientEvent:Connect(function(question, isInsane)
	if not question or question == "" then
		return
	end
	quizActive = true
	local answer = solveEquation(question)
	if not answer then
		return
	end
	task.delay(ANSWER_DELAY, function()
		if not quizActive then
			return
		end
		TextChatService.TextChannels.RBXGeneral:SendAsync(tostring(answer))
	end)
end)
MathQuizWinner.OnClientEvent:Connect(function()
	quizActive = false
end)

-- made by zuka math is hard on god
