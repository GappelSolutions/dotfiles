vis.events.subscribe(vis.events.INIT, function()
	vis.options.autoindent = true
	vis.options.ignorecase = true
	vis:command('set theme iceberg')
end)

-- vis has neither a csv filetype nor lexer: ../lexers/csv.lua
vis.ftdetect.filetypes.csv = { ext = { '%.csv$', '%.tsv$' } }

-- subscribed before vis-editorconfig-options so .editorconfig wins
local two_space = { javascript = true, typescript = true, html = true }
vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	win.options.numbers = true
	win.options.cursorline = true
	win.options.colorcolumn = 80
	win.options.expandtab = true
	win.options.tabwidth = two_space[win.syntax] and 2 or 4
end)
