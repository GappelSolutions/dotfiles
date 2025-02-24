RightScreenSpace = 58
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
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
vim.opt.undodir = "/home/cgpp/.undotree/"
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

vim.cmd([[
augroup Indentation
  autocmd!
  autocmd FileType javascript setlocal shiftwidth=2 tabstop=2 softtabstop=2
  autocmd FileType typescript setlocal shiftwidth=2 tabstop=2 softtabstop=2
  autocmd FileType html setlocal shiftwidth=2 tabstop=2 softtabstop=2
  autocmd FileType csharp setlocal shiftwidth=4 tabstop=4 softtabstop=4
  autocmd FileType json setlocal shiftwidth=4 tabstop=4 softtabstop=4
augroup END
]])
