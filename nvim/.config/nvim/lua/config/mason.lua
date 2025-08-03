require("mason").setup()

require("mason-lspconfig").setup({
	ensure_installed = {
		"angularls",
		"csharp_ls",
		"cssls",
		"html",
		"lua_ls",
		"rust_analyzer",
		"tailwindcss",
		"ts_ls",
	},
	automatic_installation = true,
})
