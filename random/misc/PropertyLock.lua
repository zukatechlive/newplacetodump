local Services = {
	Players = game:GetService("Players"),
	RunService = game:GetService("RunService"),
	CoreGui = game:GetService("CoreGui"),
	TweenService = game:GetService("TweenService"),
	UserInputService = game:GetService("UserInputService"),
}

local LocalPlayer = Services.Players.LocalPlayer

local Editor = {
	State = {
		UI = nil,
		IsMinimized = false,
		ActiveOverrides = {},
		HeartbeatConnection = nil,
		RefreshConnection = nil,
		ToolConnections = {},
		CollapsedSections = {},
	},
	Config = {
		ToggleKey = Enum.KeyCode.RightAlt,
		WindowTitle = "<3",
		AccentColor = Color3.fromRGB(0, 220, 220),
		BackgroundColor = Color3.fromRGB(28, 26, 34),
		HeaderColor = Color3.fromRGB(18, 18, 28),
		ItemColor = Color3.fromRGB(42, 42, 54),
		ItemHoverColor = Color3.fromRGB(54, 54, 68),
		TextColor = Color3.fromRGB(230, 230, 240),
		DimTextColor = Color3.fromRGB(140, 140, 160),
		LockOnColor = Color3.fromRGB(30, 150, 90),
		LockOffColor = Color3.fromRGB(150, 45, 55),
		TrueColor = Color3.fromRGB(50, 130, 80),
		FalseColor = Color3.fromRGB(130, 50, 60),
		ErrorColor = Color3.fromRGB(200, 60, 60),
		Font = Enum.Font.Gotham,
		BoldFont = Enum.Font.GothamSemibold,
		MainSize = UDim2.new(0, 360, 0, 480),
		StepAmount = 1,
	},
}

local function makeKey(parentObject, name)
	return ("%s|%s"):format(tostring(parentObject), name)
end

local function flashRed(element, originalColor)
	element.BackgroundColor3 = Editor.Config.ErrorColor
	task.delay(0.4, function()
		if element and element.Parent then
			element.BackgroundColor3 = originalColor
		end
	end)
end

local function clampWindowToBounds(frame)
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	local pos = frame.AbsolutePosition
	local size = frame.AbsoluteSize
	local clampX = math.clamp(pos.X, 0, vp.X - size.X)
	local clampY = math.clamp(pos.Y, 0, vp.Y - size.Y)
	if clampX ~= pos.X or clampY ~= pos.Y then
		frame.Position = UDim2.new(0, clampX, 0, clampY)
	end
end

function Editor:StartHeartbeat()
	local S = self.State
	if S.HeartbeatConnection then
		return
	end
	S.HeartbeatConnection = Services.RunService.Heartbeat:Connect(function()
		self:ForceProperties()
	end)
end

function Editor:StopHeartbeatIfIdle()
	local S = self.State
	if next(S.ActiveOverrides) then
		return
	end
	if S.HeartbeatConnection then
		S.HeartbeatConnection:Disconnect()
		S.HeartbeatConnection = nil
	end
end

function Editor:ForceProperties()
	local S = self.State
	for key, data in pairs(S.ActiveOverrides) do
		if not data.ParentObject or not data.ParentObject.Parent then
			S.ActiveOverrides[key] = nil
			continue
		end
		local ok, err = pcall(function()
			if data.IsAttribute then
				if data.ParentObject:GetAttribute(data.PropName) ~= data.Value then
					data.ParentObject:SetAttribute(data.PropName, data.Value)
				end
			else
				if data.ParentObject[data.PropName] ~= data.Value then
					data.ParentObject[data.PropName] = data.Value
				end
			end
		end)
		if not ok then
			warn(("[Editor] ForceProperties failed for '%s': %s"):format(data.PropName, tostring(err)))
			S.ActiveOverrides[key] = nil
		end
	end
end

function Editor:UpdateStatusBar()
	local S = self.State
	if not (S.UI and S.UI.Parent) then
		return
	end
	local statusBar = S.UI.MainFrame:FindFirstChild("StatusBar")
	if not statusBar then
		return
	end
	local count = 0
	for _ in pairs(S.ActiveOverrides) do
		count += 1
	end
	statusBar.Text = count == 0 and ("  🔓  No locks active  │  %s to toggle"):format(self.Config.ToggleKey.Name)
		or ("  🔒  %d lock%s active  │  U = unlock all"):format(count, count == 1 and "" or "s")
	statusBar.TextColor3 = count == 0 and self.Config.DimTextColor or self.Config.AccentColor
end

function Editor:Populate()
	local S, C = self.State, self.Config
	local mainFrame = S.UI and S.UI:FindFirstChild("MainFrame")
	if not mainFrame then
		return
	end
	local propertyList = mainFrame:FindFirstChild("PropertyList")
	if not propertyList then
		return
	end

	for _, child in ipairs(propertyList:GetChildren()) do
		if child:IsA("UIListLayout") or child:IsA("UIPadding") then
			continue
		end
		child:Destroy()
	end

	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		self:UpdateStatusBar()
		return
	end

	local layoutCounter = 0

	local function addHeader(text)
		layoutCounter += 1
		local headerFrame = Instance.new("Frame", propertyList)
		headerFrame.Name = text .. "Header"
		headerFrame.Size = UDim2.new(1, 0, 0, 26)
		headerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		headerFrame.LayoutOrder = layoutCounter
		Instance.new("UICorner", headerFrame).CornerRadius = UDim.new(0, 6)

		local arrow = Instance.new("TextLabel", headerFrame)
		arrow.Name = "Arrow"
		arrow.Size = UDim2.new(0, 20, 1, 0)
		arrow.Position = UDim2.new(0, 4, 0, 0)
		arrow.BackgroundTransparency = 1
		arrow.Text = S.CollapsedSections[text] and "▶" or "▼"
		arrow.Font = C.BoldFont
		arrow.TextSize = 11
		arrow.TextColor3 = C.AccentColor

		local label = Instance.new("TextLabel", headerFrame)
		label.Size = UDim2.new(1, -28, 1, 0)
		label.Position = UDim2.new(0, 24, 0, 0)
		label.BackgroundTransparency = 1
		label.Text = text
		label.Font = C.BoldFont
		label.TextSize = 13
		label.TextColor3 = C.AccentColor
		label.TextXAlignment = Enum.TextXAlignment.Left

		local hitButton = Instance.new("TextButton", headerFrame)
		hitButton.Size = UDim2.new(1, 0, 1, 0)
		hitButton.BackgroundTransparency = 1
		hitButton.Text = ""
		hitButton.ZIndex = 5
		hitButton.MouseButton1Click:Connect(function()
			S.CollapsedSections[text] = not S.CollapsedSections[text]
			self:Populate()
		end)

		return text, layoutCounter
	end

	local function sectionCollapsed(sectionName)
		return S.CollapsedSections[sectionName] == true
	end

	local humanoidSection = "Humanoid"
	addHeader(humanoidSection)

	if not sectionCollapsed(humanoidSection) then
		local humanoidProps = { "WalkSpeed", "JumpPower", "JumpHeight", "HipHeight", "MaxHealth", "Health" }
		for _, propName in ipairs(humanoidProps) do
			local ok, value = pcall(function()
				return humanoid[propName]
			end)
			if ok and type(value) == "number" then
				layoutCounter += 1
				self:CreateNumberRow(propName, value, false, humanoid, layoutCounter)
			end
		end
	end

	local objectsToScan = {}
	if character then
		objectsToScan["Character"] = character
		objectsToScan["Humanoid"] = humanoid
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			objectsToScan["HumanoidRootPart"] = rootPart
		end
		for _, desc in ipairs(character:GetDescendants()) do
			local uname = ("%s (%s)"):format(desc.Name, desc.ClassName)
			if not objectsToScan[uname] and (desc:IsA("BasePart") or desc:IsA("Tool")) then
				objectsToScan[uname] = desc
			end
		end
	end

	local sortedNames = {}
	for name in pairs(objectsToScan) do
		table.insert(sortedNames, name)
	end
	table.sort(sortedNames)

	for _, objectName in ipairs(sortedNames) do
		local parentObject = objectsToScan[objectName]
		if not parentObject or not parentObject.Parent then
			continue
		end

		local attributes = parentObject:GetAttributes()
		if not next(attributes) then
			continue
		end

		local numericAttrs, boolAttrs = {}, {}
		for aname, aval in pairs(attributes) do
			if type(aval) == "number" then
				table.insert(numericAttrs, { Name = aname, Value = aval })
			elseif type(aval) == "boolean" then
				table.insert(boolAttrs, { Name = aname, Value = aval })
			end
		end
		if not next(numericAttrs) and not next(boolAttrs) then
			continue
		end

		table.sort(numericAttrs, function(a, b)
			return a.Name < b.Name
		end)
		table.sort(boolAttrs, function(a, b)
			return a.Name < b.Name
		end)

		local sectionName = objectName .. " Attributes"
		addHeader(sectionName)

		if not sectionCollapsed(sectionName) then
			for _, data in ipairs(numericAttrs) do
				layoutCounter += 1
				self:CreateNumberRow(data.Name, data.Value, true, parentObject, layoutCounter)
			end
			for _, data in ipairs(boolAttrs) do
				layoutCounter += 1
				self:CreateBooleanRow(data.Name, data.Value, true, parentObject, layoutCounter)
			end
		end
	end

	local pad = Instance.new("Frame", propertyList)
	pad.Name, pad.Size, pad.BackgroundTransparency, pad.LayoutOrder =
		"_BottomPad", UDim2.new(1, 0, 0, 8), 1, layoutCounter + 1

	self:UpdateStatusBar()
end

function Editor:CreateNumberRow(name, value, isAttribute, parentObject, layoutOrder)
	local C, S = self.Config, self.State
	local list = S.UI.MainFrame.PropertyList
	local key = makeKey(parentObject, name)

	local frame = Instance.new("Frame", list)
	frame.Name = key .. "Row"
	frame.Size = UDim2.new(1, 0, 0, 32)
	frame.BackgroundColor3 = C.ItemColor
	frame.LayoutOrder = layoutOrder
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

	local nameLabel = Instance.new("TextLabel", frame)
	nameLabel.Size = UDim2.new(0.38, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 6, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.Font = C.Font
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = C.TextColor
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local minusBtn = Instance.new("TextButton", frame)
	minusBtn.Size = UDim2.new(0, 22, 0, 22)
	minusBtn.Position = UDim2.new(0.38, 2, 0.5, 0)
	minusBtn.AnchorPoint = Vector2.new(0, 0.5)
	minusBtn.BackgroundColor3 = C.HeaderColor
	minusBtn.Text = "−"
	minusBtn.Font = C.BoldFont
	minusBtn.TextSize = 16
	minusBtn.TextColor3 = C.TextColor
	Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 4)

	local valueBox = Instance.new("TextBox", frame)
	valueBox.Size = UDim2.new(0.26, 0, 0, 22)
	valueBox.Position = UDim2.new(0.38, 26, 0.5, 0)
	valueBox.AnchorPoint = Vector2.new(0, 0.5)
	valueBox.BackgroundColor3 = C.HeaderColor
	valueBox.Font = C.Font
	valueBox.TextSize = 13
	valueBox.TextColor3 = Color3.new(1, 1, 1)
	valueBox.Text = tostring(value)
	valueBox.ClearTextOnFocus = false
	valueBox.TextTruncate = Enum.TextTruncate.AtEnd
	Instance.new("UICorner", valueBox).CornerRadius = UDim.new(0, 4)

	local plusBtn = Instance.new("TextButton", frame)
	local plusX = 0.38 + 0.26 + (26 / 360)
	plusBtn.Size = UDim2.new(0, 22, 0, 22)
	plusBtn.Position = UDim2.new(0, 0, 0.5, 0)
	plusBtn.BackgroundColor3 = C.HeaderColor
	plusBtn.Text = "+"
	plusBtn.Font = C.BoldFont
	plusBtn.TextSize = 16
	plusBtn.TextColor3 = C.TextColor
	Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 4)

	local lockBtn = Instance.new("TextButton", frame)
	lockBtn.Name = "LockButton"
	lockBtn.Size = UDim2.new(0, 60, 0, 22)
	lockBtn.Font = C.BoldFont
	lockBtn.TextSize = 12
	lockBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 4)

	local ROW_W = 360
	local LOCK_W = 60
	local STEP_W = 22
	local GAP = 4
	local PAD_R = 8

	lockBtn.Position = UDim2.new(1, -(PAD_R + LOCK_W), 0.5, 0)
	lockBtn.AnchorPoint = Vector2.new(0, 0.5)

	plusBtn.Position = UDim2.new(1, -(PAD_R + LOCK_W + GAP + STEP_W), 0.5, 0)
	plusBtn.AnchorPoint = Vector2.new(0, 0.5)

	valueBox.Size = UDim2.new(0, 0, 0, 22)
	local leftEdge = 0.38 * ROW_W + STEP_W + GAP + 6
	local rightEdge = ROW_W - (PAD_R + LOCK_W + GAP + STEP_W + GAP)
	valueBox.Size = UDim2.new(0, rightEdge - leftEdge, 0, 22)
	valueBox.Position = UDim2.new(0, leftEdge, 0.5, 0)
	valueBox.AnchorPoint = Vector2.new(0, 0.5)

	minusBtn.Position = UDim2.new(0, 0.38 * ROW_W + 6, 0.5, 0)
	minusBtn.AnchorPoint = Vector2.new(0, 0.5)

	local function getLiveValue()
		if not (parentObject and parentObject.Parent) then
			return nil
		end
		local ok, v = pcall(function()
			return isAttribute and parentObject:GetAttribute(name) or parentObject[name]
		end)
		return ok and v or nil
	end

	local function applyValue(newVal)
		if not (parentObject and parentObject.Parent) then
			return false
		end
		local ok, err2 = pcall(function()
			if isAttribute then
				parentObject:SetAttribute(name, newVal)
			else
				parentObject[name] = newVal
			end
		end)
		if not ok then
			warn(("[Editor] applyValue failed for '%s': %s"):format(name, tostring(err2)))
		end
		return ok
	end

	local function refreshLockVisual()
		if S.ActiveOverrides[key] then
			lockBtn.BackgroundColor3 = C.LockOnColor
			lockBtn.Text = "LOCKED"
		else
			lockBtn.BackgroundColor3 = C.LockOffColor
			lockBtn.Text = "LOCK"
		end
	end
	refreshLockVisual()

	local function step(delta)
		local cur = tonumber(valueBox.Text) or getLiveValue() or 0
		local newVal = cur + delta
		valueBox.Text = tostring(newVal)
		applyValue(newVal)
		if S.ActiveOverrides[key] then
			S.ActiveOverrides[key].Value = newVal
		end
	end
	minusBtn.MouseButton1Click:Connect(function()
		step(-C.StepAmount)
	end)
	plusBtn.MouseButton1Click:Connect(function()
		step(C.StepAmount)
	end)

	valueBox.FocusLost:Connect(function(enterPressed)
		if not enterPressed then
			return
		end
		local newVal = tonumber(valueBox.Text)
		if not newVal then
			flashRed(valueBox, C.HeaderColor)
			valueBox.Text = tostring(getLiveValue() or 0)
			return
		end
		applyValue(newVal)
		if S.ActiveOverrides[key] then
			S.ActiveOverrides[key].Value = newVal
		end
		local live = getLiveValue()
		if live then
			valueBox.Text = tostring(live)
		end
	end)

	lockBtn.MouseButton1Click:Connect(function()
		local curVal = tonumber(valueBox.Text) or getLiveValue()
		if not curVal then
			flashRed(lockBtn, C.LockOffColor)
			return
		end
		if S.ActiveOverrides[key] then
			S.ActiveOverrides[key] = nil
			self:StopHeartbeatIfIdle()
		else
			S.ActiveOverrides[key] = {
				Value = curVal,
				IsAttribute = isAttribute,
				ParentObject = parentObject,
				PropName = name,
			}
			self:StartHeartbeat()
		end
		refreshLockVisual()
		self:UpdateStatusBar()
	end)

	local syncConn
	syncConn = Services.RunService.Heartbeat:Connect(function()
		if not (frame and frame.Parent) then
			syncConn:Disconnect()
			return
		end
		if valueBox:IsFocused() then
			return
		end
		if S.ActiveOverrides[key] then
			return
		end
		local live = getLiveValue()
		if live and tostring(live) ~= valueBox.Text then
			valueBox.Text = tostring(live)
		end
	end)

	frame.Destroying:Connect(function()
		syncConn:Disconnect()
	end)
end

function Editor:CreateBooleanRow(name, value, isAttribute, parentObject, layoutOrder)
	local C, S = self.Config, self.State
	local list = S.UI.MainFrame.PropertyList
	local key = makeKey(parentObject, name)

	local frame = Instance.new("Frame", list)
	frame.Name = key .. "BoolRow"
	frame.Size = UDim2.new(1, 0, 0, 32)
	frame.BackgroundColor3 = C.ItemColor
	frame.LayoutOrder = layoutOrder
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

	local nameLabel = Instance.new("TextLabel", frame)
	nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 6, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.Font = C.Font
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = C.TextColor
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local valueBtn = Instance.new("TextButton", frame)
	valueBtn.Size = UDim2.new(0, 70, 0, 22)
	valueBtn.Position = UDim2.new(1, -(8 + 60 + 4 + 70), 0.5, 0)
	valueBtn.AnchorPoint = Vector2.new(0, 0.5)
	valueBtn.Font = C.BoldFont
	valueBtn.TextSize = 12
	valueBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", valueBtn).CornerRadius = UDim.new(0, 4)

	local lockBtn = Instance.new("TextButton", frame)
	lockBtn.Name = "LockButton"
	lockBtn.Size = UDim2.new(0, 60, 0, 22)
	lockBtn.Position = UDim2.new(1, -68, 0.5, 0)
	lockBtn.AnchorPoint = Vector2.new(0, 0.5)
	lockBtn.Font = C.BoldFont
	lockBtn.TextSize = 12
	lockBtn.TextColor3 = Color3.new(1, 1, 1)
	Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 4)

	local currentValue = value

	local function updateValueBtn()
		valueBtn.Text = currentValue and "TRUE" or "FALSE"
		valueBtn.BackgroundColor3 = currentValue and C.TrueColor or C.FalseColor
	end

	local function refreshLockVisual()
		if S.ActiveOverrides[key] then
			lockBtn.BackgroundColor3 = C.LockOnColor
			lockBtn.Text = "LOCKED"
		else
			lockBtn.BackgroundColor3 = C.LockOffColor
			lockBtn.Text = "LOCK"
		end
	end

	updateValueBtn()
	refreshLockVisual()

	valueBtn.MouseButton1Click:Connect(function()
		currentValue = not currentValue
		updateValueBtn()
		if parentObject and parentObject.Parent then
			pcall(function()
				if isAttribute then
					parentObject:SetAttribute(name, currentValue)
				end
			end)
		end
		if S.ActiveOverrides[key] then
			S.ActiveOverrides[key].Value = currentValue
		end
	end)

	lockBtn.MouseButton1Click:Connect(function()
		if S.ActiveOverrides[key] then
			S.ActiveOverrides[key] = nil
			self:StopHeartbeatIfIdle()
		else
			S.ActiveOverrides[key] = {
				Value = currentValue,
				IsAttribute = isAttribute,
				ParentObject = parentObject,
				PropName = name,
			}
			self:StartHeartbeat()
		end
		refreshLockVisual()
		self:UpdateStatusBar()
	end)
end

function Editor:ToggleMinimize()
	local S, C = self.State, self.Config
	S.IsMinimized = not S.IsMinimized

	local mainFrame = S.UI.MainFrame
	local propertyList = mainFrame.PropertyList
	local minBtn = mainFrame.TitleRow:FindFirstChild("MinimizeButton")
	local statusBar = mainFrame:FindFirstChild("StatusBar")

	local targetH = S.IsMinimized and 34 or C.MainSize.Y.Offset
	local targetSize = UDim2.new(C.MainSize.X.Scale, C.MainSize.X.Offset, 0, targetH)
	local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	Services.TweenService:Create(mainFrame, tweenInfo, { Size = targetSize }):Play()
	propertyList.Visible = not S.IsMinimized
	if statusBar then
		statusBar.Visible = not S.IsMinimized
	end
	if minBtn then
		minBtn.Text = S.IsMinimized and "▲" or "▼"
	end
end

function Editor:CreateUI()
	if self.State.UI then
		return
	end
	local C, S = self.Config, self.State

	local old = Services.CoreGui:FindFirstChild("ZukaPropEditor")
	if old then
		old:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ZukaPropEditor"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = Services.CoreGui
	S.UI = screenGui

	local mainFrame = Instance.new("Frame", screenGui)
	mainFrame.Name = "MainFrame"
	mainFrame.Size = C.MainSize
	mainFrame.Position = UDim2.new(0.5, -C.MainSize.X.Offset / 2, 0.5, -C.MainSize.Y.Offset / 2)
	mainFrame.BackgroundColor3 = C.BackgroundColor
	mainFrame.Draggable = true
	mainFrame.Active = true
	mainFrame.ClipsDescendants = true
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

	local uiStroke = Instance.new("UIStroke", mainFrame)
	uiStroke.Color = C.AccentColor
	uiStroke.Thickness = 1.5
	uiStroke.Transparency = 0.35
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	local glowConn = Services.RunService.RenderStepped:Connect(function()
		if not (uiStroke and uiStroke.Parent) then
			return
		end
		local t = os.clock() * 3
		local s = math.sin(t)
		uiStroke.Thickness = 1.2 + s * 0.6
		uiStroke.Transparency = 0.3 + s * 0.25
	end)
	screenGui.Destroying:Connect(function()
		glowConn:Disconnect()
	end)

	mainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		clampWindowToBounds(mainFrame)
	end)

	local titleRow = Instance.new("Frame", mainFrame)
	titleRow.Name = "TitleRow"
	titleRow.Size = UDim2.new(1, 0, 0, 34)
	titleRow.BackgroundColor3 = C.HeaderColor
	titleRow.ZIndex = 3

	local titleLabel = Instance.new("TextLabel", titleRow)
	titleLabel.Size = UDim2.new(1, -130, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = C.WindowTitle
	titleLabel.Font = C.BoldFont
	titleLabel.TextSize = 14
	titleLabel.TextColor3 = C.TextColor
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	local function makeTitleBtn(name, text, rightOffset, color, onClick)
		local btn = Instance.new("TextButton", titleRow)
		btn.Name = name
		btn.Size = UDim2.new(0, 26, 0, 26)
		btn.Position = UDim2.new(1, rightOffset, 0.5, 0)
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.BackgroundColor3 = color
		btn.Text = text
		btn.Font = C.BoldFont
		btn.TextSize = 14
		btn.TextColor3 = Color3.new(1, 1, 1)
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
		btn.MouseButton1Click:Connect(onClick)
		return btn
	end

	makeTitleBtn("CloseButton", "✕", -6, Color3.fromRGB(160, 50, 55), function()
		screenGui.Enabled = false
	end)
	makeTitleBtn("UnlockAllButton", "U", -36, Color3.fromRGB(100, 100, 120), function()
		for k in pairs(S.ActiveOverrides) do
			S.ActiveOverrides[k] = nil
		end
		self:StopHeartbeatIfIdle()
		self:Populate()
	end)
	makeTitleBtn("RefreshButton", "R", -66, Color3.fromRGB(60, 110, 160), function()
		self:Populate()
	end)
	makeTitleBtn("MinimizeButton", "▼", -96, Color3.fromRGB(70, 70, 90), function()
		self:ToggleMinimize()
	end)

	local divider = Instance.new("Frame", mainFrame)
	divider.Name = "Divider"
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 0, 34)
	divider.BackgroundColor3 = C.AccentColor
	divider.BorderSizePixel = 0
	divider.BackgroundTransparency = 0.6

	local propertyList = Instance.new("ScrollingFrame", mainFrame)
	propertyList.Name = "PropertyList"
	propertyList.Size = UDim2.new(1, 0, 1, -70)
	propertyList.Position = UDim2.new(0, 0, 0, 35)
	propertyList.BackgroundTransparency = 1
	propertyList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	propertyList.ScrollBarImageColor3 = C.AccentColor
	propertyList.ScrollBarThickness = 4
	propertyList.BorderSizePixel = 0
	propertyList.ScrollingDirection = Enum.ScrollingDirection.Y

	local listLayout = Instance.new("UIListLayout", propertyList)
	listLayout.Padding = UDim.new(0, 3)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local uiPadding = Instance.new("UIPadding", propertyList)
	uiPadding.PaddingLeft = UDim.new(0, 6)
	uiPadding.PaddingRight = UDim.new(0, 6)
	uiPadding.PaddingTop = UDim.new(0, 4)

	local statusBar = Instance.new("TextLabel", mainFrame)
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(1, 0, 0, 24)
	statusBar.Position = UDim2.new(0, 0, 1, -24)
	statusBar.BackgroundColor3 = C.HeaderColor
	statusBar.Text = ""
	statusBar.Font = C.Font
	statusBar.TextSize = 11
	statusBar.TextColor3 = C.DimTextColor
	statusBar.TextXAlignment = Enum.TextXAlignment.Left
end

function Editor:OnCharacterAdded(character)
	for k, conn in pairs(self.State.ToolConnections) do
		conn:Disconnect()
		self.State.ToolConnections[k] = nil
	end

	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 10)
		if not humanoid then
			return
		end

		if self.State.UI and self.State.UI.Enabled then
			task.wait(0.5)
			self:Populate()
		end

		self.State.ToolConnections.ChildAdded = character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and self.State.UI and self.State.UI.Enabled then
				task.wait(0.1)
				self:Populate()
			end
		end)
		self.State.ToolConnections.ChildRemoved = character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and self.State.UI and self.State.UI.Enabled then
				self:Populate()
			end
		end)
	end)
end

function Editor:ToggleUI()
	if not self.State.UI then
		return
	end
	local S = self.State
	S.UI.Enabled = not S.UI.Enabled
	if S.UI.Enabled then
		self:Populate()
	end
end

function Editor:Init()
	self:CreateUI()
	self.State.UI.Enabled = false

	LocalPlayer.CharacterAdded:Connect(function(char)
		self:OnCharacterAdded(char)
	end)
	if LocalPlayer.Character then
		self:OnCharacterAdded(LocalPlayer.Character)
	end

	LocalPlayer.Chatted:Connect(function(msg)
		local lower = msg:lower()
		if lower == "/stats" or lower == "/editstats" or lower == "/props" then
			self:ToggleUI()
		end
	end)

	Services.UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == self.Config.ToggleKey then
			self:ToggleUI()
		end
	end)

	self:ToggleUI()
end

xpcall(function()
	Editor:Init()
end, function(err)
	warn("[ZukaPropEditor] Fatal error during init:", err, debug.traceback())
end)
