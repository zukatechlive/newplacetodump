local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local function Notify(msg)
	if type(DoNotif) == "function" then
		pcall(DoNotif, tostring(msg))
	else
		print("[WoS Enforcer v5] " .. tostring(msg))
	end
end

local Enforcer = {
	CombatTable = nil,
	ActiveStand = nil,
	DriverTable = nil,
	NetworkTable = nil,

	_lastResummon = 0,
	_resummonCooldown = 0.5,

	Config = {
		NoDash = true,
		NoStun = true,
		NoBusy = true,
		NoKnockback = true,
		NoRagdoll = true,
		NoFreeze = true,

		StandPersistence = true,

		KickBypass = true,
		BlockForcedReset = true,
		BlockControllerLock = true,
	},
}

local function RefreshReferences()
	for _, Object in pairs(getgc(true)) do
		if type(Object) ~= "table" then
			continue
		end

		if not Enforcer.CombatTable and rawget(Object, "lastDash") ~= nil and rawget(Object, "comboCount") ~= nil then
			Enforcer.CombatTable = Object
		end

		if
			not Enforcer.ActiveStand
			and rawget(Object, "standName") ~= nil
			and rawget(Object, "summoned") ~= nil
			and rawget(Object, "char") ~= nil
			and rawget(Object, "allConnections") ~= nil
		then
			Enforcer.ActiveStand = Object
		end

		if
			not Enforcer.DriverTable
			and rawget(Object, "CurrentStand") ~= nil
			and rawget(Object, "StandData") ~= nil
			and rawget(Object, "moveUtil") ~= nil
			and rawget(Object, "plr") ~= nil
		then
			Enforcer.DriverTable = Object
		end

		if
			not Enforcer.NetworkTable
			and type(rawget(Object, "FireServer")) == "function"
			and type(rawget(Object, "InvokeServer")) == "function"
			and type(rawget(Object, "BindEvent")) == "function"
		then
			Enforcer.NetworkTable = Object
		end

		if Enforcer.CombatTable and Enforcer.ActiveStand and Enforcer.DriverTable and Enforcer.NetworkTable then
			break
		end
	end
end

local R15_MOTORS = {
	{ "Waist", "UpperTorso" },
	{ "Neck", "Head" },
	{ "LeftShoulder", "LeftUpperArm" },
	{ "LeftElbow", "LeftLowerArm" },
	{ "LeftWrist", "LeftHand" },
	{ "RightShoulder", "RightUpperArm" },
	{ "RightElbow", "RightLowerArm" },
	{ "RightWrist", "RightHand" },
	{ "LeftHip", "LeftUpperLeg" },
	{ "LeftKnee", "LeftLowerLeg" },
	{ "LeftAnkle", "LeftFoot" },
	{ "RightHip", "RightUpperLeg" },
	{ "RightKnee", "RightLowerLeg" },
	{ "RightAnkle", "RightFoot" },
}

local function IsRagdolled(Character)
	for _, Desc in ipairs(Character:GetDescendants()) do
		if Desc:IsA("BallSocketConstraint") and Desc.Name == "RagdollBallSocket" then
			return true
		end
	end
	return false
end

local function RecoverFromRagdoll(Character)
	local Root = Character:FindFirstChild("HumanoidRootPart")
	if Root then
		Root.CanCollide = true
	end

	for _, pair in ipairs(R15_MOTORS) do
		local Part = Character:FindFirstChild(pair[2])
		if Part then
			local Motor = Part:FindFirstChild(pair[1])
			if Motor and Motor:IsA("Motor6D") and not Motor.Enabled then
				Motor.Enabled = true
			end
		end
	end

	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	if Humanoid and Humanoid:GetState() == Enum.HumanoidStateType.Physics then
		Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function StripFreeze(Character)
	local Primary = Character.PrimaryPart
	if not Primary then
		return
	end

	for _, Child in ipairs(Primary:GetChildren()) do
		if Child.Name == "SequencePosition" or Child.Name == "SequenceOrientation" then
			Child:Destroy()
		end
	end
end

local function StripKnockback(Root)
	for _, Child in ipairs(Root:GetChildren()) do
		if
			Child.Name == "ForwardMove"
			and (Child:IsA("BodyVelocity") or Child:IsA("LinearVelocity"))
			and not Child:GetAttribute("Validated")
		then
			Child:Destroy()
		end
	end
end

local function PatchStandModule()
	local ok, CBS = pcall(function()
		return require(ReplicatedStorage:WaitForChild("ClientBaseStand", 10))
	end)

	if not ok or type(CBS) ~= "table" then
		warn("[WoS Enforcer v5] ClientBaseStand require failed — stand hooks skipped.")
		return
	end

	if type(CBS.Summon) == "function" then
		local OldSummon = CBS.Summon
		CBS.Summon = function(self, State, ...)
			if Enforcer.Config.StandPersistence and State == false then
				return
			end
			return OldSummon(self, State, ...)
		end
	end

	if type(CBS.Hide) == "function" then
		local OldHide = CBS.Hide
		CBS.Hide = function(self, State, ...)
			if Enforcer.Config.StandPersistence and State == false then
				return
			end
			return OldHide(self, State, ...)
		end
	end

	if type(CBS.HideAura) == "function" then
		local OldHideAura = CBS.HideAura
		CBS.HideAura = function(self, ...)
			if Enforcer.Config.StandPersistence then
				return
			end
			return OldHideAura(self, ...)
		end
	end
end

local function PatchNetworkEvents()
	local deadline = os.clock() + 15
	while not Enforcer.NetworkTable and os.clock() < deadline do
		task.wait(0.5)
		RefreshReferences()
	end

	local Net = Enforcer.NetworkTable
	if not Net then
		warn("[WoS Enforcer v5] Network table not found — event hooks skipped.")
		return
	end

	local OldBindEvent = Net.BindEvent
	Net.BindEvent = function(self, eventName, callback, ...)
		if eventName == "ShowAura" and Enforcer.Config.StandPersistence then
			local WrappedCallback = function(char, visible, skipParticles)
				if visible == false then
					return
				end
				return callback(char, visible, skipParticles)
			end
			return OldBindEvent(self, eventName, WrappedCallback, ...)
		end

		if eventName == "HideStand" and Enforcer.Config.StandPersistence then
			return
		end

		if Enforcer.Config.BlockControllerLock then
			if eventName == "DisableCharacterController" or eventName == "ToggleCharacterController" then
				return
			end
		end

		if eventName == "FreezeCharacter" and Enforcer.Config.NoFreeze then
			local WrappedFreeze = function(cframe, boolVal)
				task.spawn(function()
					local char = LocalPlayer.Character
					if char then
						StripFreeze(char)
					end
				end)
			end
			return OldBindEvent(self, eventName, WrappedFreeze, ...)
		end

		return OldBindEvent(self, eventName, callback, ...)
	end

	if type(Net.InvokeServer) == "function" then
		local OldInvokeServer = Net.InvokeServer
		Net.InvokeServer = function(self, funcName, ...)
			if Enforcer.Config.BlockForcedReset and funcName == "PlayerReset" then
				return false
			end
			local ok, result = pcall(OldInvokeServer, self, funcName, ...)
			if not ok then
				return nil
			end
			return result
		end
	end

	if type(Net.FireServer) == "function" then
		local OldFireServer = Net.FireServer
		Net.FireServer = function(self, eventName, ...)
			pcall(OldFireServer, self, eventName, ...)
		end
	end
end

local function ApplyKickBypass()
	if not Enforcer.Config.KickBypass then
		return
	end

	local OldKick
	OldKick = hookfunction(LocalPlayer.Kick, function(self, Reason, ...)
		if not checkcaller() then
			local r = tostring(Reason or ""):lower()
			if
				r:find("anomaly")
				or r:find("behavior")
				or r:find("exploit")
				or r:find("cheat")
				or r:find("modified")
				or r:find("invalid")
			then
				return nil
			end
		end
		return OldKick(self, Reason, ...)
	end)
end

local function TryResummonStand()
	if not Enforcer.Config.StandPersistence then
		return
	end
	local stand = Enforcer.ActiveStand
	if not stand or stand.summoned ~= false then
		return
	end

	local now = os.clock()
	if (now - Enforcer._lastResummon) < Enforcer._resummonCooldown then
		return
	end
	Enforcer._lastResummon = now

	stand.summoned = true
	pcall(function()
		stand:Summon(true)
	end)
end

local function StartHeartbeat()
	RunService.Heartbeat:Connect(function()
		local Character = LocalPlayer.Character
		if Character then
			if Enforcer.Config.NoStun then
				if Character:GetAttribute("Stunned") then
					Character:SetAttribute("Stunned", false)
				end
				if Character:GetAttribute("Barraged") then
					Character:SetAttribute("Barraged", false)
				end
				if Character:GetAttribute("Disabled") then
					Character:SetAttribute("Disabled", false)
				end

				local Flinched = Character:FindFirstChild("Flinched")
				if Flinched and Flinched:IsA("BoolValue") and Flinched.Value == true then
					Flinched.Value = false
				end

				local Blocking = Character:FindFirstChild("Blocking")
				if Blocking and Blocking:IsA("BoolValue") then
				end
			end

			if Enforcer.Config.NoDash then
				if Character:GetAttribute("Dashing") then
					Character:SetAttribute("Dashing", false)
				end
			end

			local Root = Character:FindFirstChild("HumanoidRootPart")

			if Root and Enforcer.Config.NoKnockback then
				StripKnockback(Root)
			end

			if Enforcer.Config.NoRagdoll and IsRagdolled(Character) then
				RecoverFromRagdoll(Character)
			end

			if Enforcer.Config.NoFreeze then
				StripFreeze(Character)
			end
		end

		local ct = Enforcer.CombatTable
		if ct then
			if Enforcer.Config.NoDash then
				ct.lastDash = 0
				ct.dashing = false
			end
			if Enforcer.Config.NoStun then
				ct.stunned = false
				ct.hitStun = 0
			end
			if Enforcer.Config.NoBusy then
				ct.busy = false
			end
		end

		TryResummonStand()
	end)
end

local function StartAutoReRef()
	task.spawn(function()
		while task.wait(10) do
			Enforcer.CombatTable = nil
			Enforcer.ActiveStand = nil

			if Enforcer.DriverTable then
				local cs = rawget(Enforcer.DriverTable, "CurrentStand")
				if cs and type(cs) == "table" and rawget(cs, "standName") ~= nil then
					Enforcer.ActiveStand = cs
				end
			end

			if not Enforcer.CombatTable or not Enforcer.ActiveStand then
				RefreshReferences()
			end
		end
	end)
end

task.spawn(function()
	local deadline = os.clock() + 10
	repeat
		RefreshReferences()
		if not Enforcer.CombatTable then
			task.wait(0.5)
		end
	until Enforcer.CombatTable or os.clock() > deadline

	if not Enforcer.CombatTable then
		warn("[WoS Enforcer v5] CombatTable not found after 10s — dash bypass inactive until next re-ref.")
	end

	PatchStandModule()
	ApplyKickBypass()
	StartHeartbeat()
	StartAutoReRef()

	task.spawn(PatchNetworkEvents)

	Notify("WoS Enforcer v5 Loaded")
end)
