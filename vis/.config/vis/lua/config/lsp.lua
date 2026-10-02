local util = require('util')
local telescope = require('config.telescope')

local mason = util.mason
local lspc = require('plugins/vis-lspc')
lspc.ls_map.typescript.roots = { 'nx.json', 'tsconfig.base.json', '.git' }
-- ngserver doesn't find typescript/@angular itself: probe the cwd, then the copies
-- bundled with Mason's install (as nvim-lspconfig does)
local ng_probe = '"$PWD,' .. os.getenv('HOME')
	.. '/.local/share/nvim/mason/packages/angular-language-server/node_modules/@angular/language-server"'
lspc.ls_map.html = {
	name = 'angular',
	cmd = mason .. 'ngserver --stdio --tsProbeLocations ' .. ng_probe .. ' --ngProbeLocations ' .. ng_probe,
	roots = { 'nx.json', 'angular.json', '.git' },
}
lspc.ls_map.css.cmd = mason .. 'vscode-css-language-server --stdio'
lspc.ls_map.csharp = {
	name = 'csharp-ls',
	cmd = 'csharp-ls',
	roots = { '*.slnx', '*.sln' },
	formatting_options = { tabSize = 4, insertSpaces = true },
}
-- nvim attaches tailwindcss next to the html/css server; vis-lspc runs one server per
-- syntax, so tailwind is an extra server under its own key, opened alongside
lspc.ls_map.tailwind = {
	name = 'tailwindcss',
	cmd = mason .. 'tailwindcss-language-server --stdio',
	roots = { 'nx.json', 'angular.json', 'package.json', '.git' },
}
local tailwind_syntax = { html = true, css = true, sass = true, less = true }
-- vis-lspc only sends didOpen from FILE_OPEN, for vis.win's file, and :e opens the file while
-- vis.win is still the window being left: files from pickers, yazi or <C-o> got no diagnostics
local function attach(win)
	if not (win and win == vis.win and win.file.path and win.syntax) then
		return
	end
	local ls = lspc.get_running_ls(win)
	if ls and ls.initialized and not ls:is_file_opened(win.file) then
		vis:command('lspc-open')
	end
	if tailwind_syntax[win.syntax] then
		local tailwind = lspc.running.tailwindcss
		if not tailwind then
			vis:command('lspc-start-server tailwind')
		elseif tailwind.initialized and not tailwind:is_file_opened(win.file) then
			vis:command('lspc-open tailwind')
		end
	end
end
vis.events.subscribe(vis.events.WIN_OPEN, attach)
vis.events.subscribe(lspc.events.LS_INITIALIZED, function(ls)
	if ls.name == 'tailwindcss' then
		attach(vis.win)
	end
end)

-- references, definitions and completions in tv; locations come as `path:line:col:text`
function lspc:select(choices)
	if #choices < 2 then
		return choices[1]
	end
	local locations = choices[1]:match('^[^:]+:%d+:%d+:') ~= nil
	-- completions start filtered by the word being typed, which vis-lspc then replaces
	local typed
	if not locations then
		local pos = vis.win.selection.pos
		typed = vis.win.file:content(math.max(0, pos - 100), math.min(pos, 100)):match('[%w_$]*$')
	end
	return telescope.pick({
		title = locations and 'LSP Locations' or 'Completions',
		lines = choices,
		input = typed,
		preview = locations and telescope.location.preview,
		offset = locations and telescope.location.offset,
		header = locations and telescope.location.header,
	})
end

return lspc
