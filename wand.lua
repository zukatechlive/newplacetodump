local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ElectricWandFire = ReplicatedStorage:WaitForChild("PlayerEvents"):WaitForChild("WeaponEvents"):WaitForChild("Magic"):WaitForChild("ElectricWandFire")
local LocalPlayer = game:GetService("Players").LocalPlayer

-- Fire every frame
game:GetService("RunService").RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool or tool.Name ~= "ElectricWand" then return end
    
    local endPos = tool:FindFirstChild("End")
    if not endPos then return end
    
    local position = endPos.Position
    local direction = Vector3.new(0, 0, 24)  -- straight forward, default
    
    ElectricWandFire:FireServer(position, direction)
end)
