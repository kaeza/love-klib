
local classes = require "klib.classes"

local Widget = require("klib.gui.widget").Widget

local gui_core = require "klib.gui.core"

local m = classes.module "klib.gui.composite"

local math_max, math_min = math.max, math.min

local Composite = classes.class(m, "Composite", Widget)

function Composite:init(children)
	Widget.init(self)
	classes.check_types(2, 1, "t", children)
	self.children = children
	for i, item in ipairs(children) do
		if not classes.isinstance(item, Widget) then
			error("child at index "..i.." is not a subclass of "
					..Widget.__name, 2)
		end
		if item.parent then
			error("child at index "..i.." already has a parent", 2)
		end
		item.parent = self
	end
end

function Composite:set_margins(l, t, r, b)
	Widget.set_margins(self, l, t, r, b)
	self:layout_items()
end

function Composite:resize(w, h)
	Widget.resize(self, w, h)
	self:layout_items()
end

function Composite:reshape(x, y, w, h)
	Widget.reshape(self, x, y, w, h)
	self:layout_items()
end

function Composite:paint()
	Widget.paint(self)
	for _, item in ipairs(self.children) do
		local sx, sy = gui_core.get_scale()
		local x, y, w, h = item:get_rect()
		local cx, cy, cw, ch = love.graphics.getScissor()
		w = math_max(0, math_min(self.w, w))
		h = math_max(0, math_min(self.h, h))
		love.graphics.setScissor(x*sx, y*sy, w*sx, h*sy)
		item:repaint()
		love.graphics.setScissor(cx, cy, cw, ch)
	end
end

function Composite:update(dtime)
	Widget.update(self, dtime)
	for _, item in ipairs(self.children) do
		item:update(dtime)
	end
end

function Composite:resize(w, h)
	Widget.resize(self, w, h)
	self:layout_items()
end

function Composite:reshape(x, y, w, h)
	Widget.reshape(self, x, y, w, h)
	self:layout_items()
end

function Composite:hit_test(x, y)
	local self_hit = Widget.hit_test(self, x, y)
	if self_hit then
		local sx, sy = self.x, self.y
		local len = #self.children
		for pos = len, 1, -1 do
			local item = self.children[pos]
			local hit = item:hit_test(x, y)
			if hit then
				return hit
			end
		end
	end
	return self_hit
end

function Composite:on_remove()
	for _, item in ipairs(self.children) do
		item:on_remove()
	end
end

function Composite:layout_items()
end

return m
