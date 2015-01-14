
-- TODO: This needs implementation in C.

local classes = require "klib.classes"

-- Check for and use C lib if available.
local ok, lib = pcall(require, "klib.gui.clipboard_native")
if ok and lib then
	return lib
end

-- Simple implementation for when native support is not available.

local m = classes.module "klib.gui.clipboard"

local buffer

function m.is_type_supported(type)
	return type == "text/plain"
end

function m.set_data(type, data)
	buffer = {
		type = type,
		data = data,
	}
end

function m.get_data(type)
	if buffer and (buffer.type == type) then
		return buffer.data
	end
end

function m.clear()
	buffer = nil
end

return m
