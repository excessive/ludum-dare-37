local moment = {}

local cpml = require "cpml"

function moment.new(init)
	init = init or {}
	assert(init.position,"moment.new requires position argument")
	assert(init.orientation,"moment.new requires orientation argument")
	assert(init.offset,"moment.new requires offset argument")
	assert(init.orbit_offset,"moment.new requires orbit_offset argument")

	local self = {}

	self._position = init.position
	self._orientation = init.orientation
	self._offset = init.offset
	self._orbit_offset = init.orbit_offset
	
	self._lerptime_max = init.lerptime or 1
	self._lerptime = 0

	self.updateCamera = moment.updateCamera
	self.draw = moment.draw
	self.isDone = moment.isDone

	return self
end

function moment:updateCamera(dt,camera)

	self._lerptime = math.min(self._lerptime_max,self._lerptime + dt)

	if self._orig_position == nil then
		self._orig_position = camera.position:clone()
	end
	if self._orig_orientation == nil then
		self._orig_orientation = camera.orientation:clone()
	end
	if self._orig_offset == nil then
		self._orig_offset = camera.offset:clone()
	end
	if self._orig_orbit_offset == nil then
		self._orig_orbit_offset = camera.orbit_offset:clone()
	end

	local s = self._lerptime / self._lerptime_max

	camera.position:lerp(self._orig_position,self._position,s)
	camera.orientation:slerp(self._orig_orientation,self._orientation,s)
	camera.offset:lerp(self._orig_offset,self._offset,s)
	camera.orbit_offset:lerp(self._orig_orbit_offset,self._orbit_offset,s)
	camera.direction = camera.orientation * cpml.vec3.unit_y -- OMG YAEY #1STWORLDPROBLEMS
end

function moment:isDone()
	return self._lerptime == self._lerptime_max
end

function moment:draw()
end

return moment
