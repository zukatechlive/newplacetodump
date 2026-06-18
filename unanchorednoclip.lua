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
