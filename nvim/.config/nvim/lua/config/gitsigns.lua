local border = require("config.borders").border
require("gitsigns").setup({
	signs = {
		add = { text = "▌" },
		change = { text = "▌" },
		delete = { text = "▌" },
	},
	preview_config = {
		border = border,
	},
	current_line_blame = false, -- Disable inline blame
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
		delay = 1000,
		ignore_whitespace = false,
	},
	current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		vim.keymap.set("n", "<leader>gj", function()
			gs.next_hunk()
		end, { buffer = bufnr, desc = "Next git hunk" })
		vim.keymap.set("n", "<leader>gk", function()
			gs.prev_hunk()
		end, { buffer = bufnr, desc = "Previous git hunk" })
	end,
})

-- Define highlight groups for gitsigns
vim.api.nvim_set_hl(0, "GitSignsAdd", { link = "GitGutterAdd" })
vim.api.nvim_set_hl(0, "GitSignsChange", { link = "GitGutterChange" })
vim.api.nvim_set_hl(0, "GitSignsDelete", { link = "GitGutterDelete" })
