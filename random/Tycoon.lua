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
}

local overrides = {
	DelayAfterFiring = 0,
	LaserBeamStartupDelay = 0,
	ReduceSelfDamageOnAirOnly = 999999,
	CriticalDamageEnabled = 999999,
	MeleeCriticalDamageMultiplier = 999999,
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
	BulletsPerShot = 2,
	TacticalReloadTime = 0,
	SwitchTime = 0,
	BounceDelay = 0,
	AngleXMin = 0,
	DamageThroughWall = 999999,
	Accuracy = 0,
}

for _, gunName in ipairs(guns) do
	local ok, result = pcall(function()
		return require(GunSettings[gunName]["1"])
	end)

	if not ok then
		warn(("patched! aint that shitty"):format(gunName, result))
		continue
	end

	local mod = result

	if setreadonly then
		setreadonly(mod, false)
	end

	for key, value in pairs(overrides) do
		mod[key] = value
	end

	if setreadonly then
		setreadonly(mod, true)
	end

	print(("we're lit"):format(gunName))
end
