
local classes = require "klib.classes"

local gui_core = require "klib.gui.core"
local Desktop = require "klib.gui.desktop" . Desktop

local m = classes.module "klib.app"

local Application = classes.class(m, "Application")

Application.desktop = nil
Application.title = "untitled"

local function bind(func, self)
	return function(...)
		return func(self, ...)
	end
end

function Application:init(title, scale_x, scale_y)
	self.scale_x, self.scale_y = scale_x, scale_y
	self.title = title
	self.desktop = Desktop()
end

function Application:set_as_foreground()
	love.window.setTitle(self.title)
	love.update = bind(self.update, self)
	love.draw = bind(self.repaint, self)
	love.keypressed = bind(self.on_key_press, self)
	love.keyreleased = bind(self.on_key_release, self)
	love.textinput = bind(self.on_text_input, self)
	love.mousepressed = bind(self.on_mouse_press, self)
	love.mousereleased = bind(self.on_mouse_release, self)
	love.resize = bind(self.on_resize, self)
	self:on_resize(love.window.getWidth(), love.window.getHeight())
end

function Application:update(dtime)
	gui_core.caret_blink_timer = ((gui_core.caret_blink_timer + dtime)
			% gui_core.caret_blink_time)
	if self.desktop then
		self.desktop:update(dtime)
		local xs, ys = self.scale_x or 1, self.scale_y or 1
		local x, y = love.mouse.getPosition()
		return self.desktop:handle_mouse_move(x / xs, y / ys)
	end
end

function Application:repaint()
	self:paint_background()
	self:paint()
	self:paint_foreground()
end

function Application:paint_background()
end

function Application:paint_foreground()
end

function Application:paint()
	love.graphics.push()
	if self.scale_x then
		gui_core.set_scale(self.scale_x, self.scale_y)
		love.graphics.scale(self.scale_x, self.scale_y)
	end
	if self.desktop then
		self.desktop:repaint()
	end
	love.graphics.pop()
end

function Application:on_mouse_press(x, y, button)
	if self.desktop then
		local xs, ys = self.scale_x or 1, self.scale_y or 1
		self.desktop:handle_mouse_press(x / xs, y / ys, button)
	end
end

function Application:on_mouse_release(x, y, button)
	if self.desktop then
		local xs, ys = self.scale_x or 1, self.scale_y or 1
		self.desktop:handle_mouse_release(x / xs, y / ys, button)
	end
end

function Application:on_key_press(key)
	if self.desktop then
		self.desktop:handle_key_press(key)
	end
end

function Application:on_key_release(key)
	if self.desktop then
		self.desktop:handle_key_release(key)
	end
end

function Application:on_text_input(text)
	if self.desktop then
		self.desktop:handle_text_input(text)
	end
end

function Application:on_resize(w, h)
	if self.desktop then
		local xs, ys = self.scale_x or 1, self.scale_y or 1
		self.desktop:reshape(0, 0, w/xs, h/ys)
	end
end

return m
