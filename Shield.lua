local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local CONFIG = {
	RINGS = {
		{ radius = 5, height = 1.5, speed = 1.0 },
		{ radius = 8, height = 2.5, speed = 0.75 },
		{ radius = 11, height = 1.0, speed = 0.5 },
	},
	BASE_SPEED = 3,
	PULL_STRENGTH = 22,
	PART_CAP = 180,
	RING_CAP = 60,
	SCAN_RADIUS = 160,
	SIM_RADIUS = 1e9,
	SIM_INTERVAL = 1,
	CLEANUP_INTERVAL = 0.5,
}

local State = {
	Active = false,
	Angle = 0,
	ManagedParts = {},
	Connections = {},
	TargetPlayer = nil,
}

local function safeDestroy(instance)
	if instance and instance.Parent then
		pcall(function()
			instance:Destroy()
		end)
	end
end

local function safeSetOwner(part)
	pcall(function()
		part:SetNetworkOwner(LocalPlayer)
	end)
end

local function setSimRadius(value)
	pcall(function()
		if sethiddenproperty then
			sethiddenproperty(LocalPlayer, "SimulationRadius", value)
		end
	end)
end

local function getHRP()
	local char = LocalPlayer.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getTargetHRP()
	local target = State.TargetPlayer
	if target and target ~= LocalPlayer and target.Parent then
		local char = target.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end
	return getHRP()
end

local function getHUI()
	local ok, result = pcall(function()
		return (gethui and gethui()) or CoreGui
	end)
	return ok and result or CoreGui
end

local function setCharacterCollision(enabled)
	local char = LocalPlayer.Character
	if not char then
		return
	end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = enabled
		end
	end
end

local function collectParts()
	local hrp = getTargetHRP()
	if not hrp then
		return {}
	end
	local hrpPos = hrp.Position
	local candidates = {}
	for _, v in ipairs(Workspace:GetDescendants()) do
		if #candidates >= CONFIG.PART_CAP then
			break
		end
		if
			v:IsA("BasePart")
			and not v.Anchored
			and not v:IsDescendantOf(LocalPlayer.Character)
			and (not State.TargetPlayer or not v:IsDescendantOf(State.TargetPlayer.Character or Instance.new("Folder")))
			and not v.Parent:FindFirstChildOfClass("Humanoid")
		then
			local dist = (v.Position - hrpPos).Magnitude
			if dist < CONFIG.SCAN_RADIUS then
				table.insert(candidates, { part = v, dist = dist })
			end
		end
	end
	table.sort(candidates, function(a, b)
		return a.dist < b.dist
	end)
	local result = {}
	for _, entry in ipairs(candidates) do
		table.insert(result, entry.part)
	end
	return result
end

local function attachPart(part, ringIndex, seed)
	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1, 1, 1) * math.huge
	bv.Velocity = Vector3.zero
	bv.Parent = part

	local bav = Instance.new("BodyAngularVelocity")
	bav.MaxTorque = Vector3.new(1, 1, 1) * math.huge
	local spinAxes = {
		Vector3.new(0, 10, 3),
		Vector3.new(3, 8, 0),
		Vector3.new(0, 12, 5),
	}
	bav.AngularVelocity = spinAxes[ringIndex] or spinAxes[1]
	bav.Parent = part

	State.ManagedParts[part] = {
		Vel = bv,
		Spin = bav,
		Ring = ringIndex,
		Seed = seed,
	}
end

local function detachPart(part)
	local data = State.ManagedParts[part]
	if not data then
		return
	end
	safeDestroy(data.Vel)
	safeDestroy(data.Spin)
	State.ManagedParts[part] = nil
end

local function detachAll()
	for part in pairs(State.ManagedParts) do
		detachPart(part)
	end
end

local function orbitTarget(hrpPos, angle, seed, ring)
	local a = angle * ring.speed + seed
	return hrpPos
		+ Vector3.new(
			math.cos(a) * ring.radius,
			math.sin(a * 1.3 + seed * 0.4) * ring.height,
			math.sin(a) * ring.radius
		)
end

local function startPhysicsLoop()
	local conn = RunService.Heartbeat:Connect(function(dt)
		if not State.Active then
			return
		end
		local hrp = getTargetHRP()
		if not hrp then
			return
		end

		State.Angle = State.Angle + dt * CONFIG.BASE_SPEED
		setCharacterCollision(false)

		for part, data in pairs(State.ManagedParts) do
			if not part.Parent or part.Anchored then
				detachPart(part)
				continue
			end
			safeSetOwner(part)
			local ring = CONFIG.RINGS[data.Ring]
			local target = orbitTarget(hrp.Position, State.Angle, data.Seed, ring)
			data.Vel.Velocity = (target - part.Position) * CONFIG.PULL_STRENGTH
		end
	end)
	table.insert(State.Connections, conn)
end

local function disconnectAll()
	for _, conn in ipairs(State.Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	State.Connections = {}
end

local function activate()
	State.Active = true
	State.Angle = 0
	local parts = collectParts()
	local ringCount = #CONFIG.RINGS
	for i, part in ipairs(parts) do
		local ringIndex = ((i - 1) % ringCount) + 1
		local ringPop = 0
		for _, d in pairs(State.ManagedParts) do
			if d.Ring == ringIndex then
				ringPop += 1
			end
		end
		if ringPop < CONFIG.RING_CAP then
			attachPart(part, ringIndex, math.random() * math.pi * 2)
		end
	end
	startPhysicsLoop()
	task.spawn(function()
		while State.Active do
			task.wait(CONFIG.CLEANUP_INTERVAL)
			for part in pairs(State.ManagedParts) do
				if not part.Parent or part.Anchored then
					detachPart(part)
				end
			end
		end
	end)
end

local function deactivate()
	State.Active = false
	disconnectAll()
	detachAll()
	setCharacterCollision(true)
end

local function toggle()
	if State.Active then
		deactivate()
	else
		activate()
	end
	return State.Active
end

task.spawn(function()
	while true do
		setSimRadius(CONFIG.SIM_RADIUS)
		task.wait(CONFIG.SIM_INTERVAL)
	end
end)

local function buildUI()
	local parent = getHUI()
	if not parent then
		return
	end

	local existing = parent:FindFirstChild("OrbitShield_UI")
	if existing then
		existing:Destroy()
	end

	local Screen = Instance.new("ScreenGui")
	Screen.Name = "OrbitShield_UI"
	Screen.ResetOnSpawn = false
	Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Screen.Parent = parent

	local Frame = Instance.new("Frame")
	Frame.Name = "MainFrame"
	Frame.Size = UDim2.fromOffset(220, 160)
	Frame.Position = UDim2.new(0.5, -110, 0.08, 0)
	Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 14)
	Frame.BorderSizePixel = 0
	Frame.Parent = Screen
	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke", Frame)
	stroke.Color = Color3.fromRGB(0, 210, 140)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.3

	local Header = Instance.new("TextLabel")
	Header.Size = UDim2.new(1, 0, 0, 22)
	Header.Position = UDim2.new(0, 0, 0, 6)
	Header.BackgroundTransparency = 1
	Header.Text = "ORBIT SHIELD"
	Header.TextColor3 = Color3.fromRGB(0, 210, 140)
	Header.Font = Enum.Font.Code
	Header.TextSize = 11
	Header.TextXAlignment = Enum.TextXAlignment.Center
	Header.Parent = Frame

	local Dot = Instance.new("Frame")
	Dot.Size = UDim2.fromOffset(6, 6)
	Dot.Position = UDim2.new(0, 10, 0, 10)
	Dot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	Dot.BorderSizePixel = 0
	Dot.Parent = Frame
	Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

	local TargetLabel = Instance.new("TextLabel")
	TargetLabel.Size = UDim2.new(0.88, 0, 0, 14)
	TargetLabel.Position = UDim2.new(0.06, 0, 0, 34)
	TargetLabel.BackgroundTransparency = 1
	TargetLabel.Text = "SHIELD TARGET"
	TargetLabel.TextColor3 = Color3.fromRGB(0, 160, 110)
	TargetLabel.Font = Enum.Font.Code
	TargetLabel.TextSize = 9
	TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
	TargetLabel.Parent = Frame

	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Size = UDim2.new(0.88, 0, 0, 52)
	ScrollFrame.Position = UDim2.new(0.06, 0, 0, 50)
	ScrollFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	ScrollFrame.BorderSizePixel = 0
	ScrollFrame.ScrollBarThickness = 3
	ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 210, 140)
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollFrame.ClipsDescendants = true
	ScrollFrame.Parent = Frame
	Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 4)

	local ScrollStroke = Instance.new("UIStroke", ScrollFrame)
	ScrollStroke.Color = Color3.fromRGB(40, 40, 55)
	ScrollStroke.Thickness = 1
	ScrollStroke.Transparency = 0.3

	local ListLayout = Instance.new("UIListLayout", ScrollFrame)
	ListLayout.SortOrder = Enum.SortOrder.Name
	ListLayout.Padding = UDim.new(0, 1)

	local selectedBtn = nil
	local playerButtons = {}

	local function selectTarget(player, btn)
		if selectedBtn then
			selectedBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
			selectedBtn.TextColor3 = Color3.fromRGB(160, 160, 170)
		end
		State.TargetPlayer = player
		selectedBtn = btn
		btn.BackgroundColor3 = Color3.fromRGB(0, 45, 32)
		btn.TextColor3 = Color3.fromRGB(0, 210, 140)

		if State.Active then
			deactivate()
			activate()
		end
	end

	local function makePlayerBtn(displayName, player, sortKey)
		local existing = playerButtons[sortKey]
		if existing then
			return
		end

		local btn = Instance.new("TextButton")
		btn.Name = sortKey
		btn.Size = UDim2.new(1, 0, 0, 18)
		btn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
		btn.BorderSizePixel = 0
		btn.Text = "  " .. displayName
		btn.TextColor3 = Color3.fromRGB(160, 160, 170)
		btn.Font = Enum.Font.Code
		btn.TextSize = 10
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Parent = ScrollFrame

		if player == nil and selectedBtn == nil then
			selectedBtn = btn
			btn.BackgroundColor3 = Color3.fromRGB(0, 45, 32)
			btn.TextColor3 = Color3.fromRGB(0, 210, 140)
		end

		btn.MouseButton1Click:Connect(function()
			selectTarget(player, btn)
		end)

		playerButtons[sortKey] = btn
	end

	local function refreshPlayerList()
		makePlayerBtn("★ Self", nil, "00_Self")

		local currentKeys = { ["00_Self"] = true }
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				local key = "01_" .. p.Name
				currentKeys[key] = true
				makePlayerBtn(p.DisplayName .. " (@" .. p.Name .. ")", p, key)
			end
		end

		for key, btn in pairs(playerButtons) do
			if not currentKeys[key] then
				btn:Destroy()
				playerButtons[key] = nil
				if State.TargetPlayer and State.TargetPlayer.Name == key:sub(4) then
					selectTarget(nil, playerButtons["00_Self"])
				end
			end
		end

		local count = 0
		for _ in pairs(playerButtons) do
			count += 1
		end
		ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * 19)
	end

	refreshPlayerList()
	task.spawn(function()
		while Screen.Parent do
			task.wait(2)
			refreshPlayerList()
		end
	end)

	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(0.88, 0, 0, 34)
	Btn.Position = UDim2.new(0.06, 0, 0, 110)
	Btn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	Btn.Text = "ACTIVATE"
	Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
	Btn.Font = Enum.Font.Code
	Btn.TextSize = 13
	Btn.BorderSizePixel = 0
	Btn.Parent = Frame
	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)

	local btnStroke = Instance.new("UIStroke", Btn)
	btnStroke.Color = Color3.fromRGB(50, 50, 60)
	btnStroke.Thickness = 1
	btnStroke.Transparency = 0.5

	local Counter = Instance.new("TextLabel")
	Counter.Size = UDim2.new(1, 0, 0, 14)
	Counter.Position = UDim2.new(0, 0, 1, -16)
	Counter.BackgroundTransparency = 1
	Counter.Text = "0 parts"
	Counter.TextColor3 = Color3.fromRGB(80, 80, 90)
	Counter.Font = Enum.Font.Code
	Counter.TextSize = 10
	Counter.TextXAlignment = Enum.TextXAlignment.Center
	Counter.Parent = Frame

	local dragging, dragStart, frameStart
	Frame.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			frameStart = Frame.Position
		end
	end)
	Frame.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart
			Frame.Position = UDim2.new(
				frameStart.X.Scale,
				frameStart.X.Offset + delta.X,
				frameStart.Y.Scale,
				frameStart.Y.Offset + delta.Y
			)
		end
	end)

	local function syncUI(active)
		if active then
			Btn.Text = "DEACTIVATE"
			Btn.TextColor3 = Color3.fromRGB(0, 210, 140)
			Btn.BackgroundColor3 = Color3.fromRGB(0, 35, 25)
			btnStroke.Color = Color3.fromRGB(0, 210, 140)
			btnStroke.Transparency = 0
			Dot.BackgroundColor3 = Color3.fromRGB(0, 210, 140)
			stroke.Transparency = 0
		else
			Btn.Text = "ACTIVATE"
			Btn.TextColor3 = Color3.fromRGB(180, 180, 180)
			Btn.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
			btnStroke.Color = Color3.fromRGB(50, 50, 60)
			btnStroke.Transparency = 0.5
			Dot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			stroke.Transparency = 0.3
			Counter.Text = "0 parts"
		end
	end

	Btn.MouseButton1Click:Connect(function()
		local isNowActive = toggle()
		syncUI(isNowActive)
	end)

	task.spawn(function()
		while Screen.Parent do
			if State.Active then
				local count = 0
				for _ in pairs(State.ManagedParts) do
					count += 1
				end
				Counter.Text = count .. " part" .. (count == 1 and "" or "s") .. " orbiting"
			end
			task.wait(0.25)
		end
	end)
end

buildUI()
