local Players         = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local AttackEvent = ReplicatedStorage.Remotes:WaitForChild("AttackEvent")

-- How many remote fires per burst and the minimum seconds between bursts.
-- At 60fps, FIRE_INTERVAL = 0.1 means ~10 bursts/sec max — tune to taste.
local FIRES_PER_BURST = 2
local FIRE_INTERVAL   = 0.1  -- seconds between bursts

local enabled    = false
local lastFire   = 0

-- ── GUI ───────────────────────────────────────────────────────────────────────

local function createGui()
	-- Clean up any leftover instance from a previous run
	local existing = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("AutoFireGui")
	if existing then existing:Destroy() end

	local gui = Instance.new("ScreenGui")
	gui.Name = "AutoFireGui"
	gui.ResetOnSpawn = false
	gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local btn = Instance.new("TextButton")
	btn.Name        = "ToggleBtn"
	btn.Size        = UDim2.new(0, 120, 0, 40)
	btn.Position    = UDim2.new(0.5, -60, 0.9, -40)
	btn.BorderSizePixel = 0
	btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	btn.BackgroundTransparency = 0.6
	btn.TextColor3  = Color3.fromRGB(255, 255, 255)
	btn.Font        = Enum.Font.SourceSansBold
	btn.TextSize    = 18
	btn.Text        = "OFF"
	btn.Parent      = gui

	return btn
end

local ToggleBtn = createGui()

local function updateBtn()
	if enabled then
		ToggleBtn.Text = "ON"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		ToggleBtn.BackgroundTransparency = 0
	else
		ToggleBtn.Text = "OFF"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		ToggleBtn.BackgroundTransparency = 0.6
	end
end

local function toggle()
	enabled = not enabled
	updateBtn()
end

-- ── Input ─────────────────────────────────────────────────────────────────────

ToggleBtn.MouseButton1Click:Connect(toggle)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	-- Keyboard: F
	if input.UserInputType == Enum.UserInputType.Keyboard
		and input.KeyCode == Enum.KeyCode.F then
		toggle()
	end

	-- Gamepad: R3
	if input.UserInputType == Enum.UserInputType.Gamepad1
		and input.KeyCode == Enum.KeyCode.ButtonR3 then
		toggle()
	end
end)

-- ── Fire Loop ─────────────────────────────────────────────────────────────────

-- Heartbeat keeps firing decoupled from the render pipeline.
-- FIRE_INTERVAL throttles how often the remote is actually called
-- so you're not hammering the server 60+ times a second.
RunService.Heartbeat:Connect(function()
	if not enabled then return end

	local now = tick()
	if now - lastFire < FIRE_INTERVAL then return end
	lastFire = now

	for _ = 1, FIRES_PER_BURST do
		AttackEvent:FireServer()
	end
end)

updateBtn()
