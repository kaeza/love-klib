
local m = { _NAME = "klib.debug" }

m.warn_mode = "warn"

local warn_handlers = { }

function warn_handlers.warning(log, ...)
	log:print("WARNING:", ...)
end
warn_handlers.warn = warn_handlers.warning
warn_handlers.w = warn_handlers.warning

function warn_handlers.error(log, ...)
	local ac, av = select("#", ...), { ... }
	local t, i = { }, 1
	while i <= av do
		i = i + 1
	end
	error()
end
warn_handlers.err = warn_handlers.error
warn_handlers.e = warn_handlers.error

local log_meta = {
	print = function(self, ...)
		assert(self.file, "File is closed")
		local ac, av = select("#", ...), { ... }
		local tstamp = os.date("%y-%m-%d %H:%M:%S")
		self.file:write(tstamp..":")
		for i = 1, ac do
			self.file:write(" "..tostring(av[i]))
		end
		self.file:write("\n")
		self.file:flush()
	end,
	printf = function(self, fmt, ...)
		self:print(fmt:format(...))
	end,
	trace = function(self, ...)
		local info = debug.getinfo(2)
		local file, line = info.short_src, info.currentline
		self:print(file..":"..line..":", ...)
	end,
	tracef = function(self, fmt, ...)
		self:trace(fmt:format(...))
	end,
	warn = function(self, ...)
		local handler = warn_handlers[m.warn_mode]
		if handler then
			handler(self, ...)
		end
	end,
	warnf = function(self, fmt, ...)
		self:warn(fmt:format(...))
	end,
	deprecated = function(self, level, funcname, replacement)
		local info = debug.getinfo((level or 1) + 1)
		local file, line = info.short_src, info.currentline
		local key = file.."\0"..line
		local list = self.deprecated_locs
		if not list then
			list = { }
			self.deprecated_locs = list
		end
		if list[key] then
			return
		end
		list[key] = true
		self:warnf("call to deprecated function %s at %s:%d;"
				.." please use %s in the future",
				funcname, file, line, replacement)
	end,
	close = function(self)
		self:print("=== LOG SESSION END ===")
		self.file:close()
		self.file = nil
	end,
}
log_meta.__index = log_meta

function m.openlog(appname)
	local file, close
	if appname then
		local f, e = io.open(appname..".log", "w")
		if not f then
			return nil, e
		end
		file = f
	else
		file = io.stderr --HERE
		close = function(self)
			self.file = nil
		end
	end
	file = setmetatable({ file = file, close = close }, log_meta)
	file:print("=== LOG SESSION BEGIN ===")
	return file
end

local stderr_log

local gfuncs = {
	"print", "printf", "trace", "tracef",
	"warn", "warnf", "deprecated",
}

for _, k in ipairs(gfuncs) do
	m[k] = function(...)
		if not stderr_log then
			stderr_log = m.openlog()
		end
		return stderr_log[k](stderr_log, ...)
	end
end

function m.install()
	for _, k in ipairs(gfuncs) do
		_G[k] = m[k]
	end
end

return m
