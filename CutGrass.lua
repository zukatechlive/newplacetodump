local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local MODS = {
	["AC001"] = 590.04,
	["AnimationId"] = "rbxassetid://106887855409061",
	["AnimationTime"] = 1.3,
	["BaseArea"] = 80,
	["BaseCooldown"] = 1.5,
	["Rarity"] = 6,
	["SizePercent"] = 800,
}

local function Inject(Tool)
	if not Tool:IsA("Tool") then
		return
	end

	for Name, Value in pairs(MODS) do
		Tool:SetAttribute(Name, Value)
	end

	local WS = Tool:FindFirstChild("WeaponLocalScript")
	if WS then
		WS.Disabled = true
		task.wait(0.1)
		WS.Disabled = false
	end
end

LP.CharacterAdded:Connect(function(C)
	C.ChildAdded:Connect(Inject)
end)
if LP.Character then
	LP.Character.ChildAdded:Connect(Inject)
	for _, v in ipairs(LP.Character:GetChildren()) do
		Inject(v)
	end
end

task.spawn(function()
	while task.wait(MODS.BaseCooldown) do
		local Tool = LP.Character and LP.Character:FindFirstChildOfClass("Tool")
		local Event = Tool and Tool:FindFirstChild("WeaponSwingEvent")

		if Event then
			Event:FireServer("SwingStart")
			Event:FireServer("HitboxStart")
			task.wait(0.01)
			Event:FireServer("HitboxEnd")
			Event:FireServer("SwingEnd")
		end
	end
end)
