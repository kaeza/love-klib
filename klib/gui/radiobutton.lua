
local classes = require "klib.classes"

local gui_utils = require "klib.gui.utils"

local Button = require("klib.gui.button").Button
local Composite = require("klib.gui.composite").Composite

local m = classes.module "klib.gui.radiobutton"

local RadioButton = classes.class(m, "RadioButton", Button)

function RadioButton:init(text, value)
	Button.init(self, text)
	self.value = value
end

function RadioButton:calc_min_size()
	local w, h = gui_utils.text_size(self:get_font(), self.text)
	local ml, mt, mr, mb = self:get_margins()
	return w+h+3+ml+mr, h+2+mt+mb
end

function RadioButton:on_mouse_release(x, y, btn)
	local hit = self:hit_test(x, y)
	if (btn == "l") and (hit == self) then
		self:select()
	end
	return Button.on_mouse_release(self, x, y, btn)
end

function RadioButton:select()
	local p = self.parent
	if classes.isinstance(p, Composite) then
		for _, item in ipairs(p.children) do
			if (item ~= self) and classes.isinstance(item, RadioButton)
					and item.value then
				item.value = false
				item:on_activate()
			end
		end
	end
	self.value = true
end

return m
