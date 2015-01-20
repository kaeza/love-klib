
local classes = require "klib.classes"

local Compound = require("klib.gui.compound").Compound

local m = classes.module "klib.gui.container"

local Container = classes.class(m, "Container", Compound)

-- Private fields.
local p_id2child = { }

function Container:init()
	Compound.init(self, { })
end

function Container:insert(pos, widget)
	if widget == nil then
		widget, pos = pos, #self.children+1
	end
	if widget.parent then
		error("widget already has a parent", 2)
	end
	widget.parent = self
	table.insert(self.children, pos, widget)
	self:layout_items()
end

function Container:remove(widget)
	if widget.parent ~= self then
		error("widget is not a child of this container", 2)
	end
	local pos
	for i, v in ipairs(self.children) do
		if v == widget then
			pos = i
			v:on_remove()
			break
		end
	end
	widget.parent = nil
	table.remove(self.children, pos)
	self:layout_items()
end

function Container:remove_all()
	for _, child in ipairs(self.children) do
		child.parent = nil
	end
	self.children = { }
end

return m
