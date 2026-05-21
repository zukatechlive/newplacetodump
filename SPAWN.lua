local SPAWN_CONFIG = {


    [9273658706] = Vector3.new(978.54, 24.06, 1579.86),

    [115286378269814] = Vector3.new(60.53, 74.17, 23.04),

    [107946054053457] = Vector3.new(-139.74, -76.00, 118.33),

    [91866617681570] = Vector3.new(729.59, 112.48, -87.05),

    [78748632651649] = Vector3.new(-1581.75, 854.80, 141.88),

    [126139688197717] = Vector3.new(-2.74, 903.70, -1614.53),

    [109745098209948] = Vector3.new(4954.62, 2555.67, -8989.46),

    [113869861599482] = Vector3.new(1251.64, -298.55, -258.38),

	[109399716520867] = Vector3.new(-1068.60, 18.50, -20.35),
}


local TELEPORT_ON_RESPAWN = true
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local currentPlaceId = game.PlaceId
local targetPos = SPAWN_CONFIG[currentPlaceId] or SPAWN_CONFIG["Default"]
if not targetPos then
    print("No custom spawn set for PlaceID " .. currentPlaceId)
    return
end
local function placeSpawnLocation(position)
    local existing = workspace:FindFirstChild("CustomSpawnLocation")
    if existing then
        existing:Destroy()
    end
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "CustomSpawnLocation"
    spawn.Position = position
    spawn.Size = Vector3.new(6, 1, 6)
    spawn.Anchored = true
    spawn.CanCollide = false
    spawn.Neutral = false
    spawn.AllowTeamChangeOnTouch = false
    spawn.Duration = 0
    spawn.Transparency = 1
    spawn.Parent = workspace
    return spawn
end
local function teleportToCustomSpawn(character)
    if not character then return end
    local rootPart = character:WaitForChild("HumanoidRootPart", 10)
    if rootPart then
        task.wait(0.2)
        character:PivotTo(CFrame.new(targetPos))
        print("Spawned at custom location for PlaceID: " .. currentPlaceId)
    end
end
if not game:IsLoaded() then
    game.Loaded:Wait()
end
placeSpawnLocation(targetPos)
if localPlayer.Character then
    task.spawn(teleportToCustomSpawn, localPlayer.Character)
end
if TELEPORT_ON_RESPAWN then
    localPlayer.CharacterAdded:Connect(function(character)
        teleportToCustomSpawn(character)
    end)
end