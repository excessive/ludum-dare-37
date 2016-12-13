local lvfx = {}
local lvfx_view = {}
local lvfx_view_mt = {
	__index = lvfx_view
}

local dprint = console and console.d or print

local l3d
do
	local ok
	ok, l3d = pcall(require, "love3d")
	if not ok then
		l3d = nil
		dprint("LOVE3D not found, 3D features will not work.")
	end
end

local tclear = table.clear or function(t)
	for k, _ in pairs(t) do
		t[k] = nil
	end
end

function lvfx_view:setCanvas(_canvas)
	self._canvas = _canvas or false
end

function lvfx_view:setScissor(_x, _y, _w, _h)
	if not _x then
		self._scissor = false
		return
	end
	self._scissor = {
		x = _x,
		y = _y,
		w = _w,
		h = _h
	}
end

function lvfx_view:setDepthClear(clear)
	self._depth_clear = clear or false
end

function lvfx_view:setClear(_r, _g, _b, _a)
	local r, g, b, a = _r, _g, _b, _a
	if type(_r) == "table" and #_r >= 3 then
		r, g, b, a = _r[1], _r[2], _r[3], _r[4]
	end
	self._clear = { r, g, b, a or 1.0 }
end

function lvfx_view:setDepthTest(test, write)
	self._depth_test  = test
	self._depth_write = (write == nil) and true or write
end

function lvfx_view:setCulling(face)
	self._culling = face or false
end

function lvfx_view:getWidth()
	return self._canvas and self._canvas:getWidth() or love.graphics.getWidth()
end

function lvfx_view:getHeight()
	return self._canvas and self._canvas:getHeight() or love.graphics.getHeight()
end

function lvfx_view:getDimensions()
	return self:getWidth(), self:getHeight()
end

function lvfx.newView()
	local t = {
		_clear   = false,
		_scissor = false,
		_canvas  = false,
		_depth_test  = false,
		_depth_write = true,
		_depth_clear = false,
		_culling     = false,
		_draws   = {}
	}
	return setmetatable(t, lvfx_view_mt)
end

local lvfx_shader = {}
local lvfx_shader_mt = {
	__index = lvfx_shader
}

function lvfx.newShader(vertex, fragment, raw)
	if l3d and raw then
		local t = {
			_handle = l3d.new_shader_raw("2.1", vertex, fragment)
		}
		return setmetatable(t, lvfx_shader_mt)
	end
	local t = {
		_handle = love.graphics.newShader(vertex, fragment)
	}
	return setmetatable(t, lvfx_shader_mt)
end

local lvfx_draw = {
	mesh        = false,
	mesh_params = false,
	fn          = false,
	fn_params   = false,
	color       = false,
	shader      = false
}

local lvfx_uniform = {}
local lvfx_uniform_mt = {
	__index = lvfx_uniform
}

-- uniforms updated this frame
local uniforms = {}
function lvfx_uniform:set(...)
	self._data = { ... }
	table.insert(uniforms, self)
	uniforms[self._name] = #uniforms
end

function lvfx.newUniform(name, int)
	local t = {
		_name = assert(name, "Uniform name is required"),
		_data = false,
		_int  = int or false
	}
	return setmetatable(t, lvfx_uniform_mt)
end

-- quick shallow copy for submissions
local draw_keys = {}
for k, v in pairs(lvfx_draw) do
	table.insert(draw_keys, k)
end
local function copy_draw(t)
	local clone = {}
	for _, k in ipairs(draw_keys) do
		clone[k] = t[k]
	end
	return clone
end
local state = setmetatable({}, lvfx_draw)

function lvfx.setColor(_r, _g, _b, _a)
	local r, g, b, a = _r, _g, _b, _a
	if type(_r) == "table" and #_r >= 3 then
		r, g, b, a = _r[1], _r[2], _r[3], _r[4]
	end
	state.color = { r, g, b, a or 1.0 }
end

function lvfx.setShader(shader)
	assert(getmetatable(shader) == lvfx_shader_mt)
	state.shader = shader
end

function lvfx.setDraw(mesh, params)
	if type(mesh) == "function" then
		state.fn = mesh
		if params then
			state.fn_params = params
		end
		return
	end

	state.mesh = mesh
	if params then
		state.mesh_params = params
	end
end

local lg_fns = {
	circle    = love.graphics.circle,
	draw      = love.graphics.draw,
	rectangle = love.graphics.rectangle
}

for k, v in pairs(lg_fns) do
	lvfx[k] = function(...)
		lvfx.setDraw(v, {...})
	end
end

function lvfx.submit(view, retain)
	if view then
		assert(getmetatable(view) == lvfx_view_mt)
		local add_state = copy_draw(state)
		add_state.uniforms = {}

		-- this can probably be optimized... with a lot of uniform updates
		-- this could get slow.
		local found = {}
		for i=#uniforms, 1, -1 do
			local uniform = uniforms[i]
			if not add_state.shader then
				break
			end
			if add_state.shader._handle:getExternVariable(uniform._name) then
				-- only record the last update for a given uniform
				if not found[uniform._name] then
					found[uniform._name] = true
					table.insert(add_state.uniforms, {
						_name = uniform._name,
						_data = {unpack(uniform._data)}
					})
				end
			end
		end
		table.insert(view._draws, add_state)
	end
	if not retain then
		state = setmetatable({}, lvfx_draw)
	end
end

-- submit a dummy draw, so that clears and such will happen.
function lvfx.touch(view)
	-- TODO: count this in draw stats
	lvfx.submit(view)
end

local fix_love10_colors = function(t) return t end
if select(2, love.getVersion()) <= 10 then
	fix_love10_colors = function(t)
		return { t[1] * 255, t[2] * 255, t[3] * 255, t[4] * 255 }
	end
end

function lvfx.frame(views)
	if l3d then
		l3d.set_depth_write(true)
		l3d.clear(false, true)
	end

	local lg = love.graphics
	lg.setColor(fix_love10_colors { 1, 1, 1, 1 })
	for _, view in ipairs(views) do
		assert(getmetatable(view) == lvfx_view_mt)
		local use_shadow_map = l3d and view._canvas and view._canvas.shadow_map
		if use_shadow_map then
			l3d.bind_shadow_map(view._canvas)
		else
			lg.setCanvas(view._canvas or nil)
		end
		-- skip views with no draws
		if #view._draws == 0 then
			goto continue
		end
		if view._scissor then
			local rect = view._scissor
			lg.setScissor(rect.x, rect.y, rect.w, rect.h)
		else
			lg.setScissor()
		end
		if view._clear then
			lg.clear(fix_love10_colors(view._clear))
		end
		if l3d then
			l3d.set_culling(view._culling)
			l3d.set_depth_write(view._depth_write)
			l3d.set_depth_test(view._depth_test)
			l3d.clear(false, view._depth_clear)
			-- alpha blending and depth buffers don't play nice.
			if view._depth_write and view._depth_test then
				love.graphics.setBlendMode("alpha", "premultiplied")
			else
				love.graphics.setBlendMode("alpha")
			end
		end
		for _, draw in ipairs(view._draws) do
			lg.push("all")
			if draw.color then
				lg.setColor(fix_love10_colors(draw.color))
			end
			lg.setShader(draw.shader and draw.shader._handle or nil)
			if draw.shader then
				for _, uniform in ipairs(draw.uniforms) do
					local shader = draw.shader._handle
					if type(uniform._data[1]) == "table" and uniform._data[1].shadow_map then
						l3d.bind_shadow_texture(uniform._data[1], draw.shader, uniform._name)
					elseif uniform._int then
						shader:sendInt(uniform._name, unpack(uniform._data))
					else
						shader:send(uniform._name, unpack(uniform._data))
					end
				end
			end
			if draw.fn then
				draw.fn(unpack(draw.fn_params or {}))
			elseif draw.mesh then
				lg.draw(draw.mesh, unpack(draw.mesh_params or {}))
			end
			if use_shadow_map then
				l3d.bind_shadow_map()
			end
			lg.pop()
		end
		tclear(view._draws)
		::continue::
	end
	love.graphics.setBlendMode("alpha")
	lg.setCanvas()
	lg.setScissor()
	if l3d then
		l3d.set_culling()
		l3d.set_depth_write()
		l3d.set_depth_test()
	end

	-- clear hanging submit state, so next frame is clean
	lvfx.submit(false)
	tclear(uniforms)
end

return lvfx
