local cutscene = {}

local cpml = require "cpml"

function cutscene.new(init)
	init = init or {}

	assert(init.camera,"cutscene.new requires a camera object")

	local self = {}

	self._camera = init.camera

	self._orig_position = self._camera.position:clone()
	self._orig_orientation = self._camera.orientation:clone()
	self._orig_offset = self._camera.offset:clone()
	self._orig_orbit_offset = self._camera.orbit_offset:clone()

	self._orig_lerp = 0
	self._orig_lerp_max = 1
	self._done = false

	self._directions = {}

	self.addMoment = cutscene.addMoment
	self.addDialog = cutscene.addDialog
	self.isDone = cutscene.isDone
	self.draw = cutscene.draw
	self.update = cutscene.update

	return self
end

function cutscene:addMoment(moment)
	table.insert(self._directions,moment)
end

function cutscene:addDialog(dialog)
	table.insert(self._directions,dialog)
end

function cutscene:isDone()
	return self._done
end

function cutscene:draw()
	if self._current_direction then

		if self._current_direction.draw then
			self._current_direction:draw()
		end
	elseif self._orig_lerp > 0 then
		--print("returning to original position")
	end
end

function cutscene:update(dt)

	if self._current_direction then

		if self._current_direction.update then
			self._current_direction:update(dt)
		end
		if self._current_direction.updateCamera then
			self._current_direction:updateCamera(dt,self._camera)
		end

		if self._current_direction:isDone() then
			if self._current_direction._position then
				self._last_position = self._current_direction._position
			end
			self._current_direction = nil
		end
	end

	if not self._current_direction then
		if #self._directions > 0 then
			self._current_direction = table.remove(self._directions,1)
			if self._last_position then
				self._current_direction._orig_position = self._last_position
			end
		else

			if self._start_position == nil then
				self._start_position = self._camera.position:clone()
			end
			if self._start_orientation == nil then
				self._start_orientation = self._camera.orientation:clone()
			end
			if self._start_offset == nil then
				self._start_offset = self._camera.offset:clone()
			end
			if self._start_orbit_offset == nil then
				self._start_orbit_offset = self._camera.orbit_offset:clone()
			end

			self._orig_lerp = math.min(self._orig_lerp_max,self._orig_lerp + dt)
			local s = self._orig_lerp/self._orig_lerp_max

			self._camera.position:lerp(self._start_position,self._orig_position,s)
			self._camera.orientation:slerp(self._start_orientation,self._orig_orientation,s)
			self._camera.offset:lerp(self._start_offset,self._orig_offset,s)
			self._camera.orbit_offset:lerp(self._start_orbit_offset,self._orig_orbit_offset,s)
			self._camera.direction = self._camera.orientation * cpml.vec3.unit_y -- OMG YAEY #1STWORLDPROBLEMS

			if self._orig_lerp == self._orig_lerp_max then
				self._done = true
			end

		end
	end

end

return cutscene
