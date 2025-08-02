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
