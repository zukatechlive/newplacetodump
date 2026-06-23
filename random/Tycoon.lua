local Players = game:GetService("Players")
local GunSettings = game:GetService("ReplicatedStorage").GunSettings

local guns = {
	"AK-47", "AA-12", "AUG", "AWP", "Revolver", "M1 Garand",
	"Glock", "LMG", "Deagle", "Crossbow", "Cosmic MP7", "Berreta",
	"Raygun", "Silenced Sniper", "P90", "Tactical Airstrike",
	"Incendiary Shotgun", "Spider", "Radioactive MP5", "RPG", "MP5", "Tommy Gun",
}
local gunEnabled = {}
for _, g in ipairs(guns) do gunEnabled[g] = true end

local overrides = {
	{ key = "Auto",                  val = false,    type = "bool"   },
	{ key = "Debuff",                val = true,     type = "bool"   },
	{ key = "DebuffChance",          val = 100,      type = "number" },
	{ key = "AmmoPerMag",            val = 999999,   type = "number" },
	{ key = "BulletsPerShot",        val = 4,        type = "number" },
	{ key = "Range",                 val = 90000,    type = "number" },
	{ key = "Damage",                val = 999999,   type = "number" },
	{ key = "DamageThroughWall",     val = 999999,   type = "number" },
	{ key = "LaserTrailDamage",      val = 999999,   type = "number" },
	{ key = "CriticalDamageEnabled", val = 999999,   type = "number" },
	{ key = "Lifesteal",             val = 99999,    type = "number" },
	{ key = "HeadshotHitmarker",     val = 100,      type = "number" },
	{ key = "Spread",                val = 0,        type = "number" },
	{ key = "Accuracy",              val = 0,        type = "number" },
	{ key = "Recoil",                val = 0,        type = "number" },
	{ key = "ReloadTime",            val = 0,        type = "number" },
	{ key = "TacticalReloadTime",    val = 0,        type = "number" },
	{ key = "ChargingTime",          val = 0,        type = "number" },
	{ key = "DelayAfterFiring",      val = 0,        type = "number" },
	{ key = "DelayBeforeFiring",     val = 0,        type = "number" },
	{ key = "HitIgnoreDelay",        val = 0,        type = "number" },
	{ key = "LaserBeamStartupDelay", val = 0,        type = "number" },
	{ key = "BurstRate",             val = 0,        type = "number" },
	{ key = "SwitchTime",            val = 0,        type = "number" },
	{ key = "AngleXMin",             val = 0,        type = "number" },
}

local function buildOverrideMap()
	local m = {}
	for _, o in ipairs(overrides) do
		m[o.key] = o.val
	end
	return m
end

local function applyOverrides()
	local map = buildOverrideMap()
	for _, gunName in ipairs(guns) do
		if not gunEnabled[gunName] then continue end
		local ok, result = pcall(function()
			return require(GunSettings[gunName]["1"])
		end)
		if not ok then
			warn(("[GunOverride] Skipped "..gunName..": "..tostring(result)))
			continue
		end
		local mod = result
		if setreadonly then setreadonly(mod, false) end
		for key, value in pairs(map) do
			mod[key] = value
		end
		if setreadonly then setreadonly(mod, true) end
	end
end

local C = {
	BG         = Color3.fromRGB(14, 14, 20),
	PANEL      = Color3.fromRGB(20, 20, 30),
	HEADER     = Color3.fromRGB(25, 25, 40),
	ACCENT     = Color3.fromRGB(100, 80, 220),
	ACCENT2    = Color3.fromRGB(70, 55, 180),
	GREEN      = Color3.fromRGB(60, 200, 100),
	RED        = Color3.fromRGB(210, 60, 70),
	TEXT       = Color3.fromRGB(230, 230, 240),
	SUBTEXT    = Color3.fromRGB(140, 140, 160),
	INPUT_BG   = Color3.fromRGB(10, 10, 18),
	STROKE     = Color3.fromRGB(55, 55, 80),
	TOGGLE_ON  = Color3.fromRGB(60, 200, 100),
	TOGGLE_OFF = Color3.fromRGB(70, 70, 90),
}

local function corner(_, p)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 0)
	c.Parent = p
	return c
end
local function stroke(col, th, p)
	local s = Instance.new("UIStroke")
	s.Color = col
	s.Thickness = th
	s.Parent = p
	return s
end
local function padding(t, b, l, r, p)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, t)
	pad.PaddingBottom = UDim.new(0, b)
	pad.PaddingLeft   = UDim.new(0, l)
	pad.PaddingRight  = UDim.new(0, r)
	pad.Parent        = p
	return pad
end
local function label(text, size, color, font, parent)
	local lb = Instance.new("TextLabel")
	lb.Size              = UDim2.new(1, 0, 0, size + 4)
	lb.BackgroundTransparency = 1
	lb.Text              = text
	lb.TextSize          = size
	lb.TextColor3        = color
	lb.Font              = font or Enum.Font.GothamBold
	lb.TextXAlignment    = Enum.TextXAlignment.Left
	lb.Parent            = parent
	return lb
end

local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name             = "GunOverrideGui"
ScreenGui.ResetOnSpawn     = false
ScreenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder     = 999
local ok_ = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ok_ then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function makeDraggable(frame, handle)
	local dragging, dragInput, mousePos, framePos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			mousePos  = input.Position
			framePos  = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	game:GetService("UserInputService").InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			frame.Position = UDim2.new(
				framePos.X.Scale, framePos.X.Offset + delta.X,
				framePos.Y.Scale, framePos.Y.Offset + delta.Y
			)
		end
	end)
end

local MainFrame = Instance.new("Frame")
MainFrame.Name              = "MainFrame"
MainFrame.Size              = UDim2.new(0, 400, 0, 520)
MainFrame.Position          = UDim2.new(0.5, -200, 0.5, -260)
MainFrame.BackgroundColor3  = C.BG
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true
MainFrame.Parent            = ScreenGui
corner(10, MainFrame)
stroke(C.STROKE, 1.5, MainFrame)

local Header = Instance.new("Frame")
Header.Name             = "Header"
Header.Size             = UDim2.new(1, 0, 0, 38)
Header.BackgroundColor3 = C.HEADER
Header.BorderSizePixel  = 0
Header.Parent           = MainFrame
corner(10, Header)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size               = UDim2.new(1, -80, 1, 0)
TitleLbl.Position           = UDim2.new(0, 12, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text               = "🔫  Gun Override"
TitleLbl.TextSize            = 14
TitleLbl.TextColor3          = C.TEXT
TitleLbl.Font                = Enum.Font.GothamBold
TitleLbl.TextXAlignment      = Enum.TextXAlignment.Left
TitleLbl.Parent              = Header

local function headerBtn(text, xOff, bgCol)
	local btn = Instance.new("TextButton")
	btn.Size               = UDim2.new(0, 26, 0, 20)
	btn.Position           = UDim2.new(1, xOff, 0, 9)
	btn.BackgroundColor3   = bgCol
	btn.BorderSizePixel    = 0
	btn.Text               = text
	btn.TextColor3         = C.TEXT
	btn.TextSize           = 12
	btn.Font               = Enum.Font.GothamBold
	btn.ZIndex             = 10
	btn.Parent             = MainFrame
	corner(0, btn)
	return btn
end
local MinBtn   = headerBtn("—", -60, C.TOGGLE_OFF)
local CloseBtn = headerBtn("✕", -30, C.RED)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local minimized = false
local function setMinimized(v)
	minimized = v
	MainFrame.Size = v and UDim2.new(0, 400, 0, 38) or UDim2.new(0, 400, 0, 520)
end
MinBtn.MouseButton1Click:Connect(function() setMinimized(not minimized) end)

makeDraggable(MainFrame, Header)

local TabBar = Instance.new("Frame")
TabBar.Name             = "TabBar"
TabBar.Size             = UDim2.new(1, -16, 0, 28)
TabBar.Position         = UDim2.new(0, 8, 0, 44)
TabBar.BackgroundColor3 = C.PANEL
TabBar.BorderSizePixel  = 0
TabBar.Parent           = MainFrame
corner(6, TabBar)
stroke(C.STROKE, 1, TabBar)

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding       = UDim.new(0, 4)
TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
TabLayout.Parent        = TabBar
padding(3, 3, 4, 4, TabBar)

local ContentArea = Instance.new("Frame")
ContentArea.Name             = "ContentArea"
ContentArea.Size             = UDim2.new(1, -16, 1, -84)
ContentArea.Position         = UDim2.new(0, 8, 0, 78)
ContentArea.BackgroundColor3 = C.PANEL
ContentArea.BorderSizePixel  = 0
ContentArea.ClipsDescendants = true
ContentArea.Parent           = MainFrame
corner(8, ContentArea)
stroke(C.STROKE, 1, ContentArea)

local tabs      = {}
local tabBtns   = {}
local activeTab = nil

local function createTab(name)
		local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(0, 88, 1, 0)
	btn.BackgroundColor3 = C.PANEL
	btn.BorderSizePixel  = 0
	btn.Text             = name
	btn.TextSize         = 12
	btn.TextColor3       = C.SUBTEXT
	btn.Font             = Enum.Font.GothamBold
	btn.Parent           = TabBar
	corner(5, btn)

		local page = Instance.new("ScrollingFrame")
	page.Name                    = name
	page.Size                    = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency  = 1
	page.BorderSizePixel         = 0
	page.ScrollBarThickness      = 3
	page.ScrollBarImageColor3    = C.ACCENT
	page.CanvasSize              = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize     = Enum.AutomaticSize.Y
	page.Visible                 = false
	page.Parent                  = ContentArea

	local list = Instance.new("UIListLayout")
	list.Padding      = UDim.new(0, 5)
	list.SortOrder    = Enum.SortOrder.LayoutOrder
	list.Parent       = page
	padding(8, 8, 8, 8, page)

	tabs[name]    = { page = page, layout = list }
	tabBtns[name] = btn

	btn.MouseButton1Click:Connect(function()
				for n, t in pairs(tabs) do
			t.page.Visible          = false
			tabBtns[n].TextColor3   = C.SUBTEXT
			tabBtns[n].BackgroundColor3 = C.PANEL
		end
				page.Visible                = true
		btn.TextColor3              = C.TEXT
		btn.BackgroundColor3        = C.ACCENT2
		activeTab                   = name
	end)

	return tabs[name]
end

local tOverrides = createTab("Overrides")
local tGuns      = createTab("Guns")
local tPresets   = createTab("Presets")

tabBtns["Overrides"].TextColor3        = C.TEXT
tabBtns["Overrides"].BackgroundColor3  = C.ACCENT2
tabs["Overrides"].page.Visible         = true

local function sectionHeader(text, parent)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 20)
	row.BackgroundTransparency = 1
	row.LayoutOrder      = 0
	row.Parent           = parent

	local lb = Instance.new("TextLabel")
	lb.Size              = UDim2.new(1, 0, 1, 0)
	lb.BackgroundTransparency = 1
	lb.Text              = text
	lb.TextSize          = 11
	lb.TextColor3        = C.ACCENT
	lb.Font              = Enum.Font.GothamBold
	lb.TextXAlignment    = Enum.TextXAlignment.Left
	lb.Parent            = row
	return row
end

local function numberRow(overrideEntry, parent, order)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = C.INPUT_BG
	row.BorderSizePixel  = 0
	row.LayoutOrder      = order
	row.Parent           = parent
	corner(6, row)
	stroke(C.STROKE, 1, row)

	local keyLbl = Instance.new("TextLabel")
	keyLbl.Size              = UDim2.new(0.58, -4, 1, 0)
	keyLbl.Position          = UDim2.new(0, 8, 0, 0)
	keyLbl.BackgroundTransparency = 1
	keyLbl.Text              = overrideEntry.key
	keyLbl.TextSize          = 11
	keyLbl.TextColor3        = C.TEXT
	keyLbl.Font              = Enum.Font.Gotham
	keyLbl.TextXAlignment    = Enum.TextXAlignment.Left
	keyLbl.TextTruncate      = Enum.TextTruncate.AtEnd
	keyLbl.Parent            = row

	local box = Instance.new("TextBox")
	box.Size             = UDim2.new(0.42, -12, 0, 22)
	box.Position         = UDim2.new(0.58, 4, 0.5, -11)
	box.BackgroundColor3 = C.PANEL
	box.BorderSizePixel  = 0
	box.Text             = tostring(overrideEntry.val)
	box.TextSize         = 11
	box.TextColor3       = C.TEXT
	box.Font             = Enum.Font.Code
	box.TextXAlignment   = Enum.TextXAlignment.Center
	box.ClearTextOnFocus = false
	box.Parent           = row
	corner(4, box)
	stroke(C.ACCENT, 1, box)

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			overrideEntry.val = n
			box.TextColor3    = C.GREEN
			task.delay(1, function() box.TextColor3 = C.TEXT end)
		else
			box.Text          = tostring(overrideEntry.val)
			box.TextColor3    = C.RED
			task.delay(1, function() box.TextColor3 = C.TEXT end)
		end
	end)

	return row
end

local function boolRow(overrideEntry, parent, order)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 32)
	row.BackgroundColor3 = C.INPUT_BG
	row.BorderSizePixel  = 0
	row.LayoutOrder      = order
	row.Parent           = parent
	corner(6, row)
	stroke(C.STROKE, 1, row)

	local keyLbl = Instance.new("TextLabel")
	keyLbl.Size              = UDim2.new(0.65, 0, 1, 0)
	keyLbl.Position          = UDim2.new(0, 8, 0, 0)
	keyLbl.BackgroundTransparency = 1
	keyLbl.Text              = overrideEntry.key
	keyLbl.TextSize          = 11
	keyLbl.TextColor3        = C.TEXT
	keyLbl.Font              = Enum.Font.Gotham
	keyLbl.TextXAlignment    = Enum.TextXAlignment.Left
	keyLbl.Parent            = row

	local togBg = Instance.new("Frame")
	togBg.Size            = UDim2.new(0, 42, 0, 20)
	togBg.Position        = UDim2.new(1, -50, 0.5, -10)
	togBg.BackgroundColor3 = overrideEntry.val and C.TOGGLE_ON or C.TOGGLE_OFF
	togBg.BorderSizePixel = 0
	togBg.Parent          = row
	corner(10, togBg)

	local knob = Instance.new("Frame")
	knob.Size            = UDim2.new(0, 16, 0, 16)
	knob.Position        = overrideEntry.val
		and UDim2.new(1, -18, 0.5, -8)
		or  UDim2.new(0, 2, 0.5, -8)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent          = togBg
	corner(8, knob)

	local togBtn = Instance.new("TextButton")
	togBtn.Size               = UDim2.new(1, 0, 1, 0)
	togBtn.BackgroundTransparency = 1
	togBtn.Text               = ""
	togBtn.Parent             = togBg

	local function updateToggle()
		local v = overrideEntry.val
		togBg.BackgroundColor3 = v and C.TOGGLE_ON or C.TOGGLE_OFF
		knob.Position = v
			and UDim2.new(1, -18, 0.5, -8)
			or  UDim2.new(0, 2, 0.5, -8)
	end

	togBtn.MouseButton1Click:Connect(function()
		overrideEntry.val = not overrideEntry.val
		updateToggle()
	end)

	return row
end

local order = 0
sectionHeader("Boolean Flags", tOverrides.page).LayoutOrder = order order+=1
for _, ov in ipairs(overrides) do
	if ov.type == "bool" then
		boolRow(ov, tOverrides.page, order)
		order += 1
	end
end
sectionHeader("Numeric Values", tOverrides.page).LayoutOrder = order order+=1
for _, ov in ipairs(overrides) do
	if ov.type == "number" then
		numberRow(ov, tOverrides.page, order)
		order += 1
	end
end

local function gunRow(gunName, parent, ord)
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = C.INPUT_BG
	row.BorderSizePixel  = 0
	row.LayoutOrder      = ord
	row.Parent           = parent
	corner(6, row)
	stroke(C.STROKE, 1, row)

	local lbl = Instance.new("TextLabel")
	lbl.Size              = UDim2.new(0.7, 0, 1, 0)
	lbl.Position          = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text              = gunName
	lbl.TextSize          = 11
	lbl.TextColor3        = C.TEXT
	lbl.Font              = Enum.Font.Gotham
	lbl.TextXAlignment    = Enum.TextXAlignment.Left
	lbl.TextTruncate      = Enum.TextTruncate.AtEnd
	lbl.Parent            = row

	local togBg = Instance.new("Frame")
	togBg.Size            = UDim2.new(0, 38, 0, 18)
	togBg.Position        = UDim2.new(1, -46, 0.5, -9)
	togBg.BackgroundColor3 = gunEnabled[gunName] and C.TOGGLE_ON or C.TOGGLE_OFF
	togBg.BorderSizePixel = 0
	togBg.Parent          = row
	corner(9, togBg)

	local knob = Instance.new("Frame")
	knob.Size            = UDim2.new(0, 14, 0, 14)
	knob.Position        = gunEnabled[gunName]
		and UDim2.new(1, -16, 0.5, -7)
		or  UDim2.new(0, 2, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent          = togBg
	corner(7, knob)

	local togBtn = Instance.new("TextButton")
	togBtn.Size               = UDim2.new(1, 0, 1, 0)
	togBtn.BackgroundTransparency = 1
	togBtn.Text               = ""
	togBtn.Parent             = togBg

	togBtn.MouseButton1Click:Connect(function()
		gunEnabled[gunName] = not gunEnabled[gunName]
		local v = gunEnabled[gunName]
		togBg.BackgroundColor3 = v and C.TOGGLE_ON or C.TOGGLE_OFF
		knob.Position = v
			and UDim2.new(1, -16, 0.5, -7)
			or  UDim2.new(0, 2, 0.5, -7)
	end)

	return row
end

local selRow = Instance.new("Frame")
selRow.Size             = UDim2.new(1, 0, 0, 28)
selRow.BackgroundTransparency = 1
selRow.LayoutOrder      = 0
selRow.Parent           = tGuns.page

local function smallBtn(text, xPos, w, col, parent)
	local b = Instance.new("TextButton")
	b.Size             = UDim2.new(0, w, 1, 0)
	b.Position         = UDim2.new(0, xPos, 0, 0)
	b.BackgroundColor3 = col
	b.BorderSizePixel  = 0
	b.Text             = text
	b.TextSize         = 11
	b.TextColor3       = C.TEXT
	b.Font             = Enum.Font.GothamBold
	b.Parent           = parent
	corner(5, b)
	return b
end

local allBtn  = smallBtn("Select All",  0,   90, C.ACCENT2, selRow)
local noneBtn = smallBtn("Select None", 96,  90, C.TOGGLE_OFF, selRow)

local gunKnobs  = {}
local gunTogBgs = {}

for i, g in ipairs(guns) do
	local r = gunRow(g, tGuns.page, i)
		gunTogBgs[g] = r:FindFirstChildOfClass("Frame"):IsA("Frame") and nil
end
for _, ch in ipairs(tGuns.page:GetChildren()) do
	if ch:IsA("Frame") and ch.LayoutOrder >= 1 then ch:Destroy() end
end

local gunTogBgRef = {}
local gunKnobRef  = {}

for i, gunName in ipairs(guns) do
	local row = Instance.new("Frame")
	row.Size             = UDim2.new(1, 0, 0, 30)
	row.BackgroundColor3 = C.INPUT_BG
	row.BorderSizePixel  = 0
	row.LayoutOrder      = i
	row.Parent           = tGuns.page
	corner(6, row)
	stroke(C.STROKE, 1, row)

	local lbl = Instance.new("TextLabel")
	lbl.Size              = UDim2.new(0.7, 0, 1, 0)
	lbl.Position          = UDim2.new(0, 8, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text              = gunName
	lbl.TextSize          = 11
	lbl.TextColor3        = C.TEXT
	lbl.Font              = Enum.Font.Gotham
	lbl.TextXAlignment    = Enum.TextXAlignment.Left
	lbl.TextTruncate      = Enum.TextTruncate.AtEnd
	lbl.Parent            = row

	local togBg = Instance.new("Frame")
	togBg.Size            = UDim2.new(0, 38, 0, 18)
	togBg.Position        = UDim2.new(1, -46, 0.5, -9)
	togBg.BackgroundColor3 = gunEnabled[gunName] and C.TOGGLE_ON or C.TOGGLE_OFF
	togBg.BorderSizePixel = 0
	togBg.Parent          = row
	corner(9, togBg)
	gunTogBgRef[gunName] = togBg

	local knob = Instance.new("Frame")
	knob.Size            = UDim2.new(0, 14, 0, 14)
	knob.Position        = gunEnabled[gunName]
		and UDim2.new(1, -16, 0.5, -7)
		or  UDim2.new(0, 2, 0.5, -7)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent          = togBg
	corner(7, knob)
	gunKnobRef[gunName] = knob

	local togBtn = Instance.new("TextButton")
	togBtn.Size               = UDim2.new(1, 0, 1, 0)
	togBtn.BackgroundTransparency = 1
	togBtn.Text               = ""
	togBtn.Parent             = togBg

	local function refreshGunToggle(gName)
		local v = gunEnabled[gName]
		gunTogBgRef[gName].BackgroundColor3 = v and C.TOGGLE_ON or C.TOGGLE_OFF
		gunKnobRef[gName].Position = v
			and UDim2.new(1, -16, 0.5, -7)
			or  UDim2.new(0, 2, 0.5, -7)
	end

	togBtn.MouseButton1Click:Connect(function()
		gunEnabled[gunName] = not gunEnabled[gunName]
		refreshGunToggle(gunName)
	end)
end

local function refreshAllGunToggles()
	for _, gName in ipairs(guns) do
		local v = gunEnabled[gName]
		if gunTogBgRef[gName] then
			gunTogBgRef[gName].BackgroundColor3 = v and C.TOGGLE_ON or C.TOGGLE_OFF
		end
		if gunKnobRef[gName] then
			gunKnobRef[gName].Position = v
				and UDim2.new(1, -16, 0.5, -7)
				or  UDim2.new(0, 2, 0.5, -7)
		end
	end
end

allBtn.MouseButton1Click:Connect(function()
	for _, g in ipairs(guns) do gunEnabled[g] = true end
	refreshAllGunToggles()
end)
noneBtn.MouseButton1Click:Connect(function()
	for _, g in ipairs(guns) do gunEnabled[g] = false end
	refreshAllGunToggles()
end)

local presets = {
	{
		name = "God Mode",
		desc = "Max dmg, inf ammo, 0 reload",
		apply = function()
			for _, ov in ipairs(overrides) do
				if ov.key == "AmmoPerMag"            then ov.val = 999999 end
				if ov.key == "Damage"                then ov.val = 999999 end
				if ov.key == "DamageThroughWall"     then ov.val = 999999 end
				if ov.key == "LaserTrailDamage"      then ov.val = 999999 end
				if ov.key == "CriticalDamageEnabled" then ov.val = 999999 end
				if ov.key == "Lifesteal"             then ov.val = 99999  end
				if ov.key == "ReloadTime"            then ov.val = 0      end
				if ov.key == "TacticalReloadTime"    then ov.val = 0      end
				if ov.key == "Spread"                then ov.val = 0      end
				if ov.key == "Recoil"                then ov.val = 0      end
				if ov.key == "Range"                 then ov.val = 90000  end
			end
		end
	},
	{
		name = "Silent Aim",
		desc = "0 spread, 0 accuracy deviation",
		apply = function()
			for _, ov in ipairs(overrides) do
				if ov.key == "Spread"    then ov.val = 0 end
				if ov.key == "Accuracy"  then ov.val = 0 end
				if ov.key == "Recoil"    then ov.val = 0 end
				if ov.key == "AngleXMin" then ov.val = 0 end
			end
		end
	},
	{
		name = "Shotgun Spam",
		desc = "High bullet count, fast fire",
		apply = function()
			for _, ov in ipairs(overrides) do
				if ov.key == "BulletsPerShot"      then ov.val = 20   end
				if ov.key == "DelayAfterFiring"    then ov.val = 0    end
				if ov.key == "DelayBeforeFiring"   then ov.val = 0    end
				if ov.key == "BurstRate"           then ov.val = 0    end
				if ov.key == "ReloadTime"          then ov.val = 0    end
				if ov.key == "TacticalReloadTime"  then ov.val = 0    end
				if ov.key == "AmmoPerMag"          then ov.val = 999999 end
				if ov.key == "Auto"                then ov.val = true end
			end
		end
	},
	{
		name = "Vanilla",
		desc = "Resets all values to game defaults",
		apply = function()
			for _, ov in ipairs(overrides) do
				if ov.type == "number" then ov.val = 1  end
				if ov.type == "bool"   then ov.val = false end
			end
		end
	},
}

sectionHeader("Quick Presets", tPresets.page).LayoutOrder = 0

for i, preset in ipairs(presets) do
	local card = Instance.new("Frame")
	card.Size             = UDim2.new(1, 0, 0, 56)
	card.BackgroundColor3 = C.INPUT_BG
	card.BorderSizePixel  = 0
	card.LayoutOrder      = i
	card.Parent           = tPresets.page
	corner(8, card)
	stroke(C.STROKE, 1, card)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size              = UDim2.new(0.65, 0, 0, 20)
	nameLbl.Position          = UDim2.new(0, 10, 0, 8)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text              = preset.name
	nameLbl.TextSize          = 12
	nameLbl.TextColor3        = C.TEXT
	nameLbl.Font              = Enum.Font.GothamBold
	nameLbl.TextXAlignment    = Enum.TextXAlignment.Left
	nameLbl.Parent            = card

	local descLbl = Instance.new("TextLabel")
	descLbl.Size              = UDim2.new(0.65, 0, 0, 16)
	descLbl.Position          = UDim2.new(0, 10, 0, 30)
	descLbl.BackgroundTransparency = 1
	descLbl.Text              = preset.desc
	descLbl.TextSize          = 10
	descLbl.TextColor3        = C.SUBTEXT
	descLbl.Font              = Enum.Font.Gotham
	descLbl.TextXAlignment    = Enum.TextXAlignment.Left
	descLbl.Parent            = card

	local applyBtn = Instance.new("TextButton")
	applyBtn.Size             = UDim2.new(0, 80, 0, 28)
	applyBtn.Position         = UDim2.new(1, -90, 0.5, -14)
	applyBtn.BackgroundColor3 = C.ACCENT2
	applyBtn.BorderSizePixel  = 0
	applyBtn.Text             = "Load"
	applyBtn.TextSize         = 12
	applyBtn.TextColor3       = C.TEXT
	applyBtn.Font             = Enum.Font.GothamBold
	applyBtn.Parent           = card
	corner(6, applyBtn)

	applyBtn.MouseButton1Click:Connect(function()
		preset.apply()
		applyOverrides()
		applyBtn.Text             = "✓ Applied"
		applyBtn.BackgroundColor3 = C.GREEN
		task.delay(1.5, function()
			applyBtn.Text             = "Load"
			applyBtn.BackgroundColor3 = C.ACCENT2
		end)
				for _, child in ipairs(tOverrides.page:GetChildren()) do
			if child:IsA("Frame") then
				local box = child:FindFirstChildOfClass("TextBox")
				if box then
					for _, ov in ipairs(overrides) do
						if ov.type == "number" then
														local lbl2 = child:FindFirstChildOfClass("TextLabel")
							if lbl2 and lbl2.Text == ov.key then
								box.Text = tostring(ov.val)
							end
						end
					end
				end
			end
		end
	end)
end

local BottomBar = Instance.new("Frame")
BottomBar.Name             = "BottomBar"
BottomBar.Size             = UDim2.new(1, -16, 0, 34)
BottomBar.Position         = UDim2.new(0, 8, 1, -42)
BottomBar.BackgroundTransparency = 1
BottomBar.Parent           = MainFrame

local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Size             = UDim2.new(0.6, -4, 1, 0)
ApplyBtn.Position         = UDim2.new(0, 0, 0, 0)
ApplyBtn.BackgroundColor3 = C.ACCENT
ApplyBtn.BorderSizePixel  = 0
ApplyBtn.Text             = "▶  Apply Overrides"
ApplyBtn.TextSize         = 13
ApplyBtn.TextColor3       = C.TEXT
ApplyBtn.Font             = Enum.Font.GothamBold
ApplyBtn.Parent           = BottomBar
corner(7, ApplyBtn)

local ResetBtn = Instance.new("TextButton")
ResetBtn.Size             = UDim2.new(0.4, -4, 1, 0)
ResetBtn.Position         = UDim2.new(0.6, 4, 0, 0)
ResetBtn.BackgroundColor3 = C.TOGGLE_OFF
ResetBtn.BorderSizePixel  = 0
ResetBtn.Text             = "↺  Reset All"
ResetBtn.TextSize         = 12
ResetBtn.TextColor3       = C.TEXT
ResetBtn.Font             = Enum.Font.GothamBold
ResetBtn.Parent           = BottomBar
corner(7, ResetBtn)

ApplyBtn.MouseButton1Click:Connect(function()
	applyOverrides()
	ApplyBtn.Text             = "✓  Applied!"
	ApplyBtn.BackgroundColor3 = C.GREEN
	task.delay(1.5, function()
		ApplyBtn.Text             = "▶  Apply Overrides"
		ApplyBtn.BackgroundColor3 = C.ACCENT
	end)
end)

ResetBtn.MouseButton1Click:Connect(function()
	for _, ov in ipairs(overrides) do
		if ov.type == "number" then ov.val = 0 end
		if ov.type == "bool"   then ov.val = false end
	end
		for _, child in ipairs(tOverrides.page:GetChildren()) do
		if child:IsA("Frame") then
			local box = child:FindFirstChildOfClass("TextBox")
			local lbl2 = child:FindFirstChildOfClass("TextLabel")
			if box and lbl2 then
				for _, ov in ipairs(overrides) do
					if lbl2.Text == ov.key then
						box.Text = tostring(ov.val)
					end
				end
			end
		end
	end
	ResetBtn.Text             = "✓  Reset!"
	ResetBtn.BackgroundColor3 = C.RED
	task.delay(1.5, function()
		ResetBtn.Text             = "↺  Reset All"
		ResetBtn.BackgroundColor3 = C.TOGGLE_OFF
	end)
end)

print("[GunOverride] GUI loaded ✓")
