-- instance.lua
-- Fake Instance tree: Instance.new(), :GetService(), :FindFirstChild(), .Parent, etc.
-- This is the mock DOM that stands in for the real Roblox DataModel.
--
-- PATCH NOTES (search for "[patch N]"):
--   1. Child lookup by name in __index          (game.Players, workspace.Camera, player.PlayerGui)
--   2. Signals: Disconnect works, :Wait(), :Once(), safe iteration during Fire
--   3. IsA() walks a class hierarchy            (Part:IsA("BasePart"), x:IsA("Instance"))
--   4. Clone() is deep and gets fresh signals   (children cloned, refs remapped, no shared signals)
--   5. Position <-> CFrame stay in sync on BaseParts
--   6. Re-parenting to the same parent is a no-op (no duplicate children), cycles are rejected
--   7. Extras: ChildAdded/ChildRemoved/DescendantAdded/DescendantRemoving/Destroying/Changed,
--      GetPropertyChangedSignal, GetDescendants, IsDescendantOf, FindFirstAncestor*,
--      FindFirstChildWhichIsA, attributes, recursive Destroy, tostring(instance) == Name,
--      Humanoid.Health assignment fires HealthChanged / Died.
--
-- OPTIONAL wiring for fully-populated Parts (Size/CFrame/Position defaults):
--   local inst = dofile("instance.lua"); inst.useDatatypes(dofile("datatypes.lua"))

local M = {}

local DT = nil
function M.useDatatypes(dt) DT = dt end

local function P(t) return rawget(t, "_props") end

------------------------------------------------------------
-- [patch 2] Signals: RBXScriptSignal mock
-- (defined first so Instance code can create and recognise signals)
------------------------------------------------------------
local Signal = {}
Signal.__index = Signal

local function newSignal()
    return setmetatable({_conns = {}}, Signal)
end
local function isSignal(v)
    return type(v) == "table" and getmetatable(v) == Signal
end

function Signal:Connect(fn)
    local conn = {Connected = true, _fn = fn}
    local sig = self
    -- works as both conn:Disconnect() and conn.Disconnect()
    conn.Disconnect = function()
        conn.Connected = false
        for i, c in ipairs(sig._conns) do
            if c == conn then table.remove(sig._conns, i) break end
        end
    end
    table.insert(self._conns, conn)
    return conn
end

function Signal:Once(fn)
    local conn
    conn = self:Connect(function(...)
        conn.Disconnect()
        fn(...)
    end)
    return conn
end

function Signal:Fire(...)
    -- iterate a snapshot: handlers may connect/disconnect while we fire
    local snap = {}
    for i, c in ipairs(self._conns) do snap[i] = c end
    for i = 1, #snap do
        local c = snap[i]
        if c.Connected then
            local ok, err = pcall(c._fn, ...)
            if not ok then print("[signal handler error] " .. tostring(err)) end
        end
    end
end

-- Blocks the *calling coroutine* until the signal fires. There is no scheduler in the
-- mock, so calling this on the main thread (or inside a synchronous task.spawn) errors
-- loudly instead of silently misbehaving.
function Signal:Wait()
    local co, ismain = coroutine.running()
    if co == nil or ismain then
        error("Signal:Wait() called outside a coroutine (the mock has no scheduler to block the main thread)", 2)
    end
    self:Once(function(...)
        local ok, err = coroutine.resume(co, ...)
        if not ok then print("[signal wait resume error] " .. tostring(err)) end
    end)
    return coroutine.yield()
end

M.newSignal = newSignal

------------------------------------------------------------
-- [patch 3] Class hierarchy for IsA()
------------------------------------------------------------
local CLASS_PARENT = {
    -- 3D
    PVInstance = "Instance", BasePart = "PVInstance", Model = "PVInstance",
    Part = "BasePart", WedgePart = "BasePart", CornerWedgePart = "BasePart",
    MeshPart = "BasePart", TrussPart = "BasePart", VehicleSeat = "BasePart",
    UnionOperation = "BasePart", Terrain = "BasePart",
    SpawnLocation = "Part", Seat = "Part",
    WorldRoot = "Model", Workspace = "WorldRoot",
    BackpackItem = "Model", Tool = "BackpackItem",
    -- GUI
    GuiBase = "Instance", GuiBase2d = "GuiBase", GuiObject = "GuiBase2d",
    GuiButton = "GuiObject",
    Frame = "GuiObject", TextLabel = "GuiObject", TextBox = "GuiObject",
    ImageLabel = "GuiObject", ScrollingFrame = "GuiObject", ViewportFrame = "GuiObject",
    VideoFrame = "GuiObject", CanvasGroup = "GuiObject",
    TextButton = "GuiButton", ImageButton = "GuiButton",
    LayerCollector = "GuiBase2d", ScreenGui = "LayerCollector",
    BillboardGui = "LayerCollector", SurfaceGui = "LayerCollector",
    BasePlayerGui = "Instance", PlayerGui = "BasePlayerGui",
    StarterGui = "BasePlayerGui", CoreGui = "BasePlayerGui",
    -- values
    ValueBase = "Instance", BoolValue = "ValueBase", IntValue = "ValueBase",
    NumberValue = "ValueBase", StringValue = "ValueBase", Vector3Value = "ValueBase",
    ObjectValue = "ValueBase", Color3Value = "ValueBase", CFrameValue = "ValueBase",
    BrickColorValue = "ValueBase", RayValue = "ValueBase",
    -- scripts
    LuaSourceContainer = "Instance", BaseScript = "LuaSourceContainer",
    Script = "BaseScript", LocalScript = "BaseScript", ModuleScript = "LuaSourceContainer",
    -- lights
    Light = "Instance", PointLight = "Light", SpotLight = "Light", SurfaceLight = "Light",
    -- misc
    ServiceProvider = "Instance", DataModel = "ServiceProvider",
}

local function classIsA(cls, target)
    if target == "Instance" then return true end
    local guard = 0
    while cls and guard < 32 do
        if cls == target then return true end
        cls = CLASS_PARENT[cls]
        guard = guard + 1
    end
    return false
end
M.classIsA = classIsA
function M.registerClass(name, parent) CLASS_PARENT[name] = parent end

------------------------------------------------------------
-- Instance
------------------------------------------------------------
local Instance = {}

-- [patch 1] methods -> properties -> children (by Name)
Instance.__index = function(t, k)
    local m = Instance[k]
    if m ~= nil then return m end
    local v = P(t)[k]
    if v ~= nil then return v end
    if k == "Parent" then return nil end
    local kids = rawget(t, "_children")
    for i = 1, #kids do
        if P(kids[i]).Name == k then return kids[i] end
    end
    return nil
end

Instance.__tostring = function(t) return tostring(P(t).Name) end

local function subtree(root, out)
    out[#out + 1] = root
    for _, c in ipairs(rawget(root, "_children")) do subtree(c, out) end
    return out
end

local function fireChanged(t, props, k, v)
    local ch = props.Changed
    if isSignal(ch) then
        if classIsA(props.ClassName, "ValueBase") then
            if k == "Value" then ch:Fire(v) end   -- ValueBase.Changed passes the new value
        else
            ch:Fire(k)                            -- Instance.Changed passes the property name
        end
    end
    local ps = rawget(t, "_propSignals")[k]
    if ps then ps:Fire() end
end

-- [patch 6] same-parent is a no-op, cycles rejected; [patch 7] hierarchy events
local function setParent(t, props, v)
    local old = props.Parent
    if old == v then return end
    if v ~= nil then
        local a = v
        while a do
            if a == t then
                error(("Attempt to set %s as its own ancestor"):format(tostring(props.Name)), 3)
            end
            a = P(a).Parent
        end
    end

    local nodes = subtree(t, {})
    if old then
        local a = old
        while a do
            local sig = P(a).DescendantRemoving
            if sig then for i = 1, #nodes do sig:Fire(nodes[i]) end end
            a = P(a).Parent
        end
        local sib = rawget(old, "_children")
        for i = 1, #sib do
            if sib[i] == t then table.remove(sib, i) break end
        end
    end

    props.Parent = v
    if v then table.insert(rawget(v, "_children"), t) end

    if old then
        local s = P(old).ChildRemoved
        if s then s:Fire(t) end
    end
    if v then
        local s = P(v).ChildAdded
        if s then s:Fire(t) end
        local a = v
        while a do
            local sig = P(a).DescendantAdded
            if sig then for i = 1, #nodes do sig:Fire(nodes[i]) end end
            a = P(a).Parent
        end
    end
    fireChanged(t, props, "Parent", v)
end

Instance.__newindex = function(t, k, v)
    local props = P(t)
    if k == "Parent" then
        setParent(t, props, v)
        return
    end

    -- [patch 7] Humanoid.Health assignment behaves like the real thing
    if k == "Health" and props.ClassName == "Humanoid" and type(v) == "number" then
        local mx = props.MaxHealth or 100
        if v > mx then v = mx elseif v < 0 then v = 0 end
        local old = props.Health
        props.Health = v
        if old ~= v then
            if isSignal(props.HealthChanged) then props.HealthChanged:Fire(v) end
            if v <= 0 and (old or 0) > 0 and isSignal(props.Died) then props.Died:Fire() end
            fireChanged(t, props, "Health", v)
        end
        return
    end

    -- [patch 5] keep Position and CFrame in sync on BaseParts
    if (k == "CFrame" or k == "Position") and type(v) == "table"
        and classIsA(props.ClassName, "BasePart") then
        if k == "CFrame" then
            props.CFrame = v
            props.Position = v.Position
        else
            local cf = props.CFrame
            local CF = (cf and getmetatable(cf)) or (DT and DT.CFrame)
            props.Position = v
            if CF then
                if cf then
                    props.CFrame = CF.new(v.X, v.Y, v.Z,
                        cf.R00, cf.R01, cf.R02, cf.R10, cf.R11, cf.R12, cf.R20, cf.R21, cf.R22)
                else
                    props.CFrame = CF.new(v.X, v.Y, v.Z)
                end
            end
        end
        fireChanged(t, props, "CFrame", props.CFrame)
        fireChanged(t, props, "Position", props.Position)
        return
    end

    local old = props[k]
    props[k] = v
    if type(v) ~= "function" and old ~= v then fireChanged(t, props, k, v) end
end

local HIERARCHY_SIGNALS = {
    "Changed", "ChildAdded", "ChildRemoved", "DescendantAdded",
    "DescendantRemoving", "Destroying",
}

local function newInstance(className, name)
    local self = setmetatable({
        _props = {
            ClassName = className,
            Name = name or className,
            Parent = nil,
        },
        _children = {},
        _connections = {},
        _attrs = {},
        _propSignals = {},
    }, Instance)
    for _, n in ipairs(HIERARCHY_SIGNALS) do self._props[n] = newSignal() end
    return self
end

function Instance:GetChildren()
    local out = {}
    for i, c in ipairs(self._children) do out[i] = c end
    return out
end

function Instance:GetDescendants()
    local out = {}
    local function walk(n)
        for _, c in ipairs(rawget(n, "_children")) do
            out[#out + 1] = c
            walk(c)
        end
    end
    walk(self)
    return out
end

function Instance:FindFirstChild(name, recursive)
    for _, c in ipairs(self._children) do
        if c.Name == name then return c end
    end
    if recursive then
        for _, c in ipairs(self._children) do
            local found = c:FindFirstChild(name, true)
            if found then return found end
        end
    end
    return nil
end

function Instance:FindFirstChildOfClass(className)
    for _, c in ipairs(self._children) do
        if c.ClassName == className then return c end
    end
    return nil
end

function Instance:FindFirstChildWhichIsA(className, recursive)
    for _, c in ipairs(self._children) do
        if c:IsA(className) then return c end
    end
    if recursive then
        for _, c in ipairs(self._children) do
            local found = c:FindFirstChildWhichIsA(className, true)
            if found then return found end
        end
    end
    return nil
end

function Instance:FindFirstAncestor(name)
    local p = P(self).Parent
    while p do
        if P(p).Name == name then return p end
        p = P(p).Parent
    end
    return nil
end

function Instance:FindFirstAncestorOfClass(className)
    local p = P(self).Parent
    while p do
        if P(p).ClassName == className then return p end
        p = P(p).Parent
    end
    return nil
end

function Instance:FindFirstAncestorWhichIsA(className)
    local p = P(self).Parent
    while p do
        if classIsA(P(p).ClassName, className) then return p end
        p = P(p).Parent
    end
    return nil
end

function Instance:IsDescendantOf(ancestor)
    local p = P(self).Parent
    while p do
        if p == ancestor then return true end
        p = P(p).Parent
    end
    return false
end

function Instance:IsAncestorOf(descendant)
    return descendant:IsDescendantOf(self)
end

function Instance:WaitForChild(name, timeout)
    -- synchronous mock: no real yielding, just checks immediately then gives up
    local found = self:FindFirstChild(name)
    if found then return found end
    error(("WaitForChild: '%s' not found under %s (mock is non-yielding)"):format(name, self.Name))
end

-- [patch 3]
function Instance:IsA(className)
    return classIsA(P(self).ClassName, className)
end

-- [patch 7] recursive, fires Destroying, idempotent
function Instance:Destroy()
    if rawget(self, "_destroyed") then return end
    rawset(self, "_destroyed", true)
    local d = P(self).Destroying
    if d then d:Fire() end
    for _, c in ipairs(self:GetChildren()) do c:Destroy() end
    self.Parent = nil
end

function Instance:ClearAllChildren()
    for _, c in ipairs(self:GetChildren()) do c:Destroy() end
end

-- [patch 4] deep clone: class defaults re-applied (fresh signals), children cloned,
-- references between cloned instances remapped, Parent left nil like the real thing
local function cloneTree(src, map)
    local sp = P(src)
    local copy = M.new(sp.ClassName, sp.Name)
    local dp = P(copy)
    for k, v in pairs(sp) do
        if k ~= "Parent" and k ~= "ClassName" then
            if isSignal(v) then dp[k] = newSignal() else dp[k] = v end
        end
    end
    for k, v in pairs(rawget(src, "_attrs")) do rawget(copy, "_attrs")[k] = v end
    map[src] = copy
    for _, c in ipairs(rawget(src, "_children")) do
        local cc = cloneTree(c, map)
        cc.Parent = copy
    end
    return copy
end

function Instance:Clone()
    local map = {}
    local root = cloneTree(self, map)
    for _, copy in pairs(map) do
        local dp = P(copy)
        for k, v in pairs(dp) do
            if type(v) == "table" and map[v] then dp[k] = map[v] end
        end
    end
    return root
end

function Instance:GetFullName()
    local parts = {self.Name}
    local p = self.Parent
    while p do
        table.insert(parts, 1, p.Name)
        p = p.Parent
    end
    return table.concat(parts, ".")
end

function Instance:GetPropertyChangedSignal(name)
    local ps = rawget(self, "_propSignals")
    if not ps[name] then ps[name] = newSignal() end
    return ps[name]
end

function Instance:SetAttribute(name, value) rawget(self, "_attrs")[name] = value end
function Instance:GetAttribute(name) return rawget(self, "_attrs")[name] end
function Instance:GetAttributes()
    local out = {}
    for k, v in pairs(rawget(self, "_attrs")) do out[k] = v end
    return out
end

-- Class-specific defaults: attach signals/props that real classes have
local classDefaults = {
    RemoteEvent = function(inst)
        inst._props.OnServerEvent = newSignal()
        inst._props.OnClientEvent = newSignal()
        inst.FireServer = function(self, ...) self.OnServerEvent:Fire(...) end
        inst.FireClient = function(self, plr, ...) self.OnClientEvent:Fire(...) end
    end,
    RemoteFunction = function(inst)
        inst._props.OnServerInvoke = nil
        inst._props.OnClientInvoke = nil
        inst.InvokeServer = function(self, ...)
            if self.OnServerInvoke then return self.OnServerInvoke(...) end
        end
        inst.InvokeClient = function(self, plr, ...)
            if self.OnClientInvoke then return self.OnClientInvoke(...) end
        end
    end,
    BindableEvent = function(inst)
        inst._props.Event = newSignal()
        inst.Fire = function(self, ...) self.Event:Fire(...) end
    end,
    BindableFunction = function(inst)
        inst._props.OnInvoke = nil
        inst.Invoke = function(self, ...)
            if self.OnInvoke then return self.OnInvoke(...) end
        end
    end,
    Humanoid = function(inst)
        inst._props.Health = 100
        inst._props.MaxHealth = 100
        inst._props.WalkSpeed = 16
        inst._props.JumpPower = 50
        inst._props.HealthChanged = newSignal()
        inst._props.Died = newSignal()
        inst._props.StateChanged = newSignal()
        inst._props.Running = newSignal()
        inst._props.Jumping = newSignal()
        inst.GetState = function(self) return self._props.HState end
        inst.ChangeState = function(self, s) self._props.HState = s; self.StateChanged:Fire(s) end
        inst.MoveTo = function(self, pos) return true end
        -- Health assignment now fires HealthChanged / Died itself (see __newindex)
        inst.TakeDamage = function(self, amt)
            self.Health = self.Health - amt
        end
    end,
    Part = function(inst)
        inst._props.Anchored = false
        inst._props.CanCollide = true
        inst._props.Transparency = 0
        inst._props.Touched = newSignal()
        inst._props.TouchEnded = newSignal()
        if DT then
            inst._props.Size = DT.Vector3.new(4, 1, 2)
            inst._props.CFrame = DT.CFrame.new(0, 0, 0)
            inst._props.Position = DT.Vector3.new(0, 0, 0)
        else
            inst._props.Size = nil
        end
    end,
    Model = function(inst)
        inst.GetPrimaryPartCFrame = function(self)
            return self.PrimaryPart and self.PrimaryPart.CFrame
        end
        inst.SetPrimaryPartCFrame = function(self, cf) end
    end,
    -- GUI classes: heavy real-world usage (Frame/TextLabel/etc dominate CoreScripts)
    GuiObject = function(inst)
        inst._props.Visible = true
        inst._props.Active = true
        inst._props.BackgroundTransparency = 0
        inst._props.ZIndex = 1
        inst._props.InputBegan = newSignal()
        inst._props.InputEnded = newSignal()
        inst._props.MouseEnter = newSignal()
        inst._props.MouseLeave = newSignal()
    end,
    ScreenGui = function(inst)
        inst._props.Enabled = true
        inst._props.DisplayOrder = 0
    end,
    TextLabel = function(inst)
        inst._props.Text = ""
        inst._props.TextColor3 = nil
        inst._props.Visible = true
        inst._props.BackgroundTransparency = 0
    end,
    TextButton = function(inst)
        inst._props.Text = ""
        inst._props.Visible = true
        inst._props.MouseButton1Click = newSignal()
        inst._props.Activated = newSignal()
    end,
    ImageButton = function(inst)
        inst._props.Image = ""
        inst._props.MouseButton1Click = newSignal()
        inst._props.Activated = newSignal()
    end,
    ImageLabel = function(inst)
        inst._props.Image = ""
        inst._props.Visible = true
    end,
    ScrollingFrame = function(inst)
        inst._props.CanvasSize = nil
        inst._props.CanvasPosition = nil
        inst._props.ScrollingEnabled = true
    end,
    -- ValueBase objects: BoolValue/IntValue/StringValue/Vector3Value etc.
    BoolValue = function(inst)
        inst._props.Value = false
        inst._props.Changed = newSignal()
    end,
    IntValue = function(inst)
        inst._props.Value = 0
        inst._props.Changed = newSignal()
    end,
    NumberValue = function(inst)
        inst._props.Value = 0
        inst._props.Changed = newSignal()
    end,
    StringValue = function(inst)
        inst._props.Value = ""
        inst._props.Changed = newSignal()
    end,
    Vector3Value = function(inst)
        inst._props.Value = nil
        inst._props.Changed = newSignal()
    end,
    ObjectValue = function(inst)
        inst._props.Value = nil
        inst._props.Changed = newSignal()
    end,
    Sound = function(inst)
        inst._props.SoundId = ""
        inst._props.Volume = 0.5
        inst._props.Playing = false
        inst._props.TimePosition = 0
        inst._props.Ended = newSignal()
        inst._props.Stopped = newSignal()
        inst.Play = function(self) self.Playing = true end
        inst.Stop = function(self) self.Playing = false; self.Stopped:Fire() end
        inst.Pause = function(self) self.Playing = false end
    end,
    Folder = function(inst) end,
    ModuleScript = function(inst) end,
}

local GUI_CLASSES = {
    Frame = true, TextLabel = true, TextButton = true, TextBox = true,
    ImageLabel = true, ImageButton = true, ScrollingFrame = true,
    ScreenGui = true, BillboardGui = true, SurfaceGui = true,
}

M.Instance = Instance
M.new = function(className, parentOrName, maybeParent)
    -- Supports both Instance.new(class, parent) and Instance.new(class, name, parent)
    local name, parent
    if type(parentOrName) == "string" then
        name, parent = parentOrName, maybeParent
    else
        name, parent = nil, parentOrName
    end
    local inst = newInstance(className, name)
    if GUI_CLASSES[className] or classIsA(className, "GuiObject") then
        classDefaults.GuiObject(inst)
    end
    local setup = classDefaults[className]
    if not setup and classIsA(className, "BasePart") then setup = classDefaults.Part end
    if setup then setup(inst) end
    if parent then inst.Parent = parent end
    return inst
end

------------------------------------------------------------
-- game / workspace: pre-built service tree
------------------------------------------------------------
local SERVICE_CLASSES = {
    Workspace = "Workspace",
    Players = "Players",
    ReplicatedStorage = "ReplicatedStorage",
    ReplicatedFirst = "ReplicatedFirst",
    ServerStorage = "ServerStorage",
    ServerScriptService = "ServerScriptService",
    StarterGui = "StarterGui",
    StarterPack = "StarterPack",
    StarterPlayer = "StarterPlayer",
    Lighting = "Lighting",
    TweenService = "TweenService",
    RunService = "RunService",
    UserInputService = "UserInputService",
    ContextActionService = "ContextActionService",
    GuiService = "GuiService",
    HttpService = "HttpService",
    Debris = "Debris",
    Chat = "Chat",
    CoreGui = "CoreGui",
    CorePackages = "CorePackages",
    VRService = "VRService",
    TextService = "TextService",
    LocalizationService = "LocalizationService",
    JointsService = "JointsService",
    ContentProvider = "ContentProvider",
    AnalyticsService = "AnalyticsService",
    PathfindingService = "PathfindingService",
    LogService = "LogService",
    InsertService = "InsertService",
    Stats = "Stats",
    SoundService = "SoundService",
    MarketplaceService = "MarketplaceService",
}

function M.buildGame()
    local game = newInstance("DataModel", "game")
    local services = {}
    for name, className in pairs(SERVICE_CLASSES) do
        local svc = newInstance(className, name)
        svc.Parent = game
        services[name] = svc
    end

    game.GetService = function(self, name)
        local svc = services[name]
        if not svc then
            -- auto-create unknown services so scripts don't hard-error
            svc = newInstance(name, name)
            svc.Parent = self
            services[name] = svc
        end
        return svc
    end

    -- RunService niceties commonly used
    services.RunService.Heartbeat = newSignal()
    services.RunService.RenderStepped = newSignal()
    services.RunService.Stepped = newSignal()
    services.RunService.IsServer = function() return true end
    services.RunService.IsClient = function() return false end
    services.RunService.IsStudio = function() return true end

    -- UserInputService: 2nd most-used service in real CoreScripts, after Players
    services.UserInputService.InputBegan = newSignal()
    services.UserInputService.InputEnded = newSignal()
    services.UserInputService.InputChanged = newSignal()
    services.UserInputService.WindowFocused = newSignal()
    services.UserInputService.WindowFocusReleased = newSignal()
    services.UserInputService.TouchStarted = newSignal()
    services.UserInputService.TouchEnded = newSignal()
    services.UserInputService.KeyboardEnabled = true
    services.UserInputService.MouseEnabled = true
    services.UserInputService.TouchEnabled = false
    services.UserInputService.GamepadEnabled = false
    services.UserInputService.IsKeyDown = function(self, keycode) return false end
    services.UserInputService.GetMouseLocation = function(self) return {X = 0, Y = 0} end

    -- ContextActionService: heavily used for bind action patterns
    services.ContextActionService.BoundActions = {}
    services.ContextActionService.BindAction = function(self, name, fn, touchButton, ...)
        self.BoundActions[name] = fn
    end
    services.ContextActionService.UnbindAction = function(self, name)
        self.BoundActions[name] = nil
    end

    -- Players.LocalPlayer: almost every LocalScript references this immediately
    local localPlayer = newInstance("Player", "LocalPlayer")
    localPlayer._props.UserId = 1
    localPlayer._props.CharacterAdded = newSignal()
    localPlayer._props.CharacterRemoving = newSignal()
    localPlayer.Parent = services.Players
    services.Players.LocalPlayer = localPlayer
    services.Players.PlayerAdded = newSignal()
    services.Players.PlayerRemoving = newSignal()
    services.Players.GetPlayers = function(self) return self:GetChildren() end

    -- TweenService: minimal, no real interpolation, just fires Completed immediately
    services.TweenService.Create = function(self, instance, tweenInfo, goals)
        local tween = newInstance("Tween", "Tween")
        tween._props.Completed = newSignal()
        tween.Play = function(t)
            for k, v in pairs(goals) do instance[k] = v end
            local E = (DT and DT.Enum) or Enum
            t.Completed:Fire(E and E.PlaybackState and E.PlaybackState.Completed or "Completed")
        end
        tween.Cancel = function(t) end
        return tween
    end

    -- ContentProvider
    services.ContentProvider.PreloadAsync = function(self, list, callback) end

    -- workspace niceties
    services.Workspace.CurrentCamera = newInstance("Camera", "Camera")
    services.Workspace.CurrentCamera.Parent = services.Workspace

    -- HttpService niceties
    local json = nil
    services.HttpService.JSONEncode = function(self, val)
        -- extremely small encoder; extend as needed
        return tostring(val)
    end
    services.HttpService.GenerateGUID = function(self, wrapInCurlyBraces)
        local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
        local s = template:gsub("[xy]", function(c)
            local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
            return string.format("%x", v)
        end)
        if wrapInCurlyBraces == false then return s end
        return "{" .. s .. "}"
    end

    return game, services
end

return M
