local null_ls = require("null-ls")
local helpers = require("null-ls.helpers")

local rustfmt = {
	name = "rustfmt",
	method = null_ls.methods.FORMATTING,
	filetypes = { "rust" },
	generator = helpers.formatter_factory({
		command = "rustfmt",
		args = { "--emit=stdout" },
		to_stdin = true,
	}),
}

null_ls.setup({
	debug = true,
	sources = {
		null_ls.builtins.formatting.stylua,
		null_ls.builtins.formatting.csharpier.with({
			command = vim.fn.stdpath("data") .. "/mason/packages/csharpier/csharpier",
			args = { "format", "--write-stdout" },
			to_stdin = true,
		}),
		null_ls.builtins.formatting.prettierd.with({
			cwd = function()
				return vim.fn.getcwd()
			end,
		}),
		null_ls.builtins.formatting.prettier.with({
			filetypes = { "yaml", "yml" },
			args = function()
				return { "--no-bracket-spacing", "--parser", "yaml" }
			end,
			cwd = function()
				return vim.fn.getcwd()
			end,
		}),
		rustfmt,
	},
	on_attach = function(client, bufnr)
		require("workspace-diagnostics").populate_workspace_diagnostics(client, bufnr)
	end,
})
