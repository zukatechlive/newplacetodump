

local targetModule = require(game:GetService("ReplicatedStorage").Modules.WeaponSettings.Gun.PumpkinLauncher.Setting["1"])
if setreadonly then setreadonly(targetModule, false) end

targetModule.LaserTrailConstantDamage = 999999 -- [zukv2]
targetModule.PenetrationIgnoreDelay = 0 -- [zukv2]
targetModule.AngleX_Min = 0 -- [zukv2]
targetModule.Spread = 0 -- [zukv2]
targetModule.BaseDamage = 999999 -- [zukv2]
targetModule.LaserTrailDamageRate = 999999 -- [zukv2]
targetModule.ChargingTime = 0 -- [zukv2]
targetModule.EquipTime = 0.1 -- [zukv2]
targetModule.BurstRate = 0.1 -- [zukv2]
targetModule.Recoil = 0 -- [zukv2]
targetModule.LaserTrailDamage = 999999 -- [zukv2]
targetModule.ShotgunEnabled = true -- [zukv2]
targetModule.AmmoPerMag = 999999 -- [zukv2]
targetModule.FireRate = 0.1
targetModule.ZeroDamageDistance = 999999 -- [zukv2]
targetModule.TacticalReloadTime = 0 -- [zukv2]
targetModule.LaserTrailCriticalDamageMultiplier = 999999 -- [zukv2]
targetModule.DelayAfterFiring = 0 -- [zukv2]
targetModule.DelayBeforeFiring = 0 -- [zukv2]
targetModule.LaserTrailCriticalDamageEnabled = 999999 -- [zukv2]
targetModule.Range = 90000 -- [zukv2]
targetModule.DamageableLaserTrail = 999999 -- [zukv2]
targetModule.ReloadTime = 0.1 -- [zukv2]
targetModule.DamageBasedOnDistance = 999999 -- [zukv2]
targetModule.SwitchTime = 0 -- [zukv2]
targetModule.BulletPerShot = 11
targetModule.FullDamageDistance = 999999 -- [zukv2]
targetModule.HeadshotDamageMultiplier = 999999 -- [zukv2]
targetModule.Accuracy = 0 -- [zukv2]
targetModule.AngleX_Max = 0 -- [zukv2]
targetModule.SelfDamageRedution = 999999 -- [zukv2]
targetModule.ExplosionRadius =129
targetModule.BulletSpeed = 1111
targetModule.Auto = false

if setreadonly then setreadonly(targetModule, true) end
print('--> [zukv2]: 1 has been updated.')
