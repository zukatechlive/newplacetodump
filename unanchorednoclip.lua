local TheGrandCatalog = game:GetService("Workspace")
local PhysicsBully = game:GetService("RunService")

local function RemoveTheBonk(FloppyBrick)
    if FloppyBrick:IsA("BasePart") and not FloppyBrick.Anchored then
        FloppyBrick.CanCollide = false
    end
end

-- Initial purge of the solid matter
for _, MysteryObject in ipairs(TheGrandCatalog:GetDescendants()) do
    RemoveTheBonk(MysteryObject)
end

-- Watch for new junk spawned by the server
TheGrandCatalog.DescendantAdded:Connect(RemoveTheBonk)

-- Constant enforcement for parts that decide to unanchor later
task.spawn(function()
    while true do
        for _, PotentialGhost in ipairs(TheGrandCatalog:GetDescendants()) do
            if PotentialGhost:IsA("BasePart") and not PotentialGhost.Anchored then
                PotentialGhost.CanCollide = false
            end
        end
        task.wait(2) -- Don't fry the potato PC
    end
end)

do
local MeatSacks = game:GetService("Players")
local HeartBeatMonitor = game:GetService("RunService")
local TheMainProtag = MeatSacks.LocalPlayer
local PhysicalRealm = game:GetService("Workspace")

-- Tell the server we have a massive gravitational pull
settings().Physics.AllowSleep = false

HeartBeatMonitor.Stepped:Connect(function()
    -- Set the simulation bubble to "Galactic" size
    TheMainProtag.MaximumSimulationRadius = math.huge
    sethiddenproperty(TheMainProtag, "SimulationRadius", 1e10)
    
    for _, FragileObject in ipairs(PhysicalRealm:GetDescendants()) do
        if FragileObject:IsA("BasePart") and not FragileObject.Anchored then
            -- Don't touch our own meat suit to prevent jump glitches
            if not FragileObject:IsDescendantOf(TheMainProtag.Character) then
                -- A microscopic velocity nudge forces the server to hand over the keys
                FragileObject.Velocity = Vector3.new(0, 0.01, 0)
            end
        end
    end
end)
end
