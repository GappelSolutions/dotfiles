-- Windows clipboard: `copy` puts the selected (else hovered) files on it as files, ready for ctrl+v
-- in Teams, Outlook, browsers or Explorer; `paste` copies files from it into the current directory,
-- or saves a copied image there as PNG. The work happens in ~\.local\bin\win-clip.ps1.
local M = {}

local state = ya.sync(function()
	local paths = {}
	for _, url in pairs(cx.active.selected) do
		paths[#paths + 1] = tostring(url)
	end
	local hovered = cx.active.current.hovered
	if #paths == 0 and hovered then
		paths[1] = tostring(hovered.url)
	end
	return tostring(cx.active.current.cwd), paths
end)

function M:entry(job)
	local mode = job.args[1]
	local cwd, paths = state()
	local args = {
		"-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
		"-File", os.getenv("USERPROFILE") .. "\\.local\\bin\\win-clip.ps1", mode,
	}
	if mode == "copy" then
		if #paths == 0 then return end
		for _, p in ipairs(paths) do
			args[#args + 1] = p
		end
	else
		args[#args + 1] = cwd
	end

	-- Windows PowerShell, not pwsh: see win-clip.ps1
	local output, err = Command("powershell.exe"):arg(args):stdout(Command.PIPED):stderr(Command.PIPED):output()
	local ok = output and output.status.success
	local msg = output and (ok and output.stdout or output.stderr) or tostring(err)
	ya.notify { title = "Windows clipboard", content = msg:gsub("%s+$", ""), timeout = ok and 2 or 6, level = ok and "info" or "error" }
end

return M
