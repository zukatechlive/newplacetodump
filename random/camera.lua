local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

-- // Configuration Variables (Default Values)
local settings = {
    distance = 10,
    height = 2,
    sideOffset = 2,
    fov = 70,
    smoothness = 0.2, -- Lower is smoother
    sensitivity = 0.5
}

-- // State Variables
local angleX, angleY = 0, 0
local cameraEnabled = true

-- // UI Construction
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "CameraTweaker"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 250, 0, 300)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "CAMERA TWEAKER"
title.TextColor3 = Color3.new(1, 1, 1)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
title.Font = Enum.Font.Offset

-- // Slider Helper Function
local function createSlider(name, min, max, default, pos, callback)
    local label = Instance.new("TextLabel", mainFrame)
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, pos)
    label.BackgroundTransparency = 1
    label.Text = name .. ": " .. default
    label.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    label.TextXAlignment = Enum.TextXAlignment.Left

    local sliderBack = Instance.new("Frame", mainFrame)
    sliderBack.Size = UDim2.new(1, -20, 0, 5)
    sliderBack.Position = UDim2.new(0, 10, 0, pos + 25)
    sliderBack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

    local sliderBtn = Instance.new("TextButton", sliderBack)
    sliderBtn.Size = UDim2.new(0, 10, 0, 15)
    sliderBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    sliderBtn.Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0)
    sliderBtn.Text = ""
    sliderBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)

    local dragging = false
    
    local function update()
        local percent = math.clamp((mouse.X - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        sliderBtn.Position = UDim2.new(percent, 0, 0.5, 0)
        local val = math.floor(min + (max - min) * percent)
        label.Text = name .. ": " .. val
        callback(val)
    end

    sliderBtn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then update() end
    end)
end

-- // Initialize Sliders
createSlider("Distance", 2, 50, settings.distance, 50, function(v) settings.distance = v end)
createSlider("Height", -5, 15, settings.height, 100, function(v) settings.height = v end)
createSlider("Side Offset", -10, 10, settings.sideOffset, 150, function(v) settings.sideOffset = v end)
createSlider("Field of View", 30, 120, settings.fov, 200, function(v) settings.fov = v end)

local toggleBtn = Instance.new("TextButton", mainFrame)
toggleBtn.Size = UDim2.new(1, -20, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 1, -40)
toggleBtn.Text = "TOGGLE CUSTOM CAMERA"
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)

toggleBtn.MouseButton1Click:Connect(function()
    cameraEnabled = not cameraEnabled
    if not cameraEnabled then
        camera.CameraType = Enum.CameraType.Custom
        toggleBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 0)
    else
        camera.CameraType = Enum.CameraType.Scriptable
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 0)
    end
end)

-- // Camera Logic
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and cameraEnabled then
        local delta = input.Delta
        angleX = angleX - delta.X * settings.sensitivity
        angleY = math.clamp(angleY - delta.Y * settings.sensitivity, -80, 80)
    end
end)

RunService:BindToRenderStep("CustomCameraUpdate", Enum.RenderPriority.Camera.Value + 1, function()
    if not cameraEnabled then return end
    
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if rootPart then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.FieldOfView = settings.fov
        
        -- Calculate rotation
        local startCFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, math.rad(angleX), 0) * CFrame.Angles(math.rad(angleY), 0, 0)
        
        -- Calculate offset (Back, Up, and Side)
        local cameraOffset = Vector3.new(settings.sideOffset, settings.height, settings.distance)
        local targetCFrame = startCFrame * CFrame.new(cameraOffset)
        
        -- Look at the character (plus a slight height adjustment so you look at the head area)
        local lookAtPosition = rootPart.Position + Vector3.new(0, settings.height, 0)
        
        -- Apply CFrame with Lerp for smoothness
        camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(targetCFrame.Position, lookAtPosition), settings.smoothness)
    end
end)
