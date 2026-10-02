-- <C-o>/<C-i>: vis's jumplist belongs to a window, and :e (pickers, yazi, LSP jumps) replaces
-- the window, so the switches between files are kept here, where nvim's jumplist has them too
local open = require('util').open

local M = {}

local back, forward = {}, {}
local focused, switching
local function here(win)
	return { path = win.file.path, line = win.selection.line, col = win.selection.col }
end
vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
	if win == vis.win then
		focused = win
	end
end)
vis.events.subscribe(vis.events.WIN_CLOSE, function(win)
	if win == focused then
		focused = nil
	end
end)
-- the window being left is still open here: :e closes it after the new one opens. First, as
-- other handlers redraw, which focuses the new one.
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	local from = focused and focused.file.path
	if not switching and from and win.file.path and win.file.path ~= from then
		table.insert(back, here(focused))
		forward = {}
	end
end, 1)

-- once vis's jumplist has nothing left in that direction
local function switch(from, to)
	local pos = table.remove(from)
	if not pos then
		return
	end
	local left = here(vis.win)
	if pos.path ~= left.path then
		switching = true
		local opened = open(pos.path)
		switching = false
		if not opened then
			return table.insert(from, pos)
		end
	end
	if left.path then
		table.insert(to, left)
	end
	vis.win.selection:to(pos.line, pos.col)
end

local function jump(action, from, to)
	local win, pos = vis.win, vis.win.selection.pos
	vis:feedkeys(action)
	if vis.win == win and win.selection.pos == pos then
		switch(from, to)
	end
end

function M.back()
	jump('<vis-jumplist-prev>', back, forward)
end

-- the terminal sends <C-i> as <Tab>, vis's align for multiple selections
function M.next()
	if #vis.win.selections > 1 then
		vis:feedkeys('<vis-selections-align-indent-left>')
	else
		jump('<vis-jumplist-next>', forward, back)
	end
end

-- in vis's jumplist too, so <C-o> returns from a jump within the file
function M.lsp(command)
	return function()
		vis:feedkeys('<vis-jumplist-save>')
		vis:command(command)
	end
end

return M
