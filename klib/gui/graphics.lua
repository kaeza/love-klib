
local classes = require "klib.classes"

local gui_core = require "klib.gui.core"

local m = classes.module "klib.gui.graphics"

local Drawable = classes.class(m, "Drawable", classes.Object)

function Drawable:draw(x, y, w, h)
end

local Image = classes.class(m, "Image", Drawable)

function Image:init(image, tint)
	classes.Object.init(self)
	self.tint = tint or gui_core.get_color(255, 255, 255)
	if (type(image) == "string") or (io.type(image) == "file") then
		image = love.graphics.newImage(image)
	elseif not (image and image.typeOf and image:typeOf("Image")) then
		error("image must be a string, open file, or love.graphics.Image", 2)
	end
	self.image = image
	self.w, self.h = image:getDimensions()
end

function Image:draw(x, y, w, h)
	local iw, ih = self.w, self.h
	local q = love.graphics.newQuad(0, 0, iw, ih, iw, ih)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(self.tint:unpack())
	love.graphics.draw(self.image, q, x, y, 0, w/iw, h/ih)
	love.graphics.setColor(r, g, b, a)
end

return m
