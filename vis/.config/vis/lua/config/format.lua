local util = require('util')

local format = require('plugins/vis-format')
-- format on save only what nvim's null-ls does (stylua, rustfmt, prettierd); vis-format's
-- other defaults (fmt on text, shfmt, csharpier, ...) would rewrite files nvim leaves alone.
-- C# formats through the language server instead (<leader>=), like nvim's roslyn.
local keep = { lua = true, luaformatter = true, stylua = true, rust = true }
for name in pairs(format.formatters) do
	if not keep[name] then
		format.formatters[name] = nil
	end
end
-- run from the file's directory: prettierd resolves prettier plugins (tailwind, ...) from its cwd
local prettierd = format.stdio_formatter(function(win)
	return 'cd ' .. util.quote(util.dirname(win.file.path or '.')) .. ' && ' .. util.mason .. 'prettierd'
		.. format.with_filename(win, ' ')
end)
for _, syntax in ipairs({ 'javascript', 'typescript', 'html', 'css', 'sass', 'less', 'json', 'yaml', 'markdown' }) do
	format.formatters[syntax] = prettierd
end
format.options.on_save = true

local M = {}

function M.buffer(keys)
	if format.pick(vis.win) then
		return format.apply(keys)
	end
	vis:command('lspc-format')
	return 0
end

function M.toggle()
	format.options.on_save = not format.options.on_save
	vis:info('autoformat ' .. (format.options.on_save and 'on' or 'off'))
end

return M
