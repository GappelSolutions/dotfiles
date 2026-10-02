local rows = require('util').rows

local M = {}

-- scrolloff=8: vis only scrolls once the cursor leaves the window. Runs before the lexer
-- (index 1), so the slid view is the one that gets coloured and drawn.
local scrolloff = 8
vis.events.subscribe(vis.events.WIN_HIGHLIGHT, function(win)
	local viewport, cursor = win.viewport, win.selection.line
	local first, last = viewport.lines.start, viewport.lines.finish
	if win ~= vis.win or cursor < first or cursor > last then
		return
	end
	local off = math.min(scrolloff, math.floor((viewport.height - 1) / 2))
	local row = 0
	for lineno = first, cursor - 1 do
		row = row + rows(win, lineno)
	end
	local bottom = viewport.height - 1 - off
	if row < off and first > 1 then
		vis:feedkeys(string.rep('<vis-window-slide-down>', off - row))
	elseif row > bottom and last < #win.file.lines then
		vis:feedkeys(string.rep('<vis-window-slide-up>', row - bottom))
	end
end, 1)

-- <C-d>/<C-u> like nvim: scroll half a window and move the cursor as many lines. vis puts the
-- cursor on the old window edge, and on the file's end or start once that's in view.
function M.halfpage(down)
	return function()
		local win = vis.win
		local viewport, lines = win.viewport, #win.file.lines
		local first, last, line = viewport.lines.start, viewport.lines.finish, win.selection.line
		local n = math.floor(viewport.height / 2)
		local target = down and math.min(line + n, lines) or math.max(line - n, 1)
		local slide = down and math.min(n, lines - last) or math.min(n, first - 1)
		local move = target ~= line and math.abs(target - line) .. (down and 'j' or 'k') or ''
		slide = slide > 0 and slide .. (down and '<vis-window-slide-up>' or '<vis-window-slide-down>') or ''
		-- in the order that keeps the cursor in the window: vis re-centres on one that leaves it
		vis:feedkeys(first <= target and target <= last and move .. slide or slide .. move)
	end
end

return M
