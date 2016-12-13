-- Basic ring buffer utility, to spare the hassle.
local ringbuffer = {}
local ringbuffer_mt = {}

local function new(_items)
	local t = {
		items   = _items or {},
		current = 1
	}
	return setmetatable(t, ringbuffer_mt)
end

ringbuffer_mt.__index = ringbuffer
ringbuffer_mt.__call = function(_, ...)
	return new(...)
end

function ringbuffer:get()
	return self.items[self.current]
end

function ringbuffer:next()
	self.current = (self.current % #self.items) + 1
	return self:get()
end

function ringbuffer:prev()
	self.current = self.current - 1
	if self.current < 1 then
		self.current = #self.items
	end
	return self:get()
end

function ringbuffer:reset()
	self.current = 1
end

function ringbuffer:insert(item, ...)
	if not item then
		return
	end

	self:insert(...)
	table.insert(self.items, self.current + 1, item)
end

function ringbuffer:append(item, ...)
	if not item then
		return
	end

	self.items[#self.items + 1] = item
	return self:append(...)
end

function ringbuffer:remove(k)
	if not k then
		return table.remove(self.items, self.current)
	end

	-- same as vrld's
	local pos = (self.current + k) % #self.items
	while pos < 1 do pos = pos + #self.items end

	local item = table.remove(self.items, pos)

	if pos < self.current then self.current = self.current - 1 end
	if self.current > #self.items then self.current = 1 end

	return item
end

return setmetatable({ new = new }, ringbuffer_mt)
