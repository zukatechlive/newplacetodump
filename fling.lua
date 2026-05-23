local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CONFIG = {
	VELOCITY_MAGNITUDE = 700,
	MAX_FORCE = 1e9,
	SWEEP_BATCH = 5,
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
	if
		part:IsDescendantOf(LocalPlayer.Character or game)
		and LocalPlayer.Character
		and part:IsDescendantOf(LocalPlayer.Character)
	then
		return false
	end
	if part.Parent:FindFirstChildOfClass("Humanoid") then
		return false
	end
	return true
end
local function TryClaimOwnership(part)
	SafeHiddenProp(LocalPlayer, "SimulationRadius", math.huge)
	pcall(function()
		part:SetNetworkOwner(LocalPlayer)
	end)
end
local function SetCharacterCollision(state)
	local char = LocalPlayer.Character
	if not char then
		return
	end
	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = state
		end
	end
end
local function CleanPartData(part, data)
	if data.conn then
		data.conn:Disconnect()
		data.conn = nil
	end
	pcall(function()
		if data.bv and data.bv.Parent then
			data.bv:Destroy()
		end
	end)
end
local function ReleasePart(part)
	local data = Session.Managed[part]
	if not data then
		return
	end
	CleanPartData(part, data)
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
	local conn = RunService.Heartbeat:Connect(function(dt)
		if not Session.Active or not IsValidPart(part) then
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
				local dir = (root.Position - part.Position)
				if dir.Magnitude > 0 then
					bv.Velocity = dir.Unit * CONFIG.VELOCITY_MAGNITUDE
				end
			end
		end
	end)
	Session.Managed[part] = { bv = bv, conn = conn, lastClaim = lastClaim }
end
local function GhostSweep()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local origin = hrp.CFrame
	SetCharacterCollision(false)
	local targets = {}
	for _, v in ipairs(Workspace:GetDescendants()) do
		if IsValidPart(v) then
			targets[#targets + 1] = v
		end
	end
	local i = 1
	while i <= #targets and Session.Active do
		for b = 0, CONFIG.SWEEP_BATCH - 1 do
			local part = targets[i + b]
			if not part then
				break
			end
			if part.Parent and not part.Anchored then
				hrp.CFrame = part.CFrame
				TryClaimOwnership(part)
			end
		end
		i = i + CONFIG.SWEEP_BATCH
		RunService.Heartbeat:Wait()
	end
	if hrp and hrp.Parent then
		hrp.CFrame = origin
	end
	SetCharacterCollision(true)
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
		c:Disconnect()
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
		GhostSweep()
		for _, v in ipairs(Workspace:GetDescendants()) do
			if Session.Active then
				ApplyFling(v)
			end
		end
		local addedConn = Workspace.DescendantAdded:Connect(function(v)
			if Session.Active then
				task.delay(0.1, function()
					ApplyFling(v)
				end)
			end
		end)
		table.insert(Session.Connections, addedConn)
	end)
	local lastSim = 0
	local simConn = RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastSim >= CONFIG.SIMRADIUS_INTERVAL then
			SafeHiddenProp(LocalPlayer, "SimulationRadius", math.huge)
			lastSim = now
		end
	end)
	table.insert(Session.Connections, simConn)
end
local existingGui = (gethui and gethui() or LocalPlayer.PlayerGui):FindFirstChild("GSF_Gui")
if existingGui then
	existingGui:Destroy()
end
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GSF_Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = (gethui and gethui()) or LocalPlayer.PlayerGui
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 270, 0, 170)
Main.Position = UDim2.new(0.05, 0, 0.38, 0)
Main.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
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
TitleLabel.Text = "GHOST SWEEP FLINGER  v4"
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
Input.Size = UDim2.new(0.88, 0, 0, 34)
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
local StatusLabel = Instance.new("TextLabel", Main)
StatusLabel.Size = UDim2.new(0.88, 0, 0, 18)
StatusLabel.Position = UDim2.new(0.06, 0, 0, 86)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
StatusLabel.Font = Enum.Font.Code
StatusLabel.TextSize = 11
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
local ActionBtn = Instance.new("TextButton", Main)
ActionBtn.Size = UDim2.new(0.88, 0, 0, 38)
ActionBtn.Position = UDim2.new(0.06, 0, 0, 112)
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
