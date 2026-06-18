local TheGrandCatalog = game:GetService("Workspace")
local PhysicsBully = game:GetService("RunService")
local MeatSacks = game:GetService("Players")
local TheMainProtag = MeatSacks.LocalPlayer

local function RemoveTheBonk(FloppyBrick)
	if FloppyBrick:IsA("BasePart") and not FloppyBrick.Anchored then
		FloppyBrick.CanCollide = false
	end
end

for _, MysteryObject in ipairs(TheGrandCatalog:GetDescendants()) do
	RemoveTheBonk(MysteryObject)
end

TheGrandCatalog.DescendantAdded:Connect(RemoveTheBonk)

task.spawn(function()
	while true do
		for _, PotentialGhost in ipairs(TheGrandCatalog:GetDescendants()) do
			if PotentialGhost:IsA("BasePart") and not PotentialGhost.Anchored then
				PotentialGhost.CanCollide = false
			end
		end
		task.wait(2)
	end
end)

settings().Physics.AllowSleep = false

HeartBeatMonitor.Stepped:Connect(function()
	TheMainProtag.MaximumSimulationRadius = math.huge
	sethiddenproperty(TheMainProtag, "SimulationRadius", 1e10)

	for _, FragileObject in ipairs(PhysicalRealm:GetDescendants()) do
		if FragileObject:IsA("BasePart") and not FragileObject.Anchored then
			if not FragileObject:IsDescendantOf(TheMainProtag.Character) then
				FragileObject.Velocity = Vector3.new(0, 0.01, 0)
			end
		end
	end
end)
