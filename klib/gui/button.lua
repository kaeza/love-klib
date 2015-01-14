
local classes = require "klib.classes"

local Widget = require("klib.gui.widget").Widget
local TextMixin = require("klib.gui.mixins").TextMixin

local gui_utils = require "klib.gui.utils"

local m = classes.module "klib.gui.button"

local Button = classes.class(m, "Button", { Widget, TextMixin })

-- Public fields.
Button.pressed = false
Button.default = false
Button.margin_left = 4
Button.margin_top = 4
Button.margin_right = 4
Button.margin_bottom = 4

function Button:init(text)
	classes.check_types(2, 1, "s", text)
	Widget.init(self)
	self.text = text
	self.pressed = false
end

function Button:calc_min_size()
	local font = self:get_font()
	local text = self.text
	local w, h = gui_utils.text_size(font, text, self.text_spacing)
	local ml, mt, mr, mb = self:get_margins()
	return w+ml+mr, h+mt+mb
end

function Button:on_mouse_press(x, y, btn)
	Widget.on_mouse_press(self, x, y, btn)
	self.pressed = ((btn == "l") or (btn == "r") or (btn == "m"))
end

function Button:on_mouse_release(x, y, btn)
	Widget.on_mouse_release(self, x, y, btn)
	self.pressed = false
	if self:hit_test(x, y) == self then
		if (not self:on_click(btn)) and (btn == "l") then
			self:on_activate()
		end
	end
end

function Button:on_click(btn)
end

function Button:on_activate()
end

return m
