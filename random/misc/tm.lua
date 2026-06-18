local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local LocalPlayer = Players.LocalPlayer

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Logo"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local GoonLogoB64 =
	"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"

local GoonLogoWrap = Instance.new("Frame")
GoonLogoWrap.Name = "GoonLogoWrap"
GoonLogoWrap.Size = UDim2.fromOffset(100, 120)
GoonLogoWrap.Position = UDim2.new(1, -110, 1, -130)
GoonLogoWrap.AnchorPoint = Vector2.new(0, 0)
GoonLogoWrap.BackgroundTransparency = 1
GoonLogoWrap.BorderSizePixel = 0
GoonLogoWrap.ZIndex = 4
GoonLogoWrap.Parent = ScreenGui

local GoonLogo = Instance.new("ImageButton")
GoonLogo.Name = "GoonLogo"
GoonLogo.Size = UDim2.fromOffset(100, 100)
GoonLogo.Position = UDim2.fromOffset(0, 20)
GoonLogo.AnchorPoint = Vector2.new(0, 0)
GoonLogo.Rotation = 0
GoonLogo.LayoutOrder = 0
GoonLogo.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
GoonLogo.BackgroundTransparency = 1
GoonLogo.BorderSizePixel = 0
GoonLogo.ZIndex = 7
GoonLogo.Visible = true
GoonLogo.ScaleType = Enum.ScaleType.Fit

local GoonLogo_DIR = "zukatech_assets/"
pcall(makefolder, GoonLogo_DIR)
local GoonLogoPath = GoonLogo_DIR .. "GoonLogo.png"

local function b64decode(data)
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	data = data:gsub("[^" .. b .. "=]", "")
	local result = {}
	local i = 1
	while i <= #data do
		local c1 = b:find(data:sub(i, i), 1, true) - 1
		local c2 = b:find(data:sub(i + 1, i + 1), 1, true) - 1
		local c3 = data:sub(i + 2, i + 2) == "=" and 0 or (b:find(data:sub(i + 2, i + 2), 1, true) - 1)
		local c4 = data:sub(i + 3, i + 3) == "=" and 0 or (b:find(data:sub(i + 3, i + 3), 1, true) - 1)
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
	return table.concat(result)
end

writefile(GoonLogoPath, b64decode(GoonLogoB64))
GoonLogo.Image = getcustomasset(GoonLogoPath)

do
	local _s = Instance.new("UIStroke", GoonLogo)
	_s.Color = Color3.fromRGB(38, 38, 46)
	_s.Thickness = 1
end

GoonLogo.Parent = GoonLogoWrap

pcall(function()
	ContentProvider:PreloadAsync({ GoonLogo })
end)

local GoonLabel = Instance.new("TextLabel")
GoonLabel.Name = "GoonLabel"
GoonLabel.Size = UDim2.fromOffset(100, 20)
GoonLabel.Position = UDim2.fromOffset(0, 0)
GoonLabel.AnchorPoint = Vector2.new(0, 0)
GoonLabel.Rotation = 0
GoonLabel.LayoutOrder = 0
GoonLabel.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
GoonLabel.BackgroundTransparency = 1
GoonLabel.BorderSizePixel = 0
GoonLabel.ZIndex = 5
GoonLabel.Visible = true
GoonLabel.Text = "GoonSploit"
GoonLabel.TextColor3 = Color3.fromRGB(214, 214, 222)
GoonLabel.TextSize = 8
GoonLabel.Font = Enum.Font.SourceSansItalic
GoonLabel.TextXAlignment = Enum.TextXAlignment.Left
GoonLabel.TextYAlignment = Enum.TextYAlignment.Center
GoonLabel.TextWrapped = true

do
	local _s = Instance.new("UIStroke", GoonLabel)
	_s.Color = Color3.fromRGB(38, 38, 46)
	_s.Thickness = 1
end

GoonLabel.Parent = GoonLogoWrap
