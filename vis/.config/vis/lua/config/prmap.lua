-- PR map (hitch-focus): a PR as the flows its slices run, steps and decisions in plain words.
-- <Space>m opens this branch's map, live over the worktree (its files until hitch-focus
-- sliced it), <Space>M any map. In the flow: gd/Enter open a step's code, <Space>d the
-- slice's diff, ]b/[b walk the slices, <Space>v marks one viewed. In a slice's diff: gd/Enter
-- open the code, ]b/[b the next slice's diff, <Space>m back to the flow. The maps and their
-- buffers come from ~/.claude/skills/hitch-focus/hitch-map.
local util = require('util')
local telescope = require('config.telescope')

local M = {}

local tool = os.getenv('HOME') .. '/.claude/skills/hitch-focus/hitch-map'
local state = (os.getenv('XDG_STATE_HOME') or os.getenv('HOME') .. '/.local/state') .. '/hitch/map/'

local function run(args)
	return util.lines_of(util.quote(tool) .. ' ' .. args .. ' 2>/dev/null')
end

-- the map a block buffer belongs to, and the block's id
local function block_of(path)
	local key, id = (path or ''):match('^(' .. state:gsub('%p', '%%%0') .. '.+)/([^/]+)%.diff$')
	return key and key .. '.json', id
end

-- the map a flow buffer belongs to
local function flow_of(path)
	local key = (path or ''):match('^(' .. state:gsub('%p', '%%%0') .. '.+)/map%.flow$')
	return key and key .. '.json'
end

-- per flow line: its slice and the path:line it pins (hitch-map writes map.at beside it)
local function pins(win)
	local out = {}
	for line in io.lines((win.file.path:gsub('%.flow$', '.at'))) do
		local slice, at = line:match('^([^\t]*)\t(.*)$')
		out[#out + 1] = { slice = slice ~= '' and slice or nil, at = at ~= '' and at or nil }
	end
	return out
end

local function reopen(path)
	-- already showing: reload it, :e on the same path keeps the old text
	if path == vis.win.file.path then
		vis:command('e!')
	elseif path then
		util.open(path)
	end
end

-- the flow buffer, at slice <id>'s header if given
local function open_flow(map, id)
	reopen(run('flow ' .. util.quote(map))[1])
	if id and flow_of(vis.win.file.path) then
		for i, pin in ipairs(pins(vis.win)) do
			if pin.slice == id then
				vis.win.selection:to(i, 1)
				return
			end
		end
	end
end

local function open_block(map, id)
	reopen(run('block ' .. util.quote(map) .. ' ' .. util.quote(id))[1])
end

function M.pick_map()
	local maps = run('list')
	if #maps == 0 then
		vis:info('no PR maps: hitch-focus writes them')
		return
	end
	local labels, by_label = {}, {}
	for _, line in ipairs(maps) do
		local path, label = line:match('^([^\t]+)\t(.*)$')
		label = label .. '  (' .. path:match('([^/]+)/[^/]+$') .. ')'
		labels[#labels + 1] = label
		by_label[label] = path
	end
	local picked = telescope.pick({ title = 'PR maps', lines = labels, no_sort = true })
	if picked and by_label[picked] then
		open_flow(run('live ' .. util.quote(by_label[picked]))[1] or by_label[picked])
	end
end

-- this buffer's map, else the current branch's, rebuilt over the worktree: hitch-focus's
-- slices plus what changed since, or its files without it. Outside a repo: any map
function M.pick()
	local path = vis.win.file.path or ''
	local map, id = block_of(path)
	-- a map's own buffers: its flow, its slices' diffs, the head sources gd opened
	map = map or path:match('^(' .. state:gsub('%p', '%%%0') .. '[^/]+/[^/]+)/') or util.cwd
	map = run('live ' .. util.quote(map:match('%.json$') and map or (io.open(map .. '.json') and map .. '.json' or map)))[1]
	if not map then
		return M.pick_map()
	end
	open_flow(map, id)
end

-- the code at the cursor: a focus line's path:line, else the new-side line of the diff
local function open_code(map, path, line)
	local file = run('file ' .. util.quote(map) .. ' ' .. util.quote(path))[1]
	if file and util.open(file) then
		vis.win.selection:to(tonumber(line), 1)
	end
end

local function goto_code(win)
	local map = block_of(win.file.path)
	local lines, cur = win.file.lines, win.selection.line
	local path, line = lines[cur]:match('· (%S+):(%d+)$')
	-- the hunk's new start, plus the lines above the cursor that exist on the new side
	local count = 0
	for i = cur, 1, -1 do
		if path then
			break
		end
		local l = lines[i]
		local start = l:match('^@@ %-%d+,?%d* %+(%d+)')
		if start or l:match('^diff %-%-git ') then
			line = start and tonumber(start) + count or 1
			for j = i, 1, -1 do
				path = lines[j]:match('^diff %-%-git a/.- b/(.+)$')
				if path then
					break
				end
			end
		elseif i < cur and l:sub(1, 1) ~= '-' then
			count = count + 1
		end
	end
	if not path then
		vis:info('no code under the cursor')
		return
	end
	open_code(map, path, line)
end

local function step(win, delta)
	local map, id = block_of(win.file.path)
	local ids = {}
	for _, l in ipairs(run('outline ' .. util.quote(map))) do
		ids[#ids + 1] = l:match('^(%S+)')
	end
	for i, other in ipairs(ids) do
		if other == id then
			local next_id = ids[i + delta]
			if next_id then
				open_block(map, next_id)
			else
				vis:info(delta > 0 and 'last block' or 'first block')
			end
			return
		end
	end
end

local function mark(win)
	local map, id = block_of(win.file.path)
	local result = run('mark ' .. util.quote(map) .. ' ' .. util.quote(id))[1]
	-- on to the next block once this one is done; re-render it when reopened
	if result == 'viewed' then
		step(win, 1)
	else
		open_block(map, id)
	end
	vis:info(id .. ' ' .. (result or 'failed'))
end

-- the slice under the cursor, or the next one below
local function slice_at(win)
	local all, cur = pins(win), win.selection.line
	for i = cur, #all do
		if all[i].slice then
			return all[i].slice, all
		end
	end
end

local function flow_keys(win)
	local map = flow_of(win.file.path)
	local function code()
		local all = pins(win)
		local pin = all[win.selection.line] or {}
		local path, line = (pin.at or ''):match('^(.+):(%d+)$')
		if path then
			open_code(map, path, line)
		elseif pin.slice then
			open_block(map, pin.slice)
		else
			vis:info('no code on this line')
		end
	end
	for _, key in ipairs({ 'gd', '<Enter>' }) do
		win:map(util.n, key, code)
	end
	win:map(util.n, ' d', function()
		local id = slice_at(win)
		if id then
			open_block(map, id)
		end
	end)
	local function jump(delta)
		local lines, i = win.file.lines, win.selection.line + delta
		while lines[i] do
			if lines[i]:match('^━━') then
				win.selection:to(i, 1)
				return
			end
			i = i + delta
		end
		vis:info(delta > 0 and 'last slice' or 'first slice')
	end
	win:map(util.n, ']b', function()
		jump(1)
	end)
	win:map(util.n, '[b', function()
		jump(-1)
	end)
	win:map(util.n, ' v', function()
		local id = slice_at(win)
		if not id then
			return
		end
		local result = run('mark ' .. util.quote(map) .. ' ' .. util.quote(id))[1]
		local line = win.selection.line
		reopen(run('flow ' .. util.quote(map))[1])
		vis.win.selection:to(line, 1)
		if result == 'viewed' then
			jump(1)
		end
		vis:info(id .. ' ' .. (result or 'failed'))
	end)
end

vis.events.subscribe(vis.events.WIN_OPEN, function(win)
	if flow_of(win.file.path) then
		return flow_keys(win)
	end
	if not block_of(win.file.path) then
		return
	end
	for _, key in ipairs({ 'gd', '<Enter>' }) do
		win:map(util.n, key, function()
			goto_code(win)
		end)
	end
	win:map(util.n, ']b', function()
		step(win, 1)
	end)
	win:map(util.n, '[b', function()
		step(win, -1)
	end)
	win:map(util.n, ' v', function()
		mark(win)
	end)
end)

vis:command_register('prmap', function()
	M.pick()
	return true
end, 'PR map: the flow of this branch')

return M
