local cpml  = require "cpml"
local timer = require "timer"
local load  = require "utils.load-files"

return function()
	return {
		name          = "Hentai-chan",
		visible       = true,
		dynamic       = true,
		blob_shadow   = true,
		attacking     = false,
		target        = false,
		scanning      = false,
		tracking      = false,
		walking       = false,
		spikes        = {},
		timer         = timer.new(),
		mesh          = load.model("assets/models/cthulhu.iqm"),
		animation     = load.anims("assets/models/cthulhu.iqm"),
		markers       = load.markers("assets/markers/cthulhu.lua"),
		slerp         = 0,
		anim_cooldown = 0,
		attack_cooldown = 0,
		iframes       = 0,
		stunned       = 0,
		speed         = 3.5,
		health        = 65, -- 16, 16, 16, 16, 1
		max_health    = 65,
		phase         = 1,
		snap_to       = false,
		position      = cpml.vec3(0, -3, 0),
		orientation   = cpml.quat.rotate(-math.pi/2, cpml.vec3.unit_z),
		scale         = cpml.vec3(1, 1, 1),
		velocity      = cpml.vec3(0, 0, 0),
		matrix        = cpml.mat4(),
		last_hit      = false,
		capsules      = {
			hitbox = {
				["knee.L"]               = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 2.0 },
				["knee.R"]               = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 2.0 },
				["foot.L"]               = { radius = 0.25, a = cpml.vec3(), b = cpml.vec3(), length = 1.6 },
				["foot.R"]               = { radius = 0.25, a = cpml.vec3(), b = cpml.vec3(), length = 1.6 },
				["tentacle.front.L.004"] = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 3.0 },
				["tentacle.front.R.004"] = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 3.0 },
				["tentacle.back.L.004"]  = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 3.0 },
				["tentacle.back.R.004"]  = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 3.0 },
				["tentacle.front.L.005"] = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 3.0 },
				["tentacle.front.R.005"] = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 3.0 },
				["tentacle.back.L.005"]  = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 3.0 },
				["tentacle.back.R.005"]  = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 3.0 },
				["tail.002"]             = { radius = 0.35, a = cpml.vec3(), b = cpml.vec3(), length = 2.0 },
				["tail.003"]             = { radius = 0.35, a = cpml.vec3(), b = cpml.vec3(), length = 2.0 },
				["tail.004"]             = { radius = 0.35, a = cpml.vec3(), b = cpml.vec3(), length = 2.0 },
				["tail.005"]             = { radius = 0.35, a = cpml.vec3(), b = cpml.vec3(), length = 2.0 },
				["tail.006"]             = { radius = 0.35, a = cpml.vec3(), b = cpml.vec3(), length = 2.0 },
				["tail.007"]             = { radius = 0.35, a = cpml.vec3(), b = cpml.vec3(), length = 2.0 }
			},
			weapon = {
				["foot.L"]               = { radius = 0.25, a = cpml.vec3(), b = cpml.vec3(), length = 1.6 },
				["foot.R"]               = { radius = 0.25, a = cpml.vec3(), b = cpml.vec3(), length = 1.6 },
				["tentacle.front.L.006"] = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 4.0 },
				["tentacle.front.R.006"] = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 4.0 },
				["tentacle.back.L.006"]  = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 4.0 },
				["tentacle.back.R.006"]  = { radius = 0.60, a = cpml.vec3(), b = cpml.vec3(), length = 4.0 },
				["tail.008"]             = { radius = 0.50, a = cpml.vec3(), b = cpml.vec3(), length = 2.5 }
			}
		}
	}
end
