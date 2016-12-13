local cpml = require "cpml"
local load = require "utils.load-files"

return function(position)
	return {
		name        = "SP Power Up",
		visible     = true,
		type        = "sp",
		blob_shadow = true,
		position    = position,
		scale       = cpml.vec3(1, 1, 1),
		radius      = 1,
		mesh        = load.model("assets/models/flask.iqm", false),
		color       = { 0, 200/255, 200/255 }
	}
end
