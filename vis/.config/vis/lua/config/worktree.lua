-- switch git worktree, like nvim/.config/nvim/lua/config/workspace.lua. vis has no sessions:
-- the current file reopens at the same path in the new tree, else the git files picker.
local util = require('util')
local telescope = require('config.telescope')
local lspc = require('plugins/vis-lspc')

local M = {}

local home = os.getenv('HOME')

local function git(args)
	return util.lines_of('git -C ' .. util.quote(util.cwd) .. ' ' .. args .. ' 2>/dev/null')
end

function M.worktrees()
	local list, current = {}, nil
	for _, line in ipairs(git('worktree list --porcelain')) do
		local path = line:match('^worktree (.+)$')
		if path then
			local label = path:sub(1, #home + 1) == home .. '/' and '~' .. path:sub(#home + 1) or path
			current = { path = path, label = label }
			list[#list + 1] = current
		elseif current then
			local branch = line:match('^branch refs/heads/(.+)$')
			if branch then
				current.label = current.label .. '  [' .. branch .. ']'
			elseif line == 'detached' then
				current.label = current.label .. '  [detached]'
			end
		end
	end
	return list
end

function M.switch(dir)
	for win in vis:windows() do
		if win.file.modified then
			vis:info('unsaved: ' .. (win.file.path or '[No Name]'))
			return
		end
	end
	local root = git('rev-parse --show-toplevel')[1]
	local path = vis.win.file.path
	local rel = root and path and path:sub(1, #root + 1) == root .. '/' and path:sub(#root + 2)
	local target = rel and io.open(dir .. '/' .. rel) and dir .. '/' .. rel

	local others = {}
	for win in vis:windows() do
		if win ~= vis.win then
			others[#others + 1] = win
		end
	end
	for _, win in ipairs(others) do
		win:close(true)
	end
	if not vis:command('cd ' .. util.quote(dir)) then
		return
	end
	util.cwd = dir

	local function reopen()
		if target then
			util.open(target)
		else
			telescope.git_files()
		end
	end
	-- lspc runs one server per language, rooted where it started: restart them in the new tree.
	-- Only after each has exited: its EXIT, named like its successor, would drop that from
	-- lspc.running.
	local stopping = {}
	for name, ls in pairs(lspc.running) do
		stopping[name] = true
		ls:shutdown()
	end
	if next(stopping) == nil then
		return reopen()
	end
	-- reopened on the next redraw: vis still holds the exited process while it reports it
	local function later()
		vis.events.unsubscribe(vis.events.UI_DRAW, later)
		reopen()
	end
	local function wait(name, event)
		if event == 'EXIT' or event == 'SIGNAL' then
			stopping[name] = nil
		end
		if next(stopping) == nil then
			vis.events.unsubscribe(vis.events.PROCESS_RESPONSE, wait)
			vis.events.subscribe(vis.events.UI_DRAW, later)
		end
	end
	vis.events.subscribe(vis.events.PROCESS_RESPONSE, wait)
	vis:info('stopping language servers')
end

function M.pick()
	local list = M.worktrees()
	if #list == 0 then
		vis:info('not in a git repository')
		return
	end
	local labels, by_label = {}, {}
	for _, w in ipairs(list) do
		labels[#labels + 1] = w.label
		by_label[w.label] = w.path
	end
	local picked = telescope.pick({ title = 'Worktree', lines = labels, no_sort = true })
	if picked and by_label[picked] then
		M.switch(by_label[picked])
	end
end

return M
