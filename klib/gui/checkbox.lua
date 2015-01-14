
local classes = require "klib.classes"

local gui_utils = require "klib.gui.utils"

local Button = require("klib.gui.button").Button

local m = classes.module "klib.gui.checkbox"

local CheckBox = classes.class(m, "CheckBox", Button)

function CheckBox:init(text, value)
	Button.init(self, text)
	self.value = value
end

function CheckBox:calc_min_size()
	local w, h = gui_utils.text_size(self:get_font(), self.text)
	local ml, mt, mr, mb = self:get_margins()
	return w+h+3+ml+mr, h+2+mt+mb
end

function CheckBox:on_mouse_release(x, y, btn)
	if (btn == "l") and (self:hit_test(x, y) == self) then
		self.value = not self.value
	end
	Button.on_mouse_release(self, x, y, btn)
end

return m
