-- Christ is King!

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local TargetFolder = workspace.Main.CurrencyDrops

local Config = {
	TeleportDelay = 0.5,
	TeleportOffset = Vector3.new(0, 3, 0),
}

getgenv().TPLoopActive = false
local connection = nil

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TPLoopGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success = pcall(function()
	ScreenGui.Parent = game:GetService("CoreGui")
end)
if not success then
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 200, 0, 100)
Frame.Position = UDim2.new(0.5, -100, 0.02, 0)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 8)
Corner.Parent = Frame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(80, 80, 120)
Stroke.Thickness = 1.5
Stroke.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
Title.BorderSizePixel = 0
Title.Text = "  TP Loop"
Title.TextColor3 = Color3.fromRGB(200, 200, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 5, 0, 35)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Inactive"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 30)
ToggleBtn.Position = UDim2.new(0, 10, 0, 60)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "Start"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

local function GetTargets()
	local targets = {}
	for _, obj in ipairs(TargetFolder:GetChildren()) do
		targets[#targets + 1] = obj
	end
	return targets
end

local function GetPosition(obj)
	if obj:IsA("BasePart") then
		return obj.CFrame
	elseif obj:IsA("Model") then
		local primary = obj.PrimaryPart
		if primary then
			return primary.CFrame
		end
		for _, v in ipairs(obj:GetDescendants()) do
			if v:IsA("BasePart") then
				return v.CFrame
			end
		end
	end
	return nil
end

local function TeleportTo(cf)
	local char = LocalPlayer.Character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	root.CFrame = cf + Config.TeleportOffset
end

local function StartLoop()
	getgenv().TPLoopActive = true
	StatusLabel.Text = "Status: Running..."
	StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
	ToggleBtn.Text = "Stop"
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)

	task.spawn(function()
		while getgenv().TPLoopActive do
			local targets = GetTargets()
			if #targets == 0 then
				StatusLabel.Text = "No targets found!"
				task.wait(1)
				continue
			end

			for i, obj in ipairs(targets) do
				if not getgenv().TPLoopActive then
					break
				end

				local cf = GetPosition(obj)
				if cf then
					StatusLabel.Text = string.format("TP: %d / %d", i, #targets)
					TeleportTo(cf)
				end

				task.wait(Config.TeleportDelay)
			end
		end

		StatusLabel.Text = "Status: Inactive"
		StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		ToggleBtn.Text = "Start"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
	end)
end

local function StopLoop()
	getgenv().TPLoopActive = false
end

ToggleBtn.MouseButton1Click:Connect(function()
	if getgenv().TPLoopActive then
		StopLoop()
	else
		StartLoop()
	end
end)
