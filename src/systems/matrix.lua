return function()
	local tiny = require "tiny"
	local cpml = require "cpml"

	return tiny.processingSystem {
		filter = tiny.requireAny("position", "orientation", "scale"),
		process = function(_, entity, _)
			-- update matrices for rendering and collision point updates
			local model = cpml.mat4()
			if entity.position then
				model:translate(model, entity.position)
			end
			if entity.orientation then
				model:rotate(model, entity.orientation)
			end
			if entity.scale then
				model:scale(model, entity.scale)
			end
			entity.matrix = model
		end
	}
end
