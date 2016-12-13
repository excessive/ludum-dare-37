return function()
	local tiny = require "tiny"

	return tiny.processingSystem {
		name   = "Animation",
		filter = tiny.requireAll("animation"),
		onRemoveFromWorld = function(self)
			-- self.world = nil
		end,
		process = function(self, entity, dt)
			if entity.animation then
				entity.animation:update(dt)

				if entity.markers then
					local ca = entity.animation.current_animation or {}
					local cf = entity.animation.current_frame     or 1
					local cm = entity.animation.current_marker    or 0

					if cf ~= cm then
						entity.animation.current_marker = cf
						local marker = entity.markers[ca] and entity.markers[ca][cf] or ""
						_G.EVENT:say("anim " .. marker, entity)
					end
				end
			end
		end
	}
end