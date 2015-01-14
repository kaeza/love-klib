
local function module(name)
	name = assert(type(assert(name, "Name needed"))
			== "string" and name, "Name must be a string")
	return setmetatable({
		_NAME = name,
		__name = name,
	}, { __type = "module" })
end

local m = module "klib.classes"
m.classes = { }
m.module = module

local lua_type = type
local lua_tostring = tostring
local lua_tonumber = tonumber

local function build_mro(class, t, seen)
	t, seen = t or { }, seen or { }
	local class_super = rawget(class, "__super")
	local list = ((not (class_super and class_super.__name))
			and class_super
			or { class_super })
	if not seen[class] then
		table.insert(t, class)
		seen[class] = true
	end
	for _, cls in ipairs(list) do
		if not seen[cls] then
			table.insert(t, cls)
			seen[cls] = true
		end
	end
	for _, cls in ipairs(list) do
		build_mro(cls, t, seen)
	end
	return t
end

function m.type(x)
	local mt = (debug and debug.getmetatable
			and debug.getmetatable(x)
			or getmetatable(x) or { })
	local rt = rawget(mt, "__type")
	return ((lua_type(rt) == "function")
			and rt(x)
			or rt
			or lua_type(x))
end

function m.repr(x)
	local mt = (debug and debug.getmetatable
			and debug.getmetatable(x)
			or getmetatable(x) or { })
	return ((mt.__repr and mt.__repr(x))
			or ((lua_type(x) == "string") and ("%q"):format(x))
			or lua_tostring(x))
end

function m.tonumber(x, base)
	local mt = (debug and debug.getmetatable
			and debug.getmetatable(x)
			or getmetatable(x) or { })
	return ((mt.__tonumber and mt.__tonumber(x))
			or lua_tonumber(x))
end

local function deep_copy(t, seen)
	seen = seen or { }
	if seen[t] then return seen[t] end
	local nt = { }
	seen[t] = nt
	for k, v in pairs(t) do
		if type(v) == "table" then
			nt[k] = deep_copy(v, seen)
		else
			nt[k] = v
		end
	end
	return nt
end

local function shallow_copy(t)
	local nt = { }
	for k, v in pairs(t) do
		nt[k] = v
	end
	return nt
end

local metamethods = {
	"add", "sub", "mul", "div", "mod", "pow", "unm",
	"concat", "len", "eq", "lt", "le",
	"tostring", "tonumber", "toboolean", "repr",
}

local default_classmeta = { }

for _, k in ipairs(metamethods) do
	local kk = "__"..k
	default_classmeta["__"..k] = function(self, ...)
		local f = self[kk]
		return f and f(self, ...)
	end
end

function default_classmeta:__call(...)
	local mt = {
		__index = self,
		__type = self,
	}
	for _, k in ipairs(metamethods) do
		local kk = "__"..k
		mt["__"..k] = default_classmeta[kk]
	end
	local inst = setmetatable({
		__class = self,
		__super = self.__super,
		__mro = self.__mro,
	}, mt)
	inst:init(...)
	return inst
end

function default_classmeta:__type()
	return self.__class
end

function default_classmeta:__index(k)
	for _, class in ipairs(self.__mro) do
		local v = rawget(class, k)
		if v ~= nil then
			return v
		end
	end
end

local function make_class(module, name, super)
	assert((module == nil) or (type(module) == "table") and module._NAME,
			"Invalid module specified")
	assert(type(name) == "string", "Class name required")
	local class_name
	if module then
		class_name = module._NAME.."."..name
	else
		class_name = name
	end
	local supermeta = getmetatable(super)
	local clsmeta = shallow_copy(supermeta or default_classmeta)
	local clsdef = { }
	clsdef.__name = class_name
	clsdef.__super = super
	clsdef.__mro = build_mro(clsdef)
	m.classes[class_name] = clsdef
	if module then
		module[name] = clsdef
	end
	setmetatable(clsdef, clsmeta)
	return clsdef
end

function m.class(module, name, super)
	if type(module) == "string" then
		-- Called without module; shift arguments.
		module, name, super = nil, module, name
	end
	return make_class(module, name, super or m.Object)
end

function m.is_subclass(cls1, cls2)
	if cls1 == cls2 then return true end
	if not cls1.__super then return false end
	for _, class in ipairs(cls1.__mro) do
		if class == cls2 then
			return true
		end
	end
	return false
end

function m.is_instance(inst, cls)
	return m.is_subclass(inst.__class, cls)
end

function m.import(dest, src)
	if type(src) == "string" then
		src = require(src)
	end
	for k, v in pairs(src) do
		if k:sub(1, 1) ~= "_" then
			dest[k] = v
		end
	end
end

function m.assert_type(value, typename, message, level)
	if type(value) ~= typename then
		error(message, (level or 1) + 1)
	end
end

local type_codes = {
	s = "string", n = "number", b = "boolean",
	t = "table", u = "userdata", T = "thread",
	f = "function",
}

function m.check_types(level, start, types, ...)
	local av
	if lua_type(start) == "string" then
		av = { types, ... }
		start, types = 1, start
	else
		av = { ... }
	end
	local i = 1
	for c in types:gmatch(".%??") do
		if c ~= "*" then
			local cc, can_nil = c:match("(.)(%?)")
			c = cc or c
			local v = av[i]
			local t1 = lua_type(v)
			local t2 = type_codes[c]
			if not ((t1 == t2) or (can_nil and (t1 == "nil"))) then
				error("Argument "..(i+start-1).." must be "
						..t2.." ("..t1.." passed)", level+1)
			end
		end
		i = i + 1
	end
	return ...
end

function m.option_checker(name, options, allow_nil)
	for _, k in ipairs(options) do
		options[k] = true
	end
	local list_repr = "\""..table.concat(options, "\", \"").."\""
	if allow_nil then
		list_repr = "nil, "..list_repr
	end
	local err = ("invalid value for "..name..";"
		.." must be one of ("..list_repr..")")
	return function(value)
		if (not (value or allow_nil)) or (not valid[value]) then
			error(err.." ("..m.repr(value).." passed)", 2)
		end
	end
end

-- Aliases
m.issubclass = m.is_subclass
m.isinstance = m.is_instance
m.asserttype = m.assert_type
m.checktypes = m.check_types
m.optionlist = m.option_list

local Object = make_class(m, "Object")

function Object:init()
end

function Object:__tostring()
	return "<"..self.__name..">"
end

function Object:repr()
	return [[require("classes").Object()]]
end

require("klib.classes.test").test(m)

return m
