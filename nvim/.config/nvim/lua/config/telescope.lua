local border_chars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }

local actions = require("telescope.actions")
require("telescope").setup({
	defaults = {
		borderchars = border_chars,
		mappings = {
			n = {
				["<C-k>"] = actions.preview_scrolling_up,
				["<C-j>"] = actions.preview_scrolling_down,
			},
		},
		path_display = {
			shorten = {
				len = 3,
				exclude = { 1, -1 },
			},
			truncate = true,
		},
		layout_config = {
			horizontal = {
				width = 0.95,
				height = 0.95,
				preview_width = 0.6,
			},
		},
	},
})
require("telescope").load_extension("ui-select")
require("telescope").load_extension("recent_files")
