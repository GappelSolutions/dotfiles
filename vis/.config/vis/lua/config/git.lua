-- branch and diff of each file, for the status line
local util = require('util')

local M = { files = {} }

function M.refresh(file)
	if not file.path then
		return
	end
	local p = io.popen('cd ' .. util.quote(util.dirname(file.path)) .. ' 2>/dev/null'
		.. ' && git rev-parse --abbrev-ref HEAD 2>/dev/null'
		.. ' && git diff --numstat -- ' .. util.quote(file.path) .. ' 2>/dev/null')
	local branch, numstat = p:read('*l'), p:read('*l') or ''
	p:close()
	local added, removed = numstat:match('^(%d+)%s+(%d+)')
	M.files[file.path] = branch and { branch = branch, added = tonumber(added), removed = tonumber(removed) }
end
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	M.refresh(win.file)
end)
vis.events.subscribe(vis.events.FILE_SAVE_POST, M.refresh)

-- lazygit, then the status line catches up with what it committed or discarded
function M.lazygit()
	vis:command('!lazygit')
	M.refresh(vis.win.file)
end

return M
