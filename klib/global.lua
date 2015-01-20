
--[[
  | This file is a convenience module that imports most useful modules into
  | the global namespace (no need to localize required ones).  
--]]

classes = require "klib.classes"

local function dynamic_module(name)
	local ok, m = pcall(require, name)
	if not ok then
		m = { }
	elseif type(m) ~= "table" then
		return m
	end
	local mt = getmetatable(m) or { }
	local old_index = mt.__index or function() end
	function mt:__index(k)
		local info = debug.getinfo(2)
		local v = old_index(self, k)
		if v then return v end
		v = dynamic_module(name.."."..k)
		self[k] = v
		return v
	end
	setmetatable(m, mt)
	return m
end

klib = dynamic_module("klib")
