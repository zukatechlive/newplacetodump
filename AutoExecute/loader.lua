-- Autoexec Script

-- Env Shield
loadstring(game:HttpGet("https://raw.githubusercontent.com/zukatechlive/newplacetodump/refs/heads/main/Env.lua"))()

SandboxEnv.trust("dex")
SandboxEnv.trust("panel")


-- Main
local BASE = "https://raw.githubusercontent.com/zukatechlive/newplacetodump/refs/heads/main/AutoExecute/"
local scripts = {
	{ file = "dex.lua", chunkname = "dex", delay = 10 },
	{ file = "panel.lua", chunkname = "panel", delay = 15 },
}

for _, entry in ipairs(scripts) do
	task.delay(entry.delay, function()
		local ok, src = pcall(function()
			return game:HttpGet(BASE .. entry.file)
		end)
		if not ok or not src then
			warn("[loader] failed to fetch:", entry.file)
			return
		end
		local success, err = SandboxEnv.exec(src, entry.chunkname)
		if not success then
			warn("[loader] error in", entry.file, err)
		end
	end)
end


--[[

______         ______      _         
| ___ \       |___  /     | |        
| |_/ /_   _     / / _   _| | ____ _ 
| ___ \ | | |   / / | | | | |/ / _` |
| |_/ / |_| | ./ /__| |_| |   < (_| |
\____/ \__, | \_____/\__,_|_|\_\__,_|
        __/ |                        
       |___/                         


]]
