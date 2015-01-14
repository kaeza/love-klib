
package.path = "../../?/init.lua;../../?.lua;"..package.path

print = require("klib.utils.debug").trace

local classes = require "klib.classes"

local Application = require("klib.app").Application

local gui = require "klib.gui"

local MainWindow = classes.class("MainWindow", gui.Window)

function MainWindow:init()
	gui.Window.init(self, "Hello", gui.Label("World!"))
end

local HelloApp = classes.class("HelloApp", Application)

HelloApp.title = "Hello, World! from KLib"

function HelloApp:init()
	Application.init(self)
	local wnd = MainWindow()
	self.desktop:insert(wnd)
end

function love.load(arg)
	HelloApp():set_as_foreground()
end
