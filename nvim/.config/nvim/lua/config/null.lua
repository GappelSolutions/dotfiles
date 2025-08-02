local null_ls = require("null-ls")

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
	},
	on_attach = function(client, bufnr)
		require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
	end,
})
