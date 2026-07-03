local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local Container = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")

ScreenGui.Name = "IconPicker"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -125)
MainFrame.Size = UDim2.new(0, 300, 0, 250)
MainFrame.Active = true
MainFrame.Draggable = true

Title.Name = "Title"
Title.Parent = MainFrame
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Font = Enum.Font.GothamBold
Title.Text = "Internal Icon Copy"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14.000

Container.Name = "Container"
Container.Parent = MainFrame
Container.BackgroundTransparency = 1.000
Container.BorderSizePixel = 0
Container.Position = UDim2.new(0, 10, 0, 45)
Container.Size = UDim2.new(1, -20, 1, -55)
Container.CanvasSize = UDim2.new(0, 0, 0, 0)
Container.ScrollBarThickness = 4

UIListLayout.Parent = Container
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

local Icons = {
	{ Name = "Verified", Char = utf8.char(0xE000) },
	{ Name = "Premium", Char = utf8.char(0xE001) },
	{ Name = "Robux", Char = utf8.char(0xE002) },
	{ Name = "Roblox Plus", Char = utf8.char(0xE003) },
}

local function CreateEntry(data)
	local Frame = Instance.new("Frame")
	local Label = Instance.new("TextLabel")
	local InputBar = Instance.new("TextBox")

	Frame.Name = data.Name
	Frame.Parent = Container
	Frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	Frame.BorderSizePixel = 0
	Frame.Size = UDim2.new(1, 0, 0, 40)

	Label.Name = "Label"
	Label.Parent = Frame
	Label.BackgroundTransparency = 1.000
	Label.Position = UDim2.new(0, 8, 0, 0)
	Label.Size = UDim2.new(0, 100, 1, 0)
	Label.Font = Enum.Font.Gotham
	Label.Text = data.Name
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.TextSize = 14.000
	Label.TextXAlignment = Enum.TextXAlignment.Left

	InputBar.Name = "InputBar"
	InputBar.Parent = Frame
	InputBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	InputBar.BorderSizePixel = 0
	InputBar.Position = UDim2.new(0, 110, 0.5, -12)
	InputBar.Size = UDim2.new(1, -120, 0, 25)
	InputBar.Font = Enum.Font.GothamMedium
	InputBar.Text = data.Char
	InputBar.TextColor3 = Color3.fromRGB(255, 255, 255)
	InputBar.TextSize = 18.000
	InputBar.ClearTextOnFocus = false
	InputBar.TextEditable = false
end

for _, iconData in ipairs(Icons) do
	CreateEntry(iconData)
end

Container.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
