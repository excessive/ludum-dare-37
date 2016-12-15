local dialog = {
	img = {
		corner = love.graphics.newImage("assets/dialog/corner.png"),
		edge = love.graphics.newImage("assets/dialog/edge.png"),
		center = love.graphics.newImage("assets/dialog/center.png"),
	},
}

function dialog.new(init)
	init = init or {}
	local self = {}

	assert(init.text,"dialog.new requires text argument")

	self._text = init.text

	self._dt = 0
	self._dt_max = 4

	local sound
	if init.audio then
		local sound = love.sound.newSoundData(init.audio)
		self._dt_max = sound:getDuration()
		self._audio = love.audio.newSource(sound)
	end

	self.update = dialog.update
	self.draw = dialog.draw
	self.isDone = dialog.isDone
	self._box = dialog._box
	
	self._a = 1

	return self
end

function dialog:update(dt)
	if self._audio and not self._played then
		self._audio:play()
		self._audio:setVolume(_G.PREFERENCES.sfx_volume * 0.2)
		self._played = true
	end
	self._dt = math.min(self._dt_max,self._dt + dt)
end

function dialog:draw()
	self:_box(love.graphics.getWidth()/2,love.graphics.getHeight()*3/4,self._text)
end

function dialog:isDone()
	return self._dt ==  self._dt_max
end

function dialog:_box(cx,cy,text)

	local font = love.graphics.getFont()

	local old_font = love.graphics.getFont()
	local old_color = {love.graphics.getColor()}

	love.graphics.setFont(font)

	local max_width, wrappedtext = font:getWrap( self._text, love.graphics.getWidth()/3 )

	local tpad = 8

	local x = cx - max_width/2 - tpad
	local w = max_width + tpad*2
	local h = #wrappedtext*font:getHeight() + tpad*2
	local y = cy - h - tpad
	local p = dialog.img.edge:getHeight()

	love.graphics.setColor(255,255,255,self._a*255)
	--center
	love.graphics.draw(dialog.img.center,
		x,y,0,
		w/dialog.img.center:getWidth(),
		h/dialog.img.center:getHeight())
	--topleft
	love.graphics.draw(dialog.img.corner,x-p,y-p)
	--top
	love.graphics.draw(dialog.img.edge,x,y-p,0,w,1)
	--topright
	love.graphics.draw(dialog.img.corner,x+w+p,y-p,math.pi/2)
	--right
	love.graphics.draw(dialog.img.edge,x+w+p,y,math.pi/2,h,1)
	--bottomright
	love.graphics.draw(dialog.img.corner,x+w+p,y+h+p,math.pi)
	--bottom
	love.graphics.draw(dialog.img.edge,x+w,y+h+p,math.pi,w,1)
	--bottomleft
	love.graphics.draw(dialog.img.corner,x-p,y+h+p,-math.pi/2)
	--left
	love.graphics.draw(dialog.img.edge,x-p,y+h,-math.pi/2,h,1)

	love.graphics.printf(text,math.floor(0.5+x+tpad),math.floor(0.5+y+tpad),max_width,"left")

	local shadow = 2
	love.graphics.setColor(0,0,0,31)
	love.graphics.printf(text,math.floor(0.5+x+tpad+shadow),math.floor(0.5+y+tpad+shadow),max_width,"left")

	love.graphics.setColor(old_color)
	love.graphics.setFont(old_font)
end

return dialog
