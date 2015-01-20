
local classes = require "klib.classes"

local Composite = require("klib.gui.composite").Composite

local m = classes.module "klib.gui.box"

local math_max, math_min, math_floor = math.max, math.min, math.floor

local Box = classes.class("Box", Composite)

-- Public fields.
Box.spacing = 0

local HBox = classes.class(m, "HBox", Box)

function HBox:layout_items()
	local w, h = self.w, self.h
	local ml, mt, mr, mb = self:get_margins()
	local spc = self.spacing
	w = w - (spc * (#self.children - 1)) - ml - mr
	h = h - mt - mb
	local expanders = 0
	for index, item in ipairs(self.children) do
		if item.layout and item.layout.expand then
			expanders = expanders + 1
		else
			local iw, ih = item:get_min_size()
			w = w - iw
		end
	end
	local expander_w = w / expanders
	local x = ml
	for index, item in ipairs(self.children) do
		local iw
		if item.layout and item.layout.expand then
			iw = expander_w
		else
			local tw, th = item:get_min_size()
			iw = tw
		end
		item:reshape(x, mt, iw, h)
		x = x + iw + spc
	end
end

function HBox:calc_min_size()
	local w, h = 0, 0
	local spacing = self.spacing * (#self.children - 1)
	for _, item in ipairs(self.children) do
		local iw, ih = item:get_min_size()
		w = w + iw
		h = math_max(h, ih)
	end
	local ml, mt, mr, mb = self:get_margins()
	return w+ml+mr+spacing, h+mt+mb
end

local VBox = classes.class(m, "VBox", Box)

function VBox:layout_items()
	local w, h = self.w, self.h
	local ml, mt, mr, mb = self:get_margins()
	local spc = self.spacing
	w = w - ml - mr
	h = h - (spc * (#self.children - 1)) - mt - mb
	local expanders = 0
	for index, item in ipairs(self.children) do
		if item.layout and item.layout.expand then
			expanders = expanders + 1
		else
			local iw, ih = item:get_min_size()
			h = h - ih
		end
	end
	local expander_h = h / expanders
	local y = mt
	for index, item in ipairs(self.children) do
		local ih
		if item.layout and item.layout.expand then
			ih = expander_h
		else
			local tw, th = item:get_min_size()
			ih = th
		end
		item:reshape(ml, y, w, ih)
		y = y + ih + spc
	end
end

function VBox:calc_min_size()
	local w, h = 0, 0
	local spacing = self.spacing * (#self.children - 1)
	for _, item in ipairs(self.children) do
		local iw, ih = item:get_min_size()
		w = math_max(w, iw)
		h = h + ih
	end
	local ml, mt, mr, mb = self:get_margins()
	return w+ml+mr, h+mt+mb+spacing
end

local Grid = classes.class(m, "Grid", Box)

-- Public fields.
Grid.vspacing = nil

function Grid:init(children, cols, rows)
	classes.check_types(2, 2, "nn", cols, rows)
	self.cols = cols
	self.rows = rows
	Box.init(self, children)
end

local floor = math.floor

function Grid:layout_items()
	local w, h = self.w, self.h
	local ml, mt = self.margin_left, self.margin_top
	local hm = ml + self.margin_right
	local vm = mt + self.margin_bottom
	local hs, vs = self.spacing, self.vspacing or self.spacing
	w = w - (hs * (self.cols - 1)) - hm
	h = h - (vs * (self.rows - 1)) - vm
	local cs, rs = self.cols, self.rows
	local wpi = (w / cs)
	local hpi = (h / rs)
	for index, item in ipairs(self.children) do
		local xi, yi = (index-1) % cs, math_floor((index-1) / cs)
		item:reshape(ml+((wpi+hs)*xi), mt+((hpi+vs)*yi), wpi, hpi)
	end
end

function Grid:set_spacing(hs, vs)
	classes.check_types(2, 1, "n?n?", hs, vs)
	if hs then self.spacing = hs end
	if vs then self.vspacing = vs end
end

function Grid:get_preferred_size()
	local colw, rowh = { }, { }
	for index, item in ipairs(self.children) do
		local xi = (index - 1) % self.cols
		local yi = math_floor((index - 1) / self.cols)
		local ipw, iph = item:get_preferred_size()
		colw[yi] = math_max(colw[yi] or 0, ipw)
		rowh[xi] = math_max(rowh[xi] or 0, iph)
	end
	colw = math_max(unpack(colw))
	rowh = math_max(unpack(rowh))
	return colw * self.cols, rowh * self.rows
end

return m
