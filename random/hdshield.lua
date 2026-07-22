local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local protect = {}

local authorizedSources = {
	[LP] = true,
	[script] = true,
}

local function protectCharacter(char)
	if not char then
		return
	end

	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			local oldIndex
			oldIndex = hookmetamethod(part, "__index", function(self, key)
				return oldIndex(self, key)
			end)

			local oldNewIndex
			oldNewIndex = hookmetamethod(part, "__newindex", function(self, key, value)
				if checkcaller() then
					return oldNewIndex(self, key, value)
				end

				if key == "CFrame" or key == "Position" or key == "Orientation" then
					return
				end

				if key == "Transparency" or key == "Color" or key == "Material" or key == "Reflectance" then
					return
				end

				if key == "Anchored" or key == "CanCollide" then
					return
				end

				return oldNewIndex(self, key, value)
			end)
		end

		if
			part:IsA("BodyMover")
			or part:IsA("BodyAngularVelocity")
			or part:IsA("BodyVelocity")
			or part:IsA("BodyPosition")
			or part:IsA("BodyGyro")
		then
			if not checkcaller() then
				part:Destroy()
			end
		end
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local oldHumanoidIndex
		oldHumanoidIndex = hookmetamethod(humanoid, "__newindex", function(self, key, value)
			if not checkcaller() then
				if
					key == "Health"
					or key == "Jump"
					or key == "Sit"
					or key == "WalkSpeed"
					or key == "JumpPower"
					or key == "HipHeight"
				then
					return
				end
				if key == "PlatformStand" then
					return
				end
			end
			return oldHumanoidIndex(self, key, value)
		end)
	end
end

local blockedRemotes = {
	["HDAdmin"] = true,
	["HDAdminRemote"] = true,
	["AdminRemote"] = true,
	["ActivateClientCommand"] = true,
}

local function blockRemote(instance)
	if
		instance:IsA("RemoteEvent")
		or instance:IsA("RemoteFunction")
		or instance:IsA("BindableEvent")
		or instance:IsA("BindableFunction")
	then
		local name = instance.Name:lower()

		for pattern in pairs(blockedRemotes) do
			if name:find(pattern:lower()) then
				if instance:IsA("RemoteEvent") then
					local oldFire
					oldFire = hookmetamethod(instance, "__namecall", function(self, ...)
						local method = getnamecallmethod()
						if method == "Fire" and not checkcaller() then
							return
						end
						return oldFire(self, ...)
					end)
				elseif instance:IsA("RemoteFunction") then
					local oldInvoke
					oldInvoke = hookmetamethod(instance, "__namecall", function(self, ...)
						local method = getnamecallmethod()
						if method == "InvokeServer" and not checkcaller() then
							return
						end
						return oldInvoke(self, ...)
					end)
				end

				break
			end
		end
	end

	for _, child in pairs(instance:GetChildren()) do
		blockRemote(child)
	end
end

local function watchCharacter(char)
	if not char then
		return
	end

	local oldChildAdded
	oldChildAdded = hookmetamethod(char, "__namecall", function(self, ...)
		local method = getnamecallmethod()

		if method == "AddAccessory" and not checkcaller() and self == char then
			return
		end

		return oldChildAdded(self, ...)
	end)

	char.ChildAdded:Connect(function(child)
		if checkcaller() then
			return
		end

		task.defer(function()
			if child:IsA("Accessory") or child:IsA("Part") or child:IsA("MeshPart") then
				local isOriginal = false
				for _, origChild in pairs(char:GetChildren()) do
					if origChild == child then
						isOriginal = true
						break
					end
				end
				if not isOriginal then
					child:Destroy()
				end
			end

			if child:IsA("Attachment") or child:IsA("Beam") or child:IsA("ParticleEmitter") then
				if not child:GetAttribute("HDAdminAuthorized") then
					child:Destroy()
				end
			end

			if child:IsA("BodyMover") then
				child:Destroy()
			end
		end)
	end)
end

local function protectUI()
	LP.PlayerGui.ChildAdded:Connect(function(child)
		if checkcaller() then
			return
		end
		task.defer(function()
			if child:IsA("ScreenGui") then
				local name = child.Name:lower()
				if not name:find("roblox") and not name:find("notification") then
					child.Enabled = false
				end
			end
		end)
	end)
end

local function protectPlayerObject()
	local oldIndex
	oldIndex = hookmetamethod(LP, "__newindex", function(self, key, value)
		if not checkcaller() then
			if key == "kick" or key == "Kick" then
				return
			end
		end
		return oldIndex(self, key, value)
	end)
end

LP.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	protectCharacter(char)
	watchCharacter(char)
end)

local function init()
	protectCharacter(LP.Character)
	watchCharacter(LP.Character)

	blockRemote(game)

	protectUI()

	protectPlayerObject()

	print("[Protect] HDAdmin shield active")
	print("[Protect] Blocking: CFrame, transparency, morphs, remotes, movers, health changes, teleports")
end

task.defer(init)

getgenv().reloadProtection = function()
	init()
end

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local char = LP.Character

local oldSpawn
oldSpawn = hookmetamethod(Instance.new("Explosion"), "__namecall", function(self, ...)
	local method = getnamecallmethod()
	if method == "Parent" or method == "Destroy" then
		return oldSpawn(self, ...)
	end
	return oldSpawn(self, ...)
end)

local explosionMeta = getrawmetatable(Instance.new("Explosion"))
local oldExplosionNew
oldExplosionNew = hookmetamethod(explosionMeta, "__newindex", function(self, key, value)
	if key == "Parent" and not checkcaller() then
		local dist = (self.Position and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"))
				and (self.Position - LP.Character.HumanoidRootPart.Position).Magnitude
			or math.huge

		if dist and dist < 50 then
			self:Destroy()
			return
		end
	end
	return oldExplosionNew(self, key, value)
end)

local function blockExplosionDamage(char)
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local oldTakeDamage
	oldTakeDamage = hookmetamethod(humanoid, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if method == "TakeDamage" and not checkcaller() then
			return
		end
		return oldTakeDamage(self, ...)
	end)
end

blockExplosionDamage(char)
LP.CharacterAdded:Connect(function(newChar)
	task.wait()
	blockExplosionDamage(newChar)
end)

local function scanForExplosions()
	workspace.ChildAdded:Connect(function(child)
		task.wait()
		if child:IsA("Explosion") and not checkcaller() then
			local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (child.Position - hrp.Position).Magnitude
				if dist < 60 then
					child.Destroyed:Connect(function() end)
					child:Destroy()
				end
			end
		end
	end)
end
scanForExplosions()

local function blockJail(char)
	if not char then
		return
	end

	workspace.ChildAdded:Connect(function(child)
		task.wait()
		if checkcaller() then
			return
		end

		local name = child.Name:lower()
		if name:find(LP.Name:lower()) and (name:find("jail") or name:find("cell") or name:find("prison")) then
			child:Destroy()
			return
		end

		if child:IsA("Model") and child.PrimaryPart then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local dist = (child.PrimaryPart.Position - hrp.Position).Magnitude
				if dist < 3 and not name:find("roblox") then
					local isLegit = false
					for _, part in pairs(child:GetDescendants()) do
						if part:IsA("Part") and part.Anchored and not part:IsDescendantOf(char) then
							child:Destroy()
							break
						end
					end
				end
			end
		end
	end)

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		local function watchPart(part)
			if part:IsA("BasePart") and not part:IsDescendantOf(char) then
				local oldPartNewIndex
				oldPartNewIndex = hookmetamethod(part, "__newindex", function(self, key, value)
					if key == "CFrame" and not checkcaller() then
						local myHead = LP.Character and LP.Character:FindFirstChild("Head")
						if myHead then
							local dist = (self.Position - myHead.Position).Magnitude
							if dist < 5 and not self:IsDescendantOf(LP.Character) then
								task.defer(function()
									self:Destroy()
								end)
								return
							end
						end
					end
					return oldPartNewIndex(self, key, value)
				end)
			end
		end

		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") then
				watchPart(v)
			end
		end

		workspace.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				watchPart(desc)
			end
		end)
	end
end

blockJail(char)
LP.CharacterAdded:Connect(function(newChar)
	task.wait(1)
	blockJail(newChar)
end)

workspace.DescendantAdded:Connect(function(desc)
	task.wait()
	if checkcaller() then
		return
	end

	if
		(desc:IsA("UnionOperation") or desc:IsA("Part") or desc:IsA("MeshPart"))
		and not desc:IsDescendantOf(LP.Character)
	then
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local dist = (desc.Position - hrp.Position).Magnitude
			if dist < 2.5 and (desc.Anchored or desc:IsA("UnionOperation")) then
				task.defer(function()
					desc:Destroy()
				end)
			end
		end
	end
end)

print("[Shield] Explode & Jail protection active")
print("[Shield] Blocking: explosions, jail cells, anchored trap parts near character")

local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local hooked = {}

local function findHDAdminRemotes(instance, depth)
	depth = depth or 0
	if depth > 10 then
		return
	end

	if instance:IsA("RemoteEvent") or instance:IsA("RemoteFunction") then
		local name = instance.Name:lower()
		local patterns = {
			"hdadmin",
			"hd_admin",
			"admin",
			"signal",
			"remote",
			"retrieve",
			"request",
			"execute",
			"replicate",
			"broadcast",
			"poll",
			"alert",
			"notice",
			"bubblechat",
			"emote",
			"effect",
			"command",
			"setting",
			"rank",
			"ban",
			"permission",
			"ugc",
			"favorite",
			"gamepass",
			"offer",
			"message",
			"private",
		}

		for _, pattern in pairs(patterns) do
			if name:find(pattern) then
				hookRemote(instance)
				break
			end
		end
	end

	for _, child in pairs(instance:GetChildren()) do
		findHDAdminRemotes(child, depth + 1)
	end
end

local function hookRemote(remote)
	if hooked[remote] then
		return
	end
	hooked[remote] = true

	if remote:IsA("RemoteEvent") then
		local oldFireClient
		oldFireClient = hookmetamethod(remote, "__namecall", function(self, ...)
			local method = getnamecallmethod()

			if method == "FireClient" then
				local targetPlayer = select(1, ...)
				if targetPlayer == LP and not checkcaller() then
					return
				end
			end

			if method == "FireAllClients" and not checkcaller() then
				return
			end

			return oldFireClient(self, ...)
		end)
	elseif remote:IsA("RemoteFunction") then
		local oldInvokeClient
		oldInvokeClient = hookmetamethod(remote, "__namecall", function(self, ...)
			local method = getnamecallmethod()

			if method == "InvokeClient" then
				local targetPlayer = select(1, ...)
				if targetPlayer == LP and not checkcaller() then
					return nil
				end
			end

			return oldInvokeClient(self, ...)
		end)
	end

	if remote:IsA("Instance") then
		local oldParent
		oldParent = hookmetamethod(remote, "__newindex", function(self, key, value)
			if key == "Parent" and not checkcaller() then
				task.defer(function()
					hookRemote(self)
				end)
			end
			return oldParent(self, key, value)
		end)
	end
end

local specificRemotesToBlock = {
	"ReplicationEffectClientCommand",
	"CreateAlert",
	"Notice",
	"ForceBubbleChat",
	"CreateEmotesMenu",
	"UpdateIceBlock",
	"Halt",
	"DisplayMessage",
	"Kick",
}

local function findAndBlockSpecificRemotes(instance)
	for _, child in pairs(instance:GetChildren()) do
		if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
			for _, name in pairs(specificRemotesToBlock) do
				if child.Name == name then
					hookRemote(child)
					break
				end
			end
		end
		findAndBlockSpecificRemotes(child)
	end
end

local function blockCommandExecutionOnSelf()
	local function watchDescendants(instance)
		instance.DescendantAdded:Connect(function(desc)
			task.wait()
			if desc:IsA("RemoteEvent") or desc:IsA("RemoteFunction") then
				local name = desc.Name:lower()
				if name:find("effect") or name:find("replicate") or name:find("command") or name:find("admin") then
					hookRemote(desc)
				end
			end
		end)
	end
	watchDescendants(game)
end

local function enableNuclearShield()
	local oldFireClient
	oldFireClient = hookmetamethod(Instance.new("RemoteEvent"), "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if method == "FireClient" and not checkcaller() then
			local target = select(1, ...)
			if target == LP then
				return
			end
		end
		if method == "FireAllClients" and not checkcaller() then
			return
		end
		return oldFireClient(self, ...)
	end)

	local oldInvokeClient
	oldInvokeClient = hookmetamethod(Instance.new("RemoteFunction"), "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if method == "InvokeClient" and not checkcaller() then
			local target = select(1, ...)
			if target == LP then
				return nil
			end
		end
		return oldInvokeClient(self, ...)
	end)

	print("[Nuclear Shield] Blocking ALL FireClient/InvokeClient targeting LocalPlayer")
end

local function init()
	findHDAdminRemotes(game)

	findAndBlockSpecificRemotes(game)

	blockCommandExecutionOnSelf()

	print("[Remote Shield] Active - HDAdmin remotes blocked from targeting LocalPlayer")
	print("[Remote Shield] Blocked: ReplicationEffectClientCommand, CreateAlert, Notice,")
	print("[Remote Shield]          ForceBubbleChat, CreateEmotesMenu, UpdateIceBlock")
	print("[Remote Shield]          + all HDAdmin-patterned remotes")
end

task.defer(init)
