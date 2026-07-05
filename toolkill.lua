local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local State = {
    Enabled = false,
    Target = nil,
    Offset = CFrame.new(0, 0, 3),
    BlinkFrequency = 1.5,
}

local frameCount = 0
local originalCFrame = nil -- Defined outside to ensure scope access

-- // Root
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "TargetPanel"
ScreenGui.ResetOnSpawn = false

local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 80) 
Main.Position = UDim2.new(0.8, 0, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Main.BorderSizePixel = 0
Main.Active = true
Main.ClipsDescendants = true

-- // Custom Dragging Logic
local function makeDraggable(topbar, object)
    local dragging, dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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

local UICorner = Instance.new("UICorner", Main)
UICorner.CornerRadius = UDim.new(0, 4)

local UIStroke = Instance.new("UIStroke", Main)
UIStroke.Color = Color3.fromRGB(45, 45, 45)
UIStroke.Thickness = 1

-- // Title bar (Acts as Drag handle and dropdown toggle)
local Title = Instance.new("TextButton", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
Title.Text = "   TARGET PANEL"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(230, 230, 230)
Title.Font = Enum.Font.Code
Title.TextSize = 14
Title.AutoButtonColor = false
Title.BorderSizePixel = 0

-- Apply dragging to the Title bar
makeDraggable(Title, Main)

local TitleCorner = Instance.new("UICorner", Title)
TitleCorner.CornerRadius = UDim.new(0, 4)

local Arrow = Instance.new("TextLabel", Title)
Arrow.Size = UDim2.new(0, 25, 1, 0)
Arrow.Position = UDim2.new(1, -25, 0, 0)
Arrow.BackgroundTransparency = 1
Arrow.Text = "▾"
Arrow.TextColor3 = Color3.fromRGB(230, 230, 230)
Arrow.Font = Enum.Font.Code
Arrow.TextSize = 14

-- // Body container
local Body = Instance.new("Frame", Main)
Body.Size = UDim2.new(1, 0, 0, 245)
Body.Position = UDim2.new(0, 0, 0, 35)
Body.BackgroundTransparency = 1

local ToggleBtn = Instance.new("TextButton", Body)
ToggleBtn.Size = UDim2.new(1, -20, 0, 32)
ToggleBtn.Position = UDim2.new(0, 10, 0, 8)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
ToggleBtn.Text = "DISABLED"
ToggleBtn.TextColor3 = Color3.fromRGB(180, 60, 60)
ToggleBtn.Font = Enum.Font.Code
ToggleBtn.TextSize = 13
ToggleBtn.AutoButtonColor = false
ToggleBtn.BorderSizePixel = 0

local ToggleCorner = Instance.new("UICorner", ToggleBtn)
ToggleCorner.CornerRadius = UDim.new(0, 3)

local Scroll = Instance.new("ScrollingFrame", Body)
Scroll.Size = UDim2.new(1, -20, 0, 195)
Scroll.Position = UDim2.new(0, 10, 0, 48)
Scroll.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
Scroll.BorderSizePixel = 0
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ScrollBarThickness = 2
Scroll.ScrollBarImageColor3 = Color3.fromRGB(70, 70, 70)

local ScrollCorner = Instance.new("UICorner", Scroll)
ScrollCorner.CornerRadius = UDim.new(0, 3)

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 2)

-- // Collapse / expand logic
local collapsed = false
local EXPANDED_HEIGHT = 315
local COLLAPSED_HEIGHT = 35

local function setCollapsed(state)
    collapsed = state
    Body.Visible = not collapsed
    Arrow.Text = collapsed and "▸" or "▾"
    Main.Size = UDim2.new(0, 200, 0, collapsed and COLLAPSED_HEIGHT or EXPANDED_HEIGHT)
end

Title.MouseButton1Click:Connect(function()
    setCollapsed(not collapsed)
end)

-- // Player list update
local function updateList()
    for _, v in pairs(Scroll:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= lp then
            local b = Instance.new("TextButton", Scroll)
            b.Size = UDim2.new(1, -6, 0, 25)
            b.BackgroundColor3 = (State.Target == p) and Color3.fromRGB(45, 90, 45) or Color3.fromRGB(32, 32, 32)
            b.Text = p.Name
            b.TextColor3 = Color3.fromRGB(220, 220, 220)
            b.Font = Enum.Font.Code
            b.TextSize = 12
            b.AutoButtonColor = false
            b.BorderSizePixel = 0

            local bc = Instance.new("UICorner", b)
            bc.CornerRadius = UDim.new(0, 3)

            b.MouseButton1Click:Connect(function()
                State.Target = p
                updateList()
            end)
        end
    end
    Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y)
end

Players.PlayerAdded:Connect(updateList)
Players.PlayerRemoving:Connect(updateList)
updateList()

ToggleBtn.MouseButton1Click:Connect(function()
    State.Enabled = not State.Enabled
    ToggleBtn.Text = State.Enabled and "ENABLED" or "DISABLED"
    ToggleBtn.TextColor3 = State.Enabled and Color3.fromRGB(60, 180, 90) or Color3.fromRGB(180, 60, 60)
end)

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
