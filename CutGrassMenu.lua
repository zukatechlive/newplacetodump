

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui          = game:GetService("CoreGui")

local LP = Players.LocalPlayer


-- 1. CONFIG

local MODS = {
    ["AnimationTime"] = 1.2,
    ["BaseArea"]      = 60.118, -- can be higher
    ["BaseCooldown"]  = 0,         
    ["SizePercent"]   = 527, -- might not work
}

local ANIMATIONS = {
    ["Guitar"]   = "rbxassetid://102567168912846",
    ["Spear"]    = "rbxassetid://117059598094471",
    ["Chainsaw"] = "rbxassetid://132847207376843",
    ["Sword"]    = "rbxassetid://106887855409061",
    ["Dual"]      = "rbxassetid://109120352590655",
}

local RAPID_HIT_WINDOW = 0.15 -- i have no idea what these do tbh
local RAPID_FIRE_RATE  = 0.05   -- swing speed slider target

-- Slider ranges
local ANIM_TIME_MIN, ANIM_TIME_MAX = 0.1, 3.0
local SWING_SPEED_MIN, SWING_SPEED_MAX = 0.02, 0.5


local Mode        = "Reliable"
local rapidOn     = false
local Event       = nil
local CurrentTool = nil
local currentAnim = "Guitar"




local function ApplyToTool(Tool)
    if not Tool:IsA("Tool") then return end
    CurrentTool = Tool

    for Name, Value in pairs(MODS) do
        Tool:SetAttribute(Name, Value)
    end
    Tool:SetAttribute("AnimationId", ANIMATIONS[currentAnim] or ANIMATIONS["Guitar"])

    local WS = Tool:FindFirstChild("WeaponLocalScript")
    if WS then
        WS.Disabled = true
        task.wait(0.01)
        WS.Disabled = false
    end

    Event = Tool:FindFirstChild("WeaponSwingEvent")
end

-- unreliable tbh 
local function doRapidSwing()
    if not Event then return end
    Event:FireServer("SwingStart")
    Event:FireServer("HitboxStart")
    task.wait(RAPID_HIT_WINDOW)
    Event:FireServer("HitboxEnd")
    Event:FireServer("SwingEnd")
end

RunService.RenderStepped:Connect(function()
    if rapidOn and Mode == "Rapid" and Event then
        doRapidSwing()
        task.wait(RAPID_FIRE_RATE)
    end
end)


UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        Mode = (Mode == "Reliable") and "Rapid" or "Reliable"
        rapidOn = false
        print(("[+] Mode: %s"):format(Mode))
    elseif input.KeyCode == Enum.KeyCode.G then
        if Mode ~= "Rapid" then
            print("[!] Switch to Rapid mode first (F).")
            return
        end
        rapidOn = not rapidOn
        print(rapidOn and "[+] Rapid loop ON" or "[-] Rapid loop OFF")
    end
end)


local function createSlider(parent, yPos, label, min, max, default, onChanged)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -16, 0, 20)
    lbl.Position = UDim2.new(0, 8, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(180, 180, 190)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -16, 0, 6)
    track.Position = UDim2.new(0, 8, 0, yPos + 22)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    track.BorderSizePixel = 0
    track.Parent = parent

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(60, 140, 90)
    fill.BorderSizePixel = 0
    fill.Parent = track

    local handle = Instance.new("Frame")
    handle.Size = UDim2.new(0, 12, 0, 12)
    handle.Position = UDim2.new(0, 0, 0.5, -6)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.BorderSizePixel = 0
    handle.Parent = track

    local value = default
    local dragging = false

    local function updateFromMouse(x)
        local trackWidth = track.AbsoluteSize.X
        local localX = math.clamp(x - track.AbsolutePosition.X, 0, trackWidth)
        local frac = localX / trackWidth
        value = min + (max - min) * frac
        fill.Size = UDim2.new(frac, 0, 1, 0)
        handle.Position = UDim2.new(frac, -6, 0.5, -6)
        onChanged(value)
    end

    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromMouse(i.Position.X)
        end
    end)
    handle.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    handle.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse(i.Position.X)
        end
    end)

    -- Also allow clicking directly on the track
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromMouse(i.Position.X)
        end
    end)
    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    track.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse(i.Position.X)
        end
    end)

    -- Initialize fill/handle position to default
    local initFrac = (default - min) / (max - min)
    fill.Size = UDim2.new(initFrac, 0, 1, 0)
    handle.Position = UDim2.new(initFrac, -6, 0.5, -6)

    return function(newVal)
        value = newVal
        local frac = (value - min) / (max - min)
        fill.Size = UDim2.new(frac, 0, 1, 0)
        handle.Position = UDim2.new(frac, -6, 0.5, -6)
    end
end


-- 7. OVERHAULED GUI
-- Zuka Tech-inspired dark UI. Gameplay/config logic above remains unchanged.

local THEME = {
    BG          = Color3.fromRGB(13, 14, 18),
    PANEL       = Color3.fromRGB(19, 20, 26),
    PANEL2      = Color3.fromRGB(24, 25, 32),
    CARD        = Color3.fromRGB(28, 29, 37),
    CARD_HOVER  = Color3.fromRGB(34, 35, 44),
    STROKE      = Color3.fromRGB(48, 50, 62),
    TEXT        = Color3.fromRGB(242, 243, 247),
    MUTED       = Color3.fromRGB(148, 151, 163),
    DIM         = Color3.fromRGB(100, 103, 115),
    ACCENT      = Color3.fromRGB(153, 0, 0),
    ACCENT2     = Color3.fromRGB(190, 20, 20),
    ACCENT_DARK  = Color3.fromRGB(75, 12, 16),
    GOOD        = Color3.fromRGB(65, 180, 105),
    WARN        = Color3.fromRGB(190, 135, 55),
}

local function corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or THEME.STROKE
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.Parent = obj
    return s
end

local function label(parent, text, size, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or THEME.TEXT
    l.Font = font or Enum.Font.Gotham
    l.TextSize = size or 13
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ConfigGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui or LP.PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 390, 0, 560)
Main.Position = UDim2.new(0, 24, 0, 70)
Main.BackgroundColor3 = THEME.BG
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui
corner(Main, 12)
stroke(Main, THEME.STROKE, 1)

-- Top accent line
local AccentLine = Instance.new("Frame")
AccentLine.Size = UDim2.new(1, 0, 0, 2)
AccentLine.BackgroundColor3 = THEME.ACCENT
AccentLine.BorderSizePixel = 0
AccentLine.Parent = Main

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 58)
TitleBar.Position = UDim2.new(0, 0, 0, 2)
TitleBar.BackgroundColor3 = THEME.PANEL
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local Title = label(TitleBar, "MELEE CONFIG", 16, THEME.TEXT, Enum.Font.GothamBold)
Title.Position = UDim2.new(0, 18, 0, 8)
Title.Size = UDim2.new(1, -100, 0, 22)

local Subtitle = label(TitleBar, "ZUKA TECH  //  WEAPON CONTROL", 9, THEME.MUTED, Enum.Font.GothamMedium)
Subtitle.Position = UDim2.new(0, 19, 0, 31)
Subtitle.Size = UDim2.new(1, -100, 0, 16)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0, 13)
CloseBtn.BackgroundColor3 = THEME.CARD
CloseBtn.Text = "×"
CloseBtn.TextColor3 = THEME.MUTED
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 20
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TitleBar
corner(CloseBtn, 8)

local closeStroke = stroke(CloseBtn, THEME.STROKE, 1)
CloseBtn.MouseEnter:Connect(function()
    CloseBtn.BackgroundColor3 = THEME.ACCENT_DARK
    CloseBtn.TextColor3 = THEME.TEXT
end)
CloseBtn.MouseLeave:Connect(function()
    CloseBtn.BackgroundColor3 = THEME.CARD
    CloseBtn.TextColor3 = THEME.MUTED
end)
CloseBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
end)

-- Drag only from title bar
local dragging = false
local dragStart
local startPos

TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = i.Position
        startPos = Main.Position
    end
end)

TitleBar.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = i.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- Reopen key
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

-- Scroll content
local Scroll = Instance.new("ScrollingFrame")
Scroll.Name = "Content"
Scroll.Size = UDim2.new(1, -20, 1, -70)
Scroll.Position = UDim2.new(0, 10, 0, 68)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = THEME.ACCENT
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Padding = Instance.new("UIPadding")
Padding.PaddingLeft = UDim.new(0, 4)
Padding.PaddingRight = UDim.new(0, 4)
Padding.PaddingBottom = UDim.new(0, 14)
Padding.Parent = Scroll

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 10)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroll

local function sectionHeader(text, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 22)
    f.BackgroundTransparency = 1
    f.LayoutOrder = order or 0
    f.Parent = Scroll

    local t = label(f, text, 10, THEME.MUTED, Enum.Font.GothamBold)
    t.Size = UDim2.new(1, 0, 1, 0)

    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, -110, 0, 1)
    line.Position = UDim2.new(0, 110, 0.5, 0)
    line.BackgroundColor3 = THEME.STROKE
    line.BorderSizePixel = 0
    line.Parent = f
    return f
end

local function makeCard(height, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, height)
    f.BackgroundColor3 = THEME.PANEL
    f.BorderSizePixel = 0
    f.LayoutOrder = order or 0
    f.Parent = Scroll
    corner(f, 9)
    stroke(f, THEME.STROKE, 1)
    return f
end

-- Animation section
sectionHeader("SWING ANIMATION", 1)

local AnimCard = makeCard(148, 2)

local AnimHint = label(AnimCard, "Choose the animation applied to the current tool", 10, THEME.DIM)
AnimHint.Position = UDim2.new(0, 12, 0, 8)
AnimHint.Size = UDim2.new(1, -24, 0, 16)

local AnimGrid = Instance.new("Frame")
AnimGrid.BackgroundTransparency = 1
AnimGrid.Position = UDim2.new(0, 10, 0, 31)
AnimGrid.Size = UDim2.new(1, -20, 1, -40)
AnimGrid.Parent = AnimCard

local Grid = Instance.new("UIGridLayout")
Grid.CellSize = UDim2.new(0.333, -7, 0, 44)
Grid.CellPadding = UDim2.new(0, 7, 0, 7)
Grid.SortOrder = Enum.SortOrder.LayoutOrder
Grid.Parent = AnimGrid

local animButtons = {}
local animationOrder = {"Guitar", "Spear", "Chainsaw", "Sword", "Dual"}

local function updateAnimButton(btn, selected)
    btn.BackgroundColor3 = selected and THEME.ACCENT_DARK or THEME.CARD
    btn.TextColor3 = selected and THEME.TEXT or THEME.MUTED

    local s = btn:FindFirstChildOfClass("UIStroke")
    if s then
        s.Color = selected and THEME.ACCENT2 or THEME.STROKE
    end
end

for index, name in ipairs(animationOrder) do
    if ANIMATIONS[name] then
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Text = name
        btn.TextColor3 = THEME.MUTED
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 11
        btn.AutoButtonColor = false
        btn.LayoutOrder = index
        btn.Parent = AnimGrid
        corner(btn, 7)
        stroke(btn, THEME.STROKE, 1)

        updateAnimButton(btn, name == currentAnim)

        btn.MouseEnter:Connect(function()
            if currentAnim ~= name then
                btn.BackgroundColor3 = THEME.CARD_HOVER
            end
        end)

        btn.MouseLeave:Connect(function()
            updateAnimButton(btn, currentAnim == name)
        end)

        btn.MouseButton1Click:Connect(function()
            currentAnim = name

            for n, b in pairs(animButtons) do
                updateAnimButton(b, n == currentAnim)
            end

            if CurrentTool then
                ApplyToTool(CurrentTool)
            end

            print(("[+] Animation set to: %s"):format(name))
        end)

        animButtons[name] = btn
    end
end

-- Slider helper
local function createSliderCard(parent, labelText, min, max, default, decimals, onChanged)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 76)
    card.BackgroundColor3 = THEME.PANEL
    card.BorderSizePixel = 0
    card.Parent = parent
    corner(card, 9)
    stroke(card, THEME.STROKE, 1)

    local title = label(card, labelText, 11, THEME.TEXT, Enum.Font.GothamMedium)
    title.Position = UDim2.new(0, 12, 0, 9)
    title.Size = UDim2.new(1, -90, 0, 18)

    local valueLabel = label(card, "", 10, THEME.ACCENT2, Enum.Font.GothamBold)
    valueLabel.Position = UDim2.new(1, -70, 0, 9)
    valueLabel.Size = UDim2.new(0, 58, 0, 18)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 43)
    track.BackgroundColor3 = THEME.CARD
    track.BorderSizePixel = 0
    track.Parent = card
    corner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = THEME.ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 3)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = THEME.TEXT
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 7)
    stroke(knob, THEME.ACCENT2, 1)

    local value = default
    local draggingSlider = false

    local function setValue(v)
        value = math.clamp(v, min, max)
        local frac = (value - min) / (max - min)

        fill.Size = UDim2.new(frac, 0, 1, 0)
        knob.Position = UDim2.new(frac, 0, 0.5, 0)

        if decimals == 0 then
            valueLabel.Text = tostring(math.floor(value + 0.5))
        else
            valueLabel.Text = string.format("%." .. decimals .. "f", value)
        end

        onChanged(value)
    end

    local function updateFromX(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local frac = math.clamp(
            (x - track.AbsolutePosition.X) / width,
            0, 1
        )
        setValue(min + (max - min) * frac)
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = true
            updateFromX(i.Position.X)
        end
    end)

    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingSlider = false
        end
    end)

    track.InputChanged:Connect(function(i)
        if draggingSlider and i.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(i.Position.X)
        end
    end)

    setValue(default)
    return card
end

-- Tuning section
sectionHeader("TUNING", 3)

local TuningCard = Instance.new("Frame")
TuningCard.Size = UDim2.new(1, 0, 0, 162)
TuningCard.BackgroundTransparency = 1
TuningCard.LayoutOrder = 4
TuningCard.Parent = Scroll

local tuningLayout = Instance.new("UIListLayout")
tuningLayout.Padding = UDim.new(0, 10)
tuningLayout.Parent = TuningCard

createSliderCard(
    TuningCard,
    "Animation Time",
    ANIM_TIME_MIN,
    ANIM_TIME_MAX,
    MODS["AnimationTime"],
    2,
    function(v)
        MODS["AnimationTime"] = v
        if CurrentTool then ApplyToTool(CurrentTool) end
    end
)

createSliderCard(
    TuningCard,
    "Rapid Swing Interval",
    SWING_SPEED_MIN,
    SWING_SPEED_MAX,
    RAPID_FIRE_RATE,
    3,
    function(v)
        RAPID_FIRE_RATE = v
    end
)

-- Control section
sectionHeader("CONTROLS", 5)

local ControlCard = makeCard(132, 6)

local ModeTitle = label(ControlCard, "CURRENT MODE", 9, THEME.DIM, Enum.Font.GothamBold)
ModeTitle.Position = UDim2.new(0, 12, 0, 10)
ModeTitle.Size = UDim2.new(1, -24, 0, 14)

local ModeBtn = Instance.new("TextButton")
ModeBtn.Size = UDim2.new(0.5, -16, 0, 38)
ModeBtn.Position = UDim2.new(0, 12, 0, 31)
ModeBtn.BackgroundColor3 = THEME.CARD
ModeBtn.Text = ""
ModeBtn.AutoButtonColor = false
ModeBtn.Parent = ControlCard
corner(ModeBtn, 7)
stroke(ModeBtn, THEME.STROKE, 1)

local ModeText = label(ModeBtn, "", 11, THEME.TEXT, Enum.Font.GothamBold)
ModeText.Size = UDim2.new(1, 0, 1, 0)
ModeText.TextXAlignment = Enum.TextXAlignment.Center

local ModeKey = label(ControlCard, "[ F ]", 10, THEME.MUTED, Enum.Font.GothamBold)
ModeKey.Position = UDim2.new(0.5, 0, 0, 31)
ModeKey.Size = UDim2.new(0.5, -12, 0, 38)
ModeKey.TextXAlignment = Enum.TextXAlignment.Right

local RapidBtn = Instance.new("TextButton")
RapidBtn.Size = UDim2.new(1, -24, 0, 38)
RapidBtn.Position = UDim2.new(0, 12, 0, 80)
RapidBtn.BackgroundColor3 = THEME.CARD
RapidBtn.Text = ""
RapidBtn.AutoButtonColor = false
RapidBtn.Parent = ControlCard
corner(RapidBtn, 7)
stroke(RapidBtn, THEME.STROKE, 1)

local RapidText = label(RapidBtn, "", 11, THEME.MUTED, Enum.Font.GothamBold)
RapidText.Position = UDim2.new(0, 12, 0, 0)
RapidText.Size = UDim2.new(1, -24, 1, 0)

local function updateModeUI()
    ModeText.Text = "MODE  •  " .. Mode:upper()
    if Mode == "Rapid" then
        ModeBtn.BackgroundColor3 = THEME.ACCENT_DARK
        ModeText.TextColor3 = THEME.TEXT
    else
        ModeBtn.BackgroundColor3 = THEME.CARD
        ModeText.TextColor3 = THEME.MUTED
    end
end

local function updateRapidUI()
    if rapidOn then
        RapidBtn.BackgroundColor3 = THEME.ACCENT_DARK
        RapidText.TextColor3 = THEME.TEXT
        RapidText.Text = "●  RAPID LOOP     ON                         [ G ]"
    else
        RapidBtn.BackgroundColor3 = THEME.CARD
        RapidText.TextColor3 = THEME.MUTED
        RapidText.Text = "○  RAPID LOOP     OFF                        [ G ]"
    end
end

updateModeUI()
updateRapidUI()

ModeBtn.MouseEnter:Connect(function()
    if Mode ~= "Rapid" then ModeBtn.BackgroundColor3 = THEME.CARD_HOVER end
end)
ModeBtn.MouseLeave:Connect(updateModeUI)

ModeBtn.MouseButton1Click:Connect(function()
    Mode = (Mode == "Reliable") and "Rapid" or "Reliable"
    rapidOn = false
    updateModeUI()
    updateRapidUI()
end)

RapidBtn.MouseEnter:Connect(function()
    if not rapidOn then RapidBtn.BackgroundColor3 = THEME.CARD_HOVER end
end)
RapidBtn.MouseLeave:Connect(updateRapidUI)

RapidBtn.MouseButton1Click:Connect(function()
    if Mode ~= "Rapid" then
        Mode = "Rapid"
        updateModeUI()
    end

    rapidOn = not rapidOn
    updateRapidUI()
end)

-- Status footer
local Status = label(Scroll, "", 10, THEME.DIM, Enum.Font.GothamMedium)
Status.Size = UDim2.new(1, 0, 0, 20)
Status.LayoutOrder = 7
Status.TextXAlignment = Enum.TextXAlignment.Center

local function updateStatus()
    local toolName = CurrentTool and CurrentTool.Name or "No tool detected"
    Status.Text = ("TOOL  %s     •     SHIFT  UI"):format(toolName)
end

updateStatus()

-- Keep the original F/G hotkeys, but synchronize the new UI.
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.F then
        Mode = (Mode == "Reliable") and "Rapid" or "Reliable"
        rapidOn = false
        updateModeUI()
        updateRapidUI()

    elseif input.KeyCode == Enum.KeyCode.G then
        if Mode ~= "Rapid" then
            return
        end

        rapidOn = not rapidOn
        updateRapidUI()
    end
end)

-- Existing tool watcher.
local function bindChildAdded(C)
    C.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            ApplyToTool(child)
            updateStatus()
        end
    end)
end

LP.CharacterAdded:Connect(function(C)
    bindChildAdded(C)
    for _, v in ipairs(C:GetChildren()) do
        ApplyToTool(v)
    end
    task.defer(updateStatus)
end)

if LP.Character then
    bindChildAdded(LP.Character)
    for _, v in ipairs(LP.Character:GetChildren()) do
        ApplyToTool(v)
    end
end
