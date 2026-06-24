do
	local runService = game:GetService("RunService")
	local function getCombatTable()
		for _, v in pairs(getgc(true)) do
			if type(v) == "table" and rawget(v, "lastDash") and rawget(v, "comboCount") then
				return v
			end
		end
	end

	local combatTable = getCombatTable()

	if combatTable then
		runService.Heartbeat:Connect(function()
			combatTable.lastDash = 0
			combatTable.dashing = false

			local char = game.Players.LocalPlayer.Character
			if char and char:GetAttribute("Dashing") then
				char:SetAttribute("Dashing", false)
			end
		end)
	else
	end
end

do
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LocalPlayer = Players.LocalPlayer

	local Enforcer = {
		CombatTable = nil,
		ActiveStand = nil,
		Config = {
			NoKnockback = false,
			NoStun = true,
			StandPersistence = true,
		},
	}

	local function PatchStandModule()
		local ClientBaseStand = require(ReplicatedStorage:WaitForChild("ClientBaseStand"))

		local OldSummon = ClientBaseStand.Summon
		ClientBaseStand.Summon = function(self, State)
			if Enforcer.Config.StandPersistence and State == false then
				return
			end
			return OldSummon(self, State)
		end

		local OldHide = ClientBaseStand.Hide
		ClientBaseStand.Hide = function(self, State, ...)
			if Enforcer.Config.StandPersistence and State == false then
				return
			end
			return OldHide(self, State, ...)
		end
	end

	local function RefreshReferences()
		for _, Object in pairs(getgc(true)) do
			if type(Object) == "table" then
				if not Enforcer.CombatTable and rawget(Object, "lastDash") and rawget(Object, "comboCount") then
					Enforcer.CombatTable = Object
				end
				if not Enforcer.ActiveStand and rawget(Object, "standName") and rawget(Object, "summoned") ~= nil then
					Enforcer.ActiveStand = Object
				end
			end
		end
	end

	local function StartOptimizedLoop()
		RunService.Heartbeat:Connect(function()
			local Character = LocalPlayer.Character
			if Character and Enforcer.Config.NoStun then
				if Character:GetAttribute("Stunned") then
					Character:SetAttribute("Stunned", false)
				end
				if Character:GetAttribute("Barraged") then
					Character:SetAttribute("Barraged", false)
				end
				if Character:GetAttribute("Disabled") then
					Character:SetAttribute("Disabled", false)
				end

				local Root = Character:FindFirstChild("HumanoidRootPart")
				if Root and Enforcer.Config.NoKnockback then
					for _, Force in ipairs(Root:GetChildren()) do
						if
							Force.Name == "ForwardMove" and (Force:IsA("BodyVelocity") or Force:IsA("LinearVelocity"))
						then
							if Force.MaxForce.X <= 100000 then
								Force:Destroy()
							end
						end
					end
				end

				local Humanoid = Character:FindFirstChildOfClass("Humanoid")
				if Humanoid and Humanoid:GetState() == Enum.HumanoidStateType.Physics then
					Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end

			if Enforcer.CombatTable then
				Enforcer.CombatTable.stunned = false
				Enforcer.CombatTable.busy = false
				Enforcer.CombatTable.hitStun = 0
				Enforcer.CombatTable.lastDash = 0
			end

			if Enforcer.ActiveStand and Enforcer.Config.StandPersistence then
				if Enforcer.ActiveStand.summoned == false then
					Enforcer.ActiveStand.summoned = true
					Enforcer.ActiveStand:Summon(true)
				end
			end
		end)
	end

	task.spawn(function()
		RefreshReferences()

		PatchStandModule()

		local OldKick
		OldKick = hookfunction(LocalPlayer.Kick, function(self, Reason)
			if not checkcaller() and Reason and (Reason:lower():find("anomaly") or Reason:lower():find("behavior")) then
				return nil
			end
			return OldKick(self, Reason)
		end)

		StartOptimizedLoop()

		task.spawn(function()
			while task.wait(10) do
				Enforcer.ActiveStand = nil
				Enforcer.CombatTable = nil
				RefreshReferences()
			end
		end)
		DoNotif("Loaded")
	end)
end
