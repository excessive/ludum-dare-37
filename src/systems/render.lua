return function()
	local lvfx = require "lvfx"
	local tiny = require "tiny"
	local cpml = require "cpml"
	local l3d  = require "love3d"
	local load = require "utils.load-files"

	local render = tiny.system {
		filter = tiny.requireAny(
			tiny.requireAll("visible", "mesh"),
			tiny.requireAll("capsules")
		)
	}

	function render:onAddToWorld()
		-- use weak references so we don't screw with the gc
		self.objects = {}
		setmetatable(self.objects, { __mode = 'v'})

		self.capsules = {}
		setmetatable(self.capsules, { __mode = 'v'})

		self.views = {
			shadow      = lvfx.newView(),
			background  = lvfx.newView(),
			foreground  = lvfx.newView(),
			transparent = lvfx.newView()
		}
		self.shadow_rt = l3d.new_shadow_map(1024, 1024)

		self.capsule_debug = false

		self.views.shadow:setCanvas(self.shadow_rt)
		self.views.shadow:setDepthClear(true)
		self.views.shadow:setCulling("front")
		self.views.shadow:setDepthTest("less", true)

		self.views.background:setClear(0.05, 0.1, 0.3, 1)
		self.views.background:setDepthClear(true)
		self.views.background:setCulling("back")
		self.views.background:setDepthTest("less", false)

		self.views.foreground:setDepthTest("less", true)
		self.views.foreground:setCulling("back")

		self.views.transparent:setDepthTest("less", false)

		self.light = {
			color     = { 1.2, 1.2, 1.2 },
			position  = cpml.vec3(0.0, 0.0, 5.0),
			direction = cpml.vec3(0.3, 0.0, 0.7),
			bias      = 0.005,
			range     = 25
		}
		self.light.direction:normalize(self.light.direction)

		self.uniforms = {
			-- transform matrices
			proj       = lvfx.newUniform("u_projection"),
			view       = lvfx.newUniform("u_view"),
			model      = lvfx.newUniform("u_model"),
			-- pose matrices
			pose       = lvfx.newUniform("u_pose"),
			-- camera stuff
			clips      = lvfx.newUniform("u_clips"),
			fog_color  = lvfx.newUniform("u_fog_color"),
			-- particle position
			position   = lvfx.newUniform("u_position"),
			-- lights
			light_dir  = lvfx.newUniform("u_light_direction"),
			light_col  = lvfx.newUniform("u_light_color"),
			light_v    = lvfx.newUniform("u_light_view"),
			light_p    = lvfx.newUniform("u_light_projection"),
			-- shadows
			shadow_tex = lvfx.newUniform("u_shadow_texture", true),
			shadow_vp  = lvfx.newUniform("u_shadow_vp")
		}

		self.shaders = {
			sky            = lvfx.newShader("assets/shaders/sky.glsl"),
			particle       = lvfx.newShader("assets/shaders/particle.glsl"),
			normal         = lvfx.newShader("assets/shaders/basic-normal.vs.glsl", "assets/shaders/basic.fs.glsl"),
			skinned        = lvfx.newShader("assets/shaders/basic-skinned.vs.glsl", "assets/shaders/basic.fs.glsl"),
			shadow_normal  = lvfx.newShader("assets/shaders/shadow-normal.vs.glsl", "assets/shaders/shadow.fs.glsl", true),
			shadow_skinned = lvfx.newShader("assets/shaders/shadow-skinned.vs.glsl", "assets/shaders/shadow.fs.glsl", true)
		}
		self.shaders.flat = self.shaders.normal
	end

	function render:onRemoveFromWorld()
		self.objects   = nil
		self.capsules  = nil
		self.views     = nil
		self.uniforms  = nil
		self.world     = nil
	end

	function render:onAdd(e)
		if e.mesh then
			table.insert(self.objects, e)
		end
		if e.capsules then
			table.insert(self.capsules, e)
		end
	end

	function render:onRemove(e)
		if e.mesh then
			-- all entities are guaranteed unique by tiny
			for i, entity in ipairs(self.objects) do
				if entity == e then
					table.remove(self.objects, i)
					break
				end
			end
		end
		if e.capsules then
			for i, entity in ipairs(self.capsules) do
				if entity == e then
					table.remove(self.capsules, i)
					break
				end
			end
		end
	end

	local default_pos   = cpml.vec3(0, 0, 0)
	local default_scale = cpml.vec3(1, 1, 1)

	local function draw_model(model, textures)
		for _, buffer in ipairs(model) do
			if textures and textures[buffer.material] then
				model.mesh:setTexture(load.texture(textures[buffer.material]))
			else
				model.mesh:setTexture()
			end
			model.mesh:setDrawRange(buffer.first, buffer.last)
			love.graphics.draw(model.mesh)
		end
	end

	function render:update()
		assert(self.camera, "A camera is required to draw the scene.")
		self.camera:update(self.views.foreground:getDimensions())

		self.uniforms.proj:set(self.camera.projection:to_vec4s())
		self.uniforms.view:set(self.camera.view:to_vec4s())
		self.uniforms.clips:set({self.camera.near, self.camera.far})
		self.uniforms.fog_color:set(self.views.background._clear)
		self.uniforms.light_dir:set({self.light.direction:unpack()})
		self.uniforms.light_col:set(self.light.color)

		local light_proj = cpml.mat4.from_ortho(-self.light.range, self.light.range, -self.light.range, self.light.range, -50, 50)
		local light_view = cpml.mat4()
		light_view:look_at(
			light_view,
			self.light.position,
			self.light.position - self.light.direction,
			cpml.vec3.unit_y
		)
		local bias = cpml.mat4 {
			0.5, 0.0, 0.0, 0.0,
			0.0, 0.5, 0.0, 0.0,
			0.0, 0.0, 0.5, 0.0,
			0.5, 0.5, 0.5, 1.0 + self.light.bias
		}
		self.uniforms.light_v:set(light_view:to_vec4s())
		self.uniforms.light_p:set(light_proj:to_vec4s())
		self.uniforms.shadow_vp:set((light_view * light_proj * bias):to_vec4s())
		self.uniforms.shadow_tex:set(self.shadow_rt)

		if self.capsule_debug then
			for _, entity in ipairs(self.capsules) do
				local function draw_capsules(list, r, g, b, a)
					local function mtx(capsule, radius)
						local ret = cpml.mat4()
						ret:translate(ret, capsule)
						ret:scale(ret, cpml.vec3(radius, radius, radius))
						return ret
					end
					local sphere = load.model("assets/models/debug/unit-sphere.iqm")
					local cylinder = load.model("assets/models/debug/unit-cylinder.iqm")
					for joint, capsule in pairs(list) do
						lvfx.setShader(self.shaders.flat)
						lvfx.setColor(r, g, b, a)
						lvfx.draw(sphere.mesh)

						self.uniforms.model:set(mtx(capsule.a, capsule.radius):to_vec4s())
						lvfx.submit(self.views.transparent, true)

						self.uniforms.model:set(mtx(capsule.b, capsule.radius):to_vec4s())
						lvfx.submit(self.views.transparent, true)

						local cap = cpml.mat4()
						local dir = capsule.b - capsule.a
						dir:normalize(dir)
						local rot = cpml.quat.from_direction(dir, cpml.vec3.unit_z)
						rot:normalize(rot)
						cap:translate(cap, (capsule.a + capsule.b) / 2)
						cap:rotate(cap, rot)
						cap:scale(cap, cpml.vec3(capsule.radius, capsule.radius, capsule.length / 2))
						self.uniforms.model:set(cap:to_vec4s())
						lvfx.draw(cylinder.mesh)
						lvfx.submit(self.views.transparent)
					end
				end
				draw_capsules(entity.capsules.weapon, 1.0, 0.5, 0.5, 0.15)
				draw_capsules(entity.capsules.hitbox, 0.5, 0.5, 1.0, 0.15)
			end
		end

		lvfx.touch(self.views.shadow)

		for _, entity in ipairs(self.objects) do
			if entity.sky then
				lvfx.setShader(self.shaders.sky)
				lvfx.setDraw(draw_model, { entity.mesh, entity.textures })
				lvfx.submit(self.views.background)
				goto continue
			end

			if entity.blob_shadow then
				local blob = cpml.mat4()
				blob:translate(blob, (entity.position or default_pos) + cpml.vec3(0, 0, 0.001))
				blob:scale(blob, (entity.scale or default_scale) / cpml.vec3(2, 2, 2))
				self.uniforms.model:set(blob:to_vec4s())

				lvfx.setShader(self.shaders.normal)
				lvfx.setDraw(function()
					local m = load.model("assets/models/debug/unit-plane.iqm")
					m.mesh:setTexture(load.texture("assets/textures/shadow.png"))
					love.graphics.draw(m.mesh)
				end)
				lvfx.submit(self.views.transparent)
			end

			self.uniforms.model:set((entity.matrix or cpml.mat4():identity()):to_vec4s())

			local anim = entity.animation
			if anim and anim.current_pose then
				self.uniforms.pose:set(unpack(anim.current_pose))
				lvfx.setShader(self.shaders.skinned)
			else
				lvfx.setShader(self.shaders.normal)
			end

			lvfx.setColor(entity.color or { 1, 1, 1, 1 })
			lvfx.setDraw(draw_model, { entity.mesh, entity.textures })
			lvfx.submit(self.views.foreground, true)

			if entity.no_shadow then
				lvfx.submit(false)
			else
				lvfx.setShader(anim and self.shaders.shadow_skinned or self.shaders.shadow_normal)
				lvfx.submit(self.views.shadow)
			end
			::continue::
		end
	end

	function render:draw()
		lvfx.frame {
			self.views.shadow,
			self.views.background,
			self.views.foreground,
			self.views.transparent
		}
	end

	return render
end