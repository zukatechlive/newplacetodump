local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local CONFIG = {
	VELOCITY_MAGNITUDE = 700,
	MAX_FORCE = 1e9,
	FLOOD_BATCH = 20,
	OWNERSHIP_INTERVAL = 0.35,
	SIMRADIUS_INTERVAL = 1.5,
}

local Session = {
	Active = false,
	TargetPlayer = nil,
	Managed = {},
	Connections = {},
}

local function SafeHiddenProp(inst, prop, val)
	if sethiddenproperty then
		pcall(sethiddenproperty, inst, prop, val)
	end
end

local function BumpSimRadius()
	SafeHiddenProp(LocalPlayer, "SimulationRadius", math.huge)
end

local function TryClaimOwnership(part)
	BumpSimRadius()
	pcall(function()
		part:SetNetworkOwner(LocalPlayer)
	end)
end

local function IsValidPart(part)
	if not (part and part.Parent) then
		return false
	end
	if not part:IsA("BasePart") then
		return false
	end
	if part.Anchored then
		return false
	end
	local char = LocalPlayer.Character
	if char and part:IsDescendantOf(char) then
		return false
	end
	if part.Parent:FindFirstChildOfClass("Humanoid") then
		return false
	end
	return true
end

local function ReleasePart(part)
	local data = Session.Managed[part]
	if not data then
		return
	end
	if data.conn then
		pcall(function()
			data.conn:Disconnect()
		end)
	end
	pcall(function()
		if data.bv and data.bv.Parent then
			data.bv:Destroy()
		end
	end)
	Session.Managed[part] = nil
end

local function ApplyFling(part)
	if Session.Managed[part] then
		return
	end
	if not IsValidPart(part) then
		return
	end
	if not Session.Active then
		return
	end

	TryClaimOwnership(part)

	local bv = Instance.new("BodyVelocity")
	bv.Name = "GSF_BV"
	bv.MaxForce = Vector3.new(CONFIG.MAX_FORCE, CONFIG.MAX_FORCE, CONFIG.MAX_FORCE)
	bv.Velocity = Vector3.zero
	bv.Parent = part

	local lastClaim = 0

	local conn = RunService.Heartbeat:Connect(function()
		if not Session.Active or not IsValidPart(part) or part.Anchored then
			ReleasePart(part)
			return
		end
		local now = os.clock()
		if now - lastClaim >= CONFIG.OWNERSHIP_INTERVAL then
			TryClaimOwnership(part)
			lastClaim = now
		end
		local target = Session.TargetPlayer
		if target and target.Character then
			local root = target.Character:FindFirstChild("HumanoidRootPart")
			if root and bv and bv.Parent then
				local dir = root.Position - part.Position
				if dir.Magnitude > 0 then
					bv.Velocity = dir.Unit * CONFIG.VELOCITY_MAGNITUDE
				end
			end
		end
	end)

	Session.Managed[part] = { bv = bv, conn = conn, lastClaim = lastClaim }
end

local function StopSession()
	Session.Active = false
	local snapshot = {}
	for part in pairs(Session.Managed) do
		snapshot[#snapshot + 1] = part
	end
	for _, part in ipairs(snapshot) do
		ReleasePart(part)
	end
	Session.Managed = {}
	Session.TargetPlayer = nil
	for _, c in ipairs(Session.Connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	Session.Connections = {}
end

local function StartSession(target)
	if Session.Active then
		StopSession()
	end
	Session.Active = true
	Session.TargetPlayer = target

	task.spawn(function()
		local parts = {}
		for _, v in ipairs(Workspace:GetDescendants()) do
			if IsValidPart(v) then
				parts[#parts + 1] = v
			end
		end
		local i = 1
		while i <= #parts and Session.Active do
			for b = 0, CONFIG.FLOOD_BATCH - 1 do
				local part = parts[i + b]
				if not part then
					break
				end
				ApplyFling(part)
			end
			i = i + CONFIG.FLOOD_BATCH
			RunService.Heartbeat:Wait()
		end
	end)

	local addedConn = Workspace.DescendantAdded:Connect(function(v)
		if Session.Active then
			task.delay(0.05, function()
				ApplyFling(v)
			end)
		end
	end)
	table.insert(Session.Connections, addedConn)

	local lastSim = 0
	local simConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastSim >= CONFIG.SIMRADIUS_INTERVAL then
			BumpSimRadius()
			lastSim = now
		end
	end)
	table.insert(Session.Connections, simConn)
end

local guiParent = (gethui and gethui()) or LocalPlayer.PlayerGui
local existing = guiParent:FindFirstChild("GSF_Gui")
if existing then
	existing:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GSF_Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = guiParent

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 270, 0, 185)
Main.Position = UDim2.new(0.05, 0, 0.38, 0)
Main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.ClipsDescendants = false
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 7)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(55, 55, 55)
Stroke.Thickness = 1

local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 7)
local TitleFill = Instance.new("Frame", TitleBar)
TitleFill.Size = UDim2.new(1, 0, 0.5, 0)
TitleFill.Position = UDim2.new(0, 0, 0.5, 0)
TitleFill.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
TitleFill.BorderSizePixel = 0
local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size = UDim2.new(1, -10, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "GHOST SWEEP FLINGER  v5"
TitleLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
TitleLabel.Font = Enum.Font.Code
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local StatusDot = Instance.new("Frame", TitleBar)
StatusDot.Size = UDim2.new(0, 8, 0, 8)
StatusDot.Position = UDim2.new(1, -18, 0.5, -4)
StatusDot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
StatusDot.BorderSizePixel = 0
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local Input = Instance.new("TextBox", Main)
Input.Size = UDim2.new(0, 192, 0, 34)
Input.Position = UDim2.new(0.06, 0, 0, 46)
Input.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Input.PlaceholderText = "Target username..."
Input.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
Input.Text = ""
Input.TextColor3 = Color3.fromRGB(220, 220, 220)
Input.Font = Enum.Font.Code
Input.TextSize = 12
Input.ClearTextOnFocus = false
Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 5)
local InputStroke = Instance.new("UIStroke", Input)
InputStroke.Color = Color3.fromRGB(40, 40, 40)
InputStroke.Thickness = 1

local ArrowBtn = Instance.new("TextButton", Main)
ArrowBtn.Size = UDim2.new(0, 34, 0, 34)
ArrowBtn.Position = UDim2.new(0, 202, 0, 46)
ArrowBtn.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
ArrowBtn.Text = "▼"
ArrowBtn.TextColor3 = Color3.fromRGB(140, 140, 150)
ArrowBtn.Font = Enum.Font.Code
ArrowBtn.TextSize = 14
ArrowBtn.AutoButtonColor = false
ArrowBtn.BorderSizePixel = 0
Instance.new("UICorner", ArrowBtn).CornerRadius = UDim.new(0, 5)
local ArrowStroke = Instance.new("UIStroke", ArrowBtn)
ArrowStroke.Color = Color3.fromRGB(40, 40, 40)
ArrowStroke.Thickness = 1

local DROP_MAX_VISIBLE = 5
local DROP_ROW_H = 26

local Dropdown = Instance.new("Frame", Main)
Dropdown.Name = "Dropdown"
Dropdown.Size = UDim2.new(0, 236, 0, DROP_ROW_H * DROP_MAX_VISIBLE)
Dropdown.Position = UDim2.new(0.06, 0, 0, 84)
Dropdown.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
Dropdown.BorderSizePixel = 0
Dropdown.Visible = false
Dropdown.ZIndex = 10
Dropdown.ClipsDescendants = true
Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 5)
local DropStroke = Instance.new("UIStroke", Dropdown)
DropStroke.Color = Color3.fromRGB(50, 50, 60)
DropStroke.Thickness = 1

local DropScroll = Instance.new("ScrollingFrame", Dropdown)
DropScroll.Size = UDim2.new(1, 0, 1, 0)
DropScroll.BackgroundTransparency = 1
DropScroll.BorderSizePixel = 0
DropScroll.ScrollBarThickness = 3
DropScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
DropScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
DropScroll.ZIndex = 10
local DropList = Instance.new("UIListLayout", DropScroll)
DropList.SortOrder = Enum.SortOrder.LayoutOrder
DropList.Padding = UDim.new(0, 0)

local dropOpen = false

local function closeDropdown()
	dropOpen = false
	Dropdown.Visible = false
	ArrowBtn.Text = "▼"
end

local function openDropdown()
	dropOpen = true
	Dropdown.Visible = true
	ArrowBtn.Text = "▲"
end

local function populateDropdown()
	for _, child in ipairs(DropScroll:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local playerList = Players:GetPlayers()
	local rowCount = 0

	for _, p in ipairs(playerList) do
		if p ~= LocalPlayer then
			rowCount += 1
			local row = Instance.new("TextButton", DropScroll)
			row.Name = p.Name
			row.Size = UDim2.new(1, 0, 0, DROP_ROW_H)
			row.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
			row.BorderSizePixel = 0
			row.Text = "  " .. p.DisplayName .. "  (@" .. p.Name .. ")"
			row.TextColor3 = Color3.fromRGB(190, 190, 200)
			row.Font = Enum.Font.Code
			row.TextSize = 11
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.AutoButtonColor = false
			row.LayoutOrder = rowCount
			row.ZIndex = 11

			row.MouseEnter:Connect(function()
				row.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
				row.TextColor3 = Color3.fromRGB(255, 255, 255)
			end)
			row.MouseLeave:Connect(function()
				row.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
				row.TextColor3 = Color3.fromRGB(190, 190, 200)
			end)

			row.MouseButton1Click:Connect(function()
				Input.Text = p.Name
				closeDropdown()
			end)
		end
	end

	if rowCount == 0 then
		local placeholder = Instance.new("TextLabel", DropScroll)
		placeholder.Size = UDim2.new(1, 0, 0, DROP_ROW_H)
		placeholder.BackgroundTransparency = 1
		placeholder.Text = "  no other players"
		placeholder.TextColor3 = Color3.fromRGB(70, 70, 80)
		placeholder.Font = Enum.Font.Code
		placeholder.TextSize = 11
		placeholder.TextXAlignment = Enum.TextXAlignment.Left
		placeholder.ZIndex = 11
		rowCount = 1
	end

	DropScroll.CanvasSize = UDim2.new(0, 0, 0, rowCount * DROP_ROW_H)
end

ArrowBtn.MouseButton1Click:Connect(function()
	if dropOpen then
		closeDropdown()
	else
		populateDropdown()
		openDropdown()
	end
end)

Main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		task.delay(0.05, function()
			if dropOpen then
				closeDropdown()
			end
		end)
	end
end)
Dropdown.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		input:cancel()
	end
end)

local StatusLabel = Instance.new("TextLabel", Main)
StatusLabel.Size = UDim2.new(0.88, 0, 0, 18)
StatusLabel.Position = UDim2.new(0.06, 0, 0, 100)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left

local ActionBtn = Instance.new("TextButton", Main)
ActionBtn.Size = UDim2.new(0.88, 0, 0, 38)
ActionBtn.Position = UDim2.new(0.06, 0, 0, 126)
ActionBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
ActionBtn.Text = "SWEEP & FLING"
ActionBtn.TextColor3 = Color3.fromRGB(190, 190, 190)
ActionBtn.Font = Enum.Font.Code
ActionBtn.TextSize = 13
ActionBtn.AutoButtonColor = false
Instance.new("UICorner", ActionBtn).CornerRadius = UDim.new(0, 5)
local BtnStroke = Instance.new("UIStroke", ActionBtn)
BtnStroke.Color = Color3.fromRGB(50, 50, 50)
BtnStroke.Thickness = 1

ActionBtn.MouseEnter:Connect(function()
	if not Session.Active then
		ActionBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	end
end)
ActionBtn.MouseLeave:Connect(function()
	if not Session.Active then
		ActionBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	end
end)

local function SetActiveUI(state)
	if state then
		ActionBtn.Text = "HALT"
		ActionBtn.BackgroundColor3 = Color3.fromRGB(100, 22, 22)
		BtnStroke.Color = Color3.fromRGB(160, 40, 40)
		StatusDot.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
	else
		ActionBtn.Text = "SWEEP & FLING"
		ActionBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		BtnStroke.Color = Color3.fromRGB(50, 50, 50)
		StatusDot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		StatusLabel.Text = ""
		StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	end
end

ActionBtn.MouseButton1Click:Connect(function()
	closeDropdown()

	if Session.Active then
		StopSession()
		SetActiveUI(false)
		return
	end

	local query = Input.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if query == "" then
		StatusLabel.Text = "enter a username first"
		StatusLabel.TextColor3 = Color3.fromRGB(180, 60, 60)
		return
	end

	local found = nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			if p.Name:lower():find(query, 1, true) or p.DisplayName:lower():find(query, 1, true) then
				found = p
				break
			end
		end
	end

	if not found then
		StatusLabel.Text = "player not found"
		StatusLabel.TextColor3 = Color3.fromRGB(180, 60, 60)
		return
	end

	StatusLabel.Text = "target: " .. found.Name
	StatusLabel.TextColor3 = Color3.fromRGB(90, 160, 90)
	SetActiveUI(true)
	StartSession(found)
end)

Players.PlayerRemoving:Connect(function(p)
	if Session.Active and p == Session.TargetPlayer then
		StopSession()
		SetActiveUI(false)
		StatusLabel.Text = "target left the game"
		StatusLabel.TextColor3 = Color3.fromRGB(180, 60, 60)
	end
end)

local pendingTarget = nil

LocalPlayer.CharacterAdded:Connect(function()
	if pendingTarget and pendingTarget.Parent then
		task.wait(1)
		StatusLabel.Text = "target: " .. pendingTarget.Name
		StatusLabel.TextColor3 = Color3.fromRGB(90, 160, 90)
		SetActiveUI(true)
		StartSession(pendingTarget)
	end
	pendingTarget = nil
end)

LocalPlayer.CharacterRemoving:Connect(function()
	if Session.Active then
		pendingTarget = Session.TargetPlayer
		StopSession()
		SetActiveUI(false)
	end
end)
