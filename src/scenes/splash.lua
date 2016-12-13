return function()

local anchor = require "anchor"
local timer  = require "timer"
local scene     = {}

function scene:enter()
	love.audio.setDistanceModel("none")

	self.logos = {
		love.graphics.newImage("assets/splash/logo-exmoe.png"),
		love.graphics.newImage("assets/splash/logo-love3d.png"),
		love.graphics.newImage("assets/splash/logo-mss.png"),
	}
	local theight = 0
	for _,logo in pairs(self.logos) do
		theight = theight + logo:getHeight()
	end
	self.yoffset = (love.graphics.getHeight()-theight)/2

	self.timer = timer.new()
	self.delay = 5.5
	self.overlay = {
		opacity = 255
	}
	self.bgm = {
		volume = 0.5,
		music  = love.audio.newSource("assets/splash/love.ogg")
	}
	self.next_scene = "scenes.main-menu"

	love.graphics.setBackgroundColor(love.math.gammaToLinear(30, 30, 44))
	self.bgm.music:play()
	love.mouse.setVisible(false)

	-- BGM
	self.timer:script(function(wait)
		self.bgm.music:setVolume(self.bgm.volume)
		self.bgm.music:play()
		wait(self.delay)
		self.timer:tween(1.5, self.bgm, {volume = 0}, 'in-quad')
		wait(1.5)
		self.bgm.music:stop()
	end)

	-- Overlay fade
	self.timer:script(function(wait)
		-- Fade in
		self.timer:tween(1.5, self.overlay, {opacity=0}, 'cubic')
		-- Wait a little bit
		wait(self.delay)
		-- Fade out
		self.timer:tween(1.25, self.overlay, {opacity=255}, 'out-cubic')
		-- Wait briefly
		wait(1.5)
		-- Switch
		self.switch = true
	end)
end

function scene:leave()
	love.mouse.setVisible(true)

	self.logos      = nil
	self.timer      = nil
	self.delay      = nil
	self.overlay    = nil
	self.bgm        = nil
	self.next_scene = nil
	self.switch     = nil
end

function scene:update(dt)
	self.timer:update(dt)
	self.bgm.music:setVolume(self.bgm.volume)

	if self.switch then
		self.bgm.music:stop()
		_G.SCENE.switch(require(self.next_scene))
	end
end

function scene:draw()
	local cx, cy = anchor:center()

	love.graphics.setColor(255, 255, 255, 255)
	local cheight = 0
	for _,logo in pairs(self.logos) do
		local xoffset = (love.graphics.getWidth()-logo:getWidth())/2
		love.graphics.draw(logo,xoffset,self.yoffset + cheight)
		cheight = cheight + logo:getHeight()
	end

	-- Full screen fade, we don't care about logical positioning for this.
	local w, h = love.graphics.getDimensions()
	love.graphics.setColor(0, 0, 0, self.overlay.opacity)
	love.graphics.rectangle("fill", 0, 0, w, h)
end

return scene

end
