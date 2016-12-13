local anim9   = require "anim9"
local cpml    = require "cpml"
local iqm     = require "iqm"
local memoize = require "memoize"
local load    = {}

local _lanim = memoize(function(filename)
	return iqm.load_anims(filename)
end)

load.model = memoize(function(filename, actor, invert)
	local m = iqm.load(filename, actor, invert)
	if actor then
		for _, triangle in ipairs(m.triangles) do
			triangle[1].position = cpml.vec3(triangle[1].position)
			triangle[2].position = cpml.vec3(triangle[2].position)
			triangle[3].position = cpml.vec3(triangle[3].position)
		end
	end
	return m
end)

load.anims = function(filename)
	return anim9(_lanim(filename))
end

load.markers = memoize(function(filename)
	return love.filesystem.load(filename)()
end)

load.sound = memoize(function(filename)
	return love.audio.newSource(filename)
end)

load.font = memoize(function(filename, size)
	return love.graphics.newFont(filename, size)
end)

load.texture = memoize(function(filename, flags)
	print(string.format("Loading texture %s", filename))
	local texture = love.graphics.newImage(filename, flags or { mipmaps = true })
	texture:setFilter("linear", "linear", 16)
	return texture
end)

load.map = memoize(function(filename, world)
	local map = love.filesystem.load(filename)()

	for _, data in ipairs(map.objects) do
		local entity = {}

		for k, v in pairs(data) do
			entity[k] = v
		end

		entity.position	 = cpml.vec3(entity.position)
		if entity.path then
			entity.orientation = cpml.quat(entity.orientation)
			entity.scale		 = cpml.vec3(entity.scale)
			entity.mesh        = load.model(entity.path, false)
		elseif entity.sound then
			entity.sound = load.sound(entity.sound)
		end

		world:addEntity(entity)

		love.event.pump()
		collectgarbage "step"
	end

	return true
end)

return load
