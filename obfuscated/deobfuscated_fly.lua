local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

local ANIMATIONS = {
	DefaultIdle = { id = "rbxassetid://11394033602", start = 1, stop = 1.22, speed = 0.2 },
	ChillLevitate = { id = "rbxassetid://125815409725539", start = 1, stop = 2.6, speed = 0.5 },
	FlashyFly = { id = "rbxassetid://83375399295408", start = 0.9, stop = 1.8, speed = 0.6 },
	MetroMan = { id = "rbxassetid://74645777874912", start = 0.1, stop = 1.8, speed = 0.7 },
	MustacheMark = { id = "rbxassetid://77807262438365", start = 0.1, stop = 3, speed = 1.0 },
	ZombieMark = { id = "rbxassetid://75532269733454", start = 0.1, stop = 3, speed = 1.0 },
	RelaxedFly = { id = "rbxassetid://132783162476851", start = 0.1, stop = 5, speed = 1.0 },
	TrackSuitMark = { id = "rbxassetid://125313210961391", start = 0.1, stop = 4, speed = 1.0 },
	LongHairMark = { id = "rbxassetid://101003076314239", start = 0.1, stop = 4, speed = 1.0 },
	FlaxanMark = { id = "rbxassetid://108933593456838", start = 0.1, stop = 4, speed = 1.0 },
	MasklessMark = { id = "rbxassetid://72952994235315", start = 0.1, stop = 4, speed = 1.0 },
	ViltrimiteMark = { id = "rbxassetid://124574039035034", start = 0.1, stop = 5, speed = 1.0 },
	PrisonerMark = { id = "rbxassetid://98385196315632", start = 1, stop = 4, speed = 0.6 },
	TargetMark = { id = "rbxassetid://122741335712327", start = 1, stop = 5.5, speed = 0.6 },
	NoGoggles = { id = "rbxassetid://77715558557237", start = 1, stop = 5, speed = 0.7 },
	SheistyMark = { id = "rbxassetid://121605966423204", start = 1, stop = 3.9, speed = 0.6 },
	AnnoyedIdle = { id = "rbxassetid://93326430026112", start = 0.2, stop = 3, speed = 1.2 },
	UpsideDown = { id = "rbxassetid://100566641677826", start = 0.1, stop = 3, speed = 1.0 },
	Conquest = { id = "rbxassetid://91850736796162", start = 0.5, stop = 2.5, speed = 0.7 },
	MohawkMark = { id = "rbxassetid://116733977004098", start = 0.5, stop = 3.5, speed = 1.0 },
	BulletProofMark = { id = "rbxassetid://95218435498795", start = 0.5, stop = 3.5, speed = 1.0 },
}

local ANIM_ORDER = {
	"DefaultIdle",
	"ChillLevitate",
	"FlashyFly",
	"MetroMan",
	"MustacheMark",
	"ZombieMark",
	"RelaxedFly",
	"TrackSuitMark",
	"LongHairMark",
	"FlaxanMark",
	"MasklessMark",
	"ViltrimiteMark",
	"PrisonerMark",
	"TargetMark",
	"NoGoggles",
	"SheistyMark",
	"AnnoyedIdle",
	"UpsideDown",
	"Conquest",
	"MohawkMark",
	"BulletProofMark",
}

local AnimState = {
	currentName = "DefaultIdle",
	track = nil,
}

local function stopAnim()
	if AnimState.track then
		if AnimState.track.IsPlaying then
			AnimState.track:Stop(0.3)
		end
		AnimState.track = nil
	end
end

local function playAnim(name, hrp)
	local data = ANIMATIONS[name]
	if not data or not hrp then
		return
	end

	local char = hrp.Parent
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator", hum)
	end

	stopAnim()

	local animObj = Instance.new("Animation")
	animObj.AnimationId = data.id
	local track = animator:LoadAnimation(animObj)
	track:Play(0.3, 1, data.speed)
	AnimState.track = track
	AnimState.currentName = name
end

local function switchAnim(name, hrp, isFlying)
	if not ANIMATIONS[name] then
		return
	end
	if isFlying then
		playAnim(name, hrp)
	else
		AnimState.currentName = name
	end
end

local ARM_PARTS = {
	"Left Arm",
	"Right Arm",
	"LeftHand",
	"RightHand",
	"LeftLowerArm",
	"RightLowerArm",
	"LeftUpperArm",
	"RightUpperArm",
}
local armConn

local function setArmVisibility(show)
	if armConn then
		armConn:Disconnect()
		armConn = nil
	end
	if not show then
		return
	end
	armConn = RunService.RenderStepped:Connect(function()
		local char = LocalPlayer.Character
		if not char then
			return
		end
		for _, partName in ipairs(ARM_PARTS) do
			local part = char:FindFirstChild(partName)
			if part then
				part.LocalTransparencyModifier = 0
				for _, child in ipairs(part:GetChildren()) do
					if child:IsA("Decal") or child:IsA("Texture") then
						child.Transparency = 0
					elseif child:IsA("MeshPart") then
						child.LocalTransparencyModifier = 0
					end
				end
			end
		end
	end)
end

local function DoNotif(msg, dur)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Fly",
			Text = msg,
			Duration = dur or 2,
		})
	end)
end

local Fly = {
	State = {
		IsActive = false,
		Connections = {},
		BodyMovers = {},
		Keys = {},
		Gamepad = { Left = Vector3.zero, RightTrigger = 0, LeftTrigger = 0 },
	},
	Config = {
		Speed = 100,
		SprintMultiplier = 8.5,
		Acceleration = 18,
		Deceleration = 14,
		TiltAngle = 20,
		TiltSpeed = 10,
		BoostMultiplier = 4,
		BoostDuration = 0.6,
		BoostCooldown = 3.0,
		HoverAmplitude = 0.25,
		HoverFrequency = 0.55,
		HoverRollAmount = 1.8,
		HoverBlendSpeed = 5,
		StopDeadzone = 0.12,
		VelocityDamping = 0.88,
	},
	_vel = Vector3.zero,
	_tiltCF = CFrame.identity,
	_hoverTime = 0,
	_hoverBlend = 0,
	_altLocked = false,
	_lockedY = 0,
}

local function expDecay(a, b, tau, dt)
	return a + (b - a) * (1 - math.exp(-dt / tau))
end
local function accelToTau(accel)
	return 1 / math.max(accel, 0.001)
end

function Fly:SetSpeed(s)
	local n = tonumber(s)
	if n and n > 0 then
		self.Config.Speed = n
		DoNotif("Fly speed → " .. n, 1)
	else
		DoNotif("Invalid speed.", 1)
	end
end

function Fly:SetAcceleration(a)
	local n = tonumber(a)
	if n and n > 0 then
		self.Config.Acceleration = n
		DoNotif("Fly acceleration → " .. n, 1)
	else
		DoNotif("Invalid value.", 1)
	end
end

function Fly:ToggleAltitudeLock()
	local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	self._altLocked = not self._altLocked
	self._lockedY = hrp.Position.Y
	DoNotif(self._altLocked and ("Altitude locked @ Y=" .. math.round(self._lockedY)) or "Altitude unlocked", 1)
end

function Fly:Disable()
	if not self.State.IsActive then
		return
	end
	self.State.IsActive = false
	self._vel = Vector3.zero
	self._tiltCF = CFrame.identity
	self._hoverBlend = 0
	self._hoverTime = 0
	self._altLocked = false
	self._boostActive = false

	stopAnim()
	setArmVisibility(false)

	local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if h then
		h.PlatformStand = false
	end

	for _, mover in pairs(self.State.BodyMovers) do
		if mover and mover.Parent then
			mover:Destroy()
		end
	end
	for _, conn in ipairs(self.State.Connections) do
		conn:Disconnect()
	end
	table.clear(self.State.BodyMovers)
	table.clear(self.State.Connections)
	table.clear(self.State.Keys)
	DoNotif("Fly disabled.", 1)
end

function Fly:Enable()
	if self.State.IsActive then
		return
	end

	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and humanoid) then
		DoNotif("Character required.", 1)
		return
	end

	self.State.IsActive = true
	humanoid.PlatformStand = true
	DoNotif("Fly enabled. [U] for animations, [X] alt-lock.", 3)

	playAnim(AnimState.currentName, hrp)
	setArmVisibility(true)

	local attachment = Instance.new("Attachment", hrp)

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.Responsiveness = 200
	alignOrientation.MaxTorque = math.huge
	alignOrientation.Parent = hrp

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.MaxForce = math.huge
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.Parent = hrp

	self.State.BodyMovers.Attachment = attachment
	self.State.BodyMovers.AlignOrientation = alignOrientation
	self.State.BodyMovers.LinearVelocity = linearVelocity

	local function onInput(input, gameProcessed)
		if gameProcessed then
			return
		end
		local down = input.UserInputState == Enum.UserInputState.Begin
		self.State.Keys[input.KeyCode] = down
		if down and input.KeyCode == Enum.KeyCode.X then
			self:ToggleAltitudeLock()
		end
	end

	local function onThumbstick(input)
		local gp = self.State.Gamepad
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			gp.Left = input.Position
		elseif input.KeyCode == Enum.KeyCode.ButtonR2 then
			gp.RightTrigger = input.Position.Z
		elseif input.KeyCode == Enum.KeyCode.ButtonL2 then
			gp.LeftTrigger = input.Position.Z
		end
	end

	table.insert(self.State.Connections, UserInputService.InputBegan:Connect(onInput))
	table.insert(self.State.Connections, UserInputService.InputEnded:Connect(onInput))
	table.insert(self.State.Connections, UserInputService.InputChanged:Connect(onThumbstick))

	local loop = RunService.Heartbeat:Connect(function(dt)
		if not self.State.IsActive or not hrp.Parent then
			return
		end
		dt = math.min(dt, 0.05)

		local camera = workspace.CurrentCamera
		local keys = self.State.Keys
		local cfg = self.Config
		local gp = self.State.Gamepad
		local camLook = camera.CFrame.LookVector
		local camRight = camera.CFrame.RightVector

		local dx, dy, dz = 0, 0, 0
		if keys[Enum.KeyCode.W] then
			dx += camLook.X
			dy += camLook.Y
			dz += camLook.Z
		end
		if keys[Enum.KeyCode.S] then
			dx -= camLook.X
			dy -= camLook.Y
			dz -= camLook.Z
		end
		if keys[Enum.KeyCode.D] then
			dx += camRight.X
			dy += camRight.Y
			dz += camRight.Z
		end
		if keys[Enum.KeyCode.A] then
			dx -= camRight.X
			dy -= camRight.Y
			dz -= camRight.Z
		end
		if keys[Enum.KeyCode.Space] or keys[Enum.KeyCode.E] then
			dy += 1
		end
		if keys[Enum.KeyCode.LeftControl] or keys[Enum.KeyCode.O] then
			dy -= 1
		end

		local gpFlat = Vector3.new(gp.Left.X, 0, -gp.Left.Y)
		if gpFlat.Magnitude > 0.1 then
			local camFlat = CFrame.new(Vector3.zero, Vector3.new(camLook.X, 0, camLook.Z))
			local world = camFlat:VectorToWorldSpace(gpFlat)
			dx += world.X
			dy += world.Y
			dz += world.Z
		end
		dy += gp.RightTrigger - gp.LeftTrigger

		local speed = cfg.Speed
		if keys[Enum.KeyCode.LeftShift] then
			speed = speed * cfg.SprintMultiplier
		end
		if keys[Enum.KeyCode.Q] then
			speed = speed * cfg.BoostMultiplier
		end

		local mag2 = dx * dx + dy * dy + dz * dz
		local hasInput = mag2 > 0.0001
		local targetX, targetY, targetZ

		if hasInput then
			local invMag = speed / math.sqrt(mag2)
			targetX, targetY, targetZ = dx * invMag, dy * invMag, dz * invMag
		else
			targetX, targetY, targetZ = 0, 0, 0
		end

		local tau = accelToTau(hasInput and cfg.Acceleration or cfg.Deceleration)
		local vx = expDecay(self._vel.X, targetX, tau, dt)
		local vy = expDecay(self._vel.Y, targetY, tau, dt)
		local vz = expDecay(self._vel.Z, targetZ, tau, dt)

		if not hasInput then
			local damp = cfg.VelocityDamping ^ dt
			vx, vy, vz = vx * damp, vy * damp, vz * damp
		end

		if not hasInput and (vx * vx + vy * vy + vz * vz) < cfg.StopDeadzone * cfg.StopDeadzone then
			vx, vy, vz = 0, 0, 0
		end

		self._vel = Vector3.new(vx, vy, vz)

		self._hoverTime += dt
		local hoverOsc = math.sin(self._hoverTime * cfg.HoverFrequency * math.pi * 2)
		local horizSpeed = math.sqrt(vx * vx + vz * vz)
		local moving = (horizSpeed + math.abs(vy)) > 0.5
		local targetBlend = moving and 0 or 1
		local blendTau = (targetBlend > self._hoverBlend) and accelToTau(cfg.HoverBlendSpeed) or 0.05
		self._hoverBlend = expDecay(self._hoverBlend, targetBlend, blendTau, dt)

		local hoverY = hoverOsc * cfg.HoverAmplitude * self._hoverBlend
		local hoverRoll = math.rad(cfg.HoverRollAmount * hoverOsc * self._hoverBlend)

		local finalVX = vx
		local finalVY = vy
		local finalVZ = vz

		if self._altLocked then
			finalVY = (self._lockedY - hrp.Position.Y) * 12
		else
			finalVY = finalVY + hoverY * 6
		end

		linearVelocity.VectorVelocity = Vector3.new(finalVX, finalVY, finalVZ)

		local tiltCF = CFrame.identity
		if horizSpeed > 1.0 then
			local maxSpeed = cfg.Speed * cfg.SprintMultiplier
			local speedRatio = math.clamp(horizSpeed / maxSpeed, 0, 1)
			local tiltDeg = cfg.TiltAngle * speedRatio
			local camYaw = CFrame.new(Vector3.zero, Vector3.new(camLook.X, 0, camLook.Z))
			local horizDir = Vector3.new(vx, 0, vz).Unit
			local localDir = camYaw:Inverse():VectorToObjectSpace(horizDir)
			tiltCF = CFrame.Angles(math.rad(-tiltDeg * localDir.Z), 0, math.rad(-tiltDeg * localDir.X))
		end

		self._tiltCF = self._tiltCF:Lerp(tiltCF, 1 - math.exp(-dt * cfg.TiltSpeed))
		alignOrientation.CFrame = camera.CFrame * self._tiltCF * CFrame.Angles(0, 0, hoverRoll)
	end)

	table.insert(self.State.Connections, loop)
end

function Fly:Toggle()
	if self.State.IsActive then
		self:Disable()
	else
		self:Enable()
	end
end

local uiGui, uiPanel
local uiVisible = false

local function buildUI()
	if uiGui then
		pcall(function()
			uiGui:Destroy()
		end)
	end

	uiGui = Instance.new("ScreenGui")
	uiGui.Name = "FlyAnimUI"
	uiGui.ResetOnSpawn = false
	uiGui.DisplayOrder = 50
	uiGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	uiPanel = Instance.new("Frame", uiGui)
	uiPanel.Name = "Panel"
	uiPanel.Size = UDim2.new(0, 270, 0, 430)
	uiPanel.Position = UDim2.new(1, 50, 0.5, -215)
	uiPanel.BackgroundColor3 = Color3.fromRGB(12, 6, 20)
	uiPanel.BackgroundTransparency = 0.08
	uiPanel.BorderSizePixel = 0
	uiPanel.Visible = false
	local pc = Instance.new("UICorner", uiPanel)
	pc.CornerRadius = UDim.new(0, 10)
	local ps = Instance.new("UIStroke", uiPanel)
	ps.Color = Color3.fromRGB(120, 60, 200)
	ps.Thickness = 1.5

	local titleBar = Instance.new("Frame", uiPanel)
	titleBar.Size = UDim2.new(1, 0, 0, 36)
	titleBar.BackgroundColor3 = Color3.fromRGB(70, 35, 120)
	titleBar.BorderSizePixel = 0
	local tc = Instance.new("UICorner", titleBar)
	tc.CornerRadius = UDim.new(0, 10)
	local tp = Instance.new("Frame", titleBar)
	tp.Size = UDim2.new(1, 0, 0, 10)
	tp.Position = UDim2.new(0, 0, 1, -10)
	tp.BackgroundColor3 = Color3.fromRGB(70, 35, 120)
	tp.BorderSizePixel = 0

	local titleLbl = Instance.new("TextLabel", titleBar)
	titleLbl.Size = UDim2.new(1, -10, 1, 0)
	titleLbl.Position = UDim2.new(0, 10, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "✦ Flight Animations"
	titleLbl.TextColor3 = Color3.fromRGB(240, 200, 255)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 14
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left

	local currentLbl = Instance.new("TextLabel", uiPanel)
	currentLbl.Size = UDim2.new(1, -16, 0, 20)
	currentLbl.Position = UDim2.new(0, 8, 0, 40)
	currentLbl.BackgroundTransparency = 1
	currentLbl.Text = "Playing: " .. AnimState.currentName
	currentLbl.TextColor3 = Color3.fromRGB(180, 140, 230)
	currentLbl.Font = Enum.Font.Gotham
	currentLbl.TextSize = 11
	currentLbl.TextXAlignment = Enum.TextXAlignment.Left

	local scroll = Instance.new("ScrollingFrame", uiPanel)
	scroll.Size = UDim2.new(1, -16, 1, -70)
	scroll.Position = UDim2.new(0, 8, 0, 64)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 60, 200)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.BorderSizePixel = 0

	local autoCanvas = pcall(function()
		scroll.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
	end)

	local layout = Instance.new("UIListLayout", scroll)
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	local lpad = Instance.new("UIPadding", scroll)
	lpad.PaddingTop = UDim.new(0, 3)
	lpad.PaddingBottom = UDim.new(0, 3)

	if not autoCanvas then
		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
		end)
	end

	for i, animName in ipairs(ANIM_ORDER) do
		local btn = Instance.new("TextButton", scroll)
		btn.Name = animName
		btn.Size = UDim2.new(1, -4, 0, 32)
		btn.BackgroundColor3 = (animName == AnimState.currentName) and Color3.fromRGB(80, 40, 140)
			or Color3.fromRGB(30, 15, 50)
		btn.BackgroundTransparency = 0.1
		btn.Text = animName
		btn.TextColor3 = Color3.fromRGB(220, 190, 255)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 13
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.LayoutOrder = i
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

		local hiColor = Color3.fromRGB(65, 32, 110)
		local selColor = Color3.fromRGB(90, 45, 155)
		local defColor = Color3.fromRGB(30, 15, 50)

		local hi = TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = hiColor })
		local out = TweenService:Create(
			btn,
			TweenInfo.new(0.1),
			{ BackgroundColor3 = (animName == AnimState.currentName) and selColor or defColor }
		)
		btn.MouseEnter:Connect(function()
			hi:Play()
		end)
		btn.MouseLeave:Connect(function()
			out:Play()
		end)

		btn.MouseButton1Click:Connect(function()
			for _, b in ipairs(scroll:GetChildren()) do
				if b:IsA("TextButton") then
					b.BackgroundColor3 = defColor
				end
			end
			btn.BackgroundColor3 = selColor
			currentLbl.Text = "Playing: " .. animName

			local char = LocalPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			switchAnim(animName, hrp, Fly.State.IsActive)
		end)
	end

	do
		local dragging, dragStart, startPos
		titleBar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = i.Position
				startPos = uiPanel.Position
			end
		end)
		titleBar.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - dragStart
				uiPanel.Position =
					UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
	end
end

local function toggleUI()
	if not uiGui or not uiGui.Parent then
		buildUI()
	end
	uiVisible = not uiVisible
	uiPanel.Visible = true
	if uiVisible then
		uiPanel.Position = UDim2.new(1, 50, 0.5, -215)
		TweenService:Create(uiPanel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -290, 0.5, -215),
		}):Play()
	else
		TweenService:Create(uiPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 50, 0.5, -215),
		}):Play()
		task.delay(0.35, function()
			if not uiVisible then
				uiPanel.Visible = false
			end
		end)
	end
end

local function buildToggleButton()
	local existing = LocalPlayer.PlayerGui:FindFirstChild("FlyToggleBtn")
	if existing then
		existing:Destroy()
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "FlyToggleBtn"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 49
	sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local btn = Instance.new("ImageButton", sg)
	btn.Name = "ToggleButton"
	btn.Size = UDim2.new(0, 52, 0, 52)
	btn.Position = UDim2.new(1, -70, 0.1, 0)
	btn.AnchorPoint = Vector2.new(1, 0)
	btn.BackgroundColor3 = Color3.fromRGB(90, 50, 140)
	btn.BackgroundTransparency = 0.4
	btn.Image = "rbxassetid://135684785837881"
	btn.ScaleType = Enum.ScaleType.Fit
	btn.ImageColor3 = Color3.fromRGB(240, 200, 255)
	btn.AutoButtonColor = false
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

	local grad = Instance.new("UIGradient", btn)
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 70, 180)),
		ColorSequenceKeypoint.new(0.3, Color3.fromRGB(160, 100, 220)),
		ColorSequenceKeypoint.new(0.7, Color3.fromRGB(180, 120, 240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 70, 180)),
	})
	grad.Rotation = 45
	TweenService:Create(grad, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Rotation = 405,
	}):Play()

	local glow = Instance.new("ImageLabel", btn)
	glow.Size = UDim2.new(1, 40, 1, 40)
	glow.Position = UDim2.new(0, -20, 0, -20)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://5028857084"
	glow.ImageColor3 = Color3.fromRGB(100, 50, 150)
	glow.ImageTransparency = 0.8
	glow.ScaleType = Enum.ScaleType.Slice
	glow.SliceCenter = Rect.new(24, 24, 276, 276)
	glow.ZIndex = -1

	btn.MouseButton1Click:Connect(function()
		toggleUI()
		local col = uiVisible and Color3.fromRGB(200, 150, 255) or Color3.fromRGB(240, 200, 255)
		TweenService:Create(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			ImageColor3 = col,
		}):Play()
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		Fly:Toggle()
	elseif input.KeyCode == Enum.KeyCode.U then
		toggleUI()
	end
end)

buildUI()
buildToggleButton()

return Fly
