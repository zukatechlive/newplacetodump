if SandboxEnv then
	warn("Sandbox Env: Already active — skipping re-init.")
	return
end
local _sandboxCount = 0
local _interceptCount = 0
local _auditLog = {}
local _MAX_LOG = 256
local _bypassNext = false
local _trustedSources = {}
local function _log(category, msg)
	_interceptCount = (category == "INTERCEPT") and (_interceptCount + 1) or _interceptCount
	local entry = string.format("Sandbox Env:[%s] %.3f | %s", category, tick(), msg)
	table.insert(_auditLog, entry)
	if #_auditLog > _MAX_LOG then
		table.remove(_auditLog, 1)
	end
end
local function makeDecoyInstance(className, name)
	className = className or "Instance"
	name = name or className
	local props = {
		Name = name,
		ClassName = className,
		Parent = nil,
		Archivable = false,
	}
	local function fakeSignal()
		local noop = { Disconnect = function() end }
		return {
			Connect = function(_, _f)
				return noop
			end,
			Once = function(_, _f)
				return noop
			end,
			Wait = function()
				return nil
			end,
			ConnectParallel = function(_, _f)
				return noop
			end,
		}
	end
	local mt = {}
	mt.__index = function(_, k)
		if props[k] ~= nil then
			return props[k]
		end
		if k == "GetChildren" or k == "GetDescendants" or k == "GetConnectedParts" or k == "GetTouchingParts" then
			return function()
				return {}
			end
		end
		if
			k == "FindFirstChild"
			or k == "FindFirstChildOfClass"
			or k == "FindFirstChildWhichIsA"
			or k == "FindFirstAncestor"
			or k == "FindFirstAncestorOfClass"
			or k == "FindFirstAncestorWhichIsA"
		then
			return function()
				return nil
			end
		end
		if k == "IsA" then
			return function(_, c)
				return c == className or c == "Instance"
			end
		end
		if k == "IsDescendantOf" or k == "IsAncestorOf" then
			return function()
				return false
			end
		end
		if k == "Clone" then
			return function()
				return makeDecoyInstance(className, name .. "_clone")
			end
		end
		if
			k == "Destroy"
			or k == "Remove"
			or k == "ClearAllChildren"
			or k == "SetAttribute"
			or k == "AddTag"
			or k == "RemoveTag"
		then
			return function() end
		end
		if k == "GetAttribute" then
			return function()
				return nil
			end
		end
		if k == "GetAttributes" then
			return function()
				return {}
			end
		end
		if k == "HasTag" then
			return function()
				return false
			end
		end
		if k == "GetTags" then
			return function()
				return {}
			end
		end
		if k == "GetFullName" then
			return function()
				return "Decoy." .. name
			end
		end
		if k == "WaitForChild" then
			return function(_, n, _timeout)
				return makeDecoyInstance("Instance", n)
			end
		end
		if k == "GetService" then
			return function(_, s)
				return makeDecoyInstance(s, s)
			end
		end
		local signals = {
			"Changed",
			"ChildAdded",
			"ChildRemoved",
			"DescendantAdded",
			"DescendantRemoving",
			"AncestryChanged",
			"AttributeChanged",
			"Destroying",
			"ChildrenChanged",
		}
		for _, sig in ipairs(signals) do
			if k == sig then
				return fakeSignal()
			end
		end
		if k == "Died" or k == "HealthChanged" or k == "Touched" then
			return fakeSignal()
		end
		if k == "Health" or k == "MaxHealth" then
			return 100
		end
		if k == "WalkSpeed" or k == "JumpPower" then
			return 16
		end
		return makeDecoyInstance("Instance", tostring(k))
	end
	mt.__newindex = function(_, k, v)
		props[k] = v
	end
	mt.__tostring = function()
		return className .. "(" .. name .. ")[DECOY]"
	end
	mt.__metatable = "locked"
	return setmetatable({}, mt)
end
local function makeDecoyGame()
	local realPlayers = game:GetService("Players")
	local realLp = realPlayers.LocalPlayer
	local fakeLp = makeDecoyInstance("Player", realLp and realLp.Name or "LocalPlayer")
	do
		local lmt = getmetatable(fakeLp)
		local lorig = lmt.__index
		lmt.__index = function(t, k)
			if k == "UserId" then
				return realLp and realLp.UserId or 0
			end
			if k == "Team" then
				return nil
			end
			if k == "Character" then
				return makeDecoyInstance("Model", "Character")
			end
			if k == "Backpack" then
				return makeDecoyInstance("Backpack", "Backpack")
			end
			if k == "PlayerGui" then
				return makeDecoyInstance("PlayerGui", "PlayerGui")
			end
			if k == "PlayerScripts" then
				return makeDecoyInstance("PlayerScripts", "PlayerScripts")
			end
			return lorig(t, k)
		end
	end
	local fakePlayers = makeDecoyInstance("Players", "Players")
	do
		local pmt = getmetatable(fakePlayers)
		local porig = pmt.__index
		pmt.__index = function(t, k)
			if k == "LocalPlayer" then
				return fakeLp
			end
			if k == "GetPlayers" then
				return function()
					return { fakeLp }
				end
			end
			if k == "PlayerAdded" then
				return {
					Connect = function(_, _f)
						return { Disconnect = function() end }
					end,
				}
			end
			if k == "PlayerRemoving" then
				return {
					Connect = function(_, _f)
						return { Disconnect = function() end }
					end,
				}
			end
			return porig(t, k)
		end
	end
	local fakeRun = makeDecoyInstance("RunService", "RunService")
	do
		local rmt = getmetatable(fakeRun)
		local rorig = rmt.__index
		local noop = {
			Connect = function(_, _f)
				return { Disconnect = function() end }
			end,
		}
		rmt.__index = function(t, k)
			if k == "Heartbeat" then
				return noop
			end
			if k == "RenderStepped" then
				return noop
			end
			if k == "Stepped" then
				return noop
			end
			if k == "IsClient" then
				return function()
					return true
				end
			end
			if k == "IsServer" then
				return function()
					return false
				end
			end
			if k == "IsStudio" then
				return function()
					return false
				end
			end
			return rorig(t, k)
		end
	end
	local fakeHttp = makeDecoyInstance("HttpService", "HttpService")
	do
		local hmt = getmetatable(fakeHttp)
		local horig = hmt.__index
		hmt.__index = function(t, k)
			if k == "GetAsync" or k == "PostAsync" or k == "RequestAsync" then
				return function()
					error("HttpService blocked by SHIELD")
				end
			end
			if k == "JSONEncode" then
				return function(_, v)
					local ok, r = pcall(function()
						return tostring(v)
					end)
					return ok and r or "{}"
				end
			end
			if k == "JSONDecode" then
				return function(_, _s)
					return {}
				end
			end
			return horig(t, k)
		end
	end
	local svcMap = {
		Workspace = makeDecoyInstance("Workspace", "Workspace"),
		Players = fakePlayers,
		ReplicatedStorage = makeDecoyInstance("ReplicatedStorage", "ReplicatedStorage"),
		ServerStorage = makeDecoyInstance("ServerStorage", "ServerStorage"),
		ServerScriptService = makeDecoyInstance("ServerScriptService", "ServerScriptService"),
		StarterGui = makeDecoyInstance("StarterGui", "StarterGui"),
		StarterPack = makeDecoyInstance("StarterPack", "StarterPack"),
		StarterPlayer = makeDecoyInstance("StarterPlayer", "StarterPlayer"),
		SoundService = makeDecoyInstance("SoundService", "SoundService"),
		HttpService = fakeHttp,
		RunService = fakeRun,
		TweenService = makeDecoyInstance("TweenService", "TweenService"),
		UserInputService = makeDecoyInstance("UserInputService", "UserInputService"),
		CoreGui = makeDecoyInstance("CoreGui", "CoreGui"),
		Lighting = makeDecoyInstance("Lighting", "Lighting"),
		Teams = makeDecoyInstance("Teams", "Teams"),
		Chat = makeDecoyInstance("Chat", "Chat"),
		VirtualInputManager = makeDecoyInstance("VirtualInputManager", "VirtualInputManager"),
		GuiService = makeDecoyInstance("GuiService", "GuiService"),
		ContextActionService = makeDecoyInstance("ContextActionService", "ContextActionService"),
		MarketplaceService = makeDecoyInstance("MarketplaceService", "MarketplaceService"),
		BadgeService = makeDecoyInstance("BadgeService", "BadgeService"),
		DataStoreService = makeDecoyInstance("DataStoreService", "DataStoreService"),
		MessagingService = makeDecoyInstance("MessagingService", "MessagingService"),
		PhysicsService = makeDecoyInstance("PhysicsService", "PhysicsService"),
		CollectionService = makeDecoyInstance("CollectionService", "CollectionService"),
	}
	rawset(svcMap.Workspace, "CurrentCamera", makeDecoyInstance("Camera", "Camera"))
	local fakeGame = makeDecoyInstance("DataModel", "Game")
	local fmt = getmetatable(fakeGame)
	local forig = fmt.__index
	fmt.__index = function(t, k)
		if k == "GetService" then
			return function(_, s)
				if svcMap[s] then
					return svcMap[s]
				end
				local d = makeDecoyInstance(s, s)
				svcMap[s] = d
				return d
			end
		end
		if k == "PlaceId" then
			return 0
		end
		if k == "JobId" then
			return "00000000-0000-0000-0000-000000000000"
		end
		if k == "CreatorId" then
			return 0
		end
		if svcMap[k] then
			return svcMap[k]
		end
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
	{ pattern = "getfenv%s*%(%s*0%s*%)", label = "getfenv(0) env-steal" },
	{ pattern = "string%.byte.+string%.char", label = "byte/char loop (bytecode obfusc)" },
	{ pattern = "load%s*%(.-%)", label = "raw load() call" },
	{ pattern = "pcall%s*%(%s*load", label = "pcall+load wrapper" },
	{ pattern = "%_ENV%s*=%s*nil", label = "_ENV=nil lockout" },
	{ pattern = "syn%.request", label = "Synapse HTTP request" },
	{ pattern = "fluxus%.request", label = "Fluxus HTTP request" },
	{ pattern = "getgenv%s*%(%s*%)", label = "getgenv() access" },
	{ pattern = "getrawmetatable%s*%(%s*game", label = "getrawmetatable(game)" },
	{ pattern = "hookmetamethod%s*%(%s*game", label = "hookmetamethod(game)" },
	{ pattern = "hookfunction", label = "hookfunction call" },
	{ pattern = "firetouchinterest", label = "fireTouchInterest exploit fn" },
	{ pattern = "fireproximityprompt", label = "fireProximityPrompt exploit fn" },
	{ pattern = "writefile", label = "writefile FS access" },
	{ pattern = "readfile", label = "readfile FS access" },
	{ pattern = "loadfile", label = "loadfile FS access" },
	{ pattern = "require%s*%(%s*%-?%d+", label = "require(id) module load" },
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
		wait = function(n)
			return task.wait(n)
		end,
		delay = function(n, fn)
			task.delay(n, function()
				local ok, err = pcall(setfenv(fn, sandboxEnv))
				if not ok then
					_log("SANDBOX_ERR", "task.delay fn error: " .. tostring(err))
				end
			end)
		end,
		spawn = function(fn, ...)
			local args = { ... }
			task.spawn(function()
				local ok, err = pcall(function()
					return setfenv(fn, sandboxEnv)(table.unpack(args))
				end)
				if not ok then
					_log("SANDBOX_ERR", "task.spawn fn error: " .. tostring(err))
				end
			end)
		end,
		defer = function(fn, ...)
			local args = { ... }
			task.defer(function()
				local ok, err = pcall(function()
					return setfenv(fn, sandboxEnv)(table.unpack(args))
				end)
				if not ok then
					_log("SANDBOX_ERR", "task.defer fn error: " .. tostring(err))
				end
			end)
		end,
		synchronize = function() end,
		desynchronize = function() end,
		cancel = function() end,
	}
end
local function makeSandboxedCoroutine(sandboxEnv)
	return {
		create = function(fn)
			return coroutine.create(setfenv(fn, sandboxEnv))
		end,
		wrap = function(fn)
			return coroutine.wrap(setfenv(fn, sandboxEnv))
		end,
		resume = coroutine.resume,
		yield = coroutine.yield,
		status = coroutine.status,
		running = coroutine.running,
		isyieldable = coroutine.isyieldable,
	}
end
local _fakeModuleCache = {}
local function sandboxedRequire(id)
	if type(id) == "number" then
		if _fakeModuleCache[id] then
			return _fakeModuleCache[id]
		end
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
		__index = t,
		__newindex = function() end,
		__metatable = "locked",
	})
end
local function buildEnv(fakeGame, fakeWs)
	_sandboxCount = _sandboxCount + 1
	local sandboxId = _sandboxCount
	local env = {}
	local function sandboxedLoadstring(src, chunkName)
		local fn, err = (getgenv()._SandboxEnv_REAL_LOADSTRING or loadstring)(src, chunkName or "sandboxed_inner")
		if not fn then
			return nil, err
		end
		local innerGame, innerWs = makeDecoyGame()
		local innerEnv = buildEnv(innerGame, innerWs)
		setfenv(fn, innerEnv)
		return fn
	end
	env.print = print
	env.warn = warn
	env.error = error
	env.assert = assert
	env.tostring = tostring
	env.tonumber = tonumber
	env.type = type
	env.typeof = typeof
	env.pairs = pairs
	env.ipairs = ipairs
	env.next = next
	env.select = select
	env.unpack = table.unpack or unpack
	env.rawget = rawget
	env.rawset = rawset
	env.rawequal = rawequal
	env.rawlen = rawlen
	env.pcall = pcall
	env.xpcall = xpcall
	env.setmetatable = setmetatable
	env.getmetatable = getmetatable
	env.collectgarbage = function() end
	env.newproxy = newproxy
	env.math = readonly(math)
	env.table = readonly(table)
	env.string = readonly(string)
	env.bit32 = bit32 and readonly(bit32) or nil
	env.utf8 = utf8 and readonly(utf8) or nil
	env.tick = tick
	env.time = time
	env.os = readonly({ clock = os.clock, time = os.time, date = os.date })
	env.Vector3 = Vector3
	env.Vector2 = Vector2
	env.Vector2int16 = Vector2int16
	env.Vector3int16 = Vector3int16
	env.CFrame = CFrame
	env.Color3 = Color3
	env.UDim2 = UDim2
	env.UDim = UDim
	env.Rect = Rect
	env.Enum = Enum
	env.Instance = Instance
	env.TweenInfo = TweenInfo
	env.NumberSequence = NumberSequence
	env.ColorSequence = ColorSequence
	env.Ray = Ray
	env.Region3 = Region3
	env.RaycastParams = RaycastParams
	env.OverlapParams = OverlapParams
	env.game = fakeGame
	env.workspace = fakeWs
	env.Workspace = fakeWs
	env.script = makeDecoyInstance("LocalScript", "SandboxedScript_" .. sandboxId)
	env.shared = {}
	env._G = {}
	env.task = makeSandboxedTask(env)
	env.coroutine = makeSandboxedCoroutine(env)
	env.loadstring = sandboxedLoadstring
	env.require = sandboxedRequire
	env.load = function()
		error("Sandbox Env: load() is blocked inside the sandbox")
	end
	local _poisonedGlobals = {
		"getfenv",
		"setfenv",
		"getgenv",
		"getrenv",
		"getgc",
		"getinstances",
		"getsenv",
		"getupvalues",
		"getupvalue",
		"setupvalue",
		"getconstants",
		"getconstant",
		"getrawmetatable",
		"setrawmetatable",
		"setreadonly",
		"isreadonly",
		"hookfunction",
		"hookmetamethod",
		"newcclosure",
		"iscclosure",
		"islclosure",
		"isexecutorclosure",
		"checkcaller",
		"decompile",
		"getscriptbytecode",
		"getscripthash",
		"getscripts",
		"getscriptclosure",
		"getthreadcontext",
		"setthreadidentity",
		"getthreadidentity",
		"firetouchinterest",
		"fireproximityprompt",
		"fireclickdetector",
		"writefile",
		"readfile",
		"loadfile",
		"appendfile",
		"listfiles",
		"makefolder",
		"isfile",
		"isfolder",
		"delfile",
		"delfolder",
		"request",
		"http_request",
		"syn",
		"fluxus",
		"KRNL_LOADED",
		"SYNAPSE_LOADED",
		"Sentinel",
		"Oxygen",
		"cachedWS",
		"SandboxEnv",
	}
	for _, g in ipairs(_poisonedGlobals) do
		env[g] = nil
	end
	env.tostring = function(v)
		if v == fakeGame then
			return "DataModel"
		end
		if v == fakeWs then
			return "Workspace"
		end
		return tostring(v)
	end
	env.typeof = function(v)
		local mt = getmetatable(v)
		if mt == "locked" then
			local ok, cls = pcall(function()
				return v.ClassName
			end)
			if ok and type(cls) == "string" and cls ~= "" then
				return cls
			end
		end
		return typeof(v)
	end
	env._ENV = env
	return env
end
local genv = getgenv()
local REAL_LOADSTRING = genv.loadstring or loadstring
genv._SandboxEnv_REAL_LOADSTRING = REAL_LOADSTRING
local function startWatchdog()
	task.spawn(function()
		while SandboxEnv do
			task.wait(5)
			if genv.loadstring ~= genv._SandboxEnv_HOOK then
				_log("WATCHDOG", "Hook tampered — reinstalling!")
				genv.loadstring = genv._SandboxEnv_HOOK
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
		_log(
			"INTERCEPT",
			string.format("Suspicious source [%s] — flags: %s", chunkName or "?", table.concat(flags, ", "))
		)
	else
		_log("INTERCEPT", string.format("Sandboxing chunk: %s", chunkName or "untrusted"))
	end
	local fakeGame, fakeWs = makeDecoyGame()
	local env = buildEnv(fakeGame, fakeWs)
	setfenv(fn, env)
	return fn
end)
genv.loadstring = shieldHook
genv._SandboxEnv_HOOK = shieldHook
SandboxEnv = {
	exec = function(source, chunkName)
		local fn, err = REAL_LOADSTRING(source, chunkName or "trusted")
		if not fn then
			warn("Sandbox Env: Compile error:", err)
			return false, err
		end
		local ok, runErr = pcall(fn)
		if not ok then
			warn("Sandbox Env: Runtime error:", runErr)
			return false, runErr
		end
		return true
	end,
	execSandboxed = function(source, chunkName)
		local fn, err = REAL_LOADSTRING(source, chunkName or "sandboxed_manual")
		if not fn then
			warn("Sandbox Env: Compile error:", err)
			return false, err
		end
		local fakeGame, fakeWs = makeDecoyGame()
		local env = buildEnv(fakeGame, fakeWs)
		setfenv(fn, env)
		local ok, runErr = pcall(fn)
		if not ok then
			warn("Sandbox Env: Sandbox runtime error:", runErr)
			return false, runErr
		end
		return true
	end,
	bypass = function()
		_bypassNext = true
		print("Sandbox Env: Bypass armed — next untrusted loadstring call will go through raw.")
	end,
	trust = function(chunkName)
		_trustedSources[chunkName] = true
		print("Sandbox Env: Trusted chunkName registered: " .. tostring(chunkName))
	end,
	untrust = function(chunkName)
		_trustedSources[chunkName] = nil
		print("Sandbox Env: chunkName unregistered: " .. tostring(chunkName))
	end,
	inspect = function(fn)
		if type(fn) ~= "function" then
			warn("Sandbox Env: inspect() expects a function, got " .. type(fn))
			return
		end
		local ups = getupvalues and getupvalues(fn) or {}
		print(string.format("Sandbox Env: inspect() — %d upvalue(s) found:", #ups))
		for i, v in ipairs(ups) do
			print(string.format("  [%d] %s", i, tostring(v)))
		end
		return ups
	end,
	log = function(n)
		n = n or 20
		local start = math.max(1, #_auditLog - n + 1)
		print(string.format("Sandbox Env: Last %d log entries:", math.min(n, #_auditLog)))
		for i = start, #_auditLog do
			print("  " .. _auditLog[i])
		end
	end,
	getLog = function()
		return _auditLog
	end,
	status = function()
		print(
			string.format(
				"Sandbox Env: Active | Sandboxes created: %d | Calls intercepted: %d | Log entries: %d",
				_sandboxCount,
				_interceptCount,
				#_auditLog
			)
		)
	end,
	scan = function(source)
		local flags = detectObfuscation(source)
		if #flags == 0 then
			print("Sandbox Env: Scan: no suspicious patterns detected.")
		else
			print("Sandbox Env: Scan: " .. #flags .. " flag(s) found:")
			for _, f in ipairs(flags) do
				print("  ⚠  " .. f)
			end
		end
		return flags
	end,
	disable = function()
		genv.loadstring = REAL_LOADSTRING
		genv._SandboxEnv_REAL_LOADSTRING = nil
		genv._SandboxEnv_HOOK = nil
		SandboxEnv = nil
		genv.SandboxEnv = nil
		print("Sandbox Env: Disabled. loadstring restored to original.")
	end,
}
genv.SandboxEnv = SandboxEnv
startWatchdog()
