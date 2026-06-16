local Workspace = game:GetService("Workspace")

local function acquireL4Card()
	local targetName = "L4 Keycard Giver"
	local targetObject = nil

	targetObject = Workspace:FindFirstChild(targetName, true)

	if targetObject then
		local detector = targetObject:FindFirstChildOfClass("ClickDetector")

		if detector then
			fireclickdetector(detector)
			print("[scp]: card grabbed")
		else
			warn("[scp]: Found '" .. targetName .. "' but it has no ClickDetector.")
		end
	else
		warn("[scp]: '" .. targetName .. "' not found. Searching for similar names...")
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj.Name:find("L4") and obj:FindFirstChildOfClass("ClickDetector") then
				fireclickdetector(obj:FindFirstChildOfClass("ClickDetector"))
				print("[scp]: gay L4 source: " .. obj:GetFullName())
				return
			end
		end
		warn("[scp]: error fuck")
	end
end

acquireL4Card()
