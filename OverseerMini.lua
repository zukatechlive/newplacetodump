--[[




 ________  ___      ___ _______   ________  ________  _______   _______   ________
|\   __  \|\  \    /  /|\  ___ \ |\   __  \|\   ____\|\  ___ \ |\  ___ \ |\   __  \
\ \  \|\  \ \  \  /  / | \   __/|\ \  \|\  \ \  \___|\ \   __/|\ \   __/|\ \  \|\  \
 \ \  \\\  \ \  \/  / / \ \  \_|/_\ \   _  _\ \_____  \ \  \_|/_\ \  \_|/_\ \   _  _\
  \ \  \\\  \ \    / /   \ \  \_|\ \ \  \\  \\|____|\  \ \  \_|\ \ \  \_|\ \ \  \\  \|
   \ \_______\ \__/ /     \ \_______\ \__\\ _\ ____\_\  \ \_______\ \_______\ \__\\ _\
    \|_______|\|__|/       \|_______|\|__|\|__|\_________\|_______|\|_______|\|__|\|__|
                                              \|_________|






]]--

	local httpservice = cloneref and cloneref(game:GetService("HttpService")) or game:GetService("HttpService")

	local function _base64_encode(data)
		if type(base64_encode) == "function" then
			return base64_encode(data)
		end
		local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
		return ((data:gsub('.', function(x)
			local r, byte = '', x:byte()
			for i = 8, 1, -1 do
				r = r .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and '1' or '0')
			end
			return r
		end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
			if #x < 6 then return '' end
			local c = 0
			for i = 1, 6 do
				c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0)
			end
			return b:sub(c + 1, c + 1)
		end) .. ({ '', '==', '=' })[#data % 3 + 1])
	end

	local _lastDecompileRequest = 0
	local function _apiDecompile(scr)
		assert(type(getscriptbytecode) == "function", "exploit does not support getscriptbytecode.")
		assert(type(scr) == "userdata" or typeof(scr) == "Instance", "invalid script instance")

		local ok, bytecode = pcall(getscriptbytecode, scr)
		if not ok then
			return "-- failed to read script bytecode\n--[[\n" .. tostring(bytecode) .. "\n--]]"
		end
		if type(bytecode) ~= "string" or bytecode == "" then
			return "-- failed to read script bytecode\n--[[\nempty bytecode\n--]]"
		end

		local elapsed = os.clock() - _lastDecompileRequest
		if elapsed < 0.04 then
			task.wait(0.04 - elapsed)
		end

		local env = getgenv and getgenv() or _G
		local req = env.request or env.http_request
		if not req and syn and type(syn.request) == "function" then
			req = syn.request
		end
		if type(req) ~= "function" then
			return "-- api request error\n--[[\nrequest/http_request is not available in this executor\n--]]"
		end

		local okReq, res = pcall(req, {
			Url = "https://api.lua.expert/decompile",
			Method = "POST",
			Headers = {
				["content-type"] = "application/json"
			},
			Body = httpservice:JSONEncode({
				script = _base64_encode(bytecode)
			})
		})
		_lastDecompileRequest = os.clock()

		if not okReq or not res then
			return "-- api request error\n--[[\n" .. tostring(res or "request failed") .. "\n--]]"
		end
		if res.StatusCode ~= 200 then
			return "-- api request error\n--[[\n" .. tostring(res.Body or "no response") .. "\n--]]"
		end

		return tostring(res.Body or "")
	end

	getgenv().decompile = _apiDecompile

	local CoreGui = game:GetService("CoreGui")
	local UserInputService = game:GetService("UserInputService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local RunService = game:GetService("RunService")
	local CollectionService = game:GetService("CollectionService")
	local TweenService = game:GetService("TweenService")
	if not _G.Modules then
		_G.Modules = {}
	end
	local Modules = _G.Modules
	Modules.TI = {
		State = {
			CurrentTable = nil,
			PathStack = {},
			VisitedTables = {},
			ModuleList = {},
			ActivePatches = {},
			FreezeList = {},
			SelectedPatches = {},
			RootScriptPath = nil,
			RootScriptName = nil,
			LSMode = false,
			SelectedLocalScript = nil,
			LSClosures = {},
			LSConnections = {},
			UI = nil,
			MetatableChain = {},
			SelectedModule = nil,
			ModuleSeen = {},
			GCModuleCount = 0,
			ViewerWrap = false,
		},
		Config = {
			BG_LIGHT = Color3.fromRGB(40, 40, 44),
			BG_PANEL = Color3.fromRGB(22, 22, 26),
			BG_DARK = Color3.fromRGB(16, 16, 20),
			BG_WHITE = Color3.fromRGB(28, 28, 32),
			BORDER_DARK = Color3.fromRGB(50, 50, 60),
			BORDER_LIGHT = Color3.fromRGB(70, 70, 85),
			TEXT_BLACK = Color3.fromRGB(220, 220, 230),
			TEXT_GRAY = Color3.fromRGB(120, 120, 140),
			ACCENT = Color3.fromRGB(99, 102, 241),
			HIGHLIGHT = Color3.fromRGB(56, 189, 248),
			FROZEN_RED = Color3.fromRGB(239, 68, 68),
			SUCCESS_GREEN = Color3.fromRGB(34, 197, 94),
			WARNING_ORANGE = Color3.fromRGB(251, 191, 36),
			ROW_HEIGHT = 24,
		},
	}
	local TI = Modules.TI

	local FunctionEditor = {}
	FunctionEditor.__index = FunctionEditor

	local _FE_CONFIG = {
		EDITOR_WIDTH = 500,
		EDITOR_HEIGHT = 300,
		SYNTAX_CHECK_DELAY = 0.5,
		MAX_EDIT_HISTORY = 20,
		COLORS = {
			EDITOR_BG = Color3.fromRGB(40, 40, 40),
			EDITOR_BORDER = Color3.fromRGB(60, 60, 60),
			EDITOR_TEXT = Color3.fromRGB(220, 220, 220),
			VALID = Color3.fromRGB(76, 175, 80),
			INVALID = Color3.fromRGB(244, 67, 54),
			WARNING = Color3.fromRGB(255, 193, 7),
			MODIFIED = Color3.fromRGB(33, 150, 243),
		},
	}

	function FunctionEditor.new()
		local self = setmetatable({}, FunctionEditor)
		self.History = {}
		self.EditSessions = {}
		return self
	end

	local function _fe_serializeUserdata(v)
		local ok, tn = pcall(typeof, v)
		if not ok then return string.format("error(%q)", "Couldn't read this userdata's type") end
		if tn == "Vector3" then
			return string.format("Vector3.new(%.9g, %.9g, %.9g)", v.X, v.Y, v.Z)
		elseif tn == "Vector2" then
			return string.format("Vector2.new(%.9g, %.9g)", v.X, v.Y)
		elseif tn == "Color3" then
			return string.format("Color3.new(%.9g, %.9g, %.9g)", v.R, v.G, v.B)
		elseif tn == "UDim2" then
			return string.format("UDim2.new(%.9g, %d, %.9g, %d)",
				v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
		elseif tn == "UDim" then
			return string.format("UDim.new(%.9g, %d)", v.Scale, v.Offset)
		elseif tn == "BrickColor" then
			return string.format("BrickColor.new(%s)", string.format("%q", v.Name))
		elseif tn == "EnumItem" then
			local okE, enumTypeStr = pcall(tostring, v.EnumType)
			if okE then
				return enumTypeStr .. "." .. v.Name
			end
			return string.format("error(%q)", "Couldn't read this EnumItem's type")
		elseif tn == "CFrame" then
			local okC, c = pcall(function() return { v:GetComponents() } end)
			if okC and #c == 12 then
				local parts = {}
				for i = 1, 12 do parts[i] = string.format("%.9g", c[i]) end
				return "CFrame.new(" .. table.concat(parts, ", ") .. ")"
			end
			return string.format("error(%q)", "Couldn't read this CFrame's components")
		elseif tn == "Instance" then
			local okC, className = pcall(function() return v.ClassName end)
			return string.format(
				"error(%s)",
				string.format("%q", "Instances can't be reconstructed from text"
						.. (okC and (" (" .. className .. ")") or "")
						.. " - use Dive to browse it instead")
			)
		else
			return nil
		end
	end

	local function _fe_serialize(v, seen)
		local t = type(v)
		if t == "string" then return string.format("%q", v)
		elseif t == "number" then return tostring(v)
		elseif t == "boolean" then return tostring(v)
		elseif t == "table" then
			seen = seen or {}
			if seen[v] then return "--[[ <cycle> ]] {}" end
			seen[v] = true
			local parts = {}
			local ok = pcall(function()
				for k, val in pairs(v) do
					table.insert(parts, string.format("[%s] = %s",
						(type(k) == "string") and string.format("%q", k) or tostring(k),
						_fe_serialize(val, seen)))
				end
			end)
			seen[v] = nil
			if not ok then return "--[[ <protected table> ]] {}" end
			return "{ " .. table.concat(parts, ", ") .. " }"
		elseif t == "function" then
			return "function(...)\n\treturn true\nend"
		elseif t == "userdata" then
			return _fe_serializeUserdata(v)
		else return "-- [non-editable type]" end
	end

	local _load = (typeof(load) == "function" and load)
		or (typeof(loadstring) == "function" and loadstring)
		or error("Neither load() nor loadstring() is available in this environment")

	local function _fe_deserialize(code)
		local chunk, err = _load("return " .. code)
		if not chunk then return nil, "Syntax error: " .. tostring(err) end
		local ok, result = pcall(chunk)
		if not ok then return nil, "Runtime error: " .. tostring(result) end
		return result, nil
	end

	local function _fe_validateExpr(code)
		local chunk, err = _load("return " .. code)
		if not chunk then return false, "Invalid expression: " .. tostring(err) end
		return true, "Valid expression"
	end

	function FunctionEditor:CreateEditSession(tableRef, keyName, originalValue)
		local sessionId = "edit_" .. tostring(os.clock()):gsub("%.", "_")
		local serialized = _fe_serialize(originalValue)
		local rawType = type(originalValue)
		local displayType = rawType
		local userdataType = nil
		local needsUserdataExpression = false
		if rawType == "userdata" then
			local okT, tn = pcall(typeof, originalValue)
			if okT then
				userdataType = tn
				displayType = tn
			end
			if serialized == nil then
				needsUserdataExpression = true
				serialized = ""
			end
		end
		local session = {
			Id = sessionId,
			TableRef = tableRef,
			KeyName = keyName,
			OriginalValue = originalValue,
			OriginalType = rawType,
			DisplayType = displayType,
			OriginalSerialized = serialized,
			CurrentCode = serialized,
			IsModified = false,
			ValidationStatus = needsUserdataExpression and "needs_expression" or "valid",
			ValidationMessage = needsUserdataExpression
				and ("Enter an expression returning " .. tostring(userdataType or "userdata"))
				or "Valid expression",
			UserdataType = userdataType,
			NeedsUserdataExpression = needsUserdataExpression,
		}
		self.EditSessions[sessionId] = session
		return sessionId, session
	end

	function FunctionEditor:UpdateEditSession(sessionId, newCode)
		local session = self.EditSessions[sessionId]
		if not session then return false end
		session.CurrentCode = newCode
		session.IsModified = (newCode ~= session.OriginalSerialized)
		if session.OriginalType == "userdata" and newCode:match("^%s*$") then
			session.ValidationStatus = "needs_expression"
			session.ValidationMessage =
				"Enter an expression returning " .. tostring(session.UserdataType or "userdata")
			return true, session
		end
		local isValid, msg = _fe_validateExpr(newCode)
		session.ValidationStatus = isValid and "valid" or "invalid"
		session.ValidationMessage = msg
		return true, session
	end

	function FunctionEditor:CommitEditSession(sessionId, TI_ref, freeze)
		local session = self.EditSessions[sessionId]
		if not session then return false, "Session not found" end
		if session.OriginalType == "userdata" and session.CurrentCode:match("^%s*$") then
			return false, "Enter an expression for the userdata value first"
		end
		local newValue, err = _fe_deserialize(session.CurrentCode)
		if err then return false, err end
		if session.OriginalType == "userdata" then
			if type(newValue) ~= "userdata" then
				return false, "Expression returned " .. type(newValue) .. ", expected userdata"
			end
			if session.UserdataType and type(typeof) == "function" then
				local okT, newType = pcall(typeof, newValue)
				if okT and newType ~= session.UserdataType then
					return false, "Wrong userdata type: expected "
						.. tostring(session.UserdataType) .. ", got " .. tostring(newType)
				end
			end
		end
		if TI_ref and TI_ref.CreatePatch then
			local patchId = TI_ref:CreatePatch(session.TableRef, session.KeyName, newValue, freeze or false)
			if not patchId then return false, "Patch failed (table may be protected)" end
		else
			session.TableRef[session.KeyName] = newValue
		end
		table.insert(self.History, {
			SessionId = sessionId,
			TableRef = session.TableRef,
			KeyName = session.KeyName,
			OldValue = session.OriginalValue,
			NewValue = newValue,
		})
		if #self.History > _FE_CONFIG.MAX_EDIT_HISTORY then
			table.remove(self.History, 1)
		end
		session.IsModified = false
		return true, "Changes applied"
	end

	function FunctionEditor:UndoLastEdit()
		if #self.History == 0 then return false, "No edits to undo" end
		local edit = table.remove(self.History)
		edit.TableRef[edit.KeyName] = edit.OldValue
		return true, "Edit undone: " .. tostring(edit.KeyName)
	end

	function FunctionEditor:CreateEditPanel(parent, sessionId, session, showNotificationFn, TI_ref)
		local C = _FE_CONFIG.COLORS
		local editorFrame = Instance.new("Frame", parent)
		editorFrame.Name = "FunctionEditor_" .. sessionId
		editorFrame.Size = UDim2.fromOffset(_FE_CONFIG.EDITOR_WIDTH, _FE_CONFIG.EDITOR_HEIGHT)
		editorFrame.Position = UDim2.new(0.5, -_FE_CONFIG.EDITOR_WIDTH / 2, 0.5, -_FE_CONFIG.EDITOR_HEIGHT / 2)
		editorFrame.BackgroundColor3 = C.EDITOR_BG
		editorFrame.BorderSizePixel = 2
		editorFrame.ZIndex = 200
		editorFrame.ClipsDescendants = false

		local header = Instance.new("Frame", editorFrame)
		header.Size = UDim2.new(1, 0, 0, 24)
		header.BackgroundColor3 = C.EDITOR_BORDER
		header.BorderSizePixel = 0
		header.ZIndex = 201

		local titleLbl = Instance.new("TextLabel", header)
		titleLbl.Size = UDim2.new(1, -26, 1, 0)
		titleLbl.Position = UDim2.fromOffset(4, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = "✎ Edit  [" .. session.KeyName .. " : " .. (session.DisplayType or session.OriginalType) .. "]"
		titleLbl.TextColor3 = C.EDITOR_TEXT
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.TextSize = 11
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.ZIndex = 202

		local closeBtn = Instance.new("TextButton", header)
		closeBtn.Size = UDim2.fromOffset(20, 20)
		closeBtn.Position = UDim2.new(1, -22, 0, 2)
		closeBtn.BackgroundColor3 = C.INVALID
		closeBtn.TextColor3 = Color3.new(1, 1, 1)
		closeBtn.Font = Enum.Font.GothamBold
		closeBtn.TextSize = 12
		closeBtn.Text = "×"
		closeBtn.BorderSizePixel = 0
		closeBtn.ZIndex = 202

		local dragging, dragStart, panelStart = false, nil, nil
		header.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true; dragStart = i.Position; panelStart = editorFrame.Position
			end
		end)
		game:GetService("UserInputService").InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - dragStart
				editorFrame.Position = UDim2.new(
					panelStart.X.Scale, panelStart.X.Offset + d.X,
					panelStart.Y.Scale, panelStart.Y.Offset + d.Y)
			end
		end)
		game:GetService("UserInputService").InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)

		local textBox = Instance.new("TextBox", editorFrame)
		textBox.Name = "CodeInput"
		textBox.Size = UDim2.new(1, -8, 0, 180)
		textBox.Position = UDim2.fromOffset(4, 28)
		textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		textBox.TextColor3 = C.EDITOR_TEXT
		textBox.Font = Enum.Font.Code
		textBox.TextSize = 10
		textBox.ClearTextOnFocus = false
		textBox.TextWrapped = true
		textBox.MultiLine = true
		textBox.Text = session.CurrentCode
		if session.OriginalType == "userdata" and session.NeedsUserdataExpression then
			textBox.PlaceholderText = "Enter an expression returning " .. tostring(session.UserdataType or "userdata")
			textBox.PlaceholderColor3 = Color3.fromRGB(130, 130, 145)
		end
		textBox.TextXAlignment = Enum.TextXAlignment.Left
		textBox.TextYAlignment = Enum.TextYAlignment.Top
		textBox.ZIndex = 201

		local statusLbl = Instance.new("TextLabel", editorFrame)
		statusLbl.Size = UDim2.new(1, -8, 0, 18)
		statusLbl.Position = UDim2.fromOffset(4, 212)
		statusLbl.BackgroundTransparency = 1
		statusLbl.TextColor3 = C.VALID
		statusLbl.Font = Enum.Font.Code
		statusLbl.TextSize = 9
		statusLbl.TextXAlignment = Enum.TextXAlignment.Left
		statusLbl.Text = session.ValidationMessage
		statusLbl.ZIndex = 201

		local validTimer = nil
		textBox.Changed:Connect(function(prop)
			if prop == "Text" then
				if validTimer then task.cancel(validTimer) end
				validTimer = task.delay(_FE_CONFIG.SYNTAX_CHECK_DELAY, function()
					self:UpdateEditSession(sessionId, textBox.Text)
					local s = self.EditSessions[sessionId]
					if s then
						statusLbl.Text = s.ValidationMessage
						statusLbl.TextColor3 = (s.ValidationStatus == "valid") and C.VALID or C.INVALID
					end
				end)
			end
		end)

		local btnRow = Instance.new("Frame", editorFrame)
		btnRow.Size = UDim2.new(1, 0, 0, 32)
		btnRow.Position = UDim2.new(0, 0, 1, -32)
		btnRow.BackgroundColor3 = C.EDITOR_BORDER
		btnRow.BorderSizePixel = 0
		btnRow.ZIndex = 201

		local function makeBtn(text, xOff, w, bgCol, cb)
			local b = Instance.new("TextButton", btnRow)
			b.Size = UDim2.fromOffset(w, 24)
			b.Position = UDim2.fromOffset(xOff, 4)
			b.BackgroundColor3 = bgCol
			b.TextColor3 = Color3.new(1, 1, 1)
			b.Font = Enum.Font.GothamBold
			b.TextSize = 10
			b.Text = text
			b.BorderSizePixel = 0
			b.ZIndex = 202
			b.MouseButton1Click:Connect(cb)
			return b
		end

		local function doCommit(freeze)
			local ok, msg = self:CommitEditSession(sessionId, TI_ref, freeze)
			if ok then
				statusLbl.Text = freeze and "✓ Applied & Frozen!" or "✓ Applied!"
				statusLbl.TextColor3 = C.VALID
				if showNotificationFn then
					showNotificationFn(
						(freeze and "Frozen: " or "Edited: ") .. tostring(session.KeyName),
						"success"
					)
				end
				task.wait(1)
				editorFrame:Destroy()
				if TI_ref then TI_ref:RefreshInspector() end
			else
				statusLbl.Text = "✗ " .. msg
				statusLbl.TextColor3 = C.INVALID
			end
		end
		makeBtn("✓ Apply", 4, 100, C.VALID, function() doCommit(false) end)

		makeBtn("✗ Cancel", 108, 100, C.INVALID, function()
			editorFrame:Destroy()
		end)

		makeBtn("↶ Undo", 212, 80, C.WARNING, function()
			local ok, msg = self:UndoLastEdit()
			statusLbl.Text = ok and ("✓ " .. msg) or ("✗ " .. msg)
			statusLbl.TextColor3 = ok and C.WARNING or C.INVALID
			if ok and showNotificationFn then showNotificationFn(msg, "success") end
			if ok and TI_ref then TI_ref:RefreshInspector() end
		end)

		makeBtn("❄ Freeze", 296, 88, Color3.fromRGB(33, 150, 243), function() doCommit(true) end)

		local histLbl = Instance.new("TextLabel", btnRow)
		histLbl.Size = UDim2.fromOffset(90, 24)
		histLbl.Position = UDim2.new(1, -94, 0, 4)
		histLbl.BackgroundTransparency = 1
		histLbl.TextColor3 = C.EDITOR_TEXT
		histLbl.Font = Enum.Font.Code
		histLbl.TextSize = 9
		histLbl.Text = "History: " .. #self.History
		histLbl.ZIndex = 202

		if session.OriginalType == "function" then
			local forceRow = Instance.new("Frame", editorFrame)
			forceRow.Size = UDim2.new(1, 0, 0, 26)
			forceRow.Position = UDim2.new(0, 0, 1, -58)
			forceRow.BackgroundColor3 = C.EDITOR_BORDER
			forceRow.BorderSizePixel = 0
			forceRow.ZIndex = 201

			local forceLbl = Instance.new("TextLabel", forceRow)
			forceLbl.Size = UDim2.fromOffset(60, 20)
			forceLbl.Position = UDim2.fromOffset(4, 3)
			forceLbl.BackgroundTransparency = 1
			forceLbl.TextColor3 = C.EDITOR_TEXT
			forceLbl.Font = Enum.Font.Code
			forceLbl.TextSize = 9
			forceLbl.Text = "Force:"
			forceLbl.TextXAlignment = Enum.TextXAlignment.Left
			forceLbl.ZIndex = 202

			local function applyForce(code, label)
				textBox.Text = code
				self:UpdateEditSession(sessionId, code)
				local ok, msg = self:CommitEditSession(sessionId, TI_ref)
				if ok then
					statusLbl.Text = "✓ Forced " .. label
					statusLbl.TextColor3 = C.VALID
					if showNotificationFn then
						showNotificationFn("Forced " .. tostring(session.KeyName) .. " → " .. label, "success")
					end
					task.wait(0.6)
					editorFrame:Destroy()
					if TI_ref then TI_ref:RefreshInspector() end
				else
					statusLbl.Text = "✗ " .. msg
					statusLbl.TextColor3 = C.INVALID
				end
			end

			local fbBtnRow = Instance.new("Frame", forceRow)
			fbBtnRow.Size = UDim2.new(1, -68, 1, 0)
			fbBtnRow.Position = UDim2.fromOffset(64, 0)
			fbBtnRow.BackgroundTransparency = 1
			fbBtnRow.ZIndex = 202

			local function makeForceBtn(text, xOff, w, bgCol, code, label)
				local b = Instance.new("TextButton", fbBtnRow)
				b.Size = UDim2.fromOffset(w, 20)
				b.Position = UDim2.fromOffset(xOff, 3)
				b.BackgroundColor3 = bgCol
				b.TextColor3 = Color3.new(1, 1, 1)
				b.Font = Enum.Font.GothamBold
				b.TextSize = 9
				b.Text = text
				b.BorderSizePixel = 0
				b.ZIndex = 203
				b.MouseButton1Click:Connect(function() applyForce(code, label) end)
				return b
			end

			makeForceBtn("True", 0, 56, Color3.fromRGB(76, 175, 80),
				"function(...)\n\treturn true\nend", "true")
			makeForceBtn("False", 60, 56, Color3.fromRGB(244, 67, 54),
				"function(...)\n\treturn false\nend", "false")
			makeForceBtn("Nil", 120, 56, Color3.fromRGB(120, 120, 120),
				"function(...)\n\treturn nil\nend", "nil")
		end

		closeBtn.MouseButton1Click:Connect(function()
			editorFrame:Destroy()
		end)

		return editorFrame
	end

	function FunctionEditor:OpenFor(tableRef, keyName, parentFrame, showNotificationFn, TI_ref)
		local sessionId, session = self:CreateEditSession(tableRef, keyName, tableRef[keyName])
		local sgParent = parentFrame
		while sgParent and not sgParent:IsA("ScreenGui") do
			sgParent = sgParent.Parent
		end
		local panel = self:CreateEditPanel(sgParent or parentFrame, sessionId, session, showNotificationFn, TI_ref)
		return sessionId, session, panel
	end

	TI.FunctionEditor = FunctionEditor.new()

	function TI:_generateUID()
		local cs = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
		local r = ""
		for _ = 1, 12 do
			r = r .. cs:sub(math.random(1, #cs), math.random(1, #cs))
		end
		return r
	end
	function TI:_createBorder(parent, inset)
		local stroke = Instance.new("UIStroke", parent)
		stroke.Color = inset and self.Config.BORDER_DARK or self.Config.BORDER_LIGHT
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	end
	function TI:_createButton(parent, text, size, position, callback)
		local btn = Instance.new("TextButton", parent)
		btn.Size = size
		btn.Position = position
		btn.BackgroundColor3 = self.Config.BG_LIGHT
		btn.Text = text
		btn.TextColor3 = self.Config.TEXT_BLACK
		btn.Font = Enum.Font.GothamMedium
		btn.TextSize = 11
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.ClipsDescendants = true
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = self.Config.BORDER_LIGHT
		stroke.Thickness = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		if callback then
			btn.MouseButton1Click:Connect(callback)
		end
		btn.MouseButton1Down:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundColor3 = self.Config.ACCENT }):Play()
		end)
		btn.MouseButton1Up:Connect(function()
			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_LIGHT }):Play()
		end)
		btn.MouseEnter:Connect(function()
			if btn.BackgroundColor3 ~= self.Config.ACCENT then
				TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(55, 55, 65) }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if btn.BackgroundColor3 ~= self.Config.ACCENT then
				TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_LIGHT }):Play()
			end
		end)
		return btn
	end
	function TI:_showNotification(message, msgType)
		if not self.State.UI then
			return
		end
		local notif = Instance.new("Frame", self.State.UI.Main)
		notif.Size = UDim2.fromOffset(280, 50)
		notif.Position = UDim2.new(1, -290, 1, 10)
		notif.BackgroundColor3 = msgType == "success" and Color3.fromRGB(20, 50, 30)
			or msgType == "error" and Color3.fromRGB(50, 20, 20)
			or msgType == "warning" and Color3.fromRGB(50, 40, 10)
			or self.Config.BG_LIGHT
		notif.BorderSizePixel = 0
		notif.ZIndex = 1000
		Instance.new("UICorner", notif).CornerRadius = UDim.new(0, 8)
		local ns = Instance.new("UIStroke", notif)
		ns.Color = msgType == "success" and self.Config.SUCCESS_GREEN
			or msgType == "error" and self.Config.FROZEN_RED
			or msgType == "warning" and self.Config.WARNING_ORANGE
			or self.Config.ACCENT
		ns.Thickness = 1
		local icon = Instance.new("TextLabel", notif)
		icon.Size = UDim2.fromOffset(34, 34)
		icon.Position = UDim2.fromOffset(8, 8)
		icon.BackgroundTransparency = 1
		icon.ZIndex = 1001
		icon.Text = msgType == "success" and "✓"
			or msgType == "error" and "✗"
			or msgType == "warning" and "⚠"
			or "ℹ"
		icon.TextColor3 = msgType == "success" and self.Config.SUCCESS_GREEN
			or msgType == "error" and self.Config.FROZEN_RED
			or msgType == "warning" and self.Config.WARNING_ORANGE
			or self.Config.ACCENT
		icon.Font = Enum.Font.GothamBold
		icon.TextSize = 22
		local msg = Instance.new("TextLabel", notif)
		msg.Size = UDim2.new(1, -48, 1, -4)
		msg.Position = UDim2.fromOffset(44, 2)
		msg.BackgroundTransparency = 1
		msg.ZIndex = 1001
		msg.Text = message
		msg.TextColor3 = self.Config.TEXT_BLACK
		msg.Font = Enum.Font.SourceSans
		msg.TextSize = 10
		msg.TextXAlignment = Enum.TextXAlignment.Left
		msg.TextYAlignment = Enum.TextYAlignment.Center
		msg.TextWrapped = true
		TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Position = UDim2.new(1, -290, 1, -60) })
		:Play()
		task.delay(3, function()
			local out = TweenService:Create(notif, TweenInfo.new(0.3), { Position = UDim2.new(1, -290, 1, 10) })
			out:Play()
			out.Completed:Connect(function()
				notif:Destroy()
			end)
		end)
	end
	function TI:GetRawMetatable(tbl)
		local ok, res = pcall(getmetatable, tbl)
		if ok and type(res) == "table" then
			return res, "getmetatable"
		end
		if getrawmetatable then
			ok, res = pcall(getrawmetatable, tbl)
			if ok and type(res) == "table" then
				return res, "getrawmetatable"
			end
		end
		if debug and debug.getmetatable then
			ok, res = pcall(debug.getmetatable, tbl)
			if ok and type(res) == "table" then
				return res, "debug.getmetatable"
			end
		end
		return nil, nil
	end
	function TI:UnlockMetatable(tbl)
		if type(tbl) ~= "table" then
			return false, "Not a table"
		end
		local mt = self:GetRawMetatable(tbl)
		if not mt then
			return false, "No metatable"
		end
		local locked = pcall(getmetatable, tbl) == false
		if setrawmetatable and locked then
			local ok = pcall(setrawmetatable, tbl, mt)
			return ok, ok and "Unlocked via setrawmetatable" or "setrawmetatable failed"
		end
		return not locked, locked and "Locked (no bypass available)" or "Already accessible"
	end
	function TI:AnalyzeMetatableChain(tbl)
		local chain, current, depth, visited = {}, tbl, 0, {}
		while current and depth < 20 do
			if visited[current] then
				break
			end
			visited[current] = true
			local mt, method = self:GetRawMetatable(current)
			if not mt then
				break
			end
			local unlocked, unlockMsg = self:UnlockMetatable(current)
			local entry = {
				Depth = depth,
				Metatable = mt,
				Fields = {},
				HasIndex = false,
				IndexType = nil,
				IndexValue = nil,
				Locked = not unlocked,
				AccessMethod = method,
				UnlockMessage = unlockMsg,
			}
			pcall(function()
				for k, v in pairs(mt) do
					table.insert(entry.Fields, { Key = k, Value = v, Type = type(v) })
					if k == "__index" then
						entry.HasIndex = true
						entry.IndexType = type(v)
						entry.IndexValue = v
					end
				end
			end)
			table.insert(chain, entry)
			if entry.HasIndex and entry.IndexType == "table" then
				current = entry.IndexValue
			else
				break
			end
			depth += 1
		end
		return chain
	end
	function TI:GetDisplayValue(value)
		local t = type(value)
		if t == "string" then
			return string.format("%q", value)
		elseif t == "number" then
			if value == math.floor(value) and value >= 0 and value < 2 ^ 32 then
				return string.format("%d (0x%X)", value, value)
			end
			return tostring(value)
		elseif t == "boolean" then
			return tostring(value)
		elseif t == "table" then
			local n = 0
			for _ in pairs(value) do
				n += 1
				if n > 100 then
					break
				end
			end
			return "{table: " .. n .. (n > 100 and "+" or "") .. " entries}"
		elseif t == "function" then
			if debug and debug.getinfo then
				local info = debug.getinfo(value)
				if info then
					return string.format("function (%s:%s)", (info.source or "?"):sub(1, 20), info.linedefined or "?")
				end
			end
			return "function"
		elseif t == "userdata" then
			local okT, tn = pcall(typeof, value)
			if okT then
				local okV, s = pcall(function()
					if tn == "Vector3" then
						return string.format("Vector3(%.4g, %.4g, %.4g)", value.X, value.Y, value.Z)
					elseif tn == "Vector2" then
						return string.format("Vector2(%.4g, %.4g)", value.X, value.Y)
					elseif tn == "Color3" then
						return string.format("Color3(%.3g, %.3g, %.3g)", value.R, value.G, value.B)
					elseif tn == "UDim2" then
						return string.format("UDim2(%.3g,%d, %.3g,%d)",
							value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
					elseif tn == "UDim" then
						return string.format("UDim(%.3g,%d)", value.Scale, value.Offset)
					elseif tn == "BrickColor" then
						return "BrickColor(" .. value.Name .. ")"
					elseif tn == "EnumItem" then
						return tostring(value.EnumType) .. "." .. value.Name
					elseif tn == "CFrame" then
						return string.format("CFrame(%.4g, %.4g, %.4g, ...)", value.X, value.Y, value.Z)
					elseif tn == "Instance" then
						return "Instance<" .. value.ClassName .. ">"
					end
					return nil
				end)
				if okV and s then return s end
				local ok, s2 = pcall(tostring, value)
				return (ok and s2 or "?") .. " [" .. tn .. "]"
			end
			local ok, s = pcall(tostring, value)
			return ok and (s .. " [userdata]") or "[userdata]"
		else
			return tostring(value)
		end
	end
	function TI:ParseValue(text, expectedType)
		if expectedType == "string" or text:match('^".*"$') or text:match("^'.*'$") then
			return text:gsub("^[\"']", ""):gsub("[\"']$", "")
		elseif text == "true" then
			return true
		elseif text == "false" then
			return false
		elseif text == "nil" then
			return nil
		elseif text == "{}" then
			return {}
		elseif tonumber(text) then
			return tonumber(text)
		else
			return expectedType == "any" and text or nil
		end
	end
	local function _getHookAPI()
		if type(hookfunction) == "function" then return hookfunction end
		if type(replaceclosure) == "function" then return replaceclosure end
		return nil
	end
	function TI:CreatePatch(tbl, key, newValue, freeze)
		if not tbl or key == nil then
			return false
		end
		local patchId = self:_generateUID()
		pcall(function()
			if setreadonly then
				setreadonly(tbl, false)
			elseif make_writeable then
				make_writeable(tbl)
			end
		end)
		local original = rawget(tbl, key)
		local hookMethod, hookOriginalRef = nil, nil
		if type(newValue) == "function" and type(original) == "function" then
			local hookFn = _getHookAPI()
			if hookFn then
				local ok, capturedOriginal = pcall(hookFn, original, newValue)
				if ok then
					hookMethod = "hookfunction"
					hookOriginalRef = capturedOriginal
				end
			end
		end
		local pathSnapshot = {}
		for _, v in ipairs(self.State.PathStack) do
			table.insert(pathSnapshot, v)
		end
		local patch = {
			ID = patchId,
			Table = tbl,
			Key = key,
			Original = original,
			NewValue = newValue,
			Frozen = freeze or false,
			Type = type(newValue),
			Timestamp = tick(),
			Active = true,
			Connection = nil,
			HookMethod = hookMethod,
			HookOriginalRef = hookOriginalRef,
			PathStack = pathSnapshot,
			RootScriptPath = self.State.RootScriptPath,
			RootScriptName = self.State.RootScriptName,
		}
		rawset(tbl, key, newValue)
		self.State.ActivePatches[patchId] = patch
		if freeze then
			patch.Connection = RunService.Heartbeat:Connect(function()
				pcall(function()
					if setreadonly then
						setreadonly(tbl, false)
					end
					rawset(tbl, key, newValue)
					if setreadonly then
						setreadonly(tbl, true)
					end
				end)
			end)
			self.State.FreezeList[patchId] = patch
		end
		pcall(function()
			if setreadonly then
				setreadonly(tbl, true)
			end
		end)
		self:RefreshPatchList()
		self:_showNotification(
			(hookMethod and "Hooked: " or "Patched: ") .. tostring(key),
			"success"
		)
		return patchId
	end
	function TI:RemovePatch(patchId)
		local patch = self.State.ActivePatches[patchId]
		if not patch then
			return false
		end
		if patch.Connection then
			patch.Connection:Disconnect()
			patch.Connection = nil
		end

		if patch.IsInstancePatch and patch.Instance then
			local ok, err = pcall(function()
				if patch.Kind == "instance_attribute" then
					patch.Instance:SetAttribute(patch.Attribute, patch.Original)
				else
					patch.Instance[patch.Property] = patch.Original
				end
			end)
			if not ok then
				self:_showNotification("Instance rollback failed: " .. tostring(err), "error")
				return false
			end
		else
			pcall(function()
				if setreadonly then
					setreadonly(patch.Table, false)
				elseif make_writeable then
					make_writeable(patch.Table)
				end
				if patch.HookMethod == "hookfunction" and patch.HookOriginalRef then
					local hookFn = _getHookAPI()
					if hookFn then pcall(hookFn, patch.Original, patch.HookOriginalRef) end
				end
				if patch.HookMethod == "setupvalue" and patch.LSClosure and patch.LSUVIndex then
					local setupv = setupvalue or (debug and debug.setupvalue)
					if setupv then pcall(setupv, patch.LSClosure, patch.LSUVIndex, patch.Original) end
				elseif patch.HookMethod == "fenv" then
					rawset(patch.Table, patch.Key, patch.Original)
				else
					rawset(patch.Table, patch.Key, patch.Original)
				end
				if setreadonly then setreadonly(patch.Table, true) end
			end)
		end

		self.State.ActivePatches[patchId] = nil
		self.State.FreezeList[patchId] = nil
		self.State.SelectedPatches[patchId] = nil
		self:RefreshPatchList()
		self:_showNotification("Patch removed", "success")
		return true
	end
	function TI:ToggleFreeze(patchId)
		local patch = self.State.ActivePatches[patchId]
		if not patch then return end
		patch.Frozen = not patch.Frozen
		if patch.Frozen then
			if not patch.Connection then
				patch.Connection = RunService.Heartbeat:Connect(function()
					pcall(function()
						if patch.IsInstancePatch and patch.Instance then
							if patch.Kind == "instance_attribute" then
								patch.Instance:SetAttribute(patch.Attribute, patch.NewValue)
							else
								patch.Instance[patch.Property] = patch.NewValue
							end
						elseif patch.HookMethod == "setupvalue" and patch.LSClosure and patch.LSUVIndex then
							local setupv = setupvalue or (debug and debug.setupvalue)
							if setupv then setupv(patch.LSClosure, patch.LSUVIndex, patch.NewValue) end
						elseif patch.Table then
							if setreadonly then setreadonly(patch.Table, false) end
							rawset(patch.Table, patch.Key, patch.NewValue)
							if setreadonly then setreadonly(patch.Table, true) end
						end
					end)
				end)
			end
			self.State.FreezeList[patchId] = patch
		else
			if patch.Connection then patch.Connection:Disconnect(); patch.Connection = nil end
			self.State.FreezeList[patchId] = nil
		end
		self:RefreshPatchList()
	end

	function TI:DrillDown(name, tbl)
		if type(tbl) ~= "table" then
			self:_showNotification("Cannot dive: " .. tostring(name) .. " is " .. type(tbl), "warning")
			return
		end
		local ok, err = pcall(function()
			return next(tbl)
		end)
		if not ok then
			self:_showNotification("Table is protected: " .. tostring(name), "error")
			return
		end
		table.insert(self.State.PathStack, tostring(name))
		self.State.CurrentTable = tbl
		self.State.VisitedTables = {}
		self:RefreshInspector()
		self:_showNotification("Diving into: " .. tostring(name), "info")
	end
	function TI:GoBack()
		if #self.State.PathStack == 0 then
			return
		end
		table.remove(self.State.PathStack)
		local root = self.State._RootTable
		if not root then
			return
		end
		local tbl = root
		for _, part in ipairs(self.State.PathStack) do
			tbl = type(tbl) == "table" and tbl[part] or nil
			if not tbl then
				return
			end
		end
		self.State.CurrentTable = tbl
		self.State.VisitedTables = {}
		self:RefreshInspector()
	end
	function TI:RefreshInspector()
		if not self.State.UI or not self.State.CurrentTable then
			return
		end
		for _, c in ipairs(self.State.UI.InspectorScroll:GetChildren()) do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
		local pathText = #self.State.PathStack > 0 and table.concat(self.State.PathStack, " > ") or "Root"
		self.State.UI.PathLabel.Text = pathText
		self:PopulateTable(self.State.CurrentTable)
		local chain = self:AnalyzeMetatableChain(self.State.CurrentTable)
		self.State.MetatableChain = chain
		if #chain > 0 then
			self:DisplayMetatableChain(chain)
		end
	end
	function TI:PopulateTable(tbl, isMetatable)
		if not tbl or type(tbl) ~= "table" then
			return
		end
		if self.State.VisitedTables[tbl] then
			return
		end
		local entries = {}
		local ok, err = pcall(function()
			for k, v in pairs(tbl) do
				table.insert(entries, { Key = k, Value = v })
			end
		end)
		if not ok then
			self:CreateInspectorRow("[ERROR]", "Cannot read table: " .. tostring(err), tbl, isMetatable)
			return
		end
		if #entries == 0 then
			self:CreateInspectorRow("[EMPTY]", "No entries", tbl, isMetatable)
			self.State.VisitedTables[tbl] = true
			return
		end
		self.State.VisitedTables[tbl] = true
		table.sort(entries, function(a, b)
			local as, bs = tostring(a.Key), tostring(b.Key)
			local aS = as:match("^%[")
			local bS = bs:match("^%[")
			if aS and not bS then
				return false
			end
			if bS and not aS then
				return true
			end
			local an, bn = tonumber(a.Key), tonumber(b.Key)
			if an and bn then
				return an < bn
			end
			if an then
				return true
			end
			if bn then
				return false
			end
			return as < bs
		end)
		for _, e in ipairs(entries) do
			self:CreateInspectorRow(e.Key, e.Value, tbl, isMetatable)
		end
	end
	function TI:CreateInspectorRow(key, value, parentTable, isMetatable)
		if not self.State.UI then
			return
		end
		local valueType = type(value)
		local displayValue = self:GetDisplayValue(value)
		if valueType == "table" then
			local n, ok = 0, true
			ok = pcall(function()
				for _ in pairs(value) do
					n += 1
					if n > 100 then
						break
					end
				end
			end)
			displayValue = ok and ("{table: " .. n .. (n > 100 and "+" or "") .. " entries}") or "{table: protected}"
		end
		local row = Instance.new("Frame", self.State.UI.InspectorScroll)
		row.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
		row.BorderSizePixel = 0
		local isPatched, isFrozen = false, false
		for _, p in pairs(self.State.ActivePatches) do
			if p.Table == parentTable and p.Key == key then
				isPatched = true
				isFrozen = p.Frozen
				break
			end
		end
		row.BackgroundColor3 = isFrozen and Color3.fromRGB(255, 220, 220)
			or isMetatable and Color3.fromRGB(30, 28, 48)
			or self.Config.BG_WHITE
		local activeBox = Instance.new("TextButton", row)
		activeBox.Size = UDim2.fromOffset(12, 12)
		activeBox.Position = UDim2.new(0.03, -6, 0.5, -6)
		activeBox.BackgroundColor3 = self.Config.BG_WHITE
		activeBox.Text = isPatched and "X" or ""
		activeBox.TextColor3 = self.Config.TEXT_BLACK
		activeBox.Font = Enum.Font.SourceSansBold
		activeBox.TextSize = 10
		activeBox.BorderSizePixel = 0
		activeBox.AutoButtonColor = false
		self:_createBorder(activeBox, true)
		local keyLabel = Instance.new("TextLabel", row)
		keyLabel.Size = UDim2.new(0.26, -4, 1, 0)
		keyLabel.Position = UDim2.new(0.07, 2, 0, 0)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Text = tostring(key)
		keyLabel.TextColor3 = isMetatable and Color3.fromRGB(99, 102, 241) or self.Config.TEXT_BLACK
		keyLabel.Font = isMetatable and Enum.Font.Code or Enum.Font.SourceSans
		keyLabel.TextSize = 10
		keyLabel.TextXAlignment = Enum.TextXAlignment.Left
		keyLabel.TextTruncate = Enum.TextTruncate.AtEnd
		local typeLabel = Instance.new("TextLabel", row)
		typeLabel.Size = UDim2.new(0.12, -4, 1, 0)
		typeLabel.Position = UDim2.new(0.33, 2, 0, 0)
		typeLabel.BackgroundTransparency = 1
		typeLabel.Text = valueType
		typeLabel.TextColor3 = self.Config.TEXT_GRAY
		typeLabel.Font = Enum.Font.SourceSans
		typeLabel.TextSize = 9
		typeLabel.TextXAlignment = Enum.TextXAlignment.Left
		local valueBox = Instance.new("TextBox", row)
		valueBox.Size = UDim2.new(0.35, -4, 1, 0)
		valueBox.Position = UDim2.new(0.45, 2, 0, 0)
		valueBox.BackgroundTransparency = 1
		valueBox.Text = displayValue
		valueBox.TextColor3 = self.Config.TEXT_BLACK
		valueBox.Font = Enum.Font.Code
		valueBox.TextSize = 9
		valueBox.TextXAlignment = Enum.TextXAlignment.Left
		valueBox.TextTruncate = Enum.TextTruncate.AtEnd
		local usesRichEditor = (valueType == "function" or valueType == "userdata")
		valueBox.TextEditable = (valueType ~= "table" and not usesRichEditor)
		valueBox.ClearTextOnFocus = false
		valueBox.FocusLost:Connect(function(enterPressed)
			if enterPressed and valueBox.TextEditable then
				local nv = self:ParseValue(valueBox.Text, valueType)
				if nv ~= nil then
					self:CreatePatch(parentTable, key, nv, false)
				else
					self:_showNotification("Invalid value for type: " .. valueType, "error")
				end
			end
		end)
		local actionBtn = self:_createButton(row, "Patch", UDim2.fromOffset(36, 16), UDim2.new(0.80, 2, 0.5, -8), function()
			if valueType == "table" then
				self:DrillDown(key, value)
			elseif usesRichEditor then
				if self.State.UI and self.State.UI.InspectorScroll then
					self.FunctionEditor:OpenFor(parentTable, key,
						self.State.UI.InspectorScroll,
						function(msg, t) self:_showNotification(msg, t) end,
						self)
				end
			else
				local nv = self:ParseValue(valueBox.Text, valueType)
				if nv ~= nil then
					self:CreatePatch(parentTable, key, nv, false)
				else
					self:_showNotification("Invalid value for type: " .. valueType, "error")
				end
			end
		end)
		actionBtn.TextSize = 9
		if valueType == "table" then
			actionBtn.Text = "Dive"
			actionBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
		elseif usesRichEditor then
			actionBtn.Text = "✎ Edit"
			actionBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
		end

		if valueType ~= "table" and not usesRichEditor then
			local editBtn = self:_createButton(row, "✎ Edit", UDim2.fromOffset(36, 16), UDim2.new(0.855, 2, 0.5, -8), function()
				if self.State.UI and self.State.UI.InspectorScroll then
					self.FunctionEditor:OpenFor(parentTable, key,
						self.State.UI.InspectorScroll,
						function(msg, t) self:_showNotification(msg, t) end,
						self)
				end
			end)
			editBtn.TextSize = 8
			editBtn.BackgroundColor3 = Color3.fromRGB(80, 160, 120)
		end

		local freezeBtn = self:_createButton(
			row,
			"Freeze",
			UDim2.fromOffset(36, 16),
			UDim2.new(0.910, 2, 0.5, -8),
			function()
				if valueBox.TextEditable then
					local nv = self:ParseValue(valueBox.Text, valueType)
					if nv ~= nil then
						self:CreatePatch(parentTable, key, nv, true)
					else
						self:_showNotification("Invalid value for type: " .. valueType, "error")
					end
				elseif usesRichEditor then
					self:_showNotification("Use \"❄ Apply & Freeze\" in the editor panel", "info")
					if self.State.UI and self.State.UI.InspectorScroll then
						self.FunctionEditor:OpenFor(parentTable, key,
							self.State.UI.InspectorScroll,
							function(msg, t) self:_showNotification(msg, t) end,
							self)
					end
				else
					self:_showNotification("Cannot freeze " .. valueType, "warning")
				end
			end
		)
		freezeBtn.TextSize = 8
		if valueType == "table" then
			local lastClick = 0
			row.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					local now = tick()
					if now - lastClick < 0.5 then
						pcall(function()
							self:DrillDown(key, value)
						end)
					end
					lastClick = now
				end
			end)
		end
		row.MouseEnter:Connect(function()
			if not isFrozen then
				row.BackgroundColor3 = Color3.fromRGB(230, 240, 255)
			end
		end)
		row.MouseLeave:Connect(function()
			local pFrozen = false
			for _, p in pairs(self.State.ActivePatches) do
				if p.Table == parentTable and p.Key == key then
					pFrozen = p.Frozen
					break
				end
			end
			row.BackgroundColor3 = pFrozen and Color3.fromRGB(255, 220, 220)
				or isMetatable and self.Config.BG_LIGHT
				or self.Config.BG_WHITE
		end)
	end
	function TI:DisplayMetatableChain(chain)
		if not self.State.UI or not chain or #chain == 0 then
			return
		end
		for i, entry in ipairs(chain) do
			local sep = Instance.new("Frame", self.State.UI.InspectorScroll)
			sep.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
			sep.BorderSizePixel = 0
			sep.BackgroundColor3 = entry.Locked and Color3.fromRGB(200, 100, 100) or self.Config.ACCENT
			local lbl = Instance.new("TextLabel", sep)
			lbl.Size = UDim2.new(1, -8, 1, 0)
			lbl.Position = UDim2.fromOffset(4, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = (entry.Locked and "🔒 " or "🔓 ")
				.. "METATABLE #"
				.. i
				.. " (depth "
				.. entry.Depth
				.. ")"
				.. (entry.Locked and " [LOCKED]" or " [Unlocked]")
			lbl.TextColor3 = self.Config.BG_WHITE
			lbl.Font = Enum.Font.SourceSansBold
			lbl.TextSize = 10
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			if entry.AccessMethod or entry.UnlockMessage then
				local info = Instance.new("Frame", self.State.UI.InspectorScroll)
				info.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
				info.BackgroundColor3 = Color3.fromRGB(240, 240, 200)
				info.BorderSizePixel = 0
				local il = Instance.new("TextLabel", info)
				il.Size = UDim2.new(1, -8, 1, 0)
				il.Position = UDim2.fromOffset(4, 0)
				il.BackgroundTransparency = 1
				il.Text = "  ℹ️ " .. (entry.UnlockMessage or ("Access: " .. entry.AccessMethod))
				il.TextColor3 = Color3.fromRGB(100, 100, 0)
				il.Font = Enum.Font.SourceSansItalic
				il.TextSize = 9
				il.TextXAlignment = Enum.TextXAlignment.Left
			end
			for _, field in ipairs(entry.Fields) do
				self:CreateInspectorRow(field.Key, field.Value, entry.Metatable, true)
			end
		end
	end
	function TI:_serializeValue(v)
		local vt = type(v)
		if vt == "string" then return string.format("%q", v) end
		if vt == "boolean" then return tostring(v) end
		if vt == "number" then return tostring(v) end
		if vt == "nil" then return "nil" end
		if vt == "function" then
			local ok, dumped = pcall(string.dump, v)
			if ok then
				local b64 = {}
				for byte in dumped:gmatch(".") do
					table.insert(b64, string.format("\\%d", string.byte(byte)))
				end
				return "loadstring(" .. string.format("%q", dumped) .. ")"
			end
			local dc = rawget(getfenv and getfenv(0) or {}, "decompile") or
				rawget(getfenv and getfenv(0) or {}, "decomp")
			if dc then
				local ok2, src = pcall(dc, v)
				if ok2 and type(src) == "string" then
					return "load(" .. string.format("%q", src) .. ")"
				end
			end
			return "nil --[[ function: " .. tostring(v) .. " — could not serialize ]]"
		end
		if vt == "table" then
			local n = 0
			for _ in pairs(v) do n += 1 end
			if n <= 6 then
				local parts = {}
				for k, val in pairs(v) do
					local ks = type(k) == "string" and k or ("[" .. tostring(k) .. "]")
					table.insert(parts, ks .. " = " .. self:_serializeValue(val))
				end
				return "{ " .. table.concat(parts, ", ") .. " }"
			end
			return "nil --[[ table: too complex to inline ]]"
		end
		return "nil --[[ " .. vt .. ": " .. tostring(v) .. " ]]"
	end

	function TI:_buildKeyPath(patch)
		local stack = patch.PathStack or {}
		local chain = {}
		for _, part in ipairs(stack) do
			if part:match("^[%a_][%w_]*$") then
				table.insert(chain, "." .. part)
			else
				table.insert(chain, "[" .. string.format("%q", tostring(part)) .. "]")
			end
		end
		return "M" .. table.concat(chain)
	end

	function TI:_buildPatchSnippet(patch)
		local keyStr = type(patch.Key) == "string"
			and string.format("%q", patch.Key)
			or "[" .. tostring(patch.Key) .. "]"
		local valStr = self:_serializeValue(patch.NewValue)
		local tblPath = self:_buildKeyPath(patch)
		local vt = type(patch.NewValue)
		local lines = {}
		table.insert(lines, ("-- ┌ Patch: %s  |  type: %s%s"):format(
			tostring(patch.Key), vt,
			patch.HookMethod and "  |  hooked" or ""))
		table.insert(lines, ("-- └ Table: %s"):format(tblPath))
		if vt == "function" and patch.HookMethod == "hookfunction" then
			table.insert(lines, "do")
			table.insert(lines, "\tlocal _tbl = " .. tblPath)
			table.insert(lines, "\tlocal _orig = rawget(_tbl, " .. keyStr .. ")")
			table.insert(lines, "\tif _orig and hookfunction then")
			table.insert(lines, "\t\thookfunction(_orig, " .. valStr .. ")")
			table.insert(lines, "\telse")
			table.insert(lines, "\t\trawset(_tbl, " .. keyStr .. ", " .. valStr .. ")")
			table.insert(lines, "\tend")
			table.insert(lines, "end")
		elseif patch.Frozen then
			table.insert(lines, "do")
			table.insert(lines, "\tlocal _tbl = " .. tblPath)
			table.insert(lines, "\tlocal _val = " .. valStr)
			table.insert(lines, "\tgame:GetService(\"RunService\").Heartbeat:Connect(function()")
			table.insert(lines, "\t\tpcall(function()")
			table.insert(lines, "\t\t\tif setreadonly then setreadonly(_tbl, false) end")
			table.insert(lines, "\t\t\trawset(_tbl, " .. keyStr .. ", _val)")
			table.insert(lines, "\t\t\tif setreadonly then setreadonly(_tbl, true) end")
			table.insert(lines, "\t\tend)")
			table.insert(lines, "\tend)")
			table.insert(lines, "end")
		else
			table.insert(lines, "do")
			table.insert(lines, "\tlocal _tbl = " .. tblPath)
			table.insert(lines, "\tpcall(function()")
			table.insert(lines, "\t\tif setreadonly then setreadonly(_tbl, false) end")
			table.insert(lines, "\t\trawset(_tbl, " .. keyStr .. ", " .. valStr .. ")")
			table.insert(lines, "\t\tif setreadonly then setreadonly(_tbl, true) end")
			table.insert(lines, "\tend)")
			table.insert(lines, "end")
		end
		return table.concat(lines, "\n")
	end

	function TI:ExportPatches(idsToExport)
		local patches = {}
		if idsToExport then
			for _, id in ipairs(idsToExport) do
				local p = self.State.ActivePatches[id]
				if p then table.insert(patches, p) end
			end
		else
			for _, p in pairs(self.State.ActivePatches) do
				table.insert(patches, p)
			end
		end
		if #patches == 0 then
			self:_showNotification("No patches to export", "warning")
			return
		end

		table.sort(patches, function(a, b) return a.Timestamp < b.Timestamp end)

		local groups = {}
		local order = {}
		for _, p in ipairs(patches) do
			if p.IsInstancePatch then continue end
			local key = p.RootScriptPath or "__unknown__"
			if not groups[key] then
				groups[key] = { scriptPath = key, scriptName = p.RootScriptName or key, patches = {} }
				table.insert(order, key)
			end
			table.insert(groups[key].patches, p)
		end

		local lines = {}
		local function L(s) table.insert(lines, s or "") end

		L("-- ╔══════════════════════════════════════════════════════════╗")
		L("-- ║   Overseer · Patch Export                                ║")
		L("-- ║   Generated : " .. (os.date and os.date("%Y-%m-%d %H:%M") or tostring(tick())) .. "            ║")
		L("-- ║   Patches   : " .. tostring(#patches) .. string.rep(" ", 43 - #tostring(#patches)) .. "║")
		L("-- ╚══════════════════════════════════════════════════════════╝")
		L()
		L("-- ── Runtime helpers ────────────────────────────────────────────────────")
		L("local function _write(tbl, key, val)")
		L("\tpcall(function()")
		L("\t\tif setreadonly then setreadonly(tbl, false) end")
		L("\t\trawset(tbl, key, val)")
		L("\t\tif setreadonly then setreadonly(tbl, true) end")
		L("\tend)")
		L("end")
		L("local function _freeze(tbl, key, val)")
		L("\t_write(tbl, key, val)")
		L("\tgame:GetService(\"RunService\").Heartbeat:Connect(function()")
		L("\t\t_write(tbl, key, val)")
		L("\tend)")
		L("end")
		L("local function _hook(orig, new)")
		L("\tif hookfunction then")
		L("\t\tpcall(hookfunction, orig, new)")
		L("\telse")
		L("\t\treturn false")
		L("\tend")
		L("\treturn true")
		L("end")
		L()

		for _, p in ipairs(patches) do
			if p.IsInstancePatch and p.TargetExpr then
				L()
				L("-- Instance: " .. tostring(p.Instance and p.Instance.Name or p.Key)
						.. "  [" .. tostring(p.Kind) .. "]")
				L("do")
				L("\tlocal _target = " .. p.TargetExpr)
				if p.Kind == "instance_attribute" then
					L("\t_target:SetAttribute(" .. string.format("%q", p.Attribute) .. ", " .. self:_serializeValue(p.NewValue) .. ")")
				else
					L("\t_target[" .. string.format("%q", p.Property) .. "] = " .. self:_serializeValue(p.NewValue))
				end
				L("end")
			end
		end

		for _, key in ipairs(order) do
			local g = groups[key]
			L("-- ── Module: " .. g.scriptName .. " ─────────────────────────────────────────")
			if key ~= "__unknown__" then
				L("-- Path: " .. key)
			end
			L("do")
			L("\tlocal M = require(game:GetService(\"ReplicatedStorage\"):FindFirstChild("
					.. string.format("%q", g.scriptName) .. ", true))")
			for _, p in ipairs(g.patches) do
				L()
				local subChain = p.PathStack or {}
				local tblExpr = "M"
				if #subChain > 0 then
					local parts = {}
					for _, part in ipairs(subChain) do
						if part:match("^[%a_][%w_]*$") then
							table.insert(parts, "." .. part)
						else
							table.insert(parts, "[" .. string.format("%q", tostring(part)) .. "]")
						end
					end
					tblExpr = "M" .. table.concat(parts)
				end
				local keyStr = type(p.Key) == "string"
					and string.format("%q", p.Key)
					or tostring(p.Key)
				local valStr = self:_serializeValue(p.NewValue)
				local vt = type(p.NewValue)
				L("\t-- " .. tostring(p.Key) .. "  [" .. vt .. (p.Frozen and ", frozen" or "") .. (p.HookMethod and ", hooked" or "") .. "]")
				if p.IsLSPatch and p.HookMethod == "setupvalue" then
					L("\t-- upvalue patch on closure — find by GC identity then setupvalue")
					L("\tdo")
					L("\t\tlocal _target = " .. self:_serializeValue(p.LSClosure))
					L("\t\tif setupvalue and _target then")
					L("\t\t\tpcall(setupvalue, _target, " .. tostring(p.LSUVIndex) .. ", " .. valStr .. ")")
					L("\t\telseif debug and debug.setupvalue and _target then")
					L("\t\t\tpcall(debug.setupvalue, _target, " .. tostring(p.LSUVIndex) .. ", " .. valStr .. ")")
					L("\t\tend")
					L("\tend")
				elseif p.IsLSPatch and p.HookMethod == "fenv" then
					L("\t-- fenv patch: scan GC for closures from this script and patch their environment")
					L("\tdo")
					L("\t\tlocal _key, _val = " .. keyStr .. ", " .. valStr)
					L("\t\tif getgc then")
					L("\t\t\tfor _, fn in ipairs(getgc(false) or {}) do")
					L("\t\t\t\tif type(fn) == \"function\" and getfenv then")
					L("\t\t\t\t\tpcall(function()")
					L("\t\t\t\t\t\tlocal fenv = getfenv(fn)")
					L("\t\t\t\t\t\tif type(fenv) == \"table\" and rawget(fenv, \"script\") == " .. string.format("%q", p.RootScriptName or "?") .. " then")
					L("\t\t\t\t\t\t\trawset(fenv, _key, _val)")
					L("\t\t\t\t\t\tend")
					L("\t\t\t\t\tend)")
					L("\t\t\t\tend")
					L("\t\t\tend")
					L("\t\tend")
					L("\tend")
				elseif vt == "function" and p.HookMethod == "hookfunction" then
					L("\tdo")
					L("\t\tlocal _orig = rawget(" .. tblExpr .. ", " .. keyStr .. ")")
					L("\t\tif not _hook(_orig, " .. valStr .. ") then")
					L("\t\t\t_write(" .. tblExpr .. ", " .. keyStr .. ", " .. valStr .. ")")
					L("\t\tend")
					L("\tend")
				elseif p.Frozen then
					L("\t_freeze(" .. tblExpr .. ", " .. keyStr .. ", " .. valStr .. ")")
				else
					L("\t_write(" .. tblExpr .. ", " .. keyStr .. ", " .. valStr .. ")")
				end
			end
			L()
			L("end")
			L()
		end

		local full = table.concat(lines, "\n")

		local saved = false
		local fname = "overseer_patches_" .. (os.date and os.date("%Y%m%d_%H%M%S") or tostring(math.floor(tick()))) .. ".lua"
		if writefile then
			pcall(function()
				writefile(fname, full)
				saved = true
			end)
		end
		local clipped = false
		pcall(function()
			if setclipboard then setclipboard(full)
			elseif toclipboard then toclipboard(full) end
			clipped = true
		end)
		local msg = "Exported " .. #patches .. " patch(es)"
		if saved then msg = msg .. " → " .. fname end
		if clipped then msg = msg .. " + clipboard" end
		self:_showNotification(msg, "success")
	end

	function TI:SelectAllPatches()
		for id in pairs(self.State.ActivePatches) do
			self.State.SelectedPatches[id] = true
		end
		self:RefreshPatchList()
		local sel = 0
		for _ in pairs(self.State.SelectedPatches) do sel += 1 end
		if self.State.UI and self.State.UI.PatchSelCount then
			self.State.UI.PatchSelCount.Text = sel > 0 and (sel .. " sel") or ""
		end
		self:_showNotification("Selected " .. sel .. " patch(es)", "info")
	end

	function TI:RemoveSelectedPatches()
		local toRemove = {}
		for id in pairs(self.State.SelectedPatches) do
			table.insert(toRemove, id)
		end
		if #toRemove == 0 then
			self:_showNotification("No patches selected", "warning")
			return
		end
		for _, id in ipairs(toRemove) do
			self:RemovePatch(id)
		end
		self.State.SelectedPatches = {}
		if self.State.UI and self.State.UI.PatchSelCount then
			self.State.UI.PatchSelCount.Text = ""
		end
		self:_showNotification("Removed " .. #toRemove .. " patch(es)", "success")
	end

	function TI:RefreshPatchList()
		if not self.State.UI then
			return
		end
		for _, c in ipairs(self.State.UI.PatchScroll:GetChildren()) do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
		local count = 0
		for id, patch in pairs(self.State.ActivePatches) do
			count += 1
			self:CreatePatchRow(id, patch)
		end
		self.State.UI.PatchCount.Text = "Patches: " .. count
	end
	function TI:CreatePatchRow(patchId, patch)
		local row = Instance.new("Frame", self.State.UI.PatchScroll)
		row.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
		row.BackgroundColor3 = patch.Frozen and Color3.fromRGB(255, 220, 220) or self.Config.BG_WHITE
		row.BorderSizePixel = 0
		local isSelected = self.State.SelectedPatches[patchId] == true
		local selBox = Instance.new("TextButton", row)
		selBox.Size = UDim2.fromOffset(12, 12)
		selBox.Position = UDim2.new(0.02, -6, 0.5, -6)
		selBox.BackgroundColor3 = isSelected and self.Config.ACCENT or self.Config.BG_WHITE
		selBox.Text = isSelected and "✓" or ""
		selBox.TextColor3 = Color3.new(1, 1, 1)
		selBox.Font = Enum.Font.SourceSansBold
		selBox.TextSize = 8
		selBox.BorderSizePixel = 0
		selBox.AutoButtonColor = false
		self:_createBorder(selBox, true)
		selBox.MouseButton1Click:Connect(function()
			if self.State.SelectedPatches[patchId] then
				self.State.SelectedPatches[patchId] = nil
				selBox.BackgroundColor3 = self.Config.BG_WHITE
				selBox.Text = ""
			else
				self.State.SelectedPatches[patchId] = true
				selBox.BackgroundColor3 = self.Config.ACCENT
				selBox.Text = "✓"
			end
			local sel = 0
			for _ in pairs(self.State.SelectedPatches) do sel += 1 end
			if self.State.UI and self.State.UI.PatchSelCount then
				self.State.UI.PatchSelCount.Text = sel > 0 and (sel .. " sel") or ""
			end
		end)
		local freezeBox = Instance.new("TextButton", row)
		freezeBox.Size = UDim2.fromOffset(12, 12)
		freezeBox.Position = UDim2.new(0.12, -6, 0.5, -6)
		freezeBox.BackgroundColor3 = self.Config.BG_WHITE
		freezeBox.Text = patch.Frozen and "X" or ""
		freezeBox.TextColor3 = self.Config.FROZEN_RED
		freezeBox.Font = Enum.Font.SourceSansBold
		freezeBox.TextSize = 10
		freezeBox.BorderSizePixel = 0
		freezeBox.AutoButtonColor = false
		self:_createBorder(freezeBox, true)
		freezeBox.MouseButton1Click:Connect(function()
			self:ToggleFreeze(patchId)
		end)
		local keyLbl = Instance.new("TextLabel", row)
		keyLbl.Size = UDim2.new(0.35, -4, 1, 0)
		keyLbl.Position = UDim2.new(0.20, 2, 0, 0)
		keyLbl.BackgroundTransparency = 1
		keyLbl.Text = patch.IsInstancePatch
			and ((patch.Instance and patch.Instance.Name or "?") .. "." .. tostring(patch.Key))
			or tostring(patch.Key)
		keyLbl.TextColor3 = self.Config.TEXT_BLACK
		keyLbl.Font = Enum.Font.SourceSans
		keyLbl.TextSize = 9
		keyLbl.TextXAlignment = Enum.TextXAlignment.Left
		keyLbl.TextTruncate = Enum.TextTruncate.AtEnd
		local valLbl = Instance.new("TextLabel", row)
		valLbl.Size = UDim2.new(0.30, -4, 1, 0)
		valLbl.Position = UDim2.new(0.55, 2, 0, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = tostring(patch.NewValue):sub(1, 20)
		valLbl.TextColor3 = self.Config.TEXT_BLACK
		valLbl.Font = Enum.Font.Code
		valLbl.TextSize = 9
		valLbl.TextXAlignment = Enum.TextXAlignment.Left
		valLbl.TextTruncate = Enum.TextTruncate.AtEnd
		local function buildSnippet()
			if patch.IsInstancePatch and patch.TargetExpr then
				local target = patch.TargetExpr
				local val = self:_serializeValue(patch.NewValue)
				if patch.Kind == "instance_attribute" then
					return "local _target = " .. target .. "\n_target:SetAttribute(" .. string.format("%q", patch.Attribute) .. ", " .. val .. ")"
				end
				return "local _target = " .. target .. "\n_target[" .. string.format("%q", patch.Property) .. "] = " .. val
			end
			local keyStr
			if type(patch.Key) == "string" then
				keyStr = string.format("%q", patch.Key)
			else
				keyStr = tostring(patch.Key)
			end

			local valStr
			local vt = type(patch.NewValue)
			if vt == "string" then
				valStr = string.format("%q", patch.NewValue)
			elseif vt == "boolean" or vt == "number" then
				valStr = tostring(patch.NewValue)
			elseif vt == "nil" then
				valStr = "nil"
			else
				valStr = "-- [" .. vt .. ": " .. tostring(patch.NewValue) .. "]"
			end

			local lines = {}
			table.insert(lines, "-- Patch: " .. tostring(patch.Key))
			table.insert(lines, "-- Type:  " .. vt)
			if patch.Frozen then
				table.insert(lines, "-- [Frozen — value is kept on Heartbeat]")
				table.insert(lines, "RunService.Heartbeat:Connect(function()")
				table.insert(lines, "\tpcall(function()")
				table.insert(lines, "\t\tif setreadonly then setreadonly(tbl, false) end")
				table.insert(lines, "\t\trawset(tbl, " .. keyStr .. ", " .. valStr .. ")")
				table.insert(lines, "\t\tif setreadonly then setreadonly(tbl, true) end")
				table.insert(lines, "\tend)")
				table.insert(lines, "end)")
			else
				table.insert(lines, "pcall(function()")
				table.insert(lines, "\tif setreadonly then setreadonly(tbl, false) end")
				table.insert(lines, "\trawset(tbl, " .. keyStr .. ", " .. valStr .. ")")
				table.insert(lines, "\tif setreadonly then setreadonly(tbl, true) end")
				table.insert(lines, "end)")
			end
			return table.concat(lines, "\n")
		end

		local copyBtn = self:_createButton(
			row, "Copy",
			UDim2.fromOffset(34, 16),
			UDim2.new(0.80, 0, 0.5, -8),
			function()
				local snippet = buildSnippet()
				local ok = pcall(function()
					if setclipboard then
						setclipboard(snippet)
					elseif toclipboard then
						toclipboard(snippet)
					end
				end)
				self:_showNotification(
					ok and ("Copied snippet for: " .. tostring(patch.Key)) or "Clipboard unavailable",
					ok and "success" or "warning"
				)
			end
		)
		copyBtn.TextSize = 9
		copyBtn.BackgroundColor3 = Color3.fromRGB(200, 230, 255)

		local del = self:_createButton(row, "X", UDim2.fromOffset(16, 16), UDim2.new(0.93, 0, 0.5, -8), function()
			self:RemovePatch(patchId)
		end)
		del.TextSize = 10
		del.Font = Enum.Font.SourceSansBold
		del.BackgroundColor3 = Color3.fromRGB(255, 200, 200)
	end
	local ROBLOX_MODULE_BLACKLIST = {
		["BaseCamera"] = true,
		["MouseLockController"] = true,
		["OrbitalCamera"] = true,
		["ControlModule"] = true,
		["CameraModule"] = true,
		["PlayerModule"] = true,
		["ClassicCamera"] = true,
		["Poppercam"] = true,
		["TransparencyController"] = true,
	}

	function TI:_attrToString(v)
		local t = typeof(v)
		if t == "string" then return string.format("%q", v), "string" end
		if t == "number" then return tostring(v), "number" end
		if t == "boolean" then return tostring(v), "boolean" end
		if t == "Vector3" then
			return ("(%g, %g, %g)"):format(v.X, v.Y, v.Z), "Vector3"
		end
		if t == "Vector2" then
			return ("(%g, %g)"):format(v.X, v.Y), "Vector2"
		end
		if t == "Color3" then
			return ("RGB(%d,%d,%d)"):format(
				math.floor(v.R * 255), math.floor(v.G * 255), math.floor(v.B * 255)), "Color3"
		end
		if t == "BrickColor" then return v.Name, "BrickColor" end
		if t == "UDim2" then
			return ("{%g,%g,%g,%g}"):format(
				v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset), "UDim2"
		end
		if t == "UDim" then return ("%g,%g"):format(v.Scale, v.Offset), "UDim" end
		if t == "NumberRange" then return ("%g..%g"):format(v.Min, v.Max), "NumberRange" end
		if t == "Rect" then
			return ("{%g,%g,%g,%g}"):format(v.Min.X, v.Min.Y, v.Max.X, v.Max.Y), "Rect"
		end
		if t == "CFrame" then
			return ("CFrame(%g,%g,%g)"):format(v.X, v.Y, v.Z), "CFrame"
		end
		return tostring(v), t
	end

	function TI:_parseAttrValue(str, origType)
		if origType == "boolean" then
			if str == "true" then return true end
			if str == "false" then return false end
			return nil, "Expected true/false"
		end
		if origType == "number" then
			local n = tonumber(str)
			if not n then return nil, "Expected number" end
			return n
		end
		if origType == "string" then
			return str:match('^"(.*)"$') or str:match("^'(.*)'$") or str
		end
		if origType == "Vector3" then
			local x, y, z = str:match("([%-%.%d]+)[,%s]+([%-%.%d]+)[,%s]+([%-%.%d]+)")
			if x then return Vector3.new(tonumber(x), tonumber(y), tonumber(z)) end
			return nil, "Expected x,y,z"
		end
		if origType == "Vector2" then
			local x, y = str:match("([%-%.%d]+)[,%s]+([%-%.%d]+)")
			if x then return Vector2.new(tonumber(x), tonumber(y)) end
			return nil, "Expected x,y"
		end
		if origType == "Color3" then
			local r, g, b = str:match("([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)")
			if r then
				local rv, gv, bv = tonumber(r), tonumber(g), tonumber(b)
				if rv > 1 or gv > 1 or bv > 1 then
					return Color3.fromRGB(rv, gv, bv)
				end
				return Color3.new(rv, gv, bv)
			end
			return nil, "Expected r,g,b"
		end
		if origType == "UDim2" then
			local a, b2, d2, e = str:match("([%-%.%d]+)[,%s]+([%-%.%d]+)[,%s]+([%-%.%d]+)[,%s]+([%-%.%d]+)")
			if a then return UDim2.new(tonumber(a), tonumber(b2), tonumber(d2), tonumber(e)) end
			return nil, "Expected xs,xo,ys,yo"
		end
		if origType == "NumberRange" then
			local mn, mx = str:match("([%-%.%d]+)[%.%.,%s]+([%-%.%d]+)")
			if mn then return NumberRange.new(tonumber(mn), tonumber(mx)) end
			return nil, "Expected min..max"
		end
		return tonumber(str) or str
	end

	function TI:_buildAttrRow(parent, obj, attrName, attrVal, rowColor)
		local ROW_H = 22
		local row = Instance.new("Frame", parent)
		row.Size = UDim2.new(1, -2, 0, ROW_H)
		row.BackgroundColor3 = rowColor or self.Config.BG_WHITE
		row.BorderSizePixel = 0
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 2)

		local displayStr, typeName = self:_attrToString(attrVal)
		local typeColors = {
			string = Color3.fromRGB(134, 239, 172),
			number = Color3.fromRGB(251, 191, 36),
			boolean = Color3.fromRGB(56, 189, 248),
			Vector3 = Color3.fromRGB(192, 132, 252),
			Vector2 = Color3.fromRGB(192, 132, 252),
			Color3 = Color3.fromRGB(248, 113, 113),
			UDim2 = Color3.fromRGB(167, 139, 250),
		}
		local typeColor = typeColors[typeName] or self.Config.TEXT_GRAY

		local badge = Instance.new("TextLabel", row)
		badge.Size = UDim2.fromOffset(48, ROW_H - 2)
		badge.Position = UDim2.fromOffset(1, 1)
		badge.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
		badge.BorderSizePixel = 0
		badge.Text = typeName:sub(1, 6)
		badge.TextColor3 = typeColor
		badge.Font = Enum.Font.Code
		badge.TextSize = 8
		Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 2)

		local nameLbl = Instance.new("TextLabel", row)
		nameLbl.Size = UDim2.new(0.35, -52, 1, 0)
		nameLbl.Position = UDim2.fromOffset(52, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = attrName
		nameLbl.TextColor3 = self.Config.TEXT_BLACK
		nameLbl.Font = Enum.Font.GothamMedium
		nameLbl.TextSize = 10
		nameLbl.TextXAlignment = Enum.TextXAlignment.Left
		nameLbl.TextTruncate = Enum.TextTruncate.AtEnd

		local valLbl = Instance.new("TextLabel", row)
		valLbl.Size = UDim2.new(0.65, -95, 1, 0)
		valLbl.Position = UDim2.new(0.35, 0, 0, 0)
		valLbl.BackgroundTransparency = 1
		valLbl.Text = displayStr
		valLbl.TextColor3 = typeColor
		valLbl.Font = Enum.Font.Code
		valLbl.TextSize = 9
		valLbl.TextXAlignment = Enum.TextXAlignment.Left
		valLbl.TextTruncate = Enum.TextTruncate.AtEnd

		local editBtn = self:_createButton(row, "Edit",
			UDim2.fromOffset(36, 14), UDim2.new(1, -78, 0.5, -7),
			function()
				valLbl.Visible = false
				local box = Instance.new("TextBox", row)
				box.Size = UDim2.new(0.65, -95, 1, 0)
				box.Position = UDim2.new(0.35, 0, 0, 0)
				box.BackgroundColor3 = Color3.fromRGB(16, 20, 30)
				box.BorderSizePixel = 0
				box.Text = displayStr:gsub('^"', ""):gsub('"$', "")
				box.TextColor3 = Color3.new(1, 1, 1)
				box.Font = Enum.Font.Code
				box.TextSize = 9
				box.ClearTextOnFocus = false
				box:CaptureFocus()
				box.FocusLost:Connect(function(enter)
					local raw = box.Text
					box:Destroy()
					valLbl.Visible = true
					if not enter or raw == displayStr then return end
					local parsed, err = self:_parseAttrValue(raw, typeName)
					if err then
						self:_showNotification("Parse error: " .. err, "error")
						return
					end
					local ok2, e2 = pcall(function()
						obj:SetAttribute(attrName, parsed)
					end)
					if ok2 then
						local newStr = self:_attrToString(parsed)
						valLbl.Text = newStr
						self:_showNotification(
							obj.Name .. "." .. attrName .. " = " .. tostring(parsed), "success")
						self:PatchInstanceAttribute(obj, attrName, parsed, false)
					else
						self:_showNotification("SetAttribute failed: " .. tostring(e2), "error")
					end
				end)
		end)
		editBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 160)
		editBtn.TextSize = 8

		local delBtn = self:_createButton(row, "✕",
			UDim2.fromOffset(18, 14), UDim2.new(1, -38, 0.5, -7),
			function()
				local patchId, err = self:PatchInstanceAttribute(obj, attrName, nil, false)
				if patchId then
					row:Destroy()
					self:_showNotification("Deleted attribute: " .. attrName, "success")
				else
					self:_showNotification("Cannot delete attribute: " .. tostring(err), "error")
				end
		end)
		delBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
		delBtn.TextSize = 8

		return row
	end

	function TI:_buildAddAttrRow(parent, obj)
		local row = Instance.new("Frame", parent)
		row.Size = UDim2.new(1, -2, 0, 24)
		row.BackgroundColor3 = Color3.fromRGB(20, 30, 20)
		row.BorderSizePixel = 0
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 2)

		local nameBox = Instance.new("TextBox", row)
		nameBox.Size = UDim2.new(0.38, -4, 0, 16)
		nameBox.Position = UDim2.fromOffset(4, 4)
		nameBox.BackgroundColor3 = Color3.fromRGB(16, 22, 16)
		nameBox.BorderSizePixel = 0
		nameBox.PlaceholderText = "AttrName"
		nameBox.PlaceholderColor3 = Color3.fromRGB(60, 80, 60)
		nameBox.Text = ""
		nameBox.TextColor3 = Color3.new(1, 1, 1)
		nameBox.Font = Enum.Font.Code
		nameBox.TextSize = 9
		nameBox.ClearTextOnFocus = false
		Instance.new("UICorner", nameBox).CornerRadius = UDim.new(0, 2)

		local valBox = Instance.new("TextBox", row)
		valBox.Size = UDim2.new(0.38, -4, 0, 16)
		valBox.Position = UDim2.new(0.38, 4, 0, 4)
		valBox.BackgroundColor3 = Color3.fromRGB(16, 22, 16)
		valBox.BorderSizePixel = 0
		valBox.PlaceholderText = "value"
		valBox.PlaceholderColor3 = Color3.fromRGB(60, 80, 60)
		valBox.Text = ""
		valBox.TextColor3 = Color3.new(1, 1, 1)
		valBox.Font = Enum.Font.Code
		valBox.TextSize = 9
		valBox.ClearTextOnFocus = false
		Instance.new("UICorner", valBox).CornerRadius = UDim.new(0, 2)

		local addBtn = self:_createButton(row, "+ Add",
			UDim2.new(0.24, -8, 0, 16), UDim2.new(0.76, 4, 0, 4),
			function()
				local attrName = nameBox.Text
				if attrName == "" then
					self:_showNotification("Enter an attribute name", "warning")
					return
				end
				local raw = valBox.Text
				local parsed
				if raw == "true" then parsed = true
				elseif raw == "false" then parsed = false
				else parsed = tonumber(raw) or raw end
				local ok2, e2 = pcall(function() obj:SetAttribute(attrName, parsed) end)
				if ok2 then
					self:_buildAttrRow(parent, obj, attrName, parsed)
					nameBox.Text = ""; valBox.Text = ""
					self:_showNotification("Added: " .. attrName, "success")
					self:PatchInstanceAttribute(obj, attrName, parsed, false)
				else
					self:_showNotification("SetAttribute failed: " .. tostring(e2), "error")
				end
		end)
		addBtn.BackgroundColor3 = self.Config.SUCCESS_GREEN
		addBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
		addBtn.TextSize = 8
		return row
	end

	function TI:_buildAttrSection(parent, label, obj, accentColor)
		local HDR_H = 24
		accentColor = accentColor or self.Config.ACCENT
		local hdr = Instance.new("Frame", parent)
		hdr.Size = UDim2.new(1, -2, 0, HDR_H)
		hdr.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
		hdr.BorderSizePixel = 0
		Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 3)

		local accent = Instance.new("Frame", hdr)
		accent.Size = UDim2.new(0, 3, 1, 0)
		accent.BackgroundColor3 = accentColor
		accent.BorderSizePixel = 0

		local hdrLbl = Instance.new("TextLabel", hdr)
		hdrLbl.Size = UDim2.new(1, -60, 1, 0)
		hdrLbl.Position = UDim2.fromOffset(10, 0)
		hdrLbl.BackgroundTransparency = 1
		hdrLbl.Text = label
		hdrLbl.TextColor3 = accentColor
		hdrLbl.Font = Enum.Font.GothamBold
		hdrLbl.TextSize = 10
		hdrLbl.TextXAlignment = Enum.TextXAlignment.Left

		local attrs = {}
		pcall(function() attrs = obj:GetAttributes() end)
		local n = 0; for _ in pairs(attrs) do n += 1 end
		local countLbl = Instance.new("TextLabel", hdr)
		countLbl.Size = UDim2.fromOffset(50, HDR_H)
		countLbl.Position = UDim2.new(1, -54, 0, 0)
		countLbl.BackgroundTransparency = 1
		countLbl.Text = n .. " attr"
		countLbl.TextColor3 = self.Config.TEXT_GRAY
		countLbl.Font = Enum.Font.Gotham
		countLbl.TextSize = 9
		countLbl.TextXAlignment = Enum.TextXAlignment.Right

		return hdr
	end

	function TI:RefreshAttrPanel()
		local ui = self.State.UI
		if not ui or not ui.AttrScroll then return end

		for _, ch in ipairs(ui.AttrScroll:GetChildren()) do
			if not ch:IsA("UIListLayout") then ch:Destroy() end
		end

		local lp = Players.LocalPlayer
		if not lp then
			self:_showNotification("LocalPlayer not found", "error")
			return
		end

		local lpColor = Color3.fromRGB(56, 189, 248)
		self:_buildAttrSection(ui.AttrScroll, "LocalPlayer  ·  " .. lp.Name, lp, lpColor)

		local lpAttrs = {}
		pcall(function() lpAttrs = lp:GetAttributes() end)
		local lpKeys = {}
		for k in pairs(lpAttrs) do table.insert(lpKeys, k) end
		table.sort(lpKeys)

		local rowToggle = false
		if #lpKeys == 0 then
			local emptyLbl = Instance.new("TextLabel", ui.AttrScroll)
			emptyLbl.Size = UDim2.new(1, -2, 0, 18)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Text = "  (no attributes)"
			emptyLbl.TextColor3 = self.Config.TEXT_GRAY
			emptyLbl.Font = Enum.Font.Gotham
			emptyLbl.TextSize = 9
			emptyLbl.TextXAlignment = Enum.TextXAlignment.Left
		else
			for _, k in ipairs(lpKeys) do
				rowToggle = not rowToggle
				local bg = rowToggle
					and Color3.fromRGB(22, 28, 36) or Color3.fromRGB(18, 22, 30)
				self:_buildAttrRow(ui.AttrScroll, lp, k, lpAttrs[k], bg)
			end
		end
		self:_buildAddAttrRow(ui.AttrScroll, lp)

		local toolColor = Color3.fromRGB(251, 146, 60)
		local char = lp.Character
		local tools = {}
		if char then
			for _, v in ipairs(char:GetChildren()) do
				if v:IsA("Tool") then table.insert(tools, v) end
			end
		end
		local bp = lp:FindFirstChildOfClass("Backpack")
		if bp then
			for _, v in ipairs(bp:GetChildren()) do
				if v:IsA("Tool") then table.insert(tools, v) end
			end
		end

		if #tools == 0 then
			local noTools = Instance.new("TextLabel", ui.AttrScroll)
			noTools.Size = UDim2.new(1, -2, 0, 20)
			noTools.BackgroundTransparency = 1
			noTools.Text = "  (no tools equipped or in Backpack)"
			noTools.TextColor3 = self.Config.TEXT_GRAY
			noTools.Font = Enum.Font.Gotham
			noTools.TextSize = 9
			noTools.TextXAlignment = Enum.TextXAlignment.Left
		else
			for _, tool in ipairs(tools) do
				local inChar = tool.Parent == char
				local label = "Tool: " .. tool.Name .. (inChar and "  [equipped]" or "  [backpack]")
				self:_buildAttrSection(ui.AttrScroll, label, tool, toolColor)

				local toolAttrs = {}
				pcall(function() toolAttrs = tool:GetAttributes() end)
				local toolKeys = {}
				for k in pairs(toolAttrs) do table.insert(toolKeys, k) end
				table.sort(toolKeys)

				if #toolKeys == 0 then
					local emptyLbl2 = Instance.new("TextLabel", ui.AttrScroll)
					emptyLbl2.Size = UDim2.new(1, -2, 0, 16)
					emptyLbl2.BackgroundTransparency = 1
					emptyLbl2.Text = "  (no attributes on this tool)"
					emptyLbl2.TextColor3 = self.Config.TEXT_GRAY
					emptyLbl2.Font = Enum.Font.Gotham
					emptyLbl2.TextSize = 9
					emptyLbl2.TextXAlignment = Enum.TextXAlignment.Left
				else
					rowToggle = false
					for _, k in ipairs(toolKeys) do
						rowToggle = not rowToggle
						local bg = rowToggle
							and Color3.fromRGB(28, 24, 18) or Color3.fromRGB(22, 18, 14)
						self:_buildAttrRow(ui.AttrScroll, tool, k, toolAttrs[k], bg)
					end
				end
				self:_buildAddAttrRow(ui.AttrScroll, tool)
			end
		end

		if not self.State._AttrWatchConn then
			self.State._AttrWatchConn = lp.CharacterAdded:Connect(function()
				task.wait(0.5)
				if ui.AttrPanel and ui.AttrPanel.Visible then
					self:RefreshAttrPanel()
				end
			end)
		end
	end

	function TI:_instanceExpr(obj)
		if not obj or not obj:IsA("Instance") then return nil end
		local lp = Players.LocalPlayer
		if lp and obj == lp then
			return "game:GetService(\"Players\").LocalPlayer"
		end
		if lp and lp.Character and obj == lp.Character then
			return "game:GetService(\"Players\").LocalPlayer.Character"
		end
		if lp then
			local bp = lp:FindFirstChildOfClass("Backpack")
			if bp and (obj == bp or obj:IsDescendantOf(bp)) then
				local rel = {}
				local cur = obj
				while cur and cur ~= bp do
					table.insert(rel, 1, cur.Name)
					cur = cur.Parent
				end
				local e = "game:GetService(\"Players\").LocalPlayer:FindFirstChildOfClass(\"Backpack\")"
				for _, n in ipairs(rel) do
					e = e .. ":FindFirstChild(" .. string.format("%q", n) .. ")"
				end
				return e
			end
			if lp.Character and obj:IsDescendantOf(lp.Character) then
				local rel = {}
				local cur = obj
				while cur and cur ~= lp.Character do
					table.insert(rel, 1, cur.Name)
					cur = cur.Parent
				end
				local e = "game:GetService(\"Players\").LocalPlayer.Character"
				for _, n in ipairs(rel) do
					e = e .. ":FindFirstChild(" .. string.format("%q", n) .. ")"
				end
				return e
			end
		end
		local ok, full = pcall(function() return obj:GetFullName() end)
		if not ok then return nil end
		local service, rest = full:match("^([^%.]+)%.(.+)$")
		if service and game:FindFirstChild(service) then
			local e = "game:GetService(" .. string.format("%q", service) .. ")"
			for part in rest:gmatch("[^%.]+") do
				e = e .. ":FindFirstChild(" .. string.format("%q", part) .. ")"
			end
			return e
		end
		return nil
	end

	function TI:_objectPropertyList(obj)
		if not obj or not obj:IsA("Instance") then return {} end
		local class = obj.ClassName
		local common = {
			"Name",
		}
		local byClass = {
			BasePart = { "Anchored", "CanCollide", "CanTouch", "CanQuery", "Transparency", "Reflectance", "Massless", "CastShadow", "Color", "Material", "Size", "CFrame", "Position", "Orientation" },
			Humanoid = { "WalkSpeed", "JumpPower", "UseJumpPower", "HipHeight", "AutoRotate", "MaxHealth", "Health", "PlatformStand", "Sit", "Jump", "DisplayDistanceType", "NameDisplayDistance", "HealthDisplayDistance" },
			Tool = { "Enabled", "RequiresHandle", "CanBeDropped", "ManualActivationOnly", "Grip", "GripPos", "GripForward", "GripRight", "GripUp" },
			Player = { "CameraMaxZoomDistance", "CameraMinZoomDistance", "DevEnableMouseLock", "Neutral" },
			Animation = { "AnimationId" },
			Sound = { "SoundId", "Volume", "PlaybackSpeed", "Looped", "Playing", "TimePosition", "RollOffMaxDistance", "RollOffMinDistance" },
			ParticleEmitter = { "Enabled", "Rate", "Lifetime", "Speed", "Size", "Transparency", "Color" },
			Trail = { "Enabled", "Lifetime", "MinLength", "Color", "Transparency" },
			Beam = { "Enabled", "Width0", "Width1", "Color", "Transparency", "Brightness" },
			Highlight = { "Enabled", "FillColor", "FillTransparency", "OutlineColor", "OutlineTransparency", "DepthMode" },
			Decal = { "Texture", "Transparency", "Color3" },
			Texture = { "Texture", "Transparency", "Color3", "StudsPerTileU", "StudsPerTileV", "OffsetStudsU", "OffsetStudsV" },
			ProximityPrompt = { "Enabled", "HoldDuration", "MaxActivationDistance", "RequiresLineOfSight", "KeyboardKeyCode", "ActionText", "ObjectText" },
			ClickDetector = { "MaxActivationDistance" },
			Camera = { "FieldOfView", "CameraType", "CFrame", "Focus" },
		}
		local result = {}
		local seen = {}
		for _, p in ipairs(common) do seen[p] = true; table.insert(result, p) end
		local exact = byClass[class]
		if exact then
			for _, p in ipairs(exact) do
				if not seen[p] then seen[p] = true; table.insert(result, p) end
			end
		elseif obj:IsA("BasePart") then
			for _, p in ipairs(byClass.BasePart) do
				if not seen[p] then seen[p] = true; table.insert(result, p) end
			end
		end
		return result
	end

	function TI:_objectValueString(v)
		local t = typeof(v)
		if t == "string" then return string.format("%q", v), t end
		if t == "number" or t == "boolean" then return tostring(v), t end
		if t == "Vector3" then return ("%.6g, %.6g, %.6g"):format(v.X, v.Y, v.Z), t end
		if t == "Vector2" then return ("%.6g, %.6g"):format(v.X, v.Y), t end
		if t == "Color3" then return ("%d, %d, %d"):format(math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5)), t end
		if t == "UDim2" then return ("%g, %d, %g, %d"):format(v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset), t end
		if t == "CFrame" then return ("%.6g, %.6g, %.6g"):format(v.X, v.Y, v.Z), t end
		if t == "EnumItem" then return tostring(v), t end
		if t == "BrickColor" then return v.Name, t end
		return tostring(v), t
	end

	function TI:_parseObjectValue(text, expected)
		text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if expected == "boolean" then
			if text == "true" then return true end
			if text == "false" then return false end
			return nil, "expected true or false"
		elseif expected == "number" then
			local n = tonumber(text)
			if not n then return nil, "expected number" end
			return n
		elseif expected == "string" then
			return text:match('^"(.*)"$') or text:match("^'(.*)'$") or text
		elseif expected == "Vector3" then
			local a, b, c = text:match("([%+%-%.%deE]+)[,%s]+([%+%-%.%deE]+)[,%s]+([%+%-%.%deE]+)")
			if a then return Vector3.new(tonumber(a), tonumber(b), tonumber(c)) end
			return nil, "expected x,y,z"
		elseif expected == "Vector2" then
			local a, b = text:match("([%+%-%.%deE]+)[,%s]+([%+%-%.%deE]+)")
			if a then return Vector2.new(tonumber(a), tonumber(b)) end
			return nil, "expected x,y"
		elseif expected == "Color3" then
			local a, b, c = text:match("([%d%.]+)[,%s]+([%d%.]+)[,%s]+([%d%.]+)")
			if a then
				a, b, c = tonumber(a), tonumber(b), tonumber(c)
				if a > 1 or b > 1 or c > 1 then return Color3.fromRGB(a, b, c) end
				return Color3.new(a, b, c)
			end
			return nil, "expected r,g,b"
		elseif expected == "UDim2" then
			local a, b, c, d = text:match("([%+%-%.%deE]+)[,%s]+([%+%-%.%deE]+)[,%s]+([%+%-%.%deE]+)[,%s]+([%+%-%.%deE]+)")
			if a then return UDim2.new(tonumber(a), tonumber(b), tonumber(c), tonumber(d)) end
			return nil, "expected scaleX,offsetX,scaleY,offsetY"
		elseif expected == "CFrame" then
			local a, b, c = text:match("([%+%-%.%deE]+)[,%s]+([%+%-%.%deE]+)[,%s]+([%+%-%.%deE]+)")
			if a then return CFrame.new(tonumber(a), tonumber(b), tonumber(c)) end
			return nil, "expected x,y,z"
		elseif expected == "EnumItem" then
			local et, item = text:match("^Enum%.([%w_]+)%.([%w_]+)$")
			if et and item and Enum[et] and Enum[et][item] then return Enum[et][item] end
			return nil, "expected Enum.Type.Item"
		end
		return nil, "unsupported property type: " .. tostring(expected)
	end

	function TI:_recordInstancePatch(kind, obj, key, original, newValue, freeze)
		local id = self:_generateUID()
		local expr = self:_instanceExpr(obj)
		local patch = {
			ID = id,
			Kind = kind,
			Instance = obj,
			Target = obj,
			Property = kind == "instance_property" and key or nil,
			Attribute = kind == "instance_attribute" and key or nil,
			Key = key,
			Original = original,
			NewValue = newValue,
			Frozen = freeze == true,
			Active = true,
			Connection = nil,
			HookMethod = nil,
			HookOriginalRef = nil,
			TargetExpr = expr,
			Timestamp = tick(),
			RootScriptPath = self.State.RootScriptPath,
			RootScriptName = self.State.RootScriptName,
			IsInstancePatch = true,
		}
		self.State.ActivePatches[id] = patch
		return patch
	end

	function TI:_patchValuesEqual(a, b)
		local ta, tb = typeof(a), typeof(b)
		if ta ~= tb then return false end
		if ta == "number" then
			return a == b or (a ~= a and b ~= b)
		end
		if ta == "Vector2" or ta == "Vector3" or ta == "CFrame" or ta == "Color3" or ta == "UDim2" then
			return a == b
		end
		return a == b
	end

	function TI:PatchInstanceProperty(obj, property, newValue, freeze)
		if not obj or not obj:IsA("Instance") then return false, "Target is not an Instance" end
		local original
		local okRead, readErr = pcall(function() original = obj[property] end)
		if not okRead then return false, "Cannot read " .. tostring(property) .. ": " .. tostring(readErr) end
		local okWrite, writeErr = pcall(function() obj[property] = newValue end)
		if not okWrite then return false, "Cannot write " .. tostring(property) .. ": " .. tostring(writeErr) end
		local verified = false
		pcall(function() verified = self:_patchValuesEqual(obj[property], newValue) end)
		if not verified then
			pcall(function() obj[property] = original end)
			return false, "Write was not verified"
		end

		local patch = self:_recordInstancePatch("instance_property", obj, property, original, newValue, freeze)
		if freeze then
			patch.Connection = RunService.Heartbeat:Connect(function()
				pcall(function() obj[property] = patch.NewValue end)
			end)
			self.State.FreezeList[patch.ID] = patch
		end
		self:RefreshPatchList()
		self:_showNotification("Property patched: " .. obj.Name .. "." .. property, "success")
		return patch.ID
	end

	function TI:PatchInstanceAttribute(obj, attrName, newValue, freeze)
		if not obj or not obj:IsA("Instance") then return false, "Target is not an Instance" end
		local original = obj:GetAttribute(attrName)
		local okWrite, writeErr = pcall(function() obj:SetAttribute(attrName, newValue) end)
		if not okWrite then return false, "Cannot set attribute: " .. tostring(writeErr) end
		local verified = false
		pcall(function() verified = self:_patchValuesEqual(obj:GetAttribute(attrName), newValue) end)
		if not verified then
			pcall(function() obj:SetAttribute(attrName, original) end)
			return false, "Attribute write was not verified"
		end
		local patch = self:_recordInstancePatch("instance_attribute", obj, attrName, original, newValue, freeze)
		if freeze then
			patch.Connection = RunService.Heartbeat:Connect(function()
				pcall(function() obj:SetAttribute(attrName, patch.NewValue) end)
			end)
			self.State.FreezeList[patch.ID] = patch
		end
		self:RefreshPatchList()
		return patch.ID
	end

	function TI:PatchObjectPropertyFromText(obj, property, text, freeze)
		local ok, current = pcall(function() return obj[property] end)
		if not ok then
			return false, "Property unavailable"
		end
		local expected = typeof(current)
		local value, err = self:_parseObjectValue(text, expected)
		if value == nil and expected ~= "string" then
			return false, err or "invalid value"
		end
		return self:PatchInstanceProperty(obj, property, value, freeze)
	end

	function TI:_getLocalTargets()
		local lp = Players.LocalPlayer
		local out, seen = {}, {}
		local function add(obj, kind)
			if obj and obj:IsA("Instance") and not seen[obj] then
				seen[obj] = true; table.insert(out, { Object = obj, Kind = kind or obj.ClassName })
			end
		end
		local function scan(root)
			if not root then return end
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("Humanoid") then add(d, "Humanoid") elseif d:IsA("Tool") then add(d, "Tool") elseif d:IsA("Animation") then add(d, "Animation") elseif d:IsA("Animator") then add(d, "Animator") elseif d:IsA("AnimationController") then add(d, "AnimationController") elseif d:IsA("Sound") then add(d, "Sound") elseif d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then add(d, d.ClassName) end
			end
		end
		add(lp, "Player")
		if lp and lp.Character then add(lp.Character, "Character"); scan(lp.Character) end
		local bp = lp and lp:FindFirstChildOfClass("Backpack")
		if bp then add(bp, "Backpack"); scan(bp) end
		for _, plr in ipairs(Players:GetPlayers()) do if plr ~= lp then add(plr, "Player"); if plr.Character then add(plr.Character, "Character"); scan(plr.Character) end end end
		if Workspace.CurrentCamera then add(Workspace.CurrentCamera, "Camera") end
		return out
	end

	function TI:_deepSummary(obj)
		local d = { Identity = {}, Attributes = {}, Tags = {}, Children = {}, Runtime = {} }
		if typeof(obj) ~= "Instance" then return d end
		d.Identity.ClassName = obj.ClassName; d.Identity.Name = obj.Name; pcall(function() d.Identity.FullName = obj:GetFullName() end); pcall(function() d.Identity.Parent = obj.Parent and obj.Parent:GetFullName() or "nil" end)
		local kids = obj:GetChildren(); d.Children.Count = #kids; d.Children.List = kids; d.Children.DescendantCount = #obj:GetDescendants(); d.Attributes = obj:GetAttributes(); pcall(function() d.Tags = CollectionService:GetTags(obj) end)
		if obj:IsA("Humanoid") then local ok, st = pcall(function() return obj:GetState().Name end); if ok then d.Runtime.State = st end end
		return d
	end
	function TI:_watchKey(obj, key, attr) return tostring(obj) .. "|" .. (attr and "A" or "P") .. "|" .. tostring(key) end
	function TI:AddWatch(obj, key, attr)
		if typeof(obj) ~= "Instance" then return false, "invalid target" end
		self.State.Watches = self.State.Watches or {}; local id = self:_watchKey(obj, key, attr); if self.State.Watches[id] then return false, "already watched" end
		local ok, v; if attr then ok = true; v = obj:GetAttribute(key) else ok, v = pcall(function() return obj[key] end) end; if not ok then return false, v end
		self.State.Watches[id] = { Id = id, Instance = obj, Key = key, Attribute = attr, Last = v, Changes = 0 }; return true
	end
	function TI:RemoveWatch(id) if self.State.Watches then self.State.Watches[id] = nil end end
	function TI:_pollWatches()
		local ws = self.State.Watches or {}; self.State.ChangeLog = self.State.ChangeLog or {}
		for id, w in pairs(ws) do
			if not w.Instance or not w.Instance.Parent then ws[id] = nil else
				local ok, v; if w.Attribute then ok = true; v = w.Instance:GetAttribute(w.Key) else ok, v = pcall(function() return w.Instance[w.Key] end) end
				if ok and not self:_patchValuesEqual(v, w.Last) then
					table.insert(self.State.ChangeLog, 1, { Instance = w.Instance, Path = pcall(function() return w.Instance:GetFullName() end) and w.Instance:GetFullName() or w.Instance.Name, Key = w.Key, Old = w.Last, New = v }); w.Last = v; w.Changes += 1; while #self.State.ChangeLog > 200 do table.remove(self.State.ChangeLog) end
				end
			end
		end
	end
	function TI:TakeObjectSnapshot(root)
		root = root or self.State.SelectedObject; if typeof(root) ~= "Instance" then return nil, "no instance selected" end
		local snap = { Root = root, Items = {} }; local function add(o) local props = {}; for _, k in ipairs(self:_objectPropertyList(o)) do local ok, v = pcall(function() return o[k] end); if ok then props[k] = v end end; snap.Items[o] = { Properties = props, Attributes = o:GetAttributes(), Name = o.Name, ClassName = o.ClassName } end
		add(root); for _, d in ipairs(root:GetDescendants()) do add(d) end; self.State.LastSnapshot = snap; return snap
	end
	function TI:DiffObjectSnapshot(old, root)
		if not old then return nil, "no snapshot" end; root = root or old.Root; local now = self:TakeObjectSnapshot(root); local d = { Added = {}, Removed = {}, Changed = {} }
		for o, n in pairs(now.Items) do local b = old.Items[o]; if not b then table.insert(d.Added, n) else for k, v in pairs(n.Properties) do if not self:_patchValuesEqual(v, b.Properties[k]) then table.insert(d.Changed, { Object = o, Kind = "Property", Key = k, Old = b.Properties[k], New = v }) end end; for k, v in pairs(n.Attributes) do if not self:_patchValuesEqual(v, b.Attributes[k]) then table.insert(d.Changed, { Object = o, Kind = "Attribute", Key = k, Old = b.Attributes[k], New = v }) end end end end
		for o, n in pairs(old.Items) do if not now.Items[o] then table.insert(d.Removed, n) end end; self.State.LastDiff = d; return d
	end
	function TI:_animationTracksFor(obj)
		local out = {}; local function add(a) if not a then return end; local ok, ts = pcall(function() return a:GetPlayingAnimationTracks() end); if ok then for _, t in ipairs(ts) do table.insert(out, t) end end end
		if obj:IsA("Animator") then add(obj) elseif obj:IsA("Humanoid") then add(obj:FindFirstChildOfClass("Animator")) elseif obj:IsA("Animation") then local c = obj.Parent and obj.Parent.Parent; if c then for _, x in ipairs(c:GetDescendants()) do if x:IsA("Animator") then add(x) end end end end; return out
	end
	function TI:ControlAnimationTrack(track, action)
		if not track then return false, "no track" end; return pcall(function() if action == "play" then track:Play() elseif action == "stop" then track:Stop() elseif action == "pause" then track:AdjustSpeed(0) elseif action == "resume" then track:AdjustSpeed(1) elseif action == "restart" then track:Stop(); track.TimePosition = 0; track:Play() end end)
	end
	function TI:RefreshObjectPanel()
		local ui = self.State.UI
		if not ui or not ui.TargetScroll then return end
		for _, ch in ipairs(ui.TargetScroll:GetChildren()) do
			if not ch:IsA("UIListLayout") then ch:Destroy() end
		end
		for _, entry in ipairs(self:_getLocalTargets()) do
			local obj, kind = entry.Object, entry.Kind
			local row = Instance.new("TextButton", ui.TargetScroll)
			row.Size = UDim2.new(1, -2, 0, 34)
			row.BackgroundColor3 = self.Config.BG_WHITE
			row.Text = ""
			row.BorderSizePixel = 0
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 3)
			local badge = Instance.new("TextLabel", row)
			badge.Size = UDim2.fromOffset(58, 16)
			badge.Position = UDim2.fromOffset(4, 9)
			badge.BackgroundColor3 = kind == "Animation" and Color3.fromRGB(168, 85, 247)
				or kind == "Tool" and Color3.fromRGB(251, 146, 60)
				or kind == "Humanoid" and Color3.fromRGB(56, 189, 248)
				or Color3.fromRGB(99, 102, 241)
			badge.Text = kind
			badge.TextColor3 = Color3.new(1, 1, 1)
			badge.Font = Enum.Font.GothamBold
			badge.TextSize = 8
			badge.BorderSizePixel = 0
			local name = Instance.new("TextLabel", row)
			name.Size = UDim2.new(1, -70, 0, 16)
			name.Position = UDim2.fromOffset(68, 2)
			name.BackgroundTransparency = 1
			name.Text = obj.Name
			name.TextColor3 = self.Config.TEXT_BLACK
			name.Font = Enum.Font.GothamMedium
			name.TextSize = 10
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.TextTruncate = Enum.TextTruncate.AtEnd
			local path = Instance.new("TextLabel", row)
			path.Size = UDim2.new(1, -70, 0, 13)
			path.Position = UDim2.fromOffset(68, 18)
			path.BackgroundTransparency = 1
			local ok, full = pcall(function() return obj:GetFullName() end)
			path.Text = ok and full or "?"
			path.TextColor3 = self.Config.TEXT_GRAY
			path.Font = Enum.Font.Code
			path.TextSize = 8
			path.TextXAlignment = Enum.TextXAlignment.Left
			path.TextTruncate = Enum.TextTruncate.AtEnd
			row.MouseButton1Click:Connect(function()
				self:ShowObjectEditor(obj)
			end)
		end
	end

	function TI:ShowObjectEditor(obj)
		local ui = self.State.UI
		if not ui or not ui.TargetPropertyScroll then return end
		self.State.SelectedObject = obj
		if self.State.UI then task.defer(function() self:RefreshDeepPanel(); self:RefreshAnimationPanel(); self:RefreshWatchPanel(); self:RefreshDiffPanel() end) end
		for _, ch in ipairs(ui.TargetPropertyScroll:GetChildren()) do
			if not ch:IsA("UIListLayout") then ch:Destroy() end
		end
		local ok, full = pcall(function() return obj:GetFullName() end)
		ui.TargetName.Text = (ok and full or obj.Name) .. "  [" .. obj.ClassName .. "]"
		for _, prop in ipairs(self:_objectPropertyList(obj)) do
			local okRead, current = pcall(function() return obj[prop] end)
			if not okRead then continue end
			local display, typeName = self:_objectValueString(current)
			local row = Instance.new("Frame", ui.TargetPropertyScroll)
			row.Size = UDim2.new(1, -2, 0, 23)
			row.BackgroundColor3 = self.Config.BG_WHITE
			row.BorderSizePixel = 0
			local lbl = Instance.new("TextLabel", row)
			lbl.Size = UDim2.new(.28, 0, 1, 0)
			lbl.Position = UDim2.fromOffset(5, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = prop
			lbl.TextColor3 = self.Config.TEXT_BLACK
			lbl.Font = Enum.Font.GothamMedium
			lbl.TextSize = 9
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			local val = Instance.new("TextBox", row)
			val.Size = UDim2.new(.52, -4, 1, 0)
			val.Position = UDim2.new(.28, 0, 0, 0)
			val.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
			val.BorderSizePixel = 0
			val.Text = display
			val.TextColor3 = self.Config.TEXT_BLACK
			val.Font = Enum.Font.Code
			val.TextSize = 8
			val.ClearTextOnFocus = false
			val.TextXAlignment = Enum.TextXAlignment.Left
			local apply = self:_createButton(row, "Set", UDim2.fromOffset(30, 16), UDim2.new(1, -70, .5, -8), function()
				local patchId, err = self:PatchObjectPropertyFromText(obj, prop, val.Text, false)
				if patchId then
					self:ShowObjectEditor(obj)
				else
					self:_showNotification(tostring(err), "error")
				end
			end)
			apply.TextSize = 8
			local frz = self:_createButton(row, "F", UDim2.fromOffset(24, 16), UDim2.new(1, -36, .5, -8), function()
				local patchId, err = self:PatchObjectPropertyFromText(obj, prop, val.Text, true)
				if patchId then
					self:ShowObjectEditor(obj)
				else
					self:_showNotification(tostring(err), "error")
				end
			end)
			frz.TextSize = 8
			frz.BackgroundColor3 = Color3.fromRGB(80, 120, 180)
		end
		local attrs = obj:GetAttributes()
		local keys = {}
		for k in pairs(attrs) do table.insert(keys, k) end
		table.sort(keys)
		if #keys > 0 then
			local sep = Instance.new("TextLabel", ui.TargetPropertyScroll)
			sep.Size = UDim2.new(1, -2, 0, 20)
			sep.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
			sep.Text = "ATTRIBUTES"
			sep.TextColor3 = self.Config.HIGHLIGHT
			sep.Font = Enum.Font.GothamBold
			sep.TextSize = 9
			sep.TextXAlignment = Enum.TextXAlignment.Left
			Instance.new("UIPadding", sep).PaddingLeft = UDim.new(0, 5)
			for _, k in ipairs(keys) do
				local v = attrs[k]
				local disp, typ = self:_objectValueString(v)
				local ar = Instance.new("Frame", ui.TargetPropertyScroll)
				ar.Size = UDim2.new(1, -2, 0, 23); ar.BackgroundColor3 = self.Config.BG_WHITE; ar.BorderSizePixel = 0
				local al = Instance.new("TextLabel", ar); al.Size = UDim2.new(.35, 0, 1, 0); al.Position = UDim2.fromOffset(5, 0)
				al.BackgroundTransparency = 1; al.Text = k; al.TextColor3 = self.Config.TEXT_BLACK; al.Font = Enum.Font.Code; al.TextSize = 8
				local av = Instance.new("TextBox", ar); av.Size = UDim2.new(.45, 0, 1, 0); av.Position = UDim2.new(.35, 0, 0, 0)
				av.BackgroundColor3 = Color3.fromRGB(18, 18, 24); av.BorderSizePixel = 0; av.Text = disp; av.TextColor3 = self.Config.TEXT_BLACK
				av.Font = Enum.Font.Code; av.TextSize = 8; av.ClearTextOnFocus = false
				local ab = self:_createButton(ar, "Set", UDim2.fromOffset(30, 16), UDim2.new(1, -34, .5, -8), function()
					local nv, er = self:_parseObjectValue(av.Text, typ)
					if nv == nil and typ ~= "string" then self:_showNotification(er or "invalid", "error"); return end
					local id, e = self:PatchInstanceAttribute(obj, k, nv, false)
					if id then self:ShowObjectEditor(obj) else self:_showNotification(e, "error") end
				end)
				ab.TextSize = 8
			end
		end
	end

	function TI:_clearWorkspacePanel(panel) if panel then for _, c in ipairs(panel:GetChildren()) do if not c:IsA("UIListLayout") then c:Destroy() end end end end
	function TI:RefreshDeepPanel()
		local ui = self.State.UI; if not ui or not ui.TargetDeepScroll then return end; self:_clearWorkspacePanel(ui.TargetDeepScroll); local o = self.State.SelectedObject; if not o then return end; local d = self:_deepSummary(o)
		local function row(t) local r = Instance.new("TextLabel", ui.TargetDeepScroll); r.Size = UDim2.new(1, -8, 0, 20); r.BackgroundColor3 = self.Config.BG_WHITE; r.Text = t; r.TextColor3 = self.Config.TEXT_BLACK; r.Font = Enum.Font.Code; r.TextSize = 8; r.TextXAlignment = Enum.TextXAlignment.Left; Instance.new("UIPadding", r).PaddingLeft = UDim.new(0, 5) end
		row("Class: " .. o.ClassName); row("Name: " .. o.Name); row("Path: " .. tostring(d.Identity.FullName)); row("Parent: " .. tostring(d.Identity.Parent)); row("Children: " .. d.Children.Count .. "   Descendants: " .. d.Children.DescendantCount); if d.Runtime.State then row("Humanoid State: " .. d.Runtime.State) end; if #d.Tags > 0 then row("Tags: " .. table.concat(d.Tags, ", ")) end
		for _, prop in ipairs(self:_objectPropertyList(o)) do local ok, v = pcall(function() return o[prop] end); if ok then row("PROPERTY  " .. prop .. " = " .. self:_objectValueString(v)) end end
		for k, v in pairs(d.Attributes) do row("ATTRIBUTE " .. k .. " = " .. self:_objectValueString(v)) end
	end
	function TI:RefreshAnimationPanel()
		local ui = self.State.UI; if not ui or not ui.TargetAnimScroll then return end; self:_clearWorkspacePanel(ui.TargetAnimScroll); local o = self.State.SelectedObject; if not o then return end
		for _, t in ipairs(self:_animationTracksFor(o)) do local r = Instance.new("Frame", ui.TargetAnimScroll); r.Size = UDim2.new(1, -8, 0, 62); r.BackgroundColor3 = self.Config.BG_WHITE; local l = Instance.new("TextLabel", r); l.Size = UDim2.new(1, -8, 0, 18); l.Position = UDim2.fromOffset(4, 2); l.BackgroundTransparency = 1; l.Text = (t.Animation and t.Animation.Name or "AnimationTrack"); l.TextColor3 = self.Config.TEXT_BLACK; l.Font = Enum.Font.GothamBold; l.TextSize = 9; l.TextXAlignment = Enum.TextXAlignment.Left; local i = Instance.new("TextLabel", r); i.Size = UDim2.new(1, -8, 0, 14); i.Position = UDim2.fromOffset(4, 19); i.BackgroundTransparency = 1; i.Text = string.format("Time %.2f / %.2f | Speed %.2f | Weight %.2f | %s", t.TimePosition, t.Length, t.Speed, t.WeightCurrent, tostring(t.Priority)); i.TextColor3 = self.Config.TEXT_GRAY; i.Font = Enum.Font.Code; i.TextSize = 7; i.TextXAlignment = Enum.TextXAlignment.Left; local x = 4; for _, a in ipairs({ { "Play", "play" }, { "Stop", "stop" }, { "Pause", "pause" }, { "Resume", "resume" }, { "Restart", "restart" } }) do local b = self:_createButton(r, a[1], UDim2.fromOffset(48, 16), UDim2.fromOffset(x, 39), function() self:ControlAnimationTrack(t, a[2]); task.defer(function() self:RefreshAnimationPanel() end) end); b.TextSize = 7; x += 50 end end
	end
	function TI:RefreshWatchPanel()
		local ui = self.State.UI; if not ui or not ui.TargetWatchScroll then return end; self:_clearWorkspacePanel(ui.TargetWatchScroll); local n = 0; for id, w in pairs(self.State.Watches or {}) do n += 1; local r = Instance.new("Frame", ui.TargetWatchScroll); r.Size = UDim2.new(1, -8, 0, 38); r.BackgroundColor3 = self.Config.BG_WHITE; local l = Instance.new("TextLabel", r); l.Size = UDim2.new(1, -45, 0, 18); l.Position = UDim2.fromOffset(4, 2); l.BackgroundTransparency = 1; l.Text = w.Instance.Name .. "." .. w.Key .. " = " .. tostring(w.Last); l.TextColor3 = self.Config.TEXT_BLACK; l.Font = Enum.Font.Code; l.TextSize = 8; l.TextXAlignment = Enum.TextXAlignment.Left; l.TextTruncate = Enum.TextTruncate.AtEnd; local b = self:_createButton(r, "×", UDim2.fromOffset(24, 18), UDim2.new(1, -29, .5, -9), function() self:RemoveWatch(id); self:RefreshWatchPanel() end); b.TextSize = 8 end; for _, e in ipairs(self.State.ChangeLog or {}) do local r = Instance.new("TextLabel", ui.TargetWatchScroll); r.Size = UDim2.new(1, -8, 0, 22); r.BackgroundColor3 = self.Config.BG_WHITE; r.Text = "CHANGE  " .. e.Path .. "." .. e.Key .. "  " .. tostring(e.Old) .. " → " .. tostring(e.New); r.TextColor3 = self.Config.TEXT_BLACK; r.Font = Enum.Font.Code; r.TextSize = 7; r.TextXAlignment = Enum.TextXAlignment.Left; r.TextTruncate = Enum.TextTruncate.AtEnd; Instance.new("UIPadding", r).PaddingLeft = UDim.new(0, 4) end
	end
	function TI:RefreshDiffPanel()
		local ui = self.State.UI; if not ui or not ui.TargetDiffScroll then return end; self:_clearWorkspacePanel(ui.TargetDiffScroll); local d = self.State.LastDiff; if not d then return end; local function row(t) local r = Instance.new("TextLabel", ui.TargetDiffScroll); r.Size = UDim2.new(1, -8, 0, 22); r.BackgroundColor3 = self.Config.BG_WHITE; r.Text = t; r.TextColor3 = self.Config.TEXT_BLACK; r.Font = Enum.Font.Code; r.TextSize = 7; r.TextXAlignment = Enum.TextXAlignment.Left; r.TextTruncate = Enum.TextTruncate.AtEnd; Instance.new("UIPadding", r).PaddingLeft = UDim.new(0, 4) end; row("Added " .. #d.Added .. " | Removed " .. #d.Removed .. " | Changed " .. #d.Changed); for _, x in ipairs(d.Added) do row("+ " .. x.ClassName .. " " .. x.Name) end; for _, x in ipairs(d.Removed) do row("- " .. x.ClassName .. " " .. x.Name) end; for _, x in ipairs(d.Changed) do row("~ " .. x.Kind .. " " .. x.Object.Name .. "." .. x.Key .. "  " .. tostring(x.Old) .. " → " .. tostring(x.New)) end
	end

	function TI:ScanLocalScripts()
		local ui = self.State.UI
		if not ui then return end
		for _, ch in ipairs(ui.ModuleScroll:GetChildren()) do
			if not ch:IsA("UIListLayout") then ch:Destroy() end
		end
		self.State.ModuleList = {}
		if ui.ModuleCount then
			ui.ModuleCount.Text = "Scanning LS..."
			ui.ModuleCount.TextColor3 = self.Config.TEXT_GRAY
		end
		task.spawn(function()
			local seen = {}
			local function tryAdd(obj)
				if seen[obj] then return end
				if not (obj:IsA("LocalScript") or obj:IsA("Script")) then return end
				seen[obj] = true
				self:AddLocalScriptToList(obj)
			end
			local roots = { Players.LocalPlayer, Workspace,
				game:GetService("StarterGui"), game:GetService("StarterPack"),
				game:GetService("ReplicatedStorage") }
			for _, root in ipairs(roots) do
				pcall(function()
					for _, d in ipairs(root:GetDescendants()) do tryAdd(d) end
				end)
				task.wait()
			end
			if getloadedmodules then
				local ok, mods = pcall(getloadedmodules)
				if ok and mods then
					for _, m in ipairs(mods) do
						pcall(function()
							if m:IsA("LocalScript") or m:IsA("Script") then
								tryAdd(m)
							end
						end)
					end
				end
			end
			local count = #self.State.ModuleList
			if ui.ModuleCount then
				ui.ModuleCount.Text = count .. " script" .. (count == 1 and "" or "s")
				ui.ModuleCount.TextColor3 = self.Config.SUCCESS_GREEN
			end
		end)
	end

	function TI:AddLocalScriptToList(ls)
		if not self.State.UI then return end
		local ROW_H = 40
		local row = Instance.new("TextButton", self.State.UI.ModuleScroll)
		row.Size = UDim2.new(1, -2, 0, ROW_H)
		row.BackgroundColor3 = self.Config.BG_WHITE
		row.Text = ""
		row.BorderSizePixel = 0
		row.AutoButtonColor = false
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 3)
		local badge = Instance.new("TextLabel", row)
		badge.Size = UDim2.fromOffset(22, 14)
		badge.Position = UDim2.new(0, 3, 0.5, -7)
		badge.BackgroundColor3 = ls:IsA("LocalScript")
			and Color3.fromRGB(251, 146, 60)
			or Color3.fromRGB(239, 68, 68)
		badge.Text = ls:IsA("LocalScript") and "LS" or "S"
		badge.TextColor3 = Color3.new(1, 1, 1)
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 8
		badge.BorderSizePixel = 0
		Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)
		local lbl = Instance.new("TextLabel", row)
		lbl.Size = UDim2.new(1, -30, 0, 20)
		lbl.Position = UDim2.fromOffset(28, 2)
		lbl.BackgroundTransparency = 1
		lbl.Text = ls.Name
		lbl.TextColor3 = self.Config.TEXT_BLACK
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		local ok, fp = pcall(function() return ls:GetFullName() end)
		local fullPath = ok and fp or ls.Name
		local pathLbl = Instance.new("TextLabel", row)
		pathLbl.Size = UDim2.new(1, -30, 0, 14)
		pathLbl.Position = UDim2.fromOffset(28, 22)
		pathLbl.BackgroundTransparency = 1
		pathLbl.Text = fullPath
		pathLbl.TextColor3 = self.Config.TEXT_GRAY
		pathLbl.Font = Enum.Font.Code
		pathLbl.TextSize = 9
		pathLbl.TextXAlignment = Enum.TextXAlignment.Left
		pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
		local function deselectAll()
			for _, ch in ipairs(self.State.UI.ModuleScroll:GetChildren()) do
				if ch:IsA("TextButton") then
					ch.BackgroundColor3 = self.Config.BG_WHITE
				end
			end
		end
		row.MouseButton1Click:Connect(function()
			deselectAll()
			row.BackgroundColor3 = Color3.fromRGB(180, 100, 30)
			self.State.SelectedLocalScript = ls
			self:LoadLocalScript(ls)
		end)
		row.MouseEnter:Connect(function()
			if row.BackgroundColor3 ~= Color3.fromRGB(180, 100, 30) then
				row.BackgroundColor3 = self.Config.BG_LIGHT
			end
		end)
		row.MouseLeave:Connect(function()
			if row.BackgroundColor3 ~= Color3.fromRGB(180, 100, 30) then
				row.BackgroundColor3 = self.Config.BG_WHITE
			end
		end)
		table.insert(self.State.ModuleList, {
			Script = ls, Row = row, Name = ls.Name, Path = fullPath,
		})
	end

	function TI:FindScriptClosures(ls)
		local results = {}
		if not getgc then return results end
		local ok, gc = pcall(getgc, false)
		if not ok or type(gc) ~= "table" then return results end
		local getinfo = debug and debug.getinfo
		local getupv = getupvalues or (debug and debug.getupvalues)
		local getfenv_ = getfenv
		local lsName = ls.Name
		local ok2, lsPath = pcall(function() return ls:GetFullName() end)
		lsPath = ok2 and lsPath or lsName
		for _, fn in ipairs(gc) do
			if type(fn) ~= "function" then continue end
			local match = false
			if getinfo then
				local ok3, info = pcall(getinfo, fn, "S")
				if ok3 and info and info.source then
					local src = info.source:gsub("^@", "")
					if src:find(lsName, 1, true) or src:find(lsPath, 1, true) then
						match = true
					end
				end
			end
			if not match and getfenv_ then
				local ok4, fenv = pcall(getfenv_, fn)
				if ok4 and fenv and type(fenv) == "table" then
					local ok5, fenvScript = pcall(function() return rawget(fenv, "script") end)
					if ok5 and fenvScript == ls then match = true end
				end
			end
			if match then
				local upvalues = {}
				if getupv then
					local ok6, uvs = pcall(getupv, fn)
					if ok6 and type(uvs) == "table" then
						upvalues = uvs
					end
				end
				local fenv = nil
				if getfenv_ then
					pcall(function() fenv = getfenv_(fn) end)
				end
				local info = {}
				if getinfo then
					pcall(function() info = getinfo(fn, "nSl") or {} end)
				end
				table.insert(results, {
					fn = fn,
					upvalues = upvalues,
					fenv = fenv,
					info = info,
					label = (info.name or "?") .. "  [" .. (info.source or "?") .. ":" .. (info.linedefined or "?") .. "]",
				})
			end
		end
		return results
	end

	function TI:GetScriptConnections(ls)
		local results = {}
		if not getconnections then return results end
		local function scanObj(obj)
			local ok, props = pcall(function()
				return {
					obj.AncestryChanged, obj.AttributeChanged,
					obj.ChildAdded, obj.ChildRemoved,
					obj.DescendantAdded, obj.DescendantRemoving,
				}
			end)
			for _, sigName in ipairs({ "Changed", "Fired", "OnClientEvent",
				"OnServerEvent", "InputBegan", "InputEnded", "MouseButton1Click" }) do
					pcall(function()
						local sig = (obj :: any)[sigName]
						if sig then
							local conns = getconnections(sig)
							for _, conn in ipairs(conns or {}) do
								table.insert(results, {
									object = obj,
									signal = sigName,
									conn = conn,
									enabled = conn.Enabled,
									fn = conn.Function,
								})
							end
						end
					end)
				end
		end
		pcall(function() scanObj(ls) end)
		pcall(function()
			for _, ch in ipairs(ls:GetDescendants()) do
				scanObj(ch)
			end
		end)
		return results
	end

	function TI:LoadLocalScript(ls)
		local ui = self.State.UI
		if not ui then return end
		local ok, fp = pcall(function() return ls:GetFullName() end)
		self.State.RootScriptPath = ok and fp or ls.Name
		self.State.RootScriptName = ls.Name
		self:_showNotification("Scanning: " .. ls.Name .. "...", "info")
		task.spawn(function()
			self.State.LSClosures = self:FindScriptClosures(ls)
			self.State.LSConnections = self:GetScriptConnections(ls)
			local ui2 = self.State.UI
			if ui2 and ui2.SVSwitchTab then
				ui2.SVSwitchTab("ls")
			end
			self:RefreshLSPanel()
			self:_showNotification(
				ls.Name .. "  →  " .. #self.State.LSClosures .. " closure(s)  /  "
					.. #self.State.LSConnections .. " connection(s)", "success")
		end)
	end

	function TI:PatchUpvalue(closure, uvIndex, uvName, newValue)
		local setupv = setupvalue or (debug and debug.setupvalue)
		if not setupv then
			self:_showNotification("setupvalue not available", "error")
			return false
		end
		local ok, err = pcall(setupv, closure.fn, uvIndex, newValue)
		if not ok then
			self:_showNotification("Upvalue patch failed: " .. tostring(err), "error")
			return false
		end
		local patchId = self:_generateUID()
		local snap = {}
		for _, v in ipairs(self.State.PathStack) do table.insert(snap, v) end
		local patch = {
			ID = patchId,
			Table = nil,
			Key = uvName or ("upv[" .. uvIndex .. "]"),
			Original = closure.upvalues[uvIndex],
			NewValue = newValue,
			Frozen = false,
			Type = type(newValue),
			Timestamp = tick(),
			Active = true,
			Connection = nil,
			HookMethod = "setupvalue",
			HookOriginalRef = nil,
			PathStack = snap,
			RootScriptPath = self.State.RootScriptPath,
			RootScriptName = self.State.RootScriptName,
			IsLSPatch = true,
			LSClosure = closure.fn,
			LSUVIndex = uvIndex,
		}
		self.State.ActivePatches[patchId] = patch
		self:RefreshPatchList()
		self:_showNotification("Upvalue patched: " .. tostring(uvName or uvIndex), "success")
		return true
	end

	function TI:PatchFenvKey(closure, key, newValue)
		local fenv = closure.fenv
		if type(fenv) ~= "table" then
			self:_showNotification("No fenv accessible on this closure", "error")
			return false
		end
		local original = rawget(fenv, key)
		rawset(fenv, key, newValue)
		local patchId = self:_generateUID()
		local snap = {}
		for _, v in ipairs(self.State.PathStack) do table.insert(snap, v) end
		local patch = {
			ID = patchId,
			Table = fenv,
			Key = key,
			Original = original,
			NewValue = newValue,
			Frozen = false,
			Type = type(newValue),
			Timestamp = tick(),
			Active = true,
			Connection = nil,
			HookMethod = "fenv",
			HookOriginalRef = nil,
			PathStack = snap,
			RootScriptPath = self.State.RootScriptPath,
			RootScriptName = self.State.RootScriptName,
			IsLSPatch = true,
		}
		self.State.ActivePatches[patchId] = patch
		self:RefreshPatchList()
		self:_showNotification("fenv." .. tostring(key) .. " patched", "success")
		return true
	end

	function TI:DisconnectConnection(connEntry)
		pcall(function() connEntry.conn:Disconnect() end)
		self:_showNotification("Disconnected: " .. connEntry.signal, "success")
	end

	function TI:RefreshLSPanel()
		local ui = self.State.UI
		if not ui or not ui.LSPanel then return end
		for _, ch in ipairs(ui.LSClosureScroll:GetChildren()) do
			if not ch:IsA("UIListLayout") then ch:Destroy() end
		end
		for _, ch in ipairs(ui.LSConnScroll:GetChildren()) do
			if not ch:IsA("UIListLayout") then ch:Destroy() end
		end
		ui.LSClosureCount.Text = #self.State.LSClosures .. " closure(s)"
		ui.LSConnCount.Text = #self.State.LSConnections .. " connection(s)"
		local getupv = getupvalues or (debug and debug.getupvalues)
		local getupvn = getupvalnames or (debug and debug.getupvalnames)
		for ci, closure in ipairs(self.State.LSClosures) do
			local hdr = Instance.new("TextButton", ui.LSClosureScroll)
			hdr.Size = UDim2.new(1, -2, 0, 22)
			hdr.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
			hdr.Text = ""
			hdr.BorderSizePixel = 0
			hdr.AutoButtonColor = false
			Instance.new("UICorner", hdr).CornerRadius = UDim.new(0, 3)
			local hdrLbl = Instance.new("TextLabel", hdr)
			hdrLbl.Size = UDim2.new(1, -70, 1, 0)
			hdrLbl.Position = UDim2.fromOffset(6, 0)
			hdrLbl.BackgroundTransparency = 1
			hdrLbl.Text = closure.label
			hdrLbl.TextColor3 = Color3.fromRGB(251, 146, 60)
			hdrLbl.Font = Enum.Font.GothamMedium
			hdrLbl.TextSize = 10
			hdrLbl.TextXAlignment = Enum.TextXAlignment.Left
			hdrLbl.TextTruncate = Enum.TextTruncate.AtEnd
			local hookBtn = self:_createButton(hdr, "Hook",
				UDim2.fromOffset(44, 14), UDim2.new(1, -48, 0.5, -7),
				function()
					self:_showNotification(
						"Select the closure then use the Script Viewer to write a replacement, then click Apply Hook", "info")
					if ui.SVSwitchTab then ui.SVSwitchTab("script") end
					self.State._PendingHookClosure = closure.fn
					ui.ScriptViewerOutput.Text =
						"-- Write your replacement function body here.\n" ..
						"-- It will be wrapped as: function(...) <your code> end\n" ..
						"-- Then click 'Apply Hook' to hook this closure.\n\n" ..
						"-- Original closure: " .. closure.label
			end)
			hookBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
			hookBtn.TextSize = 9
			local uvs = closure.upvalues or {}
			local uvnames = {}
			if getupvn then
				pcall(function()
					local names = getupvn(closure.fn)
					if type(names) == "table" then uvnames = names end
				end)
			end
			for uvIdx, uvVal in ipairs(uvs) do
				local uvName = uvnames[uvIdx] or ("upv[" .. uvIdx .. "]")
				local uvRow = Instance.new("Frame", ui.LSClosureScroll)
				uvRow.Size = UDim2.new(1, -2, 0, 20)
				uvRow.BackgroundColor3 = self.Config.BG_WHITE
				uvRow.BorderSizePixel = 0
				Instance.new("UICorner", uvRow).CornerRadius = UDim.new(0, 2)
				local stripe = Instance.new("Frame", uvRow)
				stripe.Size = UDim2.new(0, 2, 1, 0)
				stripe.BackgroundColor3 = Color3.fromRGB(251, 146, 60)
				stripe.BorderSizePixel = 0
				local uvLbl = Instance.new("TextLabel", uvRow)
				uvLbl.Size = UDim2.new(0.45, -10, 1, 0)
				uvLbl.Position = UDim2.fromOffset(8, 0)
				uvLbl.BackgroundTransparency = 1
				uvLbl.Text = uvName
				uvLbl.TextColor3 = self.Config.TEXT_GRAY
				uvLbl.Font = Enum.Font.Code
				uvLbl.TextSize = 9
				uvLbl.TextXAlignment = Enum.TextXAlignment.Left
				uvLbl.TextTruncate = Enum.TextTruncate.AtEnd
				local uvVal2 = Instance.new("TextLabel", uvRow)
				uvVal2.Size = UDim2.new(0.35, 0, 1, 0)
				uvVal2.Position = UDim2.new(0.45, 0, 0, 0)
				uvVal2.BackgroundTransparency = 1
				local vt = type(uvVal)
				uvVal2.Text = vt == "string" and string.format("%q", uvVal):sub(1, 30)
					or vt == "number" and tostring(uvVal)
					or vt == "boolean" and tostring(uvVal)
					or "[" .. vt .. "]"
				uvVal2.TextColor3 = vt == "number" and Color3.fromRGB(251, 191, 36)
					or vt == "string" and Color3.fromRGB(134, 239, 172)
					or vt == "boolean" and Color3.fromRGB(56, 189, 248)
					or self.Config.TEXT_GRAY
				uvVal2.Font = Enum.Font.Code
				uvVal2.TextSize = 9
				uvVal2.TextXAlignment = Enum.TextXAlignment.Left
				uvVal2.TextTruncate = Enum.TextTruncate.AtEnd
				local patchBtn = self:_createButton(uvRow, "Patch",
					UDim2.fromOffset(38, 14), UDim2.new(1, -42, 0.5, -7),
					function()
						uvVal2.Visible = false
						local box = Instance.new("TextBox", uvRow)
						box.Size = UDim2.new(0.35, 0, 1, 0)
						box.Position = UDim2.new(0.45, 0, 0, 0)
						box.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
						box.BorderSizePixel = 0
						box.Text = uvVal2.Text
						box.TextColor3 = Color3.new(1, 1, 1)
						box.Font = Enum.Font.Code
						box.TextSize = 9
						box.ClearTextOnFocus = false
						box:CaptureFocus()
						box.FocusLost:Connect(function(enter)
							local raw = box.Text
							box:Destroy()
							uvVal2.Visible = true
							if not enter then return end
							local parsed
							if raw == "true" then parsed = true
							elseif raw == "false" then parsed = false
							elseif raw == "nil" then parsed = nil
							else
								local n = tonumber(raw)
								if n then parsed = n
								else
									parsed = raw:match('^"(.*)"$') or raw:match("^'(.*)'$") or raw
								end
							end
							self:PatchUpvalue(closure, uvIdx, uvName, parsed)
							uvVal2.Text = tostring(parsed)
						end)
				end)
				patchBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 160)
				patchBtn.TextSize = 8
			end
			if closure.fenv and type(closure.fenv) == "table" then
				local fenvRow = Instance.new("Frame", ui.LSClosureScroll)
				fenvRow.Size = UDim2.new(1, -2, 0, 20)
				fenvRow.BackgroundColor3 = Color3.fromRGB(24, 32, 24)
				fenvRow.BorderSizePixel = 0
				Instance.new("UICorner", fenvRow).CornerRadius = UDim.new(0, 2)
				local fenvLbl = Instance.new("TextLabel", fenvRow)
				fenvLbl.Size = UDim2.new(1, -80, 1, 0)
				fenvLbl.Position = UDim2.fromOffset(6, 0)
				fenvLbl.BackgroundTransparency = 1
				fenvLbl.TextColor3 = self.Config.SUCCESS_GREEN
				fenvLbl.Font = Enum.Font.GothamMedium
				fenvLbl.TextSize = 9
				fenvLbl.TextXAlignment = Enum.TextXAlignment.Left
				local fenvKeys = 0
				for _ in pairs(closure.fenv) do fenvKeys += 1 end
				fenvLbl.Text = "fenv  (" .. fenvKeys .. " keys)"
				local diveBtn = self:_createButton(fenvRow, "Dive",
					UDim2.fromOffset(38, 14), UDim2.new(1, -84, 0.5, -7),
					function()
						self:DrillDown("fenv[" .. ci .. "]", closure.fenv)
						if ui.SVSwitchTab then ui.SVSwitchTab("inspector") end
				end)
				diveBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
				diveBtn.TextSize = 8
			end
			task.wait()
		end
		for _, conn in ipairs(self.State.LSConnections) do
			local row = Instance.new("Frame", ui.LSConnScroll)
			row.Size = UDim2.new(1, -2, 0, 22)
			row.BackgroundColor3 = self.Config.BG_WHITE
			row.BorderSizePixel = 0
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 3)
			local enabledDot = Instance.new("Frame", row)
			enabledDot.Size = UDim2.fromOffset(6, 6)
			enabledDot.Position = UDim2.new(0, 4, 0.5, -3)
			enabledDot.BackgroundColor3 = conn.enabled
				and self.Config.SUCCESS_GREEN or self.Config.FROZEN_RED
			enabledDot.BorderSizePixel = 0
			Instance.new("UICorner", enabledDot).CornerRadius = UDim.new(0.5, 0)
			local connLbl = Instance.new("TextLabel", row)
			connLbl.Size = UDim2.new(1, -130, 1, 0)
			connLbl.Position = UDim2.fromOffset(14, 0)
			connLbl.BackgroundTransparency = 1
			local objName = "?"
			pcall(function() objName = conn.object.Name end)
			connLbl.Text = objName .. "." .. conn.signal
			connLbl.TextColor3 = self.Config.TEXT_BLACK
			connLbl.Font = Enum.Font.Code
			connLbl.TextSize = 9
			connLbl.TextXAlignment = Enum.TextXAlignment.Left
			connLbl.TextTruncate = Enum.TextTruncate.AtEnd
			local dcBtn = self:_createButton(row, "Disc",
				UDim2.fromOffset(36, 14), UDim2.new(1, -80, 0.5, -7),
				function()
					self:DisconnectConnection(conn)
					enabledDot.BackgroundColor3 = self.Config.FROZEN_RED
			end)
			dcBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40)
			dcBtn.TextSize = 8
			local hookConnBtn = self:_createButton(row, "Hook",
				UDim2.fromOffset(36, 14), UDim2.new(1, -40, 0.5, -7),
				function()
					if conn.fn and hookfunction then
						self:_showNotification("Switch to Script tab and write a replacement, then Apply Hook", "info")
						self.State._PendingHookClosure = conn.fn
						if ui.SVSwitchTab then ui.SVSwitchTab("script") end
					else
						self:_showNotification("hookfunction not available", "error")
					end
			end)
			hookConnBtn.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
			hookConnBtn.TextSize = 8
		end
	end
	function TI:_moduleKey(ms)
		if typeof(ms) == "Instance" then
			local ok, full = pcall(function() return ms:GetFullName() end)
			if ok and full and full ~= "" then
				return "instance:" .. full
			end
			return "instance:" .. tostring(ms)
		end
		return tostring(ms)
	end

	function TI:_isKnownModule(ms)
		local key = self:_moduleKey(ms)
		if self.State.ModuleSeen[key] then
			return true
		end
		self.State.ModuleSeen[key] = true
		return false
	end

	function TI:ScanGCModules()
		local env = type(getgenv) == "function" and getgenv() or _G
		local getgcFn = type(env) == "table" and env.getgc or nil
		if type(getgcFn) ~= "function" then getgcFn = rawget(_G, "getgc") end
		if type(getgcFn) ~= "function" then return 0, "getgc unavailable" end

		local ok, objects = pcall(function() return getgcFn(false) end)
		if not ok or type(objects) ~= "table" then
			return 0, "getgc(false) unavailable"
		end

		local found = 0
		local checked = {}
		local function consider(obj)
			if typeof(obj) ~= "Instance" then return end
			local okClass, isModule = pcall(function() return obj:IsA("ModuleScript") end)
			if not okClass or not isModule or ROBLOX_MODULE_BLACKLIST[obj.Name] then return end
			local key = self:_moduleKey(obj)
			if checked[key] then return end
			checked[key] = true

			if not self:_isKnownModule(obj) then
				found += 1
				self:AddModuleToList(obj, "GC direct")
			else
				for _, md in ipairs(self.State.ModuleList) do
					if md.Script == obj then
						md.GC = true
						md.Source = "Hierarchy + GC"
						if md.SourceLabel then
							md.SourceLabel.Text = "GC"
							md.SourceLabel.Visible = true
						end
						break
					end
				end
			end
		end

		for i, obj in ipairs(objects) do
			consider(obj)
			if i % 50 == 0 then task.wait() end
		end

		self.State.GCModuleCount = found
		return found, nil
	end

	function TI:ScanModules()
		local ui = self.State.UI
		if not ui then return end
		for _, c in ipairs(ui.ModuleScroll:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		self.State.ModuleList = {}
		self.State.ModuleSeen = {}
		self.State.GCModuleCount = 0
		if ui.ModuleCount then
			ui.ModuleCount.Text = "Scanning..."
			ui.ModuleCount.TextColor3 = self.Config.TEXT_GRAY
		end
		task.spawn(function()
			local roots = { ReplicatedStorage, Players.LocalPlayer, Workspace }
			pcall(function()
				for _, plr in ipairs(Players:GetPlayers()) do
					table.insert(roots, plr)
				end
			end)
			for _, root in ipairs(roots) do
				if root then
					local ok, descendants = pcall(function() return root:GetDescendants() end)
					if ok then
						for i, obj in ipairs(descendants) do
							if obj:IsA("ModuleScript") and not ROBLOX_MODULE_BLACKLIST[obj.Name] then
								if not self:_isKnownModule(obj) then
									self:AddModuleToList(obj, "Hierarchy")
								end
							end
							if i % 100 == 0 then task.wait() end
						end
					end
					task.wait()
				end
			end

			local gcFound, gcErr = self:ScanGCModules()
			local count = #self.State.ModuleList
			if ui.ModuleCount then
				if gcErr then
					ui.ModuleCount.Text = count .. " module" .. (count == 1 and "" or "s") .. " • GC unavailable"
				else
					ui.ModuleCount.Text = count .. " module" .. (count == 1 and "" or "s") .. " • " .. gcFound .. " GC-only"
				end
				ui.ModuleCount.TextColor3 = self.Config.SUCCESS_GREEN
			end
			self:_showNotification("Found " .. count .. " modules" .. (gcFound > 0 and (" (" .. gcFound .. " GC-only)") or ""), "success")
		end)
	end
	function TI:AddModuleToList(ms, source)
		if not self.State.UI then return end
		local ROW_H = 40
		local BADGE_W = 40
		source = source or "Hierarchy"

		local row = Instance.new("TextButton", self.State.UI.ModuleScroll)
		row.Size = UDim2.new(1, -2, 0, ROW_H)
		row.BackgroundColor3 = self.Config.BG_WHITE
		row.Text = ""
		row.BorderSizePixel = 0
		row.AutoButtonColor = false

		local lbl = Instance.new("TextLabel", row)
		lbl.Size = UDim2.new(1, -(BADGE_W + 8), 0, 18)
		lbl.Position = UDim2.fromOffset(4, 2)
		lbl.BackgroundTransparency = 1
		lbl.Text = ms.Name
		lbl.TextColor3 = self.Config.TEXT_BLACK
		lbl.Font = Enum.Font.GothamMedium
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd

		local sourceLabel = Instance.new("TextLabel", row)
		sourceLabel.Name = "SourceLabel"
		sourceLabel.Size = UDim2.fromOffset(34, 14)
		sourceLabel.Position = UDim2.new(1, -(BADGE_W + 38), 0, 3)
		sourceLabel.BackgroundColor3 = Color3.fromRGB(90, 55, 150)
		sourceLabel.Text = "GC"
		sourceLabel.TextColor3 = Color3.new(1, 1, 1)
		sourceLabel.Font = Enum.Font.GothamBold
		sourceLabel.TextSize = 7
		sourceLabel.BorderSizePixel = 0
		sourceLabel.Visible = source ~= "Hierarchy"
		Instance.new("UICorner", sourceLabel).CornerRadius = UDim.new(0, 3)

		local fullPath = ms:GetFullName()
		local serviceAbbrev = {
			ReplicatedStorage = "RS",
			Players = "Plr",
			Workspace = "WS",
			ServerScriptService = "SSS",
			StarterGui = "SG",
			StarterPack = "SP",
		}
		local shortPath = fullPath:gsub("^(%a+)", function(svc)
			return serviceAbbrev[svc] or svc
		end)
		local pathLbl = Instance.new("TextLabel", row)
		pathLbl.Size = UDim2.new(1, -(BADGE_W + 8), 0, 14)
		pathLbl.Position = UDim2.fromOffset(4, 22)
		pathLbl.BackgroundTransparency = 1
		pathLbl.Text = shortPath
		pathLbl.TextColor3 = self.Config.TEXT_GRAY
		pathLbl.Font = Enum.Font.Code
		pathLbl.TextSize = 9
		pathLbl.TextXAlignment = Enum.TextXAlignment.Left
		pathLbl.TextTruncate = Enum.TextTruncate.AtEnd
		if source ~= "Hierarchy" then
			pathLbl.Text = "[" .. source .. "] " .. shortPath
		end

		local BADGE_COLORS = {
			["table"] = Color3.fromRGB(56, 189, 248),
			["function"] = Color3.fromRGB(251, 191, 36),
			["nil"] = Color3.fromRGB(120, 120, 140),
			["other"] = Color3.fromRGB(239, 68, 68),
			["?"] = Color3.fromRGB(60, 60, 80),
		}
		local badge = Instance.new("TextLabel", row)
		badge.Name = "ReturnBadge"
		badge.Size = UDim2.fromOffset(BADGE_W - 4, 16)
		badge.Position = UDim2.new(1, -(BADGE_W), 0.5, -8)
		badge.BackgroundColor3 = BADGE_COLORS["?"]
		badge.Text = "?"
		badge.TextColor3 = Color3.new(1, 1, 1)
		badge.Font = Enum.Font.GothamBold
		badge.TextSize = 8
		badge.BorderSizePixel = 0
		badge.TextXAlignment = Enum.TextXAlignment.Center
		Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)

		local function deselectAll()
			for _, child in ipairs(self.State.UI.ModuleScroll:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = self.Config.BG_WHITE
					for _, l in ipairs(child:GetChildren()) do
						if l:IsA("TextLabel") and l.Name ~= "ReturnBadge" then
							if l.Font == Enum.Font.GothamMedium or l.Font == Enum.Font.Code then
								l.TextColor3 = l.Font == Enum.Font.GothamMedium
									and self.Config.TEXT_BLACK
									or self.Config.TEXT_GRAY
							end
						end
					end
				end
			end
		end

		row.MouseButton1Click:Connect(function()
			deselectAll()
			row.BackgroundColor3 = self.Config.HIGHLIGHT
			lbl.TextColor3 = Color3.new(1, 1, 1)
			pathLbl.TextColor3 = Color3.fromRGB(180, 230, 255)
			self.State.SelectedModule = ms
			if self.State.UI.ScriptViewerName then
				self.State.UI.ScriptViewerScroll.CanvasPosition = Vector2.new(0, 0)
				self.State.UI.ScriptViewerName.Text = ms.Name .. "  (" .. fullPath .. ")"
				self.State.UI.ScriptViewerOutput.Text = "← Click Decompile to send '" .. ms.Name .. "' to lua.expert"
				self.State.UI.ScriptViewerStatus.Text = ""
			end
			self:LoadModule(ms, badge, BADGE_COLORS)
		end)
		row.MouseEnter:Connect(function()
			if row.BackgroundColor3 ~= self.Config.HIGHLIGHT then
				row.BackgroundColor3 = self.Config.BG_LIGHT
			end
		end)
		row.MouseLeave:Connect(function()
			if row.BackgroundColor3 ~= self.Config.HIGHLIGHT then
				row.BackgroundColor3 = self.Config.BG_WHITE
			end
		end)

		table.insert(self.State.ModuleList, {
			Script = ms,
			Row = row,
			Name = ms.Name,
			Path = fullPath,
			Badge = badge,
			Source = source,
			GC = source ~= "Hierarchy",
			SourceLabel = sourceLabel,
		})
	end
	function TI:LoadModule(ms)
		local success, result, done = false, nil, false
		task.spawn(function()
			success, result = pcall(require, ms)
			done = true
		end)
		local t = 0
		while not done and t < 2 do
			task.wait(0.1)
			t += 0.1
		end
		if not done then
			self:_showNotification("Timeout loading: " .. ms.Name, "warning")
			return
		end
		if not success then
			self:_showNotification("Error: " .. tostring(result), "error")
			return
		end
		if result == nil then
			result = { ["[Module]"] = ms.Name, ["[Returns]"] = "nil" }
		end
		if type(result) ~= "table" then
			result = { ["[Value]"] = result, ["[Type]"] = type(result) }
		end
		self.State._RootTable = result
		self.State.CurrentTable = result
		self.State.PathStack = {}
		self.State.VisitedTables = {}
		local ok, fp = pcall(function() return ms:GetFullName() end)
		self.State.RootScriptPath = ok and fp or ms.Name
		self.State.RootScriptName = ms.Name
		self:RefreshInspector()
		self:_showNotification("Loaded: " .. ms.Name, "success")
	end
	function TI:FilterModules(query)
		query = query:lower()
		for _, md in ipairs(self.State.ModuleList) do
			md.Row.Visible = query == "" or md.Name:lower():find(query, 1, true) ~= nil
		end
	end
	local ICON_B64 =
		"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"
	local _ICON_ASSET = nil
	local function _getIconAsset()
		if _ICON_ASSET then
			return _ICON_ASSET
		end
		if type(writefile) == "function" and type(getcustomasset) == "function" then
			local path = "zukamisc_icons/TI_logo.jpg"
			pcall(makefolder, "zukamisc_icons")
			pcall(function()
				local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
				local data = ICON_B64:gsub("[^" .. b .. "=]", "")
				local result = {}
				local i = 1
				while i <= #data do
					local c1 = (b:find(data:sub(i, i), 1, true) or 1) - 1
					local c2 = (b:find(data:sub(i + 1, i + 1), 1, true) or 1) - 1
					local c3 = data:sub(i + 2, i + 2) == "=" and 0 or ((b:find(data:sub(i + 2, i + 2), 1, true) or 1) - 1)
					local c4 = data:sub(i + 3, i + 3) == "=" and 0 or ((b:find(data:sub(i + 3, i + 3), 1, true) or 1) - 1)
					local n = c1 * 262144 + c2 * 4096 + c3 * 64 + c4
					result[#result + 1] = string.char(math.floor(n / 65536))
					if data:sub(i + 2, i + 2) ~= "=" then
						result[#result + 1] = string.char(math.floor((n % 65536) / 256))
					end
					if data:sub(i + 3, i + 3) ~= "=" then
						result[#result + 1] = string.char(n % 256)
					end
					i = i + 4
				end
				writefile(path, table.concat(result))
			end)
			local ok, asset = pcall(getcustomasset, path)
			if ok and asset and asset ~= "" then
				_ICON_ASSET = asset
				return asset
			end
		end
		_ICON_ASSET = ""
		return ""
	end
	local function _makeIconImage(parent, size, zIndex)
		local img = Instance.new("ImageLabel", parent)
		img.Size = UDim2.fromOffset(size, size)
		img.Position = UDim2.new(0.5, -size / 2, 0.5, -size / 2)
		img.BackgroundTransparency = 1
		img.Image = ""
		img.ZIndex = zIndex or 2
		img.ScaleType = Enum.ScaleType.Fit
		task.spawn(function()
			local asset = _getIconAsset()
			img.Image = asset
		end)
		return img
	end
	function TI:Minimize()
		local ui = self.State.UI
		if not ui or ui.Minimized then
			return
		end
		ui.Minimized = true
		ui._savedPosition = ui.Main.Position
		local offX = ui.Main.Position.X.Offset + ui.Main.AbsoluteSize.X + 40
		local slideOut = TweenService:Create(ui.Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(ui.Main.Position.X.Scale, offX, ui.Main.Position.Y.Scale, ui.Main.Position.Y.Offset),
		})
		slideOut:Play()
		slideOut.Completed:Connect(function()
			ui.Main.Visible = false
			ui.RestoreTab.Position = UDim2.new(1, 14, ui.RestoreTab.Position.Y.Scale, ui.RestoreTab.Position.Y.Offset)
			ui.RestoreTab.Visible = true
			TweenService:Create(ui.RestoreTab, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Position = UDim2.new(1, -34, ui.RestoreTab.Position.Y.Scale, ui.RestoreTab.Position.Y.Offset),
			}):Play()
		end)
	end
	function TI:Restore()
		local ui = self.State.UI
		if not ui or not ui.Minimized then
			return
		end
		ui.Minimized = false
		local savedPos = ui._savedPosition or UDim2.new(0.5, -530, 0.5, -360)
		TweenService:Create(ui.RestoreTab, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(1, 14, ui.RestoreTab.Position.Y.Scale, ui.RestoreTab.Position.Y.Offset),
		}):Play()
		task.delay(0.15, function()
			ui.RestoreTab.Visible = false
		end)
		ui.Main.Position = UDim2.new(
			savedPos.X.Scale,
			savedPos.X.Offset + ui.Main.AbsoluteSize.X + 40,
			savedPos.Y.Scale,
			savedPos.Y.Offset
		)
		ui.Main.Visible = true
		TweenService:Create(ui.Main, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = savedPos,
		}):Play()
	end
	function TI:ScanGC(filterType, searchText)
		local results = {}
		local seen = {}
		local function addResult(kind, label, ref)
			if seen[ref] then return end
			seen[ref] = true
			local t = type(ref)
			if filterType and filterType ~= "all" and t ~= filterType then return end
			if searchText and searchText ~= "" then
				if not label:lower():find(searchText:lower(), 1, true) then return end
			end
			table.insert(results, { kind = kind, label = label, ref = ref, valueType = t })
		end
		if type(getgc) == "function" then
			local ok, gc = pcall(getgc, true)
			if ok and gc then
				for i, v in ipairs(gc) do
					local t = type(v)
					if t == "table" or t == "function" then
						local label
						if t == "table" then
							local n = 0
							pcall(function()
								for _ in pairs(v) do n += 1; if n > 100 then break end end
							end)
							label = string.format("gc[%d]  {%d+ keys}", i, n)
						else
							local info = ""
							if debug and debug.getinfo then
								local ok2, di = pcall(debug.getinfo, v)
								if ok2 and di then
									info = string.format(" (%s:%s)", (di.source or "?"):sub(1, 18), di.linedefined or "?")
								end
							end
							label = string.format("gc[%d]  fn%s", i, info)
						end
						addResult("gc", label, v)
					end
				end
			end
		end
		if type(getreg) == "function" then
			local ok, reg = pcall(getreg)
			if ok and type(reg) == "table" then
				for k, v in pairs(reg) do
					local t = type(v)
					if t == "table" or t == "function" then
						addResult("reg", "reg[" .. tostring(k) .. "]", v)
					end
				end
			end
		end
		if type(getgenv) == "function" then
			local ok, genv = pcall(getgenv)
			if ok and type(genv) == "table" then
				for k, v in pairs(genv) do
					local t = type(v)
					if t == "table" or t == "function" then
						addResult("genv", "genv." .. tostring(k), v)
					end
				end
			end
		end
		local getupvals = (type(getupvalues) == "function" and getupvalues)
			or (debug and type(debug.getupvalues) == "function" and debug.getupvalues)
		if getupvals and type(getgc) == "function" then
			local ok2, gc2 = pcall(getgc, true)
			if ok2 and gc2 then
				for _, fn in ipairs(gc2) do
					if type(fn) == "function" then
						local ok3, upvals = pcall(getupvals, fn)
						if ok3 and type(upvals) == "table" then
							for upName, upVal in pairs(upvals) do
								local t = type(upVal)
								if t == "table" or t == "function" then
									local fnLabel = "?"
									if debug and debug.getinfo then
										local ok4, di = pcall(debug.getinfo, fn)
										if ok4 and di then
											fnLabel = (di.source or "?"):sub(1, 16) .. ":" .. (di.linedefined or "?")
										end
									end
									addResult("upv",
										string.format("upv[%s]  via %s", tostring(upName), fnLabel),
										upVal)
								end
							end
						end
					end
				end
			end
		end
		return results
	end

	function TI:PopulateGCPanel(filterType, searchText)
		local ui = self.State.UI
		if not ui or not ui.GCScroll then return end
		for _, c in ipairs(ui.GCScroll:GetChildren()) do
			if not c:IsA("UIListLayout") then c:Destroy() end
		end
		ui.GCStatus.Text = "Scanning..."
		ui.GCStatus.TextColor3 = self.Config.TEXT_GRAY
		task.spawn(function()
			local results = self:ScanGC(filterType, searchText)
			local shown = 0
			for i, entry in ipairs(results) do
				if i > 400 then break end
				shown += 1
				local row = Instance.new("Frame", ui.GCScroll)
				row.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
				row.BackgroundColor3 = self.Config.BG_WHITE
				row.BorderSizePixel = 0
				row.LayoutOrder = i
				local kindColors = {
					gc = Color3.fromRGB(99, 102, 241),
					reg = Color3.fromRGB(56, 189, 248),
					genv = Color3.fromRGB(34, 197, 94),
					upv = Color3.fromRGB(251, 191, 36),
				}
				local badge = Instance.new("TextLabel", row)
				badge.Size = UDim2.fromOffset(32, 14)
				badge.Position = UDim2.new(0, 2, 0.5, -7)
				badge.BackgroundColor3 = kindColors[entry.kind] or self.Config.ACCENT
				badge.Text = entry.kind
				badge.TextColor3 = Color3.new(0, 0, 0)
				badge.Font = Enum.Font.GothamBold
				badge.TextSize = 8
				badge.BorderSizePixel = 0
				Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 3)
				local typeIcon = Instance.new("TextLabel", row)
				typeIcon.Size = UDim2.fromOffset(14, self.Config.ROW_HEIGHT)
				typeIcon.Position = UDim2.new(0, 36, 0, 0)
				typeIcon.BackgroundTransparency = 1
				typeIcon.Text = entry.valueType == "table" and "T" or "F"
				typeIcon.TextColor3 = entry.valueType == "table"
					and Color3.fromRGB(56, 189, 248)
					or Color3.fromRGB(251, 191, 36)
				typeIcon.Font = Enum.Font.GothamBold
				typeIcon.TextSize = 10
				local lbl = Instance.new("TextLabel", row)
				lbl.Size = UDim2.new(1, -130, 1, 0)
				lbl.Position = UDim2.new(0, 52, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Text = entry.label
				lbl.TextColor3 = self.Config.TEXT_BLACK
				lbl.Font = Enum.Font.Code
				lbl.TextSize = 10
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextTruncate = Enum.TextTruncate.AtEnd
				if entry.valueType == "table" then
					local diveBtn = self:_createButton(row, "Dive",
						UDim2.fromOffset(36, 16), UDim2.new(1, -80, 0.5, -8),
						function()
							self:DrillDown(entry.label, entry.ref)
							if ui.SVSwitchTab then ui.SVSwitchTab("inspector") end
					end)
					diveBtn.TextSize = 9
					diveBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
				end
				local copyBtn = self:_createButton(row, "Copy",
					UDim2.fromOffset(36, 16), UDim2.new(1, -40, 0.5, -8),
					function()
						pcall(function()
							if setclipboard then setclipboard(entry.label)
							elseif toclipboard then toclipboard(entry.label) end
						end)
						self:_showNotification("Copied: " .. entry.label, "success")
				end)
				copyBtn.TextSize = 9
				copyBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 160)
				row.MouseEnter:Connect(function()
					row.BackgroundColor3 = self.Config.BG_LIGHT
				end)
				row.MouseLeave:Connect(function()
					row.BackgroundColor3 = self.Config.BG_WHITE
				end)
				task.wait()
			end
			ui.GCStatus.Text = string.format(
				"%d shown / %d total  (gc=%s  reg=%s  genv=%s  upv=%s)",
				shown, #results,
				type(getgc) == "function" and "✓" or "✗",
				type(getreg) == "function" and "✓" or "✗",
				type(getgenv) == "function" and "✓" or "✗",
				(type(getupvalues) == "function" or (debug and type(debug.getupvalues) == "function")) and "✓" or "✗"
			)
			ui.GCStatus.TextColor3 = self.Config.SUCCESS_GREEN
		end)
	end

	local DATA_KEY_HINTS = {
		coins = true, cash = true, money = true, currency = true, balance = true, level = true,
		xp = true, experience = true, inventory = true, items = true, weapons = true, tools = true,
		stats = true, statistics = true, profile = true, playerdata = true, player_data = true,
		data = true, datastore = true, datastores = true, settings = true, progress = true,
		abilities = true, skills = true, quests = true, quest = true, badges = true, rank = true,
		permissions = true, unlocked = true, owned = true, equipped = true, loadout = true,
		userid = true, user_id = true, displayname = true, display_name = true,
	}
	local DATA_MODULE_HINTS = {
		data = true, dataservice = true, datamanager = true, datastoreservice = true,
		profile = true, profileservice = true, playerdata = true, player_data = true,
		savedata = true, loaddata = true, save = true, persistence = true, storage = true,
	}

	function TI:_dataNameScore(name)
		local n = string.lower(tostring(name or "")):gsub("[^%w]", "")
		if DATA_MODULE_HINTS[n] then return 3 end
		for hint in pairs(DATA_MODULE_HINTS) do
			if #hint >= 4 and n:find(hint, 1, true) then return 2 end
		end
		return 0
	end

	function TI:_dataTableScore(tbl)
		if type(tbl) ~= "table" then return 0, {} end
		local score, hits = 0, {}
		local ok = pcall(function()
			local count = 0
			for k in pairs(tbl) do
				count += 1
				if count > 80 then break end
				local key = string.lower(tostring(k)):gsub("[^%w]", "")
				if DATA_KEY_HINTS[key] then
					score += 2
					hits[#hits + 1] = tostring(k)
				elseif #key >= 5 then
					for hint in pairs(DATA_KEY_HINTS) do
						if #hint >= 5 and key:find(hint, 1, true) then
							score += 1
							hits[#hits + 1] = tostring(k)
							break
						end
					end
				end
			end
		end)
		if not ok then return 0, {} end
		return score, hits
	end

	function TI:ScanDataWorkspace()
		local ui = self.State.UI
		if not ui or not ui.DataScroll then return end
		self:_clearWorkspacePanel(ui.DataScroll)
		if ui.DataStatus then
			ui.DataStatus.Text = "Scanning client-side data references..."
		end

		task.spawn(function()
			local results = {}
			local seen = {}
			local function add(kind, label, detail, payload)
				local key = kind .. "|" .. tostring(label) .. "|" .. tostring(detail)
				if seen[key] then return end
				seen[key] = true
				results[#results + 1] = { Kind = kind, Label = tostring(label), Detail = tostring(detail), Payload = payload }
			end

			local DSS = game:GetService("DataStoreService")
			add("SERVICE", "DataStoreService", "Available as a client service reference; persistent records are server-side.", DSS)
			local okMS, MSS = pcall(function() return game:GetService("MemoryStoreService") end)
			if okMS and MSS then add("SERVICE", "MemoryStoreService", "Service reference; MemoryStore operations are server-side.", MSS) end

			local roots = { ReplicatedStorage, Players.LocalPlayer, Workspace }
			local remoteCount = 0
			for _, root in ipairs(roots) do
				if root then
					local ok, descendants = pcall(function() return root:GetDescendants() end)
					if ok then
						for i, obj in ipairs(descendants) do
							if obj:IsA("ModuleScript") then
								local score = self:_dataNameScore(obj.Name)
								if score > 0 then
									add("MODULE", obj.Name, obj:GetFullName(), obj)
								end
							elseif obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
								local nscore = self:_dataNameScore(obj.Name)
								if nscore > 0 or obj.Name:lower():find("data", 1, true) or obj.Name:lower():find("save", 1, true) or obj.Name:lower():find("load", 1, true) then
									remoteCount += 1
									add("REMOTE", obj.Name, obj:GetFullName() .. " • " .. obj.ClassName, obj)
								end
							end
							if i % 150 == 0 then task.wait() end
						end
					end
				end
			end

			local env = type(getgenv) == "function" and getgenv() or _G
			local getgcFn = type(env) == "table" and env.getgc or nil
			if type(getgcFn) ~= "function" then getgcFn = rawget(_G, "getgc") end
			local gcTables = 0
			if type(getgcFn) == "function" then
				local ok, objects = pcall(function() return getgcFn(true) end)
				if ok and type(objects) == "table" then
					for i, obj in ipairs(objects) do
						if type(obj) == "table" then
							gcTables += 1
							local score, hits = self:_dataTableScore(obj)
							if score >= 3 then
								local preview = table.concat(hits, ", ", 1, math.min(#hits, 5))
								add("TABLE", "Live data table", preview ~= "" and (preview .. " • GC") or "GC table", obj)
							end
							if gcTables >= 750 then break end
						end
						if i % 50 == 0 then task.wait() end
					end
				end
			end

			for _, item in ipairs(results) do
				local row = Instance.new("TextButton", ui.DataScroll)
				row.Size = UDim2.new(1, -4, 0, 42)
				row.BackgroundColor3 = self.Config.BG_WHITE
				row.BorderSizePixel = 0
				row.Text = ""
				row.AutoButtonColor = false
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 3)
				local kind = Instance.new("TextLabel", row)
				kind.Size = UDim2.fromOffset(58, 18); kind.Position = UDim2.fromOffset(4, 3)
				kind.BackgroundTransparency = 1; kind.Text = item.Kind
				kind.TextColor3 = item.Kind == "TABLE" and self.Config.WARNING_ORANGE or self.Config.ACCENT
				kind.Font = Enum.Font.GothamBold; kind.TextSize = 8; kind.TextXAlignment = Enum.TextXAlignment.Left
				local name = Instance.new("TextLabel", row)
				name.Size = UDim2.new(1, -70, 0, 18); name.Position = UDim2.fromOffset(62, 3)
				name.BackgroundTransparency = 1; name.Text = item.Label
				name.TextColor3 = self.Config.TEXT_BLACK; name.Font = Enum.Font.GothamMedium
				name.TextSize = 10; name.TextXAlignment = Enum.TextXAlignment.Left; name.TextTruncate = Enum.TextTruncate.AtEnd
				local detail = Instance.new("TextLabel", row)
				detail.Size = UDim2.new(1, -116, 0, 15); detail.Position = UDim2.fromOffset(62, 22)
				detail.BackgroundTransparency = 1; detail.Text = item.Detail
				detail.TextColor3 = self.Config.TEXT_GRAY; detail.Font = Enum.Font.Code
				detail.TextSize = 8; detail.TextXAlignment = Enum.TextXAlignment.Left; detail.TextTruncate = Enum.TextTruncate.AtEnd
				if item.Kind == "TABLE" and type(item.Payload) == "table" then
					row.MouseButton1Click:Connect(function()
						self:InspectTable(item.Payload, "Live Data Table")
					end)
				elseif typeof(item.Payload) == "Instance" and item.Payload:IsA("ModuleScript") then
					row.MouseButton1Click:Connect(function()
						self:LoadModule(item.Payload)
					end)
				elseif typeof(item.Payload) == "Instance" then
					row.MouseButton1Click:Connect(function()
						self:ShowObjectEditor(item.Payload)
					end)
				end
			end
			if ui.DataStatus then
				ui.DataStatus.Text = string.format("%d references • %d GC tables sampled", #results, gcTables)
			end
		end)
	end

	function TI:CreateUI()
		if self.State.UI and self.State.UI.Main then
			self.State.UI.Main.Visible = true
			return
		end
		pcall(function()
			local old = CoreGui:FindFirstChild("TableInspector")
			if old then
				old:Destroy()
			end
		end)
		local sg = Instance.new("ScreenGui", CoreGui)
		sg.Name = "TableInspector"
		sg.ResetOnSpawn = false
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		local main = Instance.new("Frame", sg)
		main.Name = "Main"
		main.Size = UDim2.fromOffset(1060, 720)
		main.Position = UDim2.new(0.5, -530, 0.5, -360)
		main.BackgroundColor3 = self.Config.BG_PANEL
		main.BorderSizePixel = 0
		main.ClipsDescendants = false
		Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
		local mainStroke = Instance.new("UIStroke", main)
		mainStroke.Thickness = 2
		mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		local _rainbowHue = 0
		RunService.RenderStepped:Connect(function(dt)
			_rainbowHue = (_rainbowHue + dt * 0.18) % 1
			local c1 = Color3.fromHSV(_rainbowHue, 0.85, 1)
			local c2 = Color3.fromHSV((_rainbowHue + 0.33) % 1, 0.85, 1)
			local c3 = Color3.fromHSV((_rainbowHue + 0.66) % 1, 0.85, 1)
			local grad = Instance.new("UIGradient")
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, c1),
				ColorSequenceKeypoint.new(0.33, c2),
				ColorSequenceKeypoint.new(0.66, c3),
				ColorSequenceKeypoint.new(1, c1),
			})
			grad.Rotation = (_rainbowHue * 360) % 360
			local old = mainStroke:FindFirstChildOfClass("UIGradient")
			if old then old:Destroy() end
			grad.Parent = mainStroke
		end)
		local titleBar = Instance.new("Frame", main)
		titleBar.Size = UDim2.new(1, 0, 0, 32)
		titleBar.BackgroundColor3 = self.Config.BG_DARK
		titleBar.BorderSizePixel = 0
		Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)
		local accentBar = Instance.new("Frame", titleBar)
		accentBar.Size = UDim2.new(0, 3, 1, 0)
		accentBar.BackgroundColor3 = self.Config.ACCENT
		accentBar.BorderSizePixel = 0
		local title = Instance.new("TextLabel", titleBar)
		title.Size = UDim2.new(1, -100, 1, 0)
		title.Position = UDim2.fromOffset(14, 0)
		title.BackgroundTransparency = 1
		title.Text = "Overseer  ·  Inspector  ·  Editor  ·  Freeze  ·  GC/Upvalues"
		title.TextColor3 = self.Config.TEXT_BLACK
		title.Font = Enum.Font.GothamBold
		title.TextSize = 12
		title.TextXAlignment = Enum.TextXAlignment.Left
		self:_createButton(titleBar, "✕", UDim2.fromOffset(24, 20), UDim2.new(1, -28, 0, 6), function()
			main.Visible = false
		end)
		local minimizeBtn = self:_createButton(
			titleBar, "─", UDim2.fromOffset(24, 20), UDim2.new(1, -56, 0, 6),
			function() self:Minimize() end
		)
		local dragging, dragStart, startPos
		titleBar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = i.Position
				startPos = main.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				local d = i.Position - dragStart
				main.Position =
					UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
		local content = Instance.new("Frame", main)
		content.Size = UDim2.new(1, -12, 1, -40)
		content.Position = UDim2.fromOffset(6, 36)
		content.BackgroundTransparency = 1
		content.BorderSizePixel = 0
		local modPanel = Instance.new("Frame", content)
		modPanel.Size = UDim2.new(0.198, 0, 1, 0)
		modPanel.Position = UDim2.new(0, 0, 0, 0)
		modPanel.BackgroundColor3 = self.Config.BG_PANEL
		modPanel.BorderSizePixel = 0
		Instance.new("UICorner", modPanel).CornerRadius = UDim.new(0, 6)
		self:_createBorder(modPanel, false)
		local modTitle = Instance.new("TextLabel", modPanel)
		modTitle.Size = UDim2.new(1, -4, 0, 18)
		modTitle.Position = UDim2.fromOffset(2, 2)
		modTitle.BackgroundColor3 = self.Config.BG_DARK
		modTitle.BorderSizePixel = 0
		modTitle.Text = "Modules"
		modTitle.TextColor3 = self.Config.TEXT_BLACK
		modTitle.Font = Enum.Font.GothamBold
		modTitle.TextSize = 11
		modTitle.TextXAlignment = Enum.TextXAlignment.Left
		local mp = Instance.new("UIPadding", modTitle)
		mp.PaddingLeft = UDim.new(0, 4)
		self:_createBorder(modTitle, true)
		local modSearch = Instance.new("TextBox", modPanel)
		modSearch.Size = UDim2.new(1, -8, 0, 22)
		modSearch.Position = UDim2.fromOffset(4, 24)
		modSearch.BackgroundColor3 = self.Config.BG_WHITE
		modSearch.Text = ""
		modSearch.PlaceholderText = "Search modules..."
		modSearch.TextColor3 = self.Config.TEXT_BLACK
		modSearch.Font = Enum.Font.Gotham
		modSearch.TextSize = 11
		modSearch.TextXAlignment = Enum.TextXAlignment.Left
		modSearch.BorderSizePixel = 0
		modSearch.ClearTextOnFocus = false
		local msp = Instance.new("UIPadding", modSearch)
		msp.PaddingLeft = UDim.new(0, 4)
		self:_createBorder(modSearch, true)
		local rescanBtn = self:_createButton(
			modPanel, "Rescan",
			UDim2.new(0.5, -6, 0, 20),
			UDim2.fromOffset(4, 50),
			function()
				if self.State.LSMode then self:ScanLocalScripts() else self:ScanModules() end
			end
		)
		rescanBtn.TextSize = 10
		local lsModeBtn
		lsModeBtn = self:_createButton(
			modPanel, "LocalScripts",
			UDim2.new(0.5, -6, 0, 20),
			UDim2.new(0.5, 2, 0, 50),
			function()
				self.State.LSMode = not self.State.LSMode
				if self.State.LSMode then
					lsModeBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 20)
					lsModeBtn.Text = "← Modules"
					modTitle.Text = "LocalScripts"
					self:ScanLocalScripts()
				else
					lsModeBtn.BackgroundColor3 = self.Config.BG_LIGHT
					lsModeBtn.Text = "LocalScripts"
					modTitle.Text = "Modules"
					self:ScanModules()
				end
			end
		)
		lsModeBtn.TextSize = 9
		local modScroll = Instance.new("ScrollingFrame", modPanel)
		modScroll.Size = UDim2.new(1, -8, 1, -78)
		modScroll.Position = UDim2.fromOffset(4, 74)
		modScroll.BackgroundColor3 = self.Config.BG_WHITE
		modScroll.BorderSizePixel = 0
		modScroll.ScrollBarThickness = 4
		modScroll.ScrollBarImageColor3 = self.Config.ACCENT
		modScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		modScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		self:_createBorder(modScroll, true)
		local modList = Instance.new("UIListLayout", modScroll)
		modList.Padding = UDim.new(0, 2)
		local debounce
		modSearch.Changed:Connect(function(prop)
			if prop == "Text" then
				if debounce then
					task.cancel(debounce)
				end
				debounce = task.delay(0.25, function()
					self:FilterModules(modSearch.Text)
				end)
			end
		end)
		local inspPanel = Instance.new("Frame", content)
		inspPanel.Size = UDim2.new(0.6155, 0, 1, 0)
		inspPanel.Position = UDim2.new(0.2026, 0, 0, 0)
		inspPanel.BackgroundColor3 = self.Config.BG_PANEL
		inspPanel.BorderSizePixel = 0
		Instance.new("UICorner", inspPanel).CornerRadius = UDim.new(0, 6)
		self:_createBorder(inspPanel, false)
		local inspTitle = Instance.new("TextLabel", inspPanel)
		inspTitle.Size = UDim2.new(1, -4, 0, 18)
		inspTitle.Position = UDim2.fromOffset(2, 2)
		inspTitle.BackgroundColor3 = self.Config.BG_DARK
		inspTitle.BorderSizePixel = 0
		inspTitle.Text = "Table Inspector"
		inspTitle.TextColor3 = self.Config.TEXT_BLACK
		inspTitle.Font = Enum.Font.GothamBold
		inspTitle.TextSize = 11
		inspTitle.TextXAlignment = Enum.TextXAlignment.Left
		local itp = Instance.new("UIPadding", inspTitle)
		itp.PaddingLeft = UDim.new(0, 4)
		self:_createBorder(inspTitle, true)
		local svTabStrip = Instance.new("Frame", inspPanel)
		svTabStrip.Size = UDim2.new(1, -4, 0, 20)
		svTabStrip.Position = UDim2.fromOffset(2, 20)
		svTabStrip.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
		svTabStrip.BorderSizePixel = 0
		self:_createBorder(svTabStrip, true)
		local svActiveTab = "inspector"
		local svInspTab = Instance.new("TextButton", svTabStrip)
		svInspTab.Size = UDim2.fromOffset(110, 20)
		svInspTab.Position = UDim2.fromOffset(0, 0)
		svInspTab.BackgroundColor3 = self.Config.BG_LIGHT
		svInspTab.Text = "Table Inspector"
		svInspTab.TextColor3 = self.Config.TEXT_BLACK
		svInspTab.Font = Enum.Font.GothamMedium
		svInspTab.TextSize = 10
		svInspTab.BorderSizePixel = 0
		svInspTab.AutoButtonColor = false
		self:_createBorder(svInspTab, false)
		local svScriptTab = Instance.new("TextButton", svTabStrip)
		svScriptTab.Size = UDim2.fromOffset(100, 20)
		svScriptTab.Position = UDim2.fromOffset(111, 0)
		svScriptTab.BackgroundColor3 = self.Config.BG_PANEL
		svScriptTab.Text = "Script Viewer"
		svScriptTab.TextColor3 = self.Config.TEXT_BLACK
		svScriptTab.Font = Enum.Font.GothamMedium
		svScriptTab.TextSize = 10
		svScriptTab.BorderSizePixel = 0
		svScriptTab.AutoButtonColor = false
		self:_createBorder(svScriptTab, true)
		local svGCTab = Instance.new("TextButton", svTabStrip)
		svGCTab.Size = UDim2.fromOffset(110, 20)
		svGCTab.Position = UDim2.fromOffset(213, 0)
		svGCTab.BackgroundColor3 = self.Config.BG_PANEL
		svGCTab.Text = "GC / Upvalues"
		svGCTab.TextColor3 = self.Config.TEXT_BLACK
		svGCTab.Font = Enum.Font.GothamMedium
		svGCTab.TextSize = 10
		svGCTab.BorderSizePixel = 0
		svGCTab.AutoButtonColor = false
		self:_createBorder(svGCTab, true)
		local toolbar = Instance.new("Frame", inspPanel)
		toolbar.Size = UDim2.new(1, -8, 0, 26)
		toolbar.Position = UDim2.fromOffset(4, 42)
		toolbar.BackgroundColor3 = self.Config.BG_DARK
		toolbar.BorderSizePixel = 0
		self:_createBorder(toolbar, true)
		self:_createButton(toolbar, "< Back", UDim2.fromOffset(58, 20), UDim2.fromOffset(2, 2), function()
			self:GoBack()
		end)
		self:_createButton(toolbar, "Refresh", UDim2.fromOffset(58, 20), UDim2.fromOffset(62, 2), function()
			self:RefreshInspector()
		end)
		local pathLabel = Instance.new("TextLabel", toolbar)
		pathLabel.Size = UDim2.new(1, -128, 1, -4)
		pathLabel.Position = UDim2.fromOffset(124, 2)
		pathLabel.BackgroundTransparency = 1
		pathLabel.Text = "Root"
		pathLabel.TextColor3 = self.Config.TEXT_BLACK
		pathLabel.Font = Enum.Font.Code
		pathLabel.TextSize = 11
		pathLabel.TextXAlignment = Enum.TextXAlignment.Left
		pathLabel.TextTruncate = Enum.TextTruncate.AtEnd
		local hdr = Instance.new("Frame", inspPanel)
		hdr.Size = UDim2.new(1, -8, 0, self.Config.ROW_HEIGHT)
		hdr.Position = UDim2.fromOffset(4, 72)
		hdr.BackgroundColor3 = self.Config.BG_DARK
		hdr.BorderSizePixel = 0
		self:_createBorder(hdr, true)
		local hdrs = { "Active", "Key", "Type", "Value", "Actions" }
		local hW = { 0.07, 0.26, 0.12, 0.35, 0.20 }
		local xp = 0
		for i, ht in ipairs(hdrs) do
			local h = Instance.new("TextLabel", hdr)
			h.Size = UDim2.new(hW[i], -2, 1, 0)
			h.Position = UDim2.new(xp, 1, 0, 0)
			h.BackgroundTransparency = 1
			h.Text = ht
			h.TextColor3 = self.Config.TEXT_BLACK
			h.Font = Enum.Font.GothamBold
			h.TextSize = 11
			h.TextXAlignment = Enum.TextXAlignment.Left
			local hp = Instance.new("UIPadding", h)
			hp.PaddingLeft = UDim.new(0, 4)
			xp = xp + hW[i]
		end
		local inspScroll = Instance.new("ScrollingFrame", inspPanel)
		inspScroll.Size = UDim2.new(1, -8, 1, -100)
		inspScroll.Position = UDim2.fromOffset(4, 96)
		inspScroll.BackgroundColor3 = self.Config.BG_WHITE
		inspScroll.BorderSizePixel = 0
		inspScroll.ScrollBarThickness = 12
		inspScroll.ScrollBarImageColor3 = self.Config.ACCENT
		inspScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		inspScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		self:_createBorder(inspScroll, true)
		local inspList = Instance.new("UIListLayout", inspScroll)
		inspList.Padding = UDim.new(0, 0)
		local scriptPanel = Instance.new("Frame", inspPanel)
		scriptPanel.Size = UDim2.new(1, -8, 1, -100)
		scriptPanel.Position = UDim2.fromOffset(4, 96)
		scriptPanel.BackgroundColor3 = self.Config.BG_WHITE
		scriptPanel.BorderSizePixel = 0
		scriptPanel.Visible = false
		self:_createBorder(scriptPanel, true)
		local svToolbar = Instance.new("Frame", scriptPanel)
		svToolbar.Size = UDim2.new(1, 0, 0, 28)
		svToolbar.Position = UDim2.fromOffset(0, 0)
		svToolbar.BackgroundColor3 = self.Config.BG_DARK
		svToolbar.BorderSizePixel = 0
		self:_createBorder(svToolbar, true)
		local svScriptNameLbl = Instance.new("TextLabel", svToolbar)
		svScriptNameLbl.Size = UDim2.new(1, -260, 1, -4)
		svScriptNameLbl.Position = UDim2.fromOffset(4, 2)
		svScriptNameLbl.BackgroundTransparency = 1
		svScriptNameLbl.Text = "No module selected"
		svScriptNameLbl.TextColor3 = self.Config.TEXT_BLACK
		svScriptNameLbl.Font = Enum.Font.GothamBold
		svScriptNameLbl.TextSize = 11
		svScriptNameLbl.TextXAlignment = Enum.TextXAlignment.Left
		svScriptNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
		local svnPad = Instance.new("UIPadding", svScriptNameLbl)
		svnPad.PaddingLeft = UDim.new(0, 4)
		local svStatusLbl = Instance.new("TextLabel", svToolbar)
		svStatusLbl.Size = UDim2.fromOffset(100, 20)
		svStatusLbl.Position = UDim2.new(1, -256, 0, 4)
		svStatusLbl.BackgroundTransparency = 1
		svStatusLbl.Text = ""
		svStatusLbl.TextColor3 = self.Config.TEXT_GRAY
		svStatusLbl.Font = Enum.Font.Gotham
		svStatusLbl.TextSize = 10
		svStatusLbl.TextXAlignment = Enum.TextXAlignment.Right
		local svApiBtn = self:_createButton(
			svToolbar,
			"API: lua.expert",
			UDim2.fromOffset(94, 20),
			UDim2.new(1, -246, 0, 4),
			nil
		)
		svApiBtn.TextSize = 9
		svApiBtn.AutoButtonColor = false
		svApiBtn.BackgroundColor3 = Color3.fromRGB(46, 78, 60)
		local svWrapBtn = self:_createButton(
			svToolbar,
			"Wrap: Off",
			UDim2.fromOffset(62, 20),
			UDim2.new(1, -148, 0, 4),
			function()
				self.State.ViewerWrap = not self.State.ViewerWrap
				svWrapBtn.Text = self.State.ViewerWrap and "Wrap: On" or "Wrap: Off"
				if self.State.UI and self.State.UI.ScriptViewerRefresh then
					self.State.UI.ScriptViewerRefresh()
				end
			end
		)
		svWrapBtn.TextSize = 9
		local svCopyBtn = self:_createButton(
			svToolbar,
			"Copy",
			UDim2.fromOffset(44, 20),
			UDim2.new(1, -100, 0, 4),
			function()
				if self.State.UI and self.State.UI.ScriptViewerOutput then
					local txt = self.State.UI.ScriptViewerOutput.Text
					if txt ~= "" then
						pcall(setclipboard, txt)
						self:_showNotification("Copied to clipboard", "success")
					end
				end
			end
		)
		svCopyBtn.TextSize = 10
		local svDecompBtn = self:_createButton(
			svToolbar,
			"Decompile",
			UDim2.fromOffset(66, 20),
			UDim2.new(1, -52, 0, 4),
			function()
				self:SVDecompile()
			end
		)
		svDecompBtn.TextSize = 10
		local svScroll = Instance.new("ScrollingFrame", scriptPanel)
		svScroll.Size = UDim2.new(1, 0, 1, -30)
		svScroll.Position = UDim2.fromOffset(0, 30)
		svScroll.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
		svScroll.BorderSizePixel = 0
		svScroll.ScrollBarThickness = 10
		svScroll.ScrollBarImageColor3 = self.Config.ACCENT
		svScroll.ScrollBarImageTransparency = 0.15
		svScroll.ScrollingDirection = Enum.ScrollingDirection.XY
		svScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
		svScroll.CanvasSize = UDim2.fromOffset(0, 0)
		svScroll.ClipsDescendants = true
		svScroll.Active = true
		svScroll.Selectable = true

		local svGutter = Instance.new("TextLabel", svScroll)
		svGutter.Name = "SVLineNumbers"
		svGutter.Size = UDim2.fromOffset(44, 100)
		svGutter.Position = UDim2.fromOffset(0, 6)
		svGutter.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
		svGutter.BackgroundTransparency = 0.15
		svGutter.Text = "1"
		svGutter.TextColor3 = Color3.fromRGB(90, 90, 105)
		svGutter.Font = Enum.Font.Code
		svGutter.TextSize = 11
		svGutter.TextXAlignment = Enum.TextXAlignment.Right
		svGutter.TextYAlignment = Enum.TextYAlignment.Top
		svGutter.TextWrapped = false
		svGutter.RichText = false
		local gpad = Instance.new("UIPadding", svGutter)
		gpad.PaddingRight = UDim.new(0, 8)

		local svOutput = Instance.new("TextBox", svScroll)
		svOutput.Name = "SVOutput"
		svOutput.Size = UDim2.fromOffset(900, 24)
		svOutput.Position = UDim2.fromOffset(52, 6)
		svOutput.BackgroundTransparency = 1
		svOutput.Text = "← Select a module then click Decompile"
		svOutput.TextColor3 = Color3.fromRGB(215, 215, 225)
		svOutput.Font = Enum.Font.Code
		svOutput.TextSize = 11
		svOutput.TextXAlignment = Enum.TextXAlignment.Left
		svOutput.TextYAlignment = Enum.TextYAlignment.Top
		svOutput.TextWrapped = false
		svOutput.RichText = false
		svOutput.ClearTextOnFocus = false
		svOutput.MultiLine = true
		svOutput.TextEditable = false
		svOutput.Active = false

		local function refreshScriptViewerLayout()
			local text = svOutput.Text or ""
			local lineCount = math.max(1, select(2, text:gsub("\n", "")) + 1)
			local lineHeight = 15
			local height = math.max(lineCount * lineHeight + 12, svScroll.AbsoluteWindowSize.Y)
			local wrap = self.State.ViewerWrap == true
			svOutput.TextWrapped = wrap
			if wrap then
				svOutput.Size = UDim2.new(1, -60, 0, height)
				svGutter.Size = UDim2.fromOffset(44, height)
				svScroll.CanvasSize = UDim2.new(0, 0, 0, height + 8)
			else
				local maxChars = 120
				for line in text:gmatch("[^\n]*") do
					if #line > maxChars then maxChars = #line end
				end
				local maxWidth = math.max(900, math.min(16000, maxChars * 7.2 + 12))
				svOutput.Size = UDim2.fromOffset(maxWidth, height)
				svGutter.Size = UDim2.fromOffset(44, height)
				svScroll.CanvasSize = UDim2.fromOffset(maxWidth + 60, height + 8)
			end
			local nums = {}
			for i = 1, lineCount do nums[i] = tostring(i) end
			svGutter.Text = table.concat(nums, "\n")
		end

		svScroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(refreshScriptViewerLayout)
		svOutput:GetPropertyChangedSignal("Text"):Connect(function()
			task.defer(refreshScriptViewerLayout)
		end)
		self.State._RefreshScriptViewerLayout = refreshScriptViewerLayout
		local gcPanel = Instance.new("Frame", inspPanel)
		gcPanel.Size = UDim2.new(1, -8, 1, -100)
		gcPanel.Position = UDim2.fromOffset(4, 96)
		gcPanel.BackgroundColor3 = self.Config.BG_WHITE
		gcPanel.BorderSizePixel = 0
		gcPanel.Visible = false
		self:_createBorder(gcPanel, true)
		local gcToolbar = Instance.new("Frame", gcPanel)
		gcToolbar.Size = UDim2.new(1, 0, 0, 30)
		gcToolbar.BackgroundColor3 = self.Config.BG_DARK
		gcToolbar.BorderSizePixel = 0
		self:_createBorder(gcToolbar, true)
		local gcSearch = Instance.new("TextBox", gcToolbar)
		gcSearch.Size = UDim2.new(0, 160, 0, 20)
		gcSearch.Position = UDim2.fromOffset(4, 5)
		gcSearch.BackgroundColor3 = self.Config.BG_WHITE
		gcSearch.Text = ""
		gcSearch.PlaceholderText = "Search labels..."
		gcSearch.TextColor3 = self.Config.TEXT_BLACK
		gcSearch.Font = Enum.Font.Gotham
		gcSearch.TextSize = 11
		gcSearch.BorderSizePixel = 0
		gcSearch.ClearTextOnFocus = false
		local gsp = Instance.new("UIPadding", gcSearch)
		gsp.PaddingLeft = UDim.new(0, 4)
		self:_createBorder(gcSearch, true)
		local gcFilterTypes = { "all", "table", "function" }
		local gcFilterIdx = 1
		local gcFilterBtn = self:_createButton(gcToolbar, "Type: all",
			UDim2.fromOffset(72, 20), UDim2.fromOffset(168, 5), function() end)
		gcFilterBtn.TextSize = 9
		gcFilterBtn.BackgroundColor3 = self.Config.ACCENT
		gcFilterBtn.MouseButton1Click:Connect(function()
			gcFilterIdx = (gcFilterIdx % #gcFilterTypes) + 1
			gcFilterBtn.Text = "Type: " .. gcFilterTypes[gcFilterIdx]
		end)
		local gcScanBtn = self:_createButton(gcToolbar, "▶ Scan",
			UDim2.fromOffset(58, 20), UDim2.fromOffset(244, 5), function()
				self:PopulateGCPanel(
					gcFilterTypes[gcFilterIdx] ~= "all" and gcFilterTypes[gcFilterIdx] or nil,
					gcSearch.Text ~= "" and gcSearch.Text or nil
				)
		end)
		gcScanBtn.TextSize = 9
		gcScanBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
		local gcSrcFilters = { "gc", "reg", "genv", "upv" }
		local gcSrcEnabled = { gc = true, reg = true, genv = true, upv = true }
		local chipX = 306
		for _, src in ipairs(gcSrcFilters) do
			local chip = self:_createButton(gcToolbar, src,
				UDim2.fromOffset(34, 20), UDim2.fromOffset(chipX, 5), function() end)
			chip.TextSize = 9
			local chipColors = {
				gc = Color3.fromRGB(99, 102, 241),
				reg = Color3.fromRGB(56, 189, 248),
				genv = Color3.fromRGB(34, 197, 94),
				upv = Color3.fromRGB(251, 191, 36),
			}
			chip.BackgroundColor3 = chipColors[src]
			chipX = chipX + 38
		end
		local gcStatus = Instance.new("TextLabel", gcPanel)
		gcStatus.Size = UDim2.new(1, -8, 0, 16)
		gcStatus.Position = UDim2.fromOffset(4, 32)
		gcStatus.BackgroundTransparency = 1
		gcStatus.Text = "Click ▶ Scan to inspect direct GC modules safely"
		gcStatus.TextColor3 = self.Config.TEXT_GRAY
		gcStatus.Font = Enum.Font.Gotham
		gcStatus.TextSize = 10
		gcStatus.TextXAlignment = Enum.TextXAlignment.Left
		local gcHdr = Instance.new("Frame", gcPanel)
		gcHdr.Size = UDim2.new(1, 0, 0, self.Config.ROW_HEIGHT)
		gcHdr.Position = UDim2.fromOffset(0, 50)
		gcHdr.BackgroundColor3 = self.Config.BG_DARK
		gcHdr.BorderSizePixel = 0
		self:_createBorder(gcHdr, true)
		for i, txt in ipairs({ "Src", "T", "Label", "Actions" }) do
			local hx = { UDim2.new(0, 2, 0, 0), UDim2.new(0, 36, 0, 0), UDim2.new(0, 52, 0, 0), UDim2.new(1, -80, 0, 0) }
			local hw = { UDim2.fromOffset(32, self.Config.ROW_HEIGHT), UDim2.fromOffset(14, self.Config.ROW_HEIGHT),
				UDim2.new(1, -134, 1, 0), UDim2.fromOffset(80, self.Config.ROW_HEIGHT) }
			local h = Instance.new("TextLabel", gcHdr)
			h.Size = hw[i]; h.Position = hx[i]
			h.BackgroundTransparency = 1; h.Text = txt
			h.TextColor3 = self.Config.TEXT_BLACK; h.Font = Enum.Font.GothamBold
			h.TextSize = 10; h.TextXAlignment = Enum.TextXAlignment.Left
			local hp = Instance.new("UIPadding", h); hp.PaddingLeft = UDim.new(0, 2)
		end
		local gcScroll = Instance.new("ScrollingFrame", gcPanel)
		gcScroll.Size = UDim2.new(1, 0, 1, -74)
		gcScroll.Position = UDim2.fromOffset(0, 74)
		gcScroll.BackgroundColor3 = self.Config.BG_WHITE
		gcScroll.BorderSizePixel = 0
		gcScroll.ScrollBarThickness = 8
		gcScroll.ScrollBarImageColor3 = self.Config.ACCENT
		gcScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		gcScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		local gcList = Instance.new("UIListLayout", gcScroll)
		gcList.Padding = UDim.new(0, 0)
		local gcDebounce
		gcSearch.Changed:Connect(function(p)
			if p == "Text" then
				if gcDebounce then task.cancel(gcDebounce) end
				gcDebounce = task.delay(0.4, function()
					if gcSearch.Text ~= "" then
						self:PopulateGCPanel(
							gcFilterTypes[gcFilterIdx] ~= "all" and gcFilterTypes[gcFilterIdx] or nil,
							gcSearch.Text
						)
					end
				end)
			end
		end)

		local lsPanel, lsTabBtn
		local targetPanel, targetTabBtn
		local dataPanel, dataTabBtn
		local function svSwitchTab(toTab)
			svActiveTab = toTab
			inspScroll.Visible = false
			hdr.Visible = false
			toolbar.Visible = false
			scriptPanel.Visible = false
			gcPanel.Visible = false
			if lsPanel then lsPanel.Visible = false end
			if targetPanel then targetPanel.Visible = false end
			if dataPanel then dataPanel.Visible = false end
			for _, btn in ipairs({ svInspTab, svScriptTab, svGCTab, lsTabBtn, targetTabBtn, dataTabBtn }) do
				if not btn then continue end
				btn.BackgroundColor3 = self.Config.BG_PANEL
				btn.Font = Enum.Font.GothamMedium
			end
			if toTab == "inspector" then
				inspScroll.Visible = true
				hdr.Visible = true
				toolbar.Visible = true
				svInspTab.BackgroundColor3 = self.Config.BG_LIGHT
				svInspTab.Font = Enum.Font.GothamBold
			elseif toTab == "scriptviewer" then
				scriptPanel.Visible = true
				svScriptTab.BackgroundColor3 = self.Config.BG_LIGHT
				svScriptTab.Font = Enum.Font.GothamBold
			elseif toTab == "gcviewer" then
				gcPanel.Visible = true
				svGCTab.BackgroundColor3 = self.Config.BG_LIGHT
				svGCTab.Font = Enum.Font.GothamBold
			elseif toTab == "ls" then
				if lsPanel then lsPanel.Visible = true end
				if lsTabBtn then
					lsTabBtn.BackgroundColor3 = self.Config.BG_LIGHT
					lsTabBtn.Font = Enum.Font.GothamBold
				end
			elseif toTab == "target" then
				if targetPanel then targetPanel.Visible = true end
				if targetTabBtn then
					targetTabBtn.BackgroundColor3 = self.Config.BG_LIGHT
					targetTabBtn.Font = Enum.Font.GothamBold
				end
			elseif toTab == "data" then
				if dataPanel then dataPanel.Visible = true end
				if dataTabBtn then
					dataTabBtn.BackgroundColor3 = self.Config.BG_LIGHT
					dataTabBtn.Font = Enum.Font.GothamBold
				end
			end
		end
		svInspTab.MouseButton1Click:Connect(function()
			svSwitchTab("inspector")
		end)
		svScriptTab.MouseButton1Click:Connect(function()
			svSwitchTab("scriptviewer")
		end)
		svGCTab.MouseButton1Click:Connect(function()
			svSwitchTab("gcviewer")
		end)
		lsTabBtn = Instance.new("TextButton", svTabStrip)
		lsTabBtn.Size = UDim2.fromOffset(100, 20)
		lsTabBtn.Position = UDim2.fromOffset(325, 0)
		lsTabBtn.BackgroundColor3 = self.Config.BG_PANEL
		lsTabBtn.Text = "LocalScript"
		lsTabBtn.TextColor3 = self.Config.TEXT_BLACK
		lsTabBtn.Font = Enum.Font.GothamMedium
		lsTabBtn.TextSize = 10
		lsTabBtn.BorderSizePixel = 0
		lsTabBtn.AutoButtonColor = false
		self:_createBorder(lsTabBtn, true)
		lsTabBtn.MouseButton1Click:Connect(function()
			svSwitchTab("ls")
		end)
		lsPanel = Instance.new("Frame", inspPanel)
		lsPanel.Size = UDim2.new(1, -8, 1, -100)
		lsPanel.Position = UDim2.fromOffset(4, 96)
		lsPanel.BackgroundColor3 = self.Config.BG_WHITE
		lsPanel.BorderSizePixel = 0
		lsPanel.Visible = false
		Instance.new("UICorner", lsPanel).CornerRadius = UDim.new(0, 4)
		local lsClosureHdr = Instance.new("TextLabel", lsPanel)
		lsClosureHdr.Size = UDim2.new(1, 0, 0, 18)
		lsClosureHdr.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
		lsClosureHdr.BorderSizePixel = 0
		lsClosureHdr.Font = Enum.Font.GothamBold
		lsClosureHdr.TextSize = 10
		lsClosureHdr.TextColor3 = Color3.fromRGB(251, 146, 60)
		lsClosureHdr.TextXAlignment = Enum.TextXAlignment.Left
		Instance.new("UIPadding", lsClosureHdr).PaddingLeft = UDim.new(0, 6)
		local lsClosureCount = Instance.new("TextLabel", lsPanel)
		lsClosureCount.Size = UDim2.new(1, -160, 0, 18)
		lsClosureCount.Position = UDim2.fromOffset(0, 0)
		lsClosureCount.BackgroundTransparency = 1
		lsClosureCount.Text = "0 closure(s)"
		lsClosureCount.TextColor3 = self.Config.TEXT_GRAY
		lsClosureCount.Font = Enum.Font.Gotham
		lsClosureCount.TextSize = 9
		lsClosureCount.TextXAlignment = Enum.TextXAlignment.Right
		local lsClosureHdrLabel = Instance.new("TextLabel", lsClosureHdr)
		lsClosureHdrLabel.Size = UDim2.new(1, -160, 1, 0)
		lsClosureHdrLabel.BackgroundTransparency = 1
		lsClosureHdrLabel.Text = "Closures / Upvalues"
		lsClosureHdrLabel.TextColor3 = Color3.fromRGB(251, 146, 60)
		lsClosureHdrLabel.Font = Enum.Font.GothamBold
		lsClosureHdrLabel.TextSize = 10
		lsClosureHdrLabel.TextXAlignment = Enum.TextXAlignment.Left
		Instance.new("UIPadding", lsClosureHdrLabel).PaddingLeft = UDim.new(0, 4)
		local lsRefreshBtn = self:_createButton(lsPanel, "↺ Refresh",
			UDim2.fromOffset(60, 14), UDim2.new(1, -64, 0, 2),
			function()
				local ls = self.State.SelectedLocalScript
				if ls then self:LoadLocalScript(ls) end
		end)
		lsRefreshBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 140)
		lsRefreshBtn.TextSize = 8
		local lsClosureScroll = Instance.new("ScrollingFrame", lsPanel)
		lsClosureScroll.Size = UDim2.new(1, 0, 0.55, -18)
		lsClosureScroll.Position = UDim2.fromOffset(0, 18)
		lsClosureScroll.BackgroundColor3 = self.Config.BG_WHITE
		lsClosureScroll.BorderSizePixel = 0
		lsClosureScroll.ScrollBarThickness = 4
		lsClosureScroll.ScrollBarImageColor3 = Color3.fromRGB(251, 146, 60)
		lsClosureScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		lsClosureScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		Instance.new("UIListLayout", lsClosureScroll).Padding = UDim.new(0, 1)
		local lsConnHdr = Instance.new("Frame", lsPanel)
		lsConnHdr.Size = UDim2.new(1, 0, 0, 18)
		lsConnHdr.Position = UDim2.new(0, 0, 0.55, 0)
		lsConnHdr.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
		lsConnHdr.BorderSizePixel = 0
		local lsConnHdrLabel = Instance.new("TextLabel", lsConnHdr)
		lsConnHdrLabel.Size = UDim2.new(1, -120, 1, 0)
		lsConnHdrLabel.BackgroundTransparency = 1
		lsConnHdrLabel.Text = "Connections"
		lsConnHdrLabel.TextColor3 = self.Config.HIGHLIGHT
		lsConnHdrLabel.Font = Enum.Font.GothamBold
		lsConnHdrLabel.TextSize = 10
		lsConnHdrLabel.TextXAlignment = Enum.TextXAlignment.Left
		Instance.new("UIPadding", lsConnHdrLabel).PaddingLeft = UDim.new(0, 6)
		local lsConnCount = Instance.new("TextLabel", lsConnHdr)
		lsConnCount.Size = UDim2.new(0, 100, 1, 0)
		lsConnCount.Position = UDim2.new(1, -104, 0, 0)
		lsConnCount.BackgroundTransparency = 1
		lsConnCount.Text = "0 connection(s)"
		lsConnCount.TextColor3 = self.Config.TEXT_GRAY
		lsConnCount.Font = Enum.Font.Gotham
		lsConnCount.TextSize = 9
		lsConnCount.TextXAlignment = Enum.TextXAlignment.Right
		local lsConnScroll = Instance.new("ScrollingFrame", lsPanel)
		lsConnScroll.Size = UDim2.new(1, 0, 0.45, -18)
		lsConnScroll.Position = UDim2.new(0, 0, 0.55, 18)
		lsConnScroll.BackgroundColor3 = self.Config.BG_WHITE
		lsConnScroll.BorderSizePixel = 0
		lsConnScroll.ScrollBarThickness = 4
		lsConnScroll.ScrollBarImageColor3 = self.Config.HIGHLIGHT
		lsConnScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		lsConnScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		Instance.new("UIListLayout", lsConnScroll).Padding = UDim.new(0, 1)
		targetTabBtn = Instance.new("TextButton", svTabStrip)
		targetTabBtn.Size = UDim2.fromOffset(96, 20)
		targetTabBtn.Position = UDim2.fromOffset(428, 0)
		targetTabBtn.BackgroundColor3 = self.Config.BG_PANEL
		targetTabBtn.Text = "Targets"
		targetTabBtn.TextColor3 = self.Config.TEXT_BLACK
		targetTabBtn.Font = Enum.Font.GothamMedium
		targetTabBtn.TextSize = 10
		targetTabBtn.BorderSizePixel = 0
		targetTabBtn.AutoButtonColor = false
		self:_createBorder(targetTabBtn, true)
		targetTabBtn.MouseButton1Click:Connect(function()
			svSwitchTab("target")
			self:RefreshObjectPanel()
		end)

		dataTabBtn = Instance.new("TextButton", svTabStrip)
		dataTabBtn.Size = UDim2.fromOffset(70, 20)
		dataTabBtn.Position = UDim2.fromOffset(527, 0)
		dataTabBtn.BackgroundColor3 = self.Config.BG_PANEL
		dataTabBtn.Text = "Data"
		dataTabBtn.TextColor3 = self.Config.TEXT_BLACK
		dataTabBtn.Font = Enum.Font.GothamMedium
		dataTabBtn.TextSize = 10
		dataTabBtn.BorderSizePixel = 0
		dataTabBtn.AutoButtonColor = false
		self:_createBorder(dataTabBtn, true)
		dataTabBtn.MouseButton1Click:Connect(function()
			svSwitchTab("data")
			self:ScanDataWorkspace()
		end)

		targetPanel = Instance.new("Frame", inspPanel); targetPanel.Size = UDim2.new(1, -8, 1, -100); targetPanel.Position = UDim2.fromOffset(4, 96); targetPanel.BackgroundColor3 = self.Config.BG_WHITE; targetPanel.BorderSizePixel = 0; targetPanel.Visible = false; self:_createBorder(targetPanel, true)
		local workspaceTabs = Instance.new("Frame", targetPanel); workspaceTabs.Size = UDim2.new(1, 0, 0, 24); workspaceTabs.BackgroundColor3 = self.Config.BG_DARK; workspaceTabs.BorderSizePixel = 0
		local wsPanels = {}; local wsButtons = {}; local function wstab(n, x) local b = Instance.new("TextButton", workspaceTabs); b.Size = UDim2.fromOffset(76, 22); b.Position = UDim2.fromOffset(x, 1); b.BackgroundColor3 = self.Config.BG_PANEL; b.Text = n; b.TextColor3 = self.Config.TEXT_BLACK; b.Font = Enum.Font.GothamMedium; b.TextSize = 8; b.BorderSizePixel = 0; b.AutoButtonColor = false; wsButtons[n] = b; return b end
		local function wsswitch(n) for k, v in pairs(wsPanels) do v.Visible = k == n; wsButtons[k].BackgroundColor3 = k == n and self.Config.BG_LIGHT or self.Config.BG_PANEL; wsButtons[k].Font = k == n and Enum.Font.GothamBold or Enum.Font.GothamMedium end end
		local be = wstab("Explorer", 2); local bi = wstab("Inspector", 79); local ba = wstab("Animations", 156); local bw = wstab("Watch", 233); local bd = wstab("Diff", 310)
		local explorerPanel = Instance.new("Frame", targetPanel); explorerPanel.Size = UDim2.new(1, 0, 1, -24); explorerPanel.Position = UDim2.fromOffset(0, 24); explorerPanel.BackgroundTransparency = 1; wsPanels.Explorer = explorerPanel
		local targetToolbar = Instance.new("Frame", explorerPanel); targetToolbar.Size = UDim2.new(1, 0, 0, 28); targetToolbar.BackgroundColor3 = self.Config.BG_DARK; targetToolbar.BorderSizePixel = 0
		local targetTitle = Instance.new("TextLabel", targetToolbar); targetTitle.Size = UDim2.new(1, -80, 1, 0); targetTitle.Position = UDim2.fromOffset(5, 0); targetTitle.BackgroundTransparency = 1; targetTitle.Text = "Live Instance Explorer"; targetTitle.TextColor3 = self.Config.TEXT_BLACK; targetTitle.Font = Enum.Font.GothamBold; targetTitle.TextSize = 10; targetTitle.TextXAlignment = Enum.TextXAlignment.Left
		local targetRefresh = self:_createButton(targetToolbar, "↺ Refresh", UDim2.fromOffset(60, 20), UDim2.new(1, -64, 0, 4), function() self:RefreshObjectPanel() end); targetRefresh.TextSize = 8
		local targetScroll = Instance.new("ScrollingFrame", explorerPanel); targetScroll.Size = UDim2.new(.42, -2, 1, -32); targetScroll.Position = UDim2.fromOffset(2, 30); targetScroll.BackgroundColor3 = self.Config.BG_DARK; targetScroll.BorderSizePixel = 0; targetScroll.ScrollBarThickness = 5; targetScroll.ScrollBarImageColor3 = self.Config.ACCENT; targetScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; targetScroll.CanvasSize = UDim2.new(0, 0, 0, 0); Instance.new("UIListLayout", targetScroll).Padding = UDim.new(0, 1)
		local targetEditor = Instance.new("Frame", explorerPanel); targetEditor.Size = UDim2.new(.58, -4, 1, -32); targetEditor.Position = UDim2.new(.42, 2, 0, 30); targetEditor.BackgroundColor3 = self.Config.BG_DARK; targetEditor.BorderSizePixel = 0
		local targetName = Instance.new("TextLabel", targetEditor); targetName.Size = UDim2.new(1, -8, 0, 28); targetName.Position = UDim2.fromOffset(4, 2); targetName.BackgroundTransparency = 1; targetName.Text = "Select a target"; targetName.TextColor3 = self.Config.HIGHLIGHT; targetName.Font = Enum.Font.GothamBold; targetName.TextSize = 9; targetName.TextXAlignment = Enum.TextXAlignment.Left; targetName.TextWrapped = true
		local targetPropertyScroll = Instance.new("ScrollingFrame", targetEditor); targetPropertyScroll.Size = UDim2.new(1, -4, 1, -34); targetPropertyScroll.Position = UDim2.fromOffset(2, 32); targetPropertyScroll.BackgroundColor3 = self.Config.BG_WHITE; targetPropertyScroll.BorderSizePixel = 0; targetPropertyScroll.ScrollBarThickness = 5; targetPropertyScroll.ScrollBarImageColor3 = self.Config.ACCENT; targetPropertyScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; targetPropertyScroll.CanvasSize = UDim2.new(0, 0, 0, 0); Instance.new("UIListLayout", targetPropertyScroll).Padding = UDim.new(0, 1)
		local inspectorPanel = Instance.new("ScrollingFrame", targetPanel); inspectorPanel.Size = UDim2.new(1, 0, 1, -24); inspectorPanel.Position = UDim2.fromOffset(0, 24); inspectorPanel.BackgroundColor3 = self.Config.BG_WHITE; inspectorPanel.BorderSizePixel = 0; inspectorPanel.ScrollBarThickness = 5; inspectorPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y; inspectorPanel.CanvasSize = UDim2.new(0, 0, 0, 0); wsPanels.Inspector = inspectorPanel; Instance.new("UIListLayout", inspectorPanel).Padding = UDim.new(0, 2)
		local animPanel = Instance.new("ScrollingFrame", targetPanel); animPanel.Size = UDim2.new(1, 0, 1, -24); animPanel.Position = UDim2.fromOffset(0, 24); animPanel.BackgroundColor3 = self.Config.BG_WHITE; animPanel.BorderSizePixel = 0; animPanel.ScrollBarThickness = 5; animPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y; animPanel.CanvasSize = UDim2.new(0, 0, 0, 0); wsPanels.Animations = animPanel; Instance.new("UIListLayout", animPanel).Padding = UDim.new(0, 2)
		local watchPanel = Instance.new("ScrollingFrame", targetPanel); watchPanel.Size = UDim2.new(1, 0, 1, -24); watchPanel.Position = UDim2.fromOffset(0, 24); watchPanel.BackgroundColor3 = self.Config.BG_WHITE; watchPanel.BorderSizePixel = 0; watchPanel.ScrollBarThickness = 5; watchPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y; watchPanel.CanvasSize = UDim2.new(0, 0, 0, 0); wsPanels.Watch = watchPanel; Instance.new("UIListLayout", watchPanel).Padding = UDim.new(0, 2)
		local watchBar = Instance.new("Frame", watchPanel); watchBar.Size = UDim2.new(1, -8, 0, 28); watchBar.Position = UDim2.fromOffset(4, 4); watchBar.BackgroundColor3 = self.Config.BG_DARK; watchBar.BorderSizePixel = 0; local wa = self:_createButton(watchBar, "Watch Selection", UDim2.fromOffset(75, 20), UDim2.fromOffset(5, 4), function() local o = self.State.SelectedObject; if o then local props = self:_objectPropertyList(o); if props[1] then self:AddWatch(o, props[1], false); self:RefreshWatchPanel() end end end); wa.TextSize = 7; local wc = self:_createButton(watchBar, "Clear", UDim2.fromOffset(50, 20), UDim2.new(1, -55, 0, 4), function() self.State.Watches = {}; self.State.ChangeLog = {}; self:RefreshWatchPanel() end); wc.TextSize = 7
		local diffPanel = Instance.new("ScrollingFrame", targetPanel); diffPanel.Size = UDim2.new(1, 0, 1, -24); diffPanel.Position = UDim2.fromOffset(0, 24); diffPanel.BackgroundColor3 = self.Config.BG_WHITE; diffPanel.BorderSizePixel = 0; diffPanel.ScrollBarThickness = 5; diffPanel.AutomaticCanvasSize = Enum.AutomaticSize.Y; diffPanel.CanvasSize = UDim2.new(0, 0, 0, 0); wsPanels.Diff = diffPanel; Instance.new("UIListLayout", diffPanel).Padding = UDim.new(0, 2)
		local diffBar = Instance.new("Frame", diffPanel); diffBar.Size = UDim2.new(1, -8, 0, 28); diffBar.Position = UDim2.fromOffset(4, 4); diffBar.BackgroundColor3 = self.Config.BG_DARK; diffBar.BorderSizePixel = 0; local ds = self:_createButton(diffBar, "Snapshot", UDim2.fromOffset(60, 20), UDim2.fromOffset(5, 4), function() if self.State.SelectedObject then self:TakeObjectSnapshot(self.State.SelectedObject); self.State.LastDiff = nil; self:RefreshDiffPanel() end end); ds.TextSize = 7; local dd = self:_createButton(diffBar, "Diff Now", UDim2.fromOffset(60, 20), UDim2.new(1, -65, 0, 4), function() if self.State.SelectedObject then self:DiffObjectSnapshot(self.State.LastSnapshot, self.State.SelectedObject); self:RefreshDiffPanel() end end); dd.TextSize = 7
		be.MouseButton1Click:Connect(function() wsswitch("Explorer") end); bi.MouseButton1Click:Connect(function() wsswitch("Inspector"); self:RefreshDeepPanel() end); ba.MouseButton1Click:Connect(function() wsswitch("Animations"); self:RefreshAnimationPanel() end); bw.MouseButton1Click:Connect(function() wsswitch("Watch"); self:RefreshWatchPanel() end); bd.MouseButton1Click:Connect(function() wsswitch("Diff"); self:RefreshDiffPanel() end); wsswitch("Explorer")

		dataPanel = Instance.new("Frame", inspPanel)
		dataPanel.Size = UDim2.new(1, -8, 1, -100)
		dataPanel.Position = UDim2.fromOffset(4, 96)
		dataPanel.BackgroundColor3 = self.Config.BG_WHITE
		dataPanel.BorderSizePixel = 0
		dataPanel.Visible = false
		self:_createBorder(dataPanel, true)
		local dataToolbar = Instance.new("Frame", dataPanel)
		dataToolbar.Size = UDim2.new(1, 0, 0, 34)
		dataToolbar.BackgroundColor3 = self.Config.BG_DARK
		dataToolbar.BorderSizePixel = 0
		self:_createBorder(dataToolbar, true)
		local dataTitle = Instance.new("TextLabel", dataToolbar)
		dataTitle.Size = UDim2.new(1, -100, 0, 18)
		dataTitle.Position = UDim2.fromOffset(5, 1)
		dataTitle.BackgroundTransparency = 1
		dataTitle.Text = "Data Architecture / Client State"
		dataTitle.TextColor3 = self.Config.TEXT_BLACK
		dataTitle.Font = Enum.Font.GothamBold
		dataTitle.TextSize = 10
		dataTitle.TextXAlignment = Enum.TextXAlignment.Left
		local dataStatus = Instance.new("TextLabel", dataToolbar)
		dataStatus.Size = UDim2.new(1, -100, 0, 14)
		dataStatus.Position = UDim2.fromOffset(5, 18)
		dataStatus.BackgroundTransparency = 1
		dataStatus.Text = "Not scanned"
		dataStatus.TextColor3 = self.Config.TEXT_GRAY
		dataStatus.Font = Enum.Font.Gotham
		dataStatus.TextSize = 8
		dataStatus.TextXAlignment = Enum.TextXAlignment.Left
		local dataScanBtn = self:_createButton(dataToolbar, "↺ Scan", UDim2.fromOffset(58, 22), UDim2.new(1, -63, 0, 6), function()
			self:ScanDataWorkspace()
		end)
		dataScanBtn.TextSize = 8
		dataScanBtn.BackgroundColor3 = self.Config.ACCENT
		local dataInfo = Instance.new("TextLabel", dataPanel)
		dataInfo.Size = UDim2.new(1, -10, 0, 30)
		dataInfo.Position = UDim2.fromOffset(5, 38)
		dataInfo.BackgroundTransparency = 1
		dataInfo.Text = "Client-side only: services, visible data modules/remotes, and a bounded sample of live Lua tables. Server DataStore records are not exposed here."
		dataInfo.TextColor3 = self.Config.TEXT_GRAY
		dataInfo.Font = Enum.Font.Gotham
		dataInfo.TextSize = 8
		dataInfo.TextWrapped = true
		dataInfo.TextXAlignment = Enum.TextXAlignment.Left
		dataInfo.TextYAlignment = Enum.TextYAlignment.Top
		local dataScroll = Instance.new("ScrollingFrame", dataPanel)
		dataScroll.Size = UDim2.new(1, -8, 1, -74)
		dataScroll.Position = UDim2.fromOffset(4, 72)
		dataScroll.BackgroundColor3 = self.Config.BG_WHITE
		dataScroll.BorderSizePixel = 0
		dataScroll.ScrollBarThickness = 7
		dataScroll.ScrollBarImageColor3 = self.Config.ACCENT
		dataScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		dataScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		self:_createBorder(dataScroll, true)
		Instance.new("UIListLayout", dataScroll).Padding = UDim.new(0, 2)

		local patchPanel = Instance.new("Frame", content)
		patchPanel.Size = UDim2.new(0.1799, 0, 1, 0)
		patchPanel.Position = UDim2.new(0.8220, 0, 0, 0)
		patchPanel.BackgroundColor3 = self.Config.BG_PANEL
		patchPanel.BorderSizePixel = 0
		Instance.new("UICorner", patchPanel).CornerRadius = UDim.new(0, 6)
		self:_createBorder(patchPanel, false)
		local patchTitle = Instance.new("TextLabel", patchPanel)
		patchTitle.Size = UDim2.new(1, -4, 0, 18)
		patchTitle.Position = UDim2.fromOffset(2, 2)
		patchTitle.BackgroundColor3 = self.Config.BG_DARK
		patchTitle.BorderSizePixel = 0
		patchTitle.Text = "Active Patches"
		patchTitle.TextColor3 = self.Config.TEXT_BLACK
		patchTitle.Font = Enum.Font.GothamBold
		patchTitle.TextSize = 11
		patchTitle.TextXAlignment = Enum.TextXAlignment.Left
		local ptp = Instance.new("UIPadding", patchTitle)
		ptp.PaddingLeft = UDim.new(0, 4)
		self:_createBorder(patchTitle, true)
		local patchControls = Instance.new("Frame", patchPanel)
		patchControls.Size = UDim2.new(1, -8, 0, 26)
		patchControls.Position = UDim2.fromOffset(4, 22)
		patchControls.BackgroundColor3 = self.Config.BG_DARK
		patchControls.BorderSizePixel = 0
		self:_createBorder(patchControls, true)
		local selAllBtn = self:_createButton(patchControls, "Sel All",
			UDim2.fromOffset(48, 20), UDim2.fromOffset(2, 3), function()
				self:SelectAllPatches()
		end)
		selAllBtn.TextSize = 9
		selAllBtn.BackgroundColor3 = self.Config.ACCENT
		local remSelBtn = self:_createButton(patchControls, "Rem Sel",
			UDim2.fromOffset(48, 20), UDim2.fromOffset(53, 3), function()
				self:RemoveSelectedPatches()
		end)
		remSelBtn.TextSize = 9
		remSelBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
		local remAllBtn = self:_createButton(patchControls, "Rem All",
			UDim2.fromOffset(48, 20), UDim2.fromOffset(104, 3), function()
				self.State.SelectedPatches = {}
				for id in pairs(self.State.ActivePatches) do
					self:RemovePatch(id)
				end
		end)
		remAllBtn.TextSize = 9
		remAllBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
		local patchSelCount = Instance.new("TextLabel", patchControls)
		patchSelCount.Size = UDim2.new(1, -156, 1, 0)
		patchSelCount.Position = UDim2.fromOffset(156, 0)
		patchSelCount.BackgroundTransparency = 1
		patchSelCount.Text = ""
		patchSelCount.TextColor3 = self.Config.HIGHLIGHT
		patchSelCount.Font = Enum.Font.GothamBold
		patchSelCount.TextSize = 10
		patchSelCount.TextXAlignment = Enum.TextXAlignment.Left
		local patchControls2 = Instance.new("Frame", patchPanel)
		patchControls2.Size = UDim2.new(1, -8, 0, 22)
		patchControls2.Position = UDim2.fromOffset(4, 50)
		patchControls2.BackgroundColor3 = self.Config.BG_DARK
		patchControls2.BorderSizePixel = 0
		self:_createBorder(patchControls2, true)
		local expAllBtn = self:_createButton(patchControls2, "Export All",
			UDim2.fromOffset(62, 16), UDim2.fromOffset(2, 3), function()
				self:ExportPatches(nil)
		end)
		expAllBtn.TextSize = 9
		expAllBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 80)
		local expSelBtn = self:_createButton(patchControls2, "Exp Sel",
			UDim2.fromOffset(52, 16), UDim2.fromOffset(67, 3), function()
				local ids = {}
				for id in pairs(self.State.SelectedPatches) do
					table.insert(ids, id)
				end
				self:ExportPatches(ids)
		end)
		expSelBtn.TextSize = 9
		expSelBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 60)
		local patchCount = Instance.new("TextLabel", patchControls2)
		patchCount.Size = UDim2.new(1, -124, 1, 0)
		patchCount.Position = UDim2.fromOffset(124, 0)
		patchCount.BackgroundTransparency = 1
		patchCount.Text = "Patches: 0"
		patchCount.TextColor3 = self.Config.TEXT_BLACK
		patchCount.Font = Enum.Font.Gotham
		patchCount.TextSize = 10
		patchCount.TextXAlignment = Enum.TextXAlignment.Left
		local phdr = Instance.new("Frame", patchPanel)
		phdr.Size = UDim2.new(1, -8, 0, self.Config.ROW_HEIGHT)
		phdr.Position = UDim2.fromOffset(4, 74)
		phdr.BackgroundColor3 = self.Config.BG_DARK
		phdr.BorderSizePixel = 0
		self:_createBorder(phdr, true)
		local pHdrs = { "Sel", "Frz", "Key", "Value", "Del" }
		local pHW = { 0.09, 0.11, 0.35, 0.31, 0.14 }
		local pxp = 0
		for i, ph in ipairs(pHdrs) do
			local h = Instance.new("TextLabel", phdr)
			h.Size = UDim2.new(pHW[i], -2, 1, 0)
			h.Position = UDim2.new(pxp, 1, 0, 0)
			h.BackgroundTransparency = 1
			h.Text = ph
			h.TextColor3 = self.Config.TEXT_BLACK
			h.Font = Enum.Font.GothamBold
			h.TextSize = 11
			h.TextXAlignment = Enum.TextXAlignment.Left
			local hp = Instance.new("UIPadding", h)
			hp.PaddingLeft = UDim.new(0, 4)
			pxp = pxp + pHW[i]
		end
		local patchScroll = Instance.new("ScrollingFrame", patchPanel)
		patchScroll.Size = UDim2.new(1, -8, 1, -100)
		patchScroll.Position = UDim2.fromOffset(4, 98)
		patchScroll.BackgroundColor3 = self.Config.BG_WHITE
		patchScroll.BorderSizePixel = 0
		patchScroll.ScrollBarThickness = 4
		patchScroll.ScrollBarImageColor3 = self.Config.ACCENT
		patchScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		patchScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		self:_createBorder(patchScroll, true)
		local patchList = Instance.new("UIListLayout", patchScroll)
		patchList.Padding = UDim.new(0, 0)
		local tab = Instance.new("Frame", sg)
		tab.Name = "RestoreTab"
		tab.Size = UDim2.fromOffset(34, 110)
		tab.Position = UDim2.new(1, -34, 0.5, -55)
		tab.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
		tab.BorderSizePixel = 0
		tab.Visible = false
		tab.ZIndex = 300
		self:_createBorder(tab, false)
		local iconFrame = Instance.new("Frame", tab)
		iconFrame.Size = UDim2.fromOffset(22, 22)
		iconFrame.Position = UDim2.new(0.5, -11, 0, 6)
		iconFrame.BackgroundTransparency = 1
		iconFrame.ZIndex = 301
		local cellSz = 6
		local gap = 1
		for row = 0, 2 do
			for col = 0, 2 do
				local cell = Instance.new("Frame", iconFrame)
				cell.Size = UDim2.fromOffset(cellSz, cellSz)
				cell.Position = UDim2.fromOffset(col * (cellSz + gap), row * (cellSz + gap))
				cell.BackgroundColor3 = row == 0 and self.Config.ACCENT or self.Config.BG_LIGHT
				cell.BorderSizePixel = 0
				cell.ZIndex = 302
			end
		end
		local tabLabel = Instance.new("TextLabel", tab)
		tabLabel.Size = UDim2.new(1, 0, 0, 14)
		tabLabel.Position = UDim2.fromOffset(0, 32)
		tabLabel.BackgroundTransparency = 1
		tabLabel.Text = "TI"
		tabLabel.TextColor3 = self.Config.TEXT_BLACK
		tabLabel.Font = Enum.Font.GothamBold
		tabLabel.TextSize = 11
		tabLabel.TextXAlignment = Enum.TextXAlignment.Center
		tabLabel.ZIndex = 301
		local tabVertLabel = Instance.new("TextLabel", tab)
		tabVertLabel.Size = UDim2.fromOffset(14, 80)
		tabVertLabel.Position = UDim2.new(0.5, -7, 0, 50)
		tabVertLabel.BackgroundTransparency = 1
		tabVertLabel.Text = "TABLE\nINSP"
		tabVertLabel.TextColor3 = self.Config.ACCENT
		tabVertLabel.Font = Enum.Font.Gotham
		tabVertLabel.TextSize = 9
		tabVertLabel.TextXAlignment = Enum.TextXAlignment.Center
		tabVertLabel.TextYAlignment = Enum.TextYAlignment.Top
		tabVertLabel.TextWrapped = true
		tabVertLabel.ZIndex = 301
		local tabBtn = Instance.new("TextButton", tab)
		tabBtn.Size = UDim2.new(1, 0, 1, 0)
		tabBtn.BackgroundTransparency = 1
		tabBtn.Text = ""
		tabBtn.ZIndex = 303
		tabBtn.MouseButton1Click:Connect(function()
			self:Restore()
		end)
		tabBtn.MouseEnter:Connect(function()
			TweenService:Create(tab, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(35, 35, 45) }):Play()
		end)
		tabBtn.MouseLeave:Connect(function()
			TweenService:Create(tab, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(14, 14, 18) }):Play()
		end)
		local tabDragging, tabDragStart, tabStartPos
		tabBtn.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				tabDragging = true
				tabDragStart = i.Position
				tabStartPos = tab.Position
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if tabDragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				local dy = i.Position.Y - tabDragStart.Y
				tab.Position =
					UDim2.new(tabStartPos.X.Scale, tabStartPos.X.Offset, tabStartPos.Y.Scale, tabStartPos.Y.Offset + dy)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				tabDragging = false
			end
		end)

		local MIN_W, MIN_H = 600, 400
		local resizeGrip = Instance.new("Frame", main)
		resizeGrip.Name = "ResizeGrip"
		resizeGrip.Size = UDim2.fromOffset(14, 14)
		resizeGrip.Position = UDim2.new(1, -14, 1, -14)
		resizeGrip.BackgroundColor3 = self.Config.BORDER_DARK
		resizeGrip.BorderSizePixel = 0
		resizeGrip.ZIndex = 500
		for k = 1, 3 do
			local dot = Instance.new("Frame", resizeGrip)
			dot.Size = UDim2.fromOffset(2, 2)
			dot.Position = UDim2.fromOffset(3 + (k - 1) * 3, 14 - 3 - (k - 1) * 3)
			dot.BackgroundColor3 = self.Config.BORDER_DARK
			dot.BorderSizePixel = 0
			dot.ZIndex = 501
		end
		local resizing, resizeDragStart, resizeStartSize = false, nil, nil
		resizeGrip.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				resizing = true
				resizeDragStart = i.Position
				resizeStartSize = main.AbsoluteSize
			end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
				local dx = i.Position.X - resizeDragStart.X
				local dy = i.Position.Y - resizeDragStart.Y
				local newW = math.max(MIN_W, resizeStartSize.X + dx)
				local newH = math.max(MIN_H, resizeStartSize.Y + dy)
				main.Size = UDim2.fromOffset(newW, newH)
			end
		end)
		UserInputService.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				resizing = false
			end
		end)

		self.State.Watches = self.State.Watches or {}; self.State.ChangeLog = self.State.ChangeLog or {}
		if not self.State._watchConnection then self.State._watchConnection = RunService.Heartbeat:Connect(function() self:_pollWatches() end) end
		self.State.UI = {
			ScreenGui = sg,
			Main = main,
			Content = content,
			TitleBar = titleBar,
			RestoreTab = tab,
			ModuleScroll = modScroll,
			InspectorScroll = inspScroll,
			PathLabel = pathLabel,
			PatchScroll = patchScroll,
			PatchCount = patchCount,
			PatchSelCount = patchSelCount,
			Minimized = false,
			ScriptViewerOutput = svOutput,
			ScriptViewerStatus = svStatusLbl,
			ScriptViewerName = svScriptNameLbl,
			ScriptViewerScroll = svScroll,
			GCScroll = gcScroll,
			GCStatus = gcStatus,
			LSPanel = lsPanel,
			LSClosureScroll = lsClosureScroll,
			LSConnScroll = lsConnScroll,
			LSClosureCount = lsClosureCount,
			LSConnCount = lsConnCount,
			LSTab = lsTabBtn,
			TargetPanel = targetPanel,
			TargetScroll = targetScroll,
			TargetPropertyScroll = targetPropertyScroll,
			TargetName = targetName,
			TargetTab = targetTabBtn,
			DataPanel = dataPanel,
			DataTab = dataTabBtn,
			DataScroll = dataScroll,
			DataStatus = dataStatus,
			TargetDeepScroll = inspectorPanel, TargetAnimScroll = animPanel, TargetWatchScroll = watchPanel, TargetDiffScroll = diffPanel,
			ScriptViewerGutter = svGutter,
			ScriptViewerWrapButton = svWrapBtn,
			ScriptViewerRefresh = refreshScriptViewerLayout,
			SVSwitchTab = svSwitchTab,
		}
		svSwitchTab("inspector")
		self:ScanModules()
		self:RefreshObjectPanel()
	end
	function TI:SVDecompile()
		local ui = self.State.UI
		if not ui then return end
		local ms = self.State.SelectedModule
		if not ms then
			self:_showNotification("No module selected", "warning")
			return
		end

		if type(getscriptbytecode) ~= "function" then
			ui.ScriptViewerOutput.Text = "-- getscriptbytecode is not supported by this executor."
			ui.ScriptViewerStatus.Text = "Unsupported"
			return
		end

		ui.ScriptViewerOutput.Text = "-- Sending '" .. ms.Name .. "' to lua.expert ..."
		ui.ScriptViewerStatus.Text = "Requesting..."
		ui.ScriptViewerScroll.CanvasPosition = Vector2.new(0, 0)

		task.spawn(function()
			local t0 = os.clock()
			local ok, result = pcall(_apiDecompile, ms)
			local elapsed = math.floor((os.clock() - t0) * 1000)
			if not ok then
				ui.ScriptViewerOutput.Text = "-- API decompiler error:\n-- " .. tostring(result)
				ui.ScriptViewerStatus.Text = "Error"
				return
			end
			result = tostring(result or "")
			local MAX = 500000
			if #result > MAX then
				result = result:sub(1, MAX) .. "\n\n-- [Output truncated at " .. MAX .. " characters]"
			end
			ui.ScriptViewerOutput.Text = result
			ui.ScriptViewerStatus.Text = (select(2, result:gsub("\n", "")) + 1) .. " lines · " .. elapsed .. "ms"
			task.defer(function()
				if self.State.UI and self.State.UI.ScriptViewerRefresh then
					self.State.UI.ScriptViewerRefresh()
				end
			end)
			self:_showNotification("Decompiled: " .. ms.Name, "success")
		end)
	end
	function TI:Open()
		self:CreateUI()
	end
	function TI:InspectTable(tbl, label)
		self:CreateUI()
		if type(tbl) ~= "table" then
			self:_showNotification("Not a table: " .. type(tbl), "error")
			return
		end
		self.State._RootTable = tbl
		self.State.CurrentTable = tbl
		self.State.PathStack = {}
		self.State.VisitedTables = {}
		self:RefreshInspector()
		if self.State.UI then
			self.State.UI.PathLabel.Text = label or "Custom Table"
		end
	end
	TI:Open()
