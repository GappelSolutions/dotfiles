-- netcd: cd that first reconnects a mapped network drive Windows hasn't restored yet.
-- Remembered mappings come back lazily: one that wasn't reachable at logon (VPN or domain not up
-- yet) stays "Unavailable", without a drive letter, until something reconnects it. Explorer does
-- that on first access; yazi only sees a missing drive and loads forever. So do what Explorer does:
-- `net use` with the remote path Windows remembers under HKCU\Network\<letter>.
--   plugin netcd 'Y:\'    plugin netcd '%YAZI_SPECS%'
local M = {}

local function notify(content, level)
	ya.notify { title = "netcd", content = content, timeout = level == "error" and 6 or 2, level = level }
end

-- the remote path of a remembered mapping, nil for drives that aren't one
local function remembered(drive)
	local output = Command("reg")
		:arg({ "query", "HKCU\\Network\\" .. drive, "/v", "RemotePath" })
		:stdin(Command.NULL)
		:output()
	return output and output.status.success and output.stdout:match("RemotePath%s+REG_SZ%s+([^\r\n]+)")
end

function M:entry(job)
	local target = (job.args[1] or ""):gsub("%%([%w_]+)%%", os.getenv)
	local drive = target:match("^(%a):")
	if drive and not fs.cha(Url(drive .. ":\\")) then
		local remote = remembered(drive:upper())
		if remote then
			notify(string.format("Reconnecting %s: (%s)", drive:upper(), remote), "info")
			local output, err = Command("net")
				:arg({ "use", drive:upper() .. ":", remote })
				:stdin(Command.NULL)
				:stdout(Command.PIPED)
				:stderr(Command.PIPED)
				:output()
			if not (output and output.status.success) then
				local msg = output and output.stderr:gsub("%s+", " ") or tostring(err)
				return notify(string.format("%s: did not reconnect: %s", drive:upper(), msg), "error")
			end
		end
	end
	ya.emit("cd", { Url(target), raw = true })
end

return M
