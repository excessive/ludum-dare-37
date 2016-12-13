local cpml = require "cpml"
local load = require "utils.load-files"

return function()
	local t = {
		name        = "Meow",
		visible     = true,
		position    = cpml.vec3(-21, -3.25, 0.2),
		orientation = cpml.quat.rotate(2, cpml.vec3.unit_z),
		scale       = cpml.vec3(1, 1, 1),
		radius      = 1,
		meow        = 20,
		audio       = love.audio.newSource("assets/sfx/opal.wav"),
		mesh        = load.model("assets/models/cat.iqm", false)
	}
	t.audio:setRelative(true)
	t.audio:setVolume(_G.PREFERENCES.sfx_volume)
	return t
end
