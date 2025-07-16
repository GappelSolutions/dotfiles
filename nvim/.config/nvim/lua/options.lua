-- screen
RightScreenSpace = 58

-- indentation & tabs → spaces
vim.opt.expandtab = true -- use spaces instead of tabs
vim.opt.shiftwidth = 4 -- width for autoindent
vim.opt.tabstop = 4 -- width of a hard tabstop
vim.opt.softtabstop = 4 -- fine-tune editing of tabs

-- general
vim.opt.clipboard = "unnamedplus"
vim.opt.backspace = "indent,eol,start"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.wrap = true
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = "/Users/cgpp/.undotree/"
vim.opt.undofile = true
vim.g.undotree_WindowLayout = 3
vim.g.undotree_SetFocusWhenToggle = 1
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"
vim.opt.whichwrap:append("h,l")
vim.opt.cursorline = true
vim.o.termguicolors = true

-- workspace folders
vim.g.augment_workspace_folders = {
	"/Users/cgpp/dev/gappel-cloud",
	"/Users/cgpp/dev/CustomerPortal-Angular",
	"/Users/cgpp/dev/CustomerPortal-WebApi",
	"/Users/cgpp/dev/BackOffice-Frontend",
	"/Users/cgpp/dev/BackOffice-Backend",
}

-- per-file overrides
vim.cmd([[
augroup Indentation
  autocmd!
  " use 2-space indents in JS/TS/HTML
  autocmd FileType javascript,typescript,html setlocal expandtab shiftwidth=2 tabstop=2 softtabstop=2
  " use 4-space in C#, JSON, etc.
  autocmd FileType csharp,json setlocal expandtab shiftwidth=4 tabstop=4 softtabstop=4
augroup END
]])
