LevelSelectState = class("LevelSelectState")

function LevelSelectState:initialize()
	self.buttons = {}
	local x = 170
	local y = 200
	local width = 200
	local height = 150
	local padding = 20
	for i = 1, 8 do
		local bx = x + (width + padding)*((i-1)%4)
		local by = y + (height + padding)*math.floor((i-1)/4)
		local button = Button:new(bx, by, width, height, {text = "Level "..i, font = font["Arcade30"]}, function()
			local queue = Queue:new()
			for j = i, 8 do
				queue:pushRight({"level"..j..".txt", false})
			end
			game:push(PlayState:new("play", queue))
		end)
		table.insert(self.buttons, button)
	end

	table.insert(self.buttons, Button:new(10, window.h-(50+20), 150, 50, {text = "Back", font = font["Arcade40"]}, function()
		game:pop()
	end))
end

function LevelSelectState:update(dt)
	for _, button in pairs(self.buttons) do
		button:update(dt)
	end
end

function LevelSelectState:draw()
	legacySetColor(100, 100, 100)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)

	legacySetColor(255, 255, 255)
	love.graphics.setFont(font["Arcade50"])
	love.graphics.printf("Level Select", 0, 10, window.w, "center")

	for _, button in pairs(self.buttons) do
		button:draw()
	end
end