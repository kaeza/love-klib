
local classes = require "klib.classes"

local Button = require("klib.gui.button").Button
local Composite = require("klib.gui.composite").Composite
local HBox = require("klib.gui.box").HBox

local m = classes.module "klib.gui.notebook"

local Notebook = classes.class(m, "Notebook", Composite)

-- Private fields.
local p_buttonbar = { }
local p_activepage = { }

function Notebook:init()
	local bb = HBox({ })
	self.pages = { }
	self[p_buttonbar] = bb
	Composite.init(self, { bb })
end

function Notebook:add_page(id, title, widget, visible)
	classes.check_types(2, 1, "sstb?", id, title, widget, visible)
	if not self:get_page(id) then
		if widget.parent then
			error("widget already has a parent", 2)
		end
		local b = Button(title)
		b.page_id = id
		local nbk = self
		function b:paint()
			Button.paint(self)
			if nbk[p_activepage]
					and (nbk[p_activepage].id ~= self.page_id) then
				local x, y, w, h = self:get_rect()
				love.graphics.setColor(0, 0, 0, 64)
				love.graphics.rectangle("fill", x, y, w, h)
			end
		end
		function b:on_activate()
			nbk:show_page(id)
		end
		local page = {
			id = id,
			title = title,
			widget = widget,
			button = b,
		}
		if visible == nil then
			visible = true
		end
		b.visible = visible
		widget.parent = self
		b.parent = self[p_buttonbar]
		table.insert(self[p_buttonbar].children, b)
		self[p_buttonbar]:layout_items()
		table.insert(self.pages, page)
		widget.visible = false
		if not self[p_activepage] then
			self:show_page(id)
		end
		self:layout_items()
	end
end

function Notebook:remove_page(id)
	for index, page in ipairs(self.pages) do
		if page.id == id then
			local cur_page = self[p_activepage]
			if cur_page and (cur_page.id == id) then
				self[p_activepage] = self.pages[index-1] or self.pages[index+1]
			end
			page.widget.parent = nil
			table.remove(self[p_buttonbar].children, index)
			table.remove(self.pages, index)
			return
		end
	end
end

function Notebook:get_page(id)
	for _, page in ipairs(self.pages) do
		if page.id == id then
			return page
		end
	end
end

function Notebook:show_page(id)
	local page = self:get_page(id)
	if page then
		local old_page = self[p_activepage]
		if old_page then
			old_page.widget.visible = false
		end
		page.widget.visible = true
		self[p_activepage] = page
		self.children[2] = page.widget
		self:layout_items()
	end
end

function Notebook:set_page(id, title, widget, visible)
	local page = self:get_page(id)
	if page then
		if visible ~= nil then
			page.button.visible = visible
		end
		if title then page.button.text = title end
		if widget and (page.widget ~= widget) then
			self:remove(page.widget)
			self:insert(widget)
			page.widget = widget
		end
	end
end

function Notebook:layout_items()
	local w, h = self.w, self.h
	self[p_buttonbar]:reshape(0, 0, w, 20)
	if self[p_activepage] then
		self[p_activepage].widget:reshape(0, 20, w, h-20)
	end
end

function Notebook:calc_min_size()
	local w, h = self[p_buttonbar]:get_min_size()
	if self[p_activepage] then
		local pw, ph = self[p_activepage].widget:get_min_size()
		w, h = w+pw, h+ph
	end
	return w, h
end

return m
