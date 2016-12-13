return function()
	local tiny = require "tiny"

	return tiny.processingSystem {
		filter = tiny.requireAll("possessed", "position"),
		physics_system = true,
		process = function(self, entity, dt)
			entity.velocity = entity.velocity or cpml.vec3()

			entity.position.x = entity.position.x + entity.velocity.x
			entity.position.y = entity.position.y + entity.velocity.y
			entity.position.z = entity.position.z + entity.velocity.z

			entity.last_velocity = entity.velocity:clone()

			entity.velocity.x = 0
			entity.velocity.y = 0
			entity.velocity.z = 0

			if self.camera and self.camera.lock ~= true then
				self.camera.position = entity.position:clone()
			end
		end
	}
end
