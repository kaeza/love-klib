
local classes = require "klib.classes"

local gui_utils = require("klib.gui.utils")

local Widget = require("klib.gui.widget").Widget
local TextMixin = require("klib.gui.mixins").TextMixin

local m = classes.module "klib.gui.label"

local Label = classes.class(m, "Label", { Widget, TextMixin })

function Label:init(text)
	classes.check_types(2, 1, "s", text)
	Widget.init(self)
	self.text = text
end

function Label:calc_min_size()
	local font = self:get_font()
	local text = self.text
	local w, h = gui_utils.text_size(font, text)
	local ml, mt, mr, mb = self:get_margins()
	return w+mr+ml, h+mt+mb
end

return m
