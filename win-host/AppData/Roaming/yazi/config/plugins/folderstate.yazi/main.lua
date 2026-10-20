--- @since 26.5.6
--- @sync entry
-- folderstate: each folder's sort, filter and hovered file, across yazi sessions. yazi keeps a
-- folder's filter and hover only until it quits, and the sort is one per tab. This saves them per
-- folder in yazi\state\folderstate.json as they change and puts them back on entering the folder;
-- folders without a saved sort get yazi.toml's. Several yazi instances (Win+E, pickers) merge
-- their changes into the same file.
--   init.lua: require("folderstate"):setup()
--   keymap:   plugin folderstate    writes changes not yet written (hover changes wait up to 1 s)
local M = {}

local PATH = os.getenv("APPDATA") .. "\\yazi\\state\\folderstate.json"
local SORT_KEYS = { "by", "reverse", "dir_first", "translit", "sensitive" }

local db = {}      -- folder (lowercase) -> { sort = yazi.toml's if nil, filter = query?, hovered = name? }
local changed = {} -- folders changed since the last write
local written = 0  -- os.time() of the last write
-- the folder whose saved state is being put back: nothing of it is saved until the sort and filter
-- are in place, and its saved hover stays until the file is hovered (the listing can take a while
-- on a share) or turns out to be gone
local pending

local function read()
	local f = io.open(PATH, "r")
	if not f then return {} end
	local s = f:read("*a")
	f:close()
	local ok, t = pcall(ya.json_decode, s)
	return ok and type(t) == "table" and t or {}
end

-- merges into what's on disk: other instances write the file too
local function write()
	if next(changed) == nil then return end
	local disk = read()
	for key in pairs(changed) do
		disk[key] = db[key]
	end
	db, changed, written = disk, {}, os.time()
	local f = io.open(PATH, "w")
	if f then
		f:write(ya.json_encode(db))
		f:close()
	end
end

local function sort_of(t, prefix)
	return {
		by = tostring(t[prefix .. "by"]),
		reverse = t[prefix .. "reverse"],
		dir_first = t[prefix .. "dir_first"],
		translit = t[prefix .. "translit"],
		sensitive = t[prefix .. "sensitive"],
	}
end

local function same_sort(a, b)
	for _, k in ipairs(SORT_KEYS) do
		if a[k] ~= b[k] then return false end
	end
	return true
end

local function filter_of(folder) return folder.files.filter and tostring(folder.files.filter) or nil end

local function has(folder, name)
	for i = 1, #folder.files do
		if folder.files[i].name == name then return true end
	end
	return false
end

-- reveals the saved hover once the file is listed; gives up when the folder is loaded without it
local function rehover(folder, loaded)
	if has(folder, pending.hovered) then
		ya.emit("reveal", { folder.cwd:join(pending.hovered), no_dummy = true })
	elseif loaded then
		pending.hovered = nil
	end
end

local function restore(cur, key)
	local e = db[key] or {}
	pending = { key = key, sort = e.sort or sort_of(rt.mgr, "sort_"), filter = e.filter, hovered = e.hovered, since = os.time() }
	local s = pending.sort
	if not same_sort(sort_of(cx.active.pref, "sort_"), s) then
		ya.emit("sort", { s.by, reverse = s.reverse, dir_first = s.dir_first, translit = s.translit, sensitive = s.sensitive })
	end
	if filter_of(cur) ~= e.filter then ya.emit("filter_do", { e.filter or "", smart = true, done = true }) end
	if pending.hovered and not (cur.hovered and cur.hovered.name == pending.hovered) then
		rehover(cur, false)
	else
		pending.hovered = nil
	end
end

-- runs on every render: notices entering a folder and changes to the current one
local function track()
	local cur = cx.active.current
	if cur.cwd.is_search then return end
	local key = tostring(cur.cwd):lower()
	if not pending or pending.key ~= key then return restore(cur, key) end

	local sort, filter = sort_of(cx.active.pref, "sort_"), filter_of(cur)
	if not pending.settled then
		-- the emitted sort/filter_do haven't run yet; 5 s: a filter yazi refused
		if (not same_sort(sort, pending.sort) or filter ~= pending.filter) and os.time() - pending.since < 5 then
			return
		end
		pending.settled = true
	end

	local old = db[key] or {}
	local hovered = cur.hovered and cur.hovered.name
	if pending.hovered then
		if hovered == pending.hovered or os.time() - pending.since > 30 then
			pending.hovered = nil
		else
			hovered = old.hovered
		end
	end

	local default = sort_of(rt.mgr, "sort_")
	local layout = not same_sort(old.sort or default, sort) or old.filter ~= filter
	if layout or old.hovered ~= hovered then
		local e = { sort = not same_sort(sort, default) and sort or nil, filter = filter, hovered = hovered }
		db[key] = (e.sort or e.filter or e.hovered) and e or nil
		changed[key] = true
	end
	-- hover changes at most once a second: holding j would write on every frame
	if layout or os.time() - written >= 1 then write() end
end

function M:setup()
	db = read()
	local redraw = Header.redraw
	function Header:redraw(...)
		local ok, err = pcall(track)
		if not ok then ya.err("folderstate: " .. tostring(err)) end
		return redraw(self, ...)
	end
	ps.sub("load", function(body)
		local cur = cx.active.current
		local key = tostring(cur.cwd):lower()
		if pending and pending.hovered and pending.key == key and tostring(body.url):lower() == key and body.stage() then
			rehover(cur, true)
		end
	end)
end

function M:entry() write() end

return M
