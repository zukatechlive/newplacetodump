local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GoldenSwordHit = ReplicatedStorage:WaitForChild("PlayerEvents"):WaitForChild("WeaponEvents"):WaitForChild("Melee"):WaitForChild("GoldenSwordHit")
local LocalPlayer = game:GetService("Players").LocalPlayer

-- Fire 5 hits per frame (server-dependent if it processes all)
game:GetService("RunService").RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Fire multiple times per frame
    for i = 1, 5 do
        GoldenSwordHit:FireServer(root.CFrame)
    end
end)
