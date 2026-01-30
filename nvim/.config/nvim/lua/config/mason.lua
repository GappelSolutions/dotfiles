require("mason").setup()

require("mason-lspconfig").setup({
	ensure_installed = {
		"tinymist",
		"angularls",
		"cssls",
		"elixirls",
		"html",
		"lua_ls",
		"rust_analyzer",
		"tailwindcss",
		"ts_ls",
	},
	automatic_installation = true,
})
