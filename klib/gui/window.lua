
local classes = require "klib.classes"

local Widget = require("klib.gui.widget").Widget
local Label = require("klib.gui.label").Label
local Button = require("klib.gui.button").Button
local Compound = require("klib.gui.compound").Compound
local TextMixin = require("klib.gui.mixins").TextMixin

local gui_utils = require("klib.gui.utils")

local math_max, math_min = math.max, math.min

local m = classes.module "klib.gui.window"

local Window = classes.class(m, "Window", { Compound, TextMixin })

-- Public fields.
Window.resizable = true
Window.has_help = false
Window.titlebar_height = 20
Window.titlebar_spacing = 4
Window.cursors = {
	move = love.mouse.getSystemCursor("sizeall"),
	resize = love.mouse.getSystemCursor("sizenwse"),
	resize_x = love.mouse.getSystemCursor("sizewe"),
	resize_y = love.mouse.getSystemCursor("sizens"),
}

-- Private fields.
local p_childwindows = { }
local p_enabledbeforemodal = { }
local p_buttons = { }
local p_drag_action, p_drag_x, p_drag_y = { }, { }, { }
local p_drag_orig_w, p_drag_orig_h = { }, { }
local p_restored_rect = { }

-- 'MAXIMIZE' (U+1F5D6)
--local MAXIMIZE_CHAR = string.char(0xF0, 0x9F, 0x97, 0x96)
local MAXIMIZE_CHAR = "[]"

-- 'MINIMIZE' (U+1F5D5)
--local MINIMIZE_CHAR = string.char(0xF0, 0x9F, 0x97, 0x95)
local MINIMIZE_CHAR = "_"

-- 'CANCELLATION X' (U+1F5D9)
--local CLOSE_CHAR = string.char(0xF0, 0x9F, 0x97, 0x99)
local CLOSE_CHAR = "X"

local HELP_CHAR = "?"

-- 'FOLDER' (U+1F5C0)
local FOLDER_ICON = string.char(0xF0, 0x9F, 0x97, 0x80)

-- 'OPEN FOLDER' (U+1F5C1)
local OPEN_FOLDER_ICON = string.char(0xF0, 0x9F, 0x97, 0x81)

local function create_button(iconname, text, on_activate)
	local graphics = require "klib.gui.graphics"
	local b = Button("")
	local theme = b:get_theme()
	--local ok, image = pcall(graphics.Image, "themes/"..theme.id.."/"..iconname)
	local ok, image = pcall(theme.get_image, theme, iconname)
	if ok and image then
		function b:paint()
			local x, y, w, h = self:get_rect()
			Button.paint(self)
			if self.pressed and self.got_mouse then
				x, y = x + 1, y + 1
			end
			image:draw(x+4, y+4, w-8, h-8)
		end
	else
		b.text = text
	end
	b.on_activate = on_activate
	return b
end

function Window:init(text, client)
	classes.check_types(2, 1, "s", text)
	if not (client and classes.isinstance(client, Widget)) then
		error("client must be an instance of "..Widget.__name, 2)
	end
	create_button("asdf")
	self.text = text
	self.client = client
	local wnd = self
	local bclose = create_button("window_close", CLOSE_CHAR, function()
		wnd:close()
	end)
	local bmax = create_button("window_max", MAXIMIZE_CHAR, function()
		wnd:maximize()
	end)
	local bmin = create_button("window_min", MINIMIZE_CHAR, function()
		wnd:minimize()
	end)
	local bhelp = create_button("window_help", HELP_CHAR, function()
		wnd:on_help()
	end)
	self[p_buttons] = { bclose, bmax, bmin, bhelp }
	self.state = "res"
	self[p_childwindows] = {}
	Compound.init(self, { client, bclose, bmax, bmin, bhelp })
	self:set_margins(4, 4, 4, 4)
	self:resize_client(client:get_min_size())
end

function Window:update(dtime)
	Compound.update(self, dtime)
	self[p_buttons][2].visible = self.resizable
	self[p_buttons][3].visible = self.resizable
	self[p_buttons][4].visible = self.has_help
end

function Window:layout_items()
	self[p_buttons][2].visible = self.resizable
	self[p_buttons][3].visible = self.resizable
	self[p_buttons][4].visible = self.has_help
	local tbh, tbs = self.titlebar_height, self.titlebar_spacing
	local ml, mt, mr, mb = self:get_margins()
	local hm, vm = ml + mr, mt + mb
	local w, h = self.w, self.h
	self.client:reshape(ml, mt+tbh+tbs, w-hm, h-tbh-tbs-vm)
	local x = tbh
	for i, b in ipairs(self[p_buttons]) do
		if b.visible then
			b:reshape(w-mr-x, mt, tbh, tbh)
			x = x + tbh
		end
	end
end

local function Window_subhit(self, x, y)
	if self:hit_test(x, y) ~= self then
		return
	end
	local sx, sy, w, h = self:get_rect()
	local ml, mt, mr, mb = self:get_margins()
	x, y = x - sx, y - sy
	local tbh = self.titlebar_height
	if (x >= ml) and (y >= mt) and (x < w-mr) and (y < mt+tbh) then
		return "move"
	elseif (x >= w-mr) and (y >= h-mb) and (x <= w) and (y <= h) then
		return "resize"
	elseif (y >= h-mb) and (y <= h) then
		return "resize_y"
	elseif (x >= w-mr) and (x <= w) then
		return "resize_x"
	end
end

function Window:on_mouse_press(x, y, btn, click_count)
	Compound.on_mouse_press(self, x, y, btn, click_count)
	if btn == "l" then
		local sx, sy, w, h = self:get_rect()
		local tbh = self.titlebar_height
		local action = Window_subhit(self, x, y)
		if action == "move" then
			if click_count == 1 then
				if self.state == "min" then
					self:minimize()
					return
				elseif self.resizable then
					self:maximize()
					return
				end
			elseif self.state == "max" then
				action = nil
			end
		else
			if (self.state == "max") or (not self.resizable) then
				action = nil
			end
		end
		self[p_drag_action] = action
		self[p_drag_x], self[p_drag_y] = x, y
		self[p_drag_orig_w], self[p_drag_orig_h] = w, h
	end
end

function Window:on_mouse_release(x, y, btn, click_count)
	Compound.on_mouse_release(self, x, y, btn, click_count)
	if btn == "l" then
		self[p_drag_x], self[p_drag_y] = nil
		self[p_drag_action] = nil
		love.mouse.setCursor()
	end
end

function Window:on_mouse_leave()
	Compound.on_mouse_leave(self)
	love.mouse.setCursor()
end

function Window:on_mouse_move(x, y)
	Compound.on_mouse_move(self, x, y)
	if (not self[p_drag_action]) or (self.state == "max") then
		local action = Window_subhit(self, x, y)
		if action == "move" or (not self.resizable) then
			action = nil
		end
		love.mouse.setCursor(action and self.cursors[action])
		return
	end
	love.mouse.setCursor(self.cursors[self[p_drag_action]])
	if self[p_drag_action] == "move" then
		self:move(self.x + x - self[p_drag_x], self.y + y - self[p_drag_y])
		self[p_drag_x], self[p_drag_y] = x, y
	elseif (self.state ~= "min") and self[p_drag_action]:match("^resize") then
		local dx, dy = x - self[p_drag_x], y - self[p_drag_y]
		local neww = self[p_drag_orig_w] + dx
		local newh = self[p_drag_orig_h] + dy
		self[p_drag_orig_w], self[p_drag_orig_h] = neww, newh
		-- --[[
		local minw, minh = self:get_min_size()
		local maxw, maxh = self:get_max_size()
		neww = math_min(maxw, math_max(neww, minw))
		newh = math_min(maxh, math_max(newh, minh))
		--]]
		if self[p_drag_action] == "resize_x" then
			newh = self.h
		elseif self[p_drag_action] == "resize_y" then
			neww = self.w
		end
		self:resize(neww, newh)
		--self[p_drag_orig_w], self[p_drag_orig_h] = neww, newh
		self[p_drag_x], self[p_drag_y] = x, y
	end
end

function Window:maximize(force)
	if force or (self.state ~= "max") then
		if not self[p_restored_rect] then
			self[p_restored_rect] = { self:get_rect_rel() }
		end
		self.state = "max"
		local maxw, maxh = self:get_max_size()
		self:reshape(0, 0, maxw, maxh)
		self:layout_items()
	elseif self[p_restored_rect] then
		self:reshape(unpack(self[p_restored_rect]))
		self:layout_items()
		self[p_restored_rect] = nil
		self.state = "res"
	end
	self.client.visible = true
end

function Window:minimize(force)
	if force or (self.state ~= "min") then
		if not self[p_restored_rect] then
			self[p_restored_rect] = { self:get_rect_rel() }
		end
		local p = self.parent
		self.state = "min"
		local minw, minh = self:get_min_size()
		minh = self.titlebar_height + self.margin_top + self.margin_bottom
		self:reshape(0, p.h-minh, minw, minh)
	elseif self[p_restored_rect] then
		self.state = "res"
		self:reshape(unpack(self[p_restored_rect]))
		self[p_restored_rect] = nil
	end
	self.client.visible = self.state ~= "min"
end

function Window:close(force)
	if self.closed then return end
	if #self[p_childwindows] > 0 then
		if force then
			for _, win in ipairs(self[p_childwindows]) do
				win:close(true)
			end
		else
			return
		end
	end
	local r = self:on_before_close(force)
	if force or (not r) then
		self.hidden = true
		self.closed = true
		self:on_close()
		if self.parent then
			self.parent:remove(self)
		end
	end
end

function Window:add_child_window(window)
	if window and (not classes.isinstance(window, Window)) then
		error("window must be a subclass of "..Window.__name, 2)
	end
	if #self[p_childwindows] == 0 then
		self[p_enabledbeforemodal] = self.enabled
	end
	table.insert(self[p_childwindows], window)
	self.enabled = false
	local wnd = self
	local old_on_close = window.on_close
	function window:on_close()
		wnd:remove_child_window(self)
		old_on_close(window)
	end
end

function Window:remove_child_window(window)
	for i, w in ipairs(self[p_childwindows]) do
		if w == window then
			table.remove(self[p_childwindows], i)
			if #self[p_childwindows] == 0 then
				self.enabled = self[p_enabledbeforemodal]
			end
			return
		end
	end
end

function Window:raise()
	local p = self.parent
	for i, w in ipairs(p.children) do
		if w == self then
			table.remove(p.children, i)
			table.insert(p.children, self)
			break
		end
	end
	for _, win in ipairs(self[p_childwindows]) do
		win:raise()
	end
end

function Window:calc_min_size()
	local ml, mt, mr, mb = self:get_margins()
	local cw, ch = self.client:get_min_size()
	local spc = self.titlebar_spacing
	return math_max(120, (self.titlebar_height*4) + ml + mr + cw),
			self.titlebar_height + mt + mb + math_max(spc + ch, 0)
end

function Window:on_key_press(key)
	if self.closed then return end
	local ctrl = (love.keyboard.isDown("lctrl")
			or love.keyboard.isDown("rctrl"))
	if (key == "w") and ctrl then
		self:close()
	end
end

function Window:resize_client(w, h)
	classes.check_types(2, 1, "nn", w, h)
	local minw, minh = self:get_min_size()
	local ml, mt, mr, mb = self:get_margins()
	local tbh, tbs = self.titlebar_height, self.titlebar_spacing
	self:resize(math_max(minw, w+ml+mr),
			math_max(minh, h+mt+tbh+tbs+mb))
end

function Window:center(widget)
	local wx, wy, ww, wh = widget:get_rect()
	local x, y, w, h = self:get_rect()
	x, y = wx-x, wy-y
	x, y = x+((ww-w)/2), y+((wh-h)/2)
	self:move(x, y)
end

function Window:on_before_close(force)
end

function Window:on_close()
end

function Window:on_remove()
	self:next(function() self:close(true) end)
end

return m
