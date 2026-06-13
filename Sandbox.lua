local _bWS = setmetatable({}, {
	__index = function(_, k)
		warn("[Security] WebSocket." .. k .. " blocked")
		return function() end
	end,
	__newindex = function() end,
	__call = function()
		warn("[Security] WebSocket() blocked")
		return nil
	end,
})
if rawget(_G, "WebSocket") ~= nil then
	rawset(_G, "WebSocket", _bWS)
end
if rawget(_G, "websocket") ~= nil then
	rawset(_G, "websocket", _bWS)
end
local _origReq = http_request or request
local function safeRequest(opts)
	local url = (opts and opts.Url) or ""
	for _, d in ipairs({ "roblox.com", "robloxlabs.com" }) do
		if url:find(d, 1, true) then
			return _origReq(opts)
		end
	end
	warn("[Security] Blocked:", url)
	return { StatusCode = 403, Body = "" }
end
http_request = safeRequest
request = safeRequest

local mt = getrawmetatable(game)
local origNC = rawget(mt, "__namecall")
if origNC and iscclosure and not iscclosure(origNC) then
	warn("[Security] __namecall hook detected -- possible remote spy")
end
local _mon = {}
local function watchRemote(remote)
	if _mon[remote] then
		return
	end
	_mon[remote] = true
	if islclosure and islclosure(remote.FireServer) then
		warn("[Security] FireServer hooked on", remote:GetFullName())
	end
end

if _SHIELD then
    warn("[SHIELD] Already active — skipping re-init.")
else

local _sandboxCount    = 0
local _interceptCount  = 0
local _auditLog        = {}
local _MAX_LOG         = 256
local _bypassNext      = false
local _trustedSources  = {}

local function _log(category, msg)
    _interceptCount = (category == "INTERCEPT") and (_interceptCount + 1) or _interceptCount
    local entry = string.format("[SHIELD][%s] %.3f | %s", category, tick(), msg)
    table.insert(_auditLog, entry)
    if #_auditLog > _MAX_LOG then
        table.remove(_auditLog, 1)
    end
end

local function makeDecoyInstance(className, name)
    className = className or "Instance"
    name      = name or className
    local props = {
        Name       = name,
        ClassName  = className,
        Parent     = nil,
        Archivable = false,
    }
    local function fakeSignal()
        local noop = { Disconnect = function() end }
        return {
            Connect         = function(_, _f) return noop end,
            Once            = function(_, _f) return noop end,
            Wait            = function()      return nil  end,
            ConnectParallel = function(_, _f) return noop end,
        }
    end
    local mt = {}
    mt.__index = function(_, k)
        if props[k] ~= nil then return props[k] end
        if k == "GetChildren" or k == "GetDescendants"
        or k == "GetConnectedParts" or k == "GetTouchingParts" then
            return function() return {} end
        end
        if k == "FindFirstChild" or k == "FindFirstChildOfClass"
        or k == "FindFirstChildWhichIsA" or k == "FindFirstAncestor"
        or k == "FindFirstAncestorOfClass" or k == "FindFirstAncestorWhichIsA" then
            return function() return nil end
        end
        if k == "IsA" then
            return function(_, c) return c == className or c == "Instance" end
        end
        if k == "IsDescendantOf" or k == "IsAncestorOf" then
            return function() return false end
        end
        if k == "Clone" then
            return function() return makeDecoyInstance(className, name .. "_clone") end
        end
        if k == "Destroy" or k == "Remove" or k == "ClearAllChildren"
        or k == "SetAttribute" or k == "AddTag" or k == "RemoveTag" then
            return function() end
        end
        if k == "GetAttribute"  then return function() return nil  end end
        if k == "GetAttributes" then return function() return {}   end end
        if k == "HasTag"        then return function() return false end end
        if k == "GetTags"       then return function() return {}   end end
        if k == "GetFullName"   then return function() return "Decoy." .. name end end
        if k == "WaitForChild"  then
            return function(_, n, _timeout) return makeDecoyInstance("Instance", n) end
        end
        if k == "GetService" then
            return function(_, s) return makeDecoyInstance(s, s) end
        end
        local signals = {
            "Changed","ChildAdded","ChildRemoved","DescendantAdded",
            "DescendantRemoving","AncestryChanged","AttributeChanged",
            "Destroying","ChildrenChanged",
        }
        for _, sig in ipairs(signals) do
            if k == sig then return fakeSignal() end
        end
        if k == "Died" or k == "HealthChanged" or k == "Touched" then
            return fakeSignal()
        end
        if k == "Health"    or k == "MaxHealth"  then return 100 end
        if k == "WalkSpeed" or k == "JumpPower"  then return 16  end
        return makeDecoyInstance("Instance", tostring(k))
    end
    mt.__newindex = function(_, k, v) props[k] = v end
    mt.__tostring = function() return className .. "(" .. name .. ")[DECOY]" end
    mt.__metatable = "locked"
    return setmetatable({}, mt)
end

local function makeDecoyGame()
    local realPlayers = game:GetService("Players")
    local realLp      = realPlayers.LocalPlayer
    local fakeLp      = makeDecoyInstance("Player", realLp and realLp.Name or "LocalPlayer")
    do
        local lmt   = getmetatable(fakeLp)
        local lorig = lmt.__index
        lmt.__index = function(t, k)
            if k == "UserId"       then return realLp and realLp.UserId or 0 end
            if k == "Team"         then return nil end
            if k == "Character"    then return makeDecoyInstance("Model",         "Character")    end
            if k == "Backpack"     then return makeDecoyInstance("Backpack",       "Backpack")     end
            if k == "PlayerGui"    then return makeDecoyInstance("PlayerGui",      "PlayerGui")    end
            if k == "PlayerScripts" then return makeDecoyInstance("PlayerScripts", "PlayerScripts") end
            return lorig(t, k)
        end
    end
    local fakePlayers = makeDecoyInstance("Players", "Players")
    do
        local pmt   = getmetatable(fakePlayers)
        local porig = pmt.__index
        pmt.__index = function(t, k)
            if k == "LocalPlayer" then return fakeLp end
            if k == "GetPlayers"  then return function() return { fakeLp } end end
            if k == "PlayerAdded" or k == "PlayerRemoving" then
                return { Connect = function(_, _f) return { Disconnect = function() end } end }
            end
            return porig(t, k)
        end
    end
    local fakeRun = makeDecoyInstance("RunService", "RunService")
    do
        local rmt   = getmetatable(fakeRun)
        local rorig = rmt.__index
        local noop  = { Connect = function(_, _f) return { Disconnect = function() end } end }
        rmt.__index = function(t, k)
            if k == "Heartbeat"     then return noop end
            if k == "RenderStepped" then return noop end
            if k == "Stepped"       then return noop end
            if k == "IsClient"      then return function() return true  end end
            if k == "IsServer"      then return function() return false end end
            if k == "IsStudio"      then return function() return false end end
            return rorig(t, k)
        end
    end
    local fakeHttp = makeDecoyInstance("HttpService", "HttpService")
    do
        local hmt   = getmetatable(fakeHttp)
        local horig = hmt.__index
        hmt.__index = function(t, k)
            if k == "GetAsync" or k == "PostAsync" or k == "RequestAsync" then
                return function() error("HttpService blocked by SHIELD") end
            end
            if k == "JSONEncode" then
                return function(_, v) local ok, r = pcall(tostring, v); return ok and r or "{}" end
            end
            if k == "JSONDecode" then return function(_, _s) return {} end end
            return horig(t, k)
        end
    end
    local svcMap = {
        Workspace            = makeDecoyInstance("Workspace",            "Workspace"),
        Players              = fakePlayers,
        ReplicatedStorage    = makeDecoyInstance("ReplicatedStorage",    "ReplicatedStorage"),
        ServerStorage        = makeDecoyInstance("ServerStorage",        "ServerStorage"),
        ServerScriptService  = makeDecoyInstance("ServerScriptService",  "ServerScriptService"),
        StarterGui           = makeDecoyInstance("StarterGui",           "StarterGui"),
        StarterPack          = makeDecoyInstance("StarterPack",          "StarterPack"),
        StarterPlayer        = makeDecoyInstance("StarterPlayer",        "StarterPlayer"),
        SoundService         = makeDecoyInstance("SoundService",         "SoundService"),
        HttpService          = fakeHttp,
        RunService           = fakeRun,
        TweenService         = makeDecoyInstance("TweenService",         "TweenService"),
        UserInputService     = makeDecoyInstance("UserInputService",     "UserInputService"),
        CoreGui              = makeDecoyInstance("CoreGui",              "CoreGui"),
        Lighting             = makeDecoyInstance("Lighting",             "Lighting"),
        Teams                = makeDecoyInstance("Teams",                "Teams"),
        Chat                 = makeDecoyInstance("Chat",                 "Chat"),
        VirtualInputManager  = makeDecoyInstance("VirtualInputManager",  "VirtualInputManager"),
        GuiService           = makeDecoyInstance("GuiService",           "GuiService"),
        ContextActionService = makeDecoyInstance("ContextActionService", "ContextActionService"),
        MarketplaceService   = makeDecoyInstance("MarketplaceService",   "MarketplaceService"),
        BadgeService         = makeDecoyInstance("BadgeService",         "BadgeService"),
        DataStoreService     = makeDecoyInstance("DataStoreService",     "DataStoreService"),
        MessagingService     = makeDecoyInstance("MessagingService",     "MessagingService"),
        PhysicsService       = makeDecoyInstance("PhysicsService",       "PhysicsService"),
        CollectionService    = makeDecoyInstance("CollectionService",    "CollectionService"),
    }
    rawset(svcMap.Workspace, "CurrentCamera", makeDecoyInstance("Camera", "Camera"))
    local fakeGame = makeDecoyInstance("DataModel", "Game")
    local fmt      = getmetatable(fakeGame)
    local forig    = fmt.__index
    fmt.__index = function(t, k)
        if k == "GetService" then
            return function(_, s)
                if not svcMap[s] then svcMap[s] = makeDecoyInstance(s, s) end
                return svcMap[s]
            end
        end
        if k == "PlaceId"    then return 0 end
        if k == "JobId"      then return "00000000-0000-0000-0000-000000000000" end
        if k == "CreatorId"  then return 0 end
        if svcMap[k]         then return svcMap[k] end
        return forig(t, k)
    end
    fmt.__namecall = newcclosure(function(self, ...)
        local method = tostring(...)
        _log("NAMECALL", string.format("fakeGame:%s() called inside sandbox", method))
        return nil
    end)
    return fakeGame, svcMap.Workspace
end

local _OBFUSC_PATTERNS = {
    { pattern = "getfenv%s*%(%s*0%s*%)",       label = "getfenv(0) env-steal"           },
    { pattern = "string%.byte.+string%.char",   label = "byte/char loop (bytecode obfusc)" },
    { pattern = "load%s*%(.-%)",                label = "raw load() call"                },
    { pattern = "pcall%s*%(%s*load",            label = "pcall+load wrapper"             },
    { pattern = "%_ENV%s*=%s*nil",              label = "_ENV=nil lockout"               },
    { pattern = "syn%.request",                 label = "Synapse HTTP request"           },
    { pattern = "fluxus%.request",              label = "Fluxus HTTP request"            },
    { pattern = "getgenv%s*%(%s*%)",            label = "getgenv() access"               },
    { pattern = "getrawmetatable%s*%(%s*game",  label = "getrawmetatable(game)"          },
    { pattern = "hookmetamethod%s*%(%s*game",   label = "hookmetamethod(game)"           },
    { pattern = "hookfunction",                 label = "hookfunction call"              },
    { pattern = "firetouchinterest",            label = "fireTouchInterest exploit fn"   },
    { pattern = "fireproximityprompt",          label = "fireProximityPrompt exploit fn" },
    { pattern = "writefile",                    label = "writefile FS access"            },
    { pattern = "readfile",                     label = "readfile FS access"             },
    { pattern = "loadfile",                     label = "loadfile FS access"             },
    { pattern = "require%s*%(%s*%-?%d+",        label = "require(id) module load"        },
}
local function detectObfuscation(source)
    local lower = source:lower()
    local found = {}
    for _, rule in ipairs(_OBFUSC_PATTERNS) do
        if lower:match(rule.pattern) then
            found[#found + 1] = rule.label
        end
    end
    return found
end

local function makeSandboxedTask(sandboxEnv)
    return {
        wait = function(n) return task.wait(n) end,
        delay = function(n, fn)
            task.delay(n, function()
                local ok, err = pcall(setfenv(fn, sandboxEnv))
                if not ok then _log("SANDBOX_ERR", "task.delay fn error: " .. tostring(err)) end
            end)
        end,
        spawn = function(fn, ...)
            local args = { ... }
            task.spawn(function()
                local ok, err = pcall(function() return setfenv(fn, sandboxEnv)(table.unpack(args)) end)
                if not ok then _log("SANDBOX_ERR", "task.spawn fn error: " .. tostring(err)) end
            end)
        end,
        defer = function(fn, ...)
            local args = { ... }
            task.defer(function()
                local ok, err = pcall(function() return setfenv(fn, sandboxEnv)(table.unpack(args)) end)
                if not ok then _log("SANDBOX_ERR", "task.defer fn error: " .. tostring(err)) end
            end)
        end,
        synchronize  = function() end,
        desynchronize = function() end,
        cancel       = function() end,
    }
end
local function makeSandboxedCoroutine(sandboxEnv)
    return {
        create    = function(fn) return coroutine.create(setfenv(fn, sandboxEnv)) end,
        wrap      = function(fn) return coroutine.wrap(setfenv(fn, sandboxEnv))   end,
        resume    = coroutine.resume,
        yield     = coroutine.yield,
        status    = coroutine.status,
        running   = coroutine.running,
        isyieldable = coroutine.isyieldable,
    }
end

local _fakeModuleCache = {}
local function sandboxedRequire(id)
    if type(id) == "number" then
        if _fakeModuleCache[id] then return _fakeModuleCache[id] end
        _log("REQUIRE", string.format("Blocked require(%d) — returning decoy module", id))
        local decoy = makeDecoyInstance("ModuleScript", "module_" .. id)
        _fakeModuleCache[id] = decoy
        return decoy
    end
    _log("REQUIRE", "Blocked require(<Instance>) — returning empty table")
    return {}
end

local function readonly(t)
    return setmetatable({}, {
        __index    = t,
        __newindex = function() end,
        __metatable = "locked",
    })
end

local function buildEnv(fakeGame, fakeWs)
    _sandboxCount = _sandboxCount + 1
    local sandboxId = _sandboxCount
    local env = {}

    local function sandboxedLoadstring(src, chunkName)
        local fn, err = (getgenv().__SHIELD_REAL_LOADSTRING or loadstring)(src, chunkName or "sandboxed_inner")
        if not fn then return nil, err end
        local innerGame, innerWs = makeDecoyGame()
        local innerEnv = buildEnv(innerGame, innerWs)
        setfenv(fn, innerEnv)
        return fn
    end

    env.print       = print
    env.warn        = warn
    env.error       = error
    env.assert      = assert
    env.tostring    = tostring
    env.tonumber    = tonumber
    env.type        = type
    env.typeof      = typeof
    env.pairs       = pairs
    env.ipairs      = ipairs
    env.next        = next
    env.select      = select
    env.unpack      = table.unpack or unpack
    env.rawget      = rawget
    env.rawset      = rawset
    env.rawequal    = rawequal
    env.rawlen      = rawlen
    env.pcall       = pcall
    env.xpcall      = xpcall
    env.setmetatable = setmetatable
    env.getmetatable = getmetatable
    env.collectgarbage = function() end
    env.newproxy    = newproxy
    env.math        = readonly(math)
    env.table       = readonly(table)
    env.string      = readonly(string)
    env.bit32       = bit32 and readonly(bit32) or nil
    env.utf8        = utf8  and readonly(utf8)  or nil
    env.tick        = tick
    env.time        = time
    env.os          = readonly({ clock = os.clock, time = os.time, date = os.date })
    env.Vector3     = Vector3;      env.Vector2       = Vector2
    env.Vector2int16 = Vector2int16; env.Vector3int16  = Vector3int16
    env.CFrame      = CFrame;       env.Color3        = Color3
    env.UDim2       = UDim2;        env.UDim          = UDim
    env.Rect        = Rect;         env.Enum          = Enum
    env.Instance    = Instance;     env.TweenInfo     = TweenInfo
    env.NumberSequence = NumberSequence
    env.ColorSequence  = ColorSequence
    env.Ray         = Ray;          env.Region3       = Region3
    env.RaycastParams  = RaycastParams
    env.OverlapParams  = OverlapParams
    env.game        = fakeGame
    env.workspace   = fakeWs
    env.Workspace   = fakeWs
    env.script      = makeDecoyInstance("LocalScript", "SandboxedScript_" .. sandboxId)
    env.shared      = {}
    env._G          = {}
    env.task        = makeSandboxedTask(env)
    env.coroutine   = makeSandboxedCoroutine(env)
    env.loadstring  = sandboxedLoadstring
    env.require     = sandboxedRequire
    env.load        = function() error("[SHIELD] load() is blocked inside the sandbox") end

    local _poisonedGlobals = {
        "getfenv","setfenv","getgenv","getrenv","getgc","getinstances","getsenv",
        "getupvalues","getupvalue","setupvalue","getconstants","getconstant",
        "getrawmetatable","setrawmetatable","setreadonly","isreadonly",
        "hookfunction","hookmetamethod","newcclosure","iscclosure","islclosure",
        "isexecutorclosure","checkcaller","decompile","getscriptbytecode",
        "getscripthash","getscripts","getscriptclosure","getthreadcontext",
        "setthreadidentity","getthreadidentity","firetouchinterest",
        "fireproximityprompt","fireclickdetector","writefile","readfile",
        "loadfile","appendfile","listfiles","makefolder","isfile","isfolder",
        "delfile","delfolder","request","http_request","syn","fluxus",
        "KRNL_LOADED","SYNAPSE_LOADED","Sentinel","Oxygen","cachedWS","_SHIELD",
    }
    for _, g in ipairs(_poisonedGlobals) do env[g] = nil end

    env.tostring = function(v)
        if v == fakeGame then return "DataModel" end
        if v == fakeWs   then return "Workspace"  end
        return tostring(v)
    end
    env.typeof = function(v)
        local mt = getmetatable(v)
        if mt == "locked" then
            local ok, cls = pcall(function() return v.ClassName end)
            if ok and type(cls) == "string" and cls ~= "" then return cls end
        end
        return typeof(v)
    end
    env._ENV = env
    return env
end

local genv            = getgenv()
local REAL_LOADSTRING = genv.loadstring or loadstring
genv.__SHIELD_REAL_LOADSTRING = REAL_LOADSTRING

local function startWatchdog()
    task.spawn(function()
        while _SHIELD do
            task.wait(5)
            if genv.loadstring ~= genv.__SHIELD_HOOK then
                _log("WATCHDOG", "Hook tampered — reinstalling!")
                genv.loadstring = genv.__SHIELD_HOOK
            end
        end
    end)
end

local shieldHook = newcclosure(function(source, chunkName)
    if checkcaller() then
        return REAL_LOADSTRING(source, chunkName)
    end
    if _bypassNext then
        _bypassNext = false
        _log("BYPASS", "One-shot bypass consumed — passing through raw.")
        return REAL_LOADSTRING(source, chunkName)
    end
    if chunkName and _trustedSources[chunkName] then
        _log("TRUSTED", "Trusted chunkName '" .. chunkName .. "' — passing through raw.")
        return REAL_LOADSTRING(source, chunkName)
    end
    local fn, compileErr = REAL_LOADSTRING(source, chunkName or "untrusted")
    if not fn then
        _log("COMPILE_ERR", tostring(compileErr))
        return nil, compileErr
    end
    local flags = detectObfuscation(source)
    if #flags > 0 then
        _log("INTERCEPT", string.format("Suspicious source [%s] — flags: %s",
            chunkName or "?", table.concat(flags, ", ")))
    else
        _log("INTERCEPT", string.format("Sandboxing chunk: %s", chunkName or "untrusted"))
    end
    local fakeGame, fakeWs = makeDecoyGame()
    local env = buildEnv(fakeGame, fakeWs)
    setfenv(fn, env)
    return fn
end)
genv.loadstring    = shieldHook
genv.__SHIELD_HOOK = shieldHook

_SHIELD = {
    exec = function(source, chunkName)
        local fn, err = REAL_LOADSTRING(source, chunkName or "trusted")
        if not fn then warn("[SHIELD] Compile error:", err); return false, err end
        local ok, runErr = pcall(fn)
        if not ok then warn("[SHIELD] Runtime error:", runErr); return false, runErr end
        return true
    end,
    execSandboxed = function(source, chunkName)
        local fn, err = REAL_LOADSTRING(source, chunkName or "sandboxed_manual")
        if not fn then warn("[SHIELD] Compile error:", err); return false, err end
        local fakeGame, fakeWs = makeDecoyGame()
        local env = buildEnv(fakeGame, fakeWs)
        setfenv(fn, env)
        local ok, runErr = pcall(fn)
        if not ok then warn("[SHIELD] Sandbox runtime error:", runErr); return false, runErr end
        return true
    end,
    bypass = function()
        _bypassNext = true
        print("[SHIELD] Bypass armed — next untrusted loadstring call will go through raw.")
    end,
    trust = function(chunkName)
        _trustedSources[chunkName] = true
        print("[SHIELD] Trusted chunkName registered: " .. tostring(chunkName))
    end,
    untrust = function(chunkName)
        _trustedSources[chunkName] = nil
        print("[SHIELD] chunkName unregistered: " .. tostring(chunkName))
    end,
    inspect = function(fn)
        if type(fn) ~= "function" then
            warn("[SHIELD] inspect() expects a function, got " .. type(fn)); return
        end
        local ups = getupvalues and getupvalues(fn) or {}
        print(string.format("[SHIELD] inspect() — %d upvalue(s) found:", #ups))
        for i, v in ipairs(ups) do print(string.format("  [%d] %s", i, tostring(v))) end
        return ups
    end,
    log = function(n)
        n = n or 20
        local start = math.max(1, #_auditLog - n + 1)
        print(string.format("[SHIELD] Last %d log entries:", math.min(n, #_auditLog)))
        for i = start, #_auditLog do print("  " .. _auditLog[i]) end
    end,
    getLog = function() return _auditLog end,
    status = function()
        print(string.format(
            "[SHIELD] Active | Sandboxes created: %d | Calls intercepted: %d | Log entries: %d",
            _sandboxCount, _interceptCount, #_auditLog))
    end,
    scan = function(source)
        local flags = detectObfuscation(source)
        if #flags == 0 then
            print("[SHIELD] Scan: no suspicious patterns detected.")
        else
            print("[SHIELD] Scan: " .. #flags .. " flag(s) found:")
            for _, f in ipairs(flags) do print("  ⚠  " .. f) end
        end
        return flags
    end,
    disable = function()
        genv.loadstring               = REAL_LOADSTRING
        genv.__SHIELD_REAL_LOADSTRING = nil
        genv.__SHIELD_HOOK            = nil
        _SHIELD    = nil
        genv._SHIELD = nil
        print("[SHIELD] Disabled. loadstring restored to original.")
    end,
}
genv._SHIELD = _SHIELD
startWatchdog()

print("╔══════════════════════════════════════════════╗")
print("║  SHIELD active                               ║")
print("║  Untrusted loadstring calls → sandboxed      ║")
print("║  Anti-tamper watchdog        → running       ║")
print("║  Obfuscation scanner         → enabled       ║")
print("╚══════════════════════════════════════════════╝")

end

--  SECTION 2: AUDITOR  (trace layer)

if getgenv().__AUDITOR then
    warn("[AUDITOR] Already loaded — skipping re-init.")
else

local _traceLog       = {}
local _callDepth      = 0
local _MAX_TRACE      = 1024
local _hookActive     = false
local _sessionId      = 0
local _lineHookEnabled = false
local INDENT_CHAR     = "  "

local function _indent()
    return string.rep(INDENT_CHAR, math.min(_callDepth, 16))
end

local function _trace(category, msg)
    local entry = {
        t        = tick(),
        category = category,
        depth    = _callDepth,
        msg      = msg,
    }
    table.insert(_traceLog, entry)
    if #_traceLog > _MAX_TRACE then table.remove(_traceLog, 1) end
    print(string.format("[AUDITOR][%s][%.3f]%s %s", category, entry.t, _indent(), msg))
end

local function _serialize(v, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = type(v)
    if t == "string" then
        local s      = v:sub(1, 80):gsub("\n", "\\n"):gsub("\r", "\\r")
        local suffix = (#v > 80) and ("…[" .. #v .. "]") or ""
        return '"' .. s .. suffix .. '"'
    elseif t == "number" or t == "boolean" then
        return tostring(v)
    elseif t == "nil" then
        return "nil"
    elseif t == "function" then
        local info = debug and debug.getinfo and debug.getinfo(v, "nS")
        if info then
            return string.format("fn<%s:%s@%s>",
                info.name or "?", info.short_src or "?", tostring(info.linedefined or "?"))
        end
        return "fn<" .. tostring(v) .. ">"
    elseif t == "table" then
        local keys = {}
        for k in pairs(v) do keys[#keys+1] = tostring(k) end
        if #keys == 0 then return "{}" end
        if #keys > 6  then return "{table:" .. #keys .. "keys}" end
        local parts = {}
        for _, k in ipairs(keys) do
            parts[#parts+1] = k .. "=" .. _serialize(rawget(v, k) or "?", depth+1)
        end
        return "{" .. table.concat(parts, ", ") .. "}"
    else
        local ok, s = pcall(tostring, v)
        return ok and s or ("?<" .. t .. ">")
    end
end

local function _debugHook(event, line)
    if not checkcaller or not checkcaller() then
        if event == "call" then
            _callDepth = _callDepth + 1
            if debug and debug.getinfo then
                local ok, info = pcall(debug.getinfo, 2, "nS")
                if ok and info then
                    _trace("CALL", string.format("→ %s  [%s:%s]",
                        info.name or "<anonymous>",
                        info.short_src or "?",
                        tostring(info.linedefined or "?")))
                end
            end
        elseif event == "return" then
            if _callDepth > 0 then _callDepth = _callDepth - 1 end
            _trace("RET", "←")
        elseif event == "line" and _lineHookEnabled then
            _trace("LINE", "line " .. tostring(line))
        end
    end
end

local _realPcall  = pcall
local _realXpcall = xpcall

local function _auditedPcall(fn, ...)
    _trace("PCALL", "pcall entered — fn: " .. _serialize(fn))
    local results = table.pack(_realPcall(fn, ...))
    _trace("PCALL", "pcall result: success=" .. tostring(results[1]))
    if not results[1] then
        _trace("PCALL_ERR", "error: " .. tostring(results[2]))
    end
    return table.unpack(results, 1, results.n)
end

local function _auditedXpcall(fn, handler, ...)
    _trace("XPCALL", "xpcall entered — fn: " .. _serialize(fn))
    local results = table.pack(_realXpcall(fn, handler, ...))
    _trace("XPCALL", "xpcall result: success=" .. tostring(results[1]))
    return table.unpack(results, 1, results.n)
end

local _REAL_LS = getgenv().__SHIELD_REAL_LOADSTRING or loadstring

local function _auditedLoadstring(src, chunkName)
    chunkName = chunkName or "dynamic_chunk"
    _trace("LOADSTRING", string.format("chunk='%s' len=%d", chunkName, #src))
    local preview = src:sub(1, 300):gsub("\n", "\\n"):gsub("\r", "\\r")
    _trace("LOADSTRING_SRC", "preview: " .. preview)
    local fn, err = _REAL_LS(src, chunkName)
    if not fn then
        _trace("LOADSTRING_ERR", "compile error: " .. tostring(err))
        return nil, err
    end
    _trace("LOADSTRING_OK", "compiled successfully — returning sandboxed fn")
    return fn
end

local _shieldLog     = _SHIELD.getLog and _SHIELD.getLog() or {}
local _lastShieldLen = #_shieldLog

local function _pollShieldLog()
    local current = _SHIELD.getLog and _SHIELD.getLog() or {}
    for i = _lastShieldLen + 1, #current do
        local entry = current[i]
        if entry:find("%[NAMECALL%]") or entry:find("%[REQUIRE%]") then
            _trace("SHIELD_FWD", entry)
        end
    end
    _lastShieldLen = #current
end

local function _dumpFunctionInternals(fn, label)
    label = label or tostring(fn)
    if type(fn) ~= "function" then return end
    local ok_c, consts = pcall(getconstants, fn)
    if ok_c and consts then
        _trace("CONSTANTS", string.format("fn '%s' has %d constant(s):", label, #consts))
        for i, v in ipairs(consts) do
            _trace("  CONST", string.format("[%d] %s = %s", i, type(v), _serialize(v)))
        end
    end
    local ok_u, ups = pcall(getupvalues, fn)
    if ok_u and ups then
        _trace("UPVALUES", string.format("fn '%s' has %d upvalue(s):", label, #ups))
        for i, v in ipairs(ups) do
            _trace("  UPVAL", string.format("[%d] %s = %s", i, type(v), _serialize(v)))
        end
    end
    local ok_p, protos = pcall(getprotos, fn)
    if ok_p and protos then
        _trace("PROTOS", string.format("fn '%s' has %d nested proto(s):", label, #protos))
        for i, p in ipairs(protos) do
            _dumpFunctionInternals(p, label .. ".proto[" .. i .. "]")
        end
    end
end

local function _runAudit(source, chunkName)
    _sessionId = _sessionId + 1
    _callDepth = 0
    chunkName  = chunkName or ("audit_session_" .. _sessionId)
    _trace("SESSION", string.format("=== AUDIT SESSION #%d START === chunk='%s'", _sessionId, chunkName))
    _trace("SESSION", string.format("Source length: %d bytes", #source))
    _trace("STATIC_SCAN", "Running static obfuscation detector...")
    local flags = _SHIELD.scan(source)
    if #flags == 0 then _trace("STATIC_SCAN", "No static flags found.") end
    local fn, compileErr = _REAL_LS(source, chunkName)
    if not fn then
        _trace("COMPILE_ERR", "Failed to compile: " .. tostring(compileErr))
        warn("[AUDITOR] Compile error — aborting audit.")
        return false
    end
    _trace("COMPILE_OK", "Compiled successfully.")
    _trace("PRE_EXEC", "Dumping top-level function internals...")
    _dumpFunctionInternals(fn, chunkName .. ":root")
    local _prevLS = getgenv().__SHIELD_REAL_LOADSTRING
    getgenv().__SHIELD_REAL_LOADSTRING = _auditedLoadstring
    if debug and debug.sethook then
        _hookActive = true
        debug.sethook(_debugHook, "cr")
        _trace("HOOK", "debug.sethook installed (call+return mode)")
    else
        _trace("HOOK", "debug.sethook not available on this executor")
    end
    _trace("EXEC", "Handing off to SHIELD.execSandboxed...")
    local ok, runErr = _SHIELD.execSandboxed(source, chunkName)
    if _hookActive and debug and debug.sethook then
        debug.sethook()
        _hookActive = false
        _trace("HOOK", "debug.sethook removed")
    end
    getgenv().__SHIELD_REAL_LOADSTRING = _prevLS
    _pollShieldLog()
    if ok then
        _trace("SESSION", string.format("=== AUDIT SESSION #%d COMPLETED CLEANLY ===", _sessionId))
    else
        _trace("SESSION_ERR", string.format("=== AUDIT SESSION #%d RUNTIME ERROR: %s ===",
            _sessionId, tostring(runErr)))
    end
    return ok
end

local function _dump(filter, n)
    local log = _traceLog
    n      = n or #log
    filter = filter and filter:upper() or nil
    local start = math.max(1, #log - n + 1)
    print(string.rep("─", 60))
    print(string.format("[AUDITOR] TRACE DUMP — %d entries (showing last %d)", #log, n))
    print(string.rep("─", 60))
    for i = start, #log do
        local e = log[i]
        if not filter or e.category:find(filter) then
            print(string.format("[%s][%.3f] %s%s",
                e.category, e.t,
                string.rep(INDENT_CHAR, math.min(e.depth, 8)),
                e.msg))
        end
    end
    print(string.rep("─", 60))
    print(string.format("[AUDITOR] End of dump. Total entries: %d", #log))
end

local AUDITOR = {}

function AUDITOR.run(source, chunkName)
    assert(type(source) == "string", "[AUDITOR] run() expects a string")
    return _runAudit(source, chunkName)
end
function AUDITOR.runUrl(url)
    _trace("FETCH", "HttpGet: " .. tostring(url))
    local ok, src = pcall(function() return game:HttpGet(url) end)
    if not ok or type(src) ~= "string" or #src == 0 then
        warn("[AUDITOR] Failed to fetch URL: " .. tostring(url))
        _trace("FETCH_ERR", "Failed: " .. tostring(src))
        return false
    end
    _trace("FETCH_OK", string.format("Got %d bytes from %s", #src, url))
    return _runAudit(src, "remote:" .. url:sub(-40))
end
function AUDITOR.dump(filter, n) _dump(filter, n) end
function AUDITOR.dumpFilter(keyword) _dump(keyword, #_traceLog) end
function AUDITOR.clear()
    _traceLog  = {}
    _callDepth = 0
    _sessionId = 0
    print("[AUDITOR] Trace log cleared.")
end
function AUDITOR.inspect(fn, label)
    assert(type(fn) == "function", "[AUDITOR] inspect() expects a function")
    _dumpFunctionInternals(fn, label or "manual_inspect")
end
function AUDITOR.toggleLineHook()
    _lineHookEnabled = not _lineHookEnabled
    print("[AUDITOR] Line hook: " .. (_lineHookEnabled and "ON (noisy!)" or "OFF"))
end
function AUDITOR.getLog() return _traceLog end
function AUDITOR.status()
    print(string.format(
        "[AUDITOR] Sessions: %d | Trace entries: %d | Hook active: %s | Line hook: %s",
        _sessionId, #_traceLog, tostring(_hookActive), tostring(_lineHookEnabled)))
    _SHIELD.status()
end

getgenv().__AUDITOR = AUDITOR
getgenv().AUDITOR   = AUDITOR

print("[AUDITOR] Loaded and ready.")
print("[AUDITOR] API: AUDITOR.run(src) | .runUrl(url) | .dump() | .dumpFilter(cat) | .inspect(fn) | .clear() | .status()")

end

--  SECTION 3: GUI

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local _existing = playerGui:FindFirstChild("Synapse X")
if _existing then _existing:Destroy() end

local T = {
    BG_DEEP      = Color3.fromRGB(22,  22,  26),
    BG_MID       = Color3.fromRGB(30,  30,  35),
    BG_PANEL     = Color3.fromRGB(26,  26,  31),
    BG_EDITOR    = Color3.fromRGB(18,  18,  22),
    BG_BTN       = Color3.fromRGB(38,  38,  45),
    BG_BTN_HOV   = Color3.fromRGB(52,  52,  62),
    STROKE_OUTER = Color3.fromRGB(60,  60,  75),
    STROKE_INNER = Color3.fromRGB(45,  45,  58),
    STROKE_BTN   = Color3.fromRGB(55,  55,  68),
    STROKE_ACCENT= Color3.fromRGB(80,  80, 180),
    TEXT_MAIN    = Color3.fromRGB(220, 220, 230),
    TEXT_DIM     = Color3.fromRGB(130, 130, 150),
    TEXT_TAB     = Color3.fromRGB(200, 200, 215),
    ICON_TINT    = Color3.fromRGB(180, 180, 200),
    CLOSE_HOV    = Color3.fromRGB(180,  50,  50),
    ATTACH_ON    = Color3.fromRGB(50,  180,  80),
}

local function stroke(parent, color, thickness, lineJoin)
    local s = Instance.new("UIStroke")
    s.Color            = color or T.STROKE_INNER
    s.Thickness        = thickness or 1
    s.LineJoinMode     = lineJoin or Enum.LineJoinMode.Miter
    s.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
    s.Parent           = parent
    return s
end

local function flash(btn, col)
    local orig = btn.BackgroundColor3
    TweenService:Create(btn, TweenInfo.new(0.06), { BackgroundColor3 = col or T.BG_BTN_HOV }):Play()
    task.delay(0.12, function()
        if btn and btn.Parent then
            TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = orig }):Play()
        end
    end)
end

local function hoverEffect(btn, hoverCol, normalCol)
    normalCol = normalCol or btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = hoverCol }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = normalCol }):Play()
    end)
end

local function createGui()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name                  = "Synapse X"
    ScreenGui.ZIndexBehavior        = Enum.ZIndexBehavior.Sibling
    ScreenGui.ScreenInsets          = Enum.ScreenInsets.CoreUISafeInsets
    ScreenGui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.FullscreenExtension

    local ToggleBtn = Instance.new("ImageButton")
    ToggleBtn.Parent                 = ScreenGui
    ToggleBtn.Name                   = "ToggleBtn"
    ToggleBtn.Size                   = UDim2.fromOffset(46, 46)
    ToggleBtn.Position               = UDim2.fromScale(0.965, 0.94)
    ToggleBtn.BackgroundColor3       = T.BG_MID
    ToggleBtn.BackgroundTransparency = 0
    ToggleBtn.BorderSizePixel        = 0
    ToggleBtn.Image                  = "rbxassetid://9524079125"
    ToggleBtn.ImageColor3            = T.ICON_TINT
    ToggleBtn.ScaleType              = Enum.ScaleType.Fit
    ToggleBtn.Style                  = Enum.ButtonStyle.Custom
    stroke(ToggleBtn, T.STROKE_OUTER, 1)
    hoverEffect(ToggleBtn, T.BG_BTN_HOV, T.BG_MID)

    local MainFrame = Instance.new("Frame")
    MainFrame.Parent           = ScreenGui
    MainFrame.Name             = "MainFrame"
    MainFrame.Size             = UDim2.fromOffset(706, 289)
    MainFrame.Position         = UDim2.fromScale(0.062, 0.096)
    MainFrame.Visible          = false
    MainFrame.BackgroundColor3 = T.BG_DEEP
    MainFrame.BorderSizePixel  = 0
    MainFrame.ClipsDescendants = true
    stroke(MainFrame, T.STROKE_OUTER, 1)

    local TitleBar = Instance.new("Frame")
    TitleBar.Parent           = MainFrame
    TitleBar.Name             = "TitleBar"
    TitleBar.Size             = UDim2.new(1, 0, 0, 28)
    TitleBar.Position         = UDim2.fromOffset(0, 0)
    TitleBar.BackgroundColor3 = T.BG_MID
    TitleBar.BorderSizePixel  = 0
    TitleBar.ZIndex           = 2

    local TitleIcon = Instance.new("ImageLabel")
    TitleIcon.Parent                 = TitleBar
    TitleIcon.Size                   = UDim2.fromOffset(18, 18)
    TitleIcon.Position               = UDim2.fromOffset(8, 5)
    TitleIcon.BackgroundTransparency = 1
    TitleIcon.Image                  = "rbxassetid://9524079125"
    TitleIcon.ImageColor3            = T.ICON_TINT
    TitleIcon.ScaleType              = Enum.ScaleType.Fit
    TitleIcon.ZIndex                 = 3

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Parent                 = TitleBar
    TitleLabel.Size                   = UDim2.new(1, -110, 1, 0)
    TitleLabel.Position               = UDim2.fromOffset(32, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text                   = "Synapse X  [SHIELD+AUDIT]"
    TitleLabel.Font                   = Enum.Font.GothamBold
    TitleLabel.TextSize               = 13
    TitleLabel.TextColor3             = T.TEXT_MAIN
    TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
    TitleLabel.ZIndex                 = 3

    local AccentLine = Instance.new("Frame")
    AccentLine.Parent           = MainFrame
    AccentLine.Size             = UDim2.new(1, 0, 0, 1)
    AccentLine.Position         = UDim2.fromOffset(0, 28)
    AccentLine.BackgroundColor3 = T.STROKE_ACCENT
    AccentLine.BorderSizePixel  = 0
    AccentLine.ZIndex           = 2

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Parent           = TitleBar
    CloseBtn.Name             = "CloseBtn"
    CloseBtn.Size             = UDim2.fromOffset(28, 20)
    CloseBtn.Position         = UDim2.new(1, -30, 0, 4)
    CloseBtn.BackgroundColor3 = T.BG_MID
    CloseBtn.BorderSizePixel  = 0
    CloseBtn.Text             = "X"
    CloseBtn.Font             = Enum.Font.GothamBold
    CloseBtn.TextSize         = 12
    CloseBtn.TextColor3       = T.TEXT_DIM
    CloseBtn.ZIndex           = 4
    hoverEffect(CloseBtn, T.CLOSE_HOV, T.BG_MID)
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.08), { TextColor3 = Color3.fromRGB(255,255,255) }):Play()
    end)
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.08), { TextColor3 = T.TEXT_DIM }):Play()
    end)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Parent           = TitleBar
    MinBtn.Name             = "MinBtn"
    MinBtn.Size             = UDim2.fromOffset(28, 20)
    MinBtn.Position         = UDim2.new(1, -60, 0, 4)
    MinBtn.BackgroundColor3 = T.BG_MID
    MinBtn.BorderSizePixel  = 0
    MinBtn.Text             = "─"
    MinBtn.Font             = Enum.Font.GothamBold
    MinBtn.TextSize         = 12
    MinBtn.TextColor3       = T.TEXT_DIM
    MinBtn.ZIndex           = 4
    hoverEffect(MinBtn, T.BG_BTN_HOV, T.BG_MID)

    local TabBar = Instance.new("Frame")
    TabBar.Parent           = MainFrame
    TabBar.Name             = "TabBar"
    TabBar.Size             = UDim2.new(1, 0, 0, 22)
    TabBar.Position         = UDim2.fromOffset(0, 29)
    TabBar.BackgroundColor3 = T.BG_PANEL
    TabBar.BorderSizePixel  = 0

    local TabBarLine = Instance.new("Frame")
    TabBarLine.Parent           = TabBar
    TabBarLine.Size             = UDim2.new(1, 0, 0, 1)
    TabBarLine.Position         = UDim2.new(0, 0, 1, -1)
    TabBarLine.BackgroundColor3 = T.STROKE_INNER
    TabBarLine.BorderSizePixel  = 0

    local Tab1 = Instance.new("Frame")
    Tab1.Parent           = TabBar
    Tab1.Name             = "Tab1"
    Tab1.Size             = UDim2.fromOffset(88, 22)
    Tab1.Position         = UDim2.fromOffset(0, 0)
    Tab1.BackgroundColor3 = T.BG_DEEP
    Tab1.BorderSizePixel  = 0

    local Tab1Label = Instance.new("TextLabel")
    Tab1Label.Parent                 = Tab1
    Tab1Label.Size                   = UDim2.new(1, -20, 1, 0)
    Tab1Label.Position               = UDim2.fromOffset(6, 0)
    Tab1Label.BackgroundTransparency = 1
    Tab1Label.Text                   = "Script 1"
    Tab1Label.Font                   = Enum.Font.Gotham
    Tab1Label.TextSize               = 11
    Tab1Label.TextColor3             = T.TEXT_TAB
    Tab1Label.TextXAlignment         = Enum.TextXAlignment.Left

    local Tab1Close = Instance.new("TextButton")
    Tab1Close.Parent           = Tab1
    Tab1Close.Name             = "TabClose"
    Tab1Close.Size             = UDim2.fromOffset(16, 16)
    Tab1Close.Position         = UDim2.new(1, -18, 0, 3)
    Tab1Close.BackgroundColor3 = T.BG_DEEP
    Tab1Close.BorderSizePixel  = 0
    Tab1Close.Text             = "✕"
    Tab1Close.Font             = Enum.Font.Gotham
    Tab1Close.TextSize         = 9
    Tab1Close.TextColor3       = T.TEXT_DIM
    hoverEffect(Tab1Close, T.CLOSE_HOV, T.BG_DEEP)
    stroke(Tab1, T.STROKE_INNER, 1)

    local NewTabBtn = Instance.new("TextButton")
    NewTabBtn.Parent           = TabBar
    NewTabBtn.Name             = "NewTab"
    NewTabBtn.Size             = UDim2.fromOffset(22, 22)
    NewTabBtn.Position         = UDim2.fromOffset(88, 0)
    NewTabBtn.BackgroundColor3 = T.BG_PANEL
    NewTabBtn.BorderSizePixel  = 0
    NewTabBtn.Text             = "+"
    NewTabBtn.Font             = Enum.Font.GothamBold
    NewTabBtn.TextSize         = 14
    NewTabBtn.TextColor3       = T.TEXT_DIM
    hoverEffect(NewTabBtn, T.BG_BTN_HOV, T.BG_PANEL)

    local Gutter = Instance.new("Frame")
    Gutter.Parent           = MainFrame
    Gutter.Name             = "Gutter"
    Gutter.Size             = UDim2.fromOffset(38, 222)
    Gutter.Position         = UDim2.fromOffset(0, 51)
    Gutter.BackgroundColor3 = T.BG_PANEL
    Gutter.BorderSizePixel  = 0
    Gutter.ClipsDescendants = true
    Gutter.ZIndex           = 2

    local GutterLine = Instance.new("Frame")
    GutterLine.Parent           = Gutter
    GutterLine.Size             = UDim2.new(0, 1, 1, 0)
    GutterLine.Position         = UDim2.new(1, -1, 0, 0)
    GutterLine.BackgroundColor3 = T.STROKE_INNER
    GutterLine.BorderSizePixel  = 0
    GutterLine.ZIndex           = 3

    local LineNumbers = Instance.new("TextLabel")
    LineNumbers.Parent                 = Gutter
    LineNumbers.Name                   = "LineNumbers"
    LineNumbers.Size                   = UDim2.new(1, -4, 10, 0)
    LineNumbers.Position               = UDim2.fromOffset(0, 4)
    LineNumbers.BackgroundTransparency = 1
    LineNumbers.Text                   = "1"
    LineNumbers.Font                   = Enum.Font.Code
    LineNumbers.TextSize               = 14
    LineNumbers.TextColor3             = T.TEXT_DIM
    LineNumbers.TextXAlignment         = Enum.TextXAlignment.Right
    LineNumbers.TextYAlignment         = Enum.TextYAlignment.Top
    LineNumbers.ZIndex                 = 3

    local EditorFrame = Instance.new("ScrollingFrame")
    EditorFrame.Parent                     = MainFrame
    EditorFrame.Name                       = "EditorScroll"
    EditorFrame.Size                       = UDim2.fromOffset(668, 222)
    EditorFrame.Position                   = UDim2.fromOffset(38, 51)
    EditorFrame.BackgroundColor3           = T.BG_EDITOR
    EditorFrame.BorderSizePixel            = 0
    EditorFrame.ClipsDescendants           = true
    EditorFrame.ScrollBarThickness         = 5
    EditorFrame.ScrollBarImageColor3       = T.STROKE_BTN
    EditorFrame.ScrollBarImageTransparency = 0
    EditorFrame.ScrollingDirection         = Enum.ScrollingDirection.XY
    EditorFrame.ElasticBehavior            = Enum.ElasticBehavior.WhenScrollable
    EditorFrame.CanvasSize                 = UDim2.new(2, 0, 4, 0)
    EditorFrame.VerticalScrollBarPosition  = Enum.VerticalScrollBarPosition.Right
    EditorFrame.BottomImage = ""
    EditorFrame.MidImage    = ""
    EditorFrame.TopImage    = ""
    stroke(EditorFrame, T.STROKE_INNER, 1)

    local HighlightLabel = Instance.new("TextLabel")
    HighlightLabel.Parent                 = EditorFrame
    HighlightLabel.Name                   = "HighlightLabel"
    HighlightLabel.Size                   = UDim2.new(1, -8, 1, 0)
    HighlightLabel.Position               = UDim2.fromOffset(6, 4)
    HighlightLabel.BackgroundTransparency = 1
    HighlightLabel.Text                   = ""
    HighlightLabel.Font                   = Enum.Font.Code
    HighlightLabel.TextSize               = 14
    HighlightLabel.TextColor3             = T.TEXT_MAIN
    HighlightLabel.TextXAlignment         = Enum.TextXAlignment.Left
    HighlightLabel.TextYAlignment         = Enum.TextYAlignment.Top
    HighlightLabel.TextTruncate           = Enum.TextTruncate.None
    HighlightLabel.RichText               = true
    HighlightLabel.ZIndex                 = 1

    local CodeBox = Instance.new("TextBox")
    CodeBox.Parent                 = EditorFrame
    CodeBox.Name                   = "CodeBox"
    CodeBox.Size                   = UDim2.new(1, -8, 1, 0)
    CodeBox.Position               = UDim2.fromOffset(6, 4)
    CodeBox.BackgroundTransparency = 1
    CodeBox.Text                   = ""
    CodeBox.Font                   = Enum.Font.Code
    CodeBox.TextSize               = 14
    CodeBox.TextColor3             = Color3.fromRGB(0, 0, 0)
    CodeBox.TextTransparency       = 1
    CodeBox.TextXAlignment         = Enum.TextXAlignment.Left
    CodeBox.TextYAlignment         = Enum.TextYAlignment.Top
    CodeBox.TextTruncate           = Enum.TextTruncate.None
    CodeBox.TextStrokeTransparency = 1
    CodeBox.PlaceholderText        = "-- paste or type your script here"
    CodeBox.PlaceholderColor3      = T.TEXT_DIM
    CodeBox.ClearTextOnFocus       = false
    CodeBox.MultiLine              = true
    CodeBox.ZIndex                 = 2

    local Toolbar = Instance.new("Frame")
    Toolbar.Parent           = MainFrame
    Toolbar.Name             = "Toolbar"
    Toolbar.Size             = UDim2.new(1, 0, 0, 34)
    Toolbar.Position         = UDim2.new(0, 0, 1, -34)
    Toolbar.BackgroundColor3 = T.BG_MID
    Toolbar.BorderSizePixel  = 0

    local ToolbarLine = Instance.new("Frame")
    ToolbarLine.Parent           = Toolbar
    ToolbarLine.Size             = UDim2.new(1, 0, 0, 1)
    ToolbarLine.Position         = UDim2.fromOffset(0, 0)
    ToolbarLine.BackgroundColor3 = T.STROKE_INNER
    ToolbarLine.BorderSizePixel  = 0

    local btnDefs = {
        { name = "Execute",     label = "Execute",      x = 6   },
        { name = "Clear",       label = "Clear",        x = 98  },
        { name = "OpenFile",    label = "Open File",    x = 190 },
        { name = "ExecuteFile", label = "Execute File", x = 282 },
        { name = "SaveFile",    label = "Save File",    x = 374 },
        { name = "Options",     label = "Options",      x = 466 },
        { name = "Attach",      label = "Attach",       x = 558 },
        { name = "Hub",         label = "Script Hub",   x = 620 },
        { name = "AuditToggle", label = "AUDIT: OFF",   x = 706 },
    }
    local buttons = {}
    for _, def in ipairs(btnDefs) do
        local btn = Instance.new("TextButton")
        btn.Parent           = Toolbar
        btn.Name             = def.name
        btn.Size             = UDim2.fromOffset(86, 22)
        btn.Position         = UDim2.fromOffset(def.x, 6)
        btn.BackgroundColor3 = T.BG_BTN
        btn.BorderSizePixel  = 0
        btn.Text             = def.label
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 11
        btn.TextColor3       = T.TEXT_MAIN
        btn.ZIndex           = 2
        stroke(btn, T.STROKE_BTN, 1)
        hoverEffect(btn, T.BG_BTN_HOV, T.BG_BTN)
        buttons[def.name] = btn
    end
    local execStroke = buttons["Execute"]:FindFirstChildOfClass("UIStroke")
    if execStroke then execStroke.Color = T.STROKE_ACCENT end

    ScreenGui.Parent = playerGui
    return {
        ScreenGui      = ScreenGui,
        ToggleBtn      = ToggleBtn,
        MainFrame      = MainFrame,
        TitleBar       = TitleBar,
        CloseBtn       = CloseBtn,
        MinBtn         = MinBtn,
        CodeBox        = CodeBox,
        HighlightLabel = HighlightLabel,
        EditorScroll   = EditorFrame,
        LineNumbers    = LineNumbers,
        TabClose       = Tab1Close,
        NewTab         = NewTabBtn,
        Execute        = buttons["Execute"],
        Clear          = buttons["Clear"],
        OpenFile       = buttons["OpenFile"],
        ExecuteFile    = buttons["ExecuteFile"],
        SaveFile       = buttons["SaveFile"],
        Options        = buttons["Options"],
        Attach         = buttons["Attach"],
        Hub            = buttons["Hub"],
        AuditToggle    = buttons["AuditToggle"],
    }
end

local Syntax = {
    Text          = Color3.fromRGB(204,204,204),
    Operator      = Color3.fromRGB(204,204,204),
    Number        = Color3.fromRGB(255,198,0),
    String        = Color3.fromRGB(173,241,149),
    Comment       = Color3.fromRGB(102,102,102),
    Keyword       = Color3.fromRGB(248,109,124),
    BuiltIn       = Color3.fromRGB(132,214,247),
    LocalMethod   = Color3.fromRGB(253,251,172),
    LocalProperty = Color3.fromRGB(97,161,241),
    Nil           = Color3.fromRGB(255,198,0),
    Bool          = Color3.fromRGB(255,198,0),
    Function      = Color3.fromRGB(248,109,124),
    Local         = Color3.fromRGB(248,109,124),
    Self          = Color3.fromRGB(248,109,124),
    FunctionName  = Color3.fromRGB(253,251,172),
    Bracket       = Color3.fromRGB(204,204,204),
}
local function colorToHex(c)
    return string.format("#%02x%02x%02x",
        math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
end
local HL_KEYWORDS = {
    ["and"]=true,["break"]=true,["do"]=true,["else"]=true,["elseif"]=true,
    ["end"]=true,["for"]=true,["function"]=true,["if"]=true,["in"]=true,
    ["local"]=true,["not"]=true,["or"]=true,["repeat"]=true,["return"]=true,
    ["then"]=true,["until"]=true,["while"]=true,
    ["false"]=true,["true"]=true,["nil"]=true,
}
local HL_BUILTINS = {
    ["game"]=true,["Players"]=true,["TweenService"]=true,["ScreenGui"]=true,
    ["Instance"]=true,["UDim2"]=true,["Vector2"]=true,["Vector3"]=true,
    ["Color3"]=true,["Enum"]=true,["loadstring"]=true,["warn"]=true,
    ["pcall"]=true,["print"]=true,["UDim"]=true,["delay"]=true,
    ["require"]=true,["spawn"]=true,["tick"]=true,["getfenv"]=true,
    ["workspace"]=true,["setfenv"]=true,["getgenv"]=true,["script"]=true,
    ["string"]=true,["pairs"]=true,["type"]=true,["math"]=true,
    ["tonumber"]=true,["tostring"]=true,["CFrame"]=true,["BrickColor"]=true,
    ["table"]=true,["Random"]=true,["Ray"]=true,["xpcall"]=true,
    ["coroutine"]=true,["_G"]=true,["_VERSION"]=true,["debug"]=true,
    ["Axes"]=true,["assert"]=true,["error"]=true,["ipairs"]=true,
    ["rawequal"]=true,["rawget"]=true,["rawset"]=true,["select"]=true,
    ["bit32"]=true,["buffer"]=true,["task"]=true,["os"]=true,
}
local HL_METHODS = {
    ["WaitForChild"]=true,["FindFirstChild"]=true,["GetService"]=true,
    ["Destroy"]=true,["Clone"]=true,["IsA"]=true,["ClearAllChildren"]=true,
    ["GetChildren"]=true,["GetDescendants"]=true,["Connect"]=true,
    ["Disconnect"]=true,["Fire"]=true,["Invoke"]=true,["rgb"]=true,
    ["FireServer"]=true,["request"]=true,["call"]=true,
}
local function hlTokenize(line)
    local tokens, i = {}, 1
    while i <= #line do
        local c = line:sub(i,i)
        if c == "-" and line:sub(i,i+1) == "--" then
            table.insert(tokens, {line:sub(i), "Comment"}); break
        elseif c == "[" and line:sub(i,i+1):match("%[=*%[") then
            local eqCount, k = 0, i+1
            while line:sub(k,k) == "=" do eqCount += 1; k += 1 end
            if line:sub(k,k) == "[" then
                local close  = "]"..string.rep("=",eqCount).."]"
                local endIdx = line:find(close, k+1, true)
                local j      = endIdx and (endIdx + #close - 1) or #line
                table.insert(tokens, {line:sub(i,j), "String"}); i = j
            else
                table.insert(tokens, {c, "Operator"})
            end
        elseif c == '"' or c == "'" then
            local q, j = c, i+1
            while j <= #line do
                if line:sub(j,j) == q and line:sub(j-1,j-1) ~= "\\" then break end
                j += 1
            end
            table.insert(tokens, {line:sub(i,j), "String"}); i = j
        elseif c:match("%d") then
            local j = i
            while j <= #line and line:sub(j,j):match("[%d%.xXa-fA-F_]") do j += 1 end
            table.insert(tokens, {line:sub(i,j-1), "Number"}); i = j-1
        elseif c:match("[%a_]") then
            local j = i
            while j <= #line and line:sub(j,j):match("[%w_]") do j += 1 end
            table.insert(tokens, {line:sub(i,j-1), "Word"}); i = j-1
        else
            table.insert(tokens, {c, "Operator"})
        end
        i += 1
    end
    return tokens
end
local function hlDetect(tokens, idx)
    local val, typ = tokens[idx][1], tokens[idx][2]
    if typ ~= "Word" then return typ end
    if val == "self"                   then return "Self"          end
    if val == "true" or val == "false" then return "Bool"          end
    if val == "nil"                    then return "Nil"           end
    if HL_KEYWORDS[val]                then return "Keyword"       end
    if HL_BUILTINS[val]                then return "BuiltIn"       end
    if HL_METHODS[val]                 then return "LocalMethod"   end
    local prev = idx > 1 and tokens[idx-1][1] or ""
    if prev == "."                     then return "LocalProperty" end
    if prev == ":"                     then return "LocalMethod"   end
    if prev == "function"              then return "FunctionName"  end
    return "Text"
end
local function hlLine(line)
    local tokens = hlTokenize(line)
    local out    = ""
    for i, tok in ipairs(tokens) do
        local col  = Syntax[hlDetect(tokens, i)] or Syntax.Text
        local safe = tok[1]
            :gsub("&","&amp;")
            :gsub("<","&lt;")
            :gsub(">","&gt;")
        out ..= string.format('<font color="%s">%s</font>', colorToHex(col), safe)
    end
    return out
end
local function applySyntaxHighlight(source, overlayLabel)
    if not overlayLabel then return end
    local lines    = source:split("\n")
    local rendered = {}
    for _, ln in ipairs(lines) do rendered[#rendered+1] = hlLine(ln) end
    overlayLabel.Text = table.concat(rendered, "\n")
end
local function updateLineNumbers(codeText, lineLabel)
    local count = 1
    for _ in codeText:gmatch("\n") do count += 1 end
    local lines = {}
    for i = 1, count do lines[i] = tostring(i) end
    lineLabel.Text = table.concat(lines, "\n")
end

local ui = createGui()

ui.ToggleBtn.MouseButton1Click:Connect(function()
    local f = ui.MainFrame
    if f.Visible then
        TweenService:Create(f, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size     = UDim2.new(0, f.AbsoluteSize.X, 0, 0),
            Position = f.Position + UDim2.fromOffset(0, f.AbsoluteSize.Y / 2)
        }):Play()
        task.delay(0.18, function()
            f.Visible  = false
            f.Size     = UDim2.fromOffset(706, 289)
            f.Position = UDim2.fromScale(0.062, 0.096)
        end)
    else
        f.Size    = UDim2.new(0, 706, 0, 0)
        f.Visible = true
        TweenService:Create(f, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(706, 289)
        }):Play()
    end
end)
ui.CloseBtn.MouseButton1Click:Connect(function()
    local f = ui.MainFrame
    TweenService:Create(f, TweenInfo.new(0.15), { Size = UDim2.new(0, f.AbsoluteSize.X, 0, 0) }):Play()
    task.delay(0.15, function()
        f.Visible = false
        f.Size    = UDim2.fromOffset(706, 289)
    end)
end)
local minimized = false
local FULL_SIZE = UDim2.fromOffset(706, 289)
local MINI_SIZE = UDim2.fromOffset(706, 28)
ui.MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    TweenService:Create(ui.MainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
        Size = minimized and MINI_SIZE or FULL_SIZE
    }):Play()
end)

do
    local dragging = false
    local dragStart, startPos = Vector2.zero, UDim2.new()
    local DRAG_TWEEN = TweenInfo.new(0.04)
    ui.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = ui.MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        TweenService:Create(ui.MainFrame, DRAG_TWEEN, {
            Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        }):Play()
    end)
end

ui.CodeBox:GetPropertyChangedSignal("Text"):Connect(function()
    local src = ui.CodeBox.Text
    updateLineNumbers(src, ui.LineNumbers)
    applySyntaxHighlight(src, ui.HighlightLabel)
end)

local _auditMode = false

local function _synapseExec(code, label)
    if _auditMode and getgenv().__AUDITOR then
        print("[SynapseUI] Audit mode ON — routing through AUDITOR")
        getgenv().__AUDITOR.run(code, label or "SynapseUI_exec")
    else
        local fn, err = loadstring(code)
        if fn then
            local ok, runErr = pcall(fn)
            if not ok then warn("[SynapseUI] Runtime error: " .. tostring(runErr)) end
        else
            warn("[SynapseUI] Compile error: " .. tostring(err))
        end
    end
end

ui.Execute.MouseButton1Click:Connect(function()
    flash(ui.Execute)
    local code = ui.CodeBox.Text
    if code ~= "" then _synapseExec(code, "SynapseUI_execute") end
end)
ui.Clear.MouseButton1Click:Connect(function()
    flash(ui.Clear)
    ui.CodeBox.Text = ""
end)
ui.OpenFile.MouseButton1Click:Connect(function()
    flash(ui.OpenFile)
    if readfile and isfile then
        local name = "autoexec.lua"
        if isfile(name) then
            ui.CodeBox.Text = readfile(name)
        else
            warn("[SynapseUI] File not found: " .. name)
        end
    else
        warn("[SynapseUI] readfile not available")
    end
end)
ui.ExecuteFile.MouseButton1Click:Connect(function()
    flash(ui.ExecuteFile)
    if readfile and isfile then
        local name = "autoexec.lua"
        if isfile(name) then
            _synapseExec(readfile(name), "SynapseUI_execfile:" .. name)
        else
            warn("[SynapseUI] File not found: " .. name)
        end
    else
        warn("[SynapseUI] readfile not available")
    end
end)
ui.SaveFile.MouseButton1Click:Connect(function()
    flash(ui.SaveFile)
    if writefile then
        writefile("saved_script.lua", ui.CodeBox.Text)
        print("[SynapseUI] Saved to saved_script.lua")
    else
        warn("[SynapseUI] writefile not available")
    end
end)
ui.Options.MouseButton1Click:Connect(function()
    flash(ui.Options)
    print("[SynapseUI] Options")
end)
ui.Attach.MouseButton1Click:Connect(function()
    flash(ui.Attach)
    local s = ui.Attach:FindFirstChildOfClass("UIStroke")
    if s then s.Color = T.ATTACH_ON end
    print("[SynapseUI] Attach")
end)
ui.Hub.MouseButton1Click:Connect(function()
    flash(ui.Hub)
    print("[SynapseUI] Script Hub")
end)
ui.TabClose.MouseButton1Click:Connect(function()
    ui.CodeBox.Text = ""
    print("[SynapseUI] Tab closed")
end)
ui.NewTab.MouseButton1Click:Connect(function()
    ui.CodeBox.Text = ""
    print("[SynapseUI] New tab")
end)

local _auditStroke    = ui.AuditToggle:FindFirstChildOfClass("UIStroke")
local _lastAuditClick = 0

ui.AuditToggle.MouseButton1Click:Connect(function()
    flash(ui.AuditToggle)
    local now = tick()
        if now - _lastAuditClick < 0.35 then
        if getgenv().__AUDITOR then
            print("[SynapseUI] Dumping AUDITOR trace...")
            getgenv().__AUDITOR.dump()
        else
            warn("[SynapseUI] AUDITOR not loaded.")
        end
        _lastAuditClick = 0
        return
    end
    _lastAuditClick = now
        _auditMode = not _auditMode
    local execStroke = ui.Execute:FindFirstChildOfClass("UIStroke")
    if _auditMode then
        ui.AuditToggle.Text       = "AUDIT: ON"
        ui.AuditToggle.TextColor3 = T.ATTACH_ON
        if _auditStroke then _auditStroke.Color = T.ATTACH_ON    end
        if execStroke   then execStroke.Color   = T.ATTACH_ON    end
        print("[SynapseUI] Audit mode ON — Execute routes through AUDITOR + SHIELD")
    else
        ui.AuditToggle.Text       = "AUDIT: OFF"
        ui.AuditToggle.TextColor3 = T.TEXT_MAIN
        if _auditStroke then _auditStroke.Color = T.STROKE_BTN   end
        if execStroke   then execStroke.Color   = T.STROKE_ACCENT end
        print("[SynapseUI] Audit mode OFF — Execute runs through SHIELD hook (sandboxed by default)")
    end
end)

print("[SynapseUI] Ready — SHIELD + AUDITOR embedded and active.")
