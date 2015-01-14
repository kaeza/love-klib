
local kdebug = require "klib.utils.debug"

local function get_location(level)
	local info = debug.getinfo(level+1)
	return info.short_src, info.currentline
end

local function G_index(t, k)
	local file, line = get_location(2)
	kdebug.warnf("%s:%d: %s", file, line,
			"Access to uninitialized global variable `"..k.."'")
	return rawget(t, k)
end

local G_meta = {
	__index = G_index,
}
setmetatable(_G, G_meta)
