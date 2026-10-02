-- File tree (nvim-tree): yazi on the current file, opening one quits it
local util = require('util')

local M = {}

function M.open()
	local chosen = os.tmpname()
	vis:command('!yazi --chooser-file=' .. chosen .. ' ' .. util.quote(vis.win.file.path or '.'))
	local f = io.open(chosen)
	local path = f and f:read('*l')
	if f then
		f:close()
	end
	os.remove(chosen)
	if path and path ~= '' then
		util.open(path)
	end
end

return M
