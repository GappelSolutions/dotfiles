-- clipboard=unnamedplus: yanks and deletes also go to the system clipboard (vis-clipboard,
-- routed like nvim's in home-vis.nix); p/P paste from it once it changed outside vis
local M = {}

local clipboard = os.execute('vis-clipboard --usable >/dev/null 2>&1')
local yanked, copied, external = '', '', false
vis.events.subscribe(vis.events.UI_DRAW, function()
	local values = {}
	for k, value in ipairs(vis.registers['"'] or {}) do
		-- vis 0.9 hands register values to Lua with their C string terminator
		values[k] = value:sub(-1) == '\0' and value:sub(1, -2) or value
	end
	local text = table.concat(values, '\n')
	if clipboard and text ~= yanked then
		yanked, copied, external = text, text, false
		local p = io.popen('vis-clipboard --copy 2>/dev/null', 'w')
		p:write(text)
		p:close()
	end
end)

function M.put(action)
	return function()
		if clipboard then
			local p = io.popen('vis-clipboard --paste 2>/dev/null')
			local text = p:read('*a')
			p:close()
			if text ~= '' and text ~= copied then
				copied, external = text, true
			end
		end
		-- "+ rather than filling the unnamed register, which would keep its linewise flag
		vis:feedkeys((external and '"+' or '') .. action)
	end
end

return M
