
local classes = require "klib.classes"

local Container = require("klib.gui.container").Container
local Window = require("klib.gui.window").Window

local gui_core = require "klib.gui.core"

local m = classes.module "klib.gui.desktop"

local Desktop = classes.class(m, "Desktop", Container)

Desktop.CENTERED = "centered"
Desktop.STRETCHED = "stretched"
Desktop.STRETCHED_X = "stretched_x"
Desktop.STRETCHED_Y = "stretched_y"

Desktop.bg_image_mode = Desktop.CENTERED

-- Private fields.
local p_dclick_timer = { }
local p_click_count = { }
local p_clicked_item = { }
local p_pointed_item = { }
local p_focused_item = { }

function Desktop:init()
	Container.init(self)
	self[p_dclick_timer] = 0
	self[p_click_count] = 0
	self[p_focused_item] = self
	self.focused = true
end

function Desktop:update(dtime)
	Container.update(self, dtime)
	if self[p_click_count] > 0 then
		self[p_dclick_timer] = self[p_dclick_timer] + dtime
		if self[p_dclick_timer] >= gui_core.dclick_timeout then
			self[p_click_count] = 0
			self[p_dclick_timer] = 0
		end
	end
end

function Desktop:layout_items(w, h)
	for _, item in ipairs(self.children) do
		if classes.is_instance(item, Window) then
			if item.state == "max" then
				item:maximize(true)
			elseif item.state == "min" then
				item:minimize(true)
			end
		end
	end
end

local function is_enabled(widget)
	if not widget.enabled then
		return false
	elseif not widget.parent then
		return widget.enabled
	end
	return is_enabled(widget.parent)
end

function Desktop:handle_mouse_press(x, y, button)
	local hit = self:hit_test(x, y)
	local curhit = self[p_clicked_item] or hit
	if hit and (hit == curhit) then
		local win = hit:get_parent_window(true)
		if win then
			win:raise()
		end
		if is_enabled(hit) then
			self[p_clicked_item] = hit
			if self[p_focused_item]
					and (not self[p_focused_item]:on_focus_change(false)) then
				self[p_focused_item].focused = false
				self[p_focused_item] = nil
			end
			if not hit:on_focus_change(false) then
				self[p_focused_item] = hit
				hit.focused = true
			end
			hit:on_mouse_press(x, y, button, self[p_click_count])
		end
	else
		self[p_focused_item] = nil
	end
end

function Desktop:handle_mouse_release(x, y, button)
	self[p_dclick_timer] = 0
	self[p_click_count] = self[p_click_count] + 1
	if self[p_clicked_item] then
		if is_enabled(self[p_clicked_item]) then
			self[p_clicked_item]:on_mouse_release(x, y,
					button, self[p_click_count])
		end
		self[p_clicked_item] = nil
	end
end

local last_mx, last_my
function Desktop:handle_mouse_move(x, y)
	if not last_mx then
		last_mx, last_my = x, y
	end
	if (last_mx == x) and (last_my == y) then
		return
	end
	if self[p_clicked_item] and is_enabled(self[p_clicked_item]) then
		self[p_clicked_item]:on_mouse_move(x, y)
	else
		local hit = self:hit_test(x, y)
		local pointed = self[p_pointed_item]
		if hit and pointed and (pointed ~= hit) then
			if is_enabled(pointed) then
				pointed:on_mouse_leave()
			end
			if is_enabled(hit) then
				hit:on_mouse_enter(x, y)
			end
		elseif hit and is_enabled(hit) then
			hit:on_mouse_move(x, y)
		end
		self[p_pointed_item] = hit
	end
	last_mx, last_my = x, y
end

function Desktop:handle_key_press(key)
	if self[p_focused_item] and is_enabled(self[p_focused_item]) then
		self[p_focused_item]:on_key_press(key)
	end
end

function Desktop:handle_key_release(key)
	if self[p_focused_item] and is_enabled(self[p_focused_item]) then
		self[p_focused_item]:on_key_release(key)
	end
end

function Desktop:handle_text_input(text)
	if self[p_focused_item] and is_enabled(self[p_focused_item]) then
		self[p_focused_item]:on_text_input(text)
	end
end

return m
