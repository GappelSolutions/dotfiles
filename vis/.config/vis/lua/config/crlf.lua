-- vis only breaks lines at \n, so CRLF files show ^M: edit them as LF and write CRLF
-- back (nvim's fileformat=dos). Required before vis-lspc so language servers get LF too.
local quote = require('util').quote

local M = { files = {} }

vis.events.subscribe(vis.events.FILE_OPEN, function(file)
	local text = file:content(0, file.size)
	local _, lf = text:gsub('\n', '')
	local _, dos = text:gsub('\r\n', '')
	if dos > 0 and dos == lf then
		file:delete(0, file.size)
		file:insert(0, (text:gsub('\r\n', '\n')))
		file.modified = false
		M.files[file] = true
	end
end)
vis.events.subscribe(vis.events.FILE_SAVE_POST, function(file, path)
	if not M.files[file] then
		return
	end
	-- keep the mtime vis just wrote, or its next :w reports the file as changed on disk
	local stamp = os.tmpname()
	os.execute('touch -r ' .. quote(path) .. ' ' .. stamp)
	local out = assert(io.open(path, 'wb'))
	out:write((file:content(0, file.size):gsub('\r?\n', '\r\n')))
	out:close()
	os.execute('touch -r ' .. stamp .. ' ' .. quote(path))
	os.remove(stamp)
end)
vis.events.subscribe(vis.events.FILE_CLOSE, function(file)
	M.files[file] = nil
end)

return M
