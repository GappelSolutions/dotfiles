local M = {}

M.n, M.i, M.v = vis.modes.NORMAL, vis.modes.INSERT, vis.modes.VISUAL
M.mason = os.getenv('HOME') .. '/.local/share/nvim/mason/bin/'
-- vis's cwd, which Lua can't read; config.worktree moves it
M.cwd = os.getenv('PWD') or ''

function M.cmd(command)
	return function()
		vis:command(command)
	end
end

function M.quote(s)
	return "'" .. s:gsub("'", [['\'']]) .. "'"
end

-- relative to the cwd if inside it
function M.relative(path)
	if path:sub(1, #M.cwd + 1) == M.cwd .. '/' then
		return path:sub(#M.cwd + 2)
	end
	return path
end

function M.lines_of(command)
	local p = io.popen(command)
	local lines = {}
	for line in p:lines() do
		lines[#lines + 1] = line
	end
	p:close()
	return lines
end

function M.dirname(path)
	return path:match('^(.*)/') or '.'
end

function M.chars(s)
	return s:gmatch('[\1-\127\194-\244][\128-\191]*')
end

-- screen rows of a file line as vis wraps it (its newline takes a cell too)
function M.rows(win, lineno)
	local w, tabwidth = 0, win.options.tabwidth
	for char in M.chars(win.file.lines[lineno] or '') do
		w = char == '\t' and w + tabwidth - w % tabwidth or w + 1
	end
	return math.floor(w / win.viewport.width) + 1
end

function M.open(path)
	-- a modified buffer can't be replaced, so open beside it
	return vis:command((vis.win.file.modified and 'o' or 'e') .. ' ' .. M.quote(path))
end

return M
