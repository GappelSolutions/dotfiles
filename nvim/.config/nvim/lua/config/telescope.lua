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
		path_display = function(opts, path)
			local tail = require("telescope.utils").path_tail(path)
			local dir = path:sub(1, -(#tail + 2))
			return string.format("%s (%s)", tail, dir)
		end,
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
