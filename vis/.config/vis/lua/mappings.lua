-- every key, like nvim/.config/nvim/lua/mappings.lua
local util = require('util')
local format = require('config.format')
local diagnostics = require('config.diagnostics')
local scroll = require('config.scroll')
local git = require('config.git')
local clipboard = require('config.clipboard')
local jumplist = require('config.jumplist')
local telescope = require('config.telescope')
local yazi = require('config.yazi')

local n, i, v, cmd = util.n, util.i, util.v, util.cmd
local function map(modes, lhs, rhs)
	for _, mode in ipairs(type(modes) == 'table' and modes or { modes }) do
		vis:map(mode, lhs, rhs)
	end
end

-- General Editing Mappings
map(n, '<C-s>', cmd('w'))
map({ i, v }, '<C-s>', '<Escape>:w<Enter>')
map(n, '<C-q>', cmd('q'))
map({ i, v }, '<C-q>', '<Escape>:q<Enter>')
map(i, '<Escape>', function()
	vis.mode = n
	diagnostics.refresh(vis.win)
end)
map({ n, v }, 'p', clipboard.put('<vis-put-after>'))
map({ n, v }, 'P', clipboard.put('<vis-put-before>'))

-- windows stack in one direction, so h/k is the previous one and j/l the next
for key, action in pairs({ h = 'prev', k = 'prev', j = 'next', l = 'next', w = 'next' }) do
	map(n, '<C-w><C-' .. key .. '>', '<vis-window-' .. action .. '>')
end

-- visual < and > keep the selection already (nvim's <gv); with several cursors one
-- < or > shifts each cursor's line, a single cursor still takes a motion
for key, shift in pairs({ ['<'] = '<vis-operator-shift-left>', ['>'] = '<vis-operator-shift-right>' }) do
	map(n, key, function()
		vis:feedkeys(#vis.win.selections > 1 and shift .. shift or shift)
	end)
end

-- Visual Mode Mappings for Movement
map(v, 'J', 'jzz')
map(v, 'K', 'kzz')

-- vim's visual D X Y C R act on whole lines, which vis leaves unbound (S is surround's)
for key, op in pairs({ D = 'd', X = 'd', Y = 'y', C = 'c', R = 'c' }) do
	map(v, key, '<vis-mode-visual-linewise>' .. op)
	map(vis.modes.VISUAL_LINE, key, op)
end

-- Normal Mode Mappings for Movement
map(n, ' aa', 'ggVG')
map(n, ' y', '<vis-mark>z<vis-selections-save>ggVG"+y<vis-mark>z<vis-selections-restore>zz')
map(n, ' P', '<vis-mark>z<vis-selections-save>ggVG"+<vis-put-after><vis-mark>z<vis-selections-restore>zz')
map(n, ' D', 'ggVGd')
map(n, ' /', '/<C-r>"<Enter>')
map(n, '<C-t>', '<vis-join-lines>')
map(n, ';', '<vis-motion-search-repeat>zz')
map(n, "'", '<vis-motion-search-repeat-reverse>zz')
map(n, 'J', 'jzz')
map(n, 'K', 'kzz')
map({ n, v }, '<C-d>', scroll.halfpage(true))
map({ n, v }, '<C-u>', scroll.halfpage(false))
map(n, ' n', 'i<Enter><Escape>^')
map(n, 'n', 'o<Escape>')
map(n, 'N', 'O<Escape>')
map(n, '<C-o>', jumplist.back)
map(n, '<Tab>', jumplist.next)
map(n, '<C-i>', jumplist.next)

-- Git
map(n, ' gg', git.lazygit)
-- git (LESS=FRX) and delta both make less quit on a short diff, which vis then redraws over
map(n, ' gh', cmd('!LESS=R git -c pager.diff="delta --paging=always" diff -- "$vis_filepath"'))
map(n, ' gb', cmd('!LESS=R git -c pager.blame="delta --paging=always" blame -- "$vis_filepath"'))
map(n, ' gf', cmd('!lazygit -f "$vis_filepath"'))

-- LSP Mappings
map(n, ' pe', diagnostics.pick)
map(n, ']d', cmd('lspc-next-diagnostic'))
map(n, '[d', cmd('lspc-prev-diagnostic'))
map(n, ' pr', jumplist.lsp('lspc-references'))
map(n, ' PR', jumplist.lsp('lspc-references'))
map(n, ' pd', jumplist.lsp('lspc-definition'))
map(n, ' PD', jumplist.lsp('lspc-definition'))
map(n, ' pi', jumplist.lsp('lspc-implementation'))
map(n, ' r', ':lspc-rename ')
map(n, ' h', cmd('lspc-hover'))
map(n, ' e', cmd('lspc-show-diagnostics'))
map(i, '<C-e>', function()
	vis:command('lspc-completion')
	vis.mode = i
end)
map(n, ' =', format.buffer)
map(n, ' af', format.toggle)

-- Project-wide search/replace (grug-far); :e! reloads a buffer it changed
map(n, ' S', cmd('!scooter'))

-- Telescope
map(n, ' F', telescope.find_files)
map(n, ' ff', telescope.git_files)
map(n, ' fw', telescope.live_grep)
map(n, ' fp', telescope.resume)
map(n, '  ', telescope.recent_files)

-- NvimTree
map(n, ' pf', yazi.open)

-- Typst
map(n, ' cp', cmd('!typst compile "$vis_filepath"'))
