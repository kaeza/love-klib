
--[[
  | loveirc.lua
  | A simple IRC client using KLib GUI, luasocket, and LuaIRC.  
  |
  | This example is part of the KLib project.
  | See `LICENSE.txt` in the root of the source directory for details.  
--]]

package.path = "../../?/init.lua;../../?.lua;"..package.path

print = require("klib.utils.debug").trace

local classes = require "klib.classes"

local Application = require("klib.app").Application

local gui = require "klib.gui"
local commands = require "commands"
local irc = require "irc"

local MainWindow = classes.class("MainWindow", gui.Window)

local function is_channel(x)
	return (x:match("^[%#%&%+%!]") ~= nil)
end

local upper_to_lower = {
	["["] = "{", ["]"] = "}",
}

local function irc_name_lower(s)
	return s:lower():gsub("[%[%]]", upper_to_lower)
end

local function mk_lc_table()
	local mt = { }
	function mt:__index(k)
		local lk = (type(k) == "string") and irc_name_lower(k) or k
		return rawget(self, lk)
	end
	function mt:__newindex(k, v)
		local lk = (type(k) == "string") and irc_name_lower(k) or k
		local vv = rawget(self, lk)
		if not vv then
			table.insert(mt.keys, k)
		end
		rawset(self, lk, v)
	end
	function mt:__pairs()
		return coroutine.wrap(function()
			for k, v in pairs(mt.keys) do
				coroutine.yield(k, v)
			end
		end)
	end
end

local special_tabs = {
	["(dummy)"] = function(tab)
		tab:add_user("*asdf")
	end,
}

local function create_channel_tab(window, channel)
	lchan = irc_name_lower(channel)
	local tab
	local chatlist = gui.ListBox()
	local chatfield = gui.TextField("")
	local sendbtn = gui.Button("Send")
	local userlist = gui.ListBox()
	local function commit()
		local text = chatfield.text
		if text ~= "" then
			local cmd, args = text:match("^%/(%S+)%s*(.*)")
			if cmd and (cmd:sub(1, 1) ~= "/") then
				window:run_command(cmd, tab, args)
			else
				if text:sub(1, 1) == "/" then
					text = text:sub(2)
				end
				window:send_text(text)
			end
		end
		chatfield.text = ""
		chatfield:select(0)
	end
	chatfield.on_commit = commit
	sendbtn.on_activate = commit
	function userlist:on_selection_activate(ss)
		window:get_channel_tab(self.items[ss])
		window:show_channel_tab(self.items[ss])
	end
	tab = gui.Compound({ chatlist, chatfield, sendbtn, userlist })
	sendbtn:resize(sendbtn:get_preferred_size())
	function tab:layout_items()
		local w, h = self.w, self.h
		chatlist:reshape(0, 0, w-128, h-sendbtn.h)
		userlist:reshape(w-128, 0, 128, h-sendbtn.h)
		chatfield:reshape(0, h-sendbtn.h, w-sendbtn.w, sendbtn.h)
		sendbtn:move(w-sendbtn.w, h-sendbtn.h)
	end
	function tab:print(text)
		local split_lines_iter = require("klib.utils.stringex").split_lines_iter
		for line in split_lines_iter(text) do
			chatlist:insert(text)
		end
	end
	function tab:clear()
		chatlist:clear()
	end
	function tab:add_user(nickname)
		table.insert(self.users, {
			nickname = nickname,
		})
		self:refresh_user_list()
	end
	function tab:refresh_user_list()
		local l = userlist
		local text = l.selection_start and lower(l.items[l.selection_start])
		l:select()
		l:clear()
		local lower = irc_name_lower
		for name, user in pairs(window.irc.channels[self.channel].users) do
			print(name)
			l:insert(name)
		end
		l:sort(function(i1, i2)
			return lower(i1) <= lower(i2)
		end)
		l:select(text)
	end
	tab.users = { }
	tab.channel = channel
	tab.parent = window.client
	return tab
end

function MainWindow:init(address, port, nickname, username, realname)
	classes.check_types(2, 1, "sn?s?s?s?", address, port,
			nickname, username, realname)
	self.address = address
	self.port = port or 6667
	self.nickname = nickname or "loveirc"
	self.username = username or nickname
	self.realname = realname or username
	self.channel_tabs = { }
	local wnd = self
	local chanlist = gui.ListBox()
	self.channel_list = chanlist
	function chanlist:on_selection_change(ss)
		if not ss then return end
		wnd:show_channel(self.items[ss])
	end
	local client = gui.Compound({ chanlist })
	function client:layout_items()
		local w, h = self.w, self.h
		chanlist:reshape(0, 0, 128, h)
		if wnd.active_tab then
			wnd.active_tab:reshape(128, 0, w-128, h)
		end
	end
	client:set_min_size(512, 256)
	gui.Window.init(self, "LoveIRC", client)
	self:get_channel_tab("(dummy)"):print("Hello, world!")
	self.irc = irc.new({ nick=self.nickname })
	local function wrap(f)
		return function(...) return f(self, ...) end
	end
	self.irc:hook("OnChat", wrap(self.on_chat))
	self.irc:hook("OnNotice", wrap(self.on_notice))
	self.irc:hook("OnJoin", wrap(self.on_join))
	self.irc:hook("OnPart", wrap(self.on_part))
end

function MainWindow:on_chat(user, channel, message)
	channel = irc_name_lower(channel)
	local ctcp, params = message:match("^\1(%S+)%s*(.-)\1")
	if ctcp then
		self:on_ctcp_chat(user, channel, ctcp, params)
	else
		self:print(channel, "<"..user.nick.."> "..message)
	end
end

function MainWindow:on_ctcp_chat(user, channel, event, params)
	event = event:lower()
	if event == "action" then
		self:print(channel, "* "..user.nick.." "..params)
		return
	elseif not is_channel(channel) then
		if event == "version" then
			self.irc:sendNotice(user.nick, event
					.." LoveIRC 0.1.0 (".._VERSION..")")
		elseif event == "ping" then
			self.irc:sendNotice(user.nick, event.." "..params)
		end
	end
	self:print("Received CTCP "..event
			.." request from "..(user.nick or channel)..":")
	if params ~= "" then self:print(channel, params) end
end

function MainWindow:on_notice(user, channel, message)
	channel = channel and irc_name_lower(channel) or "(dummy)"
	local ctcp, params = message:match("^\1(%S+)%s*(.-)\1")
	if ctcp then
		self:on_ctcp_notice(user, channel, ctcp, params)
	else
		self:print(channel, "-"..(user.nick or channel).."- "..message)
	end
end

function MainWindow:on_ctcp_notice(user, channel, event, params)
	self:print("Received CTCP "..event:upprt()
		.." notice from "..(user.nick or channel)..":")
	if params ~= "" then self:print(channel, params) end
end

function MainWindow:on_join(user, channel)
	if user.nick == self.nickname then
		self:print(channel, "Now talking on "..channel..".")
		self:show_channel(channel)
		self:next(function()
			self:get_channel_tab(channel):refresh_user_list()
		end)
	else
		local tab = self:get_channel_tab(channel)
		tab:print("*** "..user.nick.." ("
				..(user.host or "").." joined.")
		tab:refresh_user_list()
	end
end

function MainWindow:on_part(user, channel)
	channel = irc_name_lower(channel)
	if user.nick == self.nickname then
		self:close_channel_tab(channel)
	else
		local tab = self:get_channel_tab(channel)
		tab:print("*** "..user.nick.." left.")
		tab:refresh_user_list()
	end
end

function MainWindow:update(dtime)
	gui.Window.update(self, dtime)
	if not self.irc then return end
	if not self.step then
		self:print("Connecting to "..self.address..":"..self.port.."...")
		self.step = 0
	elseif self.step == 0 then
		self.irc:connect(self.address, self.port)
		self:print("Connected!")
		self.irc:join("#test")
		self.step = 1
	else
		self.irc:think()
	end
end

function MainWindow:on_close()
	self.irc:disconnect()
	self.irc = nil
end

function MainWindow:send_text(channel, text)
	if not text then
		channel, text = (self.active_tab and self.active_tab.channel
				or "(dummy)"), channel
	end
	self:get_channel_tab(channel):print(("<%s> %s"):format(
			self.nickname, text))
	if channel:sub(1, 1) ~= "(" then
		self.irc:sendChat(channel, text)
	end
end

function MainWindow:run_command(cmd, tab, args)
	local cmddef = commands.commands[cmd]
	if cmddef then
		cmddef.func(self, tab, args)
	else
		tab:print("No such command: "..cmd)
	end
end

function MainWindow:print(channel, text)
	if not text then
		channel, text = (self.active_tab and self.active_tab.channel
				or "(dummy)"), channel
	end
	self:get_channel_tab(channel):print(text)
end

function MainWindow:show_channel(channel)
	channel = irc_name_lower(channel)
	local tab = self.channel_tabs[channel]
	if tab then
		self.channel_list:select(channel, nil, false)
		self.client.children[2] = tab
		self.active_tab = tab
		self:layout_items()
	end
end

function MainWindow:get_channel_tab(channel, create)
	local tab = self.channel_tabs[channel]
	if (not tab) and (create or (create == nil)) then
		tab = create_channel_tab(self, channel)
		local lchan = irc_name_lower(channel)
		self.channel_tabs[lchan] = tab
		table.insert(self.channel_tabs, tab)
		self:refresh_channel_list()
		if not self.active_tab then
			self:show_channel(channel)
		end
	end
	return tab
end

function MainWindow:close_channel_tab(channel)
	channel = irc_name_lower(channel)
	for i, tab in ipairs(self.channel_tabs) do
		local tabchan = irc_name_lower(tab.channel)
		if channel == tabchan then
			table.remove(self.channel_tabs, i)
			self.channel_tabs[channel] = nil
			self:refresh_channel_list()
			return
		end
	end
end

function MainWindow:refresh_channel_list()
	table.sort(self.channel_tabs, function(i1, i2)
		i1, i2 = i1.channel, i2.channel
		local ic1, ic2 = is_channel(i1), is_channel(i2)
		if ic1 then
			i1, i2 = irc_name_lower(i1), irc_name_lower(i2)
			return ic2 and (i1 <= i2)
		end
		return false
	end)
	local l = self.channel_list
	local text = l.items[l.selection_start or 1]
	l:select(nil, nil, false)
	l:clear()
	for i, tab in ipairs(self.channel_tabs) do
		l:insert(tab.channel)
		if tab.channel == text then
			l:select(i, nil, false)
		end
	end
end

local LoveIRCApp = classes.class("LoveIRCApp", Application)

function LoveIRCApp:init()
	Application.init(self)
	local mainwin = MainWindow("localhost")
	self.desktop:insert(mainwin)
end

LoveIRCApp.title = "LoveIRC"

function love.load(arg)
	LoveIRCApp():set_as_foreground()
end
