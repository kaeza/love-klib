
local classes = require "klib.classes"

local Compound = require("klib.gui.compound").Compound
local Button = require("klib.gui.button").Button

local math_max, math_min = math.max, math.min

local m = classes.module "klib.gui.listbox"

local ScrollBar = classes.class(m, "ScrollBar", Compound)

-- Private fields.
local p_tl_button = { }
local p_br_button = { }
local p_handle = { }
local p_drag_start = { }

local function ScrollBar_button_activate(btn)
	local p = btn.parent
	p:set_value(p.val + btn.val)
end

local function create_sb_button(val, text)
	local b = Button(text)
	function b:calc_min_size()
		return 1, 1
	end
	b.val = val
	b.on_activate = ScrollBar_button_activate
	return b
end

function ScrollBar:init(max, val, viewsize, direction)
	max, val, viewsize = max or 1, val or 0, viewsize or 1
	self.max, self.val = max, val
	self.viewsize = viewsize
	direction = direction or "tb"
	self.direction = direction
	local v = (direction == "tb") or (direction == "bt")
	local tlb = create_sb_button(-1, "-")
	local brb = create_sb_button(1, "+")
	local hnd = Button("")
	local sb = self
	function hnd:on_mouse_press(x, y, btn)
		Button.on_mouse_press(self, x, y, btn)
		if btn == "l" then
			sb[p_drag_start] = { x-self.x, y-self.y }
		end
	end
	function hnd:on_mouse_move(x, y, btn)
		Button.on_mouse_move(self, x, y, btn)
		if sb[p_drag_start] then
			local pw, ph = sb.w, sb.h
			local minsize = math_min(pw, ph)
			local sx, sy = unpack(sb[p_drag_start])
			local dir = (sb.direction or (pw >= ph) and "lr" or "tb")
			local val
			local view = sb.max - sb.viewsize
			if (dir == "tb") or (dir == "bt") then
				local railh = ph-(minsize*2)-self.h
				local ty = math_max(minsize,
						math_min((y - sy), minsize+railh))
				val = (ty-minsize)/railh*view
			else
				local railw = pw-(minsize*2)-self.w
				local tx = math_max(minsize,
						math_min((x - sx), minsize+railw))
				val = (tx-minsize)/railw*view
			end
			sb:set_value(math.floor(val+0.5)) -- Round
		end
	end
	function hnd:on_mouse_release(x, y, btn)
		Button.on_mouse_release(self, x, y, btn)
		if (btn == "l") and sb[p_drag_start] then
			sb[p_drag_start] = nil
		end
	end
	function hnd:calc_min_size()
		return 1, 1
	end
	self[p_tl_button] = tlb
	self[p_br_button] = brb
	self[p_handle] = hnd
	Compound.init(self, { tlb, brb, hnd })
end

function ScrollBar:layout_items()
	local w, h = self.w, self.h
	local dir = self.direction or (w >= h) and "lr" or "tb"
	local max, val, viewsize = self.max, self.val, self.viewsize
	local lbx, lby, rbx, rby
	local rx, ry, rw, rh
	local hx, hy, hw, hh
	local minsize = math_min(w, h)
	self[p_handle].visible = viewsize < max
	if (dir == "tb") or (dir == "bt") then
		lbx, lby = 0, 0
		rbx, rby = 0, h-minsize
		local rh = h - (minsize * 2)
		hw, hh = w, math_max(minsize, (rh / max * viewsize))
		hx, hy = 0, minsize+(rh / max * val)
	elseif (dir == "lr") or (dir == "rl") then
		lbx, lby = 0, 0
		rbx, rby = w-minsize, 0
		local rw = w - (minsize * 2)
		hw, hh = math_max(minsize, (rw / max * viewsize)), h
		hx, hy = minsize+(rw / max * val), 0
	end
	self[p_tl_button].enabled = (viewsize < max) and (val > 0)
	self[p_br_button].enabled = (viewsize < max) and (val < (max - viewsize))
	self[p_tl_button]:reshape(lbx, lby, minsize, minsize)
	self[p_br_button]:reshape(rbx, rby, minsize, minsize)
	self[p_handle]:reshape(hx, hy, hw, hh)
end

local function handle_move_to_value(handle, value)
	local pw, ph = handle.parent.w, handle.parent.h
	local minsize = math_min(pw, ph)
	local view = handle.parent.max - handle.parent.viewsize
	local tx, ty
	local dir = (handle.parent.direction or (pw >= ph) and "lr" or "tb")
	value = math_max(0, math_min(value, view))
	if (dir == "tb") or (dir == "bt") then
		local railh = ph-(minsize*2)-handle.h
		tx = handle.x
		ty = minsize + value * railh/view
	else
		--local rw = w - (minsize * 2)
		--hw, hh = math_max(minsize, (rw / max * viewsize)), h
		--hx, hy = minsize+(rw / max * val), 0
		local railw = pw-(minsize*2)--handle.w
		tx = minsize + value * railw/view
		ty = handle.y
	end
	handle:move(tx, ty)
end

function ScrollBar:set_value(val, max, viewsize)
	classes.check_types(2, "n?n?n?", val, max, viewsize)
	if max then self.max = max end
	if viewsize then self.viewsize = viewsize end
	if val then
		val = math.floor(val)
		val = math_max(0, math_min(val, self.max-self.viewsize))
		if self.val ~= val then
			self:on_value_change(val, self.val)
		end
		self.val = val
		handle_move_to_value(self[p_handle], val)
	end
	if val or max or viewsize then
		self:layout_items()
	end
	self[p_tl_button].enabled = ((self.viewsize < self.max)
			and (self.val > 0))
	self[p_br_button].enabled = ((self.viewsize < self.max)
			and (self.val < (self.max - self.viewsize)))
end

local MINSIZE = 12
function ScrollBar:calc_min_size()
	local dir = self.direction or "tb"
	if (dir == "tb") or (dir == "bt") then
		return MINSIZE, MINSIZE*3
	else
		return MINSIZE*3, MINSIZE
	end
end

return m
