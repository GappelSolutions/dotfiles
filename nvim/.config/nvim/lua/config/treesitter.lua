require("nvim-treesitter.configs").setup({
	ensure_installed = { "lua", "javascript", "html", "typescript", "tsx", "css", "c_sharp", "dockerfile", "razor" },

	highlight = {
		enable = true,
		additional_vim_regex_highlighting = false,
	},
	indent = {
		enable = true,
	},
})

require("treesitter-context").setup({
	multiline_threshold = 2,
})

require("nvim-ts-autotag").setup()
