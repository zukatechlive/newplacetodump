local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local State = {
	Enabled = false,
	Target = nil,
	Offset = CFrame.new(0, 0, 3),
	BlinkFrequency = 1,
}

local frameCount = 0

local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 200, 0, 320)
Main.Position = UDim2.new(0.8, 0, 0.5, -160)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "INSTANT BLINK"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.Code

local ToggleBtn = Instance.new("TextButton", Main)
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 35)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 45)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
ToggleBtn.Text = "DISABLED"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.Font = Enum.Font.Code

local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(0.9, 0, 0, 210)
Scroll.Position = UDim2.new(0.05, 0, 0, 95)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.ScrollBarThickness = 2

local UIList = Instance.new("UIListLayout", Scroll)
UIList.Padding = UDim.new(0, 2)

local function updateList()
	for _, v in pairs(Scroll:GetChildren()) do
		if v:IsA("TextButton") then
			v:Destroy()
		end
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= lp then
			local b = Instance.new("TextButton", Scroll)
			b.Size = UDim2.new(1, -5, 0, 25)
			b.BackgroundColor3 = (State.Target == p) and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(40, 40, 40)
			b.Text = p.Name
			b.TextColor3 = Color3.new(1, 1, 1)
			b.Font = Enum.Font.Code
			b.TextSize = 12
			b.MouseButton1Click:Connect(function()
				State.Target = p
				updateList()
			end)
		end
	end
	Scroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y)
end

Players.PlayerAdded:Connect(updateList)
Players.PlayerRemoving:Connect(updateList)
updateList()

ToggleBtn.MouseButton1Click:Connect(function()
	State.Enabled = not State.Enabled
	ToggleBtn.Text = State.Enabled and "ENABLED" or "DISABLED"
	ToggleBtn.BackgroundColor3 = State.Enabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
end)

local originalCFrame = nil

RunService.PreSimulation:Connect(function()
	if not State.Enabled or not State.Target or not State.Target.Character then
		return
	end

	frameCount = frameCount + 1
	if frameCount % State.BlinkFrequency ~= 0 then
		return
	end

	local myChar = lp.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local targetHRP = State.Target.Character:FindFirstChild("HumanoidRootPart")

	if myHRP and targetHRP then
		originalCFrame = myHRP.CFrame

		myHRP.CFrame = targetHRP.CFrame * State.Offset
	end
end)

RunService.PostSimulation:Connect(function()
	if originalCFrame then
		local myChar = lp.Character
		local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

		if myHRP then
			myHRP.CFrame = originalCFrame
		end
		originalCFrame = nil
	end
end)
