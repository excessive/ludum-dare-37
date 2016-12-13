local anchor = require "anchor"
local camera = require "camera"
local cpml   = require "cpml"
local load   = require "utils.load-files"
local timer  = require "timer"
local tiny   = require "tiny"

return function()

local scene  = {}

function scene:enter()
	_G.MUSIC.background:play()

	self.overlay = {opacity=0}

	love.mouse.setRelativeMode(true)

	self.world          = tiny.world()
	self.world.powerups = {}

	self.icons = {
		hp = love.graphics.newImage("assets/icons/hp.png"),
		sp = love.graphics.newImage("assets/icons/sp.png"),
		na = love.graphics.newImage("assets/icons/na.png"),
	}

	self.camera = camera {
		fov          = 45,
		position     = cpml.vec3(0, 0, 0),
		orbit_offset = cpml.vec3(0, 0, -4.5),
		offset       = cpml.vec3(0, 0, -1.5)
	}

	-- Add entities
	load.map("assets/levels/test-map.lua", self.world)

	self.player = self.world:addEntity(require("assets.entities.player")())
	self.player.animation:play("idle")
	self.camera.orientation = self.player.orientation:clone()
	self.camera.direction = self.camera.orientation * cpml.vec3.unit_y

	self.boss = self.world:addEntity(require("assets.entities.boss")())
	self.boss.animation:play("idle")

	-- Easter already?
	self.world.cat = self.world:addEntity(require("assets.entities.cat")())

	-- Add systems
	self.world:addSystem(require("systems.animation")())
	self.world:addSystem(require("systems.audio")())

	self.player_controller = self.world:addSystem(require("systems.player-controller")())
	self.player_controller.camera = self.camera

	self.ai = self.world:addSystem(require("systems.ai")())
	self.ai.player = self.player

	self.world:addSystem(require("systems.collision")())
	self.movement = self.world:addSystem(require("systems.movement")())
	self.movement.camera = self.camera

	self.world:addSystem(require("systems.matrix")())
	self.world:addSystem(tiny.processingSystem {
		filter = tiny.requireAll("capsules", "animation"),
		process = function(_, entity)
			if not entity.matrix or not entity.animation or not entity.animation.current_animation then
				return
			end
			for _, category in pairs(entity.capsules) do
				for joint, capsule in pairs(category) do
					local base = { 0, 0, 0, 1 }
					local pos4 = entity.animation.current_matrices[joint] * entity.matrix * base
					capsule.a = cpml.vec3(pos4[1], pos4[2], pos4[3])

					base = { 0, capsule.length, 0, 1 }
					pos4 = entity.animation.current_matrices[joint] * entity.matrix * base
					capsule.b = cpml.vec3(pos4[1], pos4[2], pos4[3])
				end
			end
		end
	})

	self.step = love.audio.newSource("assets/sfx/step.wav")
	self.step:setVolume(_G.PREFERENCES.sfx_volume * 0.25)
	self.step:setRelative(true)

	self.world:addSystem(tiny.system {
		update = function()
			local pos = self.player.position / 10
			love.audio.setPosition(pos:unpack())
			love.audio.setOrientation(
				self.player.direction.x,
				self.player.direction.y,
				self.player.direction.z,
				0, 0, 1
			)
		end
	})

	self.renderer = self.world:addSystem(require("systems.render")())
	self.renderer.camera = self.camera

	--== Events ==--

	local function predict(time)
		local speed = (self.player.last_velocity or cpml.vec3()) * (1/love.timer.getDelta())
		local prediction = speed * time

		return self.player.position + prediction
	end

	-- Animation markers
	_G.EVENT:listen("anim target", function(entity)
		entity.target   = predict(1.0)
		entity.tracking = false
	end)

	_G.EVENT:listen("anim slash", function(entity)
		local audio = load.sound("assets/sfx/player_attack.wav")
		audio:setVolume(_G.PREFERENCES.sfx_volume * 0.7)
		audio:stop()
		audio:play()
	end)

	_G.EVENT:listen("anim heavy_slash", function(entity)
		local audio = load.sound("assets/sfx/player_attack_heavy.wav")
		audio:setVolume(_G.PREFERENCES.sfx_volume * 0.8)
		audio:stop()
		audio:play()
	end)

	_G.EVENT:listen("anim damage", function(entity)
		entity.attacking = true
	end)

	_G.EVENT:listen("anim invuln", function(entity)
		entity.iframes = 1
	end)

	_G.EVENT:listen("anim vuln", function(entity)
		entity.iframes = 0
	end)

	_G.EVENT:listen("anim recovery", function(entity)
		entity.attacking = false
	end)

	_G.EVENT:listen("anim step", function()
		self.step:play()
	end)

	_G.EVENT:listen("anim spike", function()
		self.boss.timer:script(function(wait)
			-- pick location on map
			local x, y = love.math.random() * 2 - 1, love.math.random() * 2 - 1

			local distance = 1
			local offset   = cpml.vec3(x, y, 0)
			offset:normalize(offset)
			offset = offset * distance

			local position = predict(1.25) + offset

			local max_distance = 19
			local len = position:len()
			if len > max_distance then
				position = position / len * max_distance
			end

			-- create entity
			local spike = self.world:addEntity {
				name        = "Zone-tan",
				visible     = true,
				blob_shadow = true,
				spike       = true,
				mesh        = load.model("assets/models/tentacle.iqm"),
				animation   = load.anims("assets/models/tentacle.iqm"),
				markers     = load.markers("assets/markers/tentacle.lua"),
				position    = position,
				orientation = cpml.quat(0, 0, 0, 1),
				scale       = cpml.vec3(1, 1, 1),
				matrix      = cpml.mat4(),
				iframes     = 0,
				capsules    = {
					hitbox = {
						["root"]         = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 1.2 },
						["tentacle"]     = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 1.2 },
						["tentacle.001"] = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 1.2 },
						["tentacle.002"] = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 1.2 }
					},
					weapon = {
						["tentacle.003"] = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 1.2 },
						["tentacle.004"] = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 2.0 }
					}
				}
			}
			-- spike comes up from ground after 0.25s
			spike.animation:reset()
			spike.animation:play("wiggle")
			spike.animation:update(0)
			spike.animation:reset()
			wait(0.5)
			spike.animation:play("wiggle")
			spike.blob_shadow = false

			wait(spike.animation:length("wiggle"))
			self.world:removeEntity(spike)

			local powerup = love.math.random(0, 100)
			if powerup > 90 then
				local t = love.math.random(1, 5)

				if t > 1 then
					table.insert(self.world.powerups, self.world:addEntity(require("assets.entities.item-hp")(position)))
				else
					table.insert(self.world.powerups, self.world:addEntity(require("assets.entities.item-sp")(position)))
				end
			end
		end)
	end)

	-- Player animations
	_G.EVENT:listen("player idle", function()
		local anim = self.player.animation
		if anim.current_animation ~= "run_to_idle" and anim.current_animation ~= "idle" then
			anim:reset()
			anim:play("run_to_idle", function(self)
				self:reset()
				self:play("idle")
			end)
		end
	end)

	_G.EVENT:listen("player run", function()
		local anim = self.player.animation
		if anim.current_animation ~= "idle_to_run" and anim.current_animation ~= "run" then
			anim:reset()
			anim:play("idle_to_run", function(self)
				self:reset()
				self:play("run")
			end)
		end
	end)

	-- Player actions
	_G.EVENT:listen("pickup item", function(entity)
		self.player.items:append(entity.type)
		self.world:removeEntity(entity)

		for k, powerup in ipairs(self.world.powerups) do
			if powerup == entity then
				table.remove(self.world.powerups, k)
			end
		end
	end)

	_G.EVENT:listen("cycle item", function(direction)
		if not self.player.items:get() then return end

		if direction > 0 then
			self.player.items:prev()
		elseif direction < 0 then
			self.player.items:next()
		end
	end)

	_G.EVENT:listen("use item", function()
		self.player.animation:reset()
		self.player.animation:play("roll")

		local item = self.player.items:get()
		if item == "hp" then
			self.player.health = math.min(self.player.health + math.ceil(self.player.max_health * 0.4), self.player.max_health)
		elseif item == "sp" then
			self.player.infinidagger = 10
			self.player.stamina      = math.huge
		end
		self.player.items:remove()
	end)

	_G.EVENT:listen("player attack", function()
		self.player.animation:reset()
		self.player.animation:play("attack")
		self.player.anim_cooldown = self.player.animation:length("attack")
		self.player.stamina       = self.player.stamina - 0.10
	end)

	_G.EVENT:listen("player attack charge", function()
		self.player.animation:reset()
		self.player.animation:play("attack_charge")
		self.player.anim_cooldown = self.player.animation:length("attack_charge")
	end)

	_G.EVENT:listen("player attack heavy", function()
		self.player.animation:reset()
		self.player.animation:play("attack_heavy")
		self.player.anim_cooldown = self.player.animation:length("attack_heavy")
		self.player.stamina       = self.player.stamina - 0.25
		self.player.attack_charge = 0
	end)

	_G.EVENT:listen("player dodge", function(direction, back)
		self.player.animation:reset()
		self.player.stamina = self.player.stamina - 0.15

		if back then
			self.player.animation:play("dodge")
			self.player.anim_cooldown = self.player.animation:length("dodge")
		else
			self.player.animation:play("roll")
			self.player.anim_cooldown = self.player.animation:length("roll")
		end

		local dodge_to = {
			x = self.player.position.x + direction.x * 5,
			y = self.player.position.y + direction.y * 5,
			z = self.player.position.z + direction.z * 5
		}

		self.player.dodge_timer:tween(self.player.anim_cooldown, self.player.position, dodge_to, "out-quad")
	end)

	_G.EVENT:listen("take damage", function()
		self.player.animation:reset()
		self.player.animation:play("fall")
		self.player.anim_cooldown = self.player.animation:length("fall")
		self.player.iframes       = self.player.anim_cooldown * 2
		self.player.health        = math.max(self.player.health - love.math.random(2800, 3200), 0)

		local audio = load.sound("assets/sfx/player_attack_hit.wav")
		audio:setVolume(_G.PREFERENCES.sfx_volume)
		audio:play()

		if self.player.health <= 0 then
			timer.tween(0.5, self.overlay, {opacity=255})
			self.queue_cutscene = 7
			self.phase = 7
		end
	end)

	-- Boss actions
	_G.EVENT:listen("boss attack spike", function()
		self.boss.animation:reset()
		self.boss.animation:play("attack_spike")
		self.boss.anim_cooldown   = self.boss.animation:length("attack_spike")
		self.boss.attack_cooldown = self.boss.anim_cooldown + 1
	end)

	_G.EVENT:listen("boss attack stab", function()
		self.boss.animation:reset()
		self.boss.animation:play("attack_stab")
		self.boss.anim_cooldown   = self.boss.animation:length("attack_stab")
		self.boss.attack_cooldown = self.boss.anim_cooldown + 1
	end)

	_G.EVENT:listen("boss attack sweep", function()
		self.boss.animation:reset()
		self.boss.animation:play("attack_sweep")
		self.boss.anim_cooldown   = self.boss.animation:length("attack_sweep")
		self.boss.attack_cooldown = self.boss.anim_cooldown + 1
		self.boss.last_hit        = false
	end)

	_G.EVENT:listen("boss attack spin", function()
		self.boss.animation:reset()
		self.boss.animation:play("attack_spin")
		self.boss.anim_cooldown   = self.boss.animation:length("attack_spin")
		self.boss.attack_cooldown = self.boss.anim_cooldown + 1
		self.boss.last_hit        = false
	end)

	_G.EVENT:listen("boss walk", function()
		self.boss.animation:reset()
		self.boss.animation:play("walk")
		self.boss.anim_cooldown = self.boss.animation:length("walk")

		local to = {
			x = love.math.random(0, 32) - 16,
			y = love.math.random(0, 32) - 16,
			z = 0
		}

		local dist        = self.boss.position:dist(to)
		local duration    = dist / self.boss.speed
		local d2p         = cpml.vec3.normalize(cpml.vec3(), self.boss.position - to)
		local angle       = cpml.vec2(d2p.x, d2p.y):angle_to() - math.pi / 2
		self.boss.snap_to = cpml.quat.from_direction(d2p, cpml.vec3.unit_z) * cpml.quat.rotate(angle, cpml.vec3.unit_z)
		self.boss.walking = self.boss.timer:tween(duration, self.boss.position, to, "linear", function()
			self.boss.animation:play("idle")
			self.boss.timer:after(2, function()
				self.boss.walking = false
			end)
		end)
	end)

	_G.EVENT:listen("give damage", function(hit_position, hit_location)
		local phases = {
			function() return love.math.random(1, 9) end,
			function() return love.math.random(10, 99) end,
			function() return love.math.random(100, 999) end,
			function() return love.math.random(1000, 8999) end,
			function() return 9999 end
		}
		self.boss.iframes  = 1
		self.boss.health   = math.max(self.boss.health - 1, 0)
		self.big_numbers   = phases[self.boss.phase]()
		self.boss.tracking = true
		self.boss.snap_to  = self.player.position: clone()
		self.boss.target   = self.player

		if hit_location:sub(1, 8) == "tentacle" then
			self.boss.last_hit = "tentacle"
			return
		end

		if hit_location:sub(1, 4) == "tail" then
			self.boss.last_hit = "tail"
			return
		end

		if hit_location:sub(1, 4) == "foot" then
			self.boss.last_hit = "foot"
			return
		end

		if hit_location:sub(1, 4) == "knee" then
			self.boss.last_hit = "knee"
			return
		end
	end)

	self.phase = 0
end

function scene:leave()
	self.plane    = nil
	self.player   = nil
	self.boss     = nil
	self.renderer = nil

	self.world:clearEntities()
	self.world:clearSystems()
	self.world:refresh()
	self.world = nil

	_G.EVENT = require "talkback".new()

	love.mouse.setRelativeMode(false)
end

function scene:mousemoved(_, _, mx, my)
	if not self.cutscene then
		self.camera:rotate_xy(mx, my)
	end
end

function scene:wheelmoved(_, y)
	_G.EVENT:say("cycle item", y)
end

function scene:cutsceneExists(k)
	return require("assets.cutscenes")[tonumber(k)]
end

function scene:cutsceneStart(k)
	self.cutscene = require("assets.cutscenes")[tonumber(k)](self.camera,self.player,self.boss)
	self.player.animation:play("idle")
	self.boss.animation:play("idle")
	self.player.iframes           = math.huge
	self.boss.iframes             = math.huge
	self.camera.lock              = true
	self.player_controller.active = false
	self.ai.active                = false
end

function scene:keypressed(k)
	if k == "escape" then
		_G.SCENE.switch(require "scenes.main-menu")
	end
	if not self.cutscene and self:cutsceneExists(k) then
		self.queue_cutscene = tonumber(k)
	end
	if k == "f4" and _G.FLAGS.debug_mode then
		self.renderer.capsule_debug = not self.renderer.capsule_debug
	end
end

function scene:update(dt)
	-- Process cooldowns
	timer.update(dt)
	self.player.dodge_timer:update(dt)
	self.player.iframes       = math.max(self.player.iframes - dt, 0)
	self.player.infinidagger  = math.max(self.player.infinidagger - dt, 0)
	self.player.anim_cooldown = math.max(self.player.anim_cooldown - dt, 0)
	self.boss.iframes         = math.max(self.boss.iframes - dt, 0)
	self.boss.anim_cooldown   = math.max(self.boss.anim_cooldown - dt, 0)
	self.boss.attack_cooldown = math.max(self.boss.attack_cooldown - dt, 0)
	self.world.cat.meow       = math.max(self.world.cat.meow - dt, 0)

	-- Cutscene stuff
	if self.phase == 0 and not self.queue_cutscene then
		self.queue_cutscene = 1
		self.phase = 1
	elseif self.phase == 1 and not self.queue_cutscene and self.boss.health <= 49 then
		self.queue_cutscene = 2
		self.phase = 2
	elseif self.phase == 2 and not self.queue_cutscene and self.boss.health <= 33 then
		self.queue_cutscene = 3
		self.phase = 3
	elseif self.phase == 3 and not self.queue_cutscene and self.boss.health <= 17 then
		self.queue_cutscene = 4
		self.phase = 4
	elseif self.phase == 4 and not self.queue_cutscene and self.boss.health <= 1 then
		self.queue_cutscene = 5
		self.phase = 5
	elseif self.phase == 5 and not self.queue_cutscene and self.boss.health <= 0 then
		self.queue_cutscene = 6
		self.phase = 6
		self.world:removeEntity(self.boss)
	end

	-- TODO: stamina regen should be on a longer timer than the anim cooldown
	if self.player.anim_cooldown == 0 and self.player.infinidagger == 0 then
		self.player.stamina = math.min(self.player.stamina + dt * 0.15, 1)
	end

	self.world:update(dt)
	if self.cutscene then
		self.cutscene:update(dt)
		if self.cutscene:isDone() then
			self.player.iframes           = 0
			self.boss.iframes             = 0
			self.cutscene                 = nil
			self.camera.lock              = false
			self.player_controller.active = true
			self.ai.active                = true

			if self.phase == 6 then
				self.victory = true
			elseif self.phase == 7 then
				self.dead = true
			end
		end
	end

	if self.queue_cutscene then
		self:cutsceneStart(self.queue_cutscene)
		self.queue_cutscene = nil
	end

	if self.victory or self.dead then
		_G.SCENE.switch(require("scenes.credits")())
	end
end

function scene:draw()
	self.renderer:draw()

	--== User Interface ==--

	-- Health Bar
	local hp = {
		bw = 304,
		bh = 14,
		tw = 300,
		th = 10,
		rw = math.max(math.ceil(self.player.health / self.player.max_health * 300), 0),
		rh = 10
	}

	love.graphics.setColor(255, 255, 255)
	love.graphics.rectangle("fill", anchor:center() - 152, anchor:top() + 30, hp.bw, hp.bh)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", anchor:center() - 150, anchor:top() + 32, hp.tw, hp.th)
	love.graphics.setColor(200, 0, 0)
	love.graphics.rectangle("fill", anchor:center() - 150, anchor:top() + 32, hp.rw, hp.rh)

	-- Stamina Bar
	local sp = {
		bw = 304,
		bh = 14,
		tw = 300,
		th = 10,
		rw = math.min(math.max(math.ceil(self.player.stamina * 300), 0), 300),
		rh = 10
	}

	love.graphics.setColor(255, 255, 255)
	love.graphics.rectangle("fill", anchor:center() - 152, anchor:top() + 42, sp.bw, sp.bh)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", anchor:center() - 150, anchor:top() + 44, sp.tw, sp.th)
	love.graphics.setColor(0, 200, 200)
	love.graphics.rectangle("fill", anchor:center() - 150, anchor:top() + 44, sp.rw, sp.rh)

	-- Selected Item
	local item = self.player.items:get()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(self.icons[item] or self.icons.na, anchor:center() + 162, anchor:top() + 30, 0, 0.5, 0.5)

	-- Boss Health Bar
	local bp = {
		bw = 604,
		bh = 20,
		tw = 600,
		th = 16,
		rw = math.max(math.ceil(self.boss.health / self.boss.max_health * 600), 0),
		rh = 16
	}

	love.graphics.setColor(255, 255, 255)
	love.graphics.rectangle("fill", anchor:center_x() - 300, anchor:top(), bp.bw, bp.bh)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", anchor:center_x() - 298, anchor:top() + 2, bp.tw, bp.th)
	love.graphics.setColor(200, 0, 200)
	love.graphics.rectangle("fill", anchor:center_x() - 298, anchor:top() + 2, bp.rw, bp.rh)

	if self.overlay.opacity > 0 then
		love.graphics.setColor(0, 0, 0, self.overlay.opacity)
		local w, h = love.graphics.getDimensions()
		love.graphics.rectangle("fill", 0, 0, w, h)
	end

	love.graphics.setColor(255, 255, 255, 255)
	if self.cutscene then
		self.cutscene:draw()
	end
end

return scene

end
