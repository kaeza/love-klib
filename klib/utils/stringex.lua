
local m = { _NAME = "klib.utils.stringex" }

function m.split_lines_iter(s)
	return coroutine.wrap(function()
		local s = m.normalize_lines(s)
		local pos, len = 1, #s
		local yield = coroutine.yield
		local count = 0
		while pos <= len do
			local npos = s:find("\n", pos, true)
			yield(s:sub(pos, npos and (npos-1)), count + 1, pos, npos and (npos-1))
			count = count + 1
			pos = (npos or len) + 1
		end
	end)
end

function m.split_lines(s)
	local t = { }
	for line in m.split_lines_iter(s) do
		table.insert(t, line)
	end
	return t
end

function m.split_iter(str, delim, include_empty, max_splits, sep_is_pattern)
	assert(str and type(str) == "string", type(str))
	local str_sub, str_find = str.sub, str.find
	delim = delim or ","
	max_splits = max_splits or -1
	local pos, len, seplen = 1, #str, #delim
	local plain = not sep_is_pattern
	max_splits = max_splits + 1
	local yield = coroutine.yield
	return coroutine.wrap(function()
		repeat
			local np, npe = str_find(str, delim, pos, plain)
			np, npe = (np or (len+1)), (npe or (len+1))
			if (not np) or (max_splits == 1) then
				np = len + 1
				npe = np
			end
			local s = str_sub(str, pos, np - 1)
			if include_empty or (s ~= "") then
				max_splits = max_splits - 1
				yield(s)
			end
			pos = npe + 1
		until (max_splits == 0) or (pos > (len + 1))
	end)
end

function m.split(str, delim, include_empty, max_splits, sep_is_pattern)
	local items, n = { }, 0
	for item in m.split_iter(str, delim, include_empty,
			max_splits, sep_is_pattern) do
		n = n + 1
		items[n] = item
	end
	return items
end

function m.normalize_lines(s)
	return (s:gsub("\r", "\n"):gsub("\r\n", "\n"):gsub("\r", "\n"))
end

function m.concatsep(sep, ...)
	local ac, av = select("#", ...), { ... }
	local t, i = { }, 1
	for i = 1, ac do
		local x = av[i]
		table.insert(t, (x ~= nil) and tostring(x) or "")
	end
	return table.concat(t, sep)
end

function m.concat(...)
	return m.concatsep("", ...)
end

function m.join(sep, t)
	return m.concatsep(sep, unpack(t))
end

m.splitlines = string.split_lines
m.splitlinesiter = string.split_lines_iter

function m.install(env)
	env = env or getfenv(2) or _G
	for _, e in ipairs({env, env.string}) do
		e.split_lines = m.split_lines
		e.split_lines_iter = m.split_lines_iter
		e.splitlines = m.split_lines
		e.splitlinesiter = m.split_lines_iter
		e.concatsep = m.concatsep
		e.concat = m.concat
		e.join = m.join
	end
	if env.string then
		local mt = getmetatable(env.string) or { }
		mt.__call = function(self, ...)
			return m.concatsep("", ...)
		end
		setmetatable(env.string, mt)
	end
end

local function test()
	m.install()
	print(string("a", "b"))
	print((", "):join{"foo", "bar"})
end
--os.exit(test())

return m
