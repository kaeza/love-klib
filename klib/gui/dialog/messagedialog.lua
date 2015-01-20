
local classes = require "klib.classes"

local Widget = require("klib.gui.widget").Widget
local Dialog = require("klib.gui.dialog").Dialog
local Button = require("klib.gui.button").Button
local Label = require("klib.gui.label").Label
local Compound = require("klib.gui.compound").Compound
local HBox = require("klib.gui.box").HBox
local Drawable = require("klib.gui.graphics").Drawable

local math_max, math_min = math.max, math.min

local m = classes.module "klib.gui.messagedialog"

local MessageDialog = classes.class(m, "MessageDialog", Dialog)

local default_options = {
	o = "OK",
	c = "Cancel",
	a = "Abort",
	r = "Retry",
	i = "Ignore",
	y = "Yes",
	n = "No",
	h = "Help",
}

local function get_options(options)
	local t = { }
	local default = false
	for c in options:gmatch(".") do
		if c == "!" then
			default = true
		else
			local text = default_options[c]
			if text then
				table.insert(t, { text, c, default })
			end
			default = false
		end
	end
	return t
end

function MessageDialog:init(title, text, options, icon)
	classes.check_types(2, 2, "s", text)
	local lbl = Label(text)
	lbl.text_align, lbl.text_valign = 0, 0.5
	if icon then
		if type(icon) == "string" then
			local theme = self:get_theme()
			local ok
			ok, icon = pcall(theme.get_image, theme, icon)
			if not (ok and icon) then
				icon = nil
				print("Error:", ok, icon)
			end
		elseif not classes.isinstance(icon, Drawable) then
			error("icon must be a string or an instance of "
					..Drawable.__name, 2)
		end
	end
	options = ((type(options) == "table")
			and options
			or get_options(options or "!o"))
	local dlg = self
	local image
	if icon then
		image = Widget()
		function image:paint()
			icon:draw(self:get_rect())
		end
		function image:calc_min_size()
			return 48, 48
		end
	end
	local buttons = { }
	for index, opt in ipairs(options) do
		local text, val, default = opt[1], opt[2], opt[3]
		local b = Button(text)
		b.default = default
		function b:on_activate()
			if not dlg:on_option_select(val) then
				dlg:close()
			end
		end
		table.insert(buttons, b)
	end
	local bb = HBox(buttons)
	bb:set_margins(8, 8, 8, 8)
	bb.spacing = 4
	local client = Compound({ lbl, bb, image })
	function client:layout_items()
		local bbw, bbh = bb:get_min_size()
		if image then
			local iw, ih = image:get_min_size()
			image:reshape(8, 8, iw, ih)
			lbl:reshape(16+iw, 8, self.w-24-iw, self.h-bbh-8)
		else
			lbl:reshape(8, 8, self.w, self.h-bbh-8)
		end
		bb:reshape(0, self.h-bbh, self.w, bbh)
	end
	function client:calc_min_size()
		local lw, lh = lbl:get_min_size()
		local bbw, bbh = bb:get_min_size()
		local iw, ih = 0, 0
		if image then
			iw, ih = image:get_min_size()
			iw, ih = iw + 8, ih + 8
		end
		return math_max(lw+iw+16, bbw), math_max(lh, ih)+bbh+16
	end
	Dialog.init(self, title, client)
end

function MessageDialog:on_option_select(val)
end

return m
