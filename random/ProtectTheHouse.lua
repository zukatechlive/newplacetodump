local WeaponSettings = game:GetService("ReplicatedStorage").Modules.WeaponSettings.Gun
	for _, weapon in ipairs(WeaponSettings:GetChildren()) do
		local settingFolder = weapon:FindFirstChild("Setting")
		if settingFolder then
			local setting = settingFolder:FindFirstChild("1")
			if setting and setting:IsA("ModuleScript") then
				local module = require(setting)
				if setreadonly then
					setreadonly(module, false)
				end

				module.Spread = 0
				module.Auto = true
				module.EquipTime = 0
				module.Recoil = 0
				module.ShotgunEnabled = true
				module.AmmoPerMag = 999999
				module.TacticalReloadTime = 0
				module.DelayAfterFiring = 0
				module.DelayBeforeFiring = 0
				module.Range = 90000
				module.ReloadTime = 0
				module.SwitchTime = 0
				module.BulletPerShot = 5
				module.Accuracy = 0
        module.FireRate = 0.1

				-- module.ExplosiveEnabled = true
				if setreadonly then
					setreadonly(module, true)
				end
				print(" Zuka : " .. weapon.Name .. " modified ")
			end
		end
	end
