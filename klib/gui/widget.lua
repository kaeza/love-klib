
local classes = require "klib.classes"

local gui_core = require "klib.gui.core"

local m = classes.module "klib.gui.widget"

local math_min, math_max = math.min, math.max

local Widget = classes.class(m, "Widget")

-- Public fields.
Widget.theme = nil

Widget.font = nil
Widget.line_spacing = nil

Widget.enabled = true
Widget.visible = true

Widget.margin_left = 0
Widget.margin_top = 0
Widget.margin_right = 0
Widget.margin_bottom = 0

function Widget:init()
	classes.Object.init(self)
	self.x, self.y, self.w, self.h = 0, 0, 1, 1
end

function Widget:get_font()
	return self.font or self:get_theme():get_font()
end

function Widget:get_theme()
	return self.theme or require("klib.gui.theme").get_default_theme()
end

function Widget:get_root()
	if not self.parent then return self end
	return self.parent:get_root()
end

function Widget:get_parent_window(check_self)
	local item = self
	if not check_self then
		item = item.parent
	end
	local Window = require("klib.gui.window").Window
	while item do
		if classes.isinstance(item, Window) then
			return item
		end
		item = item.parent
	end
end

function Widget:repaint()
	if not self.visible then return end
	self:paint_background()
	self:paint()
	self:paint_foreground()
end

function Widget:paint_background()
end

function Widget:paint_foreground()
end

function Widget:paint()
	local theme = self:get_theme()
	local renderer = theme:get_widget_renderer(self)
	if renderer then
		renderer(theme, self)
	end
end

function Widget:update(dtime)
	if self.nextfuncs then
		for _, func in ipairs(self.nextfuncs) do
			func(self)
		end
		self.nextfuncs = nil
	end
end

function Widget:move(x, y)
	classes.check_types(2, "nn", x, y)
	self.x, self.y = x, y
	return x, y
end

function Widget:resize(w, h)
	classes.check_types(2, "nn", w, h)
	local minw, minh = self:get_min_size()
	local maxw, maxh = self:get_max_size()
	w = math_max(minw, math_min(w, maxw))
	h = math_max(minh, math_min(h, maxh))
	self.w, self.h = w, h
	return w, h
end

function Widget:reshape(x, y, w, h)
	classes.check_types(2, "nnnn", x, y, w, h)
	local minw, minh = self:get_min_size()
	local maxw, maxh = self:get_max_size()
	w = math_max(minw, math_min(w, maxw))
	h = math_max(minh, math_min(h, maxh))
	self.w, self.h = w, h
	self.x, self.y, self.w, self.h = x, y, w, h
	return x, y, w, h
end

function Widget:set_margins(l, t, r, b)
	classes.check_types(2, 1, "n?n?n?n?", l, t, r, b)
	if l then self.margin_left = l end
	if t then self.margin_top = t end
	if r then self.margin_right = r end
	if b then self.margin_bottom = b end
end

function Widget:get_margins()
	return self.margin_left, self.margin_top,
			self.margin_right, self.margin_bottom
end

function Widget:get_rect()
	local x, y = 0, 0
	local item = self
	while item do
		x, y = x + item.x, y + item.y
		item = item.parent
	end
	return x, y, self.w, self.h
end

function Widget:get_rect_rel()
	return self.x, self.y, self.w, self.h
end

function Widget:set_preferred_size(w, h)
	classes.check_types(2, 1, "n?n?", w, h)
	if w then self.pref_w = w end
	if h then self.pref_h = h end
end

function Widget:get_preferred_size()
	if self.pref_w and self.pref_h then
		return self.pref_w, self.pref_h
	end
	local w, h = self:calc_preferred_size()
	return self.pref_w or w, self.pref_h or h
end

function Widget:calc_preferred_size()
	return self:get_min_size()
end

function Widget:set_min_size(w, h)
	classes.check_types(2, 1, "n?n?", w, h)
	if w then self.min_w = w end
	if h then self.min_h = h end
end

function Widget:get_min_size()
	if self.min_w and self.min_h then
		return self.min_w, self.min_h
	end
	local w, h = self:calc_min_size()
	return self.min_w or w, self.min_h or h
end

function Widget:calc_min_size()
	return 1, 1
end

function Widget:set_max_size(w, h)
	classes.check_types(2, 1, "n?n?", w, h)
	if w then self.max_w = w end
	if h then self.max_h = h end
end

function Widget:get_max_size()
	if self.max_w and self.max_h then
		return self.min_w, self.min_h
	end
	local w, h = self:calc_max_size()
	return self.max_w or w, self.max_h or h
end

function Widget:calc_max_size()
	if self.parent then
		return self.parent.w, self.parent.h
	else
		-- TODO: Find better way to get a "safe" maximum value.
		return (2^15)-1, (2^15)-1
	end
end

function Widget:hit_test(x, y)
	if not self.visible then return end
	local sx, sy, w, h = self:get_rect()
	if (x >= sx) and (y >= sy) and (x < sx+w) and (y < sy + h) then
		return self
	end
end

function Widget:next(func)
	if not self.nextfuncs then self.nextfuncs = { } end
	self.nextfuncs[#self.nextfuncs+1] = func
end

function Widget:on_remove()
end

function Widget:on_focus_change(got)
end

function Widget:on_mouse_press(x, y, btn)
end

function Widget:on_mouse_release(x, y, btn, click_count)
end

function Widget:on_mouse_move(x, y)
	self.got_mouse = (self:hit_test(x, y) == self)
end

function Widget:on_mouse_enter(x, y)
	self.got_mouse = true
end

function Widget:on_mouse_leave()
	self.got_mouse = false
end

function Widget:on_key_press(key)
	if self.parent then
		return self.parent:on_key_press(key)
	end
end

function Widget:on_key_release(key)
	if self.parent then
		return self.parent:on_key_release(key)
	end
end

function Widget:on_text_input(text)
	if self.parent then
		return self.parent:on_text_input(text)
	end
end

return m
