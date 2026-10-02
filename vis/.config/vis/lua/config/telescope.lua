-- Telescope: television (tv) pickers, laid out like nvim's telescope and coloured iceberg
-- (television/.config/television)
local util = require('util')
local icons = require('icons')

local M = {}

-- only for its history: its picker runs fzf through io.popen, which doesn't hand fzf the
-- terminal, so vis is left drawing on the normal screen once fzf exits
local mru = require('plugins/vis-fzf-mru/fzf-mru')
mru.fzfmru_filepath = os.getenv('HOME') .. '/.local/state/vis-mru'
mru.fzfmru_history = 100

function M.fg(colour)
	local r, g, b = colour:match('#(%x%x)(%x%x)(%x%x)')
	return string.format('\27[38;2;%d;%d;%dm', tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
end

-- iceberg as in bat/.config/bat/themes
M.bat = 'bat --color=always --style=numbers --theme=iceberg '

-- for `path:line:...` entries
M.location = {
	preview = M.bat .. "--highlight-line '{split:\\::1}' '{split:\\::0}'",
	offset = '{split:\\::1}',
	header = '{split:\\::0}',
}

-- opts: title, lines or source (a command), input (the query), ansi, no_sort, exact, preview,
-- offset, header.
-- vis captures a fullscreen command's stdout and stderr, and tv draws on stderr.
function M.pick(opts)
	local tmp, source = nil, opts.source
	if opts.lines then
		tmp = os.tmpname()
		local f = io.open(tmp, 'w')
		f:write(table.concat(opts.lines, '\n'), '\n')
		f:close()
		source = 'cat ' .. util.quote(tmp)
	end
	local args = { 'tv', '--source-command', util.quote(source), '--input-header', util.quote(opts.title) }
	if opts.input and opts.input ~= '' then
		args[#args + 1] = '--input ' .. util.quote(opts.input)
	end
	if opts.ansi then
		args[#args + 1] = "--ansi --source-output '{strip_ansi}'"
	end
	if opts.no_sort then
		args[#args + 1] = '--no-sort'
	end
	if opts.exact then
		args[#args + 1] = '--exact'
	end
	if opts.preview then
		args[#args + 1] = '--preview-command ' .. util.quote(opts.preview)
	else
		args[#args + 1] = '--no-preview'
	end
	if opts.offset then
		args[#args + 1] = '--preview-offset ' .. util.quote(opts.offset)
	end
	if opts.header then
		args[#args + 1] = '--preview-header ' .. util.quote(opts.header)
	end
	local status, out = vis:pipe(table.concat(args, ' ') .. ' </dev/tty 2>/dev/tty', true)
	if tmp then
		os.remove(tmp)
	end
	return status == 0 and out and out:match('[^\n]+') or nil
end

-- files as nvim's telescope path_display shows them, `name (dir)`, after their devicon
local cwd = os.getenv('PWD') or ''
local dimmed = M.fg('#6b7089')
local function entry(path)
	if path:sub(1, #cwd + 1) == cwd .. '/' then
		path = path:sub(#cwd + 2)
	end
	local dir, name = path:match('^(.*)/([^/]*)$')
	local icon = icons.path(path)
	return M.fg(icon[2]) .. icon[1] .. '\27[0m ' .. (name or path) .. ' ' .. dimmed .. '(' .. (dir or '.') .. ')\27[0m'
end
-- tv's templates can't split a path, so dir and name are taken apart by regex
local path = [[{strip_ansi|replace:s/^\S+ .* \((.*)\)$/$1/}/{strip_ansi|replace:s/^\S+ (.*) \(.*\)$/$1/}]]

local function pick_file(title, paths)
	local lines = {}
	for _, p in ipairs(paths) do
		lines[#lines + 1] = entry(p)
	end
	local picked = M.pick({ title = title, lines = lines, ansi = true, preview = M.bat .. util.quote(path), header = path })
	local name, dir = (picked or ''):match('^%S+ (.*) %((.*)%)$')
	if name then
		util.open(dir .. '/' .. name)
	end
end

local function lines_of(command)
	local p = io.popen(command)
	local lines = {}
	for line in p:lines() do
		lines[#lines + 1] = line
	end
	p:close()
	return lines
end

local last
-- remembered for M.resume
local function picker(fn)
	return function()
		last = fn
		fn()
	end
end

M.find_files = picker(function()
	pick_file('Find Files', lines_of('rg --files 2>/dev/null'))
end)

M.git_files = picker(function()
	local paths = lines_of('git ls-files --cached --exclude-standard 2>/dev/null')
	pick_file('Git Files', #paths > 0 and paths or lines_of('rg --files 2>/dev/null'))
end)

-- most recent first, which tv puts next to the prompt; without the current file
M.recent_files = picker(function()
	local paths = {}
	for _, p in ipairs(lines_of('cat ' .. util.quote(mru.fzfmru_filepath) .. ' 2>/dev/null')) do
		local f = p ~= vis.win.file.path and io.open(p)
		if f then
			f:close()
			paths[#paths + 1] = p
		end
	end
	pick_file('Recent Files', paths)
end)

-- every line, matched as a substring: telescope's live_grep runs rg per query, which tv can't
M.live_grep = picker(function()
	local picked = M.pick({
		title = 'Live Grep',
		source = 'rg . --no-heading --line-number --color=never --max-columns=300 --max-columns-preview',
		exact = true,
		preview = M.location.preview,
		offset = M.location.offset,
		header = M.location.header,
	})
	-- on the line's first non-blank: tv doesn't say where the query matched
	local file, line, text = (picked or ''):match('^(.-):(%d+):(.*)$')
	if file and util.open(file) then
		vis.win.selection:to(tonumber(line), text:find('%S') or 1)
	end
end)

-- the query comes back with ctrl-up, tv's query history
function M.resume()
	if last then
		last()
	end
end

return M
