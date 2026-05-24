local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local plr = Players.LocalPlayer
local playerGui = plr:WaitForChild("PlayerGui")
local workspace = game:GetService("Workspace")
local CFG = {
	Title = "Bosses",
	RefreshRate = 1.5,
	PanelW = 310,
	ItemHeight = 48,
	MaxVisible = 7,
	ToggleKey = Enum.KeyCode.RightBracket,
	AttachOffset = CFrame.new(0, 0, 4),
	AccentColor = Color3.fromRGB(220, 60, 60),
	BgColor = Color3.fromRGB(18, 18, 22),
	SurfaceColor = Color3.fromRGB(26, 26, 32),
	TextColor = Color3.fromRGB(240, 240, 240),
	SubTextColor = Color3.fromRGB(140, 140, 155),
	BorderColor = Color3.fromRGB(50, 50, 62),
	BtnTP = Color3.fromRGB(40, 110, 210),
	BtnAttach = Color3.fromRGB(30, 150, 90),
	BtnAttachON = Color3.fromRGB(220, 140, 20),
	BtnIgnore = Color3.fromRGB(70, 70, 85),
	BtnIgnoreON = Color3.fromRGB(120, 35, 35),
	HpBarFull = Color3.fromRGB(60, 200, 80),
	HpBarMid = Color3.fromRGB(220, 180, 30),
	HpBarLow = Color3.fromRGB(220, 50, 50),
	HpBarBg = Color3.fromRGB(38, 20, 20),
	EspFill = Color3.fromRGB(220, 60, 60),
	EspOutline = Color3.fromRGB(255, 255, 255),
	IgnoreSurface = Color3.fromRGB(38, 22, 22),
}
_G._bossPanelAttachConn = _G._bossPanelAttachConn or nil
_G._bossPanelAttachTarget = _G._bossPanelAttachTarget or nil
_G._bossPanelReattachName = _G._bossPanelReattachName or nil
local ignoredSet = {}
local espHighlights = {}
local espEnabled = false
local sortByDist = false
local searchQuery = ""
local isOpen = false
local guiVisible = true
local activeAttachBtn = nil
local function notify(msg, dur)
	if getgenv and getgenv().DoNotif then
		pcall(getgenv().DoNotif, msg, dur or 3)
	end
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
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, CFG.PanelW, 0, 40)
MainFrame.Position = UDim2.new(0, 24, 0, 24)
MainFrame.BackgroundColor3 = CFG.BgColor
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = MainFrame
	local s = Instance.new("UIStroke")
	s.Color = CFG.BorderColor
	s.Thickness = 1
	s.Parent = MainFrame
end
local AccentBar = Instance.new("Frame")
AccentBar.Size = UDim2.new(0, 3, 1, 0)
AccentBar.BackgroundColor3 = CFG.AccentColor
AccentBar.BorderSizePixel = 0
AccentBar.ZIndex = 2
AccentBar.Parent = MainFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = AccentBar
end
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1
Header.ZIndex = 3
Header.Parent = MainFrame
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -110, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "  " .. CFG.Title
TitleLabel.TextColor3 = CFG.TextColor
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 13
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 4
TitleLabel.Parent = Header
local EspHeaderBtn = Instance.new("TextButton")
EspHeaderBtn.Size = UDim2.new(0, 34, 0, 20)
EspHeaderBtn.Position = UDim2.new(1, -110, 0.5, -10)
EspHeaderBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
EspHeaderBtn.Text = "ESP"
EspHeaderBtn.TextColor3 = CFG.SubTextColor
EspHeaderBtn.Font = Enum.Font.GothamBold
EspHeaderBtn.TextSize = 10
EspHeaderBtn.BorderSizePixel = 0
EspHeaderBtn.ZIndex = 6
EspHeaderBtn.Parent = Header
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = EspHeaderBtn
end
local SortHeaderBtn = Instance.new("TextButton")
SortHeaderBtn.Size = UDim2.new(0, 34, 0, 20)
SortHeaderBtn.Position = UDim2.new(1, -72, 0.5, -10)
SortHeaderBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
SortHeaderBtn.Text = "DST"
SortHeaderBtn.TextColor3 = CFG.SubTextColor
SortHeaderBtn.Font = Enum.Font.GothamBold
SortHeaderBtn.TextSize = 10
SortHeaderBtn.BorderSizePixel = 0
SortHeaderBtn.ZIndex = 6
SortHeaderBtn.Parent = Header
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = SortHeaderBtn
end
local CountBadge = Instance.new("TextLabel")
CountBadge.Size = UDim2.new(0, 24, 0, 18)
CountBadge.Position = UDim2.new(1, -52, 0.5, -9)
CountBadge.BackgroundColor3 = CFG.AccentColor
CountBadge.Text = "0"
CountBadge.TextColor3 = Color3.new(1, 1, 1)
CountBadge.Font = Enum.Font.GothamBold
CountBadge.TextSize = 10
CountBadge.ZIndex = 4
CountBadge.Parent = Header
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = CountBadge
end
local Chevron = Instance.new("TextLabel")
Chevron.Size = UDim2.new(0, 24, 0, 24)
Chevron.Position = UDim2.new(1, -30, 0.5, -12)
Chevron.BackgroundTransparency = 1
Chevron.Text = ""
Chevron.TextColor3 = CFG.SubTextColor
Chevron.Font = Enum.Font.GothamBold
Chevron.TextSize = 11
Chevron.ZIndex = 4
Chevron.Parent = Header
local SearchBar = Instance.new("Frame")
SearchBar.Name = "SearchBar"
SearchBar.Size = UDim2.new(1, -12, 0, 26)
SearchBar.Position = UDim2.new(0, 6, 0, 41)
SearchBar.BackgroundColor3 = Color3.fromRGB(32, 32, 40)
SearchBar.BorderSizePixel = 0
SearchBar.ZIndex = 3
SearchBar.Visible = false
SearchBar.Parent = MainFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 5)
	c.Parent = SearchBar
	local s = Instance.new("UIStroke")
	s.Color = CFG.BorderColor
	s.Thickness = 1
	s.Parent = SearchBar
end
local SearchIcon = Instance.new("TextLabel")
SearchIcon.Size = UDim2.new(0, 22, 1, 0)
SearchIcon.Position = UDim2.new(0, 4, 0, 0)
SearchIcon.BackgroundTransparency = 1
SearchIcon.Text = ""
SearchIcon.TextSize = 11
SearchIcon.Font = Enum.Font.Gotham
SearchIcon.ZIndex = 4
SearchIcon.Parent = SearchBar
local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -30, 1, 0)
SearchBox.Position = UDim2.new(0, 24, 0, 0)
SearchBox.BackgroundTransparency = 1
SearchBox.PlaceholderText = "Search bosses..."
SearchBox.PlaceholderColor3 = CFG.SubTextColor
SearchBox.Text = ""
SearchBox.TextColor3 = CFG.TextColor
SearchBox.Font = Enum.Font.Gotham
SearchBox.TextSize = 11
SearchBox.TextXAlignment = Enum.TextXAlignment.Left
SearchBox.ClearTextOnFocus = false
SearchBox.ZIndex = 5
SearchBox.Parent = SearchBar
local Separator = Instance.new("Frame")
Separator.Name = "Separator"
Separator.Size = UDim2.new(1, -14, 0, 1)
Separator.Position = UDim2.new(0, 7, 0, 40)
Separator.BackgroundColor3 = CFG.BorderColor
Separator.BorderSizePixel = 0
Separator.ZIndex = 3
Separator.Parent = MainFrame
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
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
local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 4)
ListPadding.PaddingBottom = UDim.new(0, 4)
ListPadding.PaddingLeft = UDim.new(0, 6)
ListPadding.PaddingRight = UDim.new(0, 6)
ListPadding.Parent = ScrollFrame
local IgnoreSep = Instance.new("Frame")
IgnoreSep.Name = "IgnoreSep"
IgnoreSep.Size = UDim2.new(1, -14, 0, 1)
IgnoreSep.BackgroundColor3 = CFG.BorderColor
IgnoreSep.BorderSizePixel = 0
IgnoreSep.ZIndex = 3
IgnoreSep.Visible = false
IgnoreSep.Parent = MainFrame
local IgnoreHeader = Instance.new("Frame")
IgnoreHeader.Name = "IgnoreHeader"
IgnoreHeader.Size = UDim2.new(1, 0, 0, 28)
IgnoreHeader.BackgroundTransparency = 1
IgnoreHeader.ZIndex = 3
IgnoreHeader.Visible = false
IgnoreHeader.Parent = MainFrame
local IgnoreTitle = Instance.new("TextLabel")
IgnoreTitle.Size = UDim2.new(1, -80, 1, 0)
IgnoreTitle.Position = UDim2.new(0, 14, 0, 0)
IgnoreTitle.BackgroundTransparency = 1
IgnoreTitle.Text = "  Ignored"
IgnoreTitle.TextColor3 = CFG.SubTextColor
IgnoreTitle.Font = Enum.Font.GothamBold
IgnoreTitle.TextSize = 11
IgnoreTitle.TextXAlignment = Enum.TextXAlignment.Left
IgnoreTitle.ZIndex = 4
IgnoreTitle.Parent = IgnoreHeader
local ClearAllBtn = Instance.new("TextButton")
ClearAllBtn.Size = UDim2.new(0, 60, 0, 18)
ClearAllBtn.Position = UDim2.new(1, -68, 0.5, -9)
ClearAllBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
ClearAllBtn.Text = "Clear All"
ClearAllBtn.TextColor3 = Color3.fromRGB(230, 150, 150)
ClearAllBtn.Font = Enum.Font.GothamBold
ClearAllBtn.TextSize = 9
ClearAllBtn.BorderSizePixel = 0
ClearAllBtn.ZIndex = 5
ClearAllBtn.Parent = IgnoreHeader
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 4)
	c.Parent = ClearAllBtn
end
local IgnoreScroll = Instance.new("ScrollingFrame")
IgnoreScroll.Name = "IgnoreScroll"
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
local IgnorePadding = Instance.new("UIPadding")
IgnorePadding.PaddingTop = UDim.new(0, 2)
IgnorePadding.PaddingBottom = UDim.new(0, 4)
IgnorePadding.PaddingLeft = UDim.new(0, 6)
IgnorePadding.PaddingRight = UDim.new(0, 6)
IgnorePadding.Parent = IgnoreScroll
local function getRootPart(obj)
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
local function addEsp(bossObj)
	local name = bossObj.Name
	if espHighlights[name] then
		return
	end
	local h = Instance.new("Highlight")
	h.Name = "_BossPanelESP"
	h.FillColor = CFG.EspFill
	h.OutlineColor = CFG.EspOutline
	h.FillTransparency = 0.55
	h.OutlineTransparency = 0
	h.Adornee = bossObj
	h.Parent = bossObj
	espHighlights[name] = h
end
local function removeEsp(name)
	if espHighlights[name] then
		pcall(function()
			espHighlights[name]:Destroy()
		end)
		espHighlights[name] = nil
	end
end
local function clearAllEsp()
	for name, _ in pairs(espHighlights) do
		removeEsp(name)
	end
end
local function syncEsp(children)
	if not espEnabled then
		clearAllEsp()
		return
	end
	local existingNames = {}
	for _, child in ipairs(children) do
		existingNames[child.Name] = child
	end
	for name, _ in pairs(espHighlights) do
		if not existingNames[name] then
			removeEsp(name)
		end
	end
	for _, child in ipairs(children) do
		if not ignoredSet[child.Name] then
			addEsp(child)
		else
			removeEsp(child.Name)
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
local function startAttach(targetRoot)
	stopAttach()
	_G._bossPanelAttachTarget = targetRoot
	_G._bossPanelAttachConn = RunService.Heartbeat:Connect(function()
		local char = plr.Character
		local myHRP = char and char:FindFirstChild("HumanoidRootPart")
		if not myHRP or not targetRoot or not targetRoot.Parent then
			stopAttach()
			return
		end
		pcall(function()
			myHRP.CFrame = targetRoot.CFrame * CFG.AttachOffset
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
local reattachWatchConn = nil
local function startReattachWatch(bossName)
	_G._bossPanelReattachName = bossName
	if reattachWatchConn then
		pcall(function()
			reattachWatchConn:Disconnect()
		end)
	end
	local bossesFolder = workspace:FindFirstChild("Bosses")
	if not bossesFolder then
		return
	end
	reattachWatchConn = bossesFolder.ChildAdded:Connect(function(child)
		if child.Name == _G._bossPanelReattachName then
			task.wait(0.2)
			local root = getRootPart(child)
			if root then
				startAttach(root)
				notify("Re-attached → " .. child.Name, 3)
			end
		end
	end)
end
local function stopReattachWatch()
	_G._bossPanelReattachName = nil
	if reattachWatchConn then
		pcall(function()
			reattachWatchConn:Disconnect()
		end)
		reattachWatchConn = nil
	end
end
local function makeBtn(parent, text, bgColor, xOffset, width, zIndex)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, width, 0, 20)
	btn.Position = UDim2.new(1, xOffset, 0, 6)
	btn.BackgroundColor3 = bgColor
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 9
	btn.BorderSizePixel = 0
	btn.ZIndex = zIndex or 6
	btn.Parent = parent
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = btn
	end
	return btn
end
local currentItems = {}
local function makeItem(bossObj, layoutOrder)
	local name = bossObj.Name
	local isIgnored = ignoredSet[name] == true
	local humanoid = getHumanoid(bossObj)
	local root = getRootPart(bossObj)
	local hp = humanoid and humanoid.Health or 0
	local maxHp = humanoid and humanoid.MaxHealth or 0
	local hpRatio = (maxHp > 0) and math.clamp(hp / maxHp, 0, 1) or 0
	local dist = root and getDistance(root) or 0
	local row = Instance.new("Frame")
	row.Name = "Item_" .. name
	row.Size = UDim2.new(1, 0, 0, CFG.ItemHeight)
	row.BackgroundColor3 = isIgnored and CFG.IgnoreSurface or CFG.SurfaceColor
	row.BorderSizePixel = 0
	row.ZIndex = 4
	row.LayoutOrder = layoutOrder or 0
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent = row
	end
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 6, 0, 6)
	dot.Position = UDim2.new(0, 8, 0, 9)
	dot.BackgroundColor3 = isIgnored and Color3.fromRGB(100, 40, 40) or CFG.AccentColor
	dot.BorderSizePixel = 0
	dot.ZIndex = 5
	dot.Parent = row
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = dot
	end
	local nameLabel = Instance.new("TextButton")
	nameLabel.Size = UDim2.new(1, -170, 0, 20)
	nameLabel.Position = UDim2.new(0, 20, 0, 4)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = isIgnored and CFG.SubTextColor or CFG.TextColor
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 11
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 6
	nameLabel.Parent = row
	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(0, 50, 0, 14)
	distLabel.Position = UDim2.new(0, 20, 0, 24)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = root and (tostring(dist) .. " st") or "N/A"
	distLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
	distLabel.Font = Enum.Font.Gotham
	distLabel.TextSize = 9
	distLabel.TextXAlignment = Enum.TextXAlignment.Left
	distLabel.ZIndex = 5
	distLabel.Parent = row
	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(1, -175, 0, 5)
	hpBg.Position = UDim2.new(0, 75, 0, 28)
	hpBg.BackgroundColor3 = CFG.HpBarBg
	hpBg.BorderSizePixel = 0
	hpBg.ZIndex = 5
	hpBg.Parent = row
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = hpBg
	end
	local hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.new(hpRatio, 0, 1, 0)
	hpFill.BackgroundColor3 = humanoid and getHpColor(hpRatio) or CFG.SubTextColor
	hpFill.BorderSizePixel = 0
	hpFill.ZIndex = 6
	hpFill.Parent = hpBg
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = hpFill
	end
	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(0, 70, 0, 12)
	hpLabel.Position = UDim2.new(0, 75, 0, 14)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = humanoid and (math.floor(hp) .. "/" .. math.floor(maxHp)) or "No Humanoid"
	hpLabel.TextColor3 = humanoid and getHpColor(hpRatio) or CFG.SubTextColor
	hpLabel.Font = Enum.Font.Gotham
	hpLabel.TextSize = 9
	hpLabel.TextXAlignment = Enum.TextXAlignment.Left
	hpLabel.ZIndex = 5
	hpLabel.Parent = row
	local tpBtn = makeBtn(row, "TP", CFG.BtnTP, -160, 34, 6)
	local attBtn = makeBtn(row, "ATT", CFG.BtnAttach, -122, 36, 6)
	local ignBtn =
		makeBtn(row, isIgnored and "UNIGN" or "IGN", isIgnored and CFG.BtnIgnoreON or CFG.BtnIgnore, -82, 44, 6)
	tpBtn.Position = UDim2.new(1, -160, 0.5, -10)
	attBtn.Position = UDim2.new(1, -122, 0.5, -10)
	ignBtn.Position = UDim2.new(1, -82, 0.5, -10)
	if _G._bossPanelAttachTarget and root and _G._bossPanelAttachTarget == root then
		attBtn.BackgroundColor3 = CFG.BtnAttachON
		attBtn.Text = "STOP"
		activeAttachBtn = attBtn
	end
	local tweenIn = TweenService:Create(row, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(38, 38, 50) })
	local tweenOut = TweenService:Create(
		row,
		TweenInfo.new(0.1),
		{ BackgroundColor3 = isIgnored and CFG.IgnoreSurface or CFG.SurfaceColor }
	)
	row.MouseEnter:Connect(function()
		if not isIgnored then
			tweenIn:Play()
		end
	end)
	row.MouseLeave:Connect(function()
		tweenOut:Play()
	end)
	nameLabel.MouseButton1Click:Connect(function()
		if ignoredSet[name] then
			return
		end
		local r = getRootPart(bossObj)
		if r then
			doTP(r)
			notify("TP → " .. name, 2)
		end
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
			startAttach(r)
			startReattachWatch(name)
			attBtn.BackgroundColor3 = CFG.BtnAttachON
			attBtn.Text = "STOP"
			activeAttachBtn = attBtn
			notify("Attaching → " .. name, 3)
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
		getfenv().refreshAll()
	end)
	return row
end
local function makeIgnoreRow(name)
	local row = Instance.new("Frame")
	row.Name = "IGN_" .. name
	row.Size = UDim2.new(1, 0, 0, 24)
	row.BackgroundColor3 = Color3.fromRGB(38, 22, 22)
	row.BorderSizePixel = 0
	row.ZIndex = 4
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 5)
		c.Parent = row
	end
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -60, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = " " .. name
	lbl.TextColor3 = Color3.fromRGB(200, 100, 100)
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.ZIndex = 5
	lbl.Parent = row
	local unignBtn = Instance.new("TextButton")
	unignBtn.Size = UDim2.new(0, 44, 0, 16)
	unignBtn.Position = UDim2.new(1, -50, 0.5, -8)
	unignBtn.BackgroundColor3 = Color3.fromRGB(60, 35, 35)
	unignBtn.Text = "Unign"
	unignBtn.TextColor3 = Color3.fromRGB(240, 160, 160)
	unignBtn.Font = Enum.Font.GothamBold
	unignBtn.TextSize = 9
	unignBtn.BorderSizePixel = 0
	unignBtn.ZIndex = 6
	unignBtn.Parent = row
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent = unignBtn
	end
	unignBtn.MouseButton1Click:Connect(function()
		ignoredSet[name] = nil
		getfenv().refreshAll()
	end)
	return row
end
local HEADER_H = 40
local SEARCH_H = 30
local SEP_H = 1
local function getListTop()
	return HEADER_H + SEP_H + (isOpen and SEARCH_H or 0)
end
local function refreshAll()
	local bossesFolder = workspace:FindFirstChild("Bosses")
	for _, child in ipairs(ScrollFrame:GetChildren()) do
		if child:IsA("Frame") or (child:IsA("TextLabel") and child.Name == "Item_EMPTY") then
			child:Destroy()
		end
	end
	currentItems = {}
	for _, child in ipairs(IgnoreScroll:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	if not bossesFolder then
		CountBadge.Text = "!"
		CountBadge.BackgroundColor3 = Color3.fromRGB(180, 80, 40)
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Item_EMPTY"
		lbl.Size = UDim2.new(1, 0, 0, CFG.ItemHeight)
		lbl.BackgroundTransparency = 1
		lbl.Text = "workspace.Bosses not found"
		lbl.TextColor3 = CFG.SubTextColor
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 11
		lbl.ZIndex = 4
		lbl.Parent = ScrollFrame
		table.insert(currentItems, lbl)
		IgnoreSep.Visible = false
		IgnoreHeader.Visible = false
		IgnoreScroll.Visible = false
		return
	end
	CountBadge.BackgroundColor3 = CFG.AccentColor
	local children = bossesFolder:GetChildren()
	syncEsp(children)
	local filtered = {}
	local q = searchQuery:lower()
	for _, child in ipairs(children) do
		if q == "" or child.Name:lower():find(q, 1, true) then
			table.insert(filtered, child)
		end
	end
	if sortByDist then
		table.sort(filtered, function(a, b)
			local ra, rb = getRootPart(a), getRootPart(b)
			return getDistance(ra) < getDistance(rb)
		end)
	else
		table.sort(filtered, function(a, b)
			return a.Name < b.Name
		end)
	end
	CountBadge.Text = tostring(#children)
	if #filtered == 0 then
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Item_EMPTY"
		lbl.Size = UDim2.new(1, 0, 0, CFG.ItemHeight)
		lbl.BackgroundTransparency = 1
		lbl.Text = #children == 0 and "No bosses found" or "No results"
		lbl.TextColor3 = CFG.SubTextColor
		lbl.Font = Enum.Font.Gotham
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
	for k, _ in pairs(ignoredSet) do
		table.insert(ignoredNames, k)
	end
	table.sort(ignoredNames)
	local hasIgnored = #ignoredNames > 0
	IgnoreSep.Visible = hasIgnored
	IgnoreHeader.Visible = hasIgnored
	IgnoreScroll.Visible = hasIgnored
	for _, n in ipairs(ignoredNames) do
		local r = makeIgnoreRow(n)
		r.Parent = IgnoreScroll
	end
end
getfenv().refreshAll = refreshAll
local function updatePanelHeight()
	local listTop = getListTop()
	local contentH = ListLayout.AbsoluteContentSize.Y + 8
	local cappedH = math.min(contentH, CFG.ItemHeight * CFG.MaxVisible + 8)
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, contentH)
	ScrollFrame.Position = UDim2.new(0, 0, 0, listTop)
	SearchBar.Visible = isOpen
	SearchBar.Position = UDim2.new(0, 6, 0, HEADER_H + 5)
	local ignContentH = IgnoreLayout.AbsoluteContentSize.Y + 6
	local ignCapped = math.min(ignContentH, 24 * 4 + 6)
	IgnoreScroll.CanvasSize = UDim2.new(0, 0, 0, ignContentH)
	local hasIgnored = IgnoreScroll.Visible
	local ignBlockH = hasIgnored and (SEP_H + 28 + ignCapped) or 0
	if isOpen then
		TweenService:Create(ScrollFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 0, cappedH),
		}):Play()
	else
		ScrollFrame.Size = UDim2.new(1, 0, 0, 0)
	end
	local totalH = isOpen and (listTop + cappedH + ignBlockH) or HEADER_H
	local ignY = listTop + cappedH
	IgnoreSep.Position = UDim2.new(0, 7, 0, ignY)
	IgnoreHeader.Position = UDim2.new(0, 0, 0, ignY + SEP_H)
	IgnoreScroll.Position = UDim2.new(0, 0, 0, ignY + SEP_H + 28)
	IgnoreScroll.Size = UDim2.new(1, 0, 0, ignCapped)
	TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, CFG.PanelW, 0, totalH),
	}):Play()
end
local function togglePanel()
	isOpen = not isOpen
	Chevron.Text = isOpen and "" or ""
	if isOpen then
		refreshAll()
	end
	updatePanelHeight()
end
local headerBtn = Instance.new("TextButton")
headerBtn.Size = UDim2.new(1, -120, 0, 40)
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
	if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
		local d = inp.Position - dragStart
		MainFrame.Position =
			UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
EspHeaderBtn.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	EspHeaderBtn.BackgroundColor3 = espEnabled and CFG.AccentColor or Color3.fromRGB(50, 50, 65)
	EspHeaderBtn.TextColor3 = espEnabled and Color3.new(1, 1, 1) or CFG.SubTextColor
	if not espEnabled then
		clearAllEsp()
	else
		local bossesFolder = workspace:FindFirstChild("Bosses")
		if bossesFolder then
			syncEsp(bossesFolder:GetChildren())
		end
	end
	notify("ESP: " .. (espEnabled and "ON" or "OFF"), 2)
end)
SortHeaderBtn.MouseButton1Click:Connect(function()
	sortByDist = not sortByDist
	SortHeaderBtn.BackgroundColor3 = sortByDist and Color3.fromRGB(40, 110, 200) or Color3.fromRGB(50, 50, 65)
	SortHeaderBtn.TextColor3 = sortByDist and Color3.new(1, 1, 1) or CFG.SubTextColor
	if isOpen then
		refreshAll()
		updatePanelHeight()
	end
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
		guiVisible = not guiVisible
		MainFrame.Visible = guiVisible
		notify("BossPanel: " .. (guiVisible and "SHOWN" or "HIDDEN"), 1)
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
refreshAll()
print(string.format("open panel to expand", tostring(CFG.ToggleKey.Name)))
