local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local Enabled = false
local TargetPart = nil

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local PathInput = Instance.new("TextBox")
local SetPathBtn = Instance.new("TextButton")
local ToggleBtn = Instance.new("TextButton")
local StatusLabel = Instance.new("TextLabel")

ScreenGui.Name = "GhostTouch_V3"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -100)
MainFrame.Size = UDim2.new(0, 230, 0, 200)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ClipsDescendants = false

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(50, 50, 58)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

local MainPadding = Instance.new("UIPadding")
MainPadding.PaddingTop = UDim.new(0, 0)
MainPadding.PaddingLeft = UDim.new(0, 10)
MainPadding.PaddingRight = UDim.new(0, 10)
MainPadding.Parent = MainFrame

Title.Parent = MainFrame
Title.Size = UDim2.new(1, 20, 0, 34)
Title.Position = UDim2.new(0, -10, 0, 0)
Title.Text = " Universal Auto Touch"
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextColor3 = Color3.fromRGB(235, 235, 240)
Title.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local TitleMask = Instance.new("Frame")
TitleMask.BackgroundColor3 = Title.BackgroundColor3
TitleMask.BorderSizePixel = 0
TitleMask.Size = UDim2.new(1, 0, 0, 10)
TitleMask.Position = UDim2.new(0, 0, 1, -10)
TitleMask.ZIndex = Title.ZIndex
TitleMask.Parent = Title

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 48)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 28, 34)),
})
TitleGradient.Rotation = 0
TitleGradient.Parent = Title

PathInput.Parent = MainFrame
PathInput.Position = UDim2.new(0, 0, 0, 46)
PathInput.Size = UDim2.new(1, 0, 0, 36)
PathInput.PlaceholderText = "Paste path here..."
PathInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 128)
PathInput.Text = ""
PathInput.BackgroundColor3 = Color3.fromRGB(32, 32, 38)
PathInput.TextColor3 = Color3.fromRGB(255, 255, 255)
PathInput.TextSize = 14
PathInput.Font = Enum.Font.Gotham
PathInput.ClearTextOnFocus = false

local PathCorner = Instance.new("UICorner")
PathCorner.CornerRadius = UDim.new(0, 8)
PathCorner.Parent = PathInput

local PathStroke = Instance.new("UIStroke")
PathStroke.Color = Color3.fromRGB(55, 55, 64)
PathStroke.Thickness = 1
PathStroke.Parent = PathInput

local PathInnerPad = Instance.new("UIPadding")
PathInnerPad.PaddingLeft = UDim.new(0, 10)
PathInnerPad.PaddingRight = UDim.new(0, 10)
PathInnerPad.Parent = PathInput

SetPathBtn.Parent = MainFrame
SetPathBtn.Position = UDim2.new(0, 0, 0, 92)
SetPathBtn.Size = UDim2.new(1, 0, 0, 32)
SetPathBtn.Text = "ON"
SetPathBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
SetPathBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SetPathBtn.TextSize = 14
SetPathBtn.Font = Enum.Font.GothamBold
SetPathBtn.AutoButtonColor = false

local SetPathCorner = Instance.new("UICorner")
SetPathCorner.CornerRadius = UDim.new(0, 8)
SetPathCorner.Parent = SetPathBtn

local SetPathStroke = Instance.new("UIStroke")
SetPathStroke.Color = Color3.fromRGB(70, 70, 80)
SetPathStroke.Thickness = 1
SetPathStroke.Parent = SetPathBtn

SetPathBtn.MouseEnter:Connect(function()
	SetPathBtn.BackgroundColor3 = Color3.fromRGB(58, 58, 68)
end)
SetPathBtn.MouseLeave:Connect(function()
	SetPathBtn.BackgroundColor3 = Color3.fromRGB(48, 48, 56)
end)

ToggleBtn.Parent = MainFrame
ToggleBtn.Position = UDim2.new(0, 0, 0, 134)
ToggleBtn.Size = UDim2.new(1, 0, 0, 36)
ToggleBtn.Text = "OFF"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(130, 45, 45)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.AutoButtonColor = false

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(160, 60, 60)
ToggleStroke.Thickness = 1
ToggleStroke.Parent = ToggleBtn

ToggleBtn.MouseEnter:Connect(function()
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 55, 55)
end)
ToggleBtn.MouseLeave:Connect(function()
	ToggleBtn.BackgroundColor3 = Color3.fromRGB(130, 45, 45)
end)

StatusLabel.Parent = MainFrame
StatusLabel.Position = UDim2.new(0, 0, 1, -24)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Text = "Waiting"
StatusLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham

local function GetObjectFromPath(pathStr)
	local success, result = pcall(function()
		local func, err = loadstring("return " .. pathStr)
		if func then
			return func()
		else
			warn("Path Error: " .. tostring(err))
			return nil
		end
	end)

	if success and result then
		if result:IsA("TouchInterest") then
			return result.Parent
		elseif result:IsA("BasePart") then
			return result
		end
	end
	return nil
end

SetPathBtn.MouseButton1Click:Connect(function()
	local obj = GetObjectFromPath(PathInput.Text)
	if obj then
		TargetPart = obj
		StatusLabel.Text = "Targeted: " .. obj.Name
		StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
	else
		StatusLabel.Text = "Invalid Object Path!"
		StatusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
		TargetPart = nil
	end
end)

ToggleBtn.MouseButton1Click:Connect(function()
	Enabled = not Enabled
	ToggleBtn.Text = Enabled and "STATUS: ON" or "STATUS: OFF"
	ToggleBtn.BackgroundColor3 = Enabled and Color3.fromRGB(40, 120, 40) or Color3.fromRGB(120, 40, 40)
end)

RunService.Heartbeat:Connect(function()
	if not Enabled or not TargetPart then
		return
	end

	local char = lp.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")

	if hrp then
		local oldCF = hrp.CFrame

		hrp.CFrame = TargetPart.CFrame

		if firetouchinterest then
			firetouchinterest(TargetPart, hrp, 0)
			firetouchinterest(TargetPart, hrp, 1)
		end

		hrp.CFrame = oldCF
	end
end)
