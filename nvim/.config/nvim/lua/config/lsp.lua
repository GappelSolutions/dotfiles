local mason_lspconfig = require("mason-lspconfig")
local lspconfig = require("lspconfig")
local null_ls = require("null-ls")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local util = require("lspconfig/util")
local border = require("config.borders").border

require("colorizer").setup()
require("mason").setup({
	registries = {
		"github:mason-org/mason-registry",
		"github:Crashdummyy/mason-registry",
	},
})

mason_lspconfig.setup({
	ensure_installed = {
		"angularls",
		"eslint",
		"html",
		"lua_ls",
		"tailwindcss",
		"ts_ls",
	},
	automatic_installation = true,
})

local on_attach = function(client, bufnr)
	if client.name ~= "null-ls" then
		client.server_capabilities.documentFormattingProvider = false
		client.server_capabilities.documentRangeFormattingProvider = false
	end

	require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
end

null_ls.setup({
	debug = true,
	sources = {
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.csharpier.with({
			cwd = function(params)
				return util.root_pattern(".git", ".csharpierrc", ".editorconfig")(params.bufname) or vim.fn.getcwd()
			end,
		}),
		null_ls.builtins.formatting.prettierd.with({
			cwd = function(params)
				return util.root_pattern(".git", ".prettierrc", "package.json", ".editorconfig")(params.bufname)
					or vim.fn.getcwd()
			end,
			filetypes = {
				"javascript",
				"javascriptreact",
				"typescript",
				"typescriptreact",
				"vue",
				"css",
				"scss",
				"less",
				"html",
				"json",
				"yaml",
				"markdown",
				"graphql",
				"php",
				"htmlangular",
				"razor",
				"cshtml",
			},
		}),
	},
	on_attach = on_attach,
})

lspconfig.angularls.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	root_dir = util.root_pattern("angular.json", "nx.json", ".git"),
})

lspconfig.ts_ls.setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

lspconfig.lua_ls.setup({
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
		},
	},
	on_attach = on_attach,
	capabilities = capabilities,
})

-- lspconfig.csharp_ls.setup({
-- 	on_attach = on_attach,
-- 	capabilities = capabilities,
-- })
--
lspconfig.html.setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

lspconfig.tailwindcss.setup({
	on_attach = on_attach,

	capabilities = capabilities,
})

lspconfig.eslint.setup({
	on_attach = on_attach,
	capabilities = capabilities,
})

lspconfig.roslyn.setup()
lspconfig.rzls.setup()

local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or border
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

vim.diagnostic.config({
	float = {
		border = border,
		source = "always",
	},
})

vim.diagnostic.config({
	signs = {
		active = true,
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅙",
			[vim.diagnostic.severity.WARN] = "",
			[vim.diagnostic.severity.INFO] = "󰋼",
			[vim.diagnostic.severity.HINT] = "󰌵",
		},
	},
})

vim.api.nvim_create_autocmd("BufWritePre", {
	group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
	callback = function(args)
		local clients = vim.lsp.get_active_clients({ bufnr = args.buf, name = "null-ls" })
		if #clients > 0 then
			vim.lsp.buf.format({
				async = false,
				bufnr = args.buf,
				filter = function(client)
					return client.name == "null-ls"
				end,
			})
		end
	end,
})
