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
	capabilities = capabilities,
})

-- Override the default LSP floating window handler
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
	opts = opts or {}
	opts.border = opts.border or border
	return orig_util_open_floating_preview(contents, syntax, opts, ...)
end
