if not getgenv then
	local _fakeGenv = getfenv(0)
	getfenv().getgenv = function()
		return _fakeGenv
	end
end
local genv = getgenv()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenSvc = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local VIM = game:GetService("VirtualInputManager")
local TeleportSvc = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
genv.clonefunction = function(func)
	assert(type(func) == "function", "clonefunction: expected function")
	return function(...)
		return func(...)
	end
end
genv.iscclosure = function(func)
	if type(func) ~= "function" then
		return false
	end
	local ok, info = pcall(debug.info, func, "s")
	return ok and info == "[C]"
end
genv.islclosure = function(func)
	if type(func) ~= "function" then
		return false
	end
	return not genv.iscclosure(func)
end
if not genv.newcclosure then
	genv.newcclosure = function(f)
		assert(type(f) == "function", "newcclosure: expected function")
		return function(...)
			return f(...)
		end
	end
end
genv.cloneref = function(obj)
	if typeof(obj) ~= "Instance" then
		return obj
	end
	local ok, clone = pcall(function()
		return obj:Clone()
	end)
	return (ok and clone) or obj
end
genv.gethui = function()
	return CoreGui
end
genv.getscripts = function()
	local scripts = {}
	for _, v in pairs(game:GetDescendants()) do
		if v:IsA("ModuleScript") or v:IsA("LocalScript") or v:IsA("Script") then
			table.insert(scripts, v)
		end
	end
	return scripts
end
genv.getnilinstances = function()
	local result = {}
	if not getreg then
		return result
	end
	for _, v in pairs(getreg()) do
		if typeof(v) == "Instance" and v.Parent == nil then
			table.insert(result, v)
		end
	end
	return result
end
genv.getcallingscript = function()
	local src = debug.info(2, "s")
	for _, v in pairs(game:GetDescendants()) do
		if v:GetFullName() == src then
			return v
		end
	end
	return nil
end
genv.isreadonly = function(instance, property)
	return not pcall(function()
		instance[property] = instance[property]
	end)
end
if not genv.hookfunction then
	genv.hookfunction = function(func, replacement)
		assert(type(func) == "function", "hookfunction: arg #1 must be a function")
		assert(type(replacement) == "function", "hookfunction: arg #2 must be a function")
		local env = getfenv()
		local oldRef = nil
		for k, v in pairs(env) do
			if v == func then
				oldRef = v
				local ok = pcall(rawset, env, k, replacement)
				if not ok then
					pcall(function()
						env[k] = replacement
					end)
				end
			end
		end
		return oldRef
	end
end
if not genv.hookmetamethod then
	local _setro
	if type(setreadonly) == "function" then
		_setro = setreadonly
	elseif type(make_writeable) == "function" and type(make_readonly) == "function" then
		_setro = function(t, writable)
			if writable == false then
				make_writeable(t)
			else
				make_readonly(t)
			end
		end
	end
	genv.hookmetamethod = function(obj, method, func)
		local mt = getrawmetatable(obj)
		assert(mt, "hookmetamethod: object has no metatable")
		if _setro then
			pcall(_setro, mt, false)
		end
		local old = rawget(mt, method)
		rawset(mt, method, func)
		if _setro then
			pcall(_setro, mt, true)
		end
		return old
	end
end
local _namecallMethod = ""
if not genv.getnamecallmethod then
	genv.getnamecallmethod = function()
		return _namecallMethod
	end
end
if not genv.setnamecallmethod then
	genv.setnamecallmethod = function(m)
		_namecallMethod = m
	end
end
genv.protect_gui = function(guiElement)
	if typeof(guiElement) ~= "Instance" then
		return
	end
	local old_index = rawget(getrawmetatable(game), "__index")
	genv.hookmetamethod(
		game,
		"__index",
		genv.newcclosure(function(t, k)
			if t == guiElement and k == "Parent" then
				return nil
			end
			return old_index(t, k)
		end)
	)
	guiElement.Parent = genv.gethui()
end
if getgc then
	local _realGetGC = getgc
	genv.getgc = function(includeTables)
		local raw = _realGetGC(includeTables)
		local filtered = {}
		for _, v in pairs(raw) do
			local skip = false
			if type(v) == "function" then
				local ok, src = pcall(debug.info, v, "s")
				if ok and (src:match("FUnctions") or src == "=[C]") then
					skip = true
				end
			end
			if not skip then
				table.insert(filtered, v)
			end
		end
		return filtered
	end
end
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local _cryptShadow = {}
_cryptShadow.base64encode = function(data)
	assert(type(data) == "string", "base64encode: expected string")
	local result = {}
	local padding = (3 - #data % 3) % 3
	data = data .. string.rep("\0", padding)
	for i = 1, #data, 3 do
		local b1, b2, b3 = data:byte(i, i + 2)
		local n = b1 * 65536 + b2 * 256 + b3
		result[#result + 1] = B64_CHARS:sub(math.floor(n / 262144) % 64 + 1, math.floor(n / 262144) % 64 + 1)
		result[#result + 1] = B64_CHARS:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1)
		result[#result + 1] = B64_CHARS:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1)
		result[#result + 1] = B64_CHARS:sub(n % 64 + 1, n % 64 + 1)
	end
	local encoded = table.concat(result)
	if padding > 0 then
		encoded = encoded:sub(1, #encoded - padding) .. string.rep("=", padding)
	end
	return encoded
end
_cryptShadow.base64decode = function(data)
	assert(type(data) == "string", "base64decode: expected string")
	data = data:gsub("[^" .. B64_CHARS .. "=]", "")
	local lookup = {}
	for i = 1, #B64_CHARS do
		lookup[B64_CHARS:sub(i, i)] = i - 1
	end
	local result = {}
	for i = 1, #data, 4 do
		local c1 = lookup[data:sub(i, i)] or 0
		local c2 = lookup[data:sub(i + 1, i + 1)] or 0
		local c3 = lookup[data:sub(i + 2, i + 2)] or 0
		local c4 = lookup[data:sub(i + 3, i + 3)] or 0
		local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
		result[#result + 1] = string.char(math.floor(n / 65536) % 256)
		if data:sub(i + 2, i + 2) ~= "=" then
			result[#result + 1] = string.char(math.floor(n / 256) % 256)
		end
		if data:sub(i + 3, i + 3) ~= "=" then
			result[#result + 1] = string.char(n % 256)
		end
	end
	return table.concat(result)
end
_cryptShadow.generatekey = function(size)
	size = size or 32
	assert(type(size) == "number", "generatekey: arg #1 must be a number")
	local raw = {}
	for _ = 1, size do
		raw[#raw + 1] = string.char(math.random(0, 255))
	end
	return _cryptShadow.base64encode(table.concat(raw))
end
_cryptShadow.generatebytes = _cryptShadow.generatekey
do
	local native = genv.crypt
	if not native then
		genv.crypt = _cryptShadow
	else
		local proxy = setmetatable({}, { __index = native })
		for k, v in pairs(_cryptShadow) do
			if rawget(native, k) == nil then
				rawset(proxy, k, v)
			end
		end
		genv.crypt = proxy
	end
end
local crypt = genv.crypt
if not genv.debugg then
	genv.debugg = {}
end
local debugShim = genv.debugg
debugShim.getinfo = function(funcOrLevel)
	local okLine, currentLine = pcall(debug.info, funcOrLevel, "l")
	local _, source = pcall(debug.info, funcOrLevel, "s")
	local _, name = pcall(debug.info, funcOrLevel, "n")
	local _, numparams = pcall(debug.info, funcOrLevel, "a")
	local _, _np, isvararg = pcall(debug.info, funcOrLevel, "a")
	name = (type(name) == "string" and #name > 0) and name or nil
	source = (type(source) == "string") and source or ""
	return {
		currentline = okLine and tonumber(currentLine) or -1,
		source = source,
		name = name and tostring(name) or nil,
		numparams = tonumber(numparams) or 0,
		is_vararg = isvararg and 1 or 0,
		short_src = source:sub(1, 60),
	}
end
local _isWindowFocused = true
UIS.WindowFocused:Connect(function()
	_isWindowFocused = true
end)
UIS.WindowFocusReleased:Connect(function()
	_isWindowFocused = false
end)
genv.isrbxactive = function()
	return _isWindowFocused
end
genv.isgameactive = genv.isrbxactive
genv.identifyexecutor = function()
	if type(identifyexecutor) == "function" then
		return identifyexecutor()
	end
	if type(getexecutorname) == "function" then
		return getexecutorname()
	end
	return "Synapse", "0.0.0"
end
if not genv.VirtualDisk then
	genv.VirtualDisk = {}
end
local VFS = genv.VirtualDisk
genv.writefile = function(path, content)
	assert(type(path) == "string", "writefile: path must be a string")
	VFS[path] = tostring(content)
end
genv.readfile = function(path)
	assert(type(path) == "string", "readfile: path must be a string")
	if VFS[path] == nil then
		error("readfile: no such file '" .. path .. "'", 2)
	end
	return VFS[path]
end
genv.appendfile = function(path, content)
	assert(type(path) == "string", "appendfile: path must be a string")
	VFS[path] = (VFS[path] or "") .. tostring(content)
end
genv.isfile = function(path)
	return VFS[path] ~= nil
end
genv.delfile = function(path)
	VFS[path] = nil
end
genv.listfiles = function(dir)
	local files = {}
	for path in pairs(VFS) do
		if not dir or path:sub(1, #dir) == dir then
			table.insert(files, path)
		end
	end
	return files
end
genv.makefolder = function(path)
	VFS["__folder__" .. path] = true
end
genv.isfolder = function(path)
	return VFS["__folder__" .. path] == true
end
if not genv.Drawing then
	local hui = genv.gethui()
	local DrawingContainer = Instance.new("ScreenGui")
	DrawingContainer.Name = "__DrawingLib__"
	DrawingContainer.ZIndexBehavior = Enum.ZIndexBehavior.Global
	DrawingContainer.ResetOnSpawn = false
	DrawingContainer.Parent = hui
	local function alphaToTransparency(a)
		return 1 - math.clamp(a, 0, 1)
	end
	local function dragify(frame)
		local dragging, dragInput, dragStart, startPos
		frame.InputBegan:Connect(function(input)
			if
				(
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				) and UIS:GetFocusedTextBox() == nil
			then
				dragging = true
				dragStart = input.Position
				startPos = frame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)
		frame.InputChanged:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragInput = input
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if input == dragInput and dragging then
				local delta = input.Position - dragStart
				TweenSvc:Create(frame, TweenInfo.new(0.1), {
					Position = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					),
				}):Play()
			end
		end)
	end
	local function makeDrawingMeta(props, typeStr)
		return setmetatable({}, {
			__index = function(_, k)
				return props[k]
			end,
			__newindex = function(_, k, v)
				if props[k] ~= nil then
					props[k] = v
				end
			end,
			__tostring = function()
				return "Drawing(" .. typeStr .. ")"
			end,
		})
	end
	local DrawingLib = {}
	DrawingLib.__index = DrawingLib
	DrawingLib.new = function(objType)
		if objType == "Line" then
			local frame = Instance.new("Frame")
			frame.Name = "Drawing_Line"
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.BorderSizePixel = 0
			frame.Parent = DrawingContainer
			local props = {
				Visible = false,
				Color = Color3.new(1, 1, 1),
				Transparency = 1,
				Thickness = 1,
				From = Vector2.zero,
				To = Vector2.zero,
				ZIndex = 1,
			}
			local conn
			conn = RunService.RenderStepped:Connect(function()
				if not frame.Parent then
					conn:Disconnect()
					return
				end
				frame.Visible = props.Visible
				frame.BackgroundColor3 = props.Color
				frame.BackgroundTransparency = alphaToTransparency(props.Transparency)
				frame.ZIndex = props.ZIndex
				local mag = (props.To - props.From).Magnitude
				local center = (props.To + props.From) / 2
				local angle = math.atan2(props.To.Y - props.From.Y, props.To.X - props.From.X)
				frame.Size = UDim2.new(0, mag, 0, props.Thickness)
				frame.Position = UDim2.new(0, center.X, 0, center.Y)
				frame.Rotation = math.deg(angle)
			end)
			return makeDrawingMeta(props, "Line")
		elseif objType == "Text" then
			local label = Instance.new("TextLabel")
			label.Name = "Drawing_Text"
			label.BackgroundTransparency = 1
			label.BorderSizePixel = 0
			label.RichText = false
			label.Parent = DrawingContainer
			local props = {
				Visible = false,
				Text = "",
				Color = Color3.new(1, 1, 1),
				Transparency = 1,
				Size = 14,
				Position = Vector2.zero,
				Outline = false,
				OutlineColor = Color3.new(0, 0, 0),
				Center = false,
				ZIndex = 1,
				Font = Drawing.Fonts and Drawing.Fonts.UI or Enum.Font.SourceSans,
			}
			local conn
			conn = RunService.RenderStepped:Connect(function()
				if not label.Parent then
					conn:Disconnect()
					return
				end
				label.Visible = props.Visible
				label.Text = tostring(props.Text)
				label.TextColor3 = props.Color
				label.TextTransparency = alphaToTransparency(props.Transparency)
				label.TextSize = props.Size
				label.ZIndex = props.ZIndex
				label.Font = props.Font
				label.TextXAlignment = props.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
				local ts = label.TextBounds
				label.Size = UDim2.new(0, ts.X + 2, 0, ts.Y + 2)
				label.Position = UDim2.new(0, props.Position.X - (props.Center and ts.X / 2 or 0), 0, props.Position.Y)
			end)
			return makeDrawingMeta(props, "Text")
		elseif objType == "Circle" then
			local frame = Instance.new("Frame")
			frame.Name = "Drawing_Circle"
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.BackgroundTransparency = 1
			frame.BorderSizePixel = 0
			frame.Parent = DrawingContainer
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = frame
			local stroke = Instance.new("UIStroke")
			stroke.Parent = frame
			local props = {
				Visible = false,
				Color = Color3.new(1, 1, 1),
				Transparency = 1,
				Thickness = 1,
				Radius = 10,
				Filled = false,
				Position = Vector2.zero,
				ZIndex = 1,
			}
			local conn
			conn = RunService.RenderStepped:Connect(function()
				if not frame.Parent then
					conn:Disconnect()
					return
				end
				frame.Visible = props.Visible
				frame.ZIndex = props.ZIndex
				frame.Position = UDim2.new(0, props.Position.X, 0, props.Position.Y)
				frame.Size = UDim2.new(0, props.Radius * 2, 0, props.Radius * 2)
				if props.Filled then
					frame.BackgroundColor3 = props.Color
					frame.BackgroundTransparency = alphaToTransparency(props.Transparency)
					stroke.Enabled = false
				else
					frame.BackgroundTransparency = 1
					stroke.Enabled = true
					stroke.Color = props.Color
					stroke.Thickness = props.Thickness
					stroke.Transparency = alphaToTransparency(props.Transparency)
				end
			end)
			return makeDrawingMeta(props, "Circle")
		elseif objType == "Square" then
			local frame = Instance.new("Frame")
			frame.Name = "Drawing_Square"
			frame.BorderSizePixel = 0
			frame.BackgroundTransparency = 1
			frame.Parent = DrawingContainer
			local stroke = Instance.new("UIStroke")
			stroke.Parent = frame
			local props = {
				Visible = false,
				Color = Color3.new(1, 1, 1),
				Transparency = 1,
				Thickness = 1,
				Size = Vector2.new(100, 100),
				Position = Vector2.zero,
				Filled = false,
				ZIndex = 1,
			}
			local conn
			conn = RunService.RenderStepped:Connect(function()
				if not frame.Parent then
					conn:Disconnect()
					return
				end
				frame.Visible = props.Visible
				frame.ZIndex = props.ZIndex
				frame.Position = UDim2.new(0, props.Position.X, 0, props.Position.Y)
				frame.Size = UDim2.new(0, props.Size.X, 0, props.Size.Y)
				if props.Filled then
					frame.BackgroundColor3 = props.Color
					frame.BackgroundTransparency = alphaToTransparency(props.Transparency)
					stroke.Enabled = false
				else
					frame.BackgroundTransparency = 1
					stroke.Enabled = true
					stroke.Color = props.Color
					stroke.Thickness = props.Thickness
					stroke.Transparency = alphaToTransparency(props.Transparency)
				end
			end)
			return makeDrawingMeta(props, "Square")
		elseif objType == "Image" then
			local imageLabel = Instance.new("ImageLabel")
			imageLabel.Name = "Drawing_Image"
			imageLabel.BackgroundTransparency = 1
			imageLabel.BorderSizePixel = 0
			imageLabel.Parent = DrawingContainer
			local props = {
				Visible = false,
				Data = nil,
				DataURL = "",
				Size = Vector2.new(100, 100),
				Position = Vector2.zero,
				Transparency = 1,
				Color = Color3.new(1, 1, 1),
				ZIndex = 1,
			}
			local conn
			conn = RunService.RenderStepped:Connect(function()
				if not imageLabel.Parent then
					conn:Disconnect()
					return
				end
				imageLabel.Visible = props.Visible
				imageLabel.Image = props.DataURL
				imageLabel.ImageColor3 = props.Color
				imageLabel.ImageTransparency = alphaToTransparency(props.Transparency)
				imageLabel.Size = UDim2.new(0, props.Size.X, 0, props.Size.Y)
				imageLabel.Position = UDim2.new(0, props.Position.X, 0, props.Position.Y)
				imageLabel.ZIndex = props.ZIndex
			end)
			return makeDrawingMeta(props, "Image")
		elseif objType == "Quad" or objType == "Triangle" then
			local numLines = (objType == "Quad") and 4 or 3
			local lines = {}
			for i = 1, numLines do
				lines[i] = DrawingLib.new("Line")
			end
			local props = {
				Visible = false,
				Color = Color3.new(1, 1, 1),
				Thickness = 1,
				ZIndex = 1,
				PointA = Vector2.zero,
				PointB = Vector2.zero,
				PointC = Vector2.zero,
			}
			if objType == "Quad" then
				props.PointD = Vector2.zero
			end
			local function syncLines()
				local pts = { props.PointA, props.PointB, props.PointC }
				if objType == "Quad" then
					pts[4] = props.PointD
				end
				for i, line in ipairs(lines) do
					line.From = pts[i]
					line.To = pts[(i % numLines) + 1]
					line.Color = props.Color
					line.Thickness = props.Thickness
					line.Visible = props.Visible
					line.ZIndex = props.ZIndex
				end
			end
			return setmetatable({}, {
				__index = function(_, k)
					return props[k]
				end,
				__newindex = function(_, k, v)
					if props[k] ~= nil then
						props[k] = v
						syncLines()
					end
				end,
				__tostring = function()
					return "Drawing(" .. objType .. ")"
				end,
			})
		end
		return setmetatable({}, {
			__index = function()
				return nil
			end,
			__newindex = function() end,
			__tostring = function()
				return "Drawing(Unknown)"
			end,
		})
	end
	DrawingLib.Fonts = {
		UI = Enum.Font.SourceSans,
		System = Enum.Font.Code,
		Plex = Enum.Font.GothamMedium,
		Monospace = Enum.Font.Code,
	}
	genv.Drawing = DrawingLib
end
local function dragify(frame)
	local dragging, dragInput, dragStart, startPos
	frame.InputBegan:Connect(function(input)
		if
			(input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and UIS:GetFocusedTextBox() == nil
		then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	frame.InputChanged:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			TweenSvc:Create(frame, TweenInfo.new(0.1), {
				Position = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				),
			}):Play()
		end
	end)
end
local function buildMessageBox(title, text, buttons)
	local hui = genv.gethui()
	local sg = Instance.new("ScreenGui")
	sg.Name = "zuk_messagebox"
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.ResetOnSpawn = false
	sg.Parent = hui
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(0.5, -130, 0.5, -85)
	frame.Size = UDim2.new(0, 260, 0, 170)
	frame.Parent = sg
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	local titleBar = Instance.new("Frame")
	titleBar.BackgroundColor3 = Color3.fromRGB(44, 44, 46)
	titleBar.BorderSizePixel = 0
	titleBar.Size = UDim2.new(1, 0, 0, 36)
	titleBar.Parent = frame
	local tbCorner = Instance.new("UICorner")
	tbCorner.CornerRadius = UDim.new(0, 6)
	tbCorner.Parent = titleBar
	local patch = Instance.new("Frame")
	patch.BackgroundColor3 = Color3.fromRGB(44, 44, 46)
	patch.BorderSizePixel = 0
	patch.Position = UDim2.new(0, 0, 0.5, 0)
	patch.Size = UDim2.new(1, 0, 0.5, 0)
	patch.Parent = titleBar
	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.new(1, -36, 1, 0)
	titleLabel.Position = UDim2.new(0, 12, 0, 0)
	titleLabel.Text = tostring(title)
	titleLabel.TextColor3 = Color3.fromRGB(235, 235, 245)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 13
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar
	local closeBtn = Instance.new("TextButton")
	closeBtn.BackgroundTransparency = 1
	closeBtn.Position = UDim2.new(1, -34, 0, 2)
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Parent = titleBar
	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
	body.Position = UDim2.new(0, 12, 0, 44)
	body.Size = UDim2.new(1, -24, 0, 80)
	body.Text = tostring(text)
	body.TextColor3 = Color3.fromRGB(200, 200, 210)
	body.Font = Enum.Font.SourceSans
	body.TextSize = 14
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.Parent = frame
	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	sep.BorderSizePixel = 0
	sep.Position = UDim2.new(0, 0, 0, 130)
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.Parent = frame
	local BTN_W = 70
	local SPACING = 10
	local totalW = #buttons * BTN_W + (#buttons - 1) * SPACING
	local startX = (260 - totalW) / 2
	local result = nil
	for i, def in ipairs(buttons) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		btn.BorderSizePixel = 0
		btn.Position = UDim2.new(0, startX + (i - 1) * (BTN_W + SPACING), 0, 136)
		btn.Size = UDim2.new(0, BTN_W, 0, 26)
		btn.Text = def.text
		btn.TextColor3 = Color3.fromRGB(235, 235, 245)
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 13
		btn.Parent = frame
		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 4)
		btnCorner.Parent = btn
		btn.MouseButton1Click:Connect(function()
			result = def.returnVal
			sg:Destroy()
		end)
	end
	closeBtn.MouseButton1Click:Connect(function()
		sg:Destroy()
	end)
	dragify(frame)
	repeat
		task.wait()
	until result ~= nil or not sg.Parent
	return result or 0
end
local MSGBOX_LAYOUTS = {
	[0] = { { text = "OK", returnVal = 1 } },
	[1] = { { text = "OK", returnVal = 1 }, { text = "Cancel", returnVal = 2 } },
	[2] = {
		{ text = "Abort", returnVal = 1 },
		{ text = "Retry", returnVal = 2 },
		{ text = "Ignore", returnVal = 3 },
	},
	[3] = {
		{ text = "Yes", returnVal = 1 },
		{ text = "No", returnVal = 2 },
		{ text = "Cancel", returnVal = 3 },
	},
	[4] = { { text = "Yes", returnVal = 1 }, { text = "No", returnVal = 2 } },
	[5] = { { text = "Retry", returnVal = 1 }, { text = "Cancel", returnVal = 2 } },
	[6] = {
		{ text = "Cancel", returnVal = 1 },
		{ text = "Try Again", returnVal = 2 },
		{ text = "Continue", returnVal = 3 },
	},
}
genv.messagebox = function(text, caption, style, callback)
	local layout = MSGBOX_LAYOUTS[style] or MSGBOX_LAYOUTS[0]
	local result = buildMessageBox(caption or "Message", text or "", layout)
	if type(callback) == "function" then
		callback(result)
	end
	return result
end
local rconsoleGui = nil
local rconsoleLines = {}
local rconsoleScroll = nil
local function ensureRconsole()
	if rconsoleGui and rconsoleGui.Parent then
		return
	end
	rconsoleLines = {}
	local hui = genv.gethui()
	rconsoleGui = Instance.new("ScreenGui")
	rconsoleGui.Name = "__rconsole__"
	rconsoleGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	rconsoleGui.ResetOnSpawn = false
	rconsoleGui.Parent = hui
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(0.2, 0, 0.2, 0)
	frame.Size = UDim2.new(0, 700, 0, 300)
	frame.Parent = rconsoleGui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = frame
	local bar = Instance.new("Frame")
	bar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	bar.BorderSizePixel = 0
	bar.Size = UDim2.new(1, 0, 0, 32)
	bar.Parent = frame
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 6)
	barCorner.Parent = bar
	local barPatch = Instance.new("Frame")
	barPatch.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	barPatch.BorderSizePixel = 0
	barPatch.Position = UDim2.new(0, 0, 0.5, 0)
	barPatch.Size = UDim2.new(1, 0, 0.5, 0)
	barPatch.Parent = bar
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "ConsoleTitle"
	titleLbl.BackgroundTransparency = 1
	titleLbl.Position = UDim2.new(0, 10, 0, 0)
	titleLbl.Size = UDim2.new(1, -50, 1, 0)
	titleLbl.Text = "Console"
	titleLbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	titleLbl.Font = Enum.Font.Code
	titleLbl.TextSize = 14
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = bar
	local closeBtn = Instance.new("TextButton")
	closeBtn.BackgroundTransparency = 1
	closeBtn.Position = UDim2.new(1, -30, 0, 0)
	closeBtn.Size = UDim2.new(0, 30, 1, 0)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 14
	closeBtn.Parent = bar
	closeBtn.MouseButton1Click:Connect(function()
		rconsoleGui:Destroy()
		rconsoleGui = nil
	end)
	local minBtn = Instance.new("TextButton")
	minBtn.BackgroundTransparency = 1
	minBtn.Position = UDim2.new(1, -60, 0, 0)
	minBtn.Size = UDim2.new(0, 30, 1, 0)
	minBtn.Text = "–"
	minBtn.TextColor3 = Color3.fromRGB(200, 200, 100)
	minBtn.Font = Enum.Font.GothamBold
	minBtn.TextSize = 14
	minBtn.Parent = bar
	minBtn.MouseButton1Click:Connect(function()
		frame.Visible = not frame.Visible
	end)
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.Position = UDim2.new(0, 0, 0, 32)
	scrollFrame.Size = UDim2.new(1, 0, 1, -32)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.ScrollBarThickness = 4
	scrollFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollFrame.Parent = frame
	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 0)
	listLayout.Parent = scrollFrame
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local h = listLayout.AbsoluteContentSize.Y
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, h)
		scrollFrame.CanvasPosition = Vector2.new(0, h)
	end)
	rconsoleScroll = scrollFrame
	dragify(frame)
end
local function rconsoleAppendLine(text, color)
	ensureRconsole()
	if not rconsoleScroll or not rconsoleScroll.Parent then
		return
	end
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -10, 0, 18)
	lbl.Text = tostring(text)
	lbl.TextColor3 = color or Color3.fromRGB(200, 200, 200)
	lbl.Font = Enum.Font.Code
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextWrapped = true
	lbl.Parent = rconsoleScroll
	table.insert(rconsoleLines, lbl)
end
genv.rconsolecreate = function(title)
	ensureRconsole()
	local titleLbl = rconsoleScroll
		and rconsoleScroll.Parent
		and rconsoleScroll.Parent.Parent:FindFirstChild("ConsoleTitle", true)
	if titleLbl then
		titleLbl.Text = title or "Console"
	end
end
genv.rconsoleprint = function(text, color)
	rconsoleAppendLine(text, color)
end
genv.rconsolename = function(_)
	ensureRconsole()
end
genv.rconsoleclear = function()
	if not rconsoleScroll then
		return
	end
	for _, lbl in pairs(rconsoleLines) do
		lbl:Destroy()
	end
	rconsoleLines = {}
end
genv.rconsoledestroy = function()
	if rconsoleGui then
		rconsoleGui:Destroy()
		rconsoleGui = nil
		rconsoleLines = {}
	end
end
genv.rconsoleinput = function()
	return ""
end
local NOTIFY_DURATION_DEFAULT = 4
genv.notify = function(title, text, duration)
	local hui = genv.gethui()
	local sg = Instance.new("ScreenGui")
	sg.Name = "__notify__"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
	sg.Parent = hui
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(0, 255, 0, 75)
	frame.Parent = sg
	local fCorner = Instance.new("UICorner")
	fCorner.CornerRadius = UDim.new(0, 6)
	fCorner.Parent = frame
	local accent = Instance.new("Frame")
	accent.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
	accent.BorderSizePixel = 0
	accent.Size = UDim2.new(0, 3, 1, 0)
	accent.Parent = frame
	local aCorner = Instance.new("UICorner")
	aCorner.CornerRadius = UDim.new(0, 3)
	aCorner.Parent = accent
	local titleLbl = Instance.new("TextLabel")
	titleLbl.BackgroundTransparency = 1
	titleLbl.Position = UDim2.new(0, 12, 0, 6)
	titleLbl.Size = UDim2.new(1, -16, 0, 24)
	titleLbl.Text = tostring(title)
	titleLbl.TextColor3 = Color3.fromRGB(235, 235, 245)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 13
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = frame
	local bodyLbl = Instance.new("TextLabel")
	bodyLbl.BackgroundTransparency = 1
	bodyLbl.Position = UDim2.new(0, 12, 0, 30)
	bodyLbl.Size = UDim2.new(1, -16, 0, 36)
	bodyLbl.Text = tostring(text)
	bodyLbl.TextColor3 = Color3.fromRGB(175, 175, 185)
	bodyLbl.Font = Enum.Font.SourceSans
	bodyLbl.TextSize = 13
	bodyLbl.TextWrapped = true
	bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
	bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
	bodyLbl.Parent = frame
	local posShown = UDim2.new(1, -270, 1, -100)
	local posHidden = UDim2.new(1, 10, 1, -100)
	frame.Position = posHidden
	TweenSvc:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = posShown,
	}):Play()
	task.delay(duration or NOTIFY_DURATION_DEFAULT, function()
		if not sg.Parent then
			return
		end
		TweenSvc:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
			Position = posHidden,
		}):Play()
		task.wait(0.35)
		sg:Destroy()
	end)
end
genv.mouse1click = function(x, y)
	VIM:SendMouseButtonEvent(x or 0, y or 0, 0, true, game, false)
	task.wait()
	VIM:SendMouseButtonEvent(x or 0, y or 0, 0, false, game, false)
end
genv.mouse2click = function(x, y)
	VIM:SendMouseButtonEvent(x or 0, y or 0, 1, true, game, false)
	task.wait()
	VIM:SendMouseButtonEvent(x or 0, y or 0, 1, false, game, false)
end
genv.mouse1press = function(x, y)
	VIM:SendMouseButtonEvent(x or 0, y or 0, 0, true, game, false)
end
genv.mouse1release = function(x, y)
	VIM:SendMouseButtonEvent(x or 0, y or 0, 0, false, game, false)
end
genv.mouse2press = function(x, y)
	VIM:SendMouseButtonEvent(x or 0, y or 0, 1, true, game, false)
end
genv.mouse2release = function(x, y)
	VIM:SendMouseButtonEvent(x or 0, y or 0, 1, false, game, false)
end
genv.mousescroll = function(x, y, up)
	VIM:SendMouseWheelEvent(x or 0, y or 0, up == true, game)
end
genv.keypress = function(keyCode)
	VIM:SendKeyEvent(true, keyCode, false, game)
end
genv.keyrelease = function(keyCode)
	VIM:SendKeyEvent(false, keyCode, false, game)
end
genv.getplayer = function(nameOrObj)
	if nameOrObj == nil then
		return LocalPlayer
	end
	if typeof(nameOrObj) == "Instance" then
		return nameOrObj
	end
	assert(type(nameOrObj) == "string", "getplayer: expected string or nil")
	for _, plr in pairs(Players:GetPlayers()) do
		if plr.Name == nameOrObj or plr.DisplayName == nameOrObj then
			return plr
		end
	end
	return nil
end
genv.getlocalplayer = function()
	return LocalPlayer
end
genv.getplayers = function()
	local t = {}
	for _, plr in pairs(Players:GetPlayers()) do
		t[plr.Name] = plr
	end
	t["LocalPlayer"] = LocalPlayer
	return t
end
local function loadAndPlayAnimation(animationId, player)
	local plr = player or LocalPlayer
	local char = plr.Character
	if not char then
		return
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(animationId)
	local track = humanoid:LoadAnimation(anim)
	track:Play()
	return track
end
genv.playanimation = loadAndPlayAnimation
genv.runanimation = loadAndPlayAnimation
genv.getfps = function(suffix)
	local ok, raw = pcall(function()
		return Stats.Workspace.Heartbeat:GetValue()
	end)
	if not ok then
		return suffix and "0 fps" or "0"
	end
	local fps = tostring(math.round(tonumber(raw) or 0))
	return suffix and (fps .. " fps") or fps
end
genv.getping = function(suffix)
	local ok, raw = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
	end)
	if not ok then
		return suffix and "0 ms" or "0"
	end
	local pingNum = tonumber(raw:match("^%d+")) or 0
	local ping = tostring(math.round(pingNum))
	return suffix and (ping .. " ms") or ping
end
local PLATFORM_MAP = {
	[Enum.Platform.Windows] = "Windows",
	[Enum.Platform.OSX] = "macOS",
	[Enum.Platform.IOS] = "iOS",
	[Enum.Platform.Android] = "Android",
	[Enum.Platform.UWP] = "Windows (Microsoft Store)",
	[Enum.Platform.XBoxOne] = "Xbox One",
}
local function getPlatformString()
	return PLATFORM_MAP[UIS:GetPlatform()] or "Unknown"
end
genv.getplatform = getPlatformString
genv.getos = getPlatformString
genv.getdevice = getPlatformString
genv.getaffiliateid = function()
	return "none"
end
genv.getfpscap = function()
	if type(getfpscap) == "function" then
		return getfpscap()
	end
	return 60
end
genv.setfpscap = function(cap)
	if type(setfpscap) == "function" then
		setfpscap(cap)
	end
end
genv.join = function(placeID, jobID)
	assert(type(placeID) == "number", "join: placeID must be a number")
	if jobID then
		TeleportSvc:TeleportToPlaceInstance(placeID, jobID, LocalPlayer)
	else
		TeleportSvc:Teleport(placeID, LocalPlayer)
	end
end
if firetouchinterest then
	genv.firetouchtransmitter = firetouchinterest
elseif genv.firetouchtransmitter == nil then
	genv.firetouchtransmitter = function() end
end
genv.customprint = function(text, properties, imageId)
	print(text)
	task.wait(0.03)
	local ok, devConsole = pcall(function()
		return CoreGui.DevConsoleMaster.DevConsoleWindow.DevConsoleUI.MainView.ClientLog
	end)
	if not ok or not devConsole then
		return
	end
	local children = devConsole:GetChildren()
	local lastMsg = devConsole:FindFirstChild(tostring(#children - 1))
	if not lastMsg then
		return
	end
	local msg = lastMsg:FindFirstChild("msg")
	if msg and properties then
		for k, v in pairs(properties) do
			pcall(function()
				msg[k] = v
			end)
		end
	end
	if msg and imageId then
		local img = lastMsg:FindFirstChild("image")
		if img then
			img.Image = imageId
		end
	end
end
if getgenv().Zuka_Loaded then
	return
end
getgenv().Zuka_Loaded = true
local set_ro = setreadonly
	or (make_writeable and function(t, v)
		if v then
			make_readonly(t)
		else
			make_writeable(t)
		end
	end)
	or function() end
local get_mt = getrawmetatable or debug.getmetatable
local hook_meta = hookmetamethod
local new_cc = newcclosure or function(f)
	return f
end
local check_caller = checkcaller or function()
	return false
end
local hook_fn = hookfunction or function() end
local gc = getgc or get_gc_objects or function()
	return {}
end
local KICK_KEYWORDS = {
	"adonis",
	"anti.?cheat",
	"exploit",
	"acli",
	"detected",
	"cheat",
	"ban",
}
local ZukaStats = {
	KickAttempts = 0,
	RemotesBlocked = 0,
	DetectionsCaught = 0,
	FunctionsHooked = 0,
	ClientChecksBlocked = 0,
	RemotesFired = 0,
}
local HookedFunctions = {}
local cachedACTable = nil
local originalFunctions = {}
local isUnloaded = false
local Services = setmetatable({}, {
	__index = function(t, k)
		local ok, s = pcall(function()
			return game:GetService(k)
		end)
		if ok and s then
			rawset(t, k, s)
		end
		return s
	end,
})
local GC_CACHE_TTL = 30
local gcCache, gcCacheTime = nil, 0
local function getCachedGC()
	local now = os.clock()
	if gcCache and (now - gcCacheTime) < GC_CACHE_TTL then
		return gcCache
	end
	local ok, objs = pcall(gc, true)
	if ok and objs then
		gcCache = objs
		gcCacheTime = now
	end
	return gcCache
end
local function safe(fn, ...)
	local ok, result = pcall(fn, ...)
	return ok and result or nil
end
local function safeHook(original, replacement)
	if type(original) ~= "function" then
		return false
	end
	local ok = pcall(hook_fn, original, new_cc(replacement))
	if not ok then
		return false
	end
	table.insert(HookedFunctions, original)
	ZukaStats.FunctionsHooked += 1
	return true
end
local function dismantleReadonly(target)
	if type(target) ~= "table" then
		return
	end
	pcall(function()
		if set_ro then
			set_ro(target, false)
		end
		local mt = get_mt(target)
		if mt then
			pcall(set_ro, mt, false)
		end
	end)
end
for _, fn in ipairs({ getgenv, getrenv, getreg }) do
	if type(fn) == "function" then
		local ok, env = pcall(fn)
		if ok and type(env) == "table" then
			dismantleReadonly(env)
		end
	end
end
if not game:IsLoaded() then
	game.Loaded:Wait()
end
local BypassPlayers = Services.Players
repeat
	task.wait(0.1)
until BypassPlayers and BypassPlayers.LocalPlayer
local BypassLocalPlayer = BypassPlayers.LocalPlayer
do
	local STACK_THRESHOLD = 195
	local STACK_THRESHOLD_MAX = 198
	local ERR_CSTACK = "C stack overflow"
	local ERR_DEAD_CORO = "cannot resume dead coroutine"
	local pack = table.pack
	local unpack_ = unpack
	local info = debug.info
	local luaCacheFuncs = {}
	local StackCache = {}
	local WrapHook
	local function checkValidity(func)
		return info(func, "s") == "[C]"
	end
	local function isInCache(func)
		for _, tbl in StackCache do
			if tbl.Wrapped == func or tbl.ReplacementFunc == func then
				return tbl
			end
		end
		return nil
	end
	local function insertInCache(func, wrapped)
		if type(func) ~= "function" or type(wrapped) ~= "function" then
			return
		end
		local entry
		entry = {
			WrapCount = 1,
			Original = func,
			ReplacementFunc = function(...)
				local args = pack(pcall(WrapHook(func), ...))
				if not args[1] then
					local err = args[2]
					if err ~= ERR_DEAD_CORO and entry.WrapCount > STACK_THRESHOLD_MAX then
						task.spawn(entry.Gc)
						return getrenv().error(ERR_CSTACK, 2)
					elseif err == ERR_DEAD_CORO or select(2, pcall(WrapHook(wrapped))) == ERR_DEAD_CORO then
						task.spawn(entry.Gc)
						return getrenv().error(ERR_DEAD_CORO, 2)
					end
					task.spawn(entry.Gc)
					return getrenv().error(err, 2)
				end
				task.spawn(entry.Gc)
				return unpack_(args, 2, args.n)
			end,
			Wrapped = wrapped,
			Gc = function()
				local idx = table.find(StackCache, entry)
				if idx then
					table.remove(StackCache, idx)
				end
			end,
		}
		table.insert(StackCache, entry)
	end
	WrapHook = hook_fn(
		getrenv().coroutine.wrap,
		new_cc(function(...)
			local target = ...
			if not check_caller() and type(target) == "function" then
				local cached = isInCache(target)
				if cached then
					if not checkValidity(target) then
						local res = WrapHook(...)
						local pos = table.find(luaCacheFuncs, target)
						if pos then
							luaCacheFuncs[pos] = res
						else
							table.insert(luaCacheFuncs, res)
						end
						return res
					end
					cached.WrapCount += 1
					if cached.WrapCount == STACK_THRESHOLD then
						local nf = WrapHook(cached.ReplacementFunc)
						cached.Original, cached.ReplacementFunc = nf, nf
						cached.Wrapped = WrapHook(cached.Wrapped)
						return nf
					elseif cached.WrapCount < STACK_THRESHOLD or cached.WrapCount > STACK_THRESHOLD_MAX then
						local nf = WrapHook(cached.Wrapped)
						cached.Wrapped = nf
						return nf
					end
					local nf = WrapHook(cached.ReplacementFunc)
					cached.Original, cached.ReplacementFunc = nf, nf
					cached.Wrapped = WrapHook(WrapHook(cached.Wrapped))
					return nf
				else
					local arg = WrapHook(...)
					insertInCache(target, arg)
					return arg
				end
			end
			return WrapHook(...)
		end)
	)
	print("[Zuka] C-stack overflow bypass: active")
end
do
	local oldDebugInfo = debug.info
	local adonisCache = {}
	hook_fn(
		debug.info,
		new_cc(function(target, fmt, ...)
			if check_caller() then
				return oldDebugInfo(target, fmt, ...)
			end
			if type(target) == "function" and type(fmt) == "string" and fmt:find("f") then
				if not adonisCache[target] then
					local results = table.pack(oldDebugInfo(target, fmt, ...))
					adonisCache[target] = results
					return table.unpack(results, 1, results.n)
				else
					local c = adonisCache[target]
					return table.unpack(c, 1, c.n)
				end
			end
			return oldDebugInfo(target, fmt, ...)
		end)
	)
	print("[Zuka] debug.info tamper neutralizer: active")
end
do
	local testFn = new_cc(function() end)
	local s, l, n, a =
		debug.info(testFn, "s"), debug.info(testFn, "l"), debug.info(testFn, "n"), debug.info(testFn, "a")
	if s ~= "[C]" or l ~= -1 or n ~= "" or a ~= 0 then
		warn(
			string.format(
				"[Zuka] WARNING: newcclosure may not pass Adonis metamethod validity! source=%s line=%s name=%s args=%s",
				tostring(s),
				tostring(l),
				tostring(n),
				tostring(a)
			)
		)
	else
		print("[Zuka] newcclosure validity check: OK")
	end
end
local _require = getrenv().require
local function SanitizeCarbonModule(moduleScript)
	local success, moduleData = pcall(_require, moduleScript)
	if not success or type(moduleData) ~= "table" then
		return moduleData
	end
	for _, key in pairs({ "Security", "Verify", "Check", "AntiCheat", "ExploitCheck" }) do
		if rawget(moduleData, key) ~= nil then
			rawset(moduleData, key, function()
				return true
			end)
		end
	end
	rawset(moduleData, "Hash", nil)
	rawset(moduleData, "CheckSum", nil)
	return moduleData
end
local oldRequire
oldRequire = hook_fn(
	_require,
	new_cc(function(module)
		if check_caller() then
			return oldRequire(module)
		end
		if typeof(module) == "Instance" and module:IsA("ModuleScript") then
			if module.Name == "1" and module.Parent and module.Parent.Name == "Settings" then
				return SanitizeCarbonModule(module)
			end
			local name = module.Name:lower()
			if name:find("security") or name:find("anticheat") then
				return setmetatable({}, {
					__index = function()
						return function()
							return true
						end
					end,
				})
			end
			if name:find("topbar") or name:find("icon") or name:find("adonis") or name:find("aethetic") then
				return setmetatable({}, {
					__index = function()
						return function() end
					end,
					__newindex = function() end,
					__call = function()
						return {}
					end,
				})
			end
		end
		return oldRequire(module)
	end)
)
do
	local RS = RunService or game:GetService("RunService")
	local oldBind
	oldBind = hook_fn(
		RS.BindToRenderStep,
		new_cc(function(self, name, priority, callback)
			if not check_caller() then
				local lower = name:lower()
				if lower:find("ac") or lower:find("security") or lower:find("verify") then
					return nil
				end
			end
			return oldBind(self, name, priority, callback)
		end)
	)
end
local AC_SIGNATURES = {
	{ "Detected", true, 1 },
	{ "RemovePlayer", true, 1 },
	{ "CheckAllClients", true, 1 },
	{ "KickedPlayers", false, 1 },
	{ "SpoofCheckCache", false, 1 },
	{ "ClientTimeoutLimit", false, 1 },
	{ "CharacterCheck", true, 0.5 },
	{ "UserSpoofCheck", true, 0.5 },
	{ "AntiCheatEnabled", false, 1 },
	{ "GetPlayer", true, 0.5 },
}
local AC_SCORE_THRESHOLD = 3
local function scoreTable(v)
	if type(v) ~= "table" then
		return 0
	end
	if rawget(v, "Detected") == nil and rawget(v, "RemovePlayer") == nil then
		return 0
	end
	local score = 0
	pcall(function()
		for _, sig in ipairs(AC_SIGNATURES) do
			local name, isFunc, weight = sig[1], sig[2], sig[3]
			local val = rawget(v, name)
			if val ~= nil then
				score += (isFunc and type(val) == "function") and weight or (not isFunc) and weight or 0
			end
		end
	end)
	return score
end
local function findACTable()
	local objs = getCachedGC()
	if not objs then
		return nil
	end
	for _, v in ipairs(objs) do
		local ok, isT = pcall(function()
			return type(v) == "table"
		end)
		if ok and isT and scoreTable(v) >= AC_SCORE_THRESHOLD then
			return v
		end
	end
	return nil
end
local function hookACTable(tbl)
	if not tbl then
		return
	end
	if type(tbl.Detected) == "function" then
		safeHook(tbl.Detected, function()
			ZukaStats.DetectionsCaught += 1
		end)
	end
	if type(tbl.RemovePlayer) == "function" then
		safeHook(tbl.RemovePlayer, function()
			ZukaStats.KickAttempts += 1
		end)
	end
	if type(tbl.CheckAllClients) == "function" then
		safeHook(tbl.CheckAllClients, function()
			ZukaStats.ClientChecksBlocked += 1
		end)
	end
	if type(tbl.UserSpoofCheck) == "function" then
		safeHook(tbl.UserSpoofCheck, function() end)
	end
	if type(tbl.CharacterCheck) == "function" then
		safeHook(tbl.CharacterCheck, function() end)
	end
	if type(tbl.KickedPlayers) == "table" then
		local mt = getmetatable(tbl.KickedPlayers) or {}
		rawset(mt, "__index", function()
			return false
		end)
		rawset(mt, "__newindex", function() end)
		rawset(mt, "__len", function()
			return 0
		end)
		pcall(setmetatable, tbl.KickedPlayers, mt)
	end
	if type(tbl.SpoofCheckCache) == "table" then
		pcall(setmetatable, tbl.SpoofCheckCache, {
			__index = function(_, k)
				return {
					{
						Id = k,
						Username = BypassLocalPlayer.Name,
						DisplayName = BypassLocalPlayer.DisplayName,
						UserId = BypassLocalPlayer.UserId,
					},
				}
			end,
			__newindex = function() end,
		})
	end
	if tbl.ClientTimeoutLimit ~= nil then
		pcall(function()
			tbl.ClientTimeoutLimit = math.huge
		end)
	end
	if tbl.AntiCheatEnabled ~= nil then
		pcall(function()
			tbl.AntiCheatEnabled = false
		end)
	end
end
local function findAndPatchRemoteClients()
	local userId = tostring(BypassLocalPlayer.UserId)
	local objs = getCachedGC()
	if not objs then
		return
	end
	for _, v in ipairs(objs) do
		local ok2, isT = pcall(function()
			return type(v) == "table"
		end)
		if not (ok2 and isT) then
			continue
		end
		local ok3, client, hasMaxLen = pcall(function()
			return rawget(v, userId), rawget(v, "MaxLen")
		end)
		if not (ok3 and type(client) == "table") then
			continue
		end
		local ok4, hasLastUpdate = pcall(function()
			return rawget(client, "LastUpdate") ~= nil
		end)
		if ok4 and hasLastUpdate and hasMaxLen ~= nil then
			task.spawn(function()
				while not isUnloaded do
					task.wait(8)
					pcall(function()
						local c = v[userId]
						if c then
							c.LastUpdate = os.time()
							c.PlayerLoaded = true
						end
					end)
				end
			end)
		end
	end
end
local REMOTE_BLOCK_EXACT = {
	["__FUNCTION"] = true,
	["_FUNCTION"] = true,
	["ClientCheck"] = true,
	["ProcessCommand"] = true,
	["ClientLoaded"] = true,
	["ActivateCommand"] = true,
	["Disconnect"] = true,
}
local REMOTE_BLOCK_PATTERNS = {
	"anticheat",
	"anti_cheat",
	"kickplayer",
	"banplayer",
	"reportexploit",
	"detectclient",
	"cheatcheck",
}
local function shouldBlockRemote(remoteName)
	if REMOTE_BLOCK_EXACT[remoteName] then
		return true
	end
	local lower = remoteName:lower()
	for _, pat in ipairs(REMOTE_BLOCK_PATTERNS) do
		if lower:find(pat, 1, true) then
			return true
		end
	end
	return false
end
local function installNamecallHook()
	local mt = get_mt(game)
	if not mt then
		return
	end
	local oldNamecall = mt.__namecall
	originalFunctions.namecall = oldNamecall
	pcall(set_ro, mt, false)
	mt.__namecall = new_cc(function(self, ...)
		if isUnloaded then
			return oldNamecall(self, ...)
		end
		if check_caller() then
			return oldNamecall(self, ...)
		end
		local method = getnamecallmethod()
		local args = { ... }
		if method == "Kick" and self == BypassLocalPlayer then
			local msg = tostring(args[1] or ""):lower()
			for _, kw in ipairs(KICK_KEYWORDS) do
				if msg:find(kw) then
					ZukaStats.KickAttempts += 1
					return nil
				end
			end
		end
		if method == "FireServer" or method == "InvokeServer" then
			local name = (typeof(self) == "Instance" and self.Name) or ""
			if shouldBlockRemote(name) then
				ZukaStats.RemotesBlocked += 1
				if method == "InvokeServer" then
					return "Pong"
				end
				return nil
			end
			ZukaStats.RemotesFired += 1
		end
		return oldNamecall(self, ...)
	end)
	pcall(set_ro, mt, true)
end
local function installDebugHooks()
	local function isHooked(fn)
		for _, h in ipairs(HookedFunctions) do
			if fn == h then
				return true
			end
		end
		return false
	end
	local function wrapDebugFn(fn, fallback)
		if type(fn) ~= "function" then
			return
		end
		pcall(
			hook_fn,
			fn,
			new_cc(function(target, ...)
				if isHooked(target) then
					return fallback
				end
				return fn(target, ...)
			end)
		)
	end
	wrapDebugFn(debug.info or debug.getinfo, nil)
	wrapDebugFn(debug.getupvalues, {})
	wrapDebugFn(debug.getlocals, {})
	wrapDebugFn(debug.getconstants, {})
end
local function protectKick()
	local origKick = BypassLocalPlayer.Kick
	originalFunctions.kick = origKick
	safeHook(origKick, function(self, reason, ...)
		if check_caller() then
			return origKick(self, reason, ...)
		end
		if self == BypassLocalPlayer then
			local msg = tostring(reason or ""):lower()
			for _, kw in ipairs(KICK_KEYWORDS) do
				if msg:find(kw) then
					ZukaStats.KickAttempts += 1
					return nil
				end
			end
		end
		return origKick(self, reason, ...)
	end)
end
local function rescan()
	gcCache = nil
	local tbl = findACTable()
	if tbl and tbl ~= cachedACTable then
		cachedACTable = tbl
		hookACTable(tbl)
		warn("[Zuka] New AC table found and hooked during rescan.")
	end
	findAndPatchRemoteClients()
end
local function initialize()
	installNamecallHook()
	installDebugHooks()
	protectKick()
	cachedACTable = findACTable()
	if cachedACTable then
		hookACTable(cachedACTable)
	end
	findAndPatchRemoteClients()
	task.spawn(function()
		while not isUnloaded do
			task.wait(45)
			rescan()
		end
	end)
	task.spawn(function()
		while not isUnloaded do
			task.wait(60)
			pcall(function()
				warn(
					string.format(
						"[Zuka] Stats | Kicks: %d | Remotes: %d | Detections: %d | ClientChecks: %d | Hooks: %d",
						ZukaStats.KickAttempts,
						ZukaStats.RemotesBlocked,
						ZukaStats.DetectionsCaught,
						ZukaStats.ClientChecksBlocked,
						ZukaStats.FunctionsHooked
					)
				)
			end)
		end
	end)
end
getgenv().Zuka = {
	Version = "3.1",
	GetStats = function()
		return {
			KickAttempts = ZukaStats.KickAttempts,
			RemotesBlocked = ZukaStats.RemotesBlocked,
			DetectionsCaught = ZukaStats.DetectionsCaught,
			ClientChecksBlocked = ZukaStats.ClientChecksBlocked,
			FunctionsHooked = ZukaStats.FunctionsHooked,
			RemotesFired = ZukaStats.RemotesFired,
		}
	end,
	PrintStats = function()
		for k, v in pairs(getgenv().Zuka.GetStats()) do
			print(string.format("  %s: %d", k, v))
		end
	end,
	Rescan = function()
		rescan()
		warn("[Zuka] Manual rescan complete.")
	end,
	Unload = function()
		isUnloaded = true
		getgenv().Zuka_Loaded = nil
		warn("[Zuka] Unloaded.")
	end,
	BlockRemote = function(name)
		REMOTE_BLOCK_EXACT[name] = true
		warn("[Zuka] Now blocking remote: " .. tostring(name))
	end,
	UnblockRemote = function(name)
		REMOTE_BLOCK_EXACT[name] = nil
		warn("[Zuka] Unblocked remote: " .. tostring(name))
	end,
}
initialize()
local SPOOF_NAME = "Synapse X"
local SPOOF_VERSION = "2.1.0"
genv.identifyexecutor = function()
	return SPOOF_NAME, SPOOF_VERSION
end
genv.getexecutorname = function()
	return SPOOF_NAME
end
genv.getexecutorversion = function()
	return SPOOF_VERSION
end
if not genv.syn then
	genv.syn = {}
end
genv.syn.get_thread_identity = genv.syn.get_thread_identity or function()
	return 7
end
genv.syn.set_thread_identity = genv.syn.set_thread_identity or function() end
genv.syn.is_cached = genv.syn.is_cached or function()
	return false
end
genv.syn.cache_replace = genv.syn.cache_replace or function() end
genv.syn.cache_invalidate = genv.syn.cache_invalidate or function() end
if type(identifyexecutor) == "function" then
	pcall(hookfunction, identifyexecutor, function()
		return SPOOF_NAME, SPOOF_VERSION
	end)
end
local BLOCKED_URL_PATTERNS = {
	"discord%.gg",
	"discord%.com/api/webhooks",
	"discordapp%.com",
	"webhook%.site",
	"hooks%.slack%.com",
	"pastebin%.com",
	"hastebin%.com",
	"ghostbin%.com",
	"bin%.birdflop%.com",
	"api%.anonfiles%.com",
	"anonfile%.com",
}
local function isUrlBlocked(url)
	if type(url) ~= "string" then
		return false, nil
	end
	local lower = url:lower()
	for _, pattern in ipairs(BLOCKED_URL_PATTERNS) do
		if lower:match(pattern) then
			return true, pattern
		end
	end
	return false, nil
end
local function warnBlocked(method, url, pattern)
	warn(("[AntiWebhook] Blocked %s → %s  (rule: %s)"):format(method, url, pattern))
end
local function makeRequestInterceptor(realFn)
	return function(options)
		local url = type(options) == "table" and options.Url or tostring(options)
		local blocked, pattern = isUrlBlocked(url)
		if blocked then
			warnBlocked("request()", url, pattern)
			return { Success = false, StatusCode = 0, StatusMessage = "Blocked", Body = "" }
		end
		return realFn(options)
	end
end

--[[
    HTTP interception is left commented out intentionally – enable if
    your executor exposes request / http_request / syn.request:

if type(genv.syn) == "table" and type(genv.syn.request) == "function" then
    local _real = genv.syn.request
    genv.syn.request = makeRequestInterceptor(_real)
elseif type(http_request) == "function" then
    genv.http_request = makeRequestInterceptor(http_request)
    pcall(hookfunction, http_request, makeRequestInterceptor(http_request))
elseif type(request) == "function" then
    genv.request = makeRequestInterceptor(request)
    pcall(hookfunction, request, makeRequestInterceptor(request))
end
--]]
