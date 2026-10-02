local util = require('util')
local lspc = require('config.lsp')
local telescope = require('config.telescope')

local M = {}

-- lualine's diagnostics symbols, in iceberg's diagnostic colours
M.severities = {
	{ icon = '󰅚 ', colour = '#e27878' },
	{ icon = '󰀪 ', colour = '#e2a478' },
	{ icon = '󰋽 ', colour = '#89b8c2' },
	{ icon = '󰌶 ', colour = '#6b7089' },
}
-- underline like nvim's DiagnosticUnderline*, keeping the text's colour (vis can't colour
-- an underline: the severity shows in the line number and the status line)
lspc.highlight_diagnostics = 'range'
lspc.diagnostic_styles = {
	error = 'fore:default,underlined',
	warning = 'fore:default,underlined',
	information = 'fore:default,underlined',
	hint = 'fore:default,underlined',
}

local function each(win)
	local open = win.file.path and lspc.open_files[win.file.path]
	return coroutine.wrap(function()
		for _, list in pairs(open and open.diagnostics or {}) do
			for _, d in ipairs(list) do
				coroutine.yield(d)
			end
		end
	end)
end

-- per severity, and the worst one on the cursor line
function M.counts(win)
	local counts, here = { 0, 0, 0, 0 }, nil
	local line = win.selection.line - 1
	for d in each(win) do
		local severity = d.severity or 1
		counts[severity] = counts[severity] + 1
		if d.range.start.line <= line and line <= d.range['end'].line
			and (not here or severity < (here.severity or 1)) then
			here = d
		end
	end
	return counts, here
end

-- vis-lspc only re-syncs on save; nvim updates diagnostics as you type
function M.refresh(win)
	local open = win.file.path and lspc.open_files[win.file.path]
	for ls in pairs(open and open.language_servers or {}) do
		ls:send_did_change(win.file)
		ls:request_diagnostics(win)
	end
end

-- numhl: a diagnostic's line number takes its severity colour (nvim's DiagnosticSign*)
vis.events.subscribe(vis.events.UI_DRAW, function()
	for win in vis:windows() do
		local worst = {}
		for d in each(win) do
			local line = d.range.start.line + 1
			worst[line] = math.min(worst[line] or 4, d.severity or 1)
		end
		local viewport = win.viewport
		local digits = win.width - viewport.width - 1
		if next(worst) and digits > 0 then
			local row = 0
			for lineno = viewport.lines.start, viewport.lines.finish do
				local severity = worst[lineno]
				if severity then
					win:style_define(win.STYLE_LEXER_MAX, 'fore:' .. M.severities[severity].colour .. ',back:#1e2132')
					for x = 0, digits - 1 do
						win:style_pos(win.STYLE_LEXER_MAX, x, row)
					end
				end
				row = row + util.rows(win, lineno)
			end
		end
	end
end)

-- Trouble: the file's diagnostics, worst first, Enter jumps to one
function M.pick()
	local win = vis.win
	local list = {}
	for d in each(win) do
		list[#list + 1] = d
	end
	if #list == 0 then
		vis:info('no diagnostics')
		return
	end
	table.sort(list, function(a, b)
		if (a.severity or 1) ~= (b.severity or 1) then
			return (a.severity or 1) < (b.severity or 1)
		end
		return a.range.start.line < b.range.start.line
	end)
	local lines = {}
	for _, d in ipairs(list) do
		local severity = M.severities[d.severity or 1]
		lines[#lines + 1] = string.format('%d:%d %s%s%s\27[0m %s%s\27[0m', d.range.start.line + 1,
			d.range.start.character + 1, telescope.fg(severity.colour), severity.icon, (d.message:gsub('%s+', ' ')),
			telescope.fg('#6b7089'), d.source or '')
	end
	-- the buffer as it is, unsaved edits included
	local name = win.file.path:match('[^/]*$')
	local buffer = os.tmpname()
	local f = io.open(buffer, 'w')
	f:write(win.file:content(0, win.file.size))
	f:close()
	local picked = telescope.pick({
		title = 'Diagnostics',
		lines = lines,
		ansi = true,
		no_sort = true,
		preview = telescope.bat .. "--highlight-line '{split:\\::0}' --file-name " .. util.quote(name) .. ' '
			.. util.quote(buffer),
		offset = '{split:\\::0}',
		header = name,
	})
	os.remove(buffer)
	local line, col = (picked or ''):match('^(%d+):(%d+)')
	if line then
		win.selection:to(tonumber(line), tonumber(col))
	end
end

return M
