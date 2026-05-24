--[[ this does not give you access to any hdadmin script, this only reveals gui parts and tricks the game into thinking you have perms ]]


local function checkIntegrity()
	local mt = getrawmetatable(game)
	if not mt then
		warn("No metatable")
		return false
	end
	local idx = rawget(mt, "__index")
	if type(idx) ~= "function" and type(idx) ~= "table" then
	end
	return true
end
if not checkIntegrity() then
	error("Integrity check failed -- aborting", 2)
end

local function GetHDMain()
	for _, v in pairs(getgc(true)) do
		if type(v) == "table" and rawget(v, "GetModule") and rawget(v, "pdata") and rawget(v, "gui") then
			return v
		end
	end
end
local Main = GetHDMain()
if not Main then
	Main = _G.HDAdminMain or _G.HD
end
if not Main then
	return
end
local cf = Main:GetModule("cf")
cf.CheckPromptRank = function()
	return true
end
local originalActivate = cf.ActivateClientCommand
cf.ActivateClientCommand = function(self, cmdName, extra)
	Main.commandsAllowedToUse[cmdName] = true
	return originalActivate(self, cmdName, extra)
end
cf.UpdateIconVisiblity = function(self)
	local topbar = Main:GetModule("TopbarIcons")
	if topbar then
		if topbar.Dashboard then
			topbar.Dashboard:setEnabled(true)
		end
		if topbar.Commands then
			topbar.Commands:setEnabled(true)
		end
	end
end
Main.pdata.Rank = 255
Main.pdata.RankName = "Owner"
local guiModule = Main:GetModule("GUIs")
guiModule:DisplayPagesAccordingToRank(true)
cf:UpdateIconVisiblity()
if Main.commandRanks then
	for cmd, _ in pairs(Main.commandRanks) do
		Main.commandRanks[cmd] = 0
	end
end
local Main = _G.HDAdminMain or _G.HD
for _, v in pairs(getgc(true)) do
	if type(v) == "table" and rawget(v, "GetModule") and rawget(v, "pdata") then
		Main = v
		break
	end
end
local cf = Main:GetModule("cf")
local clientCommands = Main:GetModule("ClientCommands")
print("[] In...")
for cmdName, cmdTable in pairs(clientCommands) do
	if type(cmdTable) == "table" then
		Main.commandsAllowedToUse[cmdName] = true
	end
end
local oldRequest = Main.signals.RequestCommandSilent
Main.signals.RequestCommandSilent.InvokeServer = function(self, ...)
	local args = { ... }
	local cmdString = args[1]:lower()
	local prefix = Main.pdata.Prefix or ";"
	local cleanCmd = cmdString:gsub(prefix, ""):split(" ")[1]
	if clientCommands[cleanCmd] then
		task.spawn(function()
			if clientCommands[cleanCmd].Activate then
				clientCommands[cleanCmd].Activate(Main.player)
			end
		end)
		return
	end
	return oldRequest:InvokeServer(unpack(args))
end
local function SimulateFF()
	local char = game.Players.LocalPlayer.Character
	if char then
		local ff = Instance.new("ForceField")
		ff.Parent = char
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.MaxHealth = math.huge
			hum.Health = math.huge
		end
	end
end
local originalInvoke = Main.signals.RequestCommandSilent.InvokeServer
Main.signals.RequestCommandSilent.InvokeServer = function(self, ...)
	local cmd = ({ ... })[1]:lower()
	if cmd:find("ff") then
		SimulateFF()
		return
	end
	return originalInvoke(self, ...)
end
cf:UpdateIconVisiblity()
Main:GetModule("GUIs"):DisplayPagesAccordingToRank(true)
local Main = _G.HDAdminMain or _G.HD
for _, v in pairs(getgc(true)) do
	if type(v) == "table" and rawget(v, "GetModule") and rawget(v, "pdata") then
		Main = v
		break
	end
end
local cf = Main:GetModule("cf")
cf.GetGamepasses = function()
	local fakePasses = {}
	setmetatable(fakePasses, {
		__index = function()
			return { Name = "Spoofed Rank", GamepassId = 0, Owns = true }
		end,
	})
	return fakePasses
end
if Main.pdata then
	Main.pdata.Donor = true
	Main.pdata.Rank = 255
	Main.pdata.RankName = "Owner"
end
cf.CheckPromptRank = function()
	return true
end
cf.RankChangedUpdater = function()
end
task.spawn(function()
	local topbar = Main:GetModule("TopbarIcons")
	if topbar then
		if topbar.Dashboard then
			topbar.Dashboard:setEnabled(true)
		end
		if topbar.Commands then
			topbar.Commands:setEnabled(true)
		end
	end
	local gui = Main:GetModule("GUIs")
	gui:DisplayPagesAccordingToRank(true)
	local donorModule = Main:GetModule("PageDonor")
	if donorModule and donorModule.UpdateDonorStatus then
		donorModule:UpdateDonorStatus(true)
	end
end)

--this is a shitty script. 
