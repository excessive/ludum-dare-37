return function()
	local cpml    = require "cpml"
	local tactile = require "tactile"
	local tiny    = require "tiny"

	local system = tiny.processingSystem {
		filter   = tiny.requireAll("possessed"),
		paused   = false,
		deadzone = 0.25
	}

	local function toggle_mouse(self)
		-- love.mouse.setVisible(not love.mouse.isVisible())
		love.mouse.setRelativeMode(not love.mouse.getRelativeMode())

		if self.paused then
			local w, h = love.graphics.getDimensions()
			love.mouse.setPosition(w/2, h/2)
		end
	end

	local function register_gamepad(input, id)
		local gb = tactile.gamepadButtons
		local ga = tactile.gamepadAxis

		input.move_x = input.move_x:addAxis(ga(id, "leftx"))
		input.move_y = input.move_y:addAxis(ga(id, "lefty"))

		-- Camera
		input.camera_x = input.camera_x:addAxis(ga(id, "rightx"))
		input.camera_y = input.camera_y:addAxis(ga(id, "righty"))

		-- Actions
		input.attack          = input.attack:addButton(gb(id, "a"))
		input.dodge           = input.dodge:addButton(gb(id, "b"))
		input.use_item        = input.use_item:addButton(gb(id, "y"))
		input.cycle_item_up   = input.cycle_item_up:addButton(gb(id, "leftshoulder"))
		input.cycle_item_down = input.cycle_item_down:addButton(gb(id, "rightshoulder"))
		input.pause           = input.pause:addButton(gb(id, "start"))

		-- Menu
		input.menu_back   = input.menu_back:addButton(gb(id, "b"))
		input.menu_action = input.menu_action:addButton(gb(id, "a"))
		input.menu_up     = input.menu_up:addButton(gb(id, "dpup"))
		input.menu_down   = input.menu_down:addButton(gb(id, "dpdown"))
		input.menu_left   = input.menu_left:addButton(gb(id, "dpleft"))
		input.menu_right  = input.menu_right:addButton(gb(id, "dpright"))
	end

	function system:onAddToWorld()
		-- Shorthand functions
		-- Define inputs
		local k = tactile.keys
		local m = function(button)
			return function() return love.mouse.isDown(button) end
		end

		self.input = {
			-- Move
			move_x = tactile.newControl():addButtonPair(k("a", "left"), k("d", "right")),
			move_y = tactile.newControl():addButtonPair(k("w", "up"), k("s", "down")),

			-- Camera
			camera_x = tactile.newControl(),
			camera_y = tactile.newControl(),

			-- Actions
			attack          = tactile.newControl():addButton(k("z", "k")):addButton(m(1)),
			dodge           = tactile.newControl():addButton(k("x", "l")):addButton(m(2)),
			use_item        = tactile.newControl():addButton(k("return", "space")):addButton(m(3)),
			cycle_item_up   = tactile.newControl():addButton(k("kp-", "q")),
			cycle_item_down = tactile.newControl():addButton(k("kp+", "e")),
			pause           = tactile.newControl():addButton(k("p")),

			-- Menu
			menu_back   = tactile.newControl():addButton(k("escape")),
			menu_action = tactile.newControl():addButton(k("return")),
			menu_up     = tactile.newControl():addButton(k("up", "w")),
			menu_down   = tactile.newControl():addButton(k("down", "s")),
			menu_left   = tactile.newControl():addButton(k("left", "a")),
			menu_right  = tactile.newControl():addButton(k("right", "d"))
		}

		local sticks = love.joystick.getJoysticks()
		for i, js in ipairs(sticks) do
			if js:isGamepad() then
				register_gamepad(self.input, i)
			end
		end

		-- fuck off I'll deadzone this myself
		self.input.move_x.deadzone = self.deadzone
		self.input.move_y.deadzone = self.deadzone
	end

	function system:onAdd(entity)
		entity.orientation_offset = cpml.quat(0, 0, 0, 1)
	end

	function system:process(entity, dt)
		-- Ignore all input if console is open
		if _G.CONSOLE and _G.CONSOLE.visible then
			return
		end

		-- Process input
		for _, i in pairs(self.input) do
			i:update()
		end

		--== Menu ==--

		if self.input.pause:pressed() then
			toggle_mouse(self)
			self.paused = not self.paused
		end

		-- If game is paused, interact with menu instead
		if self.paused then
			local menu_input = {
				up     = self.input.menu_up:pressed(),
				down   = self.input.menu_down:pressed(),
				left   = self.input.menu_left:pressed(),
				right  = self.input.menu_right:pressed(),
				action = self.input.menu_action:pressed(),
				back   = self.input.menu_back:pressed()
			}

			_G.EVENT:say("menu input", menu_input)
			return
		end

		-- Check controls
		local attack          = self.input.attack:pressed()
		local attack_charge   = self.input.attack:isDown()
		local attack_heavy    = self.input.attack:released()
		local dodge           = self.input.dodge:pressed()
		local cycle_item_up   = self.input.cycle_item_up:pressed()
		local cycle_item_down = self.input.cycle_item_down:pressed()
		local use_item        = self.input.use_item:pressed()
		local move_x          = self.input.move_x:getValue()
		local move_y          = self.input.move_y:getValue()
		local camera_x        = self.input.camera_x:getValue()
		local camera_y        = self.input.camera_y:getValue()

		--== Camera ==--

		local function sign(v)
			return v > 0 and 1 or -1
		end
		camera_x = (camera_x^2) * sign(camera_x)
		camera_y = (camera_y^2) * sign(camera_y)
		self.camera:rotate_xy(camera_x*20, camera_y*10)

		--== Movement ==--

		local move        = cpml.vec3(move_x, -move_y, 0)
		local move_len    = move:len()
		local snap_cancel = false

		-- Each axis had a deadzone, but we also want a little more overall.
		if move_len < self.deadzone or attack_charge then
			move.x = 0
			move.y = 0
			move_len = 0
		elseif move_len > 1 then
			-- normalize
			move = move / move_len
		end

		--== Orientation ==--

		local angle = cpml.vec2(move.x, move.y):angle_to() + math.pi / 2

		-- Change direction player is facing, as long as they aren't mid-attack
		if (move.x ~= 0 or move.y ~= 0) and entity.anim_cooldown == 0 then
			_G.EVENT:say("player run")
			local snap_to = self.camera.orientation:clone() * cpml.quat.rotate(angle, cpml.vec3.unit_z)

			if entity.snap_to then
				-- Directions
				local current = entity.snap_to * cpml.vec3.unit_y
				local next    = snap_to * cpml.vec3.unit_y
				local from    = current:dot(self.camera.direction)
				local to      = next:dot(self.camera.direction)

				-- If you move in the opposite direction, snap to end of slerp
				if from ~= to and math.abs(from) - math.abs(to) == 0 then
					entity.orientation = entity.snap_to:clone()
				end
			end

			entity.snap_to = snap_to
			entity.slerp   = 0
		elseif entity.anim_cooldown == 0 then
			_G.EVENT:say("player idle")
		end

		if entity.snap_to and entity.anim_cooldown == 0 then
			cpml.quat.slerp(entity.orientation, entity.orientation, entity.snap_to, 8*dt*2)
			entity.orientation.x = 0
			entity.orientation.y = 0
			cpml.quat.normalize(entity.orientation, entity.orientation)
			entity.slerp         = entity.slerp + dt

			if entity.slerp > 1/2 then
				entity.snap_to = nil
				entity.slerp   = 0
			end
		end

		local charge_threshold = 0.5

		-- Charge up a heavy attack!
		if entity.anim_cooldown == 0 and attack_charge then
			entity.attack_charge = math.min(entity.attack_charge + dt, charge_threshold)
		end

		-- Cancel heavy attack if charge isn't full
		if attack_heavy and entity.attack_charge < charge_threshold then
			entity.attack_charge = 0
		end

		-- Cancel snap if performing actions
		if attack or (attack_heavy and entity.attack_charge == charge_threshold) or dodge then
			snap_cancel = true
		end

		--- cancel the orientation transition if needed
		if snap_cancel and entity.snap_to then
			entity.orientation   = entity.snap_to:clone()
			entity.orientation.x = 0
			entity.orientation.y = 0
			entity.orientation:normalize(entity.orientation)
			entity.snap_to       = nil
			entity.slerp         = 0
		end

		entity.direction = entity.orientation * -cpml.vec3.unit_y

		-- Prevent the movement animation from moving you along the wrong
		-- orientation (we want to only move how the player is trying to)
		-- This means no more dancing forward!
		local move_orientation = self.camera.orientation:clone() * cpml.quat.rotate(angle, cpml.vec3.unit_z)
		if entity.lock_velocity and entity.snap_to then
			move_orientation = entity.snap_to
		end
		move_orientation.x = 0
		move_orientation.y = 0
		move_orientation:normalize(move_orientation)
		local move_direction = move_orientation * -cpml.vec3.unit_y

		if entity.anim_cooldown == 0 then
			local speed_multiplier = entity.stamina > 0 and 1 or 0.75
			entity.velocity = (move_direction * math.min(move_len, 1)) * entity.speed * speed_multiplier * dt
		end

		if move_len == 0 then
			move_direction.x = self.camera.direction.x
			move_direction.y = self.camera.direction.y
			move_direction.z = 0
			move_direction:normalize(move_direction)
		end

		--== Actions ==--

		if cycle_item_up then
			_G.EVENT:say("cycle item", 1)
		end

		if cycle_item_down then
			_G.EVENT:say("cycle item", -1)
		end

		if entity.anim_cooldown == 0 and use_item then
			_G.EVENT:say("use item")
		end

		if entity.anim_cooldown == 0 and entity.stamina > 0 and attack then
			_G.EVENT:say("player attack", move_direction)
		end

		if entity.anim_cooldown == 0 and attack_heavy then
			_G.EVENT:say("player attack charge")
		end

		if entity.anim_cooldown == 0 and entity.stamina > 0 and attack_heavy and entity.attack_charge == charge_threshold then
			_G.EVENT:say("player attack heavy", move_direction)
		end

		if entity.anim_cooldown == 0 and entity.stamina > 0 and dodge then
			entity.orientation = move_orientation:clone()
			local back = false
			if move_len == 0 then
				back = true
				move_direction:scale(move_direction, -1)
				entity.orientation = entity.orientation * cpml.quat.rotate(math.pi / 2, cpml.vec3.unit_z)
			end
			_G.EVENT:say("player dodge", move_direction, back)
		end

		local len = entity.position:len()
		local stage_radius = 18
		if len > stage_radius then
			entity.position = entity.position / len * stage_radius
		end
		entity.position.z = 0
	end

	return system
end