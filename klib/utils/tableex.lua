
local classes = require "klib.classes"

local m = classes.module "klib.utils.tableex"

local table_remove = table.remove

function m.pop(t, i)
	i = i or #t
	local r = t[i]
	table_remove(t, i)
	return r
end

m.push = table.insert

function m.clear(t, i)
	for n = #t, (i or 1), -1 do
		t[n] = nil
	end
end

function m.extend(t1, t2)
	local i1, i2 = #t1, #t2
	while true do
		i2 = i2 + 1
		local v = t2[i2]
		if v == nil then break end
		i1 = i1 + 1
		t1[i1] = v
	end
	t1.n = i1
end

function m.test()
	local test = require "klib.utils.test"
	local ts = test.TestSuite()
	ts:add_test("push", function(log)
	end)
	ts:add_test("pop", function(log)
	end)
	ts:add_test("clear", function(log)
	end)
end

local gfuncs = { "push", "pop", "clear", "extend" }

function m.install(t)
	for _, k in ipairs(gfuncs) do
		t[k] = m[k]
	end
end

return m
