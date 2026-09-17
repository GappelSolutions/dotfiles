local parsers = { "lua", "javascript", "html", "typescript", "tsx", "css", "c_sharp", "dockerfile", "razor", "elixir", "heex", "eex" }

require("nvim-treesitter").install(parsers)

vim.api.nvim_create_autocmd("FileType", {
	pattern = parsers,
	callback = function()
		vim.treesitter.start()
		vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.wo[0][0].foldmethod = "expr"
		vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end,
})

require("treesitter-context").setup({
	multiline_threshold = 2,
})

require("nvim-ts-autotag").setup()
