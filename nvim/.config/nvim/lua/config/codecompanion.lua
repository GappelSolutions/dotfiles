vim.g.copilot_enabled = false
vim.g.copilot_no_tab_map = true
vim.api.nvim_set_keymap("i", "<Tab>", "<Tab>", { noremap = true, silent = true })

require("codecompanion").setup({
	strategies = {
		chat = {
			adapter = "copilot",
		},
		inline = {
			adapter = "copilot",
		},
		agent = {
			adapter = "copilot",
		},
	},
	extensions = {
		mcphub = {
			callback = "mcphub.extensions.codecompanion",
			opts = {
				make_vars = true,
				make_slash_commands = true,
				show_result_in_chat = true,
			},
		},
		history = {
			enabled = true,
		},
	},
})
