local lsp = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local border = require("config.borders").border

local remove_formatter_on_attach = function(client, bufnr)
	client.server_capabilities.documentFormattingProvider = false
end

lsp.angularls.setup({
	on_attach = remove_formatter_on_attach,
	capabilities = capabilities,
})

lsp.ts_ls.setup({
	on_attach = remove_formatter_on_attach,
	capabilities = capabilities,
	-- lspconfig's default root_dir stops at the nearest tsconfig.json, and Nx
	-- workspaces have one per lib (e.g. libs/ersys/auth/feature-login/tsconfig.json).
	-- That spins up a separate ts_ls instance per lib, so a buffer that sits
	-- under several overlapping libs gets the same reference/diagnostic back
	-- once per instance. Rooting at the Nx workspace instead gives one shared
	-- ts_ls for the whole repo.
	root_dir = require("lspconfig.util").root_pattern("nx.json", "tsconfig.base.json", ".git"),
})

lsp.lua_ls.setup({
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
	capabilities = capabilities,
})

lsp.rust_analyzer.setup({
	on_attach = remove_formatter_on_attach,
	capabilities = capabilities,
	-- For rust-analyzer to provide full functionality like inlay hints and checks
	-- you might need to enable specific settings.
	-- Example (uncomment if needed):
	-- settings = {
	--   ["rust-analyzer"] = {
	--     checkOnSave = {
	--       command = "clippy",
	--     },
	--     inlayHints = {
	--       typeHints = true,
	--       parameterHints = true,
	--       closureCaptureHints = true,
	--       lifetimeElisionHints = "always",
	--       discriminantHints = "field",
	--     },
	--   },
	-- },
})

lsp.html.setup({
	on_attach = remove_formatter_on_attach,
	capabilities = capabilities,
})

lsp.cssls.setup({
	on_attach = remove_formatter_on_attach,
	capabilities = capabilities,
	settings = {
		css = {
			lint = {
				unknownAtRules = "ignore",
			},
		},
		scss = {
			lint = {
				unknownAtRules = "ignore",
			},
		},
		less = {
			lint = {
				unknownAtRules = "ignore",
			},
		},
	},
})

lsp.tailwindcss.setup({
	capabilities = capabilities,
})

lsp.elixirls.setup({
	cmd = { vim.fn.expand("~/.local/share/nvim/mason/packages/elixir-ls/language_server.sh") },
	capabilities = capabilities,
	settings = {
		elixirLS = {
			dialyzerEnabled = true,
			fetchDeps = false,
		},
	},
})

-- Override the default LSP floating window handler
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or border
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

require("neotest").setup({
	adapters = {
		require("neotest-vitest")({
			vitestCommand = "bun vitest",
			vitestConfigFile = "./vitest.config.ts",
		}),
	},
})
