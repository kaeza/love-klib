
package.path = "../../?/init.lua;../../?.lua;"..package.path

print = require("klib.utils.debug").trace

local classes = require "klib.classes"

local Application = require("klib.app").Application

local gui = require "klib.gui"

local MainWindow = classes.class("MainWindow", gui.Window)

function MainWindow:init()
	local entry = gui.TextField("")
	local button = gui.Button("Send")
	entry.layout = { expand=true }
	local hbox = gui.HBox({ entry, button })
	local view = gui.ListBox()
	view.layout = { expand=true }
	local vbox = gui.VBox({ view, hbox })
	gui.Window.init(self, "Hello", vbox)
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
