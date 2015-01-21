
local classes = require "klib.classes"

local gui_utils = require("klib.gui.utils")

local Widget = require("klib.gui.widget").Widget
local Compound = require("klib.gui.compound").Compound

local math_min, math_max = math.min, math.max

local m = classes.module "klib.gui.panes"

local Pane = classes.class("Pane", Compound)

Pane.spacing = 8

function Pane:init(pane1, pane2, is_h)
	if not classes.isinstance(pane1, Widget) then
		error("pane1 must be a subclass of "..Widget.__name, 2)
	elseif not classes.isinstance(pane2, Widget) then
		error("pane2 must be a subclass of "..Widget.__name, 2)
	end
	local splitter = Widget()
	splitter.bg_color = require("klib.gui.core").get_color(255, 255, 0)
	local pane = self
	function splitter:on_mouse_press(x, y, btn)
		Widget.on_mouse_press(self, x, y, btn)
		if btn == "l" then
			self.drag_x, self.drag_y = x, y
		end
	end
	function splitter:on_mouse_release(x, y, btn)
		Widget.on_mouse_release(self, x, y, btn)
		if btn == "l" then
			self.drag_x, self.drag_y = nil, nil
		end
	end
	function splitter:on_mouse_move(x, y)
		Widget.on_mouse_move(self, x, y)
		if self.drag_x then
			local dx, dy = x - self.drag_x, y - self.drag_y
			self.drag_x, self.drag_y = x, y
			local pane1, pane2, splitter = unpack(pane.children)
			local minw1, minh1 = pane1:get_min_size()
			local minw2, minh2 = pane2:get_min_size()
			local ml, mt, mr, mb = pane:get_margins()
			local w, h = pane.w-ml-mr, pane.h-mt-mb
			local minw, maxw, minh, maxh
			if is_h then
				dy = 0
				minw, minh = minw1, 0
				maxw, maxh = w - minw2 - pane.spacing, 0
			else
				dx = 0
				minw, minh = 0, minh1
				maxw, maxh = 0, h - minh2 - pane.spacing
			end
			self:move(math_max(minw, math_min(pane1.w + dx, maxw)),
					math_max(minh, math_min(pane1.h + dy, maxh)))
			pane:layout_items()
		end
	end
	function splitter:on_mouse_enter(x, y)
		Widget.on_mouse_enter(self, x, y)
		love.mouse.setCursor(pane.resize_cursor)
	end
	function splitter:on_mouse_leave()
		Widget.on_mouse_leave(self)
		love.mouse.setCursor()
	end
	splitter.x = -1
	Compound.init(self, { pane1, pane2, splitter })
end

local HPane = classes.class(m, "HPane", Pane)

HPane.resize_cursor = love.mouse.getSystemCursor("sizewe")

function HPane:init(pane1, pane2)
	Pane.init(self, pane1, pane2, true)
end

function HPane:layout_items()
	local ml, mt, mr, mb = self:get_margins()
	local w = self.w - ml - mr - self.spacing
	local h = self.h - mt - mb
	local pane1, pane2, splitter = unpack(self.children)
	if splitter.x < 0 then
		splitter:reshape(ml+(w/2), mt, self.spacing, h)
	else
		splitter:resize(self.spacing, h)
	end
	pane1:reshape(ml, mt, splitter.x - ml, h)
	pane2:reshape(splitter.x+self.spacing, mt, w-splitter.x, h)
end

function HPane:calc_min_size()
	local w1, h1 = self.children[1]:get_min_size()
	local w2, h2 = self.children[2]:get_min_size()
	local ml, mt, mr, mb = self:get_margins()
	return w1+w2+self.spacing+ml+mr, math_max(h1, h2)+mt+mb
end

local VPane = classes.class(m, "VPane", Pane)

VPane.resize_cursor = love.mouse.getSystemCursor("sizens")

function VPane:init(pane1, pane2)
	Pane.init(self, pane1, pane2, false)
end

function VPane:layout_items()
	local ml, mt, mr, mb = self:get_margins()
	local w = self.w - ml - mr - self.spacing
	local h = self.h - mt - mb
	local pane1, pane2, splitter = unpack(self.children)
	if splitter.x < 0 then
		splitter:reshape(ml, mt+(h/2), w, self.spacing)
	else
		splitter:resize(w, self.spacing)
	end
	pane1:reshape(ml, mt, w, splitter.y - mt)
	pane2:reshape(ml, splitter.y+self.spacing, w, h-splitter.y)
end

function VPane:calc_min_size()
	local w1, h1 = self.children[1]:get_min_size()
	local w2, h2 = self.children[2]:get_min_size()
	local ml, mt, mr, mb = self:get_margins()
	return math_max(w1, w2)+ml+mr, h1+h2+self.spacing+mt+mb
end

return m
