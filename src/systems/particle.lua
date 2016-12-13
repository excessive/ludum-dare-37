return function()
	local tiny = require "tiny"
	local cpml = require "cpml"
	local particle = tiny.system()

	particle.filter          = tiny.requireAll("particles", "spawn_rate", "lifetime", "radius", "position")
	particle.particle_data   = {}
	particle.time            = 0
	particle.default_texture = love.graphics.newImage("assets/textures/particle.png")
	particle.default_size    = 0.5
	particle.layout          = {
		{ "VertexPosition", "float", 2 },
		{ "VertexTexCoord", "float", 2 }
	}

	function particle:onAdd(entity)
		local w, h, aspect
		if entity.texture then
			w, h = entity.texture:getDimensions()
		else
			w, h = self.default_texture:getDimensions()
		end
		aspect = w/h
		local size = entity.size or self.default_size
		local data = {
			{ 0, 0, 0, 0 },
			{ size*aspect, 0, 1, 0 },
			{ size*aspect, size, 1, 1 },
			{ 0, size, 0, 1 },
		}
		local m = love.graphics.newMesh(self.layout, data, "fan", "static")
		m:setTexture(entity.texture or self.default_texture)
		self.particle_data[entity] = {
			particles = {},
			current_count = 0,
			last_spawn_time = 0,
			mesh = m
		}
	end

	function particle:onRemove(entity)
		self.particle_data[entity] = nil
	end

	function particle:spawn_particle(entity)
		local pd   = self.particle_data[entity]
		local rand = love.math.random
		local r    = entity.radius
		local s    = entity.spread

		pd.last_spawn_time = self.time
		pd.current_count   = pd.current_count + 1

		-- Account for object attachment
		local pos = entity.position
		local vel = entity.velocity

		if entity.parent_matrix then
			local m = entity.parent_matrix
			local p = m * { pos.x, pos.y, pos.z, 1 }
			pos = cpml.vec3(p[1], p[2], p[3])

			local m2 = m:clone()
			m2[13], m2[14], m2[15] = 0, 0, 0

			if not entity.ignore_parent_velocity then
				local p_vel = entity.attachment.velocity
				--if p_vel then
				--	 vel = vel + p_vel
				--end
				local v = m2 * { vel.x, vel.y, vel.z, 1 }
				vel = cpml.vec3(v[1], v[2], v[3])
			end
		end

		local despawn_time = self.time
		local life = entity.lifetime

		if type(life) == "table" then
			despawn_time = despawn_time + rand(life[1]*10000, life[2]*10000) / 10000
		else
			despawn_time = despawn_time + life
		end

		-- No need to add lifetime every update, might as well do it here.
		table.insert(pd.particles, {
			despawn_time = despawn_time,
			position     = pos + cpml.vec3((2*rand()-1)*r, (2*rand()-1)*r, 0),
			velocity     = cpml.vec3(
				vel.x + (2 * rand()-1) * s,
				vel.y + (2 * rand()-1) * s,
				vel.z + (2 * rand()-1) * s
			)
		})
	end

	function particle:update_particles(dt, entity, data)
		-- It's been too long since our last particle spawn and we need more, time
		-- to get to work.
		local spawn_delta = self.time - data.last_spawn_time
		if data.current_count < entity.particles and spawn_delta > entity.spawn_rate then
			-- XXX: Why is this spawning so many at once?
			local need = math.floor(spawn_delta / entity.spawn_rate)
			-- console.i("Spawning %d particles", need)
			for _=1, math.min(need, 2) do
				self:spawn_particle(entity)
			end
		end

		-- Because particles are added in order of time and removals maintain
		-- order, we can simply count the number we need to get rid of and process
		-- the rest.
		local remove_n = 0
		for i=1, #data.particles do
			local p = data.particles[i]
			if self.time > p.despawn_time then
				remove_n = remove_n + 1
			else
				p.position.x = p.position.x + p.velocity.x * dt
				p.position.y = p.position.y + p.velocity.y * dt
				p.position.z = p.position.z + p.velocity.z * dt
			end
		end

		-- Particles be gone!
		if remove_n > 0 then
			-- console.i("Despawning %d particles", remove_n)
			data.current_count = data.current_count - remove_n
		end
		for _=1, remove_n do
			table.remove(data.particles, 1)
		end

		-- if data.current_count < entity.particles then
		-- 	print(data.current_count)
		-- end
	end

	function particle:update(dt)
		self.time = self.time + dt
		for i = 1, #self.entities do
			local entity = self.entities[i]
			self:update_particles(dt, entity, self.particle_data[entity])
		end
	end

	-- Note: While drawing particles, you want to make sure that depth writing is off.
	function particle:draw_particles(entity, shader)
		local pd = self.particle_data[entity]
		-- jfc this is going to be slow as shit
		local offset = entity.offset or cpml.vec3()
		for i = 1, #pd.particles do
			local p = pd.particles[i]
			shader:send("u_position", {
				p.position.x + offset.x,
				p.position.y + offset.y,
				p.position.z + offset.z
			})
			love.graphics.draw(pd.mesh)
		end
	end

	return particle
end
