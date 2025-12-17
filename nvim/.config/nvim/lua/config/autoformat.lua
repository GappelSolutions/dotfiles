local autoformat_enabled = true
local group_name = "LspFormatting"

-- create the augroup and setup autoformat initially
local function enable_autoformat()
	vim.api.nvim_create_augroup(group_name, { clear = true })
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = group_name,
		callback = function(args)
			local clients = vim.lsp.get_clients({
				bufnr = args.buf,
				name = "null-ls",
			})
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
end

local function disable_autoformat()
	pcall(vim.api.nvim_del_augroup_by_name, group_name)
end

-- enable it by default
enable_autoformat()

vim.api.nvim_create_user_command("ToggleAutoFormat", function()
	if autoformat_enabled then
		disable_autoformat()
		autoformat_enabled = false
		print("Autoformat: OFF")
	else
		enable_autoformat()
		autoformat_enabled = true
		print("Autoformat: ON")
	end
end, {})
