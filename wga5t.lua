-- Smart rate limit: fires at ~5 hits/sec (indistinguishable from fast clicking)
local lastFire = 0
local COOLDOWN = 0.15  -- ~6.6 hits/sec

game:GetService("RunService").Heartbeat:Connect(function()
    local now = tick()
    if now - lastFire < COOLDOWN then return end
    lastFire = now
    
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local target = getNearestPlayer()  -- from above
    if target then
        -- Subtle aim correction (don't snap, just slight angle adjustment)
        local currentLook = root.CFrame.LookVector
        local targetDir = (target.Position - root.Position).Unit
        local blend = 0.3  -- 30% aim correction per swing (less detectable)
        local smoothedDir = currentLook:Lerp(targetDir, blend)
        local spoofedCF = CFrame.lookAt(root.Position, root.Position + smoothedDir * 10)
        GoldenSwordHit:FireServer(spoofedCF)
    else
        GoldenSwordHit:FireServer(root.CFrame)
    end
end)
