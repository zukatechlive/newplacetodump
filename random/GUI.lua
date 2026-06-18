--[[
	GUI Creator v3 — ZukaTech
	Sharp HUD-style visual GUI builder + live-instance editor.
	Maker mode: drag/resize/build a ScreenGui from scratch, export to code.
	Live mode: walk and edit any existing ScreenGui (yours or another script's) in-place.
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- CONSTANTS
-- ============================================================

local FONTS = {
	"Code", "RobotoMono", "Inconsolata",
	"Gotham", "GothamBold", "GothamBlack", "GothamMedium",
	"Arial", "ArialBold",
	"SourceSans", "SourceSansBold", "SourceSansItalic", "SourceSansSemibold",
	"Ubuntu", "UbuntuBold", "UbuntuItalic",
	"Merriweather", "MerriweatherBold", "MerriweatherItalic",
	"FredokaOne", "Cartoon", "Fantasy", "TitilliumWeb", "Oswald", "Nunito",
}
local HALIGN = { "Left", "Center", "Right" }
local VALIGN = { "Top", "Center", "Bottom" }
local SCALETYPES = { "Fit", "Crop", "Stretch", "Tile", "Slice" }

local ELEM_TYPES = {
	{ Name = "Frame",          Tag = "FRM" },
	{ Name = "TextLabel",      Tag = "LBL" },
	{ Name = "TextButton",     Tag = "BTN" },
	{ Name = "TextBox",        Tag = "BOX" },
	{ Name = "ImageLabel",     Tag = "IMG" },
	{ Name = "ImageButton",    Tag = "IMB" },
	{ Name = "ScrollingFrame", Tag = "SCR" },
	{ Name = "UIListLayout",   Tag = "LST" },
	{ Name = "UIPadding",      Tag = "PAD" },
}

-- Sharp HUD palette. Single accent: hot pink. No rounding, no glow strokes.
local C = {
	BG        = Color3.fromRGB(8, 8, 11),
	PANEL     = Color3.fromRGB(13, 13, 17),
	PANEL2    = Color3.fromRGB(17, 17, 22),
	ROW       = Color3.fromRGB(20, 20, 26),
	ROW_HOVER = Color3.fromRGB(26, 26, 33),
	ROW_SEL   = Color3.fromRGB(40, 15, 28),
	INPUT     = Color3.fromRGB(11, 11, 14),
	BORDER    = Color3.fromRGB(38, 38, 46),
	ACCENT     = Color3.fromRGB(255, 80, 160), -- #FF50A0
	ACCENT_DIM = Color3.fromRGB(140, 50, 92),
	OK        = Color3.fromRGB(80, 220, 140),
	LIVE      = Color3.fromRGB(255, 80, 160),
	DANGER    = Color3.fromRGB(255, 70, 90),
	TEXT      = Color3.fromRGB(214, 214, 222),
	MUTED     = Color3.fromRGB(120, 120, 132),
	WHITE     = Color3.new(1, 1, 1),
	CANVAS_BG = Color3.fromRGB(11, 11, 15),
	WS_BG     = Color3.fromRGB(15, 15, 19),
}

-- ============================================================
-- HELPERS
-- ============================================================

local function hexToColor(h)
	h = h:gsub("^#", "")
	if #h == 6 then
		local r = tonumber(h:sub(1, 2), 16)
		local g = tonumber(h:sub(3, 4), 16)
		local b = tonumber(h:sub(5, 6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end
	local p = h:split(",")
	if #p == 3 then
		local r, g, b = tonumber(p[1]), tonumber(p[2]), tonumber(p[3])
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end
	return nil
end

local function colorToHex(c)
	return string.format("#%02X%02X%02X", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
end

-- Flat 1px border. No UICorner, no UIStroke glow/thickness games.
local function border(obj, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color or C.BORDER
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = obj
	return s
end

local function label(parent, text, size, color, font)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size or 11
	l.TextColor3 = color or C.TEXT
	l.Font = Enum.Font[font or "Code"]
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

-- Instant state snap. No tweens, no easing — sharp on/off feel.
local function snapState(obj, props)
	for k, v in pairs(props) do
		obj[k] = v
	end
end

local function isGuiObject(inst)
	return inst:IsA("GuiObject") or inst:IsA("UIBase")
end

local function isStructural(inst)
	return inst:IsA("UIListLayout")
		or inst:IsA("UIPadding")
		or inst:IsA("UIGridLayout")
		or inst:IsA("UITableLayout")
		or inst:IsA("UIAspectRatioConstraint")
		or inst:IsA("UISizeConstraint")
		or inst:IsA("UIStroke")
		or inst:IsA("UICorner")
		or inst:IsA("UIGradient")
end

-- ============================================================
-- CORE STATE
-- ============================================================

local GC = {
	State = {
		Mode = "maker",
		IsEnabled = false,
		UI = nil,
		Connections = {},
		CreatedGUIs = {},
		SelectedElement = nil,
		PropertyPanel = nil,
		HierarchyPanel = nil,
		GridFrame = nil,
		UndoStack = {},
		RedoStack = {},
		CurrentProject = { Name = "Untitled" },
		LiveTarget = nil,
		LiveNodes = {},
		LiveSelected = nil,
		LiveSelectedWatch = nil, -- AncestryChanged connection guarding current live selection
		CodePreviewOpen = false,
	},
	Config = {
		GridSize = 20,
		SnapToGrid = false,
		ShowGrid = true,
		DefaultSize = UDim2.fromOffset(200, 100),
	},
	UI = {},
}

function GC:PushUndo(action)
	table.insert(self.State.UndoStack, action)
	self.State.RedoStack = {}
	if #self.State.UndoStack > 60 then
		table.remove(self.State.UndoStack, 1)
	end
end

function GC:Undo()
	local a = table.remove(self.State.UndoStack)
	if not a then
		return
	end
	table.insert(self.State.RedoStack, a)
	a.Undo()
	self:RefreshHierarchy()
end

function GC:Redo()
	local a = table.remove(self.State.RedoStack)
	if not a then
		return
	end
	table.insert(self.State.UndoStack, a)
	a.Do()
	self:RefreshHierarchy()
end

function GC:Snap(v)
	if not self.Config.SnapToGrid then
		return v
	end
	local g = self.Config.GridSize
	return math.floor((v + g / 2) / g) * g
end

function GC:GetData(element)
	for _, d in ipairs(self.State.CreatedGUIs) do
		if d.Element == element then
			return d
		end
	end
end

-- Flat HUD button: square corners, 1px border, instant hover snap (no tween).
function GC:MakeBtn(text, color, parent, w, h)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.fromOffset(w or 110, h or 26)
	btn.BackgroundColor3 = C.INPUT
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.Code
	btn.Text = text
	btn.TextColor3 = color
	btn.TextSize = 11
	btn.AutoButtonColor = false
	btn.Parent = parent
	border(btn, color, 1)
	btn.MouseEnter:Connect(function()
		snapState(btn, { BackgroundColor3 = color, TextColor3 = C.BG })
	end)
	btn.MouseLeave:Connect(function()
		snapState(btn, { BackgroundColor3 = C.INPUT, TextColor3 = color })
	end)
	return btn
end

function GC:MakeDraggable(handle, obj)
	local drag, ds, sp = false, nil, nil
	handle.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = true
			ds = inp.Position
			sp = obj.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					drag = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - ds
			obj.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
end

function GC:DrawGrid()
	local gf = self.State.GridFrame
	if not gf then
		return
	end
	for _, c in ipairs(gf:GetChildren()) do
		c:Destroy()
	end
	if not self.Config.ShowGrid then
		return
	end
	local ws = gf.Parent
	local W, H = ws.AbsoluteSize.X, ws.AbsoluteSize.Y
	local g = self.Config.GridSize
	for x = 0, W, g do
		local line = Instance.new("Frame")
		line.Size = UDim2.new(0, 1, 1, 0)
		line.Position = UDim2.fromOffset(x, 0)
		line.BackgroundColor3 = C.BORDER
		line.BackgroundTransparency = 0.5
		line.BorderSizePixel = 0
		line.ZIndex = 1
		line.Parent = gf
	end
	for y = 0, H, g do
		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.fromOffset(0, y)
		line.BackgroundColor3 = C.BORDER
		line.BackgroundTransparency = 0.5
		line.BorderSizePixel = 0
		line.ZIndex = 1
		line.Parent = gf
	end
end

function GC:_bindKeyboard()
	local conn = UserInputService.InputBegan:Connect(function(inp, gpe)
		if gpe then
			return
		end
		local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
			or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
		if ctrl and inp.KeyCode == Enum.KeyCode.Z then
			self:Undo()
		end
		if ctrl and inp.KeyCode == Enum.KeyCode.Y then
			self:Redo()
		end
		if ctrl and inp.KeyCode == Enum.KeyCode.D and self.State.SelectedElement then
			if self.State.Mode == "maker" then
				self:DuplicateElement(self.State.SelectedElement)
			end
		end
		if inp.KeyCode == Enum.KeyCode.Delete and self.State.SelectedElement then
			if self.State.Mode == "maker" then
				self:DeleteElement(self.State.SelectedElement)
			end
		end
	end)
	table.insert(self.State.Connections, conn)
end

-- ============================================================
-- MAKER MODE — TOOLBOX / ELEMENT CREATION
-- ============================================================

function GC:PopulateToolbox(parent)
	for _, et in ipairs(ELEM_TYPES) do
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 30)
		btn.BackgroundColor3 = C.ROW
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.Code
		btn.Text = "[" .. et.Tag .. "]  " .. et.Name
		btn.TextColor3 = C.TEXT
		btn.TextSize = 11
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.AutoButtonColor = false
		btn.Parent = parent
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.Parent = btn
		btn.MouseEnter:Connect(function()
			snapState(btn, { BackgroundColor3 = C.ROW_HOVER, TextColor3 = C.ACCENT })
		end)
		btn.MouseLeave:Connect(function()
			snapState(btn, { BackgroundColor3 = C.ROW, TextColor3 = C.TEXT })
		end)
		btn.MouseButton1Click:Connect(function()
			self:CreateElement(et.Name)
		end)
	end
end

function GC:CreateElement(etype, snapshot)
	local ws = self.UI.Workspace
	local element = Instance.new(etype)
	local idx = #self.State.CreatedGUIs + 1
	element.Name = etype .. "_" .. idx
	element.BorderSizePixel = 0
	element.ZIndex = (snapshot and snapshot.ZIndex) or (idx + 2)
	local isStruct = etype == "UIListLayout" or etype == "UIPadding"
	if not isStruct then
		element.Size = (snapshot and snapshot.Size) or self.Config.DefaultSize
		element.Position = (snapshot and snapshot.Position)
			or UDim2.fromOffset(self:Snap(math.random(40, 260)), self:Snap(math.random(40, 180)))
		element.BackgroundColor3 = (snapshot and snapshot.BackgroundColor3) or C.PANEL2
	end
	if etype == "TextLabel" or etype == "TextButton" or etype == "TextBox" then
		element.Text = (snapshot and snapshot.Text) or element.Name
		element.TextColor3 = (snapshot and snapshot.TextColor3) or C.TEXT
		element.Font = (snapshot and snapshot.Font) or Enum.Font.Code
		element.TextSize = (snapshot and snapshot.TextSize) or 14
		element.TextXAlignment = (snapshot and snapshot.TextXAlignment) or Enum.TextXAlignment.Left
		element.TextYAlignment = (snapshot and snapshot.TextYAlignment) or Enum.TextYAlignment.Center
		if etype == "TextBox" then
			element.PlaceholderText = "Enter text..."
			element.ClearTextOnFocus = false
		end
	end
	if etype == "ImageLabel" or etype == "ImageButton" then
		element.Image = (snapshot and snapshot.Image) or "rbxasset://textures/ui/GuiImagePlaceholder.png"
		element.ScaleType = Enum.ScaleType.Fit
	end
	if etype == "ScrollingFrame" then
		element.ScrollingEnabled = true
		element.ScrollBarThickness = 4
		element.ScrollBarImageColor3 = C.ACCENT
		element.CanvasSize = (snapshot and snapshot.CanvasSize) or UDim2.fromOffset(480, 720)
	end
	if etype == "UIListLayout" then
		element.Padding = UDim.new(0, 4)
		element.SortOrder = Enum.SortOrder.LayoutOrder
		element.FillDirection = Enum.FillDirection.Vertical
	end
	if etype == "UIPadding" then
		element.PaddingTop = UDim.new(0, 8)
		element.PaddingBottom = UDim.new(0, 8)
		element.PaddingLeft = UDim.new(0, 8)
		element.PaddingRight = UDim.new(0, 8)
	end
	-- No UICorner injected: sharp-corner aesthetic by default for built elements.
	if not isStruct then
		border(element, C.BORDER, 1)
	end
	element.Parent = ws
	local data = {
		Element = element,
		Type = etype,
		Connections = {},
		IsStruct = isStruct,
	}
	table.insert(self.State.CreatedGUIs, data)
	if not isStruct then
		self:MakeElementInteractive(element, data)
	end
	self:RefreshHierarchy()
	self:SelectElement(element)
	if not snapshot then
		self:PushUndo({
			Do = function()
				element.Parent = ws
				table.insert(self.State.CreatedGUIs, data)
				self:RefreshHierarchy()
			end,
			Undo = function()
				element.Parent = nil
				for i, d in ipairs(self.State.CreatedGUIs) do
					if d.Element == element then
						table.remove(self.State.CreatedGUIs, i)
						break
					end
				end
				if self.State.SelectedElement == element then
					self.State.SelectedElement = nil
					self:UpdatePropertiesPanel(nil)
				end
				self:RefreshHierarchy()
			end,
		})
	end
	return element
end

function GC:DuplicateElement(element)
	local data = self:GetData(element)
	if not data then
		return
	end
	local snap = {
		Size = UDim2.fromOffset(element.Size.X.Offset, element.Size.Y.Offset),
		Position = UDim2.fromOffset(element.Position.X.Offset + 15, element.Position.Y.Offset + 15),
		BackgroundColor3 = element.BackgroundColor3,
		ZIndex = element.ZIndex,
	}
	if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
		snap.Text = element.Text
		snap.TextColor3 = element.TextColor3
		snap.TextSize = element.TextSize
		snap.Font = element.Font
		snap.TextXAlignment = element.TextXAlignment
		snap.TextYAlignment = element.TextYAlignment
	end
	if element:IsA("ImageLabel") or element:IsA("ImageButton") then
		snap.Image = element.Image
	end
	if element:IsA("ScrollingFrame") then
		snap.CanvasSize = UDim2.fromOffset(element.CanvasSize.X.Offset, element.CanvasSize.Y.Offset)
	end
	self:CreateElement(data.Type, snap)
end

-- ============================================================
-- MAKER MODE — DRAG / RESIZE / SELECT / DELETE
-- ============================================================

function GC:MakeElementInteractive(element, data)
	local canvasPanel = self.UI.Canvas
	local selBox = Instance.new("Frame")
	selBox.Name = "SelBox_" .. element.Name
	selBox.BackgroundTransparency = 1
	selBox.BorderSizePixel = 0
	selBox.Visible = false
	selBox.ZIndex = 200
	selBox.Parent = canvasPanel
	border(selBox, C.ACCENT, 1)

	local function syncSel()
		if not element or not element.Parent then
			return
		end
		local ws = self.UI.Workspace
		local wsAbs = ws.AbsolutePosition
		local cpAbs = canvasPanel.AbsolutePosition
		local ox = (wsAbs.X - cpAbs.X) + element.Position.X.Offset
		local oy = (wsAbs.Y - cpAbs.Y) + element.Position.Y.Offset
		selBox.Size = UDim2.fromOffset(element.AbsoluteSize.X + 6, element.AbsoluteSize.Y + 6)
		selBox.Position = UDim2.fromOffset(ox - 3, oy - 3)
	end

	local HANDLES = {
		{ n = "NW", ax = 0,   ay = 0,   cx = true,  cy = true  },
		{ n = "N",  ax = 0.5, ay = 0,   cx = false, cy = true  },
		{ n = "NE", ax = 1,   ay = 0,   cx = true,  cy = true  },
		{ n = "W",  ax = 0,   ay = 0.5, cx = true,  cy = false },
		{ n = "E",  ax = 1,   ay = 0.5, cx = true,  cy = false },
		{ n = "SW", ax = 0,   ay = 1,   cx = true,  cy = true  },
		{ n = "S",  ax = 0.5, ay = 1,   cx = false, cy = true  },
		{ n = "SE", ax = 1,   ay = 1,   cx = true,  cy = true  },
	}
	local hInst = {}
	for _, hd in ipairs(HANDLES) do
		local h = Instance.new("TextButton")
		h.Size = UDim2.fromOffset(8, 8)
		h.AnchorPoint = Vector2.new(0.5, 0.5)
		h.Position = UDim2.new(hd.ax, 0, hd.ay, 0)
		h.BackgroundColor3 = C.ACCENT
		h.BorderSizePixel = 0
		h.ZIndex = 201
		h.Text = ""
		h.AutoButtonColor = false
		h.Parent = selBox
		hInst[hd.n] = { frame = h, meta = hd }
	end

	local resizing, dragging, resizeHandle = false, false, nil
	local dragStart, startPos, startSize = nil, nil, nil

	for _, hdata in pairs(hInst) do
		hdata.frame.MouseButton1Down:Connect(function()
			self:SelectElement(element)
			resizing = true
			dragging = false
			resizeHandle = hdata.meta
			dragStart = UserInputService:GetMouseLocation()
			startPos = { X = element.Position.X.Offset, Y = element.Position.Y.Offset }
			startSize = { W = element.Size.X.Offset, H = element.Size.Y.Offset }
		end)
	end

	local ec = element.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if resizing then
			return
		end
		self:SelectElement(element)
		dragging = true
		dragStart = inp.Position
		startPos = { X = element.Position.X.Offset, Y = element.Position.Y.Offset }
		startSize = { W = element.Size.X.Offset, H = element.Size.Y.Offset }
	end)

	local mc = UserInputService.InputChanged:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		if resizing and resizeHandle then
			local mn = UserInputService:GetMouseLocation()
			local d = mn - dragStart
			local hd = resizeHandle
			local nx, ny = startPos.X, startPos.Y
			local nw, nh = startSize.W, startSize.H
			if hd.cx then
				if hd.ax == 0 then
					nw = math.max(20, startSize.W - d.X)
					nx = startPos.X + (startSize.W - nw)
				else
					nw = math.max(20, startSize.W + d.X)
				end
			end
			if hd.cy then
				if hd.ay == 0 then
					nh = math.max(20, startSize.H - d.Y)
					ny = startPos.Y + (startSize.H - nh)
				else
					nh = math.max(20, startSize.H + d.Y)
				end
			end
			element.Position = UDim2.fromOffset(self:Snap(nx), self:Snap(ny))
			element.Size = UDim2.fromOffset(self:Snap(nw), self:Snap(nh))
			syncSel()
			self:UpdatePropertiesPanel(element)
		elseif dragging then
			local d = inp.Position - dragStart
			element.Position = UDim2.fromOffset(self:Snap(startPos.X + d.X), self:Snap(startPos.Y + d.Y))
			syncSel()
		end
	end)

	local rc = UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if (dragging or resizing) and startPos and startSize then
			local oldPos = UDim2.fromOffset(startPos.X, startPos.Y)
			local oldSize = UDim2.fromOffset(startSize.W, startSize.H)
			local newPos, newSize = element.Position, element.Size
			if oldPos ~= newPos or oldSize ~= newSize then
				self:PushUndo({
					Do = function()
						element.Position = newPos
						element.Size = newSize
						syncSel()
						self:UpdatePropertiesPanel(element)
					end,
					Undo = function()
						element.Position = oldPos
						element.Size = oldSize
						syncSel()
						self:UpdatePropertiesPanel(element)
					end,
				})
			end
		end
		dragging = false
		resizing = false
		resizeHandle = nil
	end)

	data.Connections = { ec, mc, rc }
	data.SelectionBox = selBox
	data.SyncSelBox = syncSel
end

function GC:SelectElement(element)
	if self.State.SelectedElement == element then
		return
	end
	if self.State.SelectedElement then
		local od = self:GetData(self.State.SelectedElement)
		if od and od.SelectionBox then
			od.SelectionBox.Visible = false
		end
	end
	self.State.SelectedElement = element
	local d = self:GetData(element)
	if d and d.SelectionBox then
		d.SyncSelBox()
		d.SelectionBox.Visible = true
	end
	self:UpdatePropertiesPanel(element)
	self:RefreshHierarchy()
end

function GC:DeleteElement(element)
	local savedType, savedData
	for i, d in ipairs(self.State.CreatedGUIs) do
		if d.Element == element then
			savedType = d.Type
			savedData = d
			table.remove(self.State.CreatedGUIs, i)
			break
		end
	end
	if not savedData then
		return
	end
	if savedData.Connections then
		for _, c in ipairs(savedData.Connections) do
			if c then
				c:Disconnect()
			end
		end
	end
	if savedData.SelectionBox then
		savedData.SelectionBox:Destroy()
	end
	local snap = {
		Size = element.Size,
		Position = element.Position,
		BackgroundColor3 = element.BackgroundColor3,
		ZIndex = element.ZIndex,
	}
	if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
		snap.Text = element.Text
		snap.TextColor3 = element.TextColor3
		snap.TextSize = element.TextSize
		snap.Font = element.Font
		snap.TextXAlignment = element.TextXAlignment
		snap.TextYAlignment = element.TextYAlignment
	end
	if element:IsA("ImageLabel") or element:IsA("ImageButton") then
		snap.Image = element.Image
	end
	if element:IsA("ScrollingFrame") then
		snap.CanvasSize = UDim2.fromOffset(element.CanvasSize.X.Offset, element.CanvasSize.Y.Offset)
	end
	element:Destroy()
	self.State.SelectedElement = nil
	self:UpdatePropertiesPanel(nil)
	self:RefreshHierarchy()
	self:PushUndo({
		Undo = function()
			self:CreateElement(savedType, snap)
		end,
		Do = function()
			local l = self.State.CreatedGUIs[#self.State.CreatedGUIs]
			if l then
				self:DeleteElement(l.Element)
			end
		end,
	})
end

function GC:ClearCanvas()
	for _, d in ipairs(self.State.CreatedGUIs) do
		if d.Connections then
			for _, c in ipairs(d.Connections) do
				if c then
					c:Disconnect()
				end
			end
		end
		if d.SelectionBox then
			d.SelectionBox:Destroy()
		end
		if d.Element then
			d.Element:Destroy()
		end
	end
	self.State.CreatedGUIs = {}
	self.State.UndoStack = {}
	self.State.RedoStack = {}
	self.State.SelectedElement = nil
	self:UpdatePropertiesPanel(nil)
	self:RefreshHierarchy()
end

function GC:RefreshHierarchy()
	if self.State.Mode == "live" then
		self:RefreshLiveHierarchy()
		return
	end
	local panel = self.State.HierarchyPanel
	if not panel then
		return
	end
	for _, c in ipairs(panel:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	for _, d in ipairs(self.State.CreatedGUIs) do
		local e = d.Element
		if not e or not e.Parent then
			continue
		end
		local isSel = (self.State.SelectedElement == e)
		local row = Instance.new("TextButton")
		row.Size = UDim2.new(1, -6, 0, 24)
		row.BorderSizePixel = 0
		row.Font = Enum.Font.Code
		row.TextSize = 11
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.AutoButtonColor = false
		row.BackgroundColor3 = isSel and C.ROW_SEL or C.ROW
		row.TextColor3 = isSel and C.ACCENT or C.MUTED
		row.Text = "  [" .. e.ZIndex .. "]  " .. e.Name
		row.Parent = panel
		if isSel then
			border(row, C.ACCENT, 1)
		end
		row.MouseButton1Click:Connect(function()
			self:SelectElement(e)
		end)
		local function zBtn(lbl, off, delta)
			local b = Instance.new("TextButton")
			b.Size = UDim2.fromOffset(18, 18)
			b.Position = UDim2.new(1, off, 0.5, -9)
			b.BackgroundColor3 = C.INPUT
			b.BorderSizePixel = 0
			b.Font = Enum.Font.Code
			b.Text = lbl
			b.TextSize = 10
			b.TextColor3 = C.MUTED
			b.Parent = row
			b.MouseButton1Click:Connect(function()
				local oz = e.ZIndex
				local nz = math.max(3, oz + delta)
				e.ZIndex = nz
				self:PushUndo({
					Do = function()
						e.ZIndex = nz
						self:RefreshHierarchy()
					end,
					Undo = function()
						e.ZIndex = oz
						self:RefreshHierarchy()
					end,
				})
				self:RefreshHierarchy()
				self:UpdatePropertiesPanel(e)
			end)
		end
		zBtn("+", -42, 1)
		zBtn("-", -21, -1)
	end
end

-- ============================================================
-- MAKER MODE — PROPERTIES PANEL
-- ============================================================

function GC:UpdatePropertiesPanel(element)
	local panel = self.State.PropertyPanel
	if not panel then
		return
	end
	for _, c in ipairs(panel:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	if not element then
		return
	end
	local data = self:GetData(element)

	local function row(h)
		local con = Instance.new("Frame")
		con.Size = UDim2.new(1, -6, 0, h)
		con.BackgroundColor3 = C.ROW
		con.BorderSizePixel = 0
		con.Parent = panel
		return con
	end

	local function prop(name, val, onChange)
		local con = row(42)
		local lbl = label(con, name, 10, C.MUTED)
		lbl.Size = UDim2.new(1, -10, 0, 16)
		lbl.Position = UDim2.fromOffset(6, 3)
		local inp = Instance.new("TextBox")
		inp.Size = UDim2.new(1, -12, 0, 18)
		inp.Position = UDim2.fromOffset(6, 21)
		inp.BackgroundColor3 = C.INPUT
		inp.BorderSizePixel = 0
		inp.Font = Enum.Font.Code
		inp.Text = tostring(val)
		inp.TextColor3 = C.WHITE
		inp.TextSize = 11
		inp.ClearTextOnFocus = false
		inp.Parent = con
		border(inp, C.BORDER, 1)
		inp.Focused:Connect(function()
			border(inp, C.ACCENT, 1)
		end)
		inp.FocusLost:Connect(function()
			for _, s in ipairs(inp:GetChildren()) do
				if s:IsA("UIStroke") then s:Destroy() end
			end
			border(inp, C.BORDER, 1)
			onChange(inp.Text)
		end)
	end

	local function colorProp(name, color, onChange)
		local con = row(44)
		local lbl = label(con, name, 10, C.MUTED)
		lbl.Size = UDim2.new(1, -46, 0, 16)
		lbl.Position = UDim2.fromOffset(6, 3)
		local preview = Instance.new("Frame")
		preview.Size = UDim2.fromOffset(24, 24)
		preview.Position = UDim2.new(1, -30, 0, 3)
		preview.BackgroundColor3 = color
		preview.BorderSizePixel = 0
		preview.Parent = con
		border(preview, C.BORDER, 1)
		local inp = Instance.new("TextBox")
		inp.Size = UDim2.new(1, -12, 0, 18)
		inp.Position = UDim2.fromOffset(6, 23)
		inp.BackgroundColor3 = C.INPUT
		inp.BorderSizePixel = 0
		inp.Font = Enum.Font.Code
		inp.Text = colorToHex(color)
		inp.TextColor3 = C.WHITE
		inp.TextSize = 11
		inp.PlaceholderText = "#RRGGBB or R,G,B"
		inp.ClearTextOnFocus = false
		inp.Parent = con
		border(inp, C.BORDER, 1)
		inp.FocusLost:Connect(function()
			local nc = hexToColor(inp.Text)
			if nc then
				preview.BackgroundColor3 = nc
				onChange(nc)
				inp.Text = colorToHex(nc)
			end
		end)
	end

	local function toggleProp(name, val, onChange)
		local con = row(30)
		local lbl = label(con, name, 10, C.MUTED)
		lbl.Size = UDim2.new(1, -54, 1, 0)
		lbl.Position = UDim2.fromOffset(6, 0)
		local v = val
		local tb = Instance.new("TextButton")
		tb.Size = UDim2.fromOffset(44, 20)
		tb.Position = UDim2.new(1, -50, 0.5, -10)
		tb.BackgroundColor3 = C.INPUT
		tb.BorderSizePixel = 0
		tb.Font = Enum.Font.Code
		tb.TextSize = 10
		tb.AutoButtonColor = false
		tb.Parent = con
		local function ref()
			tb.Text = v and "ON" or "OFF"
			tb.TextColor3 = v and C.OK or C.DANGER
		end
		ref()
		border(tb, C.BORDER, 1)
		tb.MouseButton1Click:Connect(function()
			v = not v
			ref()
			onChange(v)
		end)
	end

	local function dropProp(name, options, current, onChange)
		local con = row(42)
		local lbl = label(con, name, 10, C.MUTED)
		lbl.Size = UDim2.new(1, -10, 0, 16)
		lbl.Position = UDim2.fromOffset(6, 3)
		local ci = 1
		for i, v in ipairs(options) do
			if v == current then
				ci = i
				break
			end
		end
		local curLabel = Instance.new("TextButton")
		curLabel.Size = UDim2.new(1, -12, 0, 18)
		curLabel.Position = UDim2.fromOffset(6, 21)
		curLabel.BackgroundColor3 = C.INPUT
		curLabel.BorderSizePixel = 0
		curLabel.Font = Enum.Font.Code
		curLabel.Text = "< " .. options[ci] .. " >"
		curLabel.TextColor3 = C.ACCENT
		curLabel.TextSize = 11
		curLabel.AutoButtonColor = false
		curLabel.Parent = con
		border(curLabel, C.BORDER, 1)
		curLabel.MouseButton1Click:Connect(function()
			ci = ci % #options + 1
			curLabel.Text = "< " .. options[ci] .. " >"
			onChange(options[ci])
		end)
	end

	prop("Name", element.Name, function(v)
		local old = element.Name
		element.Name = v
		self:PushUndo({
			Do = function() element.Name = v end,
			Undo = function() element.Name = old end,
		})
		self:RefreshHierarchy()
	end)

	local isStruct = data and data.IsStruct
	if not isStruct then
		prop("Size X", element.Size.X.Offset, function(v)
			element.Size = UDim2.fromOffset(tonumber(v) or 200, element.Size.Y.Offset)
			if data then data.SyncSelBox() end
		end)
		prop("Size Y", element.Size.Y.Offset, function(v)
			element.Size = UDim2.fromOffset(element.Size.X.Offset, tonumber(v) or 100)
			if data then data.SyncSelBox() end
		end)
		prop("Pos X", element.Position.X.Offset, function(v)
			element.Position = UDim2.fromOffset(tonumber(v) or 0, element.Position.Y.Offset)
			if data then data.SyncSelBox() end
		end)
		prop("Pos Y", element.Position.Y.Offset, function(v)
			element.Position = UDim2.fromOffset(element.Position.X.Offset, tonumber(v) or 0)
			if data then data.SyncSelBox() end
		end)
		prop("ZIndex", element.ZIndex, function(v)
			local old = element.ZIndex
			local nz = math.max(1, tonumber(v) or 1)
			element.ZIndex = nz
			self:PushUndo({
				Do = function() element.ZIndex = nz end,
				Undo = function() element.ZIndex = old end,
			})
			self:RefreshHierarchy()
		end)
		prop("LayoutOrder", element.LayoutOrder, function(v)
			element.LayoutOrder = tonumber(v) or 0
		end)
		prop("Rotation", element.Rotation, function(v)
			element.Rotation = tonumber(v) or 0
		end)
		prop("AnchorPoint X", element.AnchorPoint.X, function(v)
			element.AnchorPoint = Vector2.new(math.clamp(tonumber(v) or 0, 0, 1), element.AnchorPoint.Y)
			if data then data.SyncSelBox() end
		end)
		prop("AnchorPoint Y", element.AnchorPoint.Y, function(v)
			element.AnchorPoint = Vector2.new(element.AnchorPoint.X, math.clamp(tonumber(v) or 0, 0, 1))
			if data then data.SyncSelBox() end
		end)
		colorProp("BG Color", element.BackgroundColor3, function(c)
			element.BackgroundColor3 = c
		end)
		prop("BG Transparency", element.BackgroundTransparency, function(v)
			element.BackgroundTransparency = math.clamp(tonumber(v) or 0, 0, 1)
		end)
		toggleProp("Visible", element.Visible, function(v)
			element.Visible = v
		end)
	end

	if element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
		prop("Text", element.Text, function(v) element.Text = v end)
		prop("Text Size", element.TextSize, function(v) element.TextSize = tonumber(v) or 14 end)
		colorProp("Text Color", element.TextColor3, function(c) element.TextColor3 = c end)
		prop("Text Transparency", element.TextTransparency, function(v)
			element.TextTransparency = math.clamp(tonumber(v) or 0, 0, 1)
		end)
		toggleProp("Text Wrapped", element.TextWrapped, function(v) element.TextWrapped = v end)
		toggleProp("Text Scaled", element.TextScaled, function(v) element.TextScaled = v end)
		local fontName = tostring(element.Font):gsub("Enum%.Font%.", "")
		dropProp("Font", FONTS, fontName, function(v)
			pcall(function() element.Font = Enum.Font[v] end)
		end)
		dropProp("H Align", HALIGN, tostring(element.TextXAlignment):gsub("Enum%.TextXAlignment%.", ""), function(v)
			pcall(function() element.TextXAlignment = Enum.TextXAlignment[v] end)
		end)
		dropProp("V Align", VALIGN, tostring(element.TextYAlignment):gsub("Enum%.TextYAlignment%.", ""), function(v)
			pcall(function() element.TextYAlignment = Enum.TextYAlignment[v] end)
		end)
		if element:IsA("TextBox") then
			prop("Placeholder", element.PlaceholderText, function(v) element.PlaceholderText = v end)
			toggleProp("Clear On Focus", element.ClearTextOnFocus, function(v) element.ClearTextOnFocus = v end)
		end
	end

	if element:IsA("ImageLabel") or element:IsA("ImageButton") then
		prop("Image ID", element.Image, function(v) element.Image = v end)
		prop("Image Transparency", element.ImageTransparency, function(v)
			element.ImageTransparency = math.clamp(tonumber(v) or 0, 0, 1)
		end)
		dropProp("Scale Type", SCALETYPES, tostring(element.ScaleType):gsub("Enum%.ScaleType%.", ""), function(v)
			pcall(function() element.ScaleType = Enum.ScaleType[v] end)
		end)
	end

	if element:IsA("ScrollingFrame") then
		prop("Canvas W", element.CanvasSize.X.Offset, function(v)
			element.CanvasSize = UDim2.fromOffset(tonumber(v) or 480, element.CanvasSize.Y.Offset)
		end)
		prop("Canvas H", element.CanvasSize.Y.Offset, function(v)
			element.CanvasSize = UDim2.fromOffset(element.CanvasSize.X.Offset, tonumber(v) or 720)
		end)
		prop("Scrollbar Thickness", element.ScrollBarThickness, function(v)
			element.ScrollBarThickness = tonumber(v) or 6
		end)
		toggleProp("Scrolling Enabled", element.ScrollingEnabled, function(v) element.ScrollingEnabled = v end)
	end

	if element:IsA("UIListLayout") then
		prop("Padding", element.Padding.Offset, function(v)
			element.Padding = UDim.new(0, tonumber(v) or 4)
		end)
		dropProp("Fill Direction", { "Vertical", "Horizontal" },
			tostring(element.FillDirection):gsub("Enum%.FillDirection%.", ""), function(v)
				pcall(function() element.FillDirection = Enum.FillDirection[v] end)
			end)
		dropProp("H Align", { "Left", "Center", "Right" },
			tostring(element.HorizontalAlignment):gsub("Enum%.HorizontalAlignment%.", ""), function(v)
				pcall(function() element.HorizontalAlignment = Enum.HorizontalAlignment[v] end)
			end)
		dropProp("V Align", { "Top", "Center", "Bottom" },
			tostring(element.VerticalAlignment):gsub("Enum%.VerticalAlignment%.", ""), function(v)
				pcall(function() element.VerticalAlignment = Enum.VerticalAlignment[v] end)
			end)
	end

	if element:IsA("UIPadding") then
		prop("Pad Top", element.PaddingTop.Offset, function(v) element.PaddingTop = UDim.new(0, tonumber(v) or 0) end)
		prop("Pad Bottom", element.PaddingBottom.Offset, function(v) element.PaddingBottom = UDim.new(0, tonumber(v) or 0) end)
		prop("Pad Left", element.PaddingLeft.Offset, function(v) element.PaddingLeft = UDim.new(0, tonumber(v) or 0) end)
		prop("Pad Right", element.PaddingRight.Offset, function(v) element.PaddingRight = UDim.new(0, tonumber(v) or 0) end)
	end

	if not isStruct then
		local dupBtn = self:MakeBtn("DUPLICATE  [CTRL+D]", C.ACCENT, panel, 0, 28)
		dupBtn.Size = UDim2.new(1, -6, 0, 28)
		dupBtn.MouseButton1Click:Connect(function() self:DuplicateElement(element) end)
	end
	local delBtn = self:MakeBtn("DELETE ELEMENT", C.DANGER, panel, 0, 28)
	delBtn.Size = UDim2.new(1, -6, 0, 28)
	delBtn.MouseButton1Click:Connect(function() self:DeleteElement(element) end)
end

-- ============================================================
-- CODE EXPORT
-- ============================================================

function GC:ExportCode()
	local lines = {}
	local w = function(s) table.insert(lines, s) end
	w("-- ============================================")
	w("-- Generated by GUI Creator v3 (ZukaTech)")
	w("-- Project: " .. self.State.CurrentProject.Name)
	w("-- ============================================")
	w("local Players     = game:GetService('Players')")
	w("local LocalPlayer = Players.LocalPlayer")
	w("")
	w("local ScreenGui = Instance.new('ScreenGui')")
	w("ScreenGui.Name           = '" .. self.State.CurrentProject.Name .. "'")
	w("ScreenGui.ResetOnSpawn   = false")
	w("ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling")
	w("ScreenGui.Parent         = LocalPlayer:WaitForChild('PlayerGui')")
	w("")
	for _, data in ipairs(self.State.CreatedGUIs) do
		local e = data.Element
		if not e or not e.Parent then
			continue
		end
		local n = e.Name
		w("-- " .. n)
		w(string.format("local %s = Instance.new('%s')", n, data.Type))
		w(string.format("%s.Name = '%s'", n, n))
		if not data.IsStruct then
			w(string.format("%s.Size = UDim2.fromOffset(%d, %d)", n, e.Size.X.Offset, e.Size.Y.Offset))
			w(string.format("%s.Position = UDim2.fromOffset(%d, %d)", n, e.Position.X.Offset, e.Position.Y.Offset))
			w(string.format("%s.AnchorPoint = Vector2.new(%g, %g)", n, e.AnchorPoint.X, e.AnchorPoint.Y))
			w(string.format("%s.Rotation = %g", n, e.Rotation))
			w(string.format("%s.LayoutOrder = %d", n, e.LayoutOrder))
			w(string.format(
				"%s.BackgroundColor3 = Color3.fromRGB(%d, %d, %d)",
				n,
				math.round(e.BackgroundColor3.R * 255),
				math.round(e.BackgroundColor3.G * 255),
				math.round(e.BackgroundColor3.B * 255)
			))
			w(string.format("%s.BackgroundTransparency = %g", n, e.BackgroundTransparency))
			w(string.format("%s.BorderSizePixel = 0", n))
			w(string.format("%s.ZIndex = %d", n, e.ZIndex))
			w(string.format("%s.Visible = %s", n, tostring(e.Visible)))
		end
		if e:IsA("TextLabel") or e:IsA("TextButton") or e:IsA("TextBox") then
			w(string.format("%s.Text = '%s'", n, e.Text:gsub("'", "\\'")))
			w(string.format(
				"%s.TextColor3 = Color3.fromRGB(%d, %d, %d)",
				n,
				math.round(e.TextColor3.R * 255),
				math.round(e.TextColor3.G * 255),
				math.round(e.TextColor3.B * 255)
			))
			w(string.format("%s.TextSize = %d", n, e.TextSize))
			w(string.format("%s.Font = Enum.Font.%s", n, tostring(e.Font):gsub("Enum%.Font%.", "")))
			w(string.format("%s.TextXAlignment = Enum.TextXAlignment.%s", n,
				tostring(e.TextXAlignment):gsub("Enum%.TextXAlignment%.", "")))
			w(string.format("%s.TextYAlignment = Enum.TextYAlignment.%s", n,
				tostring(e.TextYAlignment):gsub("Enum%.TextYAlignment%.", "")))
			w(string.format("%s.TextWrapped = %s", n, tostring(e.TextWrapped)))
		end
		if e:IsA("ImageLabel") or e:IsA("ImageButton") then
			w(string.format("%s.Image = '%s'", n, e.Image))
			w(string.format("%s.ScaleType = Enum.ScaleType.%s", n, tostring(e.ScaleType):gsub("Enum%.ScaleType%.", "")))
		end
		if e:IsA("ScrollingFrame") then
			w(string.format("%s.ScrollBarThickness = %d", n, e.ScrollBarThickness))
			w(string.format("%s.CanvasSize = UDim2.fromOffset(%d, %d)", n, e.CanvasSize.X.Offset, e.CanvasSize.Y.Offset))
			w(string.format("%s.ScrollingEnabled = %s", n, tostring(e.ScrollingEnabled)))
		end
		if e:IsA("UIListLayout") then
			w(string.format("%s.Padding = UDim.new(0, %d)", n, e.Padding.Offset))
			w(string.format("%s.FillDirection = Enum.FillDirection.%s", n,
				tostring(e.FillDirection):gsub("Enum%.FillDirection%.", "")))
			w(string.format("%s.SortOrder = Enum.SortOrder.LayoutOrder", n))
		end
		if e:IsA("UIPadding") then
			w(string.format("%s.PaddingTop    = UDim.new(0, %d)", n, e.PaddingTop.Offset))
			w(string.format("%s.PaddingBottom = UDim.new(0, %d)", n, e.PaddingBottom.Offset))
			w(string.format("%s.PaddingLeft   = UDim.new(0, %d)", n, e.PaddingLeft.Offset))
			w(string.format("%s.PaddingRight  = UDim.new(0, %d)", n, e.PaddingRight.Offset))
		end
		if not data.IsStruct then
			w(string.format("do local _s = Instance.new('UIStroke', %s); _s.Color = Color3.fromRGB(38,38,46); _s.Thickness = 1 end", n))
		end
		w(string.format("%s.Parent = ScreenGui", n))
		w("")
	end
	local code = table.concat(lines, "\n")
	self:ShowCodePreview(code)
	if setclipboard then
		setclipboard(code)
		print("[GUICreator] Copied to clipboard")
	else
		print(code)
	end
end

function GC:ShowCodePreview(code)
	local existing = self.UI.MainFrame:FindFirstChild("CodePreview")
	if existing then
		existing:Destroy()
	end
	local panel = Instance.new("Frame")
	panel.Name = "CodePreview"
	panel.Size = UDim2.new(0, 520, 1, -90)
	panel.Position = UDim2.new(0.5, -260, 0, 86)
	panel.BackgroundColor3 = C.BG
	panel.BorderSizePixel = 0
	panel.ZIndex = 500
	panel.Parent = self.UI.MainFrame
	border(panel, C.ACCENT, 1)

	local topbar = Instance.new("Frame")
	topbar.Size = UDim2.new(1, 0, 0, 30)
	topbar.BackgroundColor3 = C.PANEL
	topbar.BorderSizePixel = 0
	topbar.Parent = panel
	local ttl = label(topbar, "GENERATED CODE", 12, C.ACCENT)
	ttl.Size = UDim2.new(1, -90, 1, 0)
	ttl.Position = UDim2.fromOffset(10, 0)
	local closeBtn = self:MakeBtn("CLOSE", C.DANGER, topbar, 70, 22)
	closeBtn.Position = UDim2.new(1, -78, 0.5, -11)
	closeBtn.MouseButton1Click:Connect(function() panel:Destroy() end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -16, 1, -38)
	scroll.Position = UDim2.fromOffset(8, 34)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = C.ACCENT
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = panel
	local codeLabel = Instance.new("TextLabel")
	codeLabel.Size = UDim2.new(1, -10, 0, 0)
	codeLabel.AutomaticSize = Enum.AutomaticSize.Y
	codeLabel.BackgroundTransparency = 1
	codeLabel.Font = Enum.Font.Code
	codeLabel.Text = code
	codeLabel.TextColor3 = C.OK
	codeLabel.TextSize = 11
	codeLabel.TextXAlignment = Enum.TextXAlignment.Left
	codeLabel.TextYAlignment = Enum.TextYAlignment.Top
	codeLabel.TextWrapped = false
	codeLabel.Parent = scroll
end

-- ============================================================
-- LIVE MODE — PICKER / LOAD / EXIT
-- ============================================================

function GC:GetAllScreenGuis()
	local results = {}
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		for _, ch in ipairs(pg:GetChildren()) do
			if ch:IsA("ScreenGui") and ch.Name ~= "GUICreator_Zuka" then
				table.insert(results, ch)
			end
		end
	end
	pcall(function()
		for _, ch in ipairs(CoreGui:GetChildren()) do
			if ch:IsA("ScreenGui") and ch.Name ~= "GUICreator_Zuka" then
				table.insert(results, ch)
			end
		end
	end)
	return results
end

function GC:OpenLivePicker()
	local existing = self.UI.MainFrame:FindFirstChild("LivePicker")
	if existing then
		existing:Destroy()
		return
	end
	local modal = Instance.new("Frame")
	modal.Name = "LivePicker"
	modal.Size = UDim2.fromOffset(340, 420)
	modal.Position = UDim2.new(0.5, -170, 0.5, -210)
	modal.BackgroundColor3 = C.PANEL
	modal.BorderSizePixel = 0
	modal.ZIndex = 600
	modal.Parent = self.UI.MainFrame
	border(modal, C.ACCENT, 1)
	self:MakeDraggable(modal, modal)

	local ttl = label(modal, "SELECT A SCREENGUI TO EDIT", 12, C.ACCENT)
	ttl.Size = UDim2.new(1, 0, 0, 34)
	ttl.Position = UDim2.fromOffset(10, 0)
	local closeBtn = self:MakeBtn("X", C.DANGER, modal, 24, 24)
	closeBtn.Position = UDim2.new(1, -30, 0, 5)
	closeBtn.MouseButton1Click:Connect(function() modal:Destroy() end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -16, 1, -50)
	scroll.Position = UDim2.fromOffset(8, 42)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = C.ACCENT
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = modal
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 4)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = scroll

	local guis = self:GetAllScreenGuis()
	if #guis == 0 then
		local none = label(scroll, "No ScreenGuis found.", 12, C.MUTED)
		none.Size = UDim2.new(1, 0, 0, 36)
		none.TextXAlignment = Enum.TextXAlignment.Center
	else
		for _, gui in ipairs(guis) do
			local childCount = #gui:GetDescendants()
			local row = self:MakeBtn(gui.Name .. "  (" .. childCount .. " descendants)", C.TEXT, scroll, 0, 36)
			row.Size = UDim2.new(1, 0, 0, 36)
			row.TextXAlignment = Enum.TextXAlignment.Left
			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 8)
			pad.Parent = row
			row.MouseButton1Click:Connect(function()
				modal:Destroy()
				self:LoadLiveGui(gui)
			end)
		end
	end

	local refBtn = self:MakeBtn("REFRESH LIST", C.ACCENT, modal, 130, 24)
	refBtn.Position = UDim2.new(0.5, -65, 1, -32)
	refBtn.MouseButton1Click:Connect(function()
		modal:Destroy()
		self:OpenLivePicker()
	end)
end

-- Tears down the watchdog guarding the previously selected live instance, if any.
function GC:_clearLiveWatch()
	if self.State.LiveSelectedWatch then
		self.State.LiveSelectedWatch:Disconnect()
		self.State.LiveSelectedWatch = nil
	end
end

-- Guards the live selection: if the underlying instance is destroyed or
-- reparented out of the tree by the game's own scripts while we're editing
-- it, the property panel clears itself with a visible [DESTROYED] notice
-- instead of silently no-opping every pcall.
function GC:_watchLiveSelection(inst)
	self:_clearLiveWatch()
	self.State.LiveSelectedWatch = inst.AncestryChanged:Connect(function(_, parent)
		if not parent then
			if self.State.LiveSelected == inst then
				self:_showLiveSelectionLost(inst)
			end
		end
	end)
end

function GC:_showLiveSelectionLost(inst)
	self.State.LiveSelected = nil
	self:_clearLiveWatch()
	local panel = self.State.PropertyPanel
	if not panel then
		return
	end
	for _, c in ipairs(panel:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	local hdr = label(panel, "[DESTROYED]  " .. inst.Name .. " was removed from the tree.", 11, C.DANGER)
	hdr.Size = UDim2.new(1, -6, 0, 40)
	hdr.TextWrapped = true
	self:RefreshLiveHierarchy()
end

function GC:LoadLiveGui(gui)
	self.State.Mode = "live"
	self.State.LiveTarget = gui
	self.State.LiveNodes = {}
	self.State.LiveSelected = nil
	self:_clearLiveWatch()
	if self.UI.ModeLabel then
		self.UI.ModeLabel.Text = "LIVE EDIT: " .. gui.Name
		self.UI.ModeLabel.TextColor3 = C.LIVE
	end
	if self.UI.ModeBar then
		self.UI.ModeBar.BackgroundColor3 = C.PANEL
	end
	if self.UI.Toolbox then
		self.UI.Toolbox.Visible = false
	end
	if self.UI.LivePanel then
		self.UI.LivePanel.Visible = true
	end
	if self.UI.Canvas then
		self.UI.Canvas.Visible = false
	end
	if self.UI.HierPanel then
		self.UI.HierPanel.Parent = self.UI.MainFrame
		self.UI.HierPanel.Size = UDim2.new(0, 360, 1, -90)
		self.UI.HierPanel.Position = UDim2.fromOffset(183, 86)
	end
	if self.UI.RightCol then
		self.UI.RightCol.Parent = self.UI.MainFrame
		self.UI.RightCol.Size = UDim2.new(0, 280, 1, -90)
		self.UI.RightCol.Position = UDim2.new(1, -290, 0, 86)
	end
	self:RefreshLiveHierarchy()
	print("[GUICreator] Live editing: " .. gui:GetFullName())
end

function GC:ExitLiveMode()
	self.State.Mode = "maker"
	self.State.LiveTarget = nil
	self.State.LiveNodes = {}
	self.State.LiveSelected = nil
	self:_clearLiveWatch()
	if self.UI.ModeLabel then
		self.UI.ModeLabel.Text = "GUI CREATOR v3 -- CTRL+Z  CTRL+Y  CTRL+D  DEL"
		self.UI.ModeLabel.TextColor3 = C.ACCENT
	end
	if self.UI.ModeBar then
		self.UI.ModeBar.BackgroundColor3 = C.PANEL
	end
	if self.UI.Toolbox then
		self.UI.Toolbox.Visible = true
	end
	if self.UI.LivePanel then
		self.UI.LivePanel.Visible = false
	end
	if self.UI.Canvas then
		self.UI.Canvas.Visible = true
	end
	if self.UI.HierPanel and self.UI.RightCol then
		self.UI.HierPanel.Parent = self.UI.RightCol
		self.UI.HierPanel.Size = UDim2.new(1, 0, 0.48, -4)
		self.UI.HierPanel.Position = UDim2.new(0, 0, 0.52, 4)
	end
	if self.UI.RightCol then
		self.UI.RightCol.Parent = self.UI.MainFrame
		self.UI.RightCol.Size = UDim2.new(0, 240, 1, -90)
		self.UI.RightCol.Position = UDim2.new(1, -250, 0, 86)
	end
	self:UpdatePropertiesPanel(nil)
	self:RefreshHierarchy()
end

-- ============================================================
-- LIVE MODE — HIERARCHY TREE
-- ============================================================

function GC:RefreshLiveHierarchy()
	local panel = self.State.HierarchyPanel
	if not panel then
		return
	end
	for _, c in ipairs(panel:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	local target = self.State.LiveTarget
	if not target then
		return
	end
	local expanded = {}
	for _, nd in ipairs(self.State.LiveNodes) do
		if nd.expanded then
			expanded[nd.inst] = true
		end
	end
	self.State.LiveNodes = {}

	local function typeColorFor(inst)
		if isStructural(inst) then
			return Color3.fromRGB(200, 180, 90)
		elseif inst:IsA("TextButton") or inst:IsA("ImageButton") then
			return Color3.fromRGB(220, 150, 90)
		elseif inst:IsA("TextLabel") then
			return Color3.fromRGB(140, 220, 110)
		elseif inst:IsA("ImageLabel") then
			return Color3.fromRGB(170, 130, 230)
		end
		return Color3.fromRGB(140, 190, 240)
	end

	local function buildTree(inst, depth)
		if not inst or not inst.Parent then
			return
		end
		local isSel = (self.State.LiveSelected == inst)
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -6, 0, 22)
		row.BackgroundColor3 = isSel and C.ROW_SEL or (depth == 0 and C.PANEL2 or C.ROW)
		row.BorderSizePixel = 0
		row.Parent = panel
		if isSel then
			border(row, C.ACCENT, 1)
		end

		local isExpanded = expanded[inst] or false
		local kids = {}
		for _, ch in ipairs(inst:GetChildren()) do
			if isGuiObject(ch) or isStructural(ch) then
				table.insert(kids, ch)
			end
		end
		local hasKids = #kids > 0

		local toggle = Instance.new("TextButton")
		toggle.Size = UDim2.fromOffset(16, 16)
		toggle.Position = UDim2.fromOffset(4 + depth * 14, 3)
		toggle.BackgroundTransparency = 1
		toggle.BorderSizePixel = 0
		toggle.Font = Enum.Font.Code
		toggle.TextSize = 11
		toggle.TextColor3 = C.MUTED
		toggle.Text = hasKids and (isExpanded and "-" or "+") or "."
		toggle.AutoButtonColor = false
		toggle.Parent = row

		local nameBtn = Instance.new("TextButton")
		local indentX = 24 + depth * 14
		nameBtn.Size = UDim2.new(1, -indentX - 4, 1, 0)
		nameBtn.Position = UDim2.fromOffset(indentX, 0)
		nameBtn.BackgroundTransparency = 1
		nameBtn.BorderSizePixel = 0
		nameBtn.Font = Enum.Font.Code
		nameBtn.TextSize = 11
		nameBtn.TextXAlignment = Enum.TextXAlignment.Left
		nameBtn.AutoButtonColor = false
		nameBtn.TextColor3 = isSel and C.ACCENT or typeColorFor(inst)
		nameBtn.Text = inst.Name .. "  [" .. inst.ClassName .. "]"
		nameBtn.Parent = row

		local nd = { inst = inst, depth = depth, expanded = isExpanded }
		table.insert(self.State.LiveNodes, nd)

		nameBtn.MouseButton1Click:Connect(function()
			self.State.LiveSelected = inst
			self:_watchLiveSelection(inst)
			self:UpdateLivePropertiesPanel(inst)
			self:RefreshLiveHierarchy()
		end)
		if hasKids then
			toggle.MouseButton1Click:Connect(function()
				nd.expanded = not nd.expanded
				self:RefreshLiveHierarchy()
			end)
		end
		if isExpanded and hasKids then
			for _, ch in ipairs(kids) do
				buildTree(ch, depth + 1)
			end
		end
	end
	buildTree(target, 0)
end

-- ============================================================
-- LIVE MODE — PROPERTIES PANEL
-- ============================================================

function GC:UpdateLivePropertiesPanel(inst)
	self.State.SelectedElement = inst
	local panel = self.State.PropertyPanel
	if not panel then
		return
	end
	for _, c in ipairs(panel:GetChildren()) do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
	if not inst then
		return
	end

	local hdr = Instance.new("Frame")
	hdr.Size = UDim2.new(1, -6, 0, 26)
	hdr.BackgroundColor3 = C.PANEL2
	hdr.BorderSizePixel = 0
	hdr.Parent = panel
	border(hdr, C.ACCENT, 1)
	local hdrLbl = label(hdr, inst.ClassName .. "  ::  " .. inst.Name, 11, C.ACCENT)
	hdrLbl.Size = UDim2.new(1, -36, 1, 0)
	hdrLbl.Position = UDim2.fromOffset(6, 0)
	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Size = UDim2.fromOffset(22, 18)
	refreshBtn.Position = UDim2.new(1, -28, 0.5, -9)
	refreshBtn.BackgroundColor3 = C.INPUT
	refreshBtn.BorderSizePixel = 0
	refreshBtn.Font = Enum.Font.Code
	refreshBtn.Text = "R"
	refreshBtn.TextSize = 10
	refreshBtn.TextColor3 = C.MUTED
	refreshBtn.AutoButtonColor = false
	refreshBtn.Parent = hdr
	border(refreshBtn, C.BORDER, 1)
	-- Manual resync: if the underlying GUI is being driven by another script
	-- while we inspect it, values can go stale. This forces a re-read.
	refreshBtn.MouseButton1Click:Connect(function()
		if inst and inst.Parent then
			self:UpdateLivePropertiesPanel(inst)
		end
	end)

	local function row(h)
		local con = Instance.new("Frame")
		con.Size = UDim2.new(1, -6, 0, h)
		con.BackgroundColor3 = C.ROW
		con.BorderSizePixel = 0
		con.Parent = panel
		return con
	end

	local function safeProp(name, getter, setter, toStr, fromStr)
		local ok, val = pcall(getter)
		if not ok then
			return
		end
		local con = row(42)
		local lbl = label(con, name, 10, C.MUTED)
		lbl.Size = UDim2.new(1, -10, 0, 16)
		lbl.Position = UDim2.fromOffset(6, 3)
		local inp = Instance.new("TextBox")
		inp.Size = UDim2.new(1, -12, 0, 18)
		inp.Position = UDim2.fromOffset(6, 21)
		inp.BackgroundColor3 = C.INPUT
		inp.BorderSizePixel = 0
		inp.Font = Enum.Font.Code
		inp.Text = toStr(val)
		inp.TextColor3 = C.LIVE
		inp.TextSize = 11
		inp.ClearTextOnFocus = false
		inp.Parent = con
		border(inp, C.BORDER, 1)
		inp.FocusLost:Connect(function()
			local nv = fromStr(inp.Text)
			if nv ~= nil then
				local oldOk, oldVal = pcall(getter)
				if not oldOk then
					oldVal = val
				end
				pcall(setter, nv)
				local newOk, newVal = pcall(getter)
				if newOk then
					val = newVal
				end
				inp.Text = toStr(val)
				self:PushUndo({
					Do = function() pcall(setter, nv) end,
					Undo = function() pcall(setter, oldVal) end,
				})
			end
		end)
	end

	local function safeColorProp(name, getter, setter)
		local ok, color = pcall(getter)
		if not ok then
			return
		end
		local con = row(44)
		local lbl = label(con, name, 10, C.MUTED)
		lbl.Size = UDim2.new(1, -46, 0, 16)
		lbl.Position = UDim2.fromOffset(6, 3)
		local preview = Instance.new("Frame")
		preview.Size = UDim2.fromOffset(24, 24)
		preview.Position = UDim2.new(1, -30, 0, 3)
		preview.BackgroundColor3 = color
		preview.BorderSizePixel = 0
		preview.Parent = con
		border(preview, C.BORDER, 1)
		local inp = Instance.new("TextBox")
		inp.Size = UDim2.new(1, -12, 0, 18)
		inp.Position = UDim2.fromOffset(6, 23)
		inp.BackgroundColor3 = C.INPUT
		inp.BorderSizePixel = 0
		inp.Font = Enum.Font.Code
		inp.Text = colorToHex(color)
		inp.TextColor3 = C.LIVE
		inp.TextSize = 11
		inp.PlaceholderText = "#RRGGBB"
		inp.ClearTextOnFocus = false
		inp.Parent = con
		border(inp, C.BORDER, 1)
		inp.FocusLost:Connect(function()
			local nc = hexToColor(inp.Text)
			if nc then
				local old = color
				preview.BackgroundColor3 = nc
				pcall(setter, nc)
				inp.Text = colorToHex(nc)
				self:PushUndo({
					Do = function() pcall(setter, nc) end,
					Undo = function() pcall(setter, old) end,
				})
			end
		end)
	end

	local function safeToggle(name, getter, setter)
		local ok, v = pcall(getter)
		if not ok then
			return
		end
		local con = row(30)
		local lbl = label(con, name, 10, C.MUTED)
		lbl.Size = UDim2.new(1, -54, 1, 0)
		lbl.Position = UDim2.fromOffset(6, 0)
		local tb = Instance.new("TextButton")
		tb.Size = UDim2.fromOffset(44, 20)
		tb.Position = UDim2.new(1, -50, 0.5, -10)
		tb.BackgroundColor3 = C.INPUT
		tb.BorderSizePixel = 0
		tb.Font = Enum.Font.Code
		tb.TextSize = 10
		tb.AutoButtonColor = false
		tb.Parent = con
		local function ref()
			tb.Text = v and "ON" or "OFF"
			tb.TextColor3 = v and C.OK or C.DANGER
		end
		ref()
		border(tb, C.BORDER, 1)
		tb.MouseButton1Click:Connect(function()
			local old = v
			v = not v
			ref()
			local nv = v
			pcall(setter, nv)
			self:PushUndo({
				Do = function() pcall(setter, nv) end,
				Undo = function() pcall(setter, old) end,
			})
		end)
	end

	local function safeDrop(name, options, getter, setter)
		local ok, cur = pcall(getter)
		if not ok then
			return
		end
		local curStr = tostring(cur):gsub("Enum%.[^%.]+%.", "")
		local ci = 1
		for i, v in ipairs(options) do
			if v == curStr then
				ci = i
				break
			end
		end
		local con = row(42)
		local lbl = label(con, name, 10, C.MUTED)
		lbl.Size = UDim2.new(1, -10, 0, 16)
		lbl.Position = UDim2.fromOffset(6, 3)
		local curLbl = Instance.new("TextButton")
		curLbl.Size = UDim2.new(1, -12, 0, 18)
		curLbl.Position = UDim2.fromOffset(6, 21)
		curLbl.BackgroundColor3 = C.INPUT
		curLbl.BorderSizePixel = 0
		curLbl.Font = Enum.Font.Code
		curLbl.Text = "< " .. options[ci] .. " >"
		curLbl.TextColor3 = C.LIVE
		curLbl.TextSize = 11
		curLbl.AutoButtonColor = false
		curLbl.Parent = con
		border(curLbl, C.BORDER, 1)
		curLbl.MouseButton1Click:Connect(function()
			ci = ci % #options + 1
			curLbl.Text = "< " .. options[ci] .. " >"
			pcall(setter, options[ci])
		end)
	end

	safeProp("Name", function() return inst.Name end, function(v)
		inst.Name = v
		self:RefreshLiveHierarchy()
	end, tostring, tostring)

	if inst:IsA("GuiObject") then
		safeProp("Size X", function() return inst.Size.X.Offset end, function(v)
			inst.Size = UDim2.fromOffset(tonumber(v) or inst.Size.X.Offset, inst.Size.Y.Offset)
		end, tostring, tonumber)
		safeProp("Size Y", function() return inst.Size.Y.Offset end, function(v)
			inst.Size = UDim2.fromOffset(inst.Size.X.Offset, tonumber(v) or inst.Size.Y.Offset)
		end, tostring, tonumber)
		safeProp("Size X Scale", function() return inst.Size.X.Scale end, function(v)
			inst.Size = UDim2.new(tonumber(v) or 0, inst.Size.X.Offset, inst.Size.Y.Scale, inst.Size.Y.Offset)
		end, tostring, tonumber)
		safeProp("Size Y Scale", function() return inst.Size.Y.Scale end, function(v)
			inst.Size = UDim2.new(inst.Size.X.Scale, inst.Size.X.Offset, tonumber(v) or 0, inst.Size.Y.Offset)
		end, tostring, tonumber)
		safeProp("Pos X", function() return inst.Position.X.Offset end, function(v)
			inst.Position = UDim2.fromOffset(tonumber(v) or inst.Position.X.Offset, inst.Position.Y.Offset)
		end, tostring, tonumber)
		safeProp("Pos Y", function() return inst.Position.Y.Offset end, function(v)
			inst.Position = UDim2.fromOffset(inst.Position.X.Offset, tonumber(v) or inst.Position.Y.Offset)
		end, tostring, tonumber)
		safeProp("Pos X Scale", function() return inst.Position.X.Scale end, function(v)
			inst.Position = UDim2.new(tonumber(v) or 0, inst.Position.X.Offset, inst.Position.Y.Scale, inst.Position.Y.Offset)
		end, tostring, tonumber)
		safeProp("Pos Y Scale", function() return inst.Position.Y.Scale end, function(v)
			inst.Position = UDim2.new(inst.Position.X.Scale, inst.Position.X.Offset, tonumber(v) or 0, inst.Position.Y.Offset)
		end, tostring, tonumber)
		-- AnchorPoint was entirely missing from live mode in v2; without it
		-- repositioning a centered/anchored real-game element was guesswork.
		safeProp("AnchorPoint X", function() return inst.AnchorPoint.X end, function(v)
			inst.AnchorPoint = Vector2.new(math.clamp(tonumber(v) or 0, 0, 1), inst.AnchorPoint.Y)
		end, tostring, tonumber)
		safeProp("AnchorPoint Y", function() return inst.AnchorPoint.Y end, function(v)
			inst.AnchorPoint = Vector2.new(inst.AnchorPoint.X, math.clamp(tonumber(v) or 0, 0, 1))
		end, tostring, tonumber)
		safeProp("ZIndex", function() return inst.ZIndex end, function(v)
			inst.ZIndex = math.max(0, tonumber(v) or 1)
		end, tostring, tonumber)
		-- LayoutOrder was missing; without it you can't reorder children
		-- under a real UIListLayout/UIGridLayout from live mode.
		safeProp("LayoutOrder", function() return inst.LayoutOrder end, function(v)
			inst.LayoutOrder = tonumber(v) or 0
		end, tostring, tonumber)
		safeProp("Rotation", function() return inst.Rotation end, function(v)
			inst.Rotation = tonumber(v) or 0
		end, tostring, tonumber)
		safeColorProp("BG Color", function() return inst.BackgroundColor3 end, function(v)
			inst.BackgroundColor3 = v
		end)
		safeProp("BG Transparency", function() return inst.BackgroundTransparency end, function(v)
			inst.BackgroundTransparency = math.clamp(tonumber(v) or 0, 0, 1)
		end, tostring, tonumber)
		safeToggle("Visible", function() return inst.Visible end, function(v) inst.Visible = v end)
		safeToggle("Clips Descendants", function() return inst.ClipsDescendants end, function(v)
			inst.ClipsDescendants = v
		end)
	end

	if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
		safeProp("Text", function() return inst.Text end, function(v) inst.Text = v end, tostring, tostring)
		safeProp("Text Size", function() return inst.TextSize end, function(v)
			inst.TextSize = tonumber(v) or 14
		end, tostring, tonumber)
		safeColorProp("Text Color", function() return inst.TextColor3 end, function(v) inst.TextColor3 = v end)
		safeProp("Text Transparency", function() return inst.TextTransparency end, function(v)
			inst.TextTransparency = math.clamp(tonumber(v) or 0, 0, 1)
		end, tostring, tonumber)
		safeToggle("Text Wrapped", function() return inst.TextWrapped end, function(v) inst.TextWrapped = v end)
		safeToggle("Text Scaled", function() return inst.TextScaled end, function(v) inst.TextScaled = v end)
		safeDrop("Font", FONTS, function() return tostring(inst.Font):gsub("Enum%.Font%.", "") end, function(v)
			pcall(function() inst.Font = Enum.Font[v] end)
		end)
		safeDrop("H Align", HALIGN, function() return tostring(inst.TextXAlignment):gsub("Enum%.TextXAlignment%.", "") end, function(v)
			pcall(function() inst.TextXAlignment = Enum.TextXAlignment[v] end)
		end)
		safeDrop("V Align", VALIGN, function() return tostring(inst.TextYAlignment):gsub("Enum%.TextYAlignment%.", "") end, function(v)
			pcall(function() inst.TextYAlignment = Enum.TextYAlignment[v] end)
		end)
		if inst:IsA("TextBox") then
			safeProp("Placeholder", function() return inst.PlaceholderText end, function(v)
				inst.PlaceholderText = v
			end, tostring, tostring)
		end
	end

	if inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
		safeProp("Image", function() return inst.Image end, function(v) inst.Image = v end, tostring, tostring)
		safeProp("Image Transparency", function() return inst.ImageTransparency end, function(v)
			inst.ImageTransparency = math.clamp(tonumber(v) or 0, 0, 1)
		end, tostring, tonumber)
		safeColorProp("Image Color", function() return inst.ImageColor3 end, function(v) inst.ImageColor3 = v end)
		safeDrop("Scale Type", SCALETYPES, function() return tostring(inst.ScaleType):gsub("Enum%.ScaleType%.", "") end, function(v)
			pcall(function() inst.ScaleType = Enum.ScaleType[v] end)
		end)
		-- SliceCenter is the rect that defines 9-slice scaling; without it,
		-- ScaleType.Slice on a real button is unverifiable and uneditable.
		if tostring(inst.ScaleType) == "Enum.ScaleType.Slice" then
			safeProp("SliceCenter (LRTB)", function()
				local r = inst.SliceCenter
				return string.format("%d,%d,%d,%d", r.Min.X, r.Min.Y, r.Max.X, r.Max.Y)
			end, function(v)
				local a, b, c2, d = v:match("(%-?%d+),%s*(%-?%d+),%s*(%-?%d+),%s*(%-?%d+)")
				if a then
					inst.SliceCenter = Rect.new(tonumber(a), tonumber(b), tonumber(c2), tonumber(d))
				end
			end, function(x) return x end, tostring)
		end
	end

	if inst:IsA("ScrollingFrame") then
		safeProp("Canvas W", function() return inst.CanvasSize.X.Offset end, function(v)
			inst.CanvasSize = UDim2.fromOffset(tonumber(v) or 0, inst.CanvasSize.Y.Offset)
		end, tostring, tonumber)
		safeProp("Canvas H", function() return inst.CanvasSize.Y.Offset end, function(v)
			inst.CanvasSize = UDim2.fromOffset(inst.CanvasSize.X.Offset, tonumber(v) or 0)
		end, tostring, tonumber)
		safeProp("Scrollbar Thickness", function() return inst.ScrollBarThickness end, function(v)
			inst.ScrollBarThickness = tonumber(v) or 6
		end, tostring, tonumber)
		safeToggle("Scrolling Enabled", function() return inst.ScrollingEnabled end, function(v)
			inst.ScrollingEnabled = v
		end)
	end

	if inst:IsA("UIListLayout") then
		safeProp("Padding", function() return inst.Padding.Offset end, function(v)
			inst.Padding = UDim.new(0, tonumber(v) or 4)
		end, tostring, tonumber)
		safeDrop("Fill Direction", { "Vertical", "Horizontal" }, function()
			return tostring(inst.FillDirection):gsub("Enum%.FillDirection%.", "")
		end, function(v)
			pcall(function() inst.FillDirection = Enum.FillDirection[v] end)
		end)
		safeDrop("H Align", { "Left", "Center", "Right" }, function()
			return tostring(inst.HorizontalAlignment):gsub("Enum%.HorizontalAlignment%.", "")
		end, function(v)
			pcall(function() inst.HorizontalAlignment = Enum.HorizontalAlignment[v] end)
		end)
		safeDrop("V Align", { "Top", "Center", "Bottom" }, function()
			return tostring(inst.VerticalAlignment):gsub("Enum%.VerticalAlignment%.", "")
		end, function(v)
			pcall(function() inst.VerticalAlignment = Enum.VerticalAlignment[v] end)
		end)
	end

	if inst:IsA("UIPadding") then
		safeProp("Pad Top", function() return inst.PaddingTop.Offset end, function(v)
			inst.PaddingTop = UDim.new(0, tonumber(v) or 0)
		end, tostring, tonumber)
		safeProp("Pad Bottom", function() return inst.PaddingBottom.Offset end, function(v)
			inst.PaddingBottom = UDim.new(0, tonumber(v) or 0)
		end, tostring, tonumber)
		safeProp("Pad Left", function() return inst.PaddingLeft.Offset end, function(v)
			inst.PaddingLeft = UDim.new(0, tonumber(v) or 0)
		end, tostring, tonumber)
		safeProp("Pad Right", function() return inst.PaddingRight.Offset end, function(v)
			inst.PaddingRight = UDim.new(0, tonumber(v) or 0)
		end, tostring, tonumber)
	end

	if inst:IsA("UICorner") then
		safeProp("Corner Radius", function() return inst.CornerRadius.Offset end, function(v)
			inst.CornerRadius = UDim.new(0, math.max(0, tonumber(v) or 0))
		end, tostring, tonumber)
	end

	if inst:IsA("UIStroke") then
		safeProp("Thickness", function() return inst.Thickness end, function(v)
			inst.Thickness = math.max(0, tonumber(v) or 1)
		end, tostring, tonumber)
		safeColorProp("Stroke Color", function() return inst.Color end, function(v) inst.Color = v end)
	end

	-- UIGradient now appears in the live tree via isStructural; previously
	-- it was invisible and unselectable entirely.
	if inst:IsA("UIGradient") then
		safeProp("Rotation", function() return inst.Rotation end, function(v)
			inst.Rotation = tonumber(v) or 0
		end, tostring, tonumber)
		safeToggle("Enabled", function() return inst.Enabled end, function(v) inst.Enabled = v end)
	end

	if inst:IsA("ScreenGui") then
		safeToggle("Enabled", function() return inst.Enabled end, function(v) inst.Enabled = v end)
		safeToggle("Reset On Spawn", function() return inst.ResetOnSpawn end, function(v) inst.ResetOnSpawn = v end)
		safeProp("Display Order", function() return inst.DisplayOrder end, function(v)
			inst.DisplayOrder = tonumber(v) or 0
		end, tostring, tonumber)
	end

	local highlightBtn = self:MakeBtn("HIGHLIGHT IN GAME", C.LIVE, panel, 0, 28)
	highlightBtn.Size = UDim2.new(1, -6, 0, 28)
	highlightBtn.MouseButton1Click:Connect(function()
		if not inst:IsA("GuiObject") then
			return
		end
		local oldColor = inst.BackgroundColor3
		local oldTrans = inst.BackgroundTransparency
		local flash = 4
		local function doFlash(n)
			if n <= 0 then
				pcall(function()
					inst.BackgroundColor3 = oldColor
					inst.BackgroundTransparency = oldTrans
				end)
				return
			end
			pcall(function()
				inst.BackgroundColor3 = C.LIVE
				inst.BackgroundTransparency = 0
			end)
			task.delay(0.15, function()
				pcall(function()
					inst.BackgroundColor3 = oldColor
					inst.BackgroundTransparency = oldTrans
				end)
				task.delay(0.15, function()
					doFlash(n - 1)
				end)
			end)
		end
		doFlash(flash)
	end)
end

-- ============================================================
-- MAIN UI SHELL
-- ============================================================

function GC:_createUI()
	local sg = Instance.new("ScreenGui")
	sg.Name = "GUICreator_Zuka"
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = CoreGui
	self.State.UI = sg

	local mf = Instance.new("Frame")
	mf.Name = "MainFrame"
	mf.Size = UDim2.fromOffset(1200, 700)
	mf.Position = UDim2.fromScale(0.5, 0.5)
	mf.AnchorPoint = Vector2.new(0.5, 0.5)
	mf.BackgroundColor3 = C.BG
	mf.BorderSizePixel = 0
	mf.Parent = sg
	border(mf, C.ACCENT, 1)
	self.UI.MainFrame = mf

	-- Mode bar
	local modeBar = Instance.new("Frame")
	modeBar.Name = "ModeBar"
	modeBar.Size = UDim2.new(1, 0, 0, 36)
	modeBar.BackgroundColor3 = C.PANEL
	modeBar.BorderSizePixel = 0
	modeBar.Parent = mf
	self.UI.ModeBar = modeBar

	local modeLabel = label(modeBar, "GUI CREATOR v3 -- CTRL+Z  CTRL+Y  CTRL+D  DEL", 12, C.ACCENT)
	modeLabel.Size = UDim2.new(0.55, 0, 1, 0)
	modeLabel.Position = UDim2.fromOffset(14, 0)
	self.UI.ModeLabel = modeLabel

	local projLbl = label(modeBar, "PROJECT:", 10, C.MUTED)
	projLbl.Size = UDim2.fromOffset(60, 18)
	projLbl.Position = UDim2.new(0.57, 0, 0.5, -9)
	projLbl.TextXAlignment = Enum.TextXAlignment.Right

	local projInput = Instance.new("TextBox")
	projInput.Size = UDim2.fromOffset(120, 20)
	projInput.Position = UDim2.new(0.57, 64, 0.5, -10)
	projInput.BackgroundColor3 = C.INPUT
	projInput.BorderSizePixel = 0
	projInput.Font = Enum.Font.Code
	projInput.Text = self.State.CurrentProject.Name
	projInput.TextColor3 = C.TEXT
	projInput.TextSize = 11
	projInput.ClearTextOnFocus = false
	projInput.Parent = modeBar
	border(projInput, C.BORDER, 1)
	projInput.FocusLost:Connect(function()
		self.State.CurrentProject.Name = projInput.Text ~= "" and projInput.Text or "Untitled"
		projInput.Text = self.State.CurrentProject.Name
	end)

	local closeBtn = self:MakeBtn("X", C.DANGER, modeBar, 28, 28)
	closeBtn.TextSize = 14
	closeBtn.Position = UDim2.new(1, -33, 0.5, -14)
	closeBtn.MouseButton1Click:Connect(function() self:Disable() end)
	self:MakeDraggable(modeBar, mf)

	-- Top action bar
	local topBar = Instance.new("Frame")
	topBar.Size = UDim2.new(1, -20, 0, 32)
	topBar.Position = UDim2.fromOffset(10, 42)
	topBar.BackgroundColor3 = C.PANEL2
	topBar.BorderSizePixel = 0
	topBar.ZIndex = 10
	topBar.Parent = mf
	local topLayout = Instance.new("UIListLayout")
	topLayout.FillDirection = Enum.FillDirection.Horizontal
	topLayout.Padding = UDim.new(0, 5)
	topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	topLayout.Parent = topBar
	local topPad = Instance.new("UIPadding")
	topPad.PaddingLeft = UDim.new(0, 8)
	topPad.Parent = topBar

	local exportBtn = self:MakeBtn("EXPORT CODE", C.OK, topBar)
	exportBtn.MouseButton1Click:Connect(function() self:ExportCode() end)

	local liveBtn = self:MakeBtn("LIVE EDIT", C.LIVE, topBar, 100)
	liveBtn.MouseButton1Click:Connect(function()
		if self.State.Mode == "live" then
			self:ExitLiveMode()
			liveBtn.Text = "LIVE EDIT"
		else
			self:OpenLivePicker()
		end
	end)
	self.UI.LiveBtn = liveBtn

	local undoBtn = self:MakeBtn("UNDO", C.TEXT, topBar, 70)
	undoBtn.MouseButton1Click:Connect(function() self:Undo() end)
	local redoBtn = self:MakeBtn("REDO", C.TEXT, topBar, 70)
	redoBtn.MouseButton1Click:Connect(function() self:Redo() end)
	local clearBtn = self:MakeBtn("CLEAR", C.DANGER, topBar, 70)
	clearBtn.MouseButton1Click:Connect(function() self:ClearCanvas() end)

	local gridBtn = self:MakeBtn("GRID: ON", C.TEXT, topBar, 80)
	gridBtn.MouseButton1Click:Connect(function()
		self.Config.ShowGrid = not self.Config.ShowGrid
		gridBtn.Text = "GRID: " .. (self.Config.ShowGrid and "ON" or "OFF")
		self:DrawGrid()
	end)
	local snapBtn = self:MakeBtn("SNAP: OFF", C.TEXT, topBar, 80)
	snapBtn.MouseButton1Click:Connect(function()
		self.Config.SnapToGrid = not self.Config.SnapToGrid
		snapBtn.Text = "SNAP: " .. (self.Config.SnapToGrid and "ON" or "OFF")
	end)

	-- Toolbox (maker)
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "Toolbox"
	leftPanel.Size = UDim2.new(0, 165, 1, -82)
	leftPanel.Position = UDim2.fromOffset(10, 78)
	leftPanel.BackgroundColor3 = C.PANEL2
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = mf
	self.UI.Toolbox = leftPanel

	local toolboxTitle = label(leftPanel, "ELEMENTS", 11, C.MUTED)
	toolboxTitle.Size = UDim2.new(1, 0, 0, 24)
	toolboxTitle.Position = UDim2.fromOffset(8, 0)

	local toolScroll = Instance.new("ScrollingFrame")
	toolScroll.Size = UDim2.new(1, -8, 1, -28)
	toolScroll.Position = UDim2.fromOffset(4, 26)
	toolScroll.BackgroundTransparency = 1
	toolScroll.BorderSizePixel = 0
	toolScroll.ScrollBarThickness = 3
	toolScroll.ScrollBarImageColor3 = C.ACCENT
	toolScroll.CanvasSize = UDim2.fromOffset(0, 0)
	toolScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	toolScroll.Parent = leftPanel
	local tlayout = Instance.new("UIListLayout")
	tlayout.Padding = UDim.new(0, 4)
	tlayout.SortOrder = Enum.SortOrder.LayoutOrder
	tlayout.Parent = toolScroll
	self:PopulateToolbox(toolScroll)

	-- Live mode side panel
	local livePanel = Instance.new("Frame")
	livePanel.Name = "LivePanel"
	livePanel.Size = UDim2.new(0, 165, 1, -82)
	livePanel.Position = UDim2.fromOffset(10, 78)
	livePanel.BackgroundColor3 = C.PANEL2
	livePanel.BorderSizePixel = 0
	livePanel.Visible = false
	livePanel.Parent = mf
	border(livePanel, C.LIVE, 1)
	self.UI.LivePanel = livePanel

	local liveTitle = label(livePanel, "LIVE MODE", 11, C.LIVE)
	liveTitle.Size = UDim2.new(1, 0, 0, 24)
	liveTitle.Position = UDim2.fromOffset(8, 0)
	local liveTip = label(livePanel, "Click any node in the\nhierarchy to inspect\nand edit it live.", 10, C.MUTED, "Code")
	liveTip.Size = UDim2.new(1, -16, 0, 60)
	liveTip.Position = UDim2.fromOffset(8, 28)
	liveTip.TextWrapped = true
	liveTip.TextYAlignment = Enum.TextYAlignment.Top

	local exitLiveBtn = self:MakeBtn("EXIT LIVE MODE", C.DANGER, livePanel, 145, 28)
	exitLiveBtn.Position = UDim2.new(0.5, -72, 1, -36)
	exitLiveBtn.MouseButton1Click:Connect(function()
		self:ExitLiveMode()
		self.UI.LiveBtn.Text = "LIVE EDIT"
	end)

	-- Canvas (maker)
	local canvas = Instance.new("Frame")
	canvas.Name = "Canvas"
	canvas.Size = UDim2.new(1, -560, 1, -82)
	canvas.Position = UDim2.fromOffset(183, 78)
	canvas.BackgroundColor3 = C.CANVAS_BG
	canvas.BorderSizePixel = 0
	canvas.ClipsDescendants = false
	canvas.Parent = mf
	self.UI.Canvas = canvas

	local canvasLbl = label(canvas, "CANVAS  480 x 360", 10, C.MUTED)
	canvasLbl.Size = UDim2.new(1, 0, 0, 20)
	canvasLbl.TextXAlignment = Enum.TextXAlignment.Center

	local ws = Instance.new("Frame")
	ws.Name = "Workspace"
	ws.Size = UDim2.fromOffset(480, 360)
	ws.Position = UDim2.new(0.5, 0, 0.5, 0)
	ws.AnchorPoint = Vector2.new(0.5, 0.5)
	ws.BackgroundColor3 = C.WS_BG
	ws.BorderSizePixel = 0
	ws.ClipsDescendants = true
	ws.Parent = canvas
	border(ws, C.BORDER, 1)
	self.UI.Workspace = ws

	local gridFrame = Instance.new("Frame")
	gridFrame.Name = "GridOverlay"
	gridFrame.Size = UDim2.new(1, 0, 1, 0)
	gridFrame.BackgroundTransparency = 1
	gridFrame.BorderSizePixel = 0
	gridFrame.ZIndex = 1
	gridFrame.Parent = ws
	self.State.GridFrame = gridFrame
	self:DrawGrid()

	-- Right column: properties + hierarchy
	local rightCol = Instance.new("Frame")
	rightCol.Name = "RightCol"
	rightCol.Size = UDim2.new(0, 240, 1, -82)
	rightCol.Position = UDim2.new(1, -250, 0, 78)
	rightCol.BackgroundTransparency = 1
	rightCol.BorderSizePixel = 0
	rightCol.Parent = mf
	self.UI.RightCol = rightCol

	local propPanel = Instance.new("Frame")
	propPanel.Name = "Properties"
	propPanel.Size = UDim2.new(1, 0, 0.52, -4)
	propPanel.BackgroundColor3 = C.PANEL2
	propPanel.BorderSizePixel = 0
	propPanel.Parent = rightCol
	local propTitle = label(propPanel, "PROPERTIES", 11, C.MUTED)
	propTitle.Size = UDim2.new(1, 0, 0, 24)
	propTitle.Position = UDim2.fromOffset(8, 0)

	local propScroll = Instance.new("ScrollingFrame")
	propScroll.Size = UDim2.new(1, -8, 1, -28)
	propScroll.Position = UDim2.fromOffset(4, 26)
	propScroll.BackgroundTransparency = 1
	propScroll.BorderSizePixel = 0
	propScroll.ScrollBarThickness = 3
	propScroll.ScrollBarImageColor3 = C.ACCENT
	propScroll.CanvasSize = UDim2.fromOffset(0, 0)
	propScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	propScroll.Parent = propPanel
	local pl = Instance.new("UIListLayout")
	pl.Padding = UDim.new(0, 4)
	pl.SortOrder = Enum.SortOrder.LayoutOrder
	pl.Parent = propScroll
	self.State.PropertyPanel = propScroll

	local hierPanel = Instance.new("Frame")
	hierPanel.Name = "Hierarchy"
	hierPanel.Size = UDim2.new(1, 0, 0.48, -4)
	hierPanel.Position = UDim2.new(0, 0, 0.52, 4)
	hierPanel.BackgroundColor3 = C.PANEL2
	hierPanel.BorderSizePixel = 0
	hierPanel.Parent = rightCol
	self.UI.HierPanel = hierPanel

	local hierTitle = label(hierPanel, "HIERARCHY", 11, C.MUTED)
	hierTitle.Size = UDim2.new(1, 0, 0, 24)
	hierTitle.Position = UDim2.fromOffset(8, 0)
	local hierRefreshBtn = self:MakeBtn("R", C.LIVE, hierPanel, 20, 18)
	hierRefreshBtn.Position = UDim2.new(1, -24, 0, 4)
	hierRefreshBtn.MouseButton1Click:Connect(function()
		if self.State.Mode == "live" then
			self:RefreshLiveHierarchy()
		end
	end)

	local hierScroll = Instance.new("ScrollingFrame")
	hierScroll.Size = UDim2.new(1, -8, 1, -28)
	hierScroll.Position = UDim2.fromOffset(4, 26)
	hierScroll.BackgroundTransparency = 1
	hierScroll.BorderSizePixel = 0
	hierScroll.ScrollBarThickness = 3
	hierScroll.ScrollBarImageColor3 = C.ACCENT
	hierScroll.CanvasSize = UDim2.fromOffset(0, 0)
	hierScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	hierScroll.Parent = hierPanel
	local hl = Instance.new("UIListLayout")
	hl.Padding = UDim.new(0, 3)
	hl.SortOrder = Enum.SortOrder.LayoutOrder
	hl.Parent = hierScroll
	self.State.HierarchyPanel = hierScroll

	self:_bindKeyboard()
end

function GC:Enable()
	if self.State.IsEnabled then
		return
	end
	self.State.IsEnabled = true
	self:_createUI()
	print("[GUICreator v3] Enabled")
	print("  Maker mode: drag, resize, Ctrl+Z/Y/D, Del")
end

function GC:Disable()
	if not self.State.IsEnabled then
		return
	end
	self.State.IsEnabled = false
	self:_clearLiveWatch()
	for _, c in pairs(self.State.Connections) do
		if c then
			c:Disconnect()
		end
	end
	table.clear(self.State.Connections)
	for _, d in ipairs(self.State.CreatedGUIs) do
		if d.Connections then
			for _, c in ipairs(d.Connections) do
				if c then
					c:Disconnect()
				end
			end
		end
	end
	if self.State.UI then
		self.State.UI:Destroy()
		self.State.UI = nil
	end
	self.State.CreatedGUIs = {}
	self.State.UndoStack = {}
	self.State.RedoStack = {}
	self.State.SelectedElement = nil
	self.State.GridFrame = nil
	self.State.Mode = "maker"
	self.State.LiveTarget = nil
	self.UI = {}
	print("[GUICreator v3] Disabled")
end

function GC:Toggle()
	if self.State.IsEnabled then
		self:Disable()
	else
		self:Enable()
	end
end

GC:Enable()

return GC
