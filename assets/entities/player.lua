local cpml       = require "cpml"
local timer      = require "timer"
local load       = require "utils.load-files"
local ringbuffer = require "utils.ringbuffer"

return function()
	local player = {
		name          = "Player",
		visible       = true,
		possessed     = true,
		dynamic       = true,
		blob_shadow   = true,
		attacking     = false,
		mesh          = load.model("assets/models/player.iqm"),
		animation     = load.anims("assets/models/player.iqm"),
		markers       = load.markers("assets/markers/player.lua"),
		anim_cooldown = 0,
		iframes       = 0,
		stunned       = 0,
		infinidagger  = 0,
		slerp         = 0,
		attack_charge = 0,
		dodge_timer   = timer.new(),
		speed         = 5,
		stamina       = 1,
		max_stamina   = 1,
		health        = 9999,
		max_health    = 9999,
		items         = ringbuffer(),
		snap_to       = cpml.quat(0, 0, 0, 1),
		position      = cpml.vec3(-17, -3, 0),
		orientation   = cpml.quat.rotate(math.pi, cpml.vec3.unit_z),
		scale         = cpml.vec3(1, 1, 1),
		radius        = cpml.vec3(1, 1, 1),
		velocity      = cpml.vec3(0, 0, 0),
		matrix        = cpml.mat4(),
		capsules      = {
			-- would be cool to have specific hit boxes instead of a single capsule
			-- but this is ludum dare and ain't nobody got time for that
			hitbox = {
				["root"] = { radius = 0.2, a = cpml.vec3(), b = cpml.vec3(), length = -1.3 }
			},
			weapon = {
				["sword"] = { radius = 0.25, a = cpml.vec3(), b = cpml.vec3(), length = 1.4 }
			}
		}
	}
	player.direction = player.orientation * cpml.vec3.unit_y
	return player
end
