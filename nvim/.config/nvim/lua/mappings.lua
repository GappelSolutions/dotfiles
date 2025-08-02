-- Leader key configuration
vim.g.mapleader = " "

-- Utility function for setting key mappings
local function Map(mode, lhs, rhs, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	if type(rhs) == "function" then
		rhs = string.format("<cmd>lua %s()<cr>", debug.getinfo(rhs).source:match("[%w_]+"))
	end
	if opts and opts.buffer then
		vim.api.nvim_buf_set_keymap(opts.buffer, mode, lhs, rhs, options)
	else
		vim.api.nvim_set_keymap(mode, lhs, rhs, options)
	end
end

-- General Editing Mappings
Map("n", "<C-s>", "<cmd>:w<cr>")
Map("i", "<C-s>", "<Esc><cmd>:w<cr>")
Map("v", "<C-s>", "<cmd>:w<cr>")
Map("n", "<C-q>", ":q<cr>")
Map("i", "<C-q>", "<Esc>:q<cr>")
Map("v", "<C-q>", ":q<cr>")

Map("v", "p", "pgvy")

-- Visual Mode Mappings for Movement
Map("v", "J", "jzz")
Map("v", "K", "kzz")
Map("v", "<", "<gv")
Map("v", ">", ">gv")

-- Normal Mode Mappings for Movement
Map("n", "<leader>aa", "ggVG")
Map("n", "<leader>y", "mzggVGy`zzz")
Map("n", "<leader>P", "mzggVGpgvy`zzz")
Map("n", "<leader>D", "ggVGd")
Map("n", "<leader>/", '/<C-r>"<cr>')
Map("n", "<leader>t", "J")
Map("n", "<leader>o", "<cmd>NeovimProjectDiscover<cr>")
Map("n", "<leader>db", "<cmd>DBUIToggle<cr>")
Map("n", ";", "nzz")
Map("n", "'", "Nzz")
Map("n", "J", "jzz")
Map("n", "K", "kzz")
Map("n", "<leader>n", "i<cr><Esc>_")
Map("n", "n", "o<Esc>")
Map("n", "N", "O<Esc>")
Map("n", "<S-h>", "<cmd>execute 'normal! 80zh'<cr>", { desc = "Scroll left half page" })
Map("n", "<S-l>", "<cmd>execute 'normal! 80zl'<cr>", { desc = "Scroll right half page" })
Map("n", "<leader>w", "<cmd>set wrap!<cr>")

-- Git
function LazyGitWithFileSearch()
	local file = vim.fn.expand("%:t")
	vim.cmd("LazyGit")

	vim.defer_fn(function()
		vim.api.nvim_feedkeys("/" .. file, "t", true)
		vim.api.nvim_input("<cr>")
		vim.api.nvim_input("<ESC>")
	end, 150)
end

Map("n", "<leader>gg", "<cmd>lua LazyGitWithFileSearch()<cr>", { desc = "[g]it" })
Map("n", "<leader>gh", "<cmd>Gitsigns preview_hunk<cr>")
Map("n", "<leader>gb", "<cmd>Gitsigns blame_line<cr>")
Map("n", "<leader>gf", "<cmd>DiffviewFileHistory %<cr>")
Map("n", "<leader>gq", "<cmd>DiffviewClose<cr>")

-- DAP Mappings
Map("n", "<leader>b", '<cmd>lua require"dap".toggle_breakpoint()<cr>')
Map("n", "<leader>ds", '<cmd>lua require"dap".continue()<cr>')
Map("n", "<leader>DS", '<cmd>lua require"dap".terminate()<cr>')
Map("n", "<leader>dw", '<cmd>lua require"dap".step_over()<cr>')
Map("n", "<leader>de", '<cmd>lua require"dap".step_into()<cr>')
Map("n", "<leader>dq", '<cmd>lua require"dap".step_out()<cr>')
Map("n", "repl", '<cmd>lua require"dap.repl".toggle()<cr>')
Map("n", "<leader>dh", '<Cmd>lua require"dapui".eval()<cr>')
Map("n", "<leader>dg", '<cmd>lua require"dapui".toggle()<cr>')

-- Noice
Map("n", "<leader>q", "<cmd>NoiceDismiss<cr>")

-- LSP Mappings
Map(
	"n",
	"<leader>pe",
	"<cmd>Trouble diagnostics toggle focus filter={buf=0,severity=vim.diagnostic.severity.ERROR}<cr>"
)
Map("n", "<leader>pr", "<cmd>Trouble lsp_references toggle focus<cr>")
Map("n", "<leader>PR", "<cmd>Telescope lsp_references<cr>")
Map("n", "<leader>pd", "<cmd>Telescope lsp_definitions<cr>")
Map("n", "<leader>PD", "<cmd>lua vim.lsp.buf.definition()<cr>")
Map("n", "<leader>pi", "<cmd>lua vim.lsp.buf.implementation()<cr>")
Map("n", "<leader>pa", "<cmd>lua vim.lsp.buf.code_action()<cr>")
Map("n", "<leader>r", "<cmd>lua vim.lsp.buf.rename()<cr>")
Map("n", "<leader>h", "<cmd>lua vim.lsp.buf.hover()<cr>")
Map("n", "<leader>e", "<cmd>lua vim.diagnostic.open_float()<cr>")
Map("n", "<leader>=", "<cmd>lua vim.lsp.buf.format({ async = true })<cr>")

-- Angular Mappings
local opts = { noremap = true, silent = true }
local ng = require("ng")
vim.keymap.set("n", "<leader>pt", ng.goto_template_for_component, opts)
vim.keymap.set("n", "<leader>pc", ng.goto_component_with_template_file, opts)

-- CtrlSF Mappings
Map("n", "<leader>S", "<cmd>GrugFar<cr>")

-- Harpoon
Map(
	"n",
	"<leader>p0",
	'<cmd>lua require("harpoon.mark").add_file()<cr><cmd>lua require("harpoon.ui").toggle_quick_menu()<cr>'
)

Map("n", "<leader>po", '<cmd>lua require("harpoon.ui").toggle_quick_menu()<cr>')

for i = 1, 9 do
	Map("n", "<leader>p" .. i, '<cmd>lua require("harpoon.ui").nav_file(' .. i .. ")<cr>")
end

-- Telescope
Map("n", "<leader>F", "<cmd>Telescope find_files<cr>")
Map("n", "<leader>ff", "<cmd>Telescope git_files<cr>")
Map("n", "<leader>fw", "<cmd>Telescope live_grep<cr>")
Map("n", "<leader>fp", "<cmd>Telescope resume<cr>")
Map("n", "<leader><leader>", "<cmd>lua require('telescope').extensions.recent_files.pick()<cr>")

-- UndoTree
Map("n", "<leader>u", "<cmd>UndotreeToggle<cr>")

-- NvimTree
Map("n", "<leader>pf", "<cmd>NvimTreeToggle<cr>")

vim.api.nvim_create_autocmd("FileType", {
	pattern = "razor",
	callback = function()
		vim.api.nvim_buf_set_keymap(0, "n", "<S-k>", "kzz", { noremap = true, silent = true })
	end,
})

-- Twighlight
Map("n", "<leader>T", "<cmd>Twilight<cr>")
