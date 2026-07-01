local theMainPlayer = game:GetService("Players").LocalPlayer
local thePlayerService = game:GetService("Players")
local thePhantomID = theMainPlayer.UserId
local theMeta = getrawmetatable(game)
local theOldIndex = theMeta.__index
local theOldNewIndex = theMeta.__newindex
local theOldNamecall = theMeta.__namecall

local isPhantomActive = true
local thePhantomCache = {}
local theFilteredResults = {}

local function filterPhantomFromTable(theTable, theDepth)
	theDepth = theDepth or 0
	if theDepth > 5 then
		return theTable
	end

	if not theTable or typeof(theTable) ~= "table" then
		return theTable
	end

	local theFiltered = {}
	for theIdx, theVal in ipairs(theTable) do
		if typeof(theVal) == "userdata" then
			if theVal == theMainPlayer then
			else
				table.insert(theFiltered, theVal)
			end
		else
			table.insert(theFiltered, theVal)
		end
	end

	return theFiltered
end

setreadonly(theMeta, false)

theMeta.__index = newcclosure(function(theObj, theKey)
	if theObj == thePlayerService and (theKey == "GetPlayers") then
		return newcclosure(function()
			local theAllPlayers = theOldIndex(theObj, theKey)()
			return filterPhantomFromTable(theAllPlayers)
		end)
	end

	if theObj:IsA("Folder") and theObj.Name == "Players" then
		if theKey == "GetChildren" then
			return newcclosure(function()
				local theChildren = theOldIndex(theObj, theKey)()
				return filterPhantomFromTable(theChildren)
			end)
		end
	end

	if theObj == theMainPlayer and theKey == "ClassName" then
		return "RemotePlayer"
	end

	if theObj == theMainPlayer and theKey == "Parent" then
		return nil
	end

	if theObj == thePlayerService and theKey == "FindFirstChild" then
		return newcclosure(function(theName, ...)
			if theName == "LocalPlayer" or theName == theMainPlayer.Name then
				return nil
			end
			return theOldIndex(theObj, "FindFirstChild")(theObj, theName, ...)
		end)
	end

	if theObj == thePlayerService and theKey == "WaitForChild" then
		return newcclosure(function(theName, ...)
			if theName == "LocalPlayer" or theName == theMainPlayer.Name then
				return nil
			end
			return theOldIndex(theObj, "WaitForChild")(theObj, theName, ...)
		end)
	end

	if theObj == theMainPlayer and (theKey == "UserId" or theKey == "UserID") then
		return -1
	end

	if theObj == theMainPlayer and theKey == "Name" then
		return "PhantomEntity"
	end

	return theOldIndex(theObj, theKey)
end)

theMeta.__newindex = newcclosure(function(theObj, theKey, theVal)
	if theObj == theMainPlayer then
		if theKey == "Parent" or theKey == "Name" or theKey == "UserId" then
			return nil
		end
	end

	return theOldNewIndex(theObj, theKey, theVal)
end)

theMeta.__namecall = newcclosure(function(theObj, ...)
	local theMethod = getnamecallmethod()
	local theArgs = { ... }

	if theObj == thePlayerService and theMethod == "GetPlayers" then
		local theAllPlayers = theOldNamecall(theObj, ...)
		return filterPhantomFromTable(theAllPlayers)
	end

	if theObj == thePlayerService then
		if theMethod == "FindFirstChild" then
			if theArgs[1] == "LocalPlayer" or theArgs[1] == theMainPlayer.Name then
				return nil
			end
		end
		if theMethod == "FindFirstChildOfClass" then
			if theArgs[1] == "Player" then
				local theResult = theOldNamecall(theObj, ...)
				if theResult == theMainPlayer then
					return nil
				end
				return theResult
			end
		end
	end

	if theMethod == "IsDescendantOf" then
		if theObj == theMainPlayer then
			return false
		end
	end

	if theMethod == "IsA" then
		if theObj == theMainPlayer then
			if theArgs[1] == "Player" then
				return false
			end
			if theArgs[1] == "RemotePlayer" then
				return true
			end
			return false
		end
	end

	return theOldNamecall(theObj, ...)
end)

setreadonly(theMeta, true)

local theTableMeta = getrawmetatable({})
setreadonly(theTableMeta, false)

local theOldTableIndex = theTableMeta.__index
theTableMeta.__index = newcclosure(function(theTable, theKey)
	return theOldTableIndex(theTable, theKey)
end)

setreadonly(theTableMeta, true)

if theMainPlayer.Character then
	local theCharacter = theMainPlayer.Character

	local theCharMeta = getrawmetatable(theCharacter)
	setreadonly(theCharMeta, false)

	local theCharOldIndex = theCharMeta.__index
	theCharMeta.__index = newcclosure(function(theObj, theKey)
		if theKey == "Parent" then
			return nil
		end
		return theCharOldIndex(theObj, theKey)
	end)

	setreadonly(theCharMeta, true)
end
