-- Christ is King!

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local Config = {
	TeleportDelay = 0.5,
	TeleportOffset = Vector3.new(0, 3, 0),
	DefaultPath = "workspace.Main.CurrencyDrops",
}

local TargetFolder = nil

local function ResolvePath(pathStr)
	local parts = string.split(pathStr, ".")
	local current = game
	for _, part in ipairs(parts) do
		local child = current:FindFirstChild(part)
		if not child then
			-- try index (for services like workspace)
			local ok, result = pcall(function() return current[part] end)
			if ok and result then
				current = result
			else
				return nil, "Path segment not found: " .. part
			end
		else
			current = child
		end
	end
	return current, nil
end

getgenv().TPLoopActive = false

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
Frame.Size = UDim2.new(0, 220, 0, 165)
Frame.Position = UDim2.new(0.5, -110, 0.02, 0)
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

-- Path label
local PathLabel = Instance.new("TextLabel")
PathLabel.Size = UDim2.new(1, -10, 0, 16)
PathLabel.Position = UDim2.new(0, 5, 0, 34)
PathLabel.BackgroundTransparency = 1
PathLabel.Text = "Target Path:"
PathLabel.TextColor3 = Color3.fromRGB(160, 160, 200)
PathLabel.TextSize = 11
PathLabel.Font = Enum.Font.Gotham
PathLabel.TextXAlignment = Enum.TextXAlignment.Left
PathLabel.Parent = Frame

-- Path input box
local PathBox = Instance.new("TextBox")
PathBox.Size = UDim2.new(1, -20, 0, 24)
PathBox.Position = UDim2.new(0, 10, 0, 52)
PathBox.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
PathBox.BorderSizePixel = 0
PathBox.Text = Config.DefaultPath
PathBox.TextColor3 = Color3.fromRGB(200, 220, 255)
PathBox.PlaceholderText = "e.g. workspace.Main.CurrencyDrops"
PathBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
PathBox.TextSize = 11
PathBox.Font = Enum.Font.Code
PathBox.TextXAlignment = Enum.TextXAlignment.Left
PathBox.ClearTextOnFocus = false
PathBox.Parent = Frame

local PathBoxCorner = Instance.new("UICorner")
PathBoxCorner.CornerRadius = UDim.new(0, 5)
PathBoxCorner.Parent = PathBox

local PathBoxStroke = Instance.new("UIStroke")
PathBoxStroke.Color = Color3.fromRGB(60, 60, 100)
PathBoxStroke.Thickness = 1
PathBoxStroke.Parent = PathBox

local PathBoxPadding = Instance.new("UIPadding")
PathBoxPadding.PaddingLeft = UDim.new(0, 6)
PathBoxPadding.PaddingRight = UDim.new(0, 6)
PathBoxPadding.Parent = PathBox

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 0, 20)
StatusLabel.Position = UDim2.new(0, 5, 0, 84)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Status: Inactive"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

-- Toggle button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 30)
ToggleBtn.Position = UDim2.new(0, 10, 0, 110)
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

-- Highlight path box border on focus
PathBox.Focused:Connect(function()
	PathBoxStroke.Color = Color3.fromRGB(100, 100, 200)
end)
PathBox.FocusLost:Connect(function()
	PathBoxStroke.Color = Color3.fromRGB(60, 60, 100)
end)

local function GetTargets()
	local targets = {}
	if not TargetFolder then return targets end
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
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	root.CFrame = cf + Config.TeleportOffset
end

local function StartLoop()
	local pathStr = PathBox.Text
	local folder, err = ResolvePath(pathStr)
	if not folder then
		StatusLabel.Text = "Bad path: " .. (err or "?")
		StatusLabel.TextColor3 = Color3.fromRGB(220, 80, 80)
		return
	end
	TargetFolder = folder

	getgenv().TPLoopActive = true
	StatusLabel.Text = "Status: Running..."
	StatusLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
	ToggleBtn.Text = "Stop"
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	PathBox.TextEditable = false

	task.spawn(function()
		while getgenv().TPLoopActive do
			local targets = GetTargets()
			if #targets == 0 then
				StatusLabel.Text = "No targets found!"
				task.wait(1)
				continue
			end

			for i, obj in ipairs(targets) do
				if not getgenv().TPLoopActive then break end
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
		PathBox.TextEditable = true
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
