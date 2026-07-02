local Players = game:GetService("Players")
local GunSettings = game:GetService("ReplicatedStorage").GunSettings
local guns = {
	"AK-47",
	"AA-12",
	"AUG",
	"AWP",
	"Revolver",
	"M1 Garand",
	"Glock",
	"LMG",
	"Deagle",
	"Crossbow",
	"Cosmic MP7",
	"Berreta",
	"Raygun",
	"Silenced Sniper",
	"P90",
	"Tactical Airstrike",
	"Incendiary Shotgun",
	"Spider",
	"Radioactive MP5",
	"RPG",
	"MP5",
	"Tommy Gun",
}

local overrides = {
	Debuff = true,
	DebuffChance = 100,
	DebuffName = IgniteScript,
	Auto = false,
	DelayAfterFiring = 0,
	LaserBeamStartupDelay = 0,
	CriticalDamageEnabled = 999999,
	HeadshotHitmarker = 100,
	ReloadTime = 0,
	Lifesteal = 99999,
	Spread = 0,
	ChargingTime = 0,
	HitIgnoreDelay = 0,
	BurstRate = 0,
	Recoil = 0,
	LaserTrailDamage = 999999,
	DelayBeforeFiring = 0,
	AmmoPerMag = 999999,
	Range = 90000,
	BulletsPerShot = 4,
	TacticalReloadTime = 0,
	SwitchTime = 0,
	AngleXMin = 0,
	DamageThroughWall = 999999,
	Accuracy = 0,
}

local function applyOverrides()
	for _, gunName in ipairs(guns) do
		local ok, result = pcall(function()
			return require(GunSettings[gunName]["1"])
		end)
		if not ok then
			warn(("patched! aint that nice"):format(gunName, result))
			continue
		end
		local mod = result
		if setreadonly then setreadonly(mod, false) end
		for key, value in pairs(overrides) do
			mod[key] = value
		end
		if setreadonly then setreadonly(mod, true) end
	end
end

applyOverrides()

-- GUI
local LocalPlayer = Players.LocalPlayer
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GunOverrideGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
local ok = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ok then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 180, 0, 60)
Frame.Position = UDim2.new(0.5, -90, 0.02, 0)
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

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, -10, 0, 20)
Label.Position = UDim2.new(0, 5, 0, 5)
Label.BackgroundTransparency = 1
Label.Text = "Auto: OFF"
Label.TextColor3 = Color3.fromRGB(220, 80, 80)
Label.TextSize = 13
Label.Font = Enum.Font.GothamBold
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.Parent = Frame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 26)
ToggleBtn.Position = UDim2.new(0, 10, 0, 28)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "Enable Auto"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 13
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = Frame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

ToggleBtn.MouseButton1Click:Connect(function()
	overrides.Auto = not overrides.Auto
	applyOverrides()
	if overrides.Auto then
		Label.Text = "Auto: ON"
		Label.TextColor3 = Color3.fromRGB(100, 220, 100)
		ToggleBtn.Text = "Disable Auto"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
	else
		Label.Text = "Auto: OFF"
		Label.TextColor3 = Color3.fromRGB(220, 80, 80)
		ToggleBtn.Text = "Enable Auto"
		ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	end
end)
