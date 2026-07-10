local REACH = 45
local HIT_MULTI = 5
local SCAN_DELAY = 0.1

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local HitRemote =
	RS:WaitForChild("PlayerEvents"):WaitForChild("WeaponEvents"):WaitForChild("Melee"):WaitForChild("ClassicSwordHit")

local currentTargets = {}

task.spawn(function()
	while true do
		local newTargets = {}
		local char = LP.Character
		local myRoot = char and char:FindFirstChild("HumanoidRootPart")

		if myRoot then
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("Humanoid") and obj.Parent:IsA("Model") and obj.Parent ~= char then
					local root = obj.Parent:FindFirstChild("HumanoidRootPart")
					if root and obj.Health > 0 then
						local dist = (myRoot.Position - root.Position).Magnitude
						if dist <= REACH then
							table.insert(newTargets, root)
						end
					end
				end
			end
		end
		currentTargets = newTargets
		task.wait(SCAN_DELAY)
	end
end)

RunService.Heartbeat:Connect(function()
	local tool = LP.Character and LP.Character:FindFirstChild("ClassicSword")

	if tool then
		for _, targetRoot in ipairs(currentTargets) do
			if targetRoot and targetRoot.Parent and targetRoot.Parent:FindFirstChild("Humanoid") then
				if targetRoot.Parent.Humanoid.Health > 0 then
					for i = 1, HIT_MULTI do
						HitRemote:FireServer(targetRoot.CFrame)
					end
				end
			end
		end
	end
end)

print("this is a mid script")
