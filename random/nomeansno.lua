local theMainPlayer = game:GetService("Players").LocalPlayer
local theCoolChar = theMainPlayer.Character or theMainPlayer.CharacterAdded:Wait()
local theHuman = theCoolChar:WaitForChild("Humanoid")

local theMeta = getrawmetatable(game)
local theOldIndex = theMeta.__index
local theOldNewIndex = theMeta.__newindex
local theOldNamecall = theMeta.__namecall
setreadonly(theMeta, false)

theMeta.__index = newcclosure(function(theObj, theKey)
	if not checkcaller() and theObj:IsA("Humanoid") and theObj == theHuman then
		if theKey == "WalkSpeed" then
			return 16
		end
		if theKey == "JumpPower" then
			return 50
		end
		if theKey == "Health" then
			return 100
		end
	end
	return theOldIndex(theObj, theKey)
end)

theMeta.__newindex = newcclosure(function(theObj, theKey, theVal)
	if not checkcaller() then
		if
			theObj == theHuman
			and (theKey == "WalkSpeed" or theKey == "JumpPower" or theKey == "PlatformStand" or theKey == "Sit")
		then
			return nil
		end
		if
			theObj:IsDescendantOf(theCoolChar) and (theKey == "CFrame" or theKey == "Position" or theKey == "Anchored")
		then
			return nil
		end
	end
	return theOldNewIndex(theObj, theKey, theVal)
end)

theMeta.__namecall = newcclosure(function(theObj, ...)
	local theMethod = getnamecallmethod()
	if not checkcaller() then
		if theObj == theMainPlayer and theMethod == "Kick" then
			return nil
		end
		if theObj:IsDescendantOf(theCoolChar) and (theMethod == "Destroy" or theMethod == "BreakJoints") then
			return nil
		end
		if theObj == theCoolChar and (theMethod == "MoveTo" or theMethod == "SetPrimaryPartCFrame") then
			return nil
		end
	end
	return theOldNamecall(theObj, ...)
end)

setreadonly(theMeta, true)
