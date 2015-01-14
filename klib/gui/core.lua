
local classes = require "klib.classes"

local m = classes.module "klib.gui.core"

m.dclick_timeout = 0.3

m.caret_blink_time = 1
m.caret_blink_timer = 0

local colors = setmetatable({ }, { __mode="kv" })

local comp_indices = {
	1, 2, 3, 4,
	r=1, g=2, b=3, a=4,
	red=1, green=2, blue=3, alpha=4
}

local function make_color_meta(hidden)
	return {
		__index = function(_, k)
			local i = comp_indices[k]
			return i and rawget(hidden, i)
					or error("Invalid component: "..tostring(k))
		end,
		__newindex = function(_, k, v)
			error("Colors cannot be changed")
		end,
		__tostring = function()
			return hidden.id
		end,
	}
end

local floor = math.floor
function m.get_color(r, g, b, a)
	if type(r) == "string" then
		local c = (r:match("%x%x%x%x%x%x%x%x")
				or r:match("%x%x%x%x%x%x"))
		assert(c, "Invalid color string")
		r = tonumber(c:sub(1, 2), 16)
		g = tonumber(c:sub(3, 4), 16)
		b = tonumber(c:sub(5, 6), 16)
		a = (c:len() == 8) and tonumber(c:sub(7, 8), 16) or 0xFF
	elseif (type(r) == "number") and (not g) then
		local c = r
		r = floor((c / 0x1000000) % 0x100)
		g = floor((c /   0x10000) % 0x100)
		b = floor((c /     0x100) % 0x100)
		a = floor((c            ) % 0x100)
	elseif type(r) == "table" then
		local c = r
		r = c.r or c[1]
		g = c.g or c[2]
		b = c.b or c[3]
		a = c.a or c[4] or 255
	else
		a = a or 255
	end
	assert(r and g and b, "Missing color component")
	local id = ("%02X%02X%02X%02X"):format(r, g, b, a)
	local color = colors[id]
	if not color then
		color = { }
		local hidden = { r, g, b, a, id=id }
		function color:tostring()
			return id
		end
		function color:tonumber()
			return tonumber(id, 16)
		end
		function color:unpack()
			return unpack(hidden)
		end
		setmetatable(color, make_color_meta(hidden))
		colors[id] = color
	end
	return color
end

local default_font

function m.get_default_font()
	if not default_font then
		default_font = love.graphics.newFont()
	end
	return default_font
end

local scale_x, scale_y = 1, 1

function m.set_scale(sx, sy)
	classes.check_types(2, 1, "nn?", sx, sy)
	scale_x, scale_y = sx, sy or sx
end

function m.get_scale()
	return scale_x, scale_y
end

return m
