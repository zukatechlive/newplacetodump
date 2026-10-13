-- Autoexec Script


loadstring(game:HttpGet("https://raw.githubusercontent.com/zukatechlive/newplacetodump/refs/heads/main/Env.lua"))()

SandboxEnv.trust("dex")
SandboxEnv.trust("main")


-- Main
local BASE = "https://raw.githubusercontent.com/zukatechlive/newplacetodump/refs/heads/main/New/"
local scripts = {
	{ file = "dex_current.lua", chunkname = "dex", delay = 5 },
	{ file = "source.lua", chunkname = "main", delay = 3 },
}

for _, entry in ipairs(scripts) do
	task.delay(entry.delay, function()
		local ok, src = pcall(function()
			return game:HttpGet(BASE .. entry.file)
		end)
		if not ok or not src then
			warn("[zuka] failed to fetch:", entry.file)
			return
		end
		local success, err = SandboxEnv.exec(src, entry.chunkname)
		if not success then
			warn("[zuka] error in", entry.file, err)
		end
	end)
end
