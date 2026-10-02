-- Port of nvim/.config/nvim: stock vis + community plugins (pinned in
-- nix/modules/shared/home-vis.nix); lua/ only fills what no plugin covers (CRLF, Angular
-- templates, tailwind, numhl, scrolloff, lualine, Trouble, unnamedplus, telescope via tv).
-- Language servers and prettierd are nvim's Mason installs.
require('vis')
package.path = debug.getinfo(1, 'S').source:match('^@(.*)/') .. '/lua/?.lua;' .. package.path

-- the order is the event handlers' order
require('options') -- before vis-editorconfig-options, so .editorconfig wins
require('config.crlf') -- before vis-lspc, so language servers get LF
require('config.angular')
require('plugins')
require('config.format')
require('config.lsp')
require('config.diagnostics')
require('config.scroll')
require('config.git')
require('config.lualine')
require('config.clipboard')
require('config.jumplist')
require('mappings')
