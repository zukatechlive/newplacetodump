
--sandbox 
local ProtectedInstances = {}
local _Instance = Instance.new
local _tostring = tostring

local InstanceHook
InstanceHook = hookfunction(
	Instance.new,
	newcclosure(function(...)
		if checkcaller() then
			local NewInstance = InstanceHook(...)
			sethiddenproperty(NewInstance, "DefinesCapabilities", true)
			ProtectedInstances[NewInstance] = true
			return NewInstance
		end
		return InstanceHook(...)
	end)
)

local tostringHook
tostringHook = hookfunction(
	_tostring,
	newcclosure(function(...)
		local args = { ... }
		if not checkcaller() then
			if ProtectedInstances[args[1]] then
				return ""
			end
		end
		return tostringHook(...)
	end)
)

local FunctionHook
FunctionHook = hookmetamethod(
	game,
	"__namecall",
	newcclosure(function(self, ...)
		local Method = getnamecallmethod()
		if not checkcaller() then
			if ProtectedInstances[self] then
				return nil
			end
			local methodLower = Method:lower()
			if methodLower:match("^findfirst") or methodLower:match("^waitforchild") then
				local Inst = FunctionHook(self, ...)
				if Inst and ProtectedInstances[Inst] then
					return nil
				end
			end
		end
		return FunctionHook(self, ...)
	end)
)

local PropertiesHook
PropertiesHook = hookmetamethod(
	game,
	"__index",
	newcclosure(function(self, index)
		if not checkcaller() then
			local indexLower = index:lower()
			local selfProtected = ProtectedInstances[self]

			if (selfProtected and indexLower:match("^is")) or indexLower:match("^findfirst") then
				local IndexFunction = PropertiesHook(self, index)
				if typeof(IndexFunction) == "function" and not isfunctionhooked(IndexFunction) then
					hookfunction(
						IndexFunction,
						newcclosure(function(...)
							local args = { ... }
							local Inst = IndexFunction(self, args[2])
							if (Inst and ProtectedInstances[Inst]) or selfProtected then
								return nil
							end
						end)
					)
				end
			end

			if selfProtected and typeof(PropertiesHook(self, index)) ~= "function" then
				return nil
			end
		end
		return PropertiesHook(self, index)
	end)
)

for _, Thread in next, getactorthreads() do
	run_on_thread(
		Thread,
		[[
        local _tostring = tostring
        local args

        hookfunction(tostring, newcclosure(function(...)
            args = {...}
            if not checkcaller() and gethiddenproperty(args[1], "DefinesCapabilities") then
                return ""
            end
            return _tostring(...)
        end))

        hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            if not checkcaller() and gethiddenproperty(self, "DefinesCapabilities") then
                return nil
            end
            return old(self, ...)
        end))
    ]]
	)
end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("RemoteEvents")



local WEAPON_MODS = {


	["AnimationTime"] = 0.5,
	["BaseCooldown"] = 0.6,


}

local function Inject(Tool)
	if not Tool:IsA("Tool") then
		return
	end

	for Name, Value in pairs(WEAPON_MODS) do
		Tool:SetAttribute(Name, Value)
	end

	local WS = Tool:FindFirstChild("WeaponLocalScript")
	if WS then
		WS.Disabled = true
		task.wait(0.1)
		WS.Disabled = false
	end
end

LP.CharacterAdded:Connect(function(Character)
	Character.ChildAdded:Connect(Inject)
end)

if LP.Character then
	LP.Character.ChildAdded:Connect(Inject)
	for _, v in ipairs(LP.Character:GetChildren()) do
		Inject(v)
	end
end

task.spawn(function()
	while task.wait(0.01) do
		local Character = LP.Character
		local Tool = Character and Character:FindFirstChildOfClass("Tool")
		local Swing = Tool and Tool:FindFirstChild("WeaponSwingEvent")

		if Swing then
			Swing:FireServer("SwingStart")
			Swing:FireServer("HitboxStart")
			Swing:FireServer("HitboxEnd")
			Swing:FireServer("SwingEnd")
		end

		local LootModels = workspace:FindFirstChild("LootModels")
		if LootModels then
			for _, Loot in ipairs(LootModels:GetChildren()) do
				Remotes.LootPickedUpEvent:FireServer(Loot.Name)
			end
		end
	end
end)
