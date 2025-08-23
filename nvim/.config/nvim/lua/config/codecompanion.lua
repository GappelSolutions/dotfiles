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
})
