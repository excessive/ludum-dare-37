local anchor   = require "anchor"
local i18n     = require "i18n"
local memoize  = require "memoize"
local cpml     = require "cpml"
local scroller = require "utils.scroller"
local timer    = require "timer"
local get_font = memoize(love.graphics.newFont)
local topx     = love.window.toPixels
local scene    = {}

_G.MUSIC = {
	background = love.audio.newSource("assets/music/WiiiUUuu.ogg"),
	win = love.audio.newSource("assets/music/Sea Man and Swallow.ogg"),
	lose = love.audio.newSource("assets/music/Death to the Disbeliever.ogg"),
}
_G.MUSIC.background:setLooping(true)

local tiny = require "tiny"
local world = tiny.world()

local load     = require "utils.load-files"
local camera   = require "camera"
local renderer = require("systems.render")()
renderer.camera = camera {
	position = cpml.vec3(20, 20, 10),
	target   = cpml.vec3(0, 0, 0)
}
world:add(renderer)
world:add {
	mesh = load.model "assets/models/sky.iqm",
	color = { 0.25, 0.25, 0.25 },
	visible = true,
	sky = true,
	no_shadow = true
}
world:add {
	color = { 0.25, 0.25, 0.25 },
	mesh = load.model "assets/models/StagePolish0.11.iqm",
	textures = {
		Stage      = "assets/textures/Stage.png",
		Grid       = "assets/textures/grid.png",
		Rock       = "assets/textures/rock.png",
		Water      = "assets/textures/Water.png",
		Wood       = "assets/textures/wood.png",
		Plant      = "assets/textures/grassThing.png",
	},
	visible = true
}
world:refresh()

function scene:enter()
	love.audio.setDistanceModel("none")
	love.audio.setVolume(_G.PREFERENCES.master_volume)

	_G.MUSIC.background:stop()
	_G.MUSIC.win:stop()
	_G.MUSIC.lose:stop()

	for _, v in pairs(_G.MUSIC) do
		v:setVolume(_G.PREFERENCES.bgm_volume)
	end

	-- Prepare language
	self.language = i18n()
	self.language:set_fallback("en")
	self.language:set_locale(_G.PREFERENCES.language)
	self.language:load(string.format("assets/locales/%s.lua", _G.PREFERENCES.language))

	local items = {
		{ label = "new-game", action = function()
			_G.SCENE.switch(require("scenes.play")())
		end },
		{ label = "options", action = function()
			_G.SCENE.switch(require("scenes.options-menu")())
		end },
		{ label = "credits", action = function()
			_G.SCENE.switch(require("scenes.credits")())
		end },
		{ label = "exit", action = function()
			love.event.quit()
		end }
	}

	local transform = function(self, offset, count, index)
		self.x = 0
		self.y = math.floor(offset * topx(40))
	end

	self.scroller = scroller(items, {
		fixed        = true,
		size         = { w = topx(200), h = topx(40) },
		sounds       = {
			prev   = love.audio.newSource("assets/sfx/bloop.wav"),
			next   = love.audio.newSource("assets/sfx/bloop.wav"),
			select = love.audio.newSource("assets/sfx/bloop.wav")
		},
		transform_fn = transform,
		position_fn  = function()
			return anchor:left() + topx(100), anchor:center_y() - topx(50)
		end
	})

	for _, v in pairs(self.scroller.sounds) do
		v:setVolume(_G.PREFERENCES.sfx_volume)
	end

	self.logo = love.graphics.newImage("assets/textures/logo.png")
	love.graphics.setBackgroundColor(0, 0, 0)

	self.state = {
		opacity = 1
	}
	self.timer = timer.new()
	self.timer:tween(2.0, self.state, { opacity = 0 }, 'out-quad')
end

function scene:go()
	local item = self.scroller:get()
	if item.action then
		item.action()
		return
	end
	error "No action for the current item"
end

function scene:keypressed(k)
	if k == "up" then
		self.scroller:prev()
		return
	end
	if k == "down" then
		self.scroller:next()
		return
	end
	if k == "return" then
		self:go()
		return
	end
	if k == "escape" then
		_G.SCENE.switch(require("scenes.splash")())
		return
	end
end

function scene:touchpressed(id, x, y)
	self:mousepressed(x, y, 1)
end

function scene:touchreleased(id, x, y)
	self:mousereleased(x, y, 1)
end

function scene:mousepressed(x, y, b)
	if self.scroller:hit(x, y, b == 1) then
		self.ready = self.scroller:get()
	end
end

function scene:mousereleased(x, y, b)
	if not self.ready then
		return
	end

	if self.scroller:hit(x, y, b == 1) then
		if self.ready == self.scroller:get() then
			self:go()
		end
	end
end

function scene:update(dt)
	self.timer:update(dt)
	self.scroller:hit(love.mouse.getPosition())
	self.scroller:update(dt)
	world:update(dt)
end

function scene:draw()
	love.graphics.setColor(255, 255, 255, 255)

	renderer:draw()

	-- Draw logo
	local x, y = anchor:left() + topx(100), anchor:center_y() - topx(150)
	local s = love.window.getPixelScale()
	love.graphics.draw(self.logo, x, y, 0, s, s)

	local font = get_font(topx(16))
	love.graphics.setFont(font)

	-- Draw highlight bar
	love.graphics.setColor(255, 60, 0, 50)
	love.graphics.rectangle("fill",
		self.scroller.cursor_data.x,
		self.scroller.cursor_data.y,
		self.scroller.size.w,
		self.scroller.size.h
	)

	-- Draw items
	love.graphics.setColor(255, 255, 255)
	for _, item in ipairs(self.scroller.data) do
		local text, duration, audio, fallback = self.language:get(item.label)
		love.graphics.print(text, item.x + topx(10), item.y + topx(10))
	end

	love.graphics.setColor(0, 0, 0, 255 * self.state.opacity)
	love.graphics.rectangle(
		"fill", 0, 0,
		love.graphics.getWidth(),
		love.graphics.getHeight()
	)
end

return scene
