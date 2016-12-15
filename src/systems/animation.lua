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
					for _, anim in ipairs(entity.animation.active) do
						if anim.frame ~= anim.marker then
							anim.marker = anim.frame
							local marker = entity.markers[anim.name] and entity.markers[anim.name][anim.frame] or false
							if marker then
								_G.EVENT:say("anim " .. marker, entity)
							end
						end
					end
				end
			end
		end
	}
end