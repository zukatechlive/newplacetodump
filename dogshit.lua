-- Universal Roblox Tool Animation Override Script with Path-Based Targeting
-- Place in LocalScript in StarterPlayerScripts

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

-- CONFIGURATION - EDIT THESE VALUES
local TARGET_TOOL_PATH = "" -- Leave empty for all tools, or specify path like "Backpack.Sword" or "Character.Humanoid.RightArm.Weapon"
local TARGET_ANIMATION_ID = "rbxassetid://103373177876482" -- Your animation ID

-- Utility function to find instance by path
local function findInstanceByPath(path)
    if path == "" or path == nil then return nil end
    
    local parts = string.split(path, ".")
    local current = game
    
    for _, part in ipairs(parts) do
        if part ~= "" then
            current = current:FindFirstChild(part)
            if not current then
                return nil
            end
        end
    end
    
    return current
end

-- UI for easy configuration with path input
local function createConfigUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 350, 0, 180)
    Frame.Position = UDim2.new(0.5, -175, 0, 10)
    Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Frame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Text = "Animation Override Config"
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Parent = Frame
    
    local PathInput = Instance.new("TextBox")
    PathInput.PlaceholderText = "Tool Path (empty for all tools)"
    PathInput.Size = UDim2.new(0.8, 0, 0, 30)
    PathInput.Position = UDim2.new(0.1, 0, 0, 40)
    PathInput.Text = TARGET_TOOL_PATH
    PathInput.Parent = Frame
    
    local PathHint = Instance.new("TextLabel")
    PathHint.Text = "Examples: Backpack.Sword, Character.Humanoid.RightArm.Weapon"
    PathHint.TextColor3 = Color3.fromRGB(180, 180, 180)
    PathHint.TextSize = 12
    PathHint.Size = UDim2.new(0.8, 0, 0, 20)
    PathHint.Position = UDim2.new(0.1, 0, 0, 75)
    PathHint.BackgroundTransparency = 1
    PathHint.Parent = Frame
    
    local AnimInput = Instance.new("TextBox")
    AnimInput.PlaceholderText = "Animation ID"
    AnimInput.Size = UDim2.new(0.8, 0, 0, 30)
    AnimInput.Position = UDim2.new(0.1, 0, 0, 100)
    AnimInput.Text = TARGET_ANIMATION_ID
    AnimInput.Parent = Frame
    
    local ApplyButton = Instance.new("TextButton")
    ApplyButton.Text = "Apply Changes"
    ApplyButton.Size = UDim2.new(0.8, 0, 0, 30)
    ApplyButton.Position = UDim2.new(0.1, 0, 0, 140)
    ApplyButton.Parent = Frame
    
    ApplyButton.MouseButton1Click:Connect(function()
        TARGET_TOOL_PATH = PathInput.Text
        TARGET_ANIMATION_ID = AnimInput.Text
        print("Configuration updated!")
        print("Target Path:", TARGET_TOOL_PATH == "" and "ALL TOOLS" or TARGET_TOOL_PATH)
        print("Animation ID:", TARGET_ANIMATION_ID)
        
        -- Re-apply to current tools
        setupToolDetection()
    end)
end

-- Get target tool based on path
local function getTargetTool()
    if TARGET_TOOL_PATH == "" then
        return nil -- Return nil to indicate all tools
    end
    
    local tool = findInstanceByPath(TARGET_TOOL_PATH)
    if tool and tool:IsA("Tool") then
        return tool
    else
        warn("Tool not found at path:", TARGET_TOOL_PATH)
        return nil
    end
end

-- Modern tool detection with path-based targeting
local function setupToolDetection()
    local targetTool = getTargetTool()
    
    if targetTool then
        -- Single tool targeting
        modifyToolAnimations(targetTool)
    else
        -- All tools targeting
        Character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.wait(0.2)
                modifyToolAnimations(child)
            end
        end)
        
        -- Check existing tools
        for _, child in ipairs(Character:GetChildren()) do
            if child:IsA("Tool") then
                modifyToolAnimations(child)
            end
        end
    end
end

-- Function to modify tool animations
local function modifyToolAnimations(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    print("Modifying tool at path:", tool:GetFullName())
    
    -- Method 1: Direct property modification
    pcall(function()
        if tool:FindFirstChild("UseAnimation") then
            tool.UseAnimation = TARGET_ANIMATION_ID
            print("✓ Direct UseAnimation property modified")
        end
    end)
    
    -- Method 2: Animation track override
    local customAnimation = Instance.new("Animation")
    customAnimation.AnimationId = TARGET_ANIMATION_ID
    customAnimation.Name = "CustomOverrideAnim"
    customAnimation.Parent = tool
    
    -- Hook activation
    local originalActivate = tool.Activate
    if originalActivate then
        tool.Activate = function(self, ...)
            -- Play custom animation
            local success, track = pcall(function()
                return Humanoid:LoadAnimation(customAnimation)
            end)
            
            if success and track then
                track:Play()
            end
            
            return originalActivate(self, ...)
        end
        print("✓ Activation hook installed")
    end
end

-- Command bar function for quick path-based changes
local function changeToolAnimByPath(toolPath, animId)
    if toolPath and toolPath ~= "" then
        local tool = findInstanceByPath(toolPath)
        if tool and tool:IsA("Tool") then
            pcall(function()
                if tool:FindFirstChild("UseAnimation") then
                    tool.UseAnimation = animId
                    print("Changed", tool:GetFullName(), "to", animId)
                end
            end)
        else
            warn("Tool not found at path:", toolPath)
        end
    else
        -- Apply to all tools in character
        local char = game.Players.LocalPlayer.Character
        if char then
            for _, child in ipairs(char:GetChildren()) do
                if child:IsA("Tool") then
                    pcall(function()
                        if child:FindFirstChild("UseAnimation") then
                            child.UseAnimation = animId
                            print("Changed", child.Name, "to", animId)
                        end
                    end)
                end
            end
        end
    end
end

-- Initialize
createConfigUI()
setupToolDetection()

print("Path-Based Animation Override Loaded!")
print("Target Path:", TARGET_TOOL_PATH == "" and "ALL TOOLS" or TARGET_TOOL_PATH)
print("Animation:", TARGET_ANIMATION_ID)
print("Use the config UI to change settings")

-- Export function to global namespace for command bar access
getfenv(1).changeToolAnimByPath = changeToolAnimByPath
