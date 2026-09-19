-- Sets a custom spawn location for places.

local CustomSpawn_ = {

--======================================================================================
	[6220960770] = Vector3.new(-221.072, 25.096, 285.560), -- "Blades World ⚔️"
	[122298649618543] = Vector3.new(-14.905, 135.564, 167.285), -- "Check your Playtime & Stats!"
	[78394956750358] = Vector3.new(-264.256, 3.442, -1857.825), -- "Dirty Apartment"
	[126061186342944] = Vector3.new(-341.104, 18.947, 2246.495), -- "Backrooms Simulator [Skin Stealer!!!]"
	[109745098209948] = Vector3.new(-859.249, 3.000, -650.613), -- "[🔥] Get +1 Skill Point Every Second "
	[4748131147] = Vector3.new(-263.551, 16.096, -117.514), -- "SCP: Site-88 Roleplay"
	[135594671657272] = Vector3.new(205.687, 363.250, -127.832), -- "Boxing Gear Troll Tower ðŸ¥Š"
	[137388290000598] = Vector3.new(-184.634, 110.011, 887.858), -- "Locked Up"
	[7253149844] = Vector3.new(-1118.673, 23080.660, -782.774), -- "SCP Games and SCP Monsters"
	[78983965093663] = Vector3.new(3088.718, 5.000, 273.876), -- "O Elevador Terror BETA"
	[796267492] = Vector3.new(317.049, 66.864, -2758.400), -- "Girls&Boys vs ZOMBIES"
	[6741970382] = Vector3.new(-74.664, -15.500, -55.707), -- "Zombie lab [Equal Avatar ScaleðŸ“]"
	[114462164882373] = Vector3.new(-21.835, 652.592, 314.661), -- "Find Missing Bacon Tower ðŸ˜­ðŸ”"
	[107946054053457] = Vector3.new(-139.74, -76.00, 118.33),
	[91866617681570] = Vector3.new(729.59, 112.48, -87.05),
	[78748632651649] = Vector3.new(-1581.75, 854.80, 141.88),
	[126139688197717] = Vector3.new(-2.74, 903.70, -1614.53),
	[113869861599482] = Vector3.new(1251.64, -298.55, -258.38),
	[109399716520867] = Vector3.new(-1068.60, 18.50, -20.35),
	[103336136418477] = Vector3.new(-39.519, 3.208, 629.574), -- "+1 Zombie Escape"
	[9273658706] = Vector3.new(995.046, 3.053, 1670.753), -- "Backrooms"
	[84559806813733] = Vector3.new(-699.490, 618.392, -489.266), -- "Level 5 Terror Hotel"
	--[71607575632633] = Vector3.new(-475.413, -66.750, 2118.429), -- "Zone Defense RNG"
	[90086669327265] = Vector3.new(-959.286, 37.721, 6937.615), -- "[X2] +1 Cut Grass Adventure"
 [14675073025] = Vector3.new(-459.642, -109.475, 112.711), -- "Summer Camp Roleplay"

 [114319646192859] = Vector3.new(-197.973, 0.065, -38.863), -- "Spin For Free!"


--======================================================================================
}
local UseCustomSpawn = true
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local currentPlaceId = game.PlaceId
local targetPos = CustomSpawn_[currentPlaceId] or CustomSpawn_["Default"]
if not targetPos then
	print("No spawn point found for this game!")
	return
end
local function placeSpawnLocation(position)
	local existing = workspace:FindFirstChild("PremiumSpawnPoint")
	if existing then
		existing:Destroy()
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "PremiumSpawnPoint"
	spawn.Position = position
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Neutral = false
	spawn.AllowTeamChangeOnTouch = false
	spawn.Duration = 0
	spawn.Transparency = 0.4
	spawn.Parent = workspace
	return spawn
end
local function SpawnPoint(character)
	if not character then
		return
	end
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if rootPart then
		task.wait(0.05)
		character:PivotTo(CFrame.new(targetPos))
		print("Spawned")
	end
end
if not game:IsLoaded() then
	game.Loaded:Wait()
end
placeSpawnLocation(targetPos)
if localPlayer.Character then
	task.spawn(SpawnPoint, localPlayer.Character)
end
if UseCustomSpawn then
	localPlayer.CharacterAdded:Connect(function(character)
		SpawnPoint(character)
	end)
end
