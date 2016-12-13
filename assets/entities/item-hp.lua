local cpml = require "cpml"
local load = require "utils.load-files"

return function(position)
	return {
		name        = "HP Power Up",
		visible     = true,
		type        = "hp",
		blob_shadow = true,
		position    = position,
		scale       = cpml.vec3(1, 1, 1),
		radius      = 1,
		mesh        = load.model("assets/models/flask.iqm", false),
		color       = { 200/255, 0, 0 }
	}
end
