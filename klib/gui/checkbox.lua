
local classes = require "klib.classes"

local gui_utils = require "klib.gui.utils"

local Button = require("klib.gui.button").Button

local m = classes.module "klib.gui.checkbox"

local CheckBox = classes.class(m, "CheckBox", Button)

-- Public fields.
CheckBox.value = false

function CheckBox:init(text, value)
	Button.init(self, text)
	self.value = value
end

function CheckBox:calc_min_size()
	local w, h = gui_utils.text_size(self:get_font(), self.text)
	local ml, mt, mr, mb = self:get_margins()
	return w+h+3+ml+mr, h+2+mt+mb
end

function CheckBox:on_activate()
	self.value = not self.value
	self:on_value_change(self.value)
end

function CheckBox:on_value_change(value)
end

return m
