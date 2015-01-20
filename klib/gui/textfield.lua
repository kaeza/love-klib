
local classes = require "klib.classes"

local Widget = require("klib.gui.widget").Widget
local TextMixin = require("klib.gui.mixins").TextMixin

local clipboard = require "klib.gui.clipboard"

local m = classes.module "klib.gui.textfield"

local TextField = classes.class(m, "TextField", { Widget, TextMixin })

-- Public fields.
TextField.text = nil
TextField.password_char = nil
TextField.pos = nil
TextField.selection_start = nil
TextField.view_offset = nil
TextField.caret_x = nil
TextField.caret_y = nil
TextField.edit_cursor = love.mouse.getSystemCursor("ibeam")

function TextField:init(text)
	classes.check_types(2, 1, "s?", text)
	Widget.init(self)
	self.text = text or ""
	self.view_offset = 0
	self:select(self.text:len())
end

function TextField:get_preferred_size()
	local w, h = require("klib.gui.utils").text_size(self:get_font(), self.text)
	return w+h+2, h+2
end

function TextField:on_mouse_enter(x, y)
	Widget.on_mouse_enter(self, x, y)
	if self.enabled then
		love.mouse.setCursor(self.edit_cursor)
	end
end

function TextField:on_mouse_leave(x, y)
	Widget.on_mouse_leave(self, x, y)
	love.mouse.setCursor()
end

function TextField:on_mouse_press(x, y, btn)
	if (btn == "l") and (self:hit_test(x, y) == self) then
		local sx, sy = self:get_rect()
		self:select(self:pos_to_index(x - sx, y - sy))
		self.clicked = true
	end
	Widget.on_mouse_press(self, x, y, btn)
end

function TextField:on_mouse_release(x, y, btn)
	if btn == "l" then
		self.clicked = false
	end
	Widget.on_mouse_release(self, x, y, btn)
end

function TextField:on_mouse_move(x, y)
	if self.clicked and (self:hit_test(x, y) == self) then
		local sx, sy = self:get_rect()
		self:select(self.selection_start,
				self:pos_to_index(x - sx, y - sy))
	end
	Widget.on_mouse_move(self, x, y)
end

function TextField:set_selection_text(text)
	local ss, se = self.selection_start, self.pos
	ss, se = math.min(ss, se), math.max(ss, se)
	local oldtext = self.text or ""
	self.text = oldtext:sub(1, ss)..text..oldtext:sub(se+1)
	self:select(ss + text:len())
end

function TextField:select(ss, se)
	self.selection_start = ss
	self.pos = se or ss
	self.selection_start_x, self.selection_start_y =
			self:index_to_pos(self.selection_start)
	self.caret_x, self.caret_y =
			self:index_to_pos(self.pos)
end

function TextField:get_selection()
	local ss, se = self:get_selection_range()
	return self.text:sub(ss+1, se), ss, se
end

function TextField:get_selection_range()
	local ss, se = self.selection_start, self.pos
	return math.min(ss, se), math.max(ss, se)
end

function TextField:on_text_input(text)
	self:set_selection_text(text)
end

local function TextField_copy_selection(self)
	if not self.password_char then
		local text = self:get_selection()
		clipboard.set_data("text/plain", text)
	end
end

local function TextField_cut_selection(self)
	if not self.password_char then
		local text = self:get_selection()
		clipboard.set_data("text/plain", text)
		self:set_selection_text("")
	end
end

local function TextField_paste_clipboard(self)
	local text = clipboard.get_data("text/plain")
	if text then
		self:on_text_input(text)
	end
end

function TextField:on_key_press(key)
	local shift = (love.keyboard.isDown("lshift")
			or love.keyboard.isDown("rshift"))
	local ctrl = (love.keyboard.isDown("lctrl")
			or love.keyboard.isDown("rctrl"))
	if ctrl then
		if not shift then
			if (key == "c") or (key == "insert") then
				TextField_copy_selection(self)
			elseif key == "x" then
				TextField_cut_selection(self)
			elseif key == "v" then
				TextField_paste_clipboard(self)
			end
		end
	elseif shift and (not ctrl) and (key == "delete") then
		TextField_cut_selection(self)
	elseif shift and (not ctrl) and (key == "insert") then
		TextField_paste_clipboard(self)
	elseif not (shift and ctrl) and (key == "return") then
		self:on_commit(self.text)
	elseif key == "left" then
		local ss, se
		se = math.max(0, self.pos - 1)
		if not shift then
			ss = se
		end
		self:select(ss or self.selection_start, se)
	elseif key == "right" then
		local ss, se
		se = math.min(#self.text, self.pos + 1)
		if not shift then
			ss = se
		end
		self:select(ss or self.selection_start, se)
	elseif key == "delete" then
		local ss, se = self:get_selection_range()
		self:set_selection_text("")
		if (ss > 0) and (ss == se) then
			self.text = self.text:sub(1, ss)..self.text:sub(se+2)
		end
	elseif key == "backspace" then
		local ss, se = self:get_selection_range()
		self:set_selection_text("")
		if (ss > 0) and (ss == se) then
			self.text = self.text:sub(1, ss-1)..self.text:sub(se+1)
			self:select(self.pos - 1)
		end
	end
end

function TextField:pos_to_index(x, y)
	if (not self.text) or (x <= 0) then
		return 0
	end
	local font = self:get_font()
	local index = self.view_offset + 1
	local base = index
	local text = self.text
	text = self.password_char and self.password_char:rep(text:len()) or text
	local len = (text and text:len() or 0) - self.view_offset
	local last_w = 0
	while index <= len do
		local w = font:getWidth(text:sub(base, index))
		local d = (w - last_w)
		if (x - last_w) < (d / 2) then
			break
		end
		index = index + 1
		last_w = w
	end
	return index - 1
end

function TextField:index_to_pos(index)
	if not self.text then
		return 0, 0
	end
	local text = self.text
	text = self.password_char and self.password_char:rep(text:len()) or text
	local font = self:get_font()
	local base = self.view_offset+1
	local x = font:getWidth(text:sub(base, index))
	return x, 0
end

function TextField:calc_min_size()
	local font = self:get_font()
	local ml, mt, mr, mb = self:get_margins()
	return 96, font:getHeight("Ay") + mt + mb
end

function TextField:on_commit(text)
end

return m
