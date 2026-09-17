require("mason").setup({
	registries = {
		"github:mason-org/mason-registry",
		"github:Crashdummyy/mason-registry",
	},
})

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
	-- mason-lspconfig v2 defaults to auto vim.lsp.enable()-ing every
	-- ensure_installed server with its bare default config. Every server
	-- here is already explicitly set up in lsp.lua (e.g. cssls's
	-- unknownAtRules override), so the auto-enable spins up a second,
	-- unconfigured client per server that fights the real one.
	automatic_enable = false,
})

local mason_registry = require("mason-registry")
mason_registry.refresh(function()
	for _, pkg_name in ipairs({ "roslyn", "prettierd" }) do
		local ok, pkg = pcall(mason_registry.get_package, pkg_name)
		if ok and not pkg:is_installed() then
			pkg:install()
		end
	end
end)
