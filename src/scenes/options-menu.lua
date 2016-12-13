return function()

local anchor     = require "anchor"
local cpml       = require "cpml"
local i18n       = require "i18n"
local json       = require "dkjson"
local memoize    = require "memoize"
local ringbuffer = require "utils.ringbuffer"
local scroller   = require "utils.scroller"
local slider     = require "utils.slider"
local get_font   = memoize(love.graphics.newFont)
local topx       = love.window.toPixels
local scene      = {}

local tiny = require "tiny"
local world = tiny.world()

local load     = require "utils.load-files"
local camera   = require "camera"
local renderer = require("systems.render")()
renderer.camera = camera {
	position = cpml.vec3(20, 20, 20),
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
	local transform = function(self, offset, count, index)
		self.x = 0
		self.y = math.floor(offset * topx(40))
	end

	self.volume_slider = slider(0, 1, 0, 100)
	self.menu_selected = "main"

	-- Prepare language
	self.language = i18n()
	self.language:set_fallback("en")
	self.language:set_locale(_G.PREFERENCES.language)

	-- List of languages
	local languages = {}
	local files = love.filesystem.getDirectoryItems("assets/locales")
	for _, file in ipairs(files) do
		local name, ext = file:match("([^/]+)%.([^%.]+)$")

		if ext == "lua" then
			table.insert(languages, name)
			self.language:load(string.format("assets/locales/%s.lua", name))
		end
	end

	-- Select current language in buffer
	self.languages = ringbuffer(languages)
	while _G.PREFERENCES.language ~= self.languages:get() do
		self.languages:next()

		-- Cycled through all languages, preference is wrong, set to English
		if self.languages.current == 1 then
			_G.PREFERENCES.language = "en"
		end
	end

	local sounds = {
		prev   = love.audio.newSource("assets/sfx/bloop.wav"),
		next   = love.audio.newSource("assets/sfx/bloop.wav"),
		select = love.audio.newSource("assets/sfx/bloop.wav")
	}
	for _, v in pairs(sounds) do
		v:setVolume(_G.PREFERENCES.sfx_volume)
	end

	-- List of menus and their options
	self.menus = {
		main = {
			{ label = "graphics", i18n = true, action = function()
				self.menu_selected = "graphics"
			end },
			{ label = "audio", i18n = true, action = function()
				self.menu_selected = "audio"
			end },
			--{ label = "language", i18n = true, action = function()
			--	self.menu_selected = "language"
			--end },
			{ label = "reset-default", i18n = true, action = function()
				for k, v in pairs(_G.DEFAULT_PREFERENCES) do
					_G.PREFERENCES[k] = v
				end
			end },
			{ label = "", skip = true },
			{ label = "return-menu", i18n = true, action = function()
				_G.SCENE.switch(require "scenes.main-menu")
			end }
		},

		graphics = {
			{ label = "toggle-fullscreen", i18n = true, action = function()
				_G.PREFERENCES.fullscreen = not _G.PREFERENCES.fullscreen
				love.window.setFullscreen(_G.PREFERENCES.fullscreen)
			end },
			{ label = "", skip = true },
			{ label = "back", i18n = true, action = function()
				self.scroller:reset()
				self.menu_selected = "main"
			end }
		},

		audio = {
			{ label = "master-volume", i18n = true, skip = true },
			{
				label = "%0.0f%%", volume = "master",
				prev = function()
					_G.PREFERENCES.master_volume = cpml.utils.clamp(_G.PREFERENCES.master_volume - 0.05, 0, 1)
					love.audio.setVolume(_G.PREFERENCES.master_volume)
				end,
				next = function()
					_G.PREFERENCES.master_volume = cpml.utils.clamp(_G.PREFERENCES.master_volume + 0.05, 0, 1)
					love.audio.setVolume(_G.PREFERENCES.master_volume)
				end
			},
			{ label = "bgm-volume", i18n = true, skip = true },
			{
				label = "%0.0f%%", volume = "bgm",
				prev = function()
					_G.PREFERENCES.bgm_volume = cpml.utils.clamp(_G.PREFERENCES.bgm_volume - 0.05, 0, 1)
				end,
				next = function()
					_G.PREFERENCES.bgm_volume = cpml.utils.clamp(_G.PREFERENCES.bgm_volume + 0.05, 0, 1)
				end
			},
			{ label = "sfx-volume", i18n = true, skip = true },
			{
				label = "%0.0f%%", volume = "sfx",
				prev = function()
					_G.PREFERENCES.sfx_volume = cpml.utils.clamp(_G.PREFERENCES.sfx_volume - 0.05, 0, 1)
					for _, v in pairs(sounds) do
						v:setVolume(_G.PREFERENCES.sfx_volume)
					end
				end,
				next = function()
					_G.PREFERENCES.sfx_volume = cpml.utils.clamp(_G.PREFERENCES.sfx_volume + 0.05, 0, 1)
					for _, v in pairs(sounds) do
						v:setVolume(_G.PREFERENCES.sfx_volume)
					end
				end
			},
			{ label = "", skip = true },
			{ label = "back", i18n = true, action = function()
				self.scroller:reset()
				self.menu_selected = "main"
			end }
		},

		language = {
			{ label = "toggle-language", i18n = true, skip = true },
			{
				label = "%s", language = true,
				prev = function()
					self.language:set_locale(self.languages:prev())
					_G.PREFERENCES.language = self.language:get_locale()
				end,
				next = function()
					self.language:set_locale(self.languages:next())
					_G.PREFERENCES.language = self.language:get_locale()
				end
			},
			{ label = "", skip = true },
			{ label = "back", i18n = true, action = function()
				self.scroller:reset()
				self.menu_selected = "main"
			end }
		},
	}

	-- List of menu scrollers
	self.scrollers = {
		main = scroller(self.menus.main, {
			fixed        = true,
			size         = { w = topx(200), h = topx(40) },
			sounds       = sounds,
			transform_fn = transform,
			position_fn  = function()
				return anchor:left() + topx(100), anchor:center_y() - topx(50)
			end
		}),

		graphics = scroller(self.menus.graphics, {
			fixed        = true,
			size         = { w = topx(200), h = topx(40) },
			sounds       = sounds,
			transform_fn = transform,
			position_fn  = function()
				return anchor:left() + topx(300), anchor:center_y() - topx(50)
			end
		}),

		audio = scroller(self.menus.audio, {
			fixed        = true,
			size         = { w = topx(200), h = topx(40) },
			sounds       = sounds,
			transform_fn = transform,
			position_fn  = function()
				return anchor:left() + topx(300), anchor:center_y() - topx(50)
			end
		}),

		language = scroller(self.menus.language, {
			fixed        = true,
			size         = { w = topx(200), h = topx(40) },
			sounds       = sounds,
			transform_fn = transform,
			position_fn  = function()
				return anchor:left() + topx(300), anchor:center_y() - topx(50)
			end
		}),
	}

	self.active_scrollers = {}

	self.scroller = self.scrollers[self.menu_selected]
	self.logo     = love.graphics.newImage("assets/textures/logo.png")
end

function scene:leave()
	love.filesystem.write("preferences.json", json.encode(_G.PREFERENCES))
end

function scene:scroller_action()
	local item = self.scroller:get()
	if item.action then
		item.action()
	end
end

function scene:scroller_prev()
	local item = self.scroller:get()
	if item.prev then
		item.prev()
	end
end

function scene:scroller_next()
	local item = self.scroller:get()
	if item.next then
		item.next()
	end
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
	if k == "left" then
		self:scroller_prev()
		return
	end
	if k == "right" then
		self:scroller_next()
		return
	end
	if k == "return" then
		self:scroller_action()
		return
	end
	if k == "escape" then
		if self.menu_selected == "main" then
			_G.SCENE.switch(require "scenes.main-menu")
		else
			self.menu_selected = "main"
		end
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
			self:scroller_action()
		end
	end
end

function scene:update(dt)
	self.scroller = self.scrollers[self.menu_selected]
	self.scroller:hit(love.mouse.getPosition())

	-- Get main menu scroller and other scroller if available
	self.active_scrollers = {
		self.scrollers.main,
		self.scrollers[self.menu_selected] ~= self.scrollers.main and self.scrollers[self.menu_selected] or nil
	}

	for _, scroll in ipairs(self.active_scrollers) do
		scroll:update(dt)
	end

	world:update(dt)
end

local function draw_arrow(dir, x, y, w, h)
	local points
	if dir == "left" then
		points = {
			x + w, y,
			x + w, y + h,
			x, y + h/2
		}
	elseif dir == "right" then
		points = {
			x, y,
			x + w, y + h/2,
			x, y + h
		}
	end
	love.graphics.polygon("fill", points)
end

function scene:draw()
	renderer:draw()

	love.graphics.setColor(255, 255, 255, 255)

	-- Draw logo
	local x, y = anchor:left() + topx(100), anchor:center_y() - topx(150)
	local s = love.window.getPixelScale()
	love.graphics.draw(self.logo, x, y, 0, s, s)

	local font = get_font(topx(16))
	love.graphics.setFont(font)

	-- Iterate through scrollers and draw them
	for _, scroll in ipairs(self.active_scrollers) do
		-- Draw highlight bar
		if scroll == self.scroller then
			love.graphics.setColor(255, 60, 0, 50)
		else
			love.graphics.setColor(255, 60, 0, 20)
		end
		love.graphics.rectangle("fill",
			scroll.cursor_data.x,
			scroll.cursor_data.y,
			scroll.size.w,
			scroll.size.h
		)

		-- Draw items
		love.graphics.setColor(255, 255, 255, scroll == self.scroller and 255 or 100)
		for i, item in ipairs(scroll.data) do
			if item.i18n then
				local text = self.language:get(item.label)
				love.graphics.print(text, item.x + topx(10), item.y + topx(10))
			elseif item.language then
				local _, language = self.language:get_locale()
				love.graphics.print(language, item.x + topx(10), item.y + topx(10))
			elseif item.volume then
				local label
				if item.volume == "master" then
					label = string.format(item.label, self.volume_slider:map(_G.PREFERENCES.master_volume))
				elseif item.volume == "bgm" then
					label = string.format(item.label, self.volume_slider:map(_G.PREFERENCES.bgm_volume))
				elseif item.volume == "sfx" then
					label = string.format(item.label, self.volume_slider:map(_G.PREFERENCES.sfx_volume))
				end
				love.graphics.print(label, item.x + topx(10), item.y + topx(10))
			else
				love.graphics.print(item.label, item.x + topx(10), item.y + topx(10))
			end
			if item.prev then
				draw_arrow("left", item.x - topx(10), item.y + topx(10), topx(10), topx(20))
			end
			if item.next then
				draw_arrow("right", item.x + scroll.size.w, item.y + topx(10), topx(10), topx(20))
			end
		end
	end
end

return scene

end
