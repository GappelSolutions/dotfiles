require("mason").setup()

require("mason-lspconfig").setup({
	ensure_installed = {
		"angularls",
		"csharp_ls",
		"cssls",
		"html",
		"lua_ls",
		"tailwindcss",
		"ts_ls",
	},
	automatic_installation = true,
})

local null_ls = require("null-ls")
local lsp = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()
local util = require("lspconfig/util")
local border = require("config.borders").border

local remove_formatter_on_attach = function(client, bufnr)
	client.server_capabilities.documentFormattingProvider = false
end

null_ls.setup({
	debug = true,
	sources = {
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.csharpier.with({
			cwd = function()
				return vim.fn.getcwd()
			end,
		}),
		null_ls.builtins.formatting.prettierd.with({
			cwd = function()
				return vim.fn.getcwd()
			end,
		}),
		null_ls.builtins.diagnostics.eslint.with({
			cwd = function()
				return vim.fn.getcwd()
			end,
		}),
	},
	on_attach = function(client, bufnr)
		require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
	end,
})

lsp.angularls.setup({
	on_attach = remove_formatter_on_attach,
	capabilities = capabilities,
})

lsp.ts_ls.setup({
	on_attach = remove_formatter_on_attach,
	capabilities = capabilities,
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

lsp.csharp_ls.setup({
	on_attach = remove_formatter_on_attach,
	capabilities = capabilities,
	config = {
		filetypes = { "cs" },
	},
})

lsp.html.setup({
	on_attach = remove_formatter_on_attach,
	capabilities = capabilities,
})

lsp.tailwindcss.setup({
	capabilities = capabilities
})

-- Override the default LSP floating window handler
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

local symbols = { Error = "󰅙", Info = "󰋼", Hint = "󰌵", Warn = "" }

for name, icon in pairs(symbols) do
	local hl = "DiagnosticSign" .. name
	vim.fn.sign_define(hl, { text = icon, numhl = hl, texthl = hl })
end
