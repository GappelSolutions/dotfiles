-- nvim/.config/nvim/lua/config/lualine.lua
local chars = require('util').chars
local icons = require('icons')
local crlf = require('config.crlf')
local git = require('config.git')
local diagnostics = require('config.diagnostics')

local severities = diagnostics.severities
local c = {
	bg = '#161821',
	fg = '#c6c8d1',
	green = '#b4be82',
	red = '#e27878',
	file = '#1e2132',
	git = '#3a4059',
	branch = '#c6c8d1',
}
local modes = {
	[vis.modes.NORMAL] = { 'NORMAL', '#84a0c6' },
	[vis.modes.OPERATOR_PENDING] = { 'NORMAL', '#84a0c6' },
	[vis.modes.INSERT] = { 'INSERT', '#89b8c2' },
	[vis.modes.VISUAL] = { 'VISUAL', '#a093c7' },
	[vis.modes.VISUAL_LINE] = { 'V-LINE', '#a093c7' },
	[vis.modes.REPLACE] = { 'REPLACE', '#e27878' },
}
local cwd = os.getenv('PWD') or ''

local function width(s)
	return select(2, s:gsub('[^\128-\191]', ''))
end

local function truncate(s, max)
	if width(s) <= max then
		return s
	end
	local out = {}
	for char in chars(s) do
		if #out >= max - 1 then
			break
		end
		out[#out + 1] = char
	end
	return table.concat(out) .. '…'
end

-- blocks are { bg = colour, { text, fg, bold }, ... }, joined by powerline separators;
-- returns one { char, style } per cell
local function powerline(blocks, right)
	local cells = {}
	local function put(text, fg, bg, bold)
		local style = 'fore:' .. fg .. ',back:' .. bg .. (bold and ',bold' or '')
		for char in chars(text) do
			cells[#cells + 1] = { char, style }
		end
	end
	for k, block in ipairs(blocks) do
		local before = k > 1 and blocks[k - 1].bg or c.file
		if right and before ~= block.bg then
			put('', block.bg, before)
		end
		for _, part in ipairs(block) do
			put(part[1], part[2], block.bg, part[3])
		end
		local after = blocks[k + 1] and blocks[k + 1].bg or c.file
		if not right and after ~= block.bg then
			put('', block.bg, after)
		end
	end
	return cells
end

vis.events.subscribe(vis.events.WIN_STATUS, function(win)
	local file, sel = win.file, win.selection
	local path = file.path or '[No Name]'
	if path:sub(1, #cwd + 1) == cwd .. '/' then
		path = path:sub(#cwd + 2)
	end
	local modified = file.modified and ' ●' or ''
	if win ~= vis.win then
		win:status(' ' .. path .. modified, sel.line .. ':' .. sel.col .. ' ')
		return
	end

	local mode = modes[vis.mode] or modes[vis.modes.NORMAL]
	local left = { { bg = mode[2], { '  ' .. mode[1] .. ' ', c.bg, true } } }
	local repo = git.files[file.path]
	if repo then
		left[#left + 1] = { bg = c.branch, { '  ' .. repo.branch .. ' ', c.bg } }
	end
	local summary = { bg = c.git }
	if repo and (repo.added or 0) > 0 then
		summary[#summary + 1] = { ' +' .. repo.added, c.green }
	end
	if repo and (repo.removed or 0) > 0 then
		summary[#summary + 1] = { ' -' .. repo.removed, c.red }
	end
	local counts, here = diagnostics.counts(win)
	for severity, count in ipairs(counts) do
		if count > 0 then
			summary[#summary + 1] = { ' ' .. severities[severity].icon .. count, severities[severity].colour }
		end
	end
	if #summary > 0 then
		summary[#summary + 1] = { ' ', c.fg }
		left[#left + 1] = summary
	end
	local current = { bg = c.file }
	left[#left + 1] = current

	local extra = {}
	if vis.input_queue ~= '' then
		extra[#extra + 1] = vis.input_queue
	end
	if #win.selections > 1 then
		extra[#extra + 1] = sel.number .. '/' .. #win.selections
	end
	local icon = icons.syntax(win.syntax)
	local total = #file.lines
	local progress = sel.line == 1 and 'Top' or sel.line >= total and 'Bot'
		or string.format('%2d%%', math.floor(sel.line / total * 100))
	local right = powerline({
		{ bg = c.file, { #extra > 0 and table.concat(extra, '  ') .. ' ' or '', c.fg } },
		{
			bg = c.git,
			{ ' utf-8  ✦  ' .. (crlf.files[file] and '' or '') .. '  ✦  ', c.fg },
			{ icon[1] .. ' ', icon[2] },
		},
		{ bg = c.branch, { ' ' .. progress .. '  ' .. string.format('%3d:%-2d', sel.line, sel.col) .. ' ', c.bg } },
	}, true)

	-- no virtual text in vis: the cursor line's diagnostic follows the file name, which
	-- drops its directory when that leaves the message too little room
	local room = win.width - #powerline(left) - #right
	local name = ' ' .. path .. modified .. (vis.recording and ' @' or '') .. ' '
	if here and room - width(name) < 40 then
		name = ' ' .. path:match('[^/]*$') .. modified .. (vis.recording and ' @' or '') .. ' '
	end
	name = truncate(name, math.max(room, 1))
	current[1] = { name, c.fg }
	if here and room - width(name) > 10 then
		local message = severities[here.severity or 1].icon .. here.message:match('[^\n]*')
		current[2] = { truncate(message, room - width(name) - 1) .. ' ', severities[here.severity or 1].colour }
	end

	-- one string for vis to draw, then each cell recoloured (until the next redraw)
	local cells = powerline(left)
	for _ = #cells + #right + 1, win.width do
		cells[#cells + 1] = { ' ', 'fore:' .. c.fg .. ',back:' .. c.file }
	end
	for _, cell in ipairs(right) do
		cells[#cells + 1] = cell
	end
	local text = {}
	for x = 1, win.width - 1 do
		text[x] = cells[x] and cells[x][1] or ' '
	end
	win:status(table.concat(text))
	local style
	for x = 1, math.min(#cells, win.width) do
		if cells[x][2] ~= style then
			style = cells[x][2]
			win:style_define(win.STYLE_LEXER_MAX, style)
		end
		win:style_pos(win.STYLE_LEXER_MAX, x - 1, win.height - 1)
	end
end)
