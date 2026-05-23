local TOGGLE_KEY = Enum.KeyCode.End
local SPAWN_PROTECTION_DURATION = 2
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local function DoNotif(msg, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "root",
			Text = msg,
			Duration = duration or 1.5,
		})
	end)
end
local State = {
	isProjecting = false,
	isSpawning = false,
	originalHRP = nil,
	originalParent = nil,
	deathConnection = nil,
	positionMarker = nil,
}
local PLAYER_GUI = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TopBarPlus"
screenGui.ResetOnSpawn = false
screenGui.Parent = PLAYER_GUI
local TopBarPlus = Instance.new("TextButton")
TopBarPlus.Name = "TopBarToggle"
TopBarPlus.Size = UDim2.fromOffset(64, 64)
TopBarPlus.AnchorPoint = Vector2.new(1, 1)
TopBarPlus.Position = UDim2.new(1, -20, 1, -100)
TopBarPlus.Font = Enum.Font.GothamBold
TopBarPlus.BackgroundTransparency = 0.5
TopBarPlus.Text = "Sync"
TopBarPlus.TextSize = 14
TopBarPlus.Parent = screenGui
Instance.new("UICorner", TopBarPlus).CornerRadius = UDim.new(1, 0)
local stroke = Instance.new("UIStroke", TopBarPlus)
stroke.Color = Color3.fromRGB(100, 100, 120)
stroke.Thickness = 1.5
local function updateUIState()
	if State.isSpawning then
		TopBarPlus.BackgroundColor3 = Color3.fromRGB(255, 160, 0)
		TopBarPlus.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif State.isProjecting then
		TopBarPlus.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
		TopBarPlus.TextColor3 = Color3.fromRGB(10, 10, 10)
	else
		TopBarPlus.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		TopBarPlus.TextColor3 = Color3.fromRGB(200, 200, 220)
	end
end
local function applyVisuals(character, isAstral)
	local highlight = character:FindFirstChild("Indicator")
	if isAstral and not highlight then
		highlight = Instance.new("Highlight", character)
		highlight.Name = "Indicator"
		highlight.FillColor = Color3.fromRGB(0, 200, 255)
		highlight.OutlineColor = Color3.fromRGB(200, 255, 255)
		highlight.FillTransparency = 0.5
	elseif not isAstral and highlight then
		highlight:Destroy()
	end
end
local function setState(shouldProject)
	if State.isSpawning then
		return
	end
	if State.isProjecting == shouldProject then
		return
	end
	local character = LocalPlayer.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if shouldProject then
		if not hrp or not humanoid then
			return
		end
		State.originalHRP = hrp
		State.originalParent = character
		local originalCFrame = hrp.CFrame
		hrp.Parent = nil
		State.isProjecting = true
		if State.positionMarker then
			State.positionMarker:Destroy()
		end
		local marker = Instance.new("Part")
		marker.Name = "PhysicalAnchor"
		marker.Size = Vector3.new(4, 5, 2)
		marker.CFrame = originalCFrame
		marker.Anchored = true
		marker.CanCollide = false
		marker.Transparency = 1
		marker.Parent = Workspace
		State.positionMarker = marker
		local hl = Instance.new("Highlight", marker)
		hl.FillColor = Color3.fromRGB(255, 50, 50)
		hl.OutlineColor = Color3.fromRGB(255, 255, 255)
		hl.FillTransparency = 0.6
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
		applyVisuals(character, true)
		DoNotif("ENABLED", 1.5)
	else
		if State.positionMarker then
			State.positionMarker:Destroy()
			State.positionMarker = nil
		end
		if State.originalHRP and State.originalParent then
			State.originalHRP.Parent = State.originalParent
		end
		State.originalHRP = nil
		State.originalParent = nil
		State.isProjecting = false
		applyVisuals(character, false)
		DoNotif("DISABLED", 1.5)
	end
	updateUIState()
end
local function makeDraggable(guiObject)
	local dragging, dragStart, startPos
	guiObject.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = guiObject.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local delta = input.Position - dragStart
			guiObject.Position =
				UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
end
local function onCharacterAdded(character)
	State.isSpawning = true
	updateUIState()
	if State.isProjecting then
		setState(false)
	end
	if State.deathConnection then
		State.deathConnection:Disconnect()
	end
	local humanoid = character:WaitForChild("Humanoid")
	State.deathConnection = humanoid.Died:Connect(function()
		setState(false)
	end)
	task.wait(SPAWN_PROTECTION_DURATION)
	State.isSpawning = false
	updateUIState()
end
makeDraggable(TopBarPlus)
TopBarPlus.MouseButton1Click:Connect(function()
	setState(not State.isProjecting)
end)
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == TOGGLE_KEY then
		setState(not State.isProjecting)
	end
end)
if LocalPlayer.Character then
	task.spawn(onCharacterAdded, LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
RunService.Heartbeat:Connect(function()
	if State.isProjecting and State.originalHRP and State.originalHRP.Parent ~= nil then
		State.originalHRP.Parent = nil
	end
end)
