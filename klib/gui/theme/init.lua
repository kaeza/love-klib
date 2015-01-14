
local classes = require "klib.classes"

local gui_core = require "klib.gui.core"

local stringex = require "klib.utils.stringex"

local m = classes.module "klib.gui.theme"

function m.get_default_theme()
	local theme = m.default_theme
	if not theme then
		theme = m.Theme()
		m.default_theme = theme
	end
	return theme
end

local Theme = classes.class(m, "Theme")

Theme.name = "Default Theme"
Theme.id = "default"

Theme.widget_fg_color = gui_core.get_color(255, 255, 255)
Theme.widget_bg_color = gui_core.get_color(64, 64, 64)

Theme.window_fg_color = gui_core.get_color(255, 255, 255)
Theme.window_bg_color = gui_core.get_color(64, 64, 64)

Theme.button_fg_color = gui_core.get_color(255, 255, 255)
Theme.button_bg_color = gui_core.get_color(96, 96, 96)
Theme.button_fg_color_default = gui_core.get_color(255, 255, 240)
Theme.button_bg_color_default = gui_core.get_color(255, 128, 0)

Theme.textfield_fg_color = gui_core.get_color(255, 255, 255)
Theme.textfield_bg_color = gui_core.get_color(48, 48, 48)

Theme.selection_fg_color = gui_core.get_color(255, 255, 255)
Theme.selection_bg_color = gui_core.get_color(0, 0, 96)

Theme.renderers = { }

local gfx = love.graphics
local begin_draw, end_draw = gfx.push, gfx.pop
local set_font = gfx.setFont
local line = gfx.line
local rect = gfx.rectangle
local circle = gfx.circle
local gprint = gfx.print
local text_size = require("klib.gui.utils").text_size

local unpack = unpack or table.unpack
local function set_color(c) gfx.setColor(c:unpack()) end

local min = math.min
local floor = math.floor

local function mulcolor(c, x)
	local r, g, b =
			min(255, c.r * x),
			min(255, c.g * x),
			min(255, c.b * x)
	return gui_core.get_color(r, g, b, c.a)
end

local function interpolate(c1, c2, x)
	return gui_core.get_color(r, g, b, c.a)
end

local function draw_text(font, x, y, w, h, c, halign, valign, text)
	local totw, toth = text_size(font, text)
	local bx, by = x + ((w - totw) * halign), y + ((h - toth) * valign)
	set_color(c)
	set_font(font)
	for line in stringex.split_lines_iter(text) do
		local lw, lh = font:getWidth(line), font:getHeight(line)
		local xx = bx + ((totw - lw) * halign)
		gprint(line, xx, by)
		by = by + font:getHeight(line)
	end
end

Theme.renderers["klib.gui.widget.Widget"] = function(theme, widget)
	local x, y, w, h = widget:get_rect()
	local bg = widget.bg_color or theme.widget_bg_color
	begin_draw()
	set_color(bg)
	rect("fill", x, y, w, h)
	set_color(mulcolor(bg, 0.75))
	rect("line", x, y, w, h)
	end_draw()
end

Theme.renderers["klib.gui.desktop.Desktop"] = function(theme, widget)
	local x, y, w, h = widget:get_rect()
	if widget.bg_color then
		set_color(widget.bg_color)
		rect("fill", x, y, w, h)
	end
	if widget.bg_image then
		local img = widget.bg_image
		local iw, ih = img.w, img.h
		local tx, ty, tw, th
		local mode = widget.bg_image_mode
		if mode == "stretched" then
			tx, ty = x, y
			tw, th = w, h
		else
			tx, ty = x + (w - iw) / 2, y + (h - ih) / 2
			tw, th = iw, ih
		end
		img:draw(tx, ty, tw, th)
	end
end

Theme.renderers["klib.gui.button.Button"] = function(theme, widget)
	local x, y, w, h = widget:get_rect()
	begin_draw()
	local fg = (widget.fg_color
			or (widget.default and theme.button_fg_color_default
				or theme.button_fg_color))
	local bg = (widget.bg_color
			or (widget.default and theme.button_bg_color_default
				or theme.button_bg_color))
	local pressed = widget.got_mouse and widget.pressed
	local offset = pressed and 1 or 0
	if not widget.enabled then
		offset = 0
		fg = mulcolor(fg, 0.5)
	elseif pressed then
		bg = mulcolor(bg, 0.8)
	elseif widget.got_mouse then
		fg = mulcolor(fg, 1.2)
		bg = mulcolor(bg, 1.2)
	end
	set_color(bg)
	rect("fill", x, y, w, h)
	set_color(mulcolor(bg, 0.75))
	rect("line", x, y, w, h)
	local text = widget.text
	if text then
		local font = widget:get_font()
		draw_text(font, x+offset, y+offset, w, h, fg,
				theme.text_halign or 0.5, theme.text_valign or 0.5, text)
	end
	end_draw()
end

local function draw_check(x, y, w, h, checkmode, fg, bg, value)
	if checkmode == "radio" then
		set_color(bg)
		circle("fill", x+(w/2), y+(h/2), h/2)
		set_color(fg)
		circle("line", x+(w/2), y+(h/2), h/2)
		if value then
			circle("fill", x+(w/2), y+(h/2), (h-4)/2)
		end
	elseif checkmode == "check" then
		set_color(bg)
		rect("fill", x, y, w, h)
		set_color(fg)
		rect("line", x, y, w, h)
		if value then
			rect("fill", x+2, y+2, w-4, h-4)
		end
	end
end

local function draw_checkbox(theme, widget, checkmode)
	local x, y, w, h = widget:get_rect()
	begin_draw()
	local fg = widget.fg_color or theme.button_fg_color
	local bg = widget.bg_color or theme.button_bg_color
	local pressed = widget.got_mouse and widget.pressed
	if not widget.enabled then
		fg = mulcolor(fg, 5)
	elseif widget.got_mouse then
		bg = mulcolor(bg, 1.2)
		fg = mulcolor(fg, 1.2)
	end
	local offset = pressed and 1 or 0
	draw_check(x+2, y+2, h-4, h-4, checkmode, fg, bg, widget.value)
	--[[if checkmode == "radio" then
		set_color(bg)
		circle("fill", x+2+((h-4)/2), y+(h/2), (h-4)/2)
		set_color(fg)
		circle("line", x+2+((h-4)/2), y+(h/2), (h-4)/2)
	elseif checkmode == "check" then
		set_color(bg)
		rect("line", x+2, y+2, h-4, h-4)
		set_color(fg)
		rect("line", x+2, y+2, h-4, h-4)
	end
	if widget.value then
		if (checkmode == "radio") or (checkmode == "menuradio") then
			circle("fill", x+4+((h-8)/2), y+(h/2), (h-8)/2)
		elseif (checkmode == "check") or (checkmode == "menucheck") then
			rect("fill", x+4, y+4, h-8, h-8)
		end
	end]]
	local text = widget.text
	if text then
		local font = widget:get_font()
		draw_text(font, x+h+offset, y+offset, w, h, fg,
				theme.text_halign or 0, theme.text_valign or 0.5, text)
	end
	end_draw()
end

Theme.renderers["klib.gui.radiobutton.RadioButton"] = function(theme, widget)
	draw_checkbox(theme, widget, "radio")
end

Theme.renderers["klib.gui.checkbox.CheckBox"] = function(theme, widget)
	draw_checkbox(theme, widget, "check")
end

local function draw_window(theme, widget, text)
	local x, y, w, h = widget:get_rect()
	begin_draw()
	local fg = widget.fg_color or theme.window_fg_color
	local bg = widget.bg_color or theme.window_bg_color
	local bd = mulcolor(bg, 0.75)
	local ml, mt, mr, mb = widget:get_margins()
	local hm, vm = ml + mr, mt + mb
	set_color(bg)
	rect("fill", x, y, w, h)
	set_color(bd)
	rect("line", x, y, w, h)
	if text then
		local font = widget:get_font()
		local tbh, tbs = widget.titlebar_height, widget.titlebar_spacing
		rect("fill", x+ml, y+mt, w-hm, tbh)
		draw_text(font, x + ml, y + mt, w - hm, tbh, fg,
				widget.text_halign or 0.0, widget.text_valign or 0.5, text)
	end
	end_draw()
end

Theme.renderers["klib.gui.window.Window"] = function(theme, widget)
	draw_window(theme, widget, widget.text)
end

local function draw_menu(theme, widget, bar)
	local x, y, w, h = widget:get_rect()
	begin_draw()
	local fg = widget.fg_color or theme.window_fg_color
	local bg = widget.bg_color or theme.window_bg_color
	local sfg = widget.fg_color_selected or theme.selection_fg_color
	local sbg = widget.bg_color_selected or theme.selection_bg_color
	local bd = mulcolor(bg, 0.75)
	set_color(bg)
	rect("fill", x, y, w, h)
	set_color(bd)
	rect("line", x, y, w, h)
	local font = widget:get_theme():get_font()
	for _, item in ipairs(widget.items) do
		local ix, iy = x + item.x, y + item.y
		local iw, ih = item.w, item.h
		local xoff = bar and 4 or 16
		local sel = (item == widget.selected_item)
		local ifg = fg
		local ibg
		if not item.enabled then
			ifg = mulcolor(fg, 0.5)
			ibg = mulcolor(bg, 0.5)
		elseif bar then
			ibg = sel and mulcolor(bg, 1.2) or bg
		else
			ifg = sel and sfg or fg
			ibg = sel and sbg or bg
		end
		if ibg and (item.type ~= "separator") then
			set_color(ibg)
			rect("fill", ix, iy, iw, ih)
		end
		draw_text(font, ix + xoff, iy + 2, iw, ih, ifg, 0, 0, item.text or "")
		if (item.type == "check") or (item.type == "radio") then
			draw_check(ix + ((ih-16)/2), iy + ((ih-16)/2), 12, 12,
					item.type, ifg, ibg, item.value)
		elseif (not bar) and (item.type == "menu") then
			local aw, ah = font:getWidth(">"), font:getHeight(">")
			gprint(">", ix + iw - aw - 2, iy + ((ih - ah) / 2))
		end
	end
	end_draw()
end

Theme.renderers["klib.gui.menu.Menu"] = function(theme, widget)
	draw_menu(theme, widget)
end

Theme.renderers["klib.gui.menu.MenuBar"] = function(theme, widget)
	draw_menu(theme, widget, true)
end

Theme.renderers["klib.gui.label.Label"] = function(theme, widget)
	local x, y, w, h = widget:get_rect()
	local ml, mt, mr, mb = widget:get_margins()
	begin_draw()
	if widget.bg_color then
		set_color(widget.bg_color)
		rect("fill", x, y, x+w, y+h)
	end
	local text = widget.text
	if text then
		local font = widget:get_font()
		draw_text(font, x+ml, y+mt, w-ml-mr, h-mt-mb,
				widget.fg_color or theme.button_fg_color,
				widget.text_halign or 0.0, widget.text_valign or 0.5, text)
	end
	end_draw()
end

Theme.renderers["klib.gui.textfield.TextField"] = function(theme, widget)
	local x, y, w, h = widget:get_rect()
	begin_draw()
	local fg = widget.fg_color or theme.textfield_fg_color
	local bg = widget.bg_color or theme.textfield_bg_color
	if not widget.enabled then
		fg = mulcolor(fg, 0.5)
	elseif widget.pressed then
		bg = mulcolor(bg, 0.8)
	elseif widget.got_mouse then
		fg = mulcolor(fg, 1.2)
		bg = mulcolor(bg, 1.2)
	end
	set_color(bg)
	rect("fill", x, y, w, h)
	set_color(mulcolor(bg, 0.75))
	rect("line", x, y, w, h)
	local text = widget.text
	if text then
		if widget.password_char then
			text = widget.password_char:rep(text:len())
		end
		local font = widget:get_font()
		if widget.selection_start ~= widget.pos then
			set_color(widget.selection_bg_color or theme.selection_bg_color)
			local ssx = math.min(widget.selection_start_x, widget.caret_x)
			rect("fill", x+ssx, y+widget.selection_start_y,
					math.abs(widget.caret_x - widget.selection_start_x),
					math.abs(widget.caret_y - widget.selection_start_y) + 16)
		end
		draw_text(font, x, y, w, h, fg,
				widget.text_halign or 0, widget.text_valign or 0.5, text)
	end
	if widget.focused
			and ((gui_core.caret_blink_timer % gui_core.caret_blink_time)
			<= (gui_core.caret_blink_time / 2)) then
		line(x+widget.caret_x, y+widget.caret_y,
				x+widget.caret_x, y+widget.caret_y+16)
	end
	end_draw()
end

Theme.renderers["klib.gui.listbox.ListBox"] = function(theme, widget)
	local x, y, w, h = widget:get_rect()
	local fg = widget.fg_color or theme.button_fg_color
	local bg = widget.bg_color or theme.window_bg_color
	begin_draw()
	set_color(bg)
	rect("fill", x, y, w, h)
	set_color(mulcolor(bg, 0.75))
	rect("line", x, y, w, h)
	local yy = y
	local view_offset = widget.view_offset or 0
	local ss, se = widget.selection_start, widget.selection_end
	if ss and se then
		ss, se = math.min(ss, se), math.max(ss, se)
	end
	local items = widget.items
	local font = widget:get_font()
	for index = view_offset + 1, #items do
		local item = items[index]
		local lh = font:getHeight(item)
		if yy >= y+h then
			break
		end
		local sfg = fg
		if ss and se and (index >= ss) and (index <= se) then
			sfg = widget.bg_color_selected or theme.selection_fg_color
			local sbg = widget.bg_color_selected or theme.selection_bg_color
			set_color(sbg)
			rect("fill", x, yy, w, lh)
			if index == se then
				set_color(mulcolor(sbg, 0.8))
				rect("line", x, yy, w, lh)
			end
		end
		draw_text(font, x, yy, w, lh, sfg, 0, 0.5, item)
		yy = yy + lh
	end
	end_draw()
end

function Theme:get_font()
	return self.font or gui_core.get_default_font()
end

function Theme:get_widget_renderer(widget)
	if widget.renderer then
		return widget.renderer
	end
	for _, class in ipairs(widget.__mro) do
		local renderer = self.renderers[class.__name]
		if renderer then
			widget.renderer = renderer
			return renderer
		end
	end
end

function Theme:render_widget(widget)
	local r = self:get_widget_renderer(widget)
	if r then
		r(self, widget)
	end
end

local images = { }

local Drawable = require("klib.gui.graphics").Drawable

local gfx = love.graphics

function images.window_max(self)
	gfx.rectangle("line", 4, 4, 120, 120)
end

function images.window_min(self)
	gfx.line(4, 124, 124, 124)
end

function images.window_close(self)
	gfx.line(4, 4, 124, 124)
	gfx.line(4, 124, 124, 4)
end

function images.dialog_info(self)
	gfx.circle("line", 64, 64, 56)
	gfx.circle("fill", 64, 36, 12)
	gfx.rectangle("fill", 52, 56, 24, 48)
end

function images.dialog_warn(self)
	gfx.line(64, 4, 124, 124, 4, 124, 64, 4)
	gfx.rectangle("fill", 52, 40, 24, 48)
	gfx.circle("fill", 64, 108, 12)
end

local dialog_ask_font
function images.dialog_ask(self)
	gfx.line(64, 4, 124, 64, 64, 124, 4, 64, 64, 4)
	-- TODO: Use shapes.
	local font = dialog_ask_font or gfx.newFont(72)
	dialog_ask_font = font
	local text = "?"
	local tw, th = font:getWidth(text), font:getHeight(text)
	local of = gfx.getFont()
	gfx.setFont(font)
	gfx.print(text, 64-(tw/2), 64-(th/2))
	gfx.setFont(of)
end

function images.dialog_err(self)
	gfx.circle("line", 64, 64, 56)
	local lw = gfx.getLineWidth()
	gfx.setLineWidth(16)
	gfx.line(32, 32, 96, 96)
	gfx.line(32, 96, 96, 32)
	gfx.setLineWidth(lw)
end

-- Aliases.
images.dialog_information = images.dialog_info
images.dialog_warning = images.dialog_warn
images.dialog_question = images.dialog_ask
images.dialog_query = images.dialog_ask
images.dialog_error = images.dialog_err

local function make_image()
	local img = Drawable()
	img.tint = gui_core.get_color(255, 255, 255)
	function img:draw(x, y, w, h)
		local r, g, b, a = gfx.getColor()
		local lw = gfx.getLineWidth()
		gfx.push()
		gfx.translate(x, y)
		gfx.scale(w/128, h/128)
		local tr, tg, tb = self.tint:unpack()
		gfx.setColor(tr, tg, tb)
		gfx.setLineWidth(3)
		self:do_draw()
		gfx.setColor(r, g, b, a)
		gfx.setLineWidth(lw)
		gfx.pop()
	end
	function img:get_size()
		return 128, 128
	end
	return img
end

function Theme:get_image(name)
	local func = images[name]
	if func then
		local img = make_image()
		img.do_draw = func
		return img
	end
end

return m
