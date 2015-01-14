
local classes = require "klib.classes"

local m = classes.module "apps.loveirc.commands"

m.commands = { }

m.commands.help = {
	desc = "Get help on a command, or a list of commands.",
	params = "[<command>]",
	func = function(window, tab, args)
		local cmd = args:match("^%S+")
		if cmd then
			local cmddef = m.commands[cmd]
			if cmddef then
				tab:print("/"..cmd
						..(cmddef.params and (" "..cmddef.params) or ""))
				tab:print(cmddef.desc)
			else
				tab:print("No such command: "..cmd)
			end
		else
			local t = { }
			for k, v in pairs(m.commands) do
				table.insert(t, { k, v })
			end
			table.sort(t)
			for _, info in ipairs(t) do
				tab:print("/"..info[1].." - "..info[2].desc)
			end
		end
	end,
}

m.commands.join = {
	desc = "Join a channel.",
	params = "<channel>",
	func = function(window, tab, args)
		local chan = args:match("^%S+")
		if not chan then
			tab:print("Specify a channel.")
			return
		end
		window.irc:join(chan)
	end,
}

m.commands.part = {
	desc = "Part a channel.",
	params = "[<channel> [<reason>]]",
	func = function(window, tab, args)
		local chan, rsn = args:match("^(%S+)%s*(.*)")
		if not chan then
			chan = window.active_tab and window.active_tab.channel
			if chan:sub(1, 1) == "(" then
				tab:print("This does not work on special channels.")
				return
			end
		end
		if rsn == "" then rsn = nil end
		window.irc:part(chan, rsn)
	end,
}

m.commands.msg = {
	desc = "Send a message to a channel or user.",
	params = "<channel-or-user> <message>",
	func = function(window, tab, args)
		local chan, msg = args:match("^(%S+)%s*(.*)")
		if not chan then
			tab:print("Try `/help msg` for usage info.")
		end
		window.irc:sendChat(chan, msg)
	end,
}

return m
