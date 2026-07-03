local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local CrosshairB64 =
	"iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAADQklEQVR4AeyVW47CMBAEYe9/ZzY/QZEhih38mOkutBLEBHu6uhb+HjysCSCAdf2PBwIggDkB8/h8AyCAOQHz+HwDIIA5AdP4e2y+AXYSps8IYFr8HhsBdhKmzwhgWvweGwF2EqbPCGBa/B4bAXYSps8IYFZ8GRcBSiJm1whgVngZFwFKImbXCGBWeBkXAUoiZtcIYFZ4GRcBSiJm1whgUvhZTAQ4I2OyjgAmRZ/FRIAzMibrCGBS9FlMBDgjY7KOACZFn8VEgDMyJusIIF70VTwEuCIk/j4CiBd8FQ8BrgiJv48A4gVfxUOAK0Li7yOAeMFX8RDgipD4+wggWnBtLASoJSV6HwKIFlsbCwFqSYnehwCixdbGQoBaUqL3IYBosbWxEKCWlOh9CCBWbGscBGglJnY/AogV2hoHAVqJid2PAGKFtsZBgFZiYvcjgFihrXEQoJWY2P0IIFLo3RgIcJecyOcQQKTIuzEQ4C45kc8hgEiRd2PYC/DaHnfhKXzOXgCFEn/JgAC/0BP4rL0Az+2RucdfZ7cTYPvJf/8d4b0XtxfHdfXXdgJs//Dvv2O578XtxXFd/bWdAGWh2z/8q1xzurYXwKnsb1kR4BsVozV7Abaf/KdR3x9R7QX4IGK2gABJC+81NgL0Ipl0HwRIWlyvsRGgF8mk+yBA0uJ6jY0AvUgm3QcBkhbXa2wE6EUy6T4IkKy43uMiQG+iyfZDgGSF9R4XAXoTTbYfAiQrrPe4CNCbaLL9ECBZYb3HRYDeRJPthwBJChs1JgKMIptkXwRIUtSoMRFgFNkk+yJAkqJGjYkAo8gm2RcBkhQ1akwEGEU2yb4IELyo0eMhwGjCwfdHgOAFjR4PAUYTDr4/AgQvaPR4CDCacPD9ESB4QaPHQ4DRhIPvjwBBC5o1FgLMIh30HAQIWsyssRBgFumg5yBA0GJmjYUAs0gHPQcBghYzaywEmEU66DkIEKyY2eMgwGziwc5DgGCFzB4HAWYTD3YeAgQrZPY4CDCbeLDzECBYIbPHQYDZxIOdhwBBClk1BgKsIh/kXAQIUsSqMRBgFfkg5yJAkCJWjYEAq8gHORcBghSxagwEWEU+yLkIsLiI1cf/AwAA///r+3KCAAAABklEQVQDAI/2IQFJiecUAAAAAElFTkSuQmCC"
local CrosshairSize = 32

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomCrosshair"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local CrosshairImg = Instance.new("ImageLabel")
CrosshairImg.Name = "CrosshairImg"
CrosshairImg.Size = UDim2.fromOffset(CrosshairSize, CrosshairSize)
CrosshairImg.Position = UDim2.new(0.5, 0, 0.5, 0)
CrosshairImg.AnchorPoint = Vector2.new(0.5, 0.5)
CrosshairImg.BackgroundTransparency = 1
CrosshairImg.BorderSizePixel = 0
CrosshairImg.ZIndex = 10
CrosshairImg.Visible = true
CrosshairImg.ScaleType = Enum.ScaleType.Fit
CrosshairImg.Parent = ScreenGui

local CrosshairImg_DIR = "misc_assets/"
local CrosshairImgPath = CrosshairImg_DIR .. "CrosshairImg.png"

if isfolder and not isfolder(CrosshairImg_DIR) then
	makefolder(CrosshairImg_DIR)
end

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

		local n = (c1 * 262144) + (c2 * 4096) + (c3 * 64) + c4

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

if CrosshairB64 ~= "" then
	writefile(CrosshairImgPath, b64decode(CrosshairB64))
	CrosshairImg.Image = getcustomasset(CrosshairImgPath)
else
	warn("CrosshairB64 string is empty! Please paste your hash.")
end

pcall(function()
	ContentProvider:PreloadAsync({ CrosshairImg })
end)
