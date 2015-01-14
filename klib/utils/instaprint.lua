
local m = { _NAME = "klib.utils.instaprint" }

local old_print, io_flush = print, io.flush
function m.print(...)
	old_print(...)
	io_flush()
end

function m.install(env)
	env.print = m.print
end

return m
