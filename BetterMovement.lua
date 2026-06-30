--!strict
local players = game:GetService("Players")
local runService = game:GetService("RunService")
local inputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local coreGui = game:GetService("CoreGui")

local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()

local mySettings = {
	icons = {
		on = "rbxasset://textures/ui/mouseLock_on.png",
		off = "rbxasset://textures/ui/mouseLock_off.png",
	},
	offsetValue = Vector3.new(2.2, 0, 0),
	smoothness = 0.2,
	key = Enum.KeyCode.LeftControl,
}

local currentStuff = {
	active = false,
	locked = false,
	guiItems = {},
	myEvents = {},
	oldData = {},
}

local function moveTheGui(theFrame, theHandle)
	local dragging = false
	local dragStart, startPos

	table.insert(currentStuff.myEvents, theHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = theFrame.Position

			local moveConn
			moveConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					moveConn:Disconnect()
				end
			end)
		end
	end))

	table.insert(currentStuff.myEvents, inputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			theFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end))
end

local function updateRotation()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local cam = workspace.CurrentCamera

	if not (hum and root and cam and hum.Health > 0) then return end

	if currentStuff.locked then
		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)

		if flat.Magnitude > 0.01 then
			root.CFrame = root.CFrame:Lerp(CFrame.lookAt(root.Position, root.Position + flat.Unit), 0.6)
		end

		hum.CameraOffset = hum.CameraOffset:Lerp(mySettings.offsetValue, mySettings.smoothness)
		inputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		if hum.CameraOffset.Magnitude > 0.01 then
			hum.CameraOffset = hum.CameraOffset:Lerp(Vector3.new(0,0,0), mySettings.smoothness)
		end
	end
end

local function setLock(state)
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")

	if state and hum and hum.Sit then return end

	currentStuff.locked = state

	if state then
		if hum then
			currentStuff.oldData.autoRotate = hum.AutoRotate
			hum.AutoRotate = false
		end
	else
		if hum and currentStuff.oldData.autoRotate ~= nil then
			hum.AutoRotate = currentStuff.oldData.autoRotate
		end
		inputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	local items = currentStuff.guiItems
	if items.btn then
		local color = state and Color3.fromRGB(0, 255, 150) or Color3.fromRGB(255, 255, 255)
		tweenService:Create(items.stroke, TweenInfo.new(0.2), {Color = color}):Play()
		items.img.Image = state and mySettings.icons.on or mySettings.icons.off
	end
end

local function startup()
	local screen = Instance.new("ScreenGui")
	screen.Name = "CoolShiftLock"
	screen.IgnoreGuiInset = true
	screen.Parent = coreGui

	local button = Instance.new("ImageButton")
	button.Size = UDim2.fromOffset(50, 50)
	button.Position = UDim2.new(0.5, 150, 0.8, 0)
	button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	button.BackgroundTransparency = 0.2
	button.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Parent = button

	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromScale(0.6, 0.6)
	icon.Position = UDim2.fromScale(0.2, 0.2)
	icon.BackgroundTransparency = 1
	icon.Image = mySettings.icons.off
	icon.Parent = button

	currentStuff.guiItems = {btn = button, img = icon, stroke = stroke, main = screen}
	
	moveTheGui(button, button)

	table.insert(currentStuff.myEvents, runService.RenderStepped:Connect(updateRotation))
	
	table.insert(currentStuff.myEvents, inputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == mySettings.key then
			setLock(not currentStuff.locked)
		end
	end))

	table.insert(currentStuff.myEvents, button.Activated:Connect(function()
		setLock(not currentStuff.locked)
	end))

	currentStuff.active = true
end

startup()
