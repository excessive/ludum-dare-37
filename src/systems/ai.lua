return function()
	local cpml   = require "cpml"
	local tiny   = require "tiny"
	local system = tiny.processingSystem {
		name   = "AI",
		filter = tiny.requireAll("phase"),
	}

	function system:snap_to(entity)
		local d2p      = self:dir_to_player(entity)
		local angle    = cpml.vec2(d2p.x, d2p.y):angle_to() - math.pi / 2
		entity.snap_to = cpml.quat.from_direction(d2p, cpml.vec3.unit_z) * cpml.quat.rotate(angle, cpml.vec3.unit_z)
	end

	function system:dir_to_player(entity)
		return cpml.vec3.normalize(cpml.vec3(), entity.position - self.player.position)
	end

	function system:scan_for_target(entity)
		entity.timer:script(function(wait)
			entity.scanning = true
			wait(entity.attack_cooldown)

			local d2p  = self:dir_to_player(entity)
			local dir  = d2p:dot(entity.orientation * cpml.vec3.unit_y)
			local dist = entity.position:dist(self.player.position)

			if dir >= 0 and dist < 25 then
				self:snap_to(entity)
				entity.tracking = true

				if entity.walking then
					entity.timer:cancel(entity.walking)
					entity.walking = false
				end
			end

			wait(4)
			entity.scanning = false
		end)
	end

	function system:process(entity, dt)
		entity.timer:update(dt)
		if not self.player then return end

		if not entity.scanning and entity.anim_cooldown == 0 then
			self:scan_for_target(entity)
		end

		if entity.tracking then
			self:snap_to(entity)
		end

		if entity.tracking and entity.anim_cooldown == 0 then
			local dist = entity.position:dist(self.player.position)
			if entity.last_hit == "tentacle" or entity.last_hit == "tail" then
				_G.EVENT:say("boss attack sweep")
			elseif entity.last_hit == "foot" or entity.last_hit == "knee" then
				_G.EVENT:say("boss attack spin")
			elseif dist > 14 and dist < 25 or dist < 10 then
				_G.EVENT:say("boss attack spike")
			elseif dist >= 10 and dist <= 14 then
				_G.EVENT:say("boss attack stab")
			end
		end

		if not entity.tracking and entity.anim_cooldown == 0 and entity.attack_cooldown == 0 and not entity.walking then
			_G.EVENT:say("boss walk")
		end

		if entity.snap_to then
			entity.orientation:slerp(entity.orientation, entity.snap_to, dt*25)
			entity.slerp         = entity.slerp + dt
			entity.orientation.x = 0
			entity.orientation.y = 0
			cpml.quat.normalize(entity.orientation, entity.orientation)

			if entity.slerp > 1 then
				entity.snap_to = false
				entity.slerp   = 0
			end
		end
	end

	return system
end
