local kg = game:GetService("Players")
local mq = game:GetService("ReplicatedStorage")
local aS = game:GetService("UserInputService")
local Xe = game:GetService("RunService")
local ez = mq.Remotes:WaitForChild("AttackEvent")
local function createGui()
	local zp = Instance.new("ScreenGui")
	zp.Name = "AutoFireGui"
	zp.ResetOnSpawn = false
	zp.Parent = gk:WaitForChild("PlayerGui")
	local Nd = Instance.new("TextButton")
	Nd.Name = "ToggleBtn"
	Nd.Size = UDim2.new(0, 120, 0, 40)
	Nd.Position = UDim2.new(0.5, -60, 0.9, -40)
	Nd.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	Nd.BackgroundTransparency = 0.6
	Nd.TextColor3 = Color3.fromRGB(255, 255, 255)
	Nd.Font = Enum.Font.SourceSansBold
	Nd.TextSize = 18
	Nd.Text = "OFF"
	Nd.Parent = zp
	return Nd
end
local GC = createGui()
local qB = false
local function updateBtn()
	if qB then
		GC.Text = "ON"
		GC.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
	else
		GC.Text = "OFF"
		GC.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	end
end
GC.MouseButton1Click:Connect(function()
	qB = not qB
	updateBtn()
end)
aS.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		qB = not qB
		updateBtn()
	end
end)
aS.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonR3 then
		qB = not qB
		updateBtn()
	end
end)
local function fireBurst()
	for _ = 1, 2 do
		ez:FireServer()
		ez:FireServer()
	end
end
Xe.RenderStepped:Connect(function()
	if qB then
		fireBurst()
		fireBurst()
	end
end)
updateBtn()
