local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Locate System Modules
local WeaponsSystem = require(ReplicatedStorage:WaitForChild("WeaponsSystem"):WaitForChild("WeaponsSystem"))

-- Wait for the system and events to be ready
repeat task.wait() until WeaponsSystem.getRemoteEvent("WeaponFired")
local FireEvent = WeaponsSystem.getRemoteEvent("WeaponFired")

getgenv().MasterConfig = {
    SilentAim = true,
    InfiniteAmmo = true,
    RapidFire = true,
    SensitivityMultiplier = 2.0,
}

-- 1. CAMERA SENSITIVITY OVERRIDE
local cam = WeaponsSystem.camera
local oldApplyInput = cam.applyInput
cam.applyInput = function(self, yawDelta, pitchDelta)
    local mult = getgenv().MasterConfig.SensitivityMultiplier or 1.0
    return oldApplyInput(self, yawDelta * mult, pitchDelta * mult)
end

-- 2. INF & RAPID FIRE (BaseWeapon Data)
-- We only touch values, not functions, to avoid crashing the internal logic
task.spawn(function()
    while true do
        task.wait(0.1)
        if getgenv().MasterConfig.InfiniteAmmo then
            for _, weapon in pairs(WeaponsSystem.knownWeapons) do
                if weapon.ammoInWeaponValue then
                    weapon.ammoInWeaponValue.Value = weapon:getConfigValue("AmmoCapacity", 30)
                end
                if getgenv().MasterConfig.RapidFire then
                    weapon.reloading = false
                end
            end
        end
    end
end)

-- 3. SILENT AIM (Hooking the Network Event)
-- By hooking FireServer, we change the target *at the moment of firing*
local oldFireServer = FireEvent.FireServer
FireEvent.FireServer = function(self, weaponInstance, data, ...)
    if getgenv().MasterConfig.SilentAim then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            -- Modify the trajectory data being sent to the server
            local targetPos = target.Character.HumanoidRootPart.Position
            local origin = data.origin
            data.dir = (targetPos - origin).Unit
        end
    end
    return oldFireServer(self, weaponInstance, data, ...)
end

-- Helper
local function getClosestPlayer()
    local closest = nil
    local shortestDist = math.huge
    local cam = workspace.CurrentCamera
    local localPlayer = Players.LocalPlayer
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local pos, onScreen = cam:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)).Magnitude
                if dist < shortestDist then
                    closest = player
                    shortestDist = dist
                end
            end
        end
    end
    return closest
end

print("WeaponsSystem Patch: Network-Hooked Version Active.")
