-- anti auto farmer script, this is a meh script, it uses cframe snapback idk it was just an idea mainly
-- [GUI overhauled — logic loop below is untouched]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

local State = {
    Enabled = false,
    Target = nil,
    Offset = CFrame.new(0, 0, 3),
    BlinkFrequency = 2,
}

local frameCount = 0
local originalCFrame = nil -- Defined outside to ensure scope access

-- ══════════════════════════════════════════════════════════════
-- THEME
-- ══════════════════════════════════════════════════════════════
local Theme = {
    Background   = Color3.fromRGB(20, 21, 24),
    Surface      = Color3.fromRGB(27, 28, 32),
    SurfaceAlt   = Color3.fromRGB(33, 34, 39),
    Border       = Color3.fromRGB(44, 45, 51),
    TextPrimary  = Color3.fromRGB(232, 232, 236),
    TextMuted    = Color3.fromRGB(140, 141, 150),
    Accent       = Color3.fromRGB(214, 156, 74),  -- warm amber, avoids the generic purple/blue accent look
    AccentDim    = Color3.fromRGB(150, 108, 52),
    Danger       = Color3.fromRGB(196, 90, 84),
    Success      = Color3.fromRGB(107, 168, 110),
}

local FONT_HEADER = Enum.Font.GothamMedium
local FONT_BODY   = Enum.Font.Gotham

local function tween(obj, props, duration, style)
    TweenService:Create(obj, TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad), props):Play()
end

-- ══════════════════════════════════════════════════════════════
-- ROOT
-- ══════════════════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "CframeTest"
ScreenGui.ResetOnSpawn = false

local COLLAPSED_HEIGHT = 38
local EXPANDED_HEIGHT = 330

local Main = Instance.new("Frame", ScreenGui)
Main.Name = "Main"
Main.Size = UDim2.new(0, 220, 0, EXPANDED_HEIGHT)
Main.Position = UDim2.new(0.78, 0, 0.5, -180)
Main.BackgroundColor3 = Theme.Background
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true

local MainCorner = Instance.new("UICorner", Main)
MainCorner.CornerRadius = UDim.new(0, 8)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Theme.Border
MainStroke.Thickness = 1

-- // Custom dragging logic
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
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

local TitleCorner = Instance.new("UICorner", Title)
TitleCorner.CornerRadius = UDim.new(0, 8)

-- mask the bottom corners of the title bar so it reads as a flat header, not a pill
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
local AccentBarCorner = Instance.new("UICorner", AccentBar)
AccentBarCorner.CornerRadius = UDim.new(1, 0)

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
local StatusDotCorner = Instance.new("UICorner", StatusDot)
StatusDotCorner.CornerRadius = UDim.new(1, 0)

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
BodyPad.PaddingLeft = UDim.new(0, 10)
BodyPad.PaddingRight = UDim.new(0, 10)
BodyPad.PaddingTop = UDim.new(0, 8)
BodyPad.PaddingBottom = UDim.new(0, 10)

-- // Toggle row (label + switch, instead of a big text button)
local ToggleRow = Instance.new("Frame", Body)
ToggleRow.Size = UDim2.new(1, 0, 0, 32)
ToggleRow.Position = UDim2.new(0, 0, 0, 0)
ToggleRow.BackgroundColor3 = Theme.Surface
ToggleRow.BorderSizePixel = 0
local ToggleRowCorner = Instance.new("UICorner", ToggleRow)
ToggleRowCorner.CornerRadius = UDim.new(0, 6)

local ToggleLabel = Instance.new("TextLabel", ToggleRow)
ToggleLabel.Size = UDim2.new(1, -56, 1, 0)
ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
ToggleLabel.BackgroundTransparency = 1
ToggleLabel.Text = "Snapback"
ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
ToggleLabel.TextColor3 = Theme.TextPrimary
ToggleLabel.Font = FONT_BODY
ToggleLabel.TextSize = 12

local ToggleBtn = Instance.new("TextButton", ToggleRow) -- kept as TextButton so logic hooks below are unaffected
ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Size = UDim2.new(0, 38, 0, 20)
ToggleBtn.Position = UDim2.new(1, -46, 0.5, -10)
ToggleBtn.BackgroundColor3 = Theme.SurfaceAlt
ToggleBtn.Text = ""
ToggleBtn.AutoButtonColor = false
ToggleBtn.BorderSizePixel = 0
local ToggleBtnCorner = Instance.new("UICorner", ToggleBtn)
ToggleBtnCorner.CornerRadius = UDim.new(1, 0)

local ToggleKnob = Instance.new("Frame", ToggleBtn)
ToggleKnob.Size = UDim2.new(0, 16, 0, 16)
ToggleKnob.Position = UDim2.new(0, 2, 0.5, -8)
ToggleKnob.BackgroundColor3 = Theme.TextMuted
ToggleKnob.BorderSizePixel = 0
local ToggleKnobCorner = Instance.new("UICorner", ToggleKnob)
ToggleKnobCorner.CornerRadius = UDim.new(1, 0)

-- // Search box
local SearchBox = Instance.new("TextBox", Body)
SearchBox.Size = UDim2.new(1, 0, 0, 26)
SearchBox.Position = UDim2.new(0, 0, 0, 40)
SearchBox.BackgroundColor3 = Theme.Surface
SearchBox.PlaceholderText = "Search players..."
SearchBox.PlaceholderColor3 = Theme.TextMuted
SearchBox.Text = ""
SearchBox.TextColor3 = Theme.TextPrimary
SearchBox.Font = FONT_BODY
SearchBox.TextSize = 12
SearchBox.ClearTextOnFocus = false
SearchBox.BorderSizePixel = 0
local SearchCorner = Instance.new("UICorner", SearchBox)
SearchCorner.CornerRadius = UDim.new(0, 6)
local SearchPad = Instance.new("UIPadding", SearchBox)
SearchPad.PaddingLeft = UDim.new(0, 10)

-- // Player list
local Scroll = Instance.new("ScrollingFrame", Body)
Scroll.Name = "Scroll"
Scroll.Size = UDim2.new(1, 0, 0, 178)
Scroll.Position = UDim2.new(0, 0, 0, 74)
Scroll.BackgroundColor3 = Theme.Surface
Scroll.BorderSizePixel = 0
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Theme.Border
local ScrollCorner = Instance.new("UICorner", Scroll)
ScrollCorner.CornerRadius = UDim.new(0, 6)
local ScrollPad = Instance.new("UIPadding", Scroll)
ScrollPad.PaddingTop = UDim.new(0, 4)
ScrollPad.PaddingLeft = UDim.new(0, 4)
ScrollPad.PaddingRight = UDim.new(0, 4)

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Name = "UIList"
UIList.Padding = UDim.new(0, 3)

-- // Target readout
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
    tween(Main, { Size = UDim2.new(0, 220, 0, collapsed and COLLAPSED_HEIGHT or EXPANDED_HEIGHT) }, 0.2, Enum.EasingStyle.Quart)
    if not collapsed then
        Body.Visible = true
    else
        task.delay(0.2, function()
            if collapsed then
                Body.Visible = false
            end
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
    for _, v in pairs(Scroll:GetChildren()) do
        if v:IsA("TextButton") then
            v:Destroy()
        end
    end

    for _, p in pairs(Players:GetPlayers()) do
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

                local bc = Instance.new("UICorner", b)
                bc.CornerRadius = UDim.new(0, 5)

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
-- TOGGLE WIRING (drives State.Enabled — same field the logic loop reads)
-- ══════════════════════════════════════════════════════════════
local function setEnabled(state)
    State.Enabled = state
    StatusDot.BackgroundColor3 = state and Theme.Success or Theme.Danger
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

-- // Logic Loop
RunService.PreSimulation:Connect(function() 
    if not State.Enabled or not State.Target or not State.Target.Character then
        return
    end

    frameCount = frameCount + 1
    if frameCount % State.BlinkFrequency ~= 0 then
        return
    end

    local myChar = lp.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local targetHRP = State.Target.Character:FindFirstChild("HumanoidRootPart")

    if myHRP and targetHRP then
        originalCFrame = myHRP.CFrame
        myHRP.CFrame = targetHRP.CFrame * State.Offset
    end
end)

RunService.PostSimulation:Connect(function()
    if originalCFrame then
        local myChar = lp.Character
        local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

        if myHRP then
            myHRP.CFrame = originalCFrame
        end
        originalCFrame = nil
    end
end)
