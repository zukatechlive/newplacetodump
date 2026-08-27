local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local lp             = Players.LocalPlayer

local State = {
	Enabled        = false,
	Target         = nil,
	Offset         = CFrame.new(0, 0, 3),  -- Z = distance behind target
	BlinkFrequency = 2,                     -- fire every N Heartbeat ticks
}

-- originalCFrame is only non-nil between a Heartbeat blink write and the
-- following Stepped restore. Keeping it local and clearing it in both
-- directions prevents stale-restore bugs.
local originalCFrame = nil
local blinkTick      = 0
local blinkArmed     = false  -- true only when a blink was actually written this frame

-- ══════════════════════════════════════════════════════════════
-- THEME
-- ══════════════════════════════════════════════════════════════
local Theme = {
	Background  = Color3.fromRGB(20, 21, 24),
	Surface     = Color3.fromRGB(27, 28, 32),
	SurfaceAlt  = Color3.fromRGB(33, 34, 39),
	Border      = Color3.fromRGB(44, 45, 51),
	TextPrimary = Color3.fromRGB(232, 232, 236),
	TextMuted   = Color3.fromRGB(140, 141, 150),
	Accent      = Color3.fromRGB(214, 156, 74),
	AccentDim   = Color3.fromRGB(150, 108, 52),
	Danger      = Color3.fromRGB(196, 90, 84),
	Success     = Color3.fromRGB(107, 168, 110),
}

local FONT_HEADER = Enum.Font.GothamMedium
local FONT_BODY   = Enum.Font.Gotham

local function tween(obj, props, duration, style)
	TweenService:Create(obj, TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad), props):Play()
end

-- ══════════════════════════════════════════════════════════════
-- ROOT
-- ══════════════════════════════════════════════════════════════
-- Clean up any leftover GUI from a previous run
local existing = game.CoreGui:FindFirstChild("CframeTest")
if existing then existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "CframeTest"
ScreenGui.ResetOnSpawn = false

local COLLAPSED_HEIGHT = 38
local EXPANDED_HEIGHT  = 380  -- slightly taller to fit the two new sliders

local Main = Instance.new("Frame", ScreenGui)
Main.Name = "Main"
Main.Size = UDim2.new(0, 220, 0, EXPANDED_HEIGHT)
Main.Position = UDim2.new(0.78, 0, 0.5, -190)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1

-- ── Dragging ──────────────────────────────────────────────────
local function makeDraggable(topbar, object)
	local dragging, dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		object.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos  = object.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- ══════════════════════════════════════════════════════════════
-- TITLE BAR
-- ══════════════════════════════════════════════════════════════
local Title = Instance.new("TextButton", Main)
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, COLLAPSED_HEIGHT)
Title.BackgroundColor3 = Theme.Surface
Title.Text = ""
Title.AutoButtonColor = false
Title.BorderSizePixel = 0
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local TitleMask = Instance.new("Frame", Title)
TitleMask.Size = UDim2.new(1, 0, 0, 8)
TitleMask.Position = UDim2.new(0, 0, 1, -8)
TitleMask.BackgroundColor3 = Theme.Surface
TitleMask.BorderSizePixel = 0
TitleMask.ZIndex = 0

local AccentBar = Instance.new("Frame", Title)
AccentBar.Size = UDim2.new(0, 3, 1, -12)
AccentBar.Position = UDim2.new(0, 8, 0, 6)
AccentBar.BackgroundColor3 = Theme.Accent
AccentBar.BorderSizePixel = 0
Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(1, 0)

local TitleLabel = Instance.new("TextLabel", Title)
TitleLabel.Size = UDim2.new(1, -55, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Target Select"
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextColor3 = Theme.TextPrimary
TitleLabel.Font = FONT_HEADER
TitleLabel.TextSize = 13

local StatusDot = Instance.new("Frame", Title)
StatusDot.Size = UDim2.new(0, 6, 0, 6)
StatusDot.Position = UDim2.new(1, -38, 0.5, -3)
StatusDot.BackgroundColor3 = Theme.Danger
StatusDot.BorderSizePixel = 0
Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1, 0)

local Arrow = Instance.new("TextLabel", Title)
Arrow.Size = UDim2.new(0, 25, 1, 0)
Arrow.Position = UDim2.new(1, -25, 0, 0)
Arrow.BackgroundTransparency = 1
Arrow.Text = "▾"
Arrow.TextColor3 = Theme.TextMuted
Arrow.Font = FONT_BODY
Arrow.TextSize = 13

makeDraggable(Title, Main)

-- ══════════════════════════════════════════════════════════════
-- BODY
-- ══════════════════════════════════════════════════════════════
local Body = Instance.new("Frame", Main)
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -COLLAPSED_HEIGHT)
Body.Position = UDim2.new(0, 0, 0, COLLAPSED_HEIGHT)
Body.BackgroundTransparency = 1

local BodyPad = Instance.new("UIPadding", Body)
BodyPad.PaddingLeft   = UDim.new(0, 10)
BodyPad.PaddingRight  = UDim.new(0, 10)
BodyPad.PaddingTop    = UDim.new(0, 8)
BodyPad.PaddingBottom = UDim.new(0, 10)

-- ── Toggle row ────────────────────────────────────────────────
local ToggleRow = Instance.new("Frame", Body)
ToggleRow.Size = UDim2.new(1, 0, 0, 32)
ToggleRow.Position = UDim2.new(0, 0, 0, 0)
ToggleRow.BackgroundColor3 = Theme.Surface
ToggleRow.BorderSizePixel = 0
Instance.new("UICorner", ToggleRow).CornerRadius = UDim.new(0, 6)

local ToggleLabel = Instance.new("TextLabel", ToggleRow)
ToggleLabel.Size = UDim2.new(1, -56, 1, 0)
ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "Snapback"
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.TextColor3 = Theme.TextPrimary
ToggleLabel.Font = FONT_BODY
ToggleLabel.TextSize = 12

local ToggleBtn = Instance.new("TextButton", ToggleRow)
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 38, 0, 20)
ToggleBtn.Position = UDim2.new(1, -46, 0.5, -10)
ToggleBtn.BackgroundColor3 = Theme.SurfaceAlt
ToggleBtn.Text = ""
ToggleBtn.AutoButtonColor = false
ToggleBtn.BorderSizePixel = 0
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local ToggleKnob = Instance.new("Frame", ToggleBtn)
ToggleKnob.Size = UDim2.new(0, 16, 0, 16)
ToggleKnob.Position = UDim2.new(0, 2, 0.5, -8)
ToggleKnob.BackgroundColor3 = Theme.TextMuted
ToggleKnob.BorderSizePixel = 0
Instance.new("UICorner", ToggleKnob).CornerRadius = UDim.new(1, 0)

-- ── Offset Z slider (distance behind target) ──────────────────
local function makeSliderRow(parent, labelText, yPos, minVal, maxVal, initVal, fmt, onChanged)
	local row = Instance.new("Frame", parent)
	row.Size = UDim2.new(1, 0, 0, 38)
	row.Position = UDim2.new(0, 0, 0, yPos)
	row.BackgroundColor3 = Theme.Surface
	row.BorderSizePixel = 0
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local lbl = Instance.new("TextLabel", row)
	lbl.Size = UDim2.new(1, -50, 0, 18)
	lbl.Position = UDim2.new(0, 10, 0, 4)
	lbl.BackgroundTransparency = 1
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextColor3 = Theme.TextPrimary
	lbl.Font = FONT_BODY
	lbl.TextSize = 11

	local valLbl = Instance.new("TextLabel", row)
	valLbl.Size = UDim2.new(0, 40, 0, 18)
	valLbl.Position = UDim2.new(1, -48, 0, 4)
	valLbl.BackgroundTransparency = 1
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.TextColor3 = Theme.Accent
	valLbl.Font = FONT_BODY
	valLbl.TextSize = 11

	local track = Instance.new("Frame", row)
	track.Size = UDim2.new(1, -20, 0, 4)
	track.Position = UDim2.new(0, 10, 0, 26)
	track.BackgroundColor3 = Theme.SurfaceAlt
	track.BorderSizePixel = 0
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill = Instance.new("Frame", track)
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = Theme.Accent
	fill.BorderSizePixel = 0
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local handle = Instance.new("TextButton", track)
	handle.Size = UDim2.fromOffset(10, 14)
	handle.Position = UDim2.new(0, 0, 0.5, -7)
	handle.BackgroundColor3 = Theme.Accent
	handle.Text = ""
	handle.AutoButtonColor = false
	handle.BorderSizePixel = 0
	Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

	local val = initVal
	local dragging = false

	local function syncUI()
		local ratio = math.clamp((val - minVal) / (maxVal - minVal), 0, 1)
		local tw = track.AbsoluteSize.X
		local hw = handle.AbsoluteSize.X
		local hx = ratio * math.max(tw - hw, 0)
		handle.Position = UDim2.new(0, hx, 0.5, -7)
		fill.Size = UDim2.new(0, hx + hw / 2, 1, 0)
		lbl.Text = labelText
		valLbl.Text = string.format(fmt or "%.1f", val)
	end

	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local mx = UserInputService:GetMouseLocation().X
			local tx = track.AbsolutePosition.X
			local tw = track.AbsoluteSize.X
			local hw = handle.AbsoluteSize.X
			local hx = math.clamp(mx - tx - hw / 2, 0, tw - hw)
			val = minVal + (maxVal - minVal) * (hx / math.max(tw - hw, 1))
			handle.Position = UDim2.new(0, hx, 0.5, -7)
			fill.Size = UDim2.new(0, hx + hw / 2, 1, 0)
			valLbl.Text = string.format(fmt or "%.1f", val)
			if onChanged then onChanged(val) end
		end
	end)

	task.defer(syncUI)
	return row
end

-- Offset Z slider: how far behind the target you land (positive = behind them)
makeSliderRow(Body, "Offset (Z)", 40, 0, 20, 3, "%.1f", function(v)
	State.Offset = CFrame.new(0, 0, v)
end)

-- Blink frequency slider: fire every N ticks (1 = every tick, 10 = every 10th)
makeSliderRow(Body, "Blink Freq", 86, 1, 10, 2, "%.0f", function(v)
	State.BlinkFrequency = math.floor(v + 0.5)
end)

-- ── Search box ────────────────────────────────────────────────
local SearchBox = Instance.new("TextBox", Body)
SearchBox.Size = UDim2.new(1, 0, 0, 26)
SearchBox.Position = UDim2.new(0, 0, 0, 132)
SearchBox.BackgroundColor3 = Theme.Surface
SearchBox.PlaceholderText = "Search players..."
SearchBox.PlaceholderColor3 = Theme.TextMuted
SearchBox.Text = ""
SearchBox.TextColor3 = Theme.TextPrimary
SearchBox.Font = FONT_BODY
SearchBox.TextSize = 12
SearchBox.ClearTextOnFocus = false
SearchBox.BorderSizePixel = 0
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 6)
local SearchPad = Instance.new("UIPadding", SearchBox)
SearchPad.PaddingLeft = UDim.new(0, 10)

-- ── Player list ───────────────────────────────────────────────
local Scroll = Instance.new("ScrollingFrame", Body)
Scroll.Name = "Scroll"
Scroll.Size = UDim2.new(1, 0, 0, 148)
Scroll.Position = UDim2.new(0, 0, 0, 166)
Scroll.BackgroundColor3 = Theme.Surface
Scroll.BorderSizePixel = 0
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Theme.Border
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 6)
local ScrollPad = Instance.new("UIPadding", Scroll)
ScrollPad.PaddingTop   = UDim.new(0, 4)
ScrollPad.PaddingLeft  = UDim.new(0, 4)
ScrollPad.PaddingRight = UDim.new(0, 4)

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Name = "UIList"
UIList.Padding = UDim.new(0, 3)

-- ── Target readout ────────────────────────────────────────────
local TargetRow = Instance.new("Frame", Body)
TargetRow.Size = UDim2.new(1, 0, 0, 26)
TargetRow.Position = UDim2.new(0, 0, 1, -26)
TargetRow.BackgroundTransparency = 1

local TargetLabel = Instance.new("TextLabel", TargetRow)
TargetLabel.Size = UDim2.new(1, 0, 1, 0)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "No target selected"
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.TextColor3 = Theme.TextMuted
TargetLabel.Font = FONT_BODY
TargetLabel.TextSize = 11

-- ══════════════════════════════════════════════════════════════
-- COLLAPSE / EXPAND
-- ══════════════════════════════════════════════════════════════
local collapsed = false

local function setCollapsed(state)
	collapsed = state
	tween(Arrow, { Rotation = collapsed and -90 or 0 }, 0.15)
	Arrow.Text = "▾"
	tween(Main, {
		Size = UDim2.new(0, 220, 0, collapsed and COLLAPSED_HEIGHT or EXPANDED_HEIGHT)
	}, 0.2, Enum.EasingStyle.Quart)
	if not collapsed then
		Body.Visible = true
	else
		task.delay(0.2, function()
			if collapsed then Body.Visible = false end
		end)
	end
end

Title.MouseButton1Click:Connect(function()
	setCollapsed(not collapsed)
end)

-- ══════════════════════════════════════════════════════════════
-- PLAYER LIST
-- ══════════════════════════════════════════════════════════════
local searchQuery = ""

local function updateList()
	-- Clear existing buttons only, leave layout/padding instances
	for _, v in ipairs(Scroll:GetChildren()) do
		if v:IsA("TextButton") then v:Destroy() end
	end

	-- ipairs on GetPlayers() gives consistent ordering
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= lp then
			if searchQuery == "" or string.find(string.lower(p.Name), searchQuery, 1, true) then
				local isTarget = State.Target == p

				local b = Instance.new("TextButton", Scroll)
				b.Size = UDim2.new(1, 0, 0, 26)
				b.BackgroundColor3 = isTarget and Theme.Accent or Theme.SurfaceAlt
				b.BackgroundTransparency = isTarget and 0.75 or 0
				b.Text = ""
				b.AutoButtonColor = false
				b.BorderSizePixel = 0
				Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)

				if isTarget then
					local bs = Instance.new("UIStroke", b)
					bs.Color = Theme.Accent
					bs.Thickness = 1
				end

				local nameLabel = Instance.new("TextLabel", b)
				nameLabel.Size = UDim2.new(1, -10, 1, 0)
				nameLabel.Position = UDim2.new(0, 10, 0, 0)
				nameLabel.BackgroundTransparency = 1
				nameLabel.Text = p.Name
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.TextColor3 = isTarget and Theme.Accent or Theme.TextPrimary
				nameLabel.Font = isTarget and FONT_HEADER or FONT_BODY
				nameLabel.TextSize = 12

				b.MouseEnter:Connect(function()
					if State.Target ~= p then
						tween(b, { BackgroundColor3 = Theme.Border }, 0.12)
					end
				end)
				b.MouseLeave:Connect(function()
					if State.Target ~= p then
						tween(b, { BackgroundColor3 = Theme.SurfaceAlt }, 0.12)
					end
				end)
				b.MouseButton1Click:Connect(function()
					State.Target = p
					TargetLabel.Text = "Target: " .. p.Name
					TargetLabel.TextColor3 = Theme.Accent
					updateList()
				end)
			end
		end
	end
	Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y)
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchQuery = string.lower(SearchBox.Text)
	updateList()
end)

Players.PlayerAdded:Connect(updateList)
Players.PlayerRemoving:Connect(function(p)
	if State.Target == p then
		State.Target = nil
		TargetLabel.Text = "No target selected"
		TargetLabel.TextColor3 = Theme.TextMuted
	end
	updateList()
end)
updateList()

-- ══════════════════════════════════════════════════════════════
-- TOGGLE WIRING
-- ══════════════════════════════════════════════════════════════
local function setEnabled(state)
	State.Enabled = state
	StatusDot.BackgroundColor3 = state and Theme.Success or Theme.Danger

	-- If disabling mid-blink, restore position immediately so we don't get stuck
	if not state and originalCFrame then
		local myChar = lp.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
		if myHRP then
			myHRP.CFrame = originalCFrame
		end
		originalCFrame = nil
		blinkArmed = false
	end

	tween(ToggleBtn, { BackgroundColor3 = state and Theme.AccentDim or Theme.SurfaceAlt }, 0.15)
	tween(ToggleKnob, {
		Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
		BackgroundColor3 = state and Theme.Accent or Theme.TextMuted,
	}, 0.15)
end

ToggleBtn.MouseButton1Click:Connect(function()
	setEnabled(not State.Enabled)
end)

setEnabled(false)
setCollapsed(false)

-- ══════════════════════════════════════════════════════════════
-- BLINK LOOP
-- Heartbeat  = pre-physics, write the blink position here
-- Stepped    = post-physics, restore the real position here
--
-- blinkTick increments only when we actually attempt a blink,
-- not on every frame, so BlinkFrequency stays accurate.
-- blinkArmed is the handshake between the two events so
-- Stepped only restores when Heartbeat actually moved us.
-- ══════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
	if not State.Enabled or not State.Target or not State.Target.Character then
		-- Guard: if we somehow land here with a stale originalCFrame, clear it
		if originalCFrame then
			local myChar = lp.Character
			local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
			if myHRP then myHRP.CFrame = originalCFrame end
			originalCFrame = nil
			blinkArmed = false
		end
		return
	end

	blinkTick = blinkTick + 1
	if blinkTick % State.BlinkFrequency ~= 0 then return end

	local myChar    = lp.Character
	local myHRP     = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local targetHRP = State.Target.Character:FindFirstChild("HumanoidRootPart")

	-- Only write if both parts are valid and character is alive
	local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
	if myHRP and targetHRP and hum and hum.Health > 0 then
		originalCFrame = myHRP.CFrame
		myHRP.CFrame   = targetHRP.CFrame * State.Offset
		blinkArmed     = true
	end
end)

RunService.Stepped:Connect(function()
	-- Only restore if Heartbeat actually wrote a blink this cycle
	if not blinkArmed then return end
	blinkArmed = false

	local myChar = lp.Character
	local myHRP  = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if myHRP and originalCFrame then
		myHRP.CFrame = originalCFrame
	end
	originalCFrame = nil
end)
