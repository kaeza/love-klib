
local classes = require "klib.classes"

local gui_core = require "klib.gui.core"

local Object = classes.Object

local Composite = require("klib.gui.composite").Composite
local ScrollBar = require("klib.gui.scrollbar").ScrollBar
local Label = require("klib.gui.widget").Label
--local TextMixin = require("klib.gui.mixins").TextMixin

local math_max, math_min = math.max, math.min

local m = classes.module "klib.gui.listbox"

local ListBoxItem = classes.class(m, "ListBoxItem")

-- Public fields.
ListBoxItem.listbox = nil

function ListBoxItem:get_size()
	return 1, 1
end

function ListBoxItem:paint(x, y, w, h, selected, fg, bg)
end

local SimpleListBoxItem = classes.class(m, "SimpleListBoxItem", ListBoxItem)

function SimpleListBoxItem:init(text)
	classes.check_types(2, 1, "s", text)
	ListBoxItem.init(self)
	self.text = text
end

function SimpleListBoxItem:paint(x, y, w, h, selected, fg, bg)
	local theme = gui_core.get_default_theme()
end

function SimpleListBoxItem:get_size()
	return gui_utils.text_size(self.text or "")
end

local ListBox = classes.class(m, "ListBox", Composite)

-- Public fields.
ListBox.selection_type = "single"
ListBox.selection_start = nil
ListBox.selection_end = nil

-- Private fields.
local p_clicked = { }
local p_scrollbar = { }

function ListBox:init()
	self.items = { }
	local sb = ScrollBar(1, 0, 1, "tb")
	local lb = self
	function sb:on_value_change(val)
		lb.view_offset = val
	end
	self.view_offset = 0
	self[p_scrollbar] = sb
	Composite.init(self, { sb })
end

function ListBox:insert(pos, item)
	if not item then
		item, pos = pos, #self.items+1
	end
	table.insert(self.items, pos, item)
	self:layout_items()
end

function ListBox:remove(pos)
	table.remove(self.items, pos)
	self:layout_items()
end

function ListBox:clear()
	self.items = { }
	self:layout_items()
end

function ListBox:sort(func)
	table.sort(self.items, func)
end

function ListBox:layout_items()
	local viewsize = 0
	local items = self.items
	local font = self:get_theme():get_font()
	local y, h = 0, self.h
	for index = (self.view_offset or 0) + 1, #items do
		local item = items[index]
		local lh = font:getHeight(item)
		if y >= (h-lh) then break end
		viewsize = viewsize + 1
		y = y + lh
	end
	local sb = self[p_scrollbar]
	sb:set_value(self.view_offset or 0, #items, viewsize)
	local sbw, sbh = sb:get_min_size()
	sb:reshape(self.w-sbw, 0, sbw, self.h)
end

function ListBox:find_item(pattern, is_regex)
	for pos, item in ipairs(self.items) do
		local s, e = tostring(item):find(pattern, 1, not is_regex)
		if s then
			return pos, item, s, e
		end
	end
end

function ListBox:find_items_iter(pattern, is_regex)
	local yield = coroutine.yield
	return coroutine.wrap(function()
		for pos, item in ipairs(self.items) do
			local s, e = tostring(item):find(pattern, 1, not is_regex)
			if s then
				yield(pos, item, s, e)
			end
		end
	end)
end

function ListBox:on_mouse_press(x, y, btn)
	Composite.on_mouse_press(self, x, y, btn)
	if (btn == "l") and (self:hit_test(x, y) == self) then
		local sx, sy = self:get_rect()
		self[p_clicked] = true
		local ss = self:pos_to_index(x-sx, y-sy)
		if ss then
			self:select(ss, ss)
		end
	end
end

function ListBox:on_mouse_release(x, y, btn, click_count)
	Composite.on_mouse_release(self, x, y, btn, click_count)
	if (btn == "l") and (self:hit_test(x, y) == self) then
		if (click_count == 2) and self.selection_start then
			self:on_selection_activate(self.selection_start,
					self.selection_end or self.selection_start)
		end
	end
	self[p_clicked] = false
end

function ListBox:on_mouse_move(x, y)
	Composite.on_mouse_move(self, x, y)
	if self[p_clicked] and self.got_mouse then
		local sx, sy = self:get_rect()
		local ss, se
		if self.selection_type == "single" then
			ss = self:pos_to_index(x-sx, y-sy)
			se = ss
		elseif self.selection_type == "multi" then
			ss = self.selection_start
			se = self:pos_to_index(x-sx, y-sy)
		end
		if ss and se then
			self:select(ss, se)
		end
	end
end

function ListBox:calc_min_size()
	local items = self.items
	local font = self:get_font()
	local maxw, maxh = 0, 0
	for index = 1, math_min(10, #items) do
		local item = items[index]
		local iw, ih = font:getWidth(item), font:getHeight(item)
		maxw = math_max(maxw, iw)
		maxh = maxh + ih
	end
	local ml, mt, mr, mb = self:get_margins()
	local sbw, sbh = self[p_scrollbar]:get_min_size()
	return maxw+ml+mr+sbw, math_max(maxh, sbh)+mt+mb
end

function ListBox:pos_to_index(x, y)
	local items = self.items
	local font = self:get_theme():get_font()
	for index = (self.view_offset or 0) + 1, #items do
		local item = items[index]
		local lh = font:getHeight(item)
		if y < lh then
			return index
		end
		y = y - lh
	end
end

function ListBox:index_to_pos(index)
	-- TODO: This is a stub
	return 0, 0
end

function ListBox:find_item(text)
	for i, item in ipairs(self.items) do
		if item == text then
			return i
		end
	end
end

function ListBox:select(ss, se, event)
	if event == nil then event = true end
	if type(ss) == "string" then ss = self:find_item(ss) end
	if self.selection_mode == "single" then
		se = ss
	elseif type(se) == "string" then
		se = self:find_item(se)
	end
	if event and ((self.selection_start ~= ss) or (self.selection_end ~= se)) then
		local nss, nse = self:on_selection_change(ss, se)
		self.selection_start = nss or ss
		self.selection_end = nse or se
	end
end

function ListBox:on_selection_change(ss, se)
end

function ListBox:on_selection_activate(ss, se)
end

return m
