local CFrameDesync = {
	State = {
		IsEnabled = false,
		DesyncActive = false,
		RealCFrame = CFrame.new(),
		VisualOffset = CFrame.new(),
		UI = nil,
		Mode = "position",
		Increment = 1,
		Connections = {},
		FakeCharacter = nil,
		GhostHighlight = nil,
		PinnedParts = {},
		CamAnchor = nil,
		SavedCameraType = nil,
	},
	Config = {
		HighlightColor = Color3.fromRGB(255, 0, 200),
		PinnedColor = Color3.fromRGB(0, 220, 255),
		ShowFakeCharacter = true,
	},
}
local PART_GROUPS = {
	{ label = "HEAD", parts = { "Head" } },
	{ label = "TORSO", parts = { "UpperTorso", "LowerTorso", "Torso" } },
	{ label = "LEFT ARM", parts = { "LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm" } },
	{ label = "RIGHT ARM", parts = { "RightUpperArm", "RightLowerArm", "RightHand", "Right Arm" } },
	{ label = "LEFT LEG", parts = { "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg" } },
	{ label = "RIGHT LEG", parts = { "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg" } },
}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local function getChar()
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")
	return char, hrp, hum
end
local function isPinned(self, partName)
	return self.State.PinnedParts[partName] == true
end
function CFrameDesync:ActivateDesync()
	local char, hrp = getChar()
	if not hrp then
		warn("[CFrameDesync] No character.")
		return
	end
	self.State.DesyncActive = true
	self.State.RealCFrame = hrp.CFrame
	if self.Config.ShowFakeCharacter then
		self:CreateFakeCharacter()
	end
	self.State.Connections.Heartbeat = RunService.Heartbeat:Connect(function()
		local _, root = getChar()
		if not root then
			return
		end
		self.State.RealCFrame = root.CFrame
		local rotOnly = CFrame.fromMatrix(
			Vector3.zero,
			self.State.VisualOffset.RightVector,
			self.State.VisualOffset.UpVector,
			-self.State.VisualOffset.LookVector
		)
		local spoof = CFrame.new(root.CFrame.Position + self.State.VisualOffset.Position)
			* CFrame.fromMatrix(Vector3.zero, root.CFrame.RightVector, root.CFrame.UpVector, -root.CFrame.LookVector)
			* rotOnly
		root.CFrame = spoof
	end)
	self.State.Connections.RenderStepped = RunService.RenderStepped:Connect(function()
		local _, root = getChar()
		if not root then
			return
		end
		root.CFrame = self.State.RealCFrame
		self:UpdateVisuals()
	end)
	local camera = workspace.CurrentCamera
	self.State.SavedCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Custom
	local camAnchor = Instance.new("Part")
	camAnchor.Name = "DesyncCamAnchor"
	camAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
	camAnchor.Transparency = 1
	camAnchor.CanCollide = false
	camAnchor.CanTouch = false
	camAnchor.CanQuery = false
	camAnchor.Anchored = true
	camAnchor.CFrame = self.State.RealCFrame
	camAnchor.Parent = workspace
	self.State.CamAnchor = camAnchor
	camera.CameraSubject = camAnchor
	self.State.Connections.CamAnchor = RunService.RenderStepped:Connect(function()
		if camAnchor and camAnchor.Parent then
			camAnchor.CFrame = self.State.RealCFrame
		end
	end)
	local ui = self.State.UI.MainFrame
	ui.Content.DesyncToggle.Text = "[ DEACTIVATE ]"
	ui.Content.DesyncToggle.BackgroundColor3 = Color3.fromRGB(80, 10, 10)
	ui.TitleBar.StatusBadge.Text = "[ONLINE]"
	ui.TitleBar.StatusBadge.TextColor3 = Color3.fromRGB(0, 255, 100)
	self:UpdateDisplay()
end
function CFrameDesync:DeactivateDesync()
	self.State.DesyncActive = false
	for _, conn in pairs(self.State.Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(self.State.Connections)
	if self.State.FakeCharacter then
		self.State.FakeCharacter:Destroy()
		self.State.FakeCharacter = nil
		self.State.GhostHighlight = nil
	end
	local camera = workspace.CurrentCamera
	local char, hrp = getChar()
	if hrp then
		camera.CameraSubject = hrp
	elseif char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			camera.CameraSubject = hum
		end
	end
	if self.State.CamAnchor then
		self.State.CamAnchor:Destroy()
		self.State.CamAnchor = nil
	end
	if not self.State.UI then
		return
	end
	local ui = self.State.UI.MainFrame
	ui.Content.DesyncToggle.Text = "[ ACTIVATE ]"
	ui.Content.DesyncToggle.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
	ui.TitleBar.StatusBadge.Text = "[OFFLINE]"
	ui.TitleBar.StatusBadge.TextColor3 = Color3.fromRGB(100, 100, 110)
	self:UpdateDisplay()
end
function CFrameDesync:ToggleDesync()
	if self.State.DesyncActive then
		self:DeactivateDesync()
	else
		self:ActivateDesync()
	end
end
function CFrameDesync:CreateFakeCharacter()
	local char = LocalPlayer.Character
	if not char then
		return
	end
	local fake = Instance.new("Model")
	fake.Name = "Desync_Visualizer"
	for _, part in pairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local p = part:Clone()
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.CastShadow = false
			p.Material = Enum.Material.Neon
			p.Transparency = isPinned(self, part.Name) and 0.45 or 0.2
			p.Color = isPinned(self, part.Name) and self.Config.PinnedColor or self.Config.HighlightColor
			p.Parent = fake
			for _, child in pairs(p:GetChildren()) do
				if not child:IsA("SpecialMesh") then
					child:Destroy()
				end
			end
		end
	end
	local hl = Instance.new("Highlight", fake)
	hl.FillColor = self.Config.HighlightColor
	hl.OutlineColor = Color3.new(1, 1, 1)
	hl.FillTransparency = 0.4
	hl.OutlineTransparency = 0.0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	self.State.GhostHighlight = hl
	fake.Parent = workspace
	self.State.FakeCharacter = fake
end
function CFrameDesync:_refreshFakeCharacterColors()
	if not self.State.FakeCharacter then
		return
	end
	for _, part in pairs(self.State.FakeCharacter:GetChildren()) do
		if part:IsA("BasePart") then
			local pinned = isPinned(self, part.Name)
			part.Color = pinned and self.Config.PinnedColor or self.Config.HighlightColor
			part.Transparency = pinned and 0.45 or 0.2
		end
	end
	if self.State.GhostHighlight then
		self.State.GhostHighlight.FillColor = self.Config.HighlightColor
	end
end
function CFrameDesync:UpdateVisuals()
	local char = LocalPlayer.Character
	if not char or not self.State.FakeCharacter then
		return
	end
	local realHRP = char:FindFirstChild("HumanoidRootPart")
	if not realHRP then
		return
	end
	local rotOnly = CFrame.fromMatrix(
		Vector3.zero,
		self.State.VisualOffset.RightVector,
		self.State.VisualOffset.UpVector,
		-self.State.VisualOffset.LookVector
	)
	local spoof = CFrame.new(self.State.RealCFrame.Position + self.State.VisualOffset.Position)
		* CFrame.fromMatrix(
			Vector3.zero,
			self.State.RealCFrame.RightVector,
			self.State.RealCFrame.UpVector,
			-self.State.RealCFrame.LookVector
		)
		* rotOnly
	for _, part in pairs(self.State.FakeCharacter:GetChildren()) do
		if part:IsA("BasePart") then
			local realPart = char:FindFirstChild(part.Name)
			if realPart then
				local relative = realHRP.CFrame:Inverse() * realPart.CFrame
				part.CFrame = isPinned(self, part.Name) and (self.State.RealCFrame * relative) or (spoof * relative)
			end
		end
	end
end
function CFrameDesync:AdjustOffset(vec)
	local inc = self.State.Increment
	if self.State.Mode == "position" then
		local cur = self.State.VisualOffset.Position
		self.State.VisualOffset = CFrame.new(cur + vec * inc)
	else
		local r = vec * math.rad(inc * 5)
		self.State.VisualOffset = self.State.VisualOffset * CFrame.Angles(r.X, r.Y, r.Z)
	end
	self:UpdateDisplay()
end
function CFrameDesync:UpdateDisplay()
	if not self.State.UI then
		return
	end
	local info = self.State.UI.MainFrame.Content.InfoBox
	if not info then
		return
	end
	if not self.State.DesyncActive then
		info.Text = "STATUS  : INACTIVE\nAWAITING ACTIVATION"
		return
	end
	local pinnedCount = 0
	for _, v in pairs(self.State.PinnedParts) do
		if v then
			pinnedCount += 1
		end
	end
	local pos = self.State.VisualOffset.Position
	local rx, ry, rz = self.State.VisualOffset:ToEulerAnglesXYZ()
	info.Text = string.format(
		"STATUS  : DESYNCED\nPINNED  : %d part(s)\n\nOFFSET POS\n  X: %+.2f  Y: %+.2f  Z: %+.2f\n\nOFFSET ROT\n  X: %+.1f°  Y: %+.1f°  Z: %+.1f°",
		pinnedCount,
		pos.X,
		pos.Y,
		pos.Z,
		math.deg(rx),
		math.deg(ry),
		math.deg(rz)
	)
end
local TERM = {
	BG = Color3.fromRGB(10, 10, 13),
	BG2 = Color3.fromRGB(15, 15, 20),
	BG3 = Color3.fromRGB(20, 20, 28),
	BORDER = Color3.fromRGB(45, 45, 60),
	ACCENT = Color3.fromRGB(255, 0, 200),
	ACCENT2 = Color3.fromRGB(0, 220, 255),
	GREEN = Color3.fromRGB(0, 220, 80),
	RED_DIM = Color3.fromRGB(80, 10, 10),
	FG = Color3.fromRGB(200, 200, 210),
	FG_DIM = Color3.fromRGB(100, 100, 115),
	FG_MUT = Color3.fromRGB(55, 55, 68),
	AX = {
		Color3.fromRGB(180, 50, 50),
		Color3.fromRGB(110, 25, 25),
		Color3.fromRGB(50, 165, 50),
		Color3.fromRGB(25, 100, 25),
		Color3.fromRGB(50, 80, 200),
		Color3.fromRGB(25, 40, 120),
	},
}
function CFrameDesync:_createUI()
	local existing = CoreGui:FindFirstChild("CFrameDesync_SA")
	if existing then
		existing:Destroy()
	end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CFrameDesync_SA"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.DisplayOrder = 9999
	self.State.UI = screenGui
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.fromOffset(280, 520)
	mainFrame.Position = UDim2.new(1, -292, 0.5, -260)
	mainFrame.BackgroundColor3 = TERM.BG
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = false
	mainFrame.Parent = screenGui
	local outerStroke = Instance.new("UIStroke", mainFrame)
	outerStroke.Color = TERM.ACCENT
	outerStroke.Thickness = 1
	outerStroke.LineJoinMode = Enum.LineJoinMode.Miter
	local titleBar = Instance.new("Frame", mainFrame)
	titleBar.Name = "TitleBar"
	titleBar.Size = UDim2.new(1, 0, 0, 20)
	titleBar.BackgroundColor3 = TERM.BG2
	titleBar.BorderSizePixel = 0
	local titleBarBorder = Instance.new("UIStroke", titleBar)
	titleBarBorder.Color = TERM.BORDER
	titleBarBorder.Thickness = 1
	titleBarBorder.LineJoinMode = Enum.LineJoinMode.Miter
	local winChrome = Instance.new("TextLabel", titleBar)
	winChrome.Size = UDim2.new(0, 18, 1, 0)
	winChrome.Position = UDim2.fromOffset(0, 0)
	winChrome.BackgroundTransparency = 1
	winChrome.Text = " >"
	winChrome.TextColor3 = TERM.ACCENT
	winChrome.Font = Enum.Font.Code
	winChrome.TextSize = 10
	winChrome.TextXAlignment = Enum.TextXAlignment.Left
	local titleText = Instance.new("TextLabel", titleBar)
	titleText.Size = UDim2.new(1, -130, 1, 0)
	titleText.Position = UDim2.fromOffset(18, 0)
	titleText.BackgroundTransparency = 1
	titleText.Text = "cframedesync v2"
	titleText.TextColor3 = TERM.FG_DIM
	titleText.Font = Enum.Font.Code
	titleText.TextSize = 10
	titleText.TextXAlignment = Enum.TextXAlignment.Left
	local statusBadge = Instance.new("TextLabel", titleBar)
	statusBadge.Name = "StatusBadge"
	statusBadge.Size = UDim2.fromOffset(70, 14)
	statusBadge.Position = UDim2.new(1, -74, 0.5, -7)
	statusBadge.BackgroundColor3 = TERM.BG3
	statusBadge.BorderSizePixel = 0
	statusBadge.Text = "[OFFLINE]"
	statusBadge.TextColor3 = TERM.FG_MUT
	statusBadge.Font = Enum.Font.Code
	statusBadge.TextSize = 9
	local sbStroke = Instance.new("UIStroke", statusBadge)
	sbStroke.Color = TERM.FG_MUT
	sbStroke.Thickness = 1
	sbStroke.LineJoinMode = Enum.LineJoinMode.Miter
	local dragging, dragStart, startPos
	titleBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = inp.Position
			startPos = mainFrame.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - dragStart
			mainFrame.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	titleBar.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	local scroll = Instance.new("ScrollingFrame", mainFrame)
	scroll.Name = "Content"
	scroll.Size = UDim2.new(1, -2, 1, -22)
	scroll.Position = UDim2.new(0, 1, 0, 21)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = TERM.ACCENT
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0, 0)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	local function sectionDiv(labelText, order)
		local row = Instance.new("Frame", scroll)
		row.LayoutOrder = order
		row.Size = UDim2.new(1, 0, 0, 15)
		row.BackgroundColor3 = TERM.BG2
		row.BorderSizePixel = 0
		local divStroke = Instance.new("UIStroke", row)
		divStroke.Color = TERM.BORDER
		divStroke.Thickness = 1
		divStroke.LineJoinMode = Enum.LineJoinMode.Miter
		local lbl = Instance.new("TextLabel", row)
		lbl.Size = UDim2.new(1, -8, 1, 0)
		lbl.Position = UDim2.fromOffset(6, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = "── " .. labelText .. " "
		lbl.TextColor3 = TERM.FG_DIM
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 9
		lbl.TextXAlignment = Enum.TextXAlignment.Left
	end
	local function padFrame(order, height)
		local f = Instance.new("Frame", scroll)
		f.LayoutOrder = order
		f.Size = UDim2.new(1, 0, 0, height)
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		return f
	end
	local function termBtn(parent, text, bgColor, textColor, stroke, strokeColor)
		local b = Instance.new("TextButton", parent)
		b.Size = UDim2.new(1, 0, 1, 0)
		b.BackgroundColor3 = bgColor
		b.BorderSizePixel = 0
		b.Text = text
		b.TextColor3 = textColor or TERM.FG
		b.Font = Enum.Font.Code
		b.TextSize = 10
		if stroke then
			local s = Instance.new("UIStroke", b)
			s.Color = strokeColor or TERM.BORDER
			s.Thickness = 1
			s.LineJoinMode = Enum.LineJoinMode.Miter
		end
		return b
	end
	local togWrap = padFrame(10, 28)
	local togInner = Instance.new("Frame", togWrap)
	togInner.Size = UDim2.new(1, -12, 1, -6)
	togInner.Position = UDim2.fromOffset(6, 3)
	togInner.BackgroundTransparency = 1
	togInner.BorderSizePixel = 0
	local desyncToggle = termBtn(togInner, "[ ACTIVATE ]", TERM.BG2, TERM.FG, true, TERM.ACCENT)
	desyncToggle.Name = "DesyncToggle"
	desyncToggle.MouseButton1Click:Connect(function()
		self:ToggleDesync()
	end)
	sectionDiv("MANIPULATION MODE", 20)
	local modeWrap = padFrame(21, 26)
	local modeInner = Instance.new("Frame", modeWrap)
	modeInner.Size = UDim2.new(1, -12, 1, -6)
	modeInner.Position = UDim2.fromOffset(6, 3)
	modeInner.BackgroundTransparency = 1
	modeInner.BorderSizePixel = 0
	local modeLayout = Instance.new("UIListLayout", modeInner)
	modeLayout.FillDirection = Enum.FillDirection.Horizontal
	modeLayout.Padding = UDim.new(0, 4)
	local modeButtons = {}
	for _, modeOpt in ipairs({ "POSITION", "ROTATION" }) do
		local isActive = modeOpt:lower() == self.State.Mode
		local mb = Instance.new("TextButton", modeInner)
		mb.Size = UDim2.new(0.5, -2, 1, 0)
		mb.BackgroundColor3 = isActive and TERM.ACCENT or TERM.BG2
		mb.BorderSizePixel = 0
		mb.Text = modeOpt
		mb.TextColor3 = isActive and TERM.BG or TERM.FG_DIM
		mb.Font = Enum.Font.Code
		mb.TextSize = 10
		local ms = Instance.new("UIStroke", mb)
		ms.Color = isActive and TERM.ACCENT or TERM.BORDER
		ms.Thickness = 1
		ms.LineJoinMode = Enum.LineJoinMode.Miter
		modeButtons[modeOpt:lower()] = { btn = mb, stroke = ms }
		mb.MouseButton1Click:Connect(function()
			self.State.Mode = modeOpt:lower()
			for m, tbl in pairs(modeButtons) do
				local active = m == self.State.Mode
				tbl.btn.BackgroundColor3 = active and TERM.ACCENT or TERM.BG2
				tbl.btn.TextColor3 = active and TERM.BG or TERM.FG_DIM
				tbl.stroke.Color = active and TERM.ACCENT or TERM.BORDER
			end
		end)
	end
	sectionDiv("INCREMENT", 30)
	local incWrap = padFrame(31, 26)
	local incBox = Instance.new("TextBox", incWrap)
	incBox.Size = UDim2.new(1, -12, 1, -6)
	incBox.Position = UDim2.fromOffset(6, 3)
	incBox.BackgroundColor3 = TERM.BG3
	incBox.BorderSizePixel = 0
	incBox.Text = "1"
	incBox.TextColor3 = TERM.FG
	incBox.Font = Enum.Font.Code
	incBox.TextSize = 10
	incBox.PlaceholderText = "enter increment..."
	incBox.PlaceholderColor3 = TERM.FG_MUT
	local incStroke = Instance.new("UIStroke", incBox)
	incStroke.Color = TERM.BORDER
	incStroke.Thickness = 1
	incStroke.LineJoinMode = Enum.LineJoinMode.Miter
	incBox.FocusLost:Connect(function()
		local v = tonumber(incBox.Text)
		if v and v > 0 then
			self.State.Increment = v
		else
			incBox.Text = tostring(self.State.Increment)
		end
	end)
	sectionDiv("OFFSET CONTROLS", 40)
	local gridWrap = padFrame(41, 66)
	local axGrid = Instance.new("Frame", gridWrap)
	axGrid.Size = UDim2.new(1, -12, 1, -6)
	axGrid.Position = UDim2.fromOffset(6, 3)
	axGrid.BackgroundTransparency = 1
	axGrid.BorderSizePixel = 0
	local AXES = {
		{ t = "+X", o = Vector3.new(1, 0, 0) },
		{ t = "-X", o = Vector3.new(-1, 0, 0) },
		{ t = "+Y", o = Vector3.new(0, 1, 0) },
		{ t = "-Y", o = Vector3.new(0, -1, 0) },
		{ t = "+Z", o = Vector3.new(0, 0, 1) },
		{ t = "-Z", o = Vector3.new(0, 0, -1) },
	}
	local CELL_W = math.floor((280 - 12 - 8) / 3)
	local CELL_H = 30
	for i, ax in ipairs(AXES) do
		local col = (i - 1) % 3
		local row = math.floor((i - 1) / 3)
		local btn = Instance.new("TextButton", axGrid)
		btn.Size = UDim2.fromOffset(CELL_W - 4, CELL_H - 4)
		btn.Position = UDim2.fromOffset(col * CELL_W, row * (CELL_H + 2))
		btn.BackgroundColor3 = TERM.AX[i]
		btn.BorderSizePixel = 0
		btn.Text = ax.t
		btn.TextColor3 = TERM.FG
		btn.Font = Enum.Font.Code
		btn.TextSize = 11
		local bs = Instance.new("UIStroke", btn)
		bs.Color = Color3.new(0, 0, 0)
		bs.Thickness = 1
		bs.LineJoinMode = Enum.LineJoinMode.Miter
		local vec = ax.o
		btn.MouseButton1Click:Connect(function()
			self:AdjustOffset(vec)
		end)
	end
	local resetWrap = padFrame(42, 26)
	local resetBtn = termBtn(
		Instance.new("Frame", resetWrap),
		"[ RESET OFFSET ]",
		TERM.BG2,
		TERM.FG_DIM,
		true,
		Color3.fromRGB(100, 30, 30)
	)
	resetBtn.Parent.Size = UDim2.new(1, -12, 1, -6)
	resetBtn.Parent.Position = UDim2.fromOffset(6, 3)
	resetBtn.Parent.BackgroundTransparency = 1
	resetBtn.Parent.BorderSizePixel = 0
	resetBtn.Size = UDim2.new(1, 0, 1, 0)
	resetBtn.MouseButton1Click:Connect(function()
		self.State.VisualOffset = CFrame.new()
		self:UpdateDisplay()
	end)
	sectionDiv("PART PIN  [cyan=pinned → stays at real pos]", 60)
	local pinButtons = {}
	for gi, group in ipairs(PART_GROUPS) do
		local rowWrap = padFrame(60 + gi, 22)
		local rowInner = Instance.new("Frame", rowWrap)
		rowInner.Size = UDim2.new(1, -12, 1, -4)
		rowInner.Position = UDim2.fromOffset(6, 2)
		rowInner.BackgroundTransparency = 1
		rowInner.BorderSizePixel = 0
		local lbl = Instance.new("TextLabel", rowInner)
		lbl.Size = UDim2.new(0, 80, 1, 0)
		lbl.Position = UDim2.fromOffset(0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = group.label
		lbl.TextColor3 = TERM.FG_DIM
		lbl.Font = Enum.Font.Code
		lbl.TextSize = 9
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		local pb = Instance.new("TextButton", rowInner)
		pb.Size = UDim2.new(1, -84, 1, 0)
		pb.Position = UDim2.fromOffset(82, 0)
		pb.BackgroundColor3 = TERM.BG2
		pb.BorderSizePixel = 0
		pb.Text = "FREE"
		pb.TextColor3 = TERM.FG_MUT
		pb.Font = Enum.Font.Code
		pb.TextSize = 9
		local pbs = Instance.new("UIStroke", pb)
		pbs.Color = TERM.BORDER
		pbs.Thickness = 1
		pbs.LineJoinMode = Enum.LineJoinMode.Miter
		pinButtons[gi] = { btn = pb, stroke = pbs, group = group }
		local function refreshPin(pinned)
			if pinned then
				pb.BackgroundColor3 = TERM.ACCENT2
				pb.TextColor3 = TERM.BG
				pb.Text = "PINNED"
				pbs.Color = TERM.ACCENT2
			else
				pb.BackgroundColor3 = TERM.BG2
				pb.TextColor3 = TERM.FG_MUT
				pb.Text = "FREE"
				pbs.Color = TERM.BORDER
			end
		end
		local function groupPinned()
			for _, p in ipairs(group.parts) do
				if not self.State.PinnedParts[p] then
					return false
				end
			end
			return true
		end
		refreshPin(groupPinned())
		pb.MouseButton1Click:Connect(function()
			local now = groupPinned()
			for _, p in ipairs(group.parts) do
				self.State.PinnedParts[p] = not now
			end
			refreshPin(not now)
			if self.State.FakeCharacter then
				self:_refreshFakeCharacterColors()
			end
		end)
	end
	sectionDiv("QUICK PRESETS", 80)
	local presetWrap = padFrame(81, 26)
	local presetInner = Instance.new("Frame", presetWrap)
	presetInner.Size = UDim2.new(1, -12, 1, -6)
	presetInner.Position = UDim2.fromOffset(6, 3)
	presetInner.BackgroundTransparency = 1
	presetInner.BorderSizePixel = 0
	local presetLayout = Instance.new("UIListLayout", presetInner)
	presetLayout.FillDirection = Enum.FillDirection.Horizontal
	presetLayout.Padding = UDim.new(0, 4)
	local PRESETS = {
		{ label = "PIN ARMS", pinned = { ["LEFT ARM"] = true, ["RIGHT ARM"] = true } },
		{ label = "PIN LEGS", pinned = { ["LEFT LEG"] = true, ["RIGHT LEG"] = true } },
		{ label = "ALL FREE", pinned = {} },
		{
			label = "ALL PIN",
			pinned = {
				["HEAD"] = true,
				["TORSO"] = true,
				["LEFT ARM"] = true,
				["RIGHT ARM"] = true,
				["LEFT LEG"] = true,
				["RIGHT LEG"] = true,
			},
		},
	}
	for _, preset in ipairs(PRESETS) do
		local pb = Instance.new("TextButton", presetInner)
		pb.Size = UDim2.new(0.25, -3, 1, 0)
		pb.BackgroundColor3 = TERM.BG2
		pb.BorderSizePixel = 0
		pb.Text = preset.label
		pb.TextColor3 = TERM.FG_DIM
		pb.Font = Enum.Font.Code
		pb.TextSize = 8
		local ps = Instance.new("UIStroke", pb)
		ps.Color = TERM.BORDER
		ps.Thickness = 1
		ps.LineJoinMode = Enum.LineJoinMode.Miter
		local cap = preset.pinned
		pb.MouseButton1Click:Connect(function()
			self.State.PinnedParts = {}
			for _, group in ipairs(PART_GROUPS) do
				for _, p in ipairs(group.parts) do
					self.State.PinnedParts[p] = cap[group.label] or false
				end
			end
			for _, info in ipairs(pinButtons) do
				local all = true
				for _, p in ipairs(info.group.parts) do
					if not self.State.PinnedParts[p] then
						all = false
						break
					end
				end
				if all then
					info.btn.BackgroundColor3 = TERM.ACCENT2
					info.btn.TextColor3 = TERM.BG
					info.btn.Text = "PINNED"
					info.stroke.Color = TERM.ACCENT2
				else
					info.btn.BackgroundColor3 = TERM.BG2
					info.btn.TextColor3 = TERM.FG_MUT
					info.btn.Text = "FREE"
					info.stroke.Color = TERM.BORDER
				end
			end
			if self.State.FakeCharacter then
				self:_refreshFakeCharacterColors()
			end
		end)
	end
	sectionDiv("LIVE STATUS", 90)
	local infoWrap = padFrame(91, 90)
	local infoBox = Instance.new("TextLabel", infoWrap)
	infoBox.Name = "InfoBox"
	infoBox.Size = UDim2.new(1, -12, 1, -6)
	infoBox.Position = UDim2.fromOffset(6, 3)
	infoBox.BackgroundColor3 = TERM.BG3
	infoBox.BorderSizePixel = 0
	infoBox.Font = Enum.Font.Code
	infoBox.Text = "STATUS  : INACTIVE\nAWAITING ACTIVATION"
	infoBox.TextColor3 = TERM.ACCENT
	infoBox.TextSize = 9
	infoBox.TextXAlignment = Enum.TextXAlignment.Left
	infoBox.TextYAlignment = Enum.TextYAlignment.Top
	infoBox.TextWrapped = true
	local ibStroke = Instance.new("UIStroke", infoBox)
	ibStroke.Color = TERM.BORDER
	ibStroke.Thickness = 1
	ibStroke.LineJoinMode = Enum.LineJoinMode.Miter
	local ibPad = Instance.new("UIPadding", infoBox)
	ibPad.PaddingLeft = UDim.new(0, 5)
	ibPad.PaddingTop = UDim.new(0, 4)
	ibPad.PaddingBottom = UDim.new(0, 4)
	local spacer = padFrame(99, 4)
	spacer.BackgroundTransparency = 1
	desyncToggle.Parent = scroll
	desyncToggle.LayoutOrder = 10
	togWrap:Destroy()
	screenGui.Parent = CoreGui
end
function CFrameDesync:Enable()
	if self.State.IsEnabled then
		return
	end
	self.State.IsEnabled = true
	self:_createUI()
end
function CFrameDesync:Disable()
	self:DeactivateDesync()
	if self.State.UI then
		self.State.UI:Destroy()
		self.State.UI = nil
	end
	self.State.IsEnabled = false
end
function CFrameDesync:Toggle()
	if self.State.IsEnabled then
		self:Disable()
	else
		self:Enable()
	end
end
CFrameDesync:Enable()
return CFrameDesync
