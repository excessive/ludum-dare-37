-- we need to require these before fire.save_the_world(), to prevent crashes
require "cpml"
require "iqm"
require "love3d".import(false)

local anchor = require "anchor"
local fire   = require "fire"
fire.save_the_world()

_G.EVENT = require "talkback".new()
_G.SCENE = require "gamestate"

function love.load(args)
	for _, v in pairs(args) do
		if v == "--debug" then
			_G.FLAGS.debug_mode = true
		end
		if v == "--hud" then
			_G.FLAGS.show_perfhud = true
		end
	end

	anchor:set_overscan(0.1)
	anchor:update()

	_G.SCENE.registerEvents {
		"update", "keypressed",
		"mousepressed", "mousereleased", "mousemoved", "wheelmoved",
		"touchpressed", "touchreleased", "touchmoved"
	}

	_G.DEFAULT_PREFERENCES = {
		fullscreen    = false,
		master_volume = 0.50,
		bgm_volume    = 0.40,
		sfx_volume    = 0.90,
		language      = "en"
	}

	_G.PREFERENCES = {}

	-- Load preferences
	if love.filesystem.isFile("preferences.json") then
		local json   = require "dkjson"
		local file   = love.filesystem.read("preferences.json")
		local decode = json.decode(file)
		for k, v in pairs(decode) do
			_G.PREFERENCES[k] = v
		end
	else
		for k, v in pairs(_G.DEFAULT_PREFERENCES) do
			_G.PREFERENCES[k] = v
		end
	end

	love.window.setFullscreen(_G.PREFERENCES.fullscreen)

	_G.SCENE.switch(require("scenes.splash")())
end

function love.update(dt)
	anchor:update()
end

local function draw_overscan()
	love.graphics.setColor(180, 180, 180, 200)
	love.graphics.setLineStyle("rough")
	love.graphics.line(anchor:left(), anchor:center_y(), anchor:right(), anchor:center_y())
	love.graphics.line(anchor:center_x(), anchor:top(), anchor:center_x(), anchor:bottom())
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.rectangle("line", anchor:bounds())
end

function love.draw()
	local top = _G.SCENE.current()

	if not top.draw then
		fire.print("no draw function on the top screen.", 0, 0, "red")
	else
		top:draw()
	end

	if _G.FLAGS.show_overscan then
		draw_overscan()
	end
end
