-- spoofer
if not game:IsLoaded() then
	game.Loaded:Wait()
end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local SPOOF_CONFIG = {
	TargetId = 919563980,
	SpoofName = true,
	SpoofDisplayName = true,
	SpoofRemotes = true,
	Debug = false,
}
if getgenv().AdminSpoofRunning then
	if getgenv().AdminSpoofCleanup then
		getgenv().AdminSpoofCleanup()
	end
	return
end
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	Players.PlayerAdded:Wait()
	LocalPlayer = Players.LocalPlayer
end
local State = {
	OriginalId = LocalPlayer.UserId,
	OriginalName = LocalPlayer.Name,
	OriginalDisplayName = LocalPlayer.DisplayName,
	SpoofedName = "",
	SpoofedDisplayName = "",
}
local function getInfo()
	local success, result = pcall(function()
		return game:HttpGet("https://users.roblox.com/v1/users/" .. SPOOF_CONFIG.TargetId)
	end)
	if success and result then
		local data = HttpService:JSONDecode(result)
		State.SpoofedName = data.name
		State.SpoofedDisplayName = data.displayName
	else
		State.SpoofedName = "Player"
		State.SpoofedDisplayName = "Player"
	end
end
getInfo()
local RawMt = getrawmetatable(LocalPlayer)
local OldIndex = RawMt.__index
local OldNamecall = RawMt.__namecall
setreadonly(RawMt, false)
RawMt.__index = newcclosure(function(self, key)
	if not checkcaller() and self == LocalPlayer then
		if key == "UserId" or key == "userId" then
			return SPOOF_CONFIG.TargetId
		end
		if SPOOF_CONFIG.SpoofName and (key == "Name" or key == "name") then
			return State.SpoofedName
		end
		if SPOOF_CONFIG.SpoofDisplayName and (key == "DisplayName" or key == "displayName") then
			return State.SpoofedDisplayName
		end
	end
	return OldIndex(self, key)
end)
if SPOOF_CONFIG.SpoofRemotes then
	RawMt.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()
		local args = { ... }
		if not checkcaller() and (method == "FireServer" or method == "InvokeServer") then
			for i, arg in ipairs(args) do
				if arg == State.OriginalId then
					args[i] = SPOOF_CONFIG.TargetId
				elseif arg == State.OriginalName then
					args[i] = State.SpoofedName
				end
			end
		end
		return OldNamecall(self, unpack(args))
	end)
end
setreadonly(RawMt, true)
getgenv().AdminSpoofCleanup = function()
	setreadonly(RawMt, false)
	RawMt.__index = OldIndex
	RawMt.__namecall = OldNamecall
	setreadonly(RawMt, true)
	getgenv().AdminSpoofRunning = false
	getgenv().AdminSpoofCleanup = nil
	print("[AdminSpoof] Spoof Disabled and Hooks Restored.")
end
getgenv().AdminSpoofRunning = true
print("[AdminSpoof] Autoexec Successful. Spoofing as: " .. State.SpoofedName)


local mt = getrawmetatable(game)
local origNC = rawget(mt, "__namecall")
if origNC and iscclosure and not iscclosure(origNC) then
    warn("[Security] __namecall hook detected -- possible remote spy")
end
local _mon = {}
local function watchRemote(remote)
    if _mon[remote] then return end
    _mon[remote] = true
    if islclosure and islclosure(remote.FireServer) then
        warn("[Security] FireServer hooked on", remote:GetFullName())
    end
end
-- watchRemote(game.ReplicatedStorage:WaitForChild("SomeRemote"))
