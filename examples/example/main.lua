
package.path = "../../?/init.lua;../../?.lua;"..package.path

print = require("klib.utils.debug").trace

local classes = require "klib.classes"

local Application = require("klib.app").Application

local gui = require "klib.gui"

local function msgbox(wnd, message, title, buttons, icon, on_select)
	print(icon)
	local msg = gui.MessageDialog(title, message,
			buttons or "o", icon)
	msg.on_option_select = on_select
	wnd:get_root():insert(msg)
	wnd:add_child_window(msg)
	msg:center(wnd)
end

local tests = {
	{ "AboutDialog", function(wnd)
		local desk = wnd:get_root()
		local ad = gui.AboutDialog("About",
				require("klib.utils.version").about_info)
		desk:insert(ad)
		ad:center(wnd)
	end },
	{ "FileDialog", function(wnd)
		local desk = wnd:get_root()
		local msg = gui.FileDialog("FileDialog", "open")
		function msg:on_file_select(filename)
			msgbox(wnd, filename, "FileDialog")
		end
		--msg:resize_client(320, 240)
		desk:insert(msg)
		wnd:add_child_window(msg)
		msg:center(wnd)
	end },
	{ "MessageDialog", function(wnd)
		local desk = wnd:get_root()
		msgbox(wnd, "Hello, World!", "MessageDialog", "!oc", "dialog_err")
	end },
}

local TestWindow = classes.class("TestWindow", gui.Window)

function TestWindow:init()
	local wnd = self
	local buttons = { }
	for _, info in ipairs(tests) do
		local text, func = unpack(info)
		local b = gui.Button(text)
		function b:on_activate()
			func(wnd)
		end
		table.insert(buttons, b)
	end
	gui.Window.init(self, "Hello, World!", gui.VBox(buttons))
	--self:resize_client(400, 300)
end

local MyApp = classes.class("MyApp", Application)

MyApp.title = "Test App"

function MyApp:init()
	Application.init(self)
	local desk = self.desktop
	local win = TestWindow()
	local w, h = love.window.getWidth(), love.window.getHeight()
	local ww, wh = win:get_min_size()
	win:move((w-ww)/2, (h-wh)/2)
	desk:insert(win)
end

function MyApp:paint()
	love.graphics.print("Custom drawing!", 4, 4)
	Application.paint(self)
	love.graphics.print("Custom overlay!", 4, 36)
end

function love.load()
	local app = MyApp()
	app:set_as_foreground()
end
