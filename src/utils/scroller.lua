local timer = require "timer"
local ringbuffer = require "utils.ringbuffer"
local cpml = require "cpml"

local scroller = {}
local scroller_mt = {}

local function default_transform(self, offset, count, index)
	local spacing = love.window.toPixels(50)
	self.x = math.floor(math.cos(offset / (count / 2)) * love.window.toPixels(50))
	self.y = math.floor(offset * spacing)
end

local function default_position(_)
	return 0, 0
end

local default_sounds = {
	prev   = false,
	next   = false,
	select = false
}

local function new(items, options)
	local t = {
		fixed       = options.fixed        or false,
		switch_time = options.switch_time  or 0.2,
		size        = options.size         or false,
		sounds      = options.sounds       or default_sounds,
		transform   = options.transform_fn or default_transform,
		position    = options.position_fn  or default_position,
		cursor_data = {},
		data        = {},
		_timer = timer.new(),
		_rb    = ringbuffer(items),
		_pos   = 1,
		_tween = false,
		_last_hit = { love.mouse.getPosition() }
	}
	t = setmetatable(t, scroller_mt)
	t:reset()
	return t
end

scroller_mt.__index = scroller
scroller_mt.__call  = function(_, ...)
	return new(...)
end
local function tween(self)
	if self._tween then
		self._timer:cancel(self._tween)
	end
	self._tween = self._timer:tween(self.switch_time, self, { _pos = self._rb.current }, "out-back")
end

function scroller:get()
	return self._rb.items[self._rb.current]
end

function scroller:prev(n)
	if self.sounds.prev then
		self.sounds.prev:stop()
		self.sounds.prev:play()
	end
	for _ = 1, (n or 1) do self._rb:prev() end
	local item = self:get()
	if item.skip then
		self:prev()
	else
		tween(self)
	end
end

function scroller:next(n)
	if self.sounds.next then
		self.sounds.next:stop()
		self.sounds.next:play()
	end

	for _ = 1, (n or 1) do self._rb:next() end
	local item = self:get()
	if item.skip then
		self:next()
	else
		tween(self)
	end
end

function scroller:reset()
	self._rb:reset()

	-- If you manage to land on a skip that is bad mojo, go to the next one
	local item = self:get()
	while item.skip do
		self:next()
		item = self:get()
	end

	-- throw in a big number to force an initial skip to not animate
	self:update(math.huge)
end

function scroller:hit(x, y, click)
	if not self.size or (not self.fixed and not click) then
		self._last_hit = false
		return false
	end
	if self._last_hit and self._last_hit[1] == x and self._last_hit[2] == y then
		if not click then
			return false
		end
	end
	self._last_hit = { x, y }
	local p = cpml.vec3(x, y, 0)
	for i, item in ipairs(self._rb.items) do
		local b = {
			min = cpml.vec3(self.data[i].x, self.data[i].y, 0),
			max = cpml.vec3(self.data[i].x + self.size.w, self.data[i].y + self.size.h, 0)
		}
		if not item.skip and cpml.intersect.point_aabb(p, b) then
			self._rb.current = i
			tween(self)
			return true
		end
	end
	return false
end

function scroller:update(dt)
	self._timer:update(dt)
	local x, y = self:position()
	for i, v in ipairs(self._rb.items) do
		self.data[i] = setmetatable({ x = 0, y = 0 }, { __index = v })
		local ipos = i
		if not self.fixed then
			ipos = ipos - self._pos
		end
		self.transform(self.data[i], ipos, #self._rb.items, i)
		self.data[i].x = self.data[i].x + x
		self.data[i].y = self.data[i].y + y
	end
	self.transform(self.cursor_data, self.fixed and self._pos or 0, #self._rb.items, 1)
	self.cursor_data.x = self.cursor_data.x + x
	self.cursor_data.y = self.cursor_data.y + y

	while #self.data > #self._rb.items do
		table.remove(self.data)
	end
end

return setmetatable({ new = new }, scroller_mt)
