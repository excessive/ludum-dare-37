return function()
	local tiny = require "tiny"
	local cpml = require "cpml"

	local player_player = tiny.processingSystem {
		name     = "Player Collision",
		priority = 201,
		filter   = tiny.requireAll("capsules", "position"),
		process  = function(self, entity, _)
			-- Attack collision
			for _, other in ipairs(self.entities) do
				if not entity.attacking then break end      -- don't check if you're not attacking
				if other == entity then goto continue end   -- don't check against yourself
				if other.iframes > 0 then goto continue end -- don't check if other is invincible

				for _, ecap in pairs(entity.capsules.weapon) do
					for o, ocap in pairs(other.capsules.hitbox) do
						local hit, _, p2 = cpml.intersect.capsule_capsule(ecap, ocap)
						if hit and other.iframes == 0 then -- gotta check again!
							if other.possessed then
								_G.EVENT:say("take damage", p2, o)
							else
								if entity.spike or other.spike then goto continue end
								_G.EVENT:say("give damage", p2, o)
							end
						end
					end
				end

				::continue::
			end

			if not entity.possessed then return end

			local function cc_hit(ecap, ocap)
				local hit, p1, p2 = cpml.intersect.capsule_capsule(ecap, ocap)
				if hit then
					local direction = p1 - p2
					direction:normalize(direction)

					local power     = entity.velocity:dot(direction)
					local reject    = direction * -power
					entity.velocity = entity.velocity + reject * entity.velocity:len()

					local offset    = p1 - entity.position
					entity.position = p2 - offset + direction * (ecap.radius + ocap.radius)
				end
			end

			-- Hitbox collision
			for _, other in ipairs(self.entities) do
				if other == entity then goto continue end

				for _, ecap in pairs(entity.capsules.hitbox) do
					-- Collide with hit boxes
					for _, ocap in pairs(other.capsules.hitbox) do
						cc_hit(ecap, ocap)
					end

					-- Collide with weapons
					if other.attacking then goto continue end
					for _, ocap in pairs(other.capsules.weapon) do
						cc_hit(ecap, ocap)
					end
				end

				::continue::
			end

			-- meow
			local dist = entity.position:dist(self.world.cat.position)
			if dist < 5 and self.world.cat.meow == 0 then
				self.world.cat.meow = 10
				self.world.cat.audio:play()
			end
		end
	}

	local player_powerups = tiny.processingSystem {
		name    = "Powerup Collision",
		filter  = tiny.requireAll("possessed", "position"),
		process = function(self, entity, dt)
			for _, powerup in ipairs(self.world.powerups) do
				if entity.position:dist(powerup.position) <= powerup.radius then
					_G.EVENT:say("pickup item", powerup)
				end
			end
		end
	}

	return tiny.system {
		name     = "Collision",
		priority = 200,
		onAddToWorld = function(_, world)
			world:addSystem(player_player)
			world:addSystem(player_powerups)
		end
	}
end
