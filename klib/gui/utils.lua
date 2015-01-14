
local classes = require "klib.classes"

local stringex = require "klib.utils.stringex"

local m = classes.module "klib.gui.utils"

function m.text_size(font, text, spacing)
	spacing = spacing or 0
	local maxw, maxh, max = 0, 0, math.max
	for line in stringex.split_lines_iter(text) do
		maxw = max(maxw, font:getWidth(line))
		maxh = maxh + font:getHeight(line) + spacing
	end
	return maxw, maxh - spacing
end

return m
