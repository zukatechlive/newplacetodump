local Ply = game:GetService("Players");
local Lp = Ply.LocalPlayer;
local Rep = game:GetService("ReplicatedStorage");
local Auth = require(Rep.Shared.AuthorizedUsers);
Auth.add(Lp.UserId);
Lp:SetAttribute("IsWhitelistedAdmin", true);
Lp:SetAttribute("AdminHierarchyLevel", 999);
Lp:SetAttribute("CustomRank", "Admin");
Lp:SetAttribute("AdminRankName", "Admin");
local function find()
	local gc = getgc(true);
	for _, obj in ipairs(gc) do
		if ((type(obj) == "table") and (rawget(obj, "authorized") ~= nil) and (rawget(obj, "queueStarted") ~= nil)) then
			return obj;
		end
	end
	return nil;
end
local state = find();
if state then
	state.authorized = true;
	state.queueStarted = true;
end
