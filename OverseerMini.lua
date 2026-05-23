--[[

   RegisterCommand({
    Name        = "osmini",
    Aliases     = {"overseermini"},
    Description = "smaller",
}, function(args) --plugin 

 ]]


    local CoreGui = game:GetService("CoreGui")
    local UserInputService = game:GetService("UserInputService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
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
    		UI = nil,
    		MetatableChain = {},
    	},
    	Config = {
    		BG_LIGHT = Color3.fromRGB(240, 240, 240),
    		BG_PANEL = Color3.fromRGB(236, 233, 216),
    		BG_DARK = Color3.fromRGB(212, 208, 200),
    		BG_WHITE = Color3.fromRGB(255, 255, 255),
    		BORDER_DARK = Color3.fromRGB(128, 128, 128),
    		BORDER_LIGHT = Color3.fromRGB(128, 128, 128),
    		TEXT_BLACK = Color3.fromRGB(0, 0, 0),
    		TEXT_GRAY = Color3.fromRGB(128, 128, 128),
    		ACCENT = Color3.fromRGB(111, 0, 0),
    		HIGHLIGHT = Color3.fromRGB(51, 153, 255),
    		FROZEN_RED = Color3.fromRGB(255, 0, 0),
    		SUCCESS_GREEN = Color3.fromRGB(0, 180, 0),
    		WARNING_ORANGE = Color3.fromRGB(255, 165, 0),
    		ROW_HEIGHT = 22,
    	},
    }
    local TI = Modules.TI
    function TI:_generateUID()
    	local cs = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    	local r = ""
    	for _ = 1, 12 do
    		r = r .. cs:sub(math.random(1, #cs), math.random(1, #cs))
    	end
    	return r
    end
    function TI:_createBorder(parent, inset)
    	local top = inset and self.Config.BORDER_DARK or self.Config.BORDER_LIGHT
    	local bottom = inset and self.Config.BORDER_LIGHT or self.Config.BORDER_DARK
    	local function edge(sz, pos, col)
    		local f = Instance.new("Frame", parent)
    		f.Size = sz
    		f.Position = pos
    		f.BackgroundColor3 = col
    		f.BorderSizePixel = 0
    		f.ZIndex = parent.ZIndex + 1
    	end
    	edge(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), top)
    	edge(UDim2.new(0, 1, 1, 0), UDim2.new(0, 0, 0, 0), top)
    	edge(UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 1, -1), bottom)
    	edge(UDim2.new(0, 1, 1, 0), UDim2.new(1, -1, 0, 0), bottom)
    end
    function TI:_createButton(parent, text, size, position, callback)
    	local btn = Instance.new("TextButton", parent)
    	btn.Size = size
    	btn.Position = position
    	btn.BackgroundColor3 = self.Config.BG_PANEL
    	btn.Text = text
    	btn.TextColor3 = self.Config.TEXT_BLACK
    	btn.Font = Enum.Font.SourceSans
    	btn.TextSize = 11
    	btn.BorderSizePixel = 0
    	btn.AutoButtonColor = false
    	btn.ClipsDescendants = true
    	self:_createBorder(btn, false)
    	if callback then
    		btn.MouseButton1Click:Connect(callback)
    	end
    	btn.MouseButton1Down:Connect(function()
    		btn.BackgroundColor3 = self.Config.BG_DARK
    		for _, c in ipairs(btn:GetChildren()) do
    			if c.Name == "BorderTop" or c.Name == "BorderLeft" then
    				c.BackgroundColor3 = self.Config.BORDER_DARK
    			elseif c.Name == "BorderBottom" or c.Name == "BorderRight" then
    				c.BackgroundColor3 = self.Config.BORDER_LIGHT
    			end
    		end
    	end)
    	btn.MouseButton1Up:Connect(function()
    		btn.BackgroundColor3 = self.Config.BG_PANEL
    		for _, c in ipairs(btn:GetChildren()) do
    			if c.Name == "BorderTop" or c.Name == "BorderLeft" then
    				c.BackgroundColor3 = self.Config.BORDER_LIGHT
    			elseif c.Name == "BorderBottom" or c.Name == "BorderRight" then
    				c.BackgroundColor3 = self.Config.BORDER_DARK
    			end
    		end
    	end)
    	btn.MouseEnter:Connect(function()
    		if btn.BackgroundColor3 ~= self.Config.BG_DARK then
    			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_LIGHT }):Play()
    		end
    	end)
    	btn.MouseLeave:Connect(function()
    		if btn.BackgroundColor3 ~= self.Config.BG_DARK then
    			TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_PANEL }):Play()
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
    	notif.BackgroundColor3 = msgType == "success" and Color3.fromRGB(220, 255, 220)
    		or msgType == "error" and Color3.fromRGB(255, 220, 220)
    		or msgType == "warning" and Color3.fromRGB(255, 245, 220)
    		or self.Config.BG_LIGHT
    	notif.BorderSizePixel = 0
    	notif.ZIndex = 1000
    	self:_createBorder(notif, true)
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
    	icon.Font = Enum.Font.SourceSansBold
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
    		return '"' .. value .. '"'
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
    	self:_showNotification("Patched: " .. tostring(key), "success")
    	return patchId
    end
    function TI:RemovePatch(patchId)
    	local patch = self.State.ActivePatches[patchId]
    	if not patch then
    		return false
    	end
    	if patch.Connection then
    		patch.Connection:Disconnect()
    	end
    	pcall(function()
    		if setreadonly then
    			setreadonly(patch.Table, false)
    		elseif make_writeable then
    			make_writeable(patch.Table)
    		end
    		rawset(patch.Table, patch.Key, patch.Original)
    		if setreadonly then
    			setreadonly(patch.Table, true)
    		end
    	end)
    	self.State.ActivePatches[patchId] = nil
    	self.State.FreezeList[patchId] = nil
    	self:RefreshPatchList()
    	self:_showNotification("Patch removed", "success")
    	return true
    end
    function TI:ToggleFreeze(patchId)
    	local patch = self.State.ActivePatches[patchId]
    	if not patch then
    		return
    	end
    	patch.Frozen = not patch.Frozen
    	if patch.Frozen then
    		if not patch.Connection then
    			local tbl, key, val = patch.Table, patch.Key, patch.NewValue
    			patch.Connection = RunService.Heartbeat:Connect(function()
    				pcall(function()
    					if setreadonly then
    						setreadonly(tbl, false)
    					end
    					rawset(tbl, key, val)
    					if setreadonly then
    						setreadonly(tbl, true)
    					end
    				end)
    			end)
    		end
    		self.State.FreezeList[patchId] = patch
    	else
    		if patch.Connection then
    			patch.Connection:Disconnect()
    			patch.Connection = nil
    		end
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
    		or isMetatable and self.Config.BG_LIGHT
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
    	keyLabel.TextColor3 = isMetatable and Color3.fromRGB(0, 0, 128) or self.Config.TEXT_BLACK
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
    	valueBox.TextEditable = (valueType ~= "table" and valueType ~= "function")
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
    	local actionBtn = self:_createButton(row, "Patch", UDim2.fromOffset(45, 16), UDim2.new(0.80, 2, 0.5, -8), function()
    		if valueType == "table" then
    			self:DrillDown(key, value)
    		elseif valueType == "function" then
    			self:_showNotification("Function at: " .. tostring(key) .. " — hook from full tool", "info")
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
    	elseif valueType == "function" then
    		actionBtn.Text = "Info"
    		actionBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
    	end
    	local freezeBtn = self:_createButton(
    		row,
    		"Freeze",
    		UDim2.fromOffset(45, 16),
    		UDim2.new(0.88, 2, 0.5, -8),
    		function()
    			if valueBox.TextEditable then
    				local nv = self:ParseValue(valueBox.Text, valueType)
    				if nv ~= nil then
    					self:CreatePatch(parentTable, key, nv, true)
    				else
    					self:_showNotification("Invalid value for type: " .. valueType, "error")
    				end
    			else
    				self:_showNotification("Cannot freeze " .. valueType, "warning")
    			end
    		end
    	)
    	freezeBtn.TextSize = 9
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
    	local freezeBox = Instance.new("TextButton", row)
    	freezeBox.Size = UDim2.fromOffset(12, 12)
    	freezeBox.Position = UDim2.new(0.05, -6, 0.5, -6)
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
    	keyLbl.Size = UDim2.new(0.38, -4, 1, 0)
    	keyLbl.Position = UDim2.new(0.13, 2, 0, 0)
    	keyLbl.BackgroundTransparency = 1
    	keyLbl.Text = tostring(patch.Key)
    	keyLbl.TextColor3 = self.Config.TEXT_BLACK
    	keyLbl.Font = Enum.Font.SourceSans
    	keyLbl.TextSize = 9
    	keyLbl.TextXAlignment = Enum.TextXAlignment.Left
    	keyLbl.TextTruncate = Enum.TextTruncate.AtEnd
    	local valLbl = Instance.new("TextLabel", row)
    	valLbl.Size = UDim2.new(0.35, -4, 1, 0)
    	valLbl.Position = UDim2.new(0.51, 2, 0, 0)
    	valLbl.BackgroundTransparency = 1
    	valLbl.Text = tostring(patch.NewValue):sub(1, 20)
    	valLbl.TextColor3 = self.Config.TEXT_BLACK
    	valLbl.Font = Enum.Font.Code
    	valLbl.TextSize = 9
    	valLbl.TextXAlignment = Enum.TextXAlignment.Left
    	valLbl.TextTruncate = Enum.TextTruncate.AtEnd
    	local del = self:_createButton(row, "X", UDim2.fromOffset(16, 16), UDim2.new(0.88, 0, 0.5, -8), function()
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
    function TI:ScanModules()
    	if not self.State.UI then
    		return
    	end
    	for _, c in ipairs(self.State.UI.ModuleScroll:GetChildren()) do
    		if not c:IsA("UIListLayout") then
    			c:Destroy()
    		end
    	end
    	self.State.ModuleList = {}
    	task.spawn(function()
    		for _, root in ipairs({ ReplicatedStorage, Players.LocalPlayer, Workspace }) do
    			if root then
    				for _, obj in ipairs(root:GetDescendants()) do
    					if obj:IsA("ModuleScript") and not ROBLOX_MODULE_BLACKLIST[obj.Name] then
    						self:AddModuleToList(obj)
    					end
    				end
    				task.wait()
    			end
    		end
    		self:_showNotification("Found " .. #self.State.ModuleList .. " modules", "success")
    	end)
    end
    function TI:AddModuleToList(ms)
    	if not self.State.UI then
    		return
    	end
    	local row = Instance.new("TextButton", self.State.UI.ModuleScroll)
    	row.Size = UDim2.new(1, -2, 0, self.Config.ROW_HEIGHT)
    	row.BackgroundColor3 = self.Config.BG_WHITE
    	row.Text = ""
    	row.BorderSizePixel = 0
    	row.AutoButtonColor = false
    	local lbl = Instance.new("TextLabel", row)
    	lbl.Size = UDim2.new(1, -8, 1, 0)
    	lbl.Position = UDim2.fromOffset(4, 0)
    	lbl.BackgroundTransparency = 1
    	lbl.Text = ms.Name
    	lbl.TextColor3 = self.Config.TEXT_BLACK
    	lbl.Font = Enum.Font.SourceSans
    	lbl.TextSize = 12
    	lbl.TextXAlignment = Enum.TextXAlignment.Left
    	lbl.TextTruncate = Enum.TextTruncate.AtEnd
    	row.MouseButton1Click:Connect(function()
    		for _, child in ipairs(self.State.UI.ModuleScroll:GetChildren()) do
    			if child:IsA("TextButton") then
    				child.BackgroundColor3 = self.Config.BG_WHITE
    				for _, l in ipairs(child:GetChildren()) do
    					if l:IsA("TextLabel") then
    						l.TextColor3 = self.Config.TEXT_BLACK
    					end
    				end
    			end
    		end
    		row.BackgroundColor3 = self.Config.HIGHLIGHT
    		lbl.TextColor3 = self.Config.BG_WHITE
    		self:LoadModule(ms)
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
    	table.insert(self.State.ModuleList, { Script = ms, Row = row, Name = ms.Name })
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
    	self:_createBorder(main, false)
    	local titleBar = Instance.new("Frame", main)
    	titleBar.Size = UDim2.new(1, 0, 0, 24)
    	titleBar.BackgroundColor3 = self.Config.BG_DARK
    	titleBar.BorderSizePixel = 0
    	self:_createBorder(titleBar, true)
    	local title = Instance.new("TextLabel", titleBar)
    	title.Size = UDim2.new(1, -72, 1, 0)
    	title.Position = UDim2.fromOffset(6, 0)
    	title.BackgroundTransparency = 1
    	title.Text = "Table Inspector  ·  Editor  ·  Freeze  ·  Dive"
    	title.TextColor3 = self.Config.TEXT_BLACK
    	title.Font = Enum.Font.SourceSansBold
    	title.TextSize = 13
    	title.TextXAlignment = Enum.TextXAlignment.Left
    	self:_createButton(titleBar, "×", UDim2.fromOffset(20, 18), UDim2.new(1, -22, 0, 2), function()
    		main.Visible = false
    	end)
    	local minimizeBtn = self:_createButton(
    		titleBar,
    		"─",
    		UDim2.fromOffset(20, 18),
    		UDim2.new(1, -44, 0, 2),
    		function()
    			self:Minimize()
    		end
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
    	content.Size = UDim2.new(1, -4, 1, -28)
    	content.Position = UDim2.fromOffset(2, 26)
    	content.BackgroundTransparency = 1
    	content.BorderSizePixel = 0
    	local modPanel = Instance.new("Frame", content)
    	modPanel.Size = UDim2.fromOffset(210, 688)
    	modPanel.Position = UDim2.fromOffset(0, 0)
    	modPanel.BackgroundColor3 = self.Config.BG_PANEL
    	modPanel.BorderSizePixel = 0
    	self:_createBorder(modPanel, false)
    	local modTitle = Instance.new("TextLabel", modPanel)
    	modTitle.Size = UDim2.new(1, -4, 0, 18)
    	modTitle.Position = UDim2.fromOffset(2, 2)
    	modTitle.BackgroundColor3 = self.Config.BG_DARK
    	modTitle.BorderSizePixel = 0
    	modTitle.Text = "Modules"
    	modTitle.TextColor3 = self.Config.TEXT_BLACK
    	modTitle.Font = Enum.Font.SourceSansBold
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
    	modSearch.Font = Enum.Font.SourceSans
    	modSearch.TextSize = 12
    	modSearch.TextXAlignment = Enum.TextXAlignment.Left
    	modSearch.BorderSizePixel = 0
    	modSearch.ClearTextOnFocus = false
    	local msp = Instance.new("UIPadding", modSearch)
    	msp.PaddingLeft = UDim.new(0, 4)
    	self:_createBorder(modSearch, true)
    	local rescanBtn = self:_createButton(
    		modPanel,
    		"Rescan",
    		UDim2.new(1, -8, 0, 20),
    		UDim2.fromOffset(4, 50),
    		function()
    			self:ScanModules()
    		end
    	)
    	rescanBtn.TextSize = 10
    	local modScroll = Instance.new("ScrollingFrame", modPanel)
    	modScroll.Size = UDim2.new(1, -8, 1, -78)
    	modScroll.Position = UDim2.fromOffset(4, 74)
    	modScroll.BackgroundColor3 = self.Config.BG_WHITE
    	modScroll.BorderSizePixel = 0
    	modScroll.ScrollBarThickness = 10
    	modScroll.ScrollBarImageColor3 = self.Config.BG_DARK
    	modScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    	modScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    	self:_createBorder(modScroll, true)
    	local modList = Instance.new("UIListLayout", modScroll)
    	modList.Padding = UDim.new(0, 1)
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
    	inspPanel.Size = UDim2.fromOffset(650, 688)
    	inspPanel.Position = UDim2.fromOffset(214, 0)
    	inspPanel.BackgroundColor3 = self.Config.BG_PANEL
    	inspPanel.BorderSizePixel = 0
    	self:_createBorder(inspPanel, false)
    	local inspTitle = Instance.new("TextLabel", inspPanel)
    	inspTitle.Size = UDim2.new(1, -4, 0, 18)
    	inspTitle.Position = UDim2.fromOffset(2, 2)
    	inspTitle.BackgroundColor3 = self.Config.BG_DARK
    	inspTitle.BorderSizePixel = 0
    	inspTitle.Text = "Table Inspector"
    	inspTitle.TextColor3 = self.Config.TEXT_BLACK
    	inspTitle.Font = Enum.Font.SourceSansBold
    	inspTitle.TextSize = 11
    	inspTitle.TextXAlignment = Enum.TextXAlignment.Left
    	local itp = Instance.new("UIPadding", inspTitle)
    	itp.PaddingLeft = UDim.new(0, 4)
    	self:_createBorder(inspTitle, true)
    	local toolbar = Instance.new("Frame", inspPanel)
    	toolbar.Size = UDim2.new(1, -8, 0, 26)
    	toolbar.Position = UDim2.fromOffset(4, 22)
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
    	hdr.Position = UDim2.fromOffset(4, 52)
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
    		h.Font = Enum.Font.SourceSansBold
    		h.TextSize = 11
    		h.TextXAlignment = Enum.TextXAlignment.Left
    		local hp = Instance.new("UIPadding", h)
    		hp.PaddingLeft = UDim.new(0, 4)
    		xp = xp + hW[i]
    	end
    	local inspScroll = Instance.new("ScrollingFrame", inspPanel)
    	inspScroll.Size = UDim2.new(1, -8, 1, -78)
    	inspScroll.Position = UDim2.fromOffset(4, 76)
    	inspScroll.BackgroundColor3 = self.Config.BG_WHITE
    	inspScroll.BorderSizePixel = 0
    	inspScroll.ScrollBarThickness = 12
    	inspScroll.ScrollBarImageColor3 = self.Config.BG_DARK
    	inspScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    	inspScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    	self:_createBorder(inspScroll, true)
    	local inspList = Instance.new("UIListLayout", inspScroll)
    	inspList.Padding = UDim.new(0, 0)
    	local patchPanel = Instance.new("Frame", content)
    	patchPanel.Size = UDim2.fromOffset(190, 688)
    	patchPanel.Position = UDim2.fromOffset(868, 0)
    	patchPanel.BackgroundColor3 = self.Config.BG_PANEL
    	patchPanel.BorderSizePixel = 0
    	self:_createBorder(patchPanel, false)
    	local patchTitle = Instance.new("TextLabel", patchPanel)
    	patchTitle.Size = UDim2.new(1, -4, 0, 18)
    	patchTitle.Position = UDim2.fromOffset(2, 2)
    	patchTitle.BackgroundColor3 = self.Config.BG_DARK
    	patchTitle.BorderSizePixel = 0
    	patchTitle.Text = "Active Patches"
    	patchTitle.TextColor3 = self.Config.TEXT_BLACK
    	patchTitle.Font = Enum.Font.SourceSansBold
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
    	self:_createButton(patchControls, "Clear All", UDim2.fromOffset(72, 20), UDim2.fromOffset(2, 2), function()
    		for id in pairs(self.State.ActivePatches) do
    			self:RemovePatch(id)
    		end
    	end)
    	local patchCount = Instance.new("TextLabel", patchControls)
    	patchCount.Size = UDim2.new(1, -78, 1, 0)
    	patchCount.Position = UDim2.fromOffset(76, 0)
    	patchCount.BackgroundTransparency = 1
    	patchCount.Text = "Patches: 0"
    	patchCount.TextColor3 = self.Config.TEXT_BLACK
    	patchCount.Font = Enum.Font.SourceSans
    	patchCount.TextSize = 12
    	patchCount.TextXAlignment = Enum.TextXAlignment.Left
    	local phdr = Instance.new("Frame", patchPanel)
    	phdr.Size = UDim2.new(1, -8, 0, self.Config.ROW_HEIGHT)
    	phdr.Position = UDim2.fromOffset(4, 52)
    	phdr.BackgroundColor3 = self.Config.BG_DARK
    	phdr.BorderSizePixel = 0
    	self:_createBorder(phdr, true)
    	local pHdrs = { "Frz", "Key", "Value", "Del" }
    	local pHW = { 0.13, 0.38, 0.35, 0.14 }
    	local pxp = 0
    	for i, ph in ipairs(pHdrs) do
    		local h = Instance.new("TextLabel", phdr)
    		h.Size = UDim2.new(pHW[i], -2, 1, 0)
    		h.Position = UDim2.new(pxp, 1, 0, 0)
    		h.BackgroundTransparency = 1
    		h.Text = ph
    		h.TextColor3 = self.Config.TEXT_BLACK
    		h.Font = Enum.Font.SourceSansBold
    		h.TextSize = 11
    		h.TextXAlignment = Enum.TextXAlignment.Left
    		local hp = Instance.new("UIPadding", h)
    		hp.PaddingLeft = UDim.new(0, 4)
    		pxp = pxp + pHW[i]
    	end
    	local patchScroll = Instance.new("ScrollingFrame", patchPanel)
    	patchScroll.Size = UDim2.new(1, -8, 1, -78)
    	patchScroll.Position = UDim2.fromOffset(4, 76)
    	patchScroll.BackgroundColor3 = self.Config.BG_WHITE
    	patchScroll.BorderSizePixel = 0
    	patchScroll.ScrollBarThickness = 10
    	patchScroll.ScrollBarImageColor3 = self.Config.BG_DARK
    	patchScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    	patchScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    	self:_createBorder(patchScroll, true)
    	local patchList = Instance.new("UIListLayout", patchScroll)
    	patchList.Padding = UDim.new(0, 0)
    	local tab = Instance.new("Frame", sg)
    	tab.Name = "RestoreTab"
    	tab.Size = UDim2.fromOffset(34, 110)
    	tab.Position = UDim2.new(1, -34, 0.5, -55)
    	tab.BackgroundColor3 = self.Config.BG_DARK
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
    			cell.BackgroundColor3 = row == 0 and Color3.fromRGB(180, 180, 180) or self.Config.BG_WHITE
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
    	tabLabel.Font = Enum.Font.SourceSansBold
    	tabLabel.TextSize = 11
    	tabLabel.TextXAlignment = Enum.TextXAlignment.Center
    	tabLabel.ZIndex = 301
    	local tabVertLabel = Instance.new("TextLabel", tab)
    	tabVertLabel.Size = UDim2.fromOffset(14, 80)
    	tabVertLabel.Position = UDim2.new(0.5, -7, 0, 50)
    	tabVertLabel.BackgroundTransparency = 1
    	tabVertLabel.Text = "TABLE\nINSP"
    	tabVertLabel.TextColor3 = self.Config.TEXT_GRAY
    	tabVertLabel.Font = Enum.Font.SourceSans
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
    		TweenService:Create(tab, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_LIGHT }):Play()
    	end)
    	tabBtn.MouseLeave:Connect(function()
    		TweenService:Create(tab, TweenInfo.new(0.1), { BackgroundColor3 = self.Config.BG_DARK }):Play()
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
    		Minimized = false,
    	}
    	self:ScanModules()
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


--end)--plugin
