MainMenuState = class("MainMenuState")

local function customWallBounce(self)
	local r = self:getR()
	local x, y = self:getPos()

	if x - r < 0 + 16        then self:handleCollision( 1,  0) end
	if x + r > window.w - 16 then self:handleCollision(-1,  0) end
	if y - r < 0             then self:handleCollision( 0,  1) end
	if y + r > window.h      then self:handleCollision( 0, -1) end
end

local function makeMenuButton(imgstr, text, pos, callback)
	if not imgstr then imgstr = "clear_pixel" end
	local x, y = pos[1], pos[2]
	local b = Button:new(
		x, y, 50, 50, {
			image = {imgstr = imgstr, w = 40, h = 40, offx = -1, offy = -1},
			subtext = {text = text, font = font["Arcade20"], offx = 40 + 20, offy = 10}
		},
		callback
	)
	return b
end

function MainMenuState:initialize(mode)
	mainmenu = self --make itself public to global space

	--modes: default, play
	self.mode = mode or "default"

	local ix = 150
	local iy = 250

	local pos = {}
	for i = 1, 10 do
		pos[i] = {}
		for j = 1, 2 do
			pos[i][j] = {ix + (j-1)*300, iy + (50 + 20)*(i-1)}
		end
	end

	self.buttons = {
		makeMenuButton("menu_campaign", "Play Campaign", pos[1][1], function()
			game:push(CampaignState:new())
		end),
		makeMenuButton("menu_playlist", "Play Playlist", pos[2][1], function()
			game:push(LevelSelectState:new("playlist", true))
		end),
		makeMenuButton("menu_play", "Play Level", pos[3][1], function()
			game:push(LevelSelectState:new())
		end),
		makeMenuButton("menu_options", "Options", pos[1][2], function()
			game:push(OptionState:new())
		end),
		makeMenuButton("menu_editlist", "Playlist Editor", pos[2][2], function()
			game:push(LevelSelectState:new("playlist"))
		end),
		makeMenuButton("menu_edit", "Level Editor", pos[3][2], function()
			game:push(EditorState:new())
		end),
		
		Button:new(
			window.w - 70, window.h - 55, 44, 44, {
				image = {imgstr = "quit_icon", rect = nil, w = 32, h = 32},
				color = {idle = 150, hovered = 150, clicked = 200}
			},
			function()
				love.event.quit()
			end
		),
	}

	--gameplay stuff

	self.balls = {}

	for i = 1, 7 do
		local vx, vy = util.rotateVec(math.random(300, 500), 0, math.random(0, 360))
		local ball = Ball:new(window.w/2, window.h/2, vx, vy)
		ball.wallBounce = customWallBounce --replace default function
		table.insert(self.balls, ball)
	end


	--read bricks from title.txt
	self.bricks = {}
	local ix, iy = 100, 100
	local i, j = 0, 0
	for line in love.filesystem.lines("states/title.txt") do
		j = 0
		for mode in line:gmatch("%S+") do
			if mode ~= "___" then
				local br = TitleBrick:new(ix + j*16, iy + i*8, mode)
				table.insert(self.bricks, br)
			end
			j = j + 1
		end
		i = i + 1
	end
end

function MainMenuState:update(dt)
	for _, button in pairs(self.buttons) do
		button:update(dt)
	end
	if self.mode ~= "default" then
		if keys.escape then
			game:pop()
			return
		end
	end

	--gameplay stuff
	if keys.n then
		local vx, vy = util.rotateVec(400, 0, math.random(0, 360))
		local ball = Ball:new(window.w/2, window.h/2, vx, vy)
		ball.wallBounce = customWallBounce --replace default function
		table.insert(self.balls, ball)
	end


	for _, b in ipairs(self.balls) do
		for _, br in ipairs(self.bricks) do
			local check, norm = br:checkBallHit(b)
			if check then
				br:onBallHit(b, norm)
			end
		end
	end

	for i, b in ipairs(self.balls) do
		b:update(dt)
	end

	for i, br in ipairs(self.bricks) do
		br:update(dt)
	end
end

local subtextRect = {
	make_rect(0, 2, 270, 11),
	make_rect(0, 14, 146, 23),
	make_rect(0, 39, 287, 13)
}

function MainMenuState:draw()
	legacySetColor(100, 100, 100)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)

	legacySetColor(255, 255, 255)
	-- love.graphics.setFont(font["Origami100"])
	-- love.graphics.printf("Otaku-Ball", 0, window.h/2 - 200, window.w, "center")

	-- local imgstr, rect = "background", rects.bg[13][1]
	-- local w = rect.w * 2
	-- local h = rect.h * 2
	-- local across = math.ceil(window.w / w)
	-- local down = math.ceil(window.h / h)
	-- for i = 1, down do
	-- 	for j = 1, across do
	-- 		draw(imgstr, rect, 8 + w*(j-1), 0 + h*(i-1), 0, w, h, 0, 0)
	-- 	end
	-- end
	draw("menu_bg", nil, window.w/2, window.h/2, 0, 800, 600)

	draw("title_sub", subtextRect[1], window.w/2, 75, 0, 270, 11, nil, 0)
	draw("title_sub", subtextRect[2], 540, 165, 0, 146, 23, 0, 0)
	draw("title_sub", subtextRect[3], window.w/2-.5, window.h-10.5, 0, 287, 13)

	for i, b in ipairs(self.bricks) do
		b:draw()
	end

	for i, b in ipairs(self.balls) do
		b:draw()
	end

	-- draw("title_temp", nil, window.w/2, window.h/2 - 200, 0, 568, 64)
	draw("border", make_rect(0, 9, 8, 9), 8           , window.h/2, 0, 16, window.h)
	draw("border", make_rect(0, 9, 8, 9), window.w - 8, window.h/2, 0, 16, window.h)

	for _, button in pairs(self.buttons) do
		button:draw()
	end

end