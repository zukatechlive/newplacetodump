--[[
    PHANTOM ENTITY V2 - Advanced LocalPlayer Virtualization
    Optimized for Luau/Roblox Environment
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RealUserId = LocalPlayer.UserId
local RealName = LocalPlayer.Name

local PHANTOM_NAME = "PhantomEntity"
local PHANTOM_ID = -1
local PHANTOM_CLASS = "RemotePlayer"

-- Optimization: Cache methods to avoid hooks triggering themselves
local TableInsert = table.insert
local TableFind = table.find
local IsA = game.IsA
local GetNamecallMethod = getnamecallmethod or get_namecall_method

-- Utility: Filter the LocalPlayer out of player lists
local function FilterList(tbl)
    if type(tbl) ~= "table" then return tbl end
    local clean = {}
    for _, obj in ipairs(tbl) do
        if obj ~= LocalPlayer then
            TableInsert(clean, obj)
        end
    end
    return clean
end

-- Metatable setup
local RawMeta = getrawmetatable(game)
local OldIndex = RawMeta.__index
local OldNamecall = RawMeta.__namecall
local OldNewIndex = RawMeta.__newindex
setreadonly(RawMeta, false)

-- 1. __INDEX HOOK (Property Access)
RawMeta.__index = newcclosure(function(self, key)
    if not checkcaller() then
        -- Spoof Players.LocalPlayer (prevent scripts from finding you here)
        if self == Players and (key == "LocalPlayer" or key == "localPlayer") then
            return nil
        end

        -- Spoof Identity
        if self == LocalPlayer then
            if key == "Name" or key == "DisplayName" then return PHANTOM_NAME end
            if key == "UserId" or key == "UserID" then return PHANTOM_ID end
            if key == "ClassName" then return PHANTOM_CLASS end
            if key == "Parent" then return nil end
        end

        -- Intercept method indexing (e.g., game.Players:GetPlayers())
        if self == Players then
            if key == "GetPlayers" or key == "GetChildren" or key == "GetDescendants" then
                return newcclosure(function(s)
                    return FilterList(OldIndex(s, key)(s))
                end)
            end
        end
    end

    return OldIndex(self, key)
end)

-- 2. __NAMECALL HOOK (Method Calls - Most Important for Performance)
RawMeta.__namecall = newcclosure(function(self, ...)
    local method = GetNamecallMethod()
    local args = {...}

    if not checkcaller() then
        -- Filtering Player Lists
        if (method == "GetPlayers" or method == "getPlayers" or method == "children" or method == "GetChildren") and self == Players then
            local realResults = OldNamecall(self, ...)
            return FilterList(realResults)
        end

        -- Finding the Player
        if (method == "FindFirstChild" or method == "WaitForChild" or method == "FindFirstChildOfClass") and self == Players then
            local target = args[1]
            if target == RealName or target == "LocalPlayer" or (method == "FindFirstChildOfClass" and target == "Player") then
                -- Return nil or a dummy if they try to find you specifically
                local result = OldNamecall(self, ...)
                if result == LocalPlayer then return nil end
                return result
            end
        end

        -- Spatial/Hierarchy Spoofing
        if self == LocalPlayer then
            if method == "IsDescendantOf" or method == "isDescendantOf" then
                return false
            end
            if method == "IsA" or method == "isA" then
                if args[1] == "Player" then return false end
                if args[1] == PHANTOM_CLASS then return true end
            end
        end
    end

    return OldNamecall(self, ...)
end)

-- 3. __NEWINDEX HOOK (Property Writing)
RawMeta.__newindex = newcclosure(function(self, key, val)
    if not checkcaller() and self == LocalPlayer then
        -- Prevent scripts from renaming you or reparenting you
        if key == "Name" or key == "Parent" or key == "UserId" then
            return nil 
        end
    end
    return OldNewIndex(self, key, val)
end)

setreadonly(RawMeta, true)

-- Character Persistence (Handling Respawns)
local function HookCharacter(char)
    if not char then return end
    local charMeta = getrawmetatable(char)
    if charMeta then
        setreadonly(charMeta, false)
        local oldCharIndex = charMeta.__index
        charMeta.__index = newcclosure(function(self, key)
            if not checkcaller() and key == "Parent" then
                return nil -- Pretend character isn't in Workspace
            end
            return oldCharIndex(self, key)
        end)
        setreadonly(charMeta, true)
    end
end

LocalPlayer.CharacterAdded:Connect(HookCharacter)
if LocalPlayer.Character then HookCharacter(LocalPlayer.Character) end

print("Phantom Entity V2 Active: You are now a ghost in the machine.")
