OptionState = class("OptionState")

function OptionState:initialize()
	self.backbutton = Button:new(window.w - 110, window.h - 50, 100, 40, {text = "Back", font = font["Arcade30"]})
	self.opensave = Button:new(50, 380, 150, 50, {text = "Open Save Folder", font = font["Arcade20"], wrap = 2})
	self.controlRadios = {}
	local cr = self.controlRadios
	cr[1] = Radio:new(80, 100, false, cr, "mouse")
	cr[2] = Radio:new(80, 125, false, cr, "keyboard")
	cr[3] = Radio:new(80, 150, false, cr, "smart_keyboard")
	for i, r in ipairs(cr) do
		if r.value == control_mode then r.state = true end
	end
	self.difficultyRadios = {}
	local dr = self.difficultyRadios
	dr[1] = Radio:new(80, 210, false, dr, "easy")
	dr[2] = Radio:new(80, 235, false , dr, "normal")
	dr[3] = Radio:new(80, 260, false, dr, "hard")
	dr[4] = Radio:new(80, 285, false, dr, "very_hard")
	for i, r in ipairs(dr) do
		if r.value == difficulty then r.state = true end
	end
	self.slider = Slider:new(50, 345, 400, 25, 0, 100, math.floor(love.audio.getVolume() * 100 + 0.5), 10)
	self.fullscreenbox = Checkbox:new(50, 440, window.fullscreen ~= nil)
end

function OptionState:update(dt)
	if keys.escape then
		game:pop()
	end
	if self.backbutton:update(dt) then
		game:pop()
	end
	if self.opensave:update(dt) then
		love.system.openURL("file://"..love.filesystem.getSaveDirectory())
	end
	for i, r in ipairs(self.controlRadios) do
		if r:update(dt) then
			control_mode = r.value
		end
	end
	for i, r in ipairs(self.difficultyRadios) do
		if r:update(dt) then
			difficulty = r.value
		end
	end
	if self.slider:update(dt) then
		love.audio.setVolume(self.slider.value / 100)
		prefs.volume = self.slider.value
	end
	if self.fullscreenbox:update(dt) ~= nil then
		window:setFullscreen(self.fullscreenbox.state)
	end
end

function OptionState:draw()
	legacySetColor(100, 100, 100, 255)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)

	legacySetColor(255, 255, 255, 255)
	love.graphics.setFont(font["Arcade50"])
	love.graphics.printf("Options", 0, 0, window.w, "center")

	love.graphics.setFont(font["Arcade30"])
	love.graphics.print("Control Mode:", 50, 70)

	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Munro20"])
	love.graphics.print("Mouse"          , 105, 100)
	love.graphics.print("Keyboard"       , 105, 125)
	love.graphics.print("Smart Keyboard" , 105, 150)
	for i, r in ipairs(self.controlRadios) do
		r:draw()
	end 

	legacySetColor(255, 255, 255, 255)
	love.graphics.setFont(font["Arcade30"])
	love.graphics.print("Difficulty:", 50, 180)

	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Munro20"])
	love.graphics.print("Easy"      , 105, 210)
	love.graphics.print("Normal"    , 105, 235)
	love.graphics.print("Hard"      , 105, 260)
	love.graphics.print("Very Hard" , 105, 285)
	for i, r in ipairs(self.difficultyRadios) do
		r:draw()
	end

	legacySetColor(255, 255, 255, 255)
	love.graphics.setFont(font["Arcade30"])
	love.graphics.print("Volume:", 50, 315)
	self.slider:draw()

	
	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Arcade20"])
	local value = self.slider.value
	love.graphics.print(value, self.slider.x + self.slider.w + 10, self.slider.y)

	self.backbutton:draw()
	self.opensave:draw()

	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Munro20"])
	love.graphics.print("Fullscreen Mode", 75, 440)
	self.fullscreenbox:draw()

end