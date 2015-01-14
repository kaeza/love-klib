
local classes = require "klib.classes"

local m = classes.module "klib.utils.timer"

local Timer = classes.class(m, "Timer")

-- Public Fields.
Timer.interval = nil
Timer.time = nil
Timer.func = nil

function Timer:init(interval, func)
	classes.check_types(2, 1, "nf?", interval, func)
	self.time = interval
	self.interval = interval
	self.func = func
end

function Timer:update(dtime)
	self.time = self.time - dtime
end

function Timer:ticked()
	local r = (self.time <= 0)
	if r then
		self.time = self.time + self.interval
	end
	return r
end

function Timer:tick(dtime)
	self:update(dtime)
	local func = self.func or self.on_alarm
	local interval = self.interval
	while self:ticked() do
		func(self, interval)
	end
end

function Timer:on_alarm(interval)
end

return m
