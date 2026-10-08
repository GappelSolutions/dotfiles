-- fidx: fzf over a prebuilt file list (%LOCALAPPDATA%\fidx\<Drive>.txt, written by fidx.ps1),
-- scoped to the current directory. Network drives become instant to search.
-- In fzf: ctrl-l = ignore the index and walk the cwd live with fd.
local M = {}

local state = ya.sync(function() return cx.active.current.cwd end)

local function sh_quote(s)
	if (os.getenv("SHELL") or "") ~= "" then
		return "'" .. s:gsub("'", "'\\''") .. "'"
	end
	return '"' .. s .. '"' -- fzf falls back to cmd.exe when $SHELL is unset
end

-- path separators become \x5c: Git Bash collapses "\\" in argv handed to native exes
local function rg_escape(s)
	return (s:gsub("[%^%$%.%*%+%?%(%)%[%]%{%}|\\]", function(c) return c == "\\" and "\\x5c" or "\\" .. c end))
end

local function age(secs)
	if secs < 3600 then return string.format("%dm", math.floor(secs / 60)) end
	if secs < 86400 then return string.format("%dh", math.floor(secs / 3600)) end
	return string.format("%dd", math.floor(secs / 86400))
end

function M:entry()
	local cwd = state()
	local path = tostring(cwd)
	local drive = path:match("^(%a):")
	local index = drive and string.format("%s\\fidx\\%s.txt", os.getenv("LOCALAPPDATA"), drive:upper())
	local cha = index and fs.cha(Url(index))
	if not cha then
		return ya.emit("plugin", { "fzf" }) -- no index for this drive: plain fzf
	end

	local prefix = path:gsub("\\$", "") .. "\\"
	local source = string.format("rg --no-config -N -i -- %s %s", sh_quote("^" .. rg_escape(prefix)), sh_quote(index))
	-- --path-separator: fd emits '/' when MSYSTEM is set (Git Bash)
	local sep = (os.getenv("SHELL") or "") ~= "" and "'\\'" or "\\" -- a quoted "\" would escape the quote in cmd
	local live = string.format("fd -H -I -j 32 --color=never --path-separator=%s . %s", sep, sh_quote(path))

	local permit = ui.hide()
	local child, err = Command("fzf")
		:arg({
			"-m",
			"--scheme=path",
			"--header=" .. string.format("%s index %s old  |  ctrl-l: live fd", drive:upper(), age(os.time() - cha.mtime)),
			"--bind=ctrl-l:reload:" .. live,
		})
		:env("FZF_DEFAULT_COMMAND", source)
		:cwd(path)
		:stdout(Command.PIPED)
		:spawn()
	if not child then
		permit:drop()
		return ya.notify { title = "fidx", content = "Failed to start fzf: " .. tostring(err), timeout = 5, level = "error" }
	end
	local output = child:wait_with_output()
	permit:drop()
	if not output or (not output.status.success and output.status.code ~= 130) then
		return ya.notify { title = "fidx", content = "fzf exited abnormally", timeout = 5, level = "error" }
	end

	local urls = {}
	for line in output.stdout:gmatch("[^\r\n]+") do
		urls[#urls + 1] = Url(line)
	end
	if #urls == 1 then
		local c = fs.cha(urls[1])
		ya.emit(c and c.is_dir and "cd" or "reveal", { urls[1], raw = true })
	elseif #urls > 1 then
		urls.state = "on"
		ya.emit("toggle_all", urls)
	end
end

return M
