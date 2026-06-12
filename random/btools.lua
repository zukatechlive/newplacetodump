local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
assert(player, "[BuildTools] LocalPlayer not found!")

local THEME = {
	Background = Color3.fromRGB(22, 20, 28),
	BackgroundAlt = Color3.fromRGB(30, 28, 36),
	Accent = Color3.fromRGB(255, 105, 180),
	AccentDim = Color3.fromRGB(180, 60, 120),
	Title = Color3.fromRGB(255, 200, 220),
	Text = Color3.fromRGB(220, 215, 230),
	TextDim = Color3.fromRGB(140, 130, 155),
	Interactive = Color3.fromRGB(38, 34, 46),
	InteractiveHover = Color3.fromRGB(55, 48, 68),
	ActiveMode = Color3.fromRGB(255, 105, 180),
	ActiveModeText = Color3.fromRGB(22, 20, 28),
	Destructive = Color3.fromRGB(220, 65, 85),
	DestructiveHover = Color3.fromRGB(255, 80, 100),
	Success = Color3.fromRGB(80, 200, 130),
	Stroke = Color3.fromRGB(70, 55, 85),
}

local State = {
	isActive = false,
	currentMode = "select",
	currentPart = nil,
	selectedParts = {},
	history = {},
	saveHistory = {},

	isDragging = false,
	dragStart = nil,
	dragOffsets = {},

	ui = nil,
	highlight = nil,

	connections = {},
}

local function notify(title, text, duration)
	pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
		Title = title,
		Text = text,
		Duration = duration or 3,
	})
end

local function conn(signal, fn)
	local c = signal:Connect(fn)
	table.insert(State.connections, c)
	return c
end

local function trySet(obj, prop, val)
	local ok, err = pcall(function()
		obj[prop] = val
	end)
	if not ok then
		notify("BuildTools", "Protected: cannot set " .. prop, 2)
	end
	return ok
end

local function raycastFromCursor()
	local camera = workspace.CurrentCamera
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	local char = player.Character

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = char and { char } or {}

	local result = workspace:Raycast(ray.Origin, ray.Direction * 2048, params)
	if result then
		return result.Instance, result.Position
	end
	return nil, nil
end

local function resolveBasePart(inst)
	if not inst then
		return nil
	end
	if inst:IsA("BasePart") then
		return inst
	end
	local p = inst.Parent
	while p and p ~= workspace do
		if p:IsA("BasePart") then
			return p
		end
		p = p.Parent
	end
	return nil
end

local function isCharacterPart(part)
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and part:IsDescendantOf(plr.Character) then
			return true
		end
	end
	return false
end

local function pushHistory(entry)
	table.insert(State.history, entry)
	if #State.history > 64 then
		table.remove(State.history, 1)
	end
end

local function undoLast()
	local entry = table.remove(State.history)
	if not entry then
		notify("BuildTools", "Nothing to undo.", 2)
		return
	end

	if entry.type == "delete" then
		pcall(function()
			entry.part.Parent = entry.parent
		end)
		pcall(function()
			entry.part.CFrame = entry.cframe
		end)
		notify("BuildTools", "Restored '" .. entry.part.Name .. "'", 2)
	elseif entry.type == "anchor" then
		pcall(function()
			entry.part.Anchored = entry.before
		end)
		notify("BuildTools", "Reverted anchor on '" .. entry.part.Name .. "'", 2)
	elseif entry.type == "collide" then
		pcall(function()
			entry.part.CanCollide = entry.before
		end)
		notify("BuildTools", "Reverted CanCollide on '" .. entry.part.Name .. "'", 2)
	elseif entry.type == "move" then
		for _, data in ipairs(entry.parts) do
			pcall(function()
				data.part.CFrame = data.before
			end)
		end
		notify("BuildTools", "Reverted move", 2)
	end
end

local ModeHandlers = {}

ModeHandlers["select"] = function(part)
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		for i, p in ipairs(State.selectedParts) do
			if p == part then
				table.remove(State.selectedParts, i)
				return
			end
		end
		table.insert(State.selectedParts, part)
	else
		State.selectedParts = { part }
	end
end

ModeHandlers["move"] = function(part)
	if not UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		local alreadyIn = false
		for _, p in ipairs(State.selectedParts) do
			if p == part then
				alreadyIn = true
				break
			end
		end
		if not alreadyIn then
			State.selectedParts = { part }
		end
	else
		for i, p in ipairs(State.selectedParts) do
			if p == part then
				table.remove(State.selectedParts, i)
				return
			end
		end
		table.insert(State.selectedParts, part)
	end
end

ModeHandlers["delete"] = function(part)
	if isCharacterPart(part) then
		notify("BuildTools", "Cannot delete character parts.", 2)
		return
	end
	pushHistory({ type = "delete", part = part, parent = part.Parent, cframe = part.CFrame })
	table.insert(State.saveHistory, { name = part.Name, position = part.Position })
	pcall(function()
		part.Parent = nil
	end)
	for i, p in ipairs(State.selectedParts) do
		if p == part then
			table.remove(State.selectedParts, i)
			break
		end
	end
	notify("BuildTools", "Deleted '" .. part.Name .. "'", 2)
end

ModeHandlers["anchor"] = function(part)
	pushHistory({ type = "anchor", part = part, before = part.Anchored })
	local ok = trySet(part, "Anchored", not part.Anchored)
	if ok then
		notify("BuildTools", ("'%s' Anchored → %s"):format(part.Name, tostring(part.Anchored)), 2)
	end
end

ModeHandlers["collide"] = function(part)
	pushHistory({ type = "collide", part = part, before = part.CanCollide })
	local ok = trySet(part, "CanCollide", not part.CanCollide)
	if ok then
		notify("BuildTools", ("'%s' CanCollide → %s"):format(part.Name, tostring(part.CanCollide)), 2)
	end
end

ModeHandlers["group_model"] = function(_part)
	if #State.selectedParts == 0 then
		notify("BuildTools", "No parts selected.", 2)
		return
	end
	local model = Instance.new("Model")
	model.Name = "BuildGroup_" .. tostring(os.clock()):sub(-4)
	model.Parent = workspace
	for _, p in ipairs(State.selectedParts) do
		pcall(function()
			p.Parent = model
		end)
	end
	State.selectedParts = {}
	notify("BuildTools", "Grouped " .. #model:GetChildren() .. " parts as Model", 2)
end

ModeHandlers["group_folder"] = function(_part)
	if #State.selectedParts == 0 then
		notify("BuildTools", "No parts selected.", 2)
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "BuildGroup_" .. tostring(os.clock()):sub(-4)
	folder.Parent = workspace
	for _, p in ipairs(State.selectedParts) do
		pcall(function()
			p.Parent = folder
		end)
	end
	State.selectedParts = {}
	notify("BuildTools", "Grouped as Folder", 2)
end

local MODE_ORDER = {
	{ key = "select", label = "Select", color = nil },
	{ key = "move", label = "Move", color = nil },
	{ key = "delete", label = "Delete", color = "destructive" },
	{ key = "anchor", label = "Toggle Anchor", color = nil },
	{ key = "collide", label = "Toggle CanCollide", color = nil },
	{ key = "group_model", label = "Group → Model", color = nil },
	{ key = "group_folder", label = "Group → Folder", color = nil },
}

local function makeCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 6)
	return c
end

local function makeStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or THEME.Stroke
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	return s
end

local function makeDraggable(frame, handle)
	local dragging, dragStart, frameStart
	handle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			frameStart = frame.Position
		end
	end)
	handle.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	handle.InputChanged:Connect(function(input)
		if
			dragging
			and dragStart
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				frameStart.X.Scale,
				frameStart.X.Offset + delta.X,
				frameStart.Y.Scale,
				frameStart.Y.Offset + delta.Y
			)
		end
	end)
end

local function buildUI()
	local old = CoreGui:FindFirstChild("BuildToolsUI")
	if old then
		old:Destroy()
	end

	local ui = {}

	ui.ScreenGui = Instance.new("ScreenGui")
	ui.ScreenGui.Name = "BuildToolsUI"
	ui.ScreenGui.ResetOnSpawn = false
	ui.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ui.ScreenGui.Parent = CoreGui

	local panel = Instance.new("Frame", ui.ScreenGui)
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(268, 0)
	panel.AutomaticSize = Enum.AutomaticSize.Y
	panel.Position = UDim2.new(0.04, 0, 0.35, 0)
	panel.BackgroundColor3 = THEME.Background
	panel.ClipsDescendants = true
	makeCorner(panel, 10)
	makeStroke(panel, THEME.Accent, 1.5, 0.3)

	conn(RunService.Heartbeat, function()
		local s = panel:FindFirstChildWhichIsA("UIStroke")
		if s then
			local t = os.clock()
			s.Transparency = 0.25 + math.sin(t * 3) * 0.18
		end
	end)

	local padding = Instance.new("UIPadding", panel)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 10)

	local listLayout = Instance.new("UIListLayout", panel)
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local header = Instance.new("Frame", panel)
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 36)
	header.BackgroundTransparency = 1
	header.LayoutOrder = 0
	header.Active = true

	local titleLabel = Instance.new("TextLabel", header)
	titleLabel.Size = UDim2.new(1, -36, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Text = "🔨 BuildTools"
	titleLabel.TextColor3 = THEME.Title
	titleLabel.TextSize = 16
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left

	local closeBtn = Instance.new("TextButton", header)
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -28, 0.5, -14)
	closeBtn.BackgroundColor3 = THEME.Destructive
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "×"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 18
	makeCorner(closeBtn, 6)
	closeBtn.MouseButton1Click:Connect(function()
		_G._BuildTools_Disable()
	end)

	makeDraggable(panel, header)

	local div1 = Instance.new("Frame", panel)
	div1.Size = UDim2.new(1, 0, 0, 1)
	div1.BackgroundColor3 = THEME.Stroke
	div1.BorderSizePixel = 0
	div1.LayoutOrder = 1

	ui.StatusLabel = Instance.new("TextLabel", panel)
	ui.StatusLabel.Name = "StatusLabel"
	ui.StatusLabel.Size = UDim2.new(1, 0, 0, 28)
	ui.StatusLabel.BackgroundColor3 = THEME.BackgroundAlt
	ui.StatusLabel.Font = Enum.Font.Gotham
	ui.StatusLabel.TextColor3 = THEME.TextDim
	ui.StatusLabel.TextSize = 10
	ui.StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	ui.StatusLabel.TextWrapped = false
	ui.StatusLabel.ClipsDescendants = true
	ui.StatusLabel.LayoutOrder = 2
	local statusPad = Instance.new("UIPadding", ui.StatusLabel)
	statusPad.PaddingLeft = UDim.new(0, 8)
	makeCorner(ui.StatusLabel, 5)
	makeStroke(ui.StatusLabel, THEME.Stroke, 1, 0.5)

	ui.ModeButtons = {}

	local function createModeButton(modeInfo)
		local btn = Instance.new("TextButton", panel)
		btn.Name = "Mode_" .. modeInfo.key
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.Font = Enum.Font.GothamSemibold
		btn.Text = modeInfo.label
		btn.TextSize = 12
		btn.BackgroundColor3 = THEME.Interactive
		btn.TextColor3 = THEME.Text
		btn.AutoButtonColor = false
		makeCorner(btn, 6)
		makeStroke(btn, THEME.Stroke, 1, 0.6)

		btn.MouseEnter:Connect(function()
			if State.currentMode ~= modeInfo.key then
				btn.BackgroundColor3 = THEME.InteractiveHover
			end
		end)
		btn.MouseLeave:Connect(function()
			if State.currentMode ~= modeInfo.key then
				btn.BackgroundColor3 = THEME.Interactive
			end
		end)

		btn.MouseButton1Click:Connect(function()
			State.currentMode = modeInfo.key
			for _, entry in ipairs(ui.ModeButtons) do
				local isActive = (State.currentMode == entry.key)
				local color = isActive and THEME.ActiveMode or THEME.Interactive
				local textColor = isActive and THEME.ActiveModeText or THEME.Text
				if entry.colorType == "destructive" and isActive then
					color = THEME.Destructive
					textColor = Color3.new(1, 1, 1)
				end
				entry.btn.BackgroundColor3 = color
				entry.btn.TextColor3 = textColor
			end
			notify("BuildTools", "Mode: " .. modeInfo.label, 1)
		end)

		return btn
	end

	for i, modeInfo in ipairs(MODE_ORDER) do
		local btn = createModeButton(modeInfo)
		btn.LayoutOrder = 10 + i
		table.insert(ui.ModeButtons, { key = modeInfo.key, btn = btn, colorType = modeInfo.color })
	end

	local div2 = Instance.new("Frame", panel)
	div2.Size = UDim2.new(1, 0, 0, 1)
	div2.BackgroundColor3 = THEME.Stroke
	div2.BorderSizePixel = 0
	div2.LayoutOrder = 20

	local function createActionButton(label, color, layoutOrder, callback)
		local btn = Instance.new("TextButton", panel)
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.Font = Enum.Font.GothamSemibold
		btn.Text = label
		btn.TextSize = 12
		btn.BackgroundColor3 = color or THEME.Interactive
		btn.TextColor3 = THEME.Text
		btn.AutoButtonColor = false
		btn.LayoutOrder = layoutOrder
		makeCorner(btn, 6)
		makeStroke(btn, THEME.Stroke, 1, 0.6)
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = (btn.BackgroundColor3:lerp(Color3.new(1, 1, 1), 0.08))
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = color or THEME.Interactive
		end)
		btn.MouseButton1Click:Connect(callback)
		return btn
	end

	createActionButton("↩  Undo Last", THEME.Interactive, 21, undoLast)

	createActionButton("✂  Delete Selected (Del)", THEME.Destructive, 22, function()
		if #State.selectedParts == 0 then
			notify("BuildTools", "Nothing selected.", 2)
			return
		end
		local count = 0
		for _, part in ipairs(State.selectedParts) do
			if not isCharacterPart(part) then
				pushHistory({ type = "delete", part = part, parent = part.Parent, cframe = part.CFrame })
				table.insert(State.saveHistory, { name = part.Name, position = part.Position })
				pcall(function()
					part.Parent = nil
				end)
				count = count + 1
			end
		end
		State.selectedParts = {}
		notify("BuildTools", ("Deleted %d part(s)"):format(count), 2)
	end)

	createActionButton("📋  Export Delete Script", THEME.Interactive, 23, function()
		if #State.saveHistory == 0 then
			notify("BuildTools", "No deleted parts to export.", 3)
			return
		end
		local lines = { "-- BuildTools auto-generated delete script" }
		for _, data in ipairs(State.saveHistory) do
			local px, py, pz = data.position.X, data.position.Y, data.position.Z
			table.insert(
				lines,
				string.format(
					"for _,v in ipairs(workspace:GetDescendants()) do if v:IsA('BasePart') and v.Name==%q and (v.Position-Vector3.new(%.3f,%.3f,%.3f)).Magnitude<1 then v:Destroy() end end",
					data.name,
					px,
					py,
					pz
				)
			)
		end
		local script = table.concat(lines, "\n")
		if setclipboard then
			setclipboard(script)
			notify("BuildTools", ("Copied %d entries."):format(#State.saveHistory), 3)
		else
			notify("BuildTools", "setclipboard unavailable in this executor.", 3)
		end
	end)

	createActionButton("🗑  Clear Selection", THEME.Interactive, 24, function()
		State.selectedParts = {}
		notify("BuildTools", "Selection cleared.", 1)
	end)

	local hint = Instance.new("TextLabel", panel)
	hint.Size = UDim2.new(1, 0, 0, 18)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.Text = "Shift+B to toggle  •  Shift+Click to multi-select"
	hint.TextColor3 = THEME.TextDim
	hint.TextSize = 9
	hint.LayoutOrder = 30

	for _, entry in ipairs(ui.ModeButtons) do
		entry.btn.BackgroundColor3 = (State.currentMode == entry.key) and THEME.ActiveMode or THEME.Interactive
		entry.btn.TextColor3 = (State.currentMode == entry.key) and THEME.ActiveModeText or THEME.Text
	end

	return ui
end

local function updateStatus()
	if not (State.ui and State.ui.StatusLabel) then
		return
	end
	local targetName = State.currentPart and State.currentPart.Name or "—"
	State.ui.StatusLabel.Text = string.format(
		" %s  |  hover: %s  |  sel: %d  |  hist: %d",
		State.currentMode:upper(),
		targetName,
		#State.selectedParts,
		#State.history
	)
end

local function buildToggleButton()
	local old = CoreGui:FindFirstChild("BuildToolsToggle")
	if old then
		old:Destroy()
	end

	local tGui = Instance.new("ScreenGui")
	tGui.Name = "BuildToolsToggle"
	tGui.ResetOnSpawn = false
	tGui.Parent = CoreGui

	local btn = Instance.new("TextButton", tGui)
	btn.Size = UDim2.fromOffset(52, 52)
	btn.Position = UDim2.new(0, 16, 0.5, -26)
	btn.BackgroundColor3 = THEME.Background
	btn.Font = Enum.Font.GothamBold
	btn.Text = "B"
	btn.TextColor3 = THEME.Accent
	btn.TextSize = 24
	btn.AutoButtonColor = false
	makeCorner(btn, 999)
	makeStroke(btn, THEME.Accent, 2, 0.2)

	RunService.Heartbeat:Connect(function()
		local s = btn:FindFirstChildWhichIsA("UIStroke")
		if not s then
			return
		end
		if State.isActive then
			s.Transparency = 0.1 + math.abs(math.sin(os.clock() * 3)) * 0.4
		else
			s.Transparency = 0.6
		end
	end)

	makeDraggable(btn, btn)

	local clickedDown = false
	btn.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			clickedDown = true
		end
	end)
	btn.Activated:Connect(function()
		if clickedDown then
			_G._BuildTools_Toggle()
			clickedDown = false
		end
	end)
end

local function disable()
	if not State.isActive then
		return
	end
	State.isActive = false

	for _, c in ipairs(State.connections) do
		pcall(function()
			c:Disconnect()
		end)
	end
	table.clear(State.connections)

	if State.ui and State.ui.ScreenGui then
		pcall(function()
			State.ui.ScreenGui:Destroy()
		end)
	end
	State.ui = nil

	if State.highlight then
		pcall(function()
			State.highlight:Destroy()
		end)
	end
	State.highlight = nil

	State.selectedParts = {}
	State.currentPart = nil
	State.isDragging = false
	State.dragOffsets = {}

	notify("BuildTools", "Deactivated.", 2)
end

local function enable()
	if State.isActive then
		return
	end
	State.isActive = true

	State.ui = buildUI()

	State.highlight = Instance.new("SelectionBox")
	State.highlight.Name = "BT_SelectionHighlight"
	State.highlight.LineThickness = 0.05
	State.highlight.Color3 = THEME.Accent
	State.highlight.SurfaceTransparency = 0.88
	State.highlight.SurfaceColor3 = THEME.AccentDim
	State.highlight.Parent = CoreGui

	conn(RunService.RenderStepped, function()
		local part, hitPos = raycastFromCursor()
		local resolved = resolveBasePart(part)

		State.currentPart = resolved
		State.highlight.Adornee = resolved

		updateStatus()

		if State.isDragging and #State.dragOffsets > 0 then
			if hitPos then
				for _, data in ipairs(State.dragOffsets) do
					if data.part and data.part.Parent then
						local targetPos = hitPos + data.offset
						pcall(function()
							data.part.CFrame = CFrame.new(targetPos) * (data.part.CFrame - data.part.CFrame.Position)
						end)
					end
				end
			end
		end
	end)

	conn(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local part = State.currentPart
		if not part then
			return
		end

		local handler = ModeHandlers[State.currentMode]
		if handler then
			handler(part)
		end

		if State.currentMode == "move" and #State.selectedParts > 0 then
			local _p, hitPos = raycastFromCursor()
			if hitPos then
				State.isDragging = true
				State.dragOffsets = {}
				local undoEntry = { type = "move", parts = {} }
				for _, p in ipairs(State.selectedParts) do
					if p and p.Parent then
						table.insert(undoEntry.parts, { part = p, before = p.CFrame })
						table.insert(State.dragOffsets, { part = p, offset = p.Position - hitPos })
					end
				end
				pushHistory(undoEntry)
			end
		end
	end)

	conn(UserInputService.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if State.isDragging then
				State.isDragging = false
				State.dragOffsets = {}
			end
		end
	end)

	conn(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode ~= Enum.KeyCode.Delete then
			return
		end
		if #State.selectedParts == 0 then
			return
		end

		local count = 0
		for _, p in ipairs(State.selectedParts) do
			if p and p.Parent and not isCharacterPart(p) then
				pushHistory({ type = "delete", part = p, parent = p.Parent, cframe = p.CFrame })
				table.insert(State.saveHistory, { name = p.Name, position = p.Position })
				pcall(function()
					p.Parent = nil
				end)
				count = count + 1
			end
		end
		State.selectedParts = {}
		notify("BuildTools", ("Deleted %d part(s)"):format(count), 2)
	end)

	conn(UserInputService.InputBegan, function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Z and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			undoLast()
		end
	end)

	notify("BuildTools", "Activated. Mode: " .. State.currentMode, 2)
end

local function toggle()
	if State.isActive then
		disable()
	else
		enable()
	end
end

_G._BuildTools_Disable = disable
_G._BuildTools_Toggle = toggle

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.B and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		toggle()
	end
end)

buildToggleButton()
enable()

print("[BuildTools v2.0] Loaded. Shift+B to toggle.")
