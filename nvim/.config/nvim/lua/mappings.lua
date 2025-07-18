-- Leader key configuration
vim.g.mapleader = " "

-- Utility function for setting key mappings
local function Map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	if type(rhs) == "function" then
		rhs = string.format("<cmd>lua %s()<CR>", debug.getinfo(rhs).source:match("[%w_]+"))
	end
	if opts and opts.buffer then
		vim.api.nvim_buf_set_keymap(opts.buffer, mode, lhs, rhs, options)
	else
		vim.api.nvim_set_keymap(mode, lhs, rhs, options)
	end
end

-- Function to delete lock file and open LazyGit
function DeleteLockFileAndOpenLazyGit()
	local lock_file_path = ".git/index.lock"
	if vim.fn.filereadable(lock_file_path) == 1 then
		vim.cmd("silent !del " .. lock_file_path)
	end
	vim.cmd("LazyGit")
end

-- Function to run build command
function RunDetachedBuildCommand()
	local build_command =
		'start cmd.exe /c "dotnet build C:/Users/aiche/dev/gappel-cloud/src/GappelCloud/GappelCloud & pause"'
	os.execute(build_command)
	print("Build started in a new command window")
end

-- General Editing Mappings
Map("n", "<C-s>", "<cmd>:w<CR>")
Map("i", "<C-s>", "<Esc><cmd>:w<CR>")
Map("v", "<C-s>", "<cmd>:w<CR>")
Map("n", "<C-q>", ":q<CR>")
Map("i", "<C-q>", "<Esc>:q<CR>")
Map("v", "<C-q>", ":q<CR>")
Map("v", "p", "pgvy")

-- Visual Mode Mappings for Movement
Map("v", "J", "jzz")
Map("v", "K", "kzz")
Map("v", "<A-j>", ":m '>+1<CR>gv=gvzz")
Map("v", "<A-k>", ":m '<-2<CR>gv=gvzz")
Map("v", "<C-k>", "<C-u>zz")
Map("v", "<C-j>", "<C-d>zz")
Map("v", "<", "<gv")
Map("v", ">", ">gv")

-- Normal Mode Mappings for Movement
Map("n", "<leader>[", "%")
Map("n", "<leader>aa", "ggVG")
Map("n", "<leader>y", "mzggVGy`zzz")
Map("n", "<leader>P", "mzggVGpgvy`zzz")
Map("n", "<leader>D", "ggVGd")
Map("n", "<leader>/", '/<C-r>"<CR>')
Map("n", "<leader>t", "J")
Map("n", "<leader>o", "<cmd>NeovimProjectDiscover<CR>")
Map("n", "<leader>db", "<cmd>DBUIToggle<CR>")
Map("n", ";", "nzz")
Map("n", "'", "Nzz")
Map("n", "J", "jzz")
Map("n", "K", "kzz")
Map("n", "<leader>n", "i<CR><Esc>_")
Map("n", "n", "o<Esc>")
Map("n", "N", "O<Esc>")
Map("n", "<S-h>", ":execute 'normal! 80zh'<CR>", { desc = "Scroll left half page" })
Map("n", "<S-l>", ":execute 'normal! 80zl'<CR>", { desc = "Scroll right half page" })
Map("n", "<A-j>", ":m .+1<CR>==zz")
Map("n", "<A-k>", ":m .-2<CR>==zz")
Map("n", "<C-m>", "<C-w>_")
Map("n", "<leader>w", "<cmd>set wrap!<CR>")

-- Git
Map("n", "<leader>G", "<cmd>lua DeleteLockFileAndOpenLazyGit()<CR>")
Map("n", "<leader>gg", "<cmd>LazyGit<CR>")
Map("n", "<leader>gh", ":Gitsigns preview_hunk<CR>")
Map("n", "<leader>gb", ":Gitsigns blame_line<CR>")

-- DAP Mappings
Map("n", "<leader>b", '<cmd>lua require"dap".toggle_breakpoint()<CR>')
Map("n", "<leader>ds", '<cmd>lua require"dap".continue()<CR>')
Map("n", "<leader>DS", '<cmd>lua require"dap".terminate()<CR>')
Map("n", "<leader>dw", '<cmd>lua require"dap".step_over()<CR>')
Map("n", "<leader>de", '<cmd>lua require"dap".step_into()<CR>')
Map("n", "<leader>dq", '<cmd>lua require"dap".step_out()<CR>')
Map("n", "repl", '<cmd>lua require"dap.repl".toggle()<CR>')
Map("n", "<leader>dh", '<Cmd>lua require"dapui".eval()<CR>')
Map("n", "<leader>dg", '<cmd>lua require"dapui".toggle()<CR>')

-- Noice
Map("n", "<leader>q", "<cmd>NoiceDismiss<CR>")

-- LSP Mappings
Map(
	"n",
	"<leader>pe",
	"<cmd>Trouble diagnostics toggle focus filter={buf=0,severity=vim.diagnostic.severity.ERROR}<cr>"
)
Map("n", "<leader>pr", "<cmd>Trouble lsp_references toggle focus<cr>")
Map("n", "<leader>PR", "<cmd>Telescope lsp_references<cr>")
Map("n", "<leader>pd", "<cmd>Telescope lsp_definitions<CR>")
Map("n", "<leader>PD", "<cmd>lua vim.lsp.buf.definition()<CR>")
Map("n", "<leader>pi", "<cmd>lua vim.lsp.buf.implementation()<CR>")
Map("n", "<leader>pa", "<cmd>lua vim.lsp.buf.code_action()<CR>")
Map("n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<CR>")
Map("n", "<leader>h", "<cmd>lua vim.lsp.buf.hover()<CR>")
Map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<CR>")
Map("n", "<leader>=", "<cmd>lua vim.lsp.buf.format({ async = true })<CR>")

-- Angular Mappings
local opts = { noremap = true, silent = true }
local ng = require("ng")
vim.keymap.set("n", "<leader>pt", ng.goto_template_for_component, opts)
vim.keymap.set("n", "<leader>pc", ng.goto_component_with_template_file, opts)

-- CtrlSF Mappings
Map("n", "<leader>S", "<cmd>GrugFar<CR>")

-- Key binding for build command
Map("n", "<F6>", [[:lua RunDetachedBuildCommand()<CR>]])

-- Harpoon
Map(
	"n",
	"<leader>p0",
	'<cmd>lua require("harpoon.mark").add_file()<CR><cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>'
)

Map("n", "<leader>po", '<cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>')

for i = 1, 9 do
	Map("n", "<leader>p" .. i, '<cmd>lua require("harpoon.ui").nav_file(' .. i .. ")<CR>")
end

-- Telescope
Map("n", "<leader>F", "<cmd>Telescope find_files<CR>")
Map("n", "<leader>ff", "<cmd>Telescope git_files<CR>")
Map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>")
Map("n", "<leader>fp", "<cmd>Telescope resume<CR>")
Map("n", "<leader><leader>", "<cmd>lua require('telescope').extensions.recent_files.pick()<CR>")

-- UndoTree
Map("n", "<leader>u", "<cmd>UndotreeToggle<CR>")

-- NvimTree
Map("n", "<leader>pf", "<cmd>NvimTreeToggle<CR>")

-- -- Augment AI
-- Map("n", "<leader>A", "<cmd>Augment chat-toggle<CR>")
-- Map("n", "<leader>an", "<cmd>Augment chat-new<CR>")
-- Map("n", "<leader>ac", "<cmd>Augment chat<CR>")
-- Map("n", "<leader>ad", "<cmd>Augment disable<CR>")
-- Map("n", "<leader>ae", "<cmd>Augment enable<CR>")

-- Avante
-- Map("n", "<leader>AC", "<cmd>AvanteChat<CR>")
-- Map("n", "<leader>AA", "<cmd>AvanteFocus<CR>")
-- Map("n", "<leader>AS", "<cmd>AvanteStop<CR>")

vim.api.nvim_create_autocmd("FileType", {
	pattern = "razor",
	callback = function()
		vim.api.nvim_buf_set_keymap(0, "n", "<S-k>", "kzz", { noremap = true, silent = true })
	end,
})

-- Twighlight
Map("n", "<leader>T", "<cmd>Twilight<CR>")
