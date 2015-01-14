
local classes = require "klib.classes"

local theme = require "klib.gui.theme"

local m = classes.module "klib.gui.mixins"

local TextMixin = classes.class(m, "TextMixin")

-- Public Fields.
TextMixin.font = nil
TextMixin.theme = nil
TextMixin.line_spacing = nil

function TextMixin:get_font()
	return self.font or self:get_theme():get_font()
end

function TextMixin:get_theme()
	return self.theme or theme.get_default_theme()
end

return m
