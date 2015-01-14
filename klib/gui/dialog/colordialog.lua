
local classes = require "klib.classes"

local Dialog = require("klib.gui.dialog").Dialog
local Button = require("klib.gui.button").Button
local Label = require("klib.gui.label").Label
local Composite = require("klib.gui.composite").Composite
local Widget = require("klib.gui.widget").Widget
local Grid = require("klib.gui.box").Grid
local ScrollBar = require("klib.gui.scrollbar").ScrollBar
local TextField = require("klib.gui.textfield").TextField

local gui_core = require "klib.gui.core"

local stringex = require "klib.utils.stringex"

local math_min, math_max = math.min, math.max

local m = classes.module "klib.gui.dialog.aboutdialog"

local ColorDialog = classes.class(m, "ColorDialog", Dialog)

-- Private fields.
local p_color = {}

local function create_slider(dlg, text, c, cc)
	local lbl = Label(text)
	local sld = Widget()
	local ent = TextField(tostring(c[cc]))
	function sld:on_mouse_press(x, y, btn)
		Widget.on_mouse_press(self, x, y, btn)
		if btn == "l" then
			self.clicked = true
			self:on_mouse_move(x, y)
		end
	end
	function sld:on_mouse_release(x, y, btn)
		Widget.on_mouse_release(self, x, y, btn)
		if btn == "l" then
			self.clicked = false
		end
	end
	function sld:on_mouse_move(x, y)
		Widget.on_mouse_move(self, x, y)
		if self.clicked then
			local sx, sy = self:get_rect()
			local val = 255 * (x-sx) / self.w
			self:on_value_change(math_max(0, math_min(val, 255)))
		end
	end
	function sld:on_value_change(val)
		local c = dlg[p_color]
		local col = { c.r, c.g, c.b }
		col[cc] = val
		dlg[p_color] = gui_core.get_color(col)
		ent.text = tostring(math.floor(val))
		ent:select(#ent.text)
	end
	function sld:paint()
		Widget.paint(self)
		local x, y, w, h = self:get_rect()
		local bg = { 0, 0, 0 }
		local v = math.floor(dlg[p_color][cc] + 0.5)
		bg[cc] = 255
		love.graphics.setColor(unpack(bg))
		love.graphics.rectangle("fill", x, y, self.w * v / 255, h)
		bg[cc] = 224
		love.graphics.setColor(unpack(bg))
		love.graphics.rectangle("line", x, y, self.w * v / 255, h)
	end
	local comp = Composite({ lbl, sld, ent })
	function comp:layout_items()
		local w, h = self.w, self.h
		lbl:reshape(0, 0, 64, 20)
		sld:reshape(64, 0, w-128, 20)
		ent:reshape(w-64, 0, 64, 20)
	end
	function comp:calc_min_size()
		return 64+256+64, 20
	end
	return comp
end

function ColorDialog:init(title, default)
	default = gui_core.get_color(default)
	self[p_color] = default
	local dlg = self
	local b_ok, b_cl
	local sb_r, sb_g, sb_b, cwid
	sb_r = create_slider(self, "Red", default, 1)
	sb_g = create_slider(self, "Green", default, 2)
	sb_b = create_slider(self, "Blue", default, 3)
	local bw, bh
	b_ok = Button("OK")
	b_ok:set_margins(8, 4, 8, 4)
	b_ok:resize(b_ok:get_preferred_size())
	function b_ok:on_activate()
		if not dlg:on_color_select(dlg[p_color]) then
			dlg:close()
		end
	end
	b_cl = Button("Cancel")
	b_cl:set_margins(8, 4, 8, 4)
	b_cl:resize(b_cl:get_preferred_size())
	function b_cl:on_activate()
		dlg:close()
	end
	cwid = Widget()
	function cwid:paint()
		local x, y, w, h = self:get_rect()
		love.graphics.setColor(dlg[p_color]:unpack())
		love.graphics.rectangle("fill", x, y, w, h)
	end
	local client = Composite({ cwid, sb_r, sb_g, sb_b, b_ok, b_cl })
	function client:layout_items()
		local w, h = self.w, self.h
		local sbw, sbh = sb_r:get_preferred_size()
		cwid:reshape(0, 0, 64, 64)
		sb_r:reshape(64, 0, w-64, sbh)
		sb_g:reshape(64, sbh, w-64, sbh)
		sb_b:reshape(64, sbh*2, w-64, sbh)
		b_ok:move(w-b_cl.w-b_ok.w, h-b_ok.h)
		b_cl:move(w-b_cl.w, h-b_cl.h)
	end
	Dialog.init(self, title, client)
	self:resize_client(128+256+64, 240)
end

function ColorDialog:on_color_select(color)
end

return m
