-- cwd = git worktree root, one persistence session per worktree.

local M = {}

local function git(args, cwd)
	local out = vim.fn.systemlist({ "git", "-C", cwd, unpack(args) })
	if vim.v.shell_error ~= 0 then
		return nil
	end
	return out
end

local function worktree_root(path)
	local out = git({ "rev-parse", "--show-toplevel" }, path)
	return out and out[1] ~= "" and out[1] or nil
end

function M.worktrees()
	local out = git({ "worktree", "list", "--porcelain" }, vim.fn.getcwd())
	if not out then
		return {}
	end
	local list, current = {}, nil
	for _, line in ipairs(out) do
		local path = line:match("^worktree (.+)$")
		if path then
			current = { path = path, label = vim.fn.fnamemodify(path, ":~") }
			table.insert(list, current)
		elseif current then
			local branch = line:match("^branch refs/heads/(.+)$")
			if branch then
				current.label = current.label .. "  [" .. branch .. "]"
			elseif line == "detached" then
				current.label = current.label .. "  [detached]"
			end
		end
	end
	return list
end

function M.switch(dir)
	if vim.fn.isdirectory(dir) == 0 then
		vim.notify("no such worktree: " .. dir, vim.log.levels.ERROR)
		return
	end
	local persistence = require("persistence")
	persistence.save()
	vim.cmd("silent! %bdelete!")
	vim.cmd.cd(vim.fn.fnameescape(dir))
	persistence.load()
	vim.notify("worktree: " .. vim.fn.fnamemodify(dir, ":~"))
end

function M.pick()
	local list = M.worktrees()
	if #list == 0 then
		vim.notify("not in a git repository", vim.log.levels.WARN)
		return
	end
	vim.ui.select(list, {
		prompt = "Worktree",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if choice then
			M.switch(choice.path)
		end
	end)
end

vim.api.nvim_create_user_command("Worktree", function(opts)
	if opts.args ~= "" then
		M.switch(vim.fn.expand(opts.args))
	else
		M.pick()
	end
end, { nargs = "?", complete = "dir" })

-- Land in the worktree root and restore its session when nvim is started bare.
vim.api.nvim_create_autocmd("VimEnter", {
	nested = true,
	callback = function()
		if vim.fn.argc() > 0 or vim.g.started_with_stdin then
			return
		end
		local root = worktree_root(vim.fn.getcwd())
		if root then
			vim.cmd.cd(vim.fn.fnameescape(root))
		end
		require("persistence").load()
	end,
})

vim.api.nvim_create_autocmd("StdinReadPre", {
	callback = function()
		vim.g.started_with_stdin = true
	end,
})

return M
