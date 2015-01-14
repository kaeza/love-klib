
local m = { }

local function test_inheritance(m)
	local Test1 = m.class("Test1")
	Test1.a = "Test1"
	local Test2 = m.class("Test2", Test1)
	local Test3 = m.class("Test3", Test1)
	Test3.a = "Test3"
	local Test4 = m.class("Test4")
	local Test5 = m.class("Test5", {Test4, Test1})
	assert(Test2.a == "Test1")
	assert(Test3.a == "Test3")
	assert(Test4.a == nil)
	assert(Test5.a == "Test1")
end

local function test_meta(m)
	local Number = m.class("Number")
	local tonumber = m.tonumber
	function Number:init(value)
		self.value = tonumber(value)
	end
	function Number:__add(x)
		return Number(self.value + tonumber(x))
	end
	function Number:__sub(x)
		return Number(self.value - tonumber(x))
	end
	function Number:__mul(x)
		x = (m.type(x) == "number") and x or x.value
		return Number(self.value * tonumber(x))
	end
	function Number:__div(x)
		return Number(self.value / tonumber(x))
	end
	function Number:__mod(x)
		return Number(self.value % tonumber(x))
	end
	function Number:__unm()
		return Number(-self.value)
	end
	function Number:__tostring()
		return (self.__class
				and tostring(self.value)
				or m.Object.__tostring(self))
	end
	function Number:__tonumber()
		return self.value
	end
	function Number:__eq(x)
		return self.value == tonumber(x)
	end
	function Number:__repr()
		return ("Number(%f)"):format(self.value)
	end
	local n1, n2 = Number(1), Number(2)
	local nr, n3 = (n1 + n2), Number(3)
	assert(nr == n3)
end

local tests = {
	test_inheritance,
	test_meta,
}

function m.test(m)
	for _, test in ipairs(tests) do
		test(m)
	end
end

return m
