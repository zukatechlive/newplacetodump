local runService = game:GetService("RunService")
local function getCombatTable()
	for _, v in pairs(getgc(true)) do
		if type(v) == "table" and rawget(v, "lastDash") and rawget(v, "comboCount") then
			return v
		end
	end
end
local combatTable = getCombatTable()
if combatTable then
	print("ORAORAORA")
	runService.Heartbeat:Connect(function()
		combatTable.lastDash = 0
		combatTable.dashing = false
		local char = game.Players.LocalPlayer.Character
		if char and char:GetAttribute("Dashing") then
			char:SetAttribute("Dashing", false)
		end
	end)
else
	warn("Oh, so it's the same type of script as infinite yield?")
end
local function StripKnockback(Root)
	for _, Child in ipairs(Root:GetChildren()) do
		if
			Child.Name == "ForwardMove"
			and (Child:IsA("BodyVelocity") or Child:IsA("LinearVelocity"))
			and not Child:GetAttribute("Validated")
		then
			Child:Destroy()
		end
	end
end
