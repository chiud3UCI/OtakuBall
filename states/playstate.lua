PlayState = class("PlayState")

ball_limit = 50
instant_powerups = false

pow_scale = 1.5
PlayState.pow_scale = pow_scale
PlayState.powerupBox = make_rect(window.rwallx + 56, window.ceiling - 16, 64*pow_scale, 320*pow_scale)

--DEFUNCT
-- finished_powerups = {}
-- for id in pairs(PowerUp.funcTable) do
-- 	table.insert(finished_powerups, id)
-- end

-- PlayState.finishedPowerUpSprites = {}
-- for _, i in ipairs(finished_powerups) do
-- 	local x, y, w, h = unpack(PlayState.powerupBox)
-- 	local rect = rects.powerup_ordered[i] 
-- 	local dx, dy = rect.x - (64*8), rect.y - 0
-- 	dx = dx * pow_scale
-- 	dy = dy * pow_scale
-- 	local t = {rect, x + dx, y + dy}
-- 	table.insert(PlayState.finishedPowerUpSprites, t)
-- end

function beatlevel()
	local state = game:top()
	if state ~= nil and state.stateName == "playstate" then
		state:setVictory()
	end
end

function beatzone()
	local state = game:top()
	if state ~= nil and state.stateName == "playstate" then
		state:setVictory()
		local q = state.fileQueue
		if q then
			while not q:empty() do
				q:popRight()
			end
		end
	end
end

menacerButton = {
	x = 10, 
	y = 135+45, 
	w = 144, 
	h = 24, 
	rect1 = make_rect(0, 12, 36, 12), 
	rect2 = make_rect(0, 24, 36, 12)
}
--menacerButton = Sprite:new("ball_spritesheet", make_rect(0, 12, 36, 24), 90, 60, 100, 300)
function menacerButton:containPoint(x, y)
	return x > self.x and
		   x < self.x + self.w and
		   y > self.y and
		   y < self.y + self.h
end

function menacerButton:getMenacerType(x, y)
	local lookup = {"red", "green", "cyan", "bronze", "silver", "pewter"}
	local dx = x - self.x
	local j = math.floor(dx / (self.w/6))
	return lookup[j+1]
end

function menacerButton:draw()
	draw("ball_spritesheet", self.rect1, self.x + self.w/4, self.y + self.h/2, 0, self.w/2, self.h)
	draw("ball_spritesheet", self.rect2, self.x + 3*self.w/4, self.y + self.h/2, 0, self.w/2, self.h)
end

enemyButton = {
	x = 10,
	y = 160+45,
	w = 96,
	h = 24
}

enemyButton.containPoint = menacerButton.containPoint

function enemyButton:getEnemyType(x, y)
	local lookup = {"dizzy", "cubic", "gumballtrio", "walkblock"}
	local dx = x - self.x
	local j = math.floor(dx / (self.w/4))
	return lookup[j+1]
end

function enemyButton:draw()
	draw("enemy_editor", nil, self.x + self.w/2, self.y + self.h/2, 0, self.w, self.h)
end


function PlayState:loadBricks(filename)
	local chunk = nil
	if filename:sub(1, 1) == "_" then
		chunk = love.filesystem.load("default_levels/"..filename)
	else
		chunk = love.filesystem.load("levels/"..filename)
	end
	if not chunk then
		print("ERROR: file \""..filename.."\" not found")
		return
	end
	local data = chunk()
	for _, v in pairs(data.bricks) do
		local i, j, id, patch = unpack(v)
		local x, y = getGridPosInverse(i, j)
		local brickData = EditorState.brickDataLookup[id]
		local Constructor = _G[brickData.type]
		local brick = Constructor:new(x, y, unpack(brickData.args))
		brick:setPatches(patch)
		table.insert(game.bricks, brick)
	end
	local t = data.menacerTimer or {}
	enemySpawner:initialize(data.menacer, unpack(t))
	if data.powerup then
		powerupGenerator:initialize(data.powerup.overall_chance, data.powerup.weights)
	else
		powerupGenerator:initialize()
	end
	if data.background then
		self.background = data.background
		if self.background.tile then
			local tile = self.background.tile
			tile.rect = rects.bg[tile.i][tile.j]
		end
	else
		self.background = {r = 0, g = 0, b = 128}
	end
	game.config.slot_blue = {1, 2, 3}
	game.config.slot_yellow = {1, 2, 3}
	if data.config then
		for k, v in pairs(data.config) do
			game.config[k] = v
		end
	end
end

sweeperSpeed = 600
borderSpeed = 400


function PlayState:reset()
	game:clearObjects() --even deletes the paddle
	self.state = "intro"
	self.sweeper = {x = window.lwallx, y = window.h, w = window.rwallx - window.lwallx, h = 32, vy = -sweeperSpeed}
	self.sweeper.activated = false
	local spd = borderSpeed
	local left = Sprite:new("border", make_rect(0, 0, 8, 264), 16, window.h-window.ceiling+16, window.rwallx, window.ceiling-16)
	local right = Sprite:new("border", make_rect(224-8, 0, 8, 264), 16, window.h-window.ceiling+16, window.lwallx-16, window.ceiling-16)
	local top = Sprite:new("border", make_rect(0, 0, 224, 8), window.rwallx-window.lwallx+32, 16, window.lwallx-16, window.h)
	local distx = window.rwallx - right.x
	local disty = top.y - (window.ceiling - 16)
	top.vy = -spd
	right.vx = spd * distx / disty
	left.vx = -right.vx
	self.movingBorders = {left = left, right = right, top = top}
	self.fadeOut = nil
	self.timeWarp = nil
	self.time_scale = 1.0
	self.bypass = nil
	self.warp = nil
	self:initGates() --cloese any gates that might have been open
end

--skips a level if warp is set to true
function PlayState:nextLevel()
	local skip = self.warp and 2 or 1
	self:reset()
	local file
	for i = 1, skip do
		if not self.fileQueue or self.fileQueue:empty() then
			if self.zones then
				campaignstate:record("zoneselect")
				campaignstate:chooseZone()
			end
			game:pop()
			return
		end
		file = self.fileQueue:popLeft()
	end
	if self.zones then
		--campaign will save progress for each level
		campaignstate:record(file)
	end
	self:loadBricks(file)
	activateAllBricks()
	self.round = self.round + skip
end

--starts the game 
--can be called during the intro or spawn states
--entry point for editorstate
function PlayState:start()
	if not game.paddle then
		game.paddle = Paddle:new()
	end
	game.paddle.bob = nil
	game.paddle.spawnOrbs = nil
	game.paddle:setPos(nil, Paddle.baseline)
	game.paddle.speedLimit.y = 500
	if #game.balls == 0 then
		local ball = Ball:new(0, 0, 0, Ball.defaultSpeed[difficulty])
		game.paddle:attachBall(ball, "random")
		table.insert(game.balls, ball)
	else
		local ball = game.balls[1]
		ball.color.a = 255
	end
	mouse.m1 = false --prevents the paddle from releasing the ball immediately
	game.paddle:update(0)
	self.state = "playing"
	self.mouseProtect = true
end

function PlayState:spawn()
	game.paddle = Paddle:new()
	game.paddle.y = window.h + 8 --spawn off screen
	game.paddle.speedLimit.y = 100
	game.paddle.bob = {vy = -200, ay = 0, up = true, queue = Queue:new({750, 1000}), done = false}
	local spawnOrbs = {vel = 1250, dist = 1000, done = false}
	for i = 1, 4 do spawnOrbs[i] = Particle:new("white_circle", nil, 14, 14) end
	game.paddle.spawnOrbs = spawnOrbs
	self.state = "spawn"
end

gateOffset = {
	top = {31, 79, 143, 191, 0},
	side = {31, 79, 111, 159, 223}
}
local gateIndex = {
	top = 0,
	left = 4,
	right = 9
}
local gateRect = {
	left = make_rect(23, 0, 9, 8),
	right = make_rect(32, 0, 9, 8),
	up = make_rect(0, 23, 8, 9),
	down = make_rect(0, 32, 8, 9)
}

function PlayState:initGates()
	self.gates = {top = {}, left = {}, right = {}, bottom = {}}
	--there are 5 side gates and 4 top gates
	--there are two bottom gates that open at the bottom left and bottom right
	--states: closed, opening, opened, closed
	for i = 1, 5 do
		local topdiv = window.lwallx - 16 + gateOffset.top[i]*2
		local sidediv = window.ceiling - 16 + gateOffset.side[i]*2
		self.gates.top[i] = {side = "top", index = i, middle = topdiv, width = 0, target = 0, state = "closed"}
		self.gates.left[i] = {side = "left", index = i, middle = sidediv, width = 0, target = 0, state = "closed"}
		self.gates.right[i] = {side = "right", index = i, middle = sidediv, width = 0, target = 0, state = "closed"}
	end
	self.gates.top[5] = nil
	self.gates.bottom[1] = {side = "bottom", index = 1, middle = 0, width = 0, target = 0, state = "closed"}
	self.gates.bottom[2] = {side = "bottom", index = 2, middle = 0, width = 0, target = 0, state = "closed"}
end

function PlayState:updateGates(dt)
	for k, v in pairs(self.gates) do
		for i, gate in ipairs(v) do
			if gate.state == "opening" then
				gate.width = gate.width + dt*100
				if gate.width >= gate.target then
					gate.width = gate.target
					gate.state = "opened"
				end
			elseif gate.state == "opened" then
			elseif gate.state == "closing" then
				gate.width = gate.width - dt*100
				if gate.width <= 0 then
					gate.width = 0
					gate.state = "closed"
				end
			end
		end
	end
end

function PlayState:drawGate(gate)
	if gate.state == "closed" then return end
	if gate.side == "top" then
		legacySetColor(255, 255, 255, 255)
		draw("border", gateRect.left, gate.middle - 18/2 - gate.width/2 + 2, window.ceiling - 8, 0, 18, 16)
		draw("border", gateRect.right, gate.middle + 18/2 + gate.width/2 + 2, window.ceiling - 8, 0, 18, 16)
		legacySetColor(0, 0, 0, 255)
		love.graphics.rectangle("fill", gate.middle - gate.width/2 + 2, window.ceiling - 16, gate.width, 16)
	elseif gate.side == "left" or gate.side == "right" then
		local x = (gate.side == "left") and (window.lwallx - 8) or (window.rwallx + 8)
		legacySetColor(255, 255, 255, 255)
		draw("border", gateRect.up, x, gate.middle - 18/2 - gate.width/2 + 2, 0, 16, 18)
		draw("border", gateRect.down, x, gate.middle + 18/2 + gate.width/2 + 2, 0, 16, 18)
		legacySetColor(0, 0, 0, 255)
		local x = (gate.side == "left") and (window.lwallx - 16) or (window.rwallx)
		love.graphics.rectangle("fill", x, gate.middle - gate.width/2 + 2, 16, gate.width)
	else
		local x = (gate.index == 1) and (window.lwallx - 16) or (window.rwallx)
		legacySetColor(0, 0, 0, 255)
		love.graphics.rectangle("fill", x, window.h - gate.width, 16, gate.width)
	end
	legacySetColor(255, 255, 255, 255)
end

function PlayState:drawGates()
	for k, v in pairs(self.gates) do
		for i, gate in ipairs(v) do
			self:drawGate(gate)
		end
	end
end

function openGate(side, num, amount)
	playstate:openGate(side, num, amount)
end

function PlayState:openGate(side, num, amount)
	if side == "bottom" and amount == nil then
		amount = 62 -- the height between the bottom part and the bottom
	end
	local gate = self.gates[side][num]
	if gate.state == "closed" then
		gate.state = "opening"
		gate.target = amount
	end
	return gate
end

function PlayState:closeGate(side, num)
	local gate = self.gates[side][num]
	if gate.state ~= "closed" then gate.state = "closing" end
end

--generate preview of first level of zone playlist
function PlayState:getPreview(zone)
	local lines = readlines("default_playlists/_Zone"..zone)
	for _, line in ipairs(lines) do
		return LevelSelectState.generatePreview(line)
	end
end

--filename can also be a queue of filenames
--zones is a list of strings
--if zones exists, then the player will choose which zone to go to once there are no more levels
function PlayState:initialize(mode, filename, zones)
	playstate = self
	self.stateName = "playstate"
	--"test" mode is for debugging, "play" mode is for playing a level
	self.mode = mode or "test"
	self.round = 1

	self.zones = zones

	self.score = 0
	self.scoreModifier = 1.0
	self.lives = 3
	self.ballCount = 1 --later on you have to take in account of gatebricks

	if self.mode == "test" then
		local options = {
			image = {imgstr = "button_icon", rect = rects.icon.stop[1], w = 36, h = 33, offx = -50, offy = -1},
			color = {idle = 150, hovered = 150, clicked = 200},
			text = "Stop",
			font = font["Arcade30"],
			offx = 20
		}
		self.stopButton = Button:new(10, 45, 155, 50, options)
		self.noPitButton = Checkbox:new(10, 200 + 45, false)
		self.enemyDebugButton = Checkbox:new(10, 230 + 45, false)
	else
		local options = {
			image = {imgstr = "quit_icon", rect = nil, w = 32, h = 32},
			color = {idle = 150, hovered = 150, clicked = 200}
		}
		self.quitButton = Button:new(10, 45, 44, 44, options)
	end

	self.maxStalemate = 30
	self.stalemateTimer = self.maxStalemate

	self.background = {r = 0, g = 0, b = 128}

	--each gate is 16x8 or 8x16
	--gates should open from the center
	self:initGates()

	soundMonitor:activate()

	--brickGrid can be modified
	--rectGrid is constant
	self.brickGrid = {}
	self.rectGrid = {}
	for i = 1, 32 do
		self.brickGrid[i] = {}
		self.rectGrid[i] = {}
		for j = 1, 13 do
			self.brickGrid[i][j] = {}
			self.rectGrid[i][j] = {window.lwallx+(j-1)*32, window.ceiling+(i-1)*16, window.lwallx+j*32, window.ceiling+i*16}
		end
	end

	--intro, spawn, playing, victory, death, gameover, zoneselect
	--respawn <-- death --> gameover

	if self.mode == "play" then 
		self:reset()
		self.lives = 3
		if type(filename) == "string" then
			self:loadBricks(filename)
		else
			self.fileQueue = filename
			local file = self.fileQueue:popLeft()
			self:loadBricks(file)
		end
	else
		self:start()
		tooltipManager:clear()
	end

	activateAllBricks() --from bricks\_init

	--self.mouseProtect = true 
end

function PlayState:update(dt)
	soundMonitor:update(dt)
	if self.shake then
		self.shake.timer = self.shake.timer - dt
		if self.shake.timer <= 0 then
			self.shake = nil
		end
	end

	if self.state ~= "playing" then
		self.timeWarp = nil
		time_scale = 1
	end

	if self.mouseProtect then
		if not mouse.m1 then
			self.mouseProtect = nil
		else
			mouse.m1 = false
		end
	end

	--input based events
	if keys.escape then
		if self.mode == "test" or (self.mode == "play" and self.state == "gameover") then
			game:clearObjects()
			GateBrick.ballCount = 0
			game:pop()
			return
		else
			game:push(PlayStateClosePrompt:new(function()
				game:clearObjects()
				GateBrick.ballCount = 0
				game:pop()
			end))
		end
	end
	if self.mode == "test" then
		if keys.n then
			local ball = Ball:new(window.w/2, window.h/2, Ball.defaultSpeed[difficulty], 0)
			game.paddle:attachBall(ball, "random")
			ball:updateShape()
			game:emplace("balls", ball)
		end
		if self.stopButton:update(dt) then
			game:clearObjects()
			GateBrick.ballCount = 0
			game:pop()
			return
		end
		local id = self.getPowerUpId(mouse.x, mouse.y)
		tooltipManager:selectPowerUp(id)
		if mouse.m1 == 1 then
			if mouse.x > window.rwallx then
				if id > 0 then
					local pow = PowerUp:new(game.paddle.x, game.paddle.y - (instant_powerups and 0 or 100), id)
					game:emplace("powerups", pow)
				end
			elseif mouse.x < window.lwallx then
				local mx, my = mouse.x, mouse.y
				if menacerButton:containPoint(mx, my) then
					spawnEnemy(menacerButton:getMenacerType(mx, my))
				elseif enemyButton:containPoint(mx, my) then
					spawnEnemy(enemyButton:getEnemyType(mx, my))
				end
			end
		end
		local check = self.noPitButton:update(dt)
		if check ~= nil then
			cheats.no_pit = check
		end
		check = self.enemyDebugButton:update(dt)
		if check ~= nil then
			cheats.enemy_debug = check
		end
	else
		if self.quitButton:update(dt) then
			game:push(PlayStateClosePrompt:new(function()
				game:clearObjects()
				GateBrick.ballCount = 0
				game:pop()
			end))
		end
	end
	if self.state == "intro" then
		if mouse.m1 == 1 then
			self:start()
		end
		local sweeper = self.sweeper
		if not sweeper.activated then
			local borders = self.movingBorders
			borders.left:update(dt)
			borders.right:update(dt)
			borders.top:update(dt)
			if borders.top.y <= window.ceiling-16 then
				borders.top.y = window.ceiling-16
				borders.left.x = window.lwallx-16
				borders.right.x = window.rwallx
				sweeper.activated = true
			end
		else
			sweeper.y = sweeper.y + sweeper.vy * dt
			if sweeper.vy < 0 then
				if sweeper.y <= window.ceiling then
					sweeper.vy = -sweeper.vy
				end
			else
				if sweeper.y > window.h then
					self:spawn()
				end
			end
		end
		return
	elseif self.state == "spawn" then
		game.paddle:update(dt)
		if mouse.m1 == 1 or game.paddle.spawnOrbs.done then
			self:start()
		end
		return
	elseif self.state == "death" then
		for _, p in pairs(game.particles) do p:update(dt) end
		util.remove_if(game.particles, function(v) return v:isDead() end, game.destructor)
		local newParticles = game.newObjects.particles
		for k, p in pairs(newParticles) do
			table.insert(game.particles, p)
			newParticles[k] = nil
		end
		self.deathTimer = self.deathTimer - dt
		if self.deathTimer <= 0 then
			if self.lives > 0 then
				self:spawn()
				self.lives = self.lives - 1
			else
				self.state = "gameover"
				campaignstate:record("gameover")
			end
		end
		return
	elseif self.state == "gameover" then
		return
	end

	--collision based events
	self:setBrickGrid() --uses grid-based partitioning

	for _, ball in pairs(game.balls) do
		--brick collisions
		--prioritizes collisions with bricks in a cross pattern before diagonals
		local bucket = self:getBrickBucket(ball)
		local temp = {}
		for brick, v in pairs(bucket) do 
			if v == 1 then
				table.insert(temp, 1, brick)
			else
				table.insert(temp, brick)
			end
		end
		for _, brick in pairs(temp) do
		-- for brick in pairs(bucket) do
			if ball:canHit(brick) then
				local check, norm = brick:checkBallHit(ball)
				if check then
					brick:onBallHit(ball, norm)
					if brick:isDead() then
						self.stalemateTimer = self.maxStalemate
					end
				end
			end
		end
		--enemy collisions
		for _, enemy in pairs(game.enemies) do
			if ball:canHit(enemy) then
				local check, norm = enemy:checkBallHit(ball)
				if check then
					enemy:onBallHit(ball, norm)
				end
			end
		end
		--paddle collisions
		if util.bboxOverlap({ball.shape:bbox()}, {game.paddle.shape:bbox()}) then
			if game.paddle:checkBallHit(ball) then
				game.paddle:onBallHit(ball)
			end
		end
	end

	-- for _, enemy in pairs(game.enemies) do
	-- 	if enemy.brickCol then
	-- 		local bucket = self:getBrickBucket(enemy)
	-- 		for brick, v in pairs(bucket) do
	-- 			local check, norm = enemy:checkBrickHit(brick) 
	-- 			if check then
	-- 				enemy:onBrickHit(brick, norm)
	-- 			end
	-- 		end
	-- 	end
	-- end

	for _, menacer in pairs(game.menacers) do
		--brick collisions
		--prioritizes collisions with bricks in a cross pattern before diagonals
		local bucket = self:getBrickBucket(menacer)
		local temp = {}
		for brick, v in pairs(bucket) do 
			if v == 1 then
				table.insert(temp, 1, brick)
			else
				table.insert(temp, brick)
			end
		end
		for _, brick in pairs(temp) do
		-- for brick in pairs(bucket) do
			local check, norm = brick:checkMenacerHit(menacer)
			if check then
				brick:onMenacerHit(menacer, norm)
			end
		end
		--enemy collisions
		for _, enemy in pairs(game.enemies) do
			local check, norm = enemy:checkMenacerHit(menacer)
			if check then
				enemy:onMenacerHit(menacer, norm)
			end
		end
		--paddle collisions
		if util.bboxOverlap({menacer.shape:bbox()}, {game.paddle.shape:bbox()}) then
			if menacer.shape:collidesWith(game.paddle.shape) then
				game.paddle:onMenacerHit(menacer)
			end
		end
	end

	for _, proj in pairs(game.projectiles) do
		local bucket = self:getBrickBucket(proj)
		--brick collisions
		if proj.colFlag.brick then
			for brick in pairs(bucket) do
				if proj:canHit(brick) then
					local check, norm = brick:checkProjectileHit(proj)
					if check then
						brick:onProjectileHit(proj, norm)
					end
				end
			end
			--if a projectile can hit bricks, then it should be able to hit enemys too
			for _, enemy in pairs(game.enemies) do
				if proj:canHit(enemy) then
					local check, norm = enemy:checkProjectileHit(proj)
					if check then
						enemy:onProjectileHit(proj, norm)
					end
				end
			end
		end
		if proj.colFlag.paddle then
			if util.bboxOverlap({proj.shape:bbox()}, {game.paddle.shape:bbox()}) then
				if proj.shape:collidesWith(game.paddle.shape) then
					game.paddle:onProjectileHit(proj)
				end
			-- elseif game.paddle.twin then
			-- 	if util.bboxOverlap({proj.shape:bbox()}, {game.paddle.twin.shape:bbox()}) then
			-- 		if proj.shape:collidesWith(game.paddle.twin.shape) then
			-- 			game.paddle:onProjectileHit(proj)
			-- 		end
			-- 	end
			-- end
			end
		end
	end

	--the paddle is able to destroy enemies on contact
	for _, dr in pairs(game.enemies) do
		if util.bboxOverlap({dr.shape:bbox()}, {game.paddle.shape:bbox()}) then
			if dr.shape:collidesWith(game.paddle.shape) then
				dr:onPaddleHit(game.paddle)
			end
		end
	end
	

	--handles powerup activation
	for _, pow in pairs(game.powerups) do
		local powbox = {pow.shape:bbox()}
		local padbox = {game.paddle.shape:bbox()}
		if util.bboxOverlap(powbox, padbox) then
			if game.paddle:canCollectPowerUp(pow) then
				game.paddle:collectPowerUp(pow)
			end
		elseif game.paddle.twin then
			if util.bboxOverlap(powbox, {game.paddle.twin.shape:bbox()}) then
				if game.paddle:canCollectPowerUp(pow) then
					game.paddle:collectPowerUp(pow)
				end
			end
		end
	end

	--time warp powerup
	if self.timeWarp then
		time_scale = math.pow(2, 1.5 * math.sin(12 * self.timeWarp / (2 * math.pi)))
		self.timeWarp = self.timeWarp + dt
		if self.timeWarp > 15 then
			self.timeWarp = nil
			time_scale = 1.0
		end
	end

	dt = dt * time_scale

	-- if self.mode == "test" then
	-- 	for _, b in pairs(game.balls) do
	-- 		if b.y + b:getR() > window.h then
	-- 			b:handleCollision(0, -1)
	-- 		end
	-- 	end
	-- end

	--updates all objects in all lists
	--if player dies or wins, then just update the particle effects
	if self.state == "victory" or self.state == "death" then
		for _, p in pairs(game.particles) do
			p:update(dt)
		end
	else
		for _, k in pairs(listTypes) do
			for _, v in pairs(game[k]) do
				v:update(dt)
			end
		end
	end
	game.paddle:update(dt)
	monitorManager:update()
	game.enemySpawner:update(dt)

	self:updateGates(dt)


	--stalemate resolution: If the ball is stuck somewhere and hasn't hit the paddle in a certain amount of time,
	--it will spawn a Re-Serve powerup that can cause all balls to be teleported back onto the paddle
	self.stalemateTimer = self.stalemateTimer - dt
	if self.stalemateTimer <= 0 then
		self.stalemateTimer = self.maxStalemate
		local reserve = PowerUp:new(window.w/2, window.ceiling + 50, 93)
		reserve.suppress = true
		reserve.vy = reserve.vy * 1.5
		game:emplace("powerups", reserve)
		playSound("stalemate")
	end

	--removes all dead objects; specialized method for balls
	for _, k in pairs(listTypes) do
		if k ~= "balls" then
			util.remove_if(game[k], function(v) return v:isDead() end, game.destructor)
		end
	end
	--temporarily removes balls if they are teleporting
	util.remove_if(game.balls, function(v) return v:isDead() or v.isTeleporting end, function(v) 
		if v:isDead() then 
			game.destructor(v)
			self.ballCount = self.ballCount - 1
		end
	end)

	--add objects from the object queue
	for str, list in pairs(game.newObjects) do
		local flag = #list > 0
		local t = game[str]
		for k, v in pairs(list) do
			if str ~= "balls" or self.ballCount < ball_limit + 1 or v.bypass_ball_limit then
				--limits the number of balls that can exist
				--maybe i should rewrite this section
				t[#t+1] = v
				v.bypass_ball_limit = nil
				self.ballCount = self.ballCount + 1
			else
				game.destructor(v)
			end
			list[k] = nil
		end
		--rearranges the drawing order for some of the lists
		if flag and (str == "bricks" or str == "particles") then
			draw_stable_sort(t)
		end
	end

	--resort the bricks if draw priority changes
	if game.sortflag then
		game.sortflag = nil
		draw_stable_sort(game.bricks)
	end

	--handle bricks moving due to movement patches
	Brick.manageMovement()

	--check for victory condition
	if self.mode == "play" and self.state ~= "victory" and self.state ~= "zoneselect" then
		if self:checkVictory() then
			self:setVictory()
		end
	end
	if self.bypass == "standby" then
		if game.paddle.x + game.paddle.w/2 >= window.rwallx and not game.paddle.autopilot then
			self.bypass = "activated"
			self:setVictory()
			game.paddle.bypass = "right"
			playSound("bypassexit")
		end
	end

	--calculate ball count
	self.ballCount = #game.balls + GateBrick.ballCount
	--respawn ball if there are no balls in play
	if self.ballCount == 0 then
		--test mode hase instant respawn
		if self.mode == "test" then
			self.lives = self.lives - 1
			self.timeWarp = nil
			time_scale = 1
			game.paddle:normal()
			local ball = Ball:new(window.w/2, window.h/2, Ball.defaultSpeed[difficulty], 0)
			game.paddle:attachBall(ball, "random")
			ball:updateShape()
			game:emplace("balls", ball)
			for _, br in pairs(game.bricks) do
				if br.brickType == "LaserEyeBrick" then
					br:reset()
				end
			end

			util.clear(game.environments, game.destructor)
			monitorManager:clear()
		elseif self.state ~= "death" and self.state ~= "zoneselect" then
			--if not game.paddle.flag.tested then
			self.state = "death"
			self.deathTimer = 3
			game.paddle:onDeath()
			game.paddle:destructor()
			game.paddle = nil

			util.clear(game.environments, game.destructor)
			util.clear(game.enemies, game.destructor)
			util.clear(game.powerups, game.destructor)
			util.clear(game.menacers, game.destructor)
			
			monitorManager:clear()
			--game.paddle.flag.tested = true
		end
	end
	if self.state == "victory" then
		self.victoryTimer = self.victoryTimer - dt
		if self.victoryTimer <= 0 then
			-- if self.zones and self.fileQueue:empty() then --implying filequeue exists
			-- 	if #self.zones >= 1 then
			-- 		local z1, z2 = self.zones[1], self.zones[2]
			-- 		local nodes = campaignstate.nodes
			-- 		self.state = "zoneselect"
			-- 		self.zonePreview = {}
			-- 		self.zonePreview[1] = self:getPreview(z1)
			-- 		self:openGate("bottom", 1)
			-- 		if #self.zones > 1 then
			-- 			self:openGate("bottom", 2)
			-- 			self.zonePreview[2] = self:getPreview(z2)
			-- 		end
			-- 		game:clearObjects(true)
			-- 		GateBrick.ballCount = 0
			-- 		return
			-- 	end
			-- end
			if not self.fadeOut then
				self.fadeOut = 0
			else
				self.fadeOut = self.fadeOut + dt * 255
				if self.fadeOut > 255 then
					if self.mode == "test" then
						game:clearObjects()
						GateBrick.ballCount = 0
						game:pop()
					else
						self:nextLevel()
					end
				end
			end
		end
	end
	-- if self.state == "zoneselect" then
	-- 	local paddle = game.paddle
	-- 	if not self.paddleExit then
	-- 		if self.gates.bottom[1].state == "opened" then
	-- 			if self.zones[2] and paddle.x + paddle.w/2 >= window.rwallx then
	-- 				paddle.bypass = "right"
	-- 				self.paddleExit = true
	-- 				campaignstate:advance(self.zones[2])
	-- 			elseif self.zones[1] and paddle.x - paddle.w/2 <= window.lwallx then
	-- 				paddle.bypass = "left"
	-- 				self.paddleExit = true
	-- 				campaignstate:advance(self.zones[1])
	-- 			end
	-- 		end
	-- 	elseif not self.fadeOut then
	-- 		if paddle.x - paddle.w/2 >= window.rwallx or paddle.x + paddle.w/2 <= window.lwallx then
	-- 			self.fadeOut = 0
	-- 		end
	-- 	else
	-- 		self.fadeOut = self.fadeOut + dt * 255
	-- 		if self.fadeOut > 255 then
	-- 			game:clearObjects()
	-- 			game:pop()
	-- 		end
	-- 	end
	-- end
end

--axis is "x" or "y", sign is 1 or -1 depening on which direction
function PlayState:brickCascade(br1, movingBricks, axis, sign) --make it recursive?
	local val, vel, perp
	if axis == "x" then
		val, vel, perp = 32, "vx", "y"
	else
		val, vel, perp = 16, "vy", "x"
	end
	for _, br2 in pairs(movingBricks) do
		if br2[perp] == br1[perp] and br2[vel] * br1[vel] < 0 and util.deltaEqual(br1[axis] + val*sign, br2[axis], val/5) then
			br2[axis] = br1[axis] + val*sign
			br2[vel] = -br2[vel]
			self:brickCascade(br2, movingBricks, axis, sign)
		end
	end
end

function PlayState:checkVictory(debug)
	for _, br in pairs(game.bricks) do
		if br.essential and not br.patch.invisible then
			return false 
		end
	end
	return true
end

function PlayState:setVictory()
	self.state = "victory"
	self.victoryTimer = 2
end

function PlayState:screenShake(magnitude, time)
	self.shake = {mag = magnitude, timer = time}
end

function PlayState:draw()
	local off = {x = 0, y = 0}
	if self.shake then
		local mag = self.shake.mag
		off.x = math.random(-mag, mag)
		off.y = math.random(-mag, mag)
		love.graphics.translate(off.x, off.y)
	end

	legacySetColor(self.background.r, self.background.g, self.background.b)
	love.graphics.rectangle("fill", window.lwallx + off.x, window.ceiling + off.y, window.boardw, window.boardh)
	if self.background.tile then
		local tile = self.background.tile
		local imgstr, rect = tile.imgstr, tile.rect
		legacySetColor(255, 255, 255, 255)
		local w = rect.w * 2
		local h = rect.h * 2
		local across = math.ceil(window.boardw / w)
		local down = math.ceil(window.boardh / h)
		for i = 1, down do
			for j = 1, across do
				draw(imgstr, rect, window.lwallx + w*(j-1), window.ceiling + h*(i-1), 0, w, h, 0, 0)
			end
		end
	end

	legacySetColor(187, 187, 187, 255)
	love.graphics.rectangle("fill", off.x, off.y, window.wallw, window.h)
	love.graphics.rectangle("fill", window.rwallx + off.x, off.y, window.wallw, window.h)
	love.graphics.rectangle("fill", window.lwallx + off.x, off.y, window.rwallx - window.lwallx, window.ceiling)
	
	drawscore = true

	if self.mode == "test" then
		legacySetColor(255, 255, 255, 255)
		local height = (window.h-window.ceiling)/320
		draw2("powerup_editor", nil, PlayState.powerupBox[1], PlayState.powerupBox[2], 0, pow_scale, pow_scale, 0, 0, 0, 0)

		-- legacySetColor(255, 255, 255, 255)
		-- for _, v in ipairs(PlayState.finishedPowerUpSprites) do
		-- 	local rect, x, y = unpack(v)
		-- 	draw2("powerup_spritesheet", rect, x, y, 0, pow_scale, pow_scale, 0, 0)
		-- end

		legacySetColor(0, 0, 0, 255)
		love.graphics.setFont(font["Munro20"])
		love.graphics.print("Powerup Spawner", window.rwallx  + 30, 40)
		
		love.graphics.setFont(font["Munro20"])
		love.graphics.print("Enemy Spawner", 10, 110 + 45)
		legacySetColor(255, 255, 255, 255)
		menacerButton:draw()
		enemyButton:draw()

		self.noPitButton:draw()
		self.enemyDebugButton:draw()
		love.graphics.setFont(font["Munro20"])
		legacySetColor(0, 0, 0, 255)
		love.graphics.print("Disable Pit", 35, 200 + 45)
		love.graphics.print("Enemy Debug", 35, 230 + 45)

		legacySetColor(255, 255, 255, 255)
		if tooltipManager.mode == "powerup" then drawscore = false end
		tooltipManager:draw()

		self.stopButton:draw()
	else
		self.quitButton:draw()
	end

	legacySetColor(0, 0, 0)
	love.graphics.setFont(font["Arcade20"])
	love.graphics.print(self.state, 10, window.h-60)

	--score drawing
	if drawscore then
		local scorestr = PlayState.getScoreStr(self.score)
		love.graphics.setColor(0, 0, 0)
		love.graphics.setFont(font["Arcade30"])
		love.graphics.print("Score", window.lwallx, 5)
		love.graphics.setFont(font["Arcade30"])
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(scorestr, window.lwallx, 35)
		love.graphics.setColor(0, 0, 0)
		love.graphics.setFont(font["Arcade20"])
		if self.scoreModifier == 0.5 then
			love.graphics.print("x0.5", window.lwallx + 115, 12)
		elseif self.scoreModifier == 2.0 then
			love.graphics.print("x2", window.lwallx + 115, 12)
		end
		--lives drawing
		love.graphics.setFont(font["Arcade20"])
		love.graphics.print("Lives: "..self.lives, window.lwallx + 200, 10)
	end

	legacySetColor(0, 0, 0)
	if self.mode == "test" then
		love.graphics.setFont(font["Windows32"])
		love.graphics.print("Test Mode", 10, 10)

		love.graphics.setFont(font["Windows16"])
		love.graphics.print("Press ESC to Return", 10, 105)
		legacySetColor(0, 0, 0, 255)
		love.graphics.print("# of Balls: "..self.ballCount, 10, 120)

		local maxspeed = 0
		for i, b in ipairs(game.balls) do
			maxspeed = math.max(maxspeed, b:getSpeed())
		end
		love.graphics.print("Ball Speed: "..math.floor(maxspeed+0.5), 10, 135)
	else
		love.graphics.setFont(font["Windows32"])
		love.graphics.print("Otaku-Ball", 10, 10)

		love.graphics.setFont(font["Windows16"])
		love.graphics.print("Press ESC to Exit", 10, 100)
		love.graphics.print("# of Balls: "..self.ballCount, 10, 115)
	end
	legacySetColor(255, 255, 255, 255)


	-- love.graphics.setFont(font["Munro20"])
	-- legacySetColor(0, 0, 0, 255)
	-- love.graphics.print("# of Balls: "..self.ballCount, 10, 70)
	-- legacySetColor(255, 255, 255, 255)

	monitorManager:draw()

	love.graphics.push("all")
	love.graphics.setCanvas(shadow_canvas)
	love.graphics.clear()
	
	if self.state ~= "intro" or self.sweeper.activated then
		legacySetColor(255, 255, 255, 255)
		draw(
			"border", 
			nil, 
			window.w/2, 
			window.ceiling + (window.h - window.ceiling) / 2 - 8, 
			0, 
			224*2,--window.rwallx - window.lwallx + 32, 
			264*2--window.h - window.ceiling + 16
		)
		self:drawGates()
	end
	if self.state == "intro" then
		if self.sweeper.vy > 0 then
			love.graphics.setScissor(window.lwallx, window.ceiling, window.boardw, math.max(0, self.sweeper.y - window.ceiling))
			for k, v in pairs(game.bricks) do v:draw() end
			love.graphics.setScissor()
		end
		--game.paddle:draw()
		--for k, v in pairs(game.balls) do v:draw() end

		legacySetColor(128, 128, 128, 255)
		love.graphics.rectangle("fill", self.sweeper.x, self.sweeper.y, self.sweeper.w, self.sweeper.h)

		for _, b in pairs(self.movingBorders) do
			b:drawAlt()
		end
	else
		--every thing else drawing
		--drawing order is actually important
		local blackout, oldie, undestructible
		for k, v in pairs(game.environments) do 
			if v.blackout then 
				blackout = v 
			elseif v.oldie then
				oldie = v
			elseif v.undestructible then
				undestructible = v
			else
				v:draw() 
			end 
		end
		for k, v in pairs(game.bricks) do v:draw() end
		if blackout then blackout:draw() end
		if oldie then oldie:draw() end
		if undestructible then undestructible:draw() end
		for k, v in pairs(game.projectiles) do v:draw() end
		if game.paddle then game.paddle:draw() end
		for k, v in pairs(game.particles) do v:draw() end
		for k, v in pairs(game.powerups) do v:draw() end
		for k, v in pairs(game.enemies) do v:draw() end
		for k, v in pairs(game.menacers) do v:draw() end
		for k, v in pairs(game.balls) do v:draw() end
	end
	if self.state == "spawn" then
		legacySetColor(255, 255, 255, 255)
		love.graphics.setFont(font["Arcade40"])
		love.graphics.printf("ROUND "..self.round.."\nREADY", window.lwallx, window.h - 175, window.boardw, "center")
	elseif self.state == "victory" then
		local width = window.rwallx - window.lwallx
		legacySetColor(255, 255, 255, 255)
		love.graphics.setFont(font["Arcade40"])
		love.graphics.printf("ROUND CLEAR", window.lwallx, window.h - 150, width, "center")
	elseif self.state == "gameover" then
		local width = window.rwallx - window.lwallx
		legacySetColor(255, 255, 255, 255)
		love.graphics.setFont(font["Arcade40"])
		love.graphics.printf("GAME OVER", window.lwallx, window.h - 150, width, "center")
	elseif self.state == "zoneselect" then
		legacySetColor(255, 255, 255, 255)
		love.graphics.setFont(font["Arcade20"])
		love.graphics.print("Zone "..self.zones[1], window.lwallx + 10, window.h - 80)
		love.graphics.draw(self.zonePreview[1], window.lwallx, window.h/2 - 50)
		if self.zones[2] then
			local text = "Zone "..self.zones[2]
			local width = font["Arcade20"]:getWidth(text)
			love.graphics.print(text, window.rwallx - width - 10, window.h - 80)
			love.graphics.draw(self.zonePreview[2], window.w/2, window.h/2 - 50)
		end
	end

	-- love.graphics.setCanvas()
	love.graphics.pop()

	--draw the shadow first
	local shift = 8
	love.graphics.translate(shift, shift)
	legacySetColor(0, 0, 0, 128)
	love.graphics.setScissor(window.lwallx, window.ceiling, window.boardw, window.boardh)
	love.graphics.draw(shadow_canvas)
	love.graphics.setScissor()
	legacySetColor(255, 255, 255, 255)
	love.graphics.translate(-shift, -shift)
	love.graphics.draw(shadow_canvas)

	--lives indicator
	legacySetColor(255, 255, 255, 255)
	if self.lives > 5 then
		draw("paddle_life", nil, window.lwallx, window.h - 16, 0, 32, 16, 0, 0)
		love.graphics.setFont(font["Arcade20"])
		love.graphics.print(self.lives, window.lwallx + 32, window.h - 18)
	else
		for i = 1, self.lives do
			draw("paddle_life", nil, window.lwallx + (i-1)*32, window.h - 16, 0, 32, 16, 0, 0)
		end
	end

	--fadeout
	if self.fadeOut then
		legacySetColor(0, 0, 0, self.fadeOut)
		love.graphics.rectangle("fill", 0, 0, window.w, window.h)
	end
end

local function ss_comp(a, b)
	local p1 = a.drawPriority
	local p2 = b.drawPriority
	local i1 = a.stable_sort_index
	local i2 = b.stable_sort_index
	if p1 < p2 then return true end
	if p1 == p2 then return i1 < i2 end
	return false
end

function draw_stable_sort(t)
	for i, v in ipairs(t) do v.stable_sort_index = i end
	table.sort(t, ss_comp)
	for i, v in ipairs(t) do v.stable_sort_index = nil end
end

function PlayState:close()
	love.audio.stop()
	soundMonitor:deactivate()
	time_scale = 1.0
	playstate = nil
	for k, v in pairs(cheats) do 
		cheats[k] = false
	end
end

--this algorithm also checks to see if the brick is aligned to the grid
function PlayState:setBrickGrid()
	for i = 1, 32 do
		for j = 1, 13 do
			self.brickGrid[i][j] = {}
		end
	end
	local bricks = game.bricks
	for n = 1, #bricks do
		local brick = bricks[n]
		brick.alignedToGrid = true
		--does not work if brick dimensions are not 32 x 16
		local x, y = brick:getPos()
		local i, j = getGridPos(x, y)
		--if brick is out of bounds, then it will not be collided at all
		if not boundCheck(i, j) then goto stop1 end
		local offx = (x - window.lwallx) % 32
		local offy = (y - window.ceiling) % 16
		table.insert(self.brickGrid[i][j], brick)
		if offx == 16 and offy == 8 then goto stop1 end
		--if the brick is not right at the center of the cell, then we have
		--to check if it is contained in the adjacent cells
		brick.alignedToGrid = nil
		local box = {brick.shape:bbox()}
		for a = -1, 1 do 
		for b = -1, 1 do
			local ii, jj = i+a, j+b
			if a == 0 and b == 0 then goto continue1 end
			if not boundCheck(ii, jj) then goto continue1 end
			if util.bboxOverlap(box, self.rectGrid[ii][jj]) then
				table.insert(self.brickGrid[ii][jj], brick)
			end
			::continue1::
		end 
		end
		::stop1::
	end
end

--REMEMBER THE BRICKS ARE THE KEYS NOT THE VALUES
--The values for each key represent the priority in which the object should test for collision.
--The bricks that should be tested first should be the bricks that are in a cross-pattern from the
--center cell as those bricks are more likely exposed to the object than the corner bricks.
--I'm not sure how this would perform with bigger balls though.
function PlayState:getBrickBucket(sprite)
	local x, y = sprite:getPos()
	local i, j = getGridPos(x, y)
	local box = {sprite.shape:bbox()}
	local w, h = box[3] - box[1], box[4] - box[2]
	--bigger objects require a larger search radius
	local rj = math.ceil(w / (32 * 2))
	local ri = math.ceil(h / (16 * 2))
	local bucket = {}
	for a = -ri, ri do
	for b = -rj, rj do
		local ii, jj = i+a, j+b
		if not boundCheck(ii, jj) then goto continue1 end
		if util.bboxOverlap(box, self.rectGrid[ii][jj]) then
			for k, br in pairs(self.brickGrid[ii][jj]) do
				if not bucket[br] and (a == 0 or b == 0) and br.alignedToGrid then
					bucket[br] = 1
				else
					bucket[br] = 2
				end
			end
		end
		::continue1::
	end
	end
	return bucket
end

--static method
--retrieves a powerup id based on which button the mouse is pressing
function PlayState.getPowerUpId(mx, my)
	--translated from c++ so expect 0-indexing at first
	local x, y, w, h = unpack(PlayState.powerupBox)
	w = math.floor(w / 4)
	h = math.floor(h / 40)
	local col = math.floor((mx - x) / w)
	local row = math.floor((my - y) / h)
	if row < 0 or row > 39 or col < 0 or col > 3 then
		return 0
	end

	local id = -1
	if col == 0 or col == 1 then
		id = (col * 40) + row
	elseif col == 2 then
		if row < 37 then
			id = 80 + row
		end
	elseif col == 3 then
		if row < 18 then
			id = 117 + row
		end
	end
	return id + 1
end

function PlayState:incrementScore(points)
	self.score = self.score + points * self.scoreModifier
end

--leading zeroes will be gray
--significant digits will be black
function PlayState.getScoreStr(score, color1, color2)
	color1 = color1 or 0.5
	color2 = color2 or 0
	local sig = tostring(score)
	if score >= 100000000 then
		sig = "99999999"
	end
	local lead = ""
	for i = #sig, 8-1 do
		lead = lead.."0"
	end
	return {{color1, color1, color1}, lead, {color2, color2, color2}, sig}
end

PlayStateClosePrompt = class("PlayStateClosePrompt")

function PlayStateClosePrompt:initialize(callback)
	self.callback = callback
	local text = "Are you sure you want to exit this game? Progress will not be saved."
	self.box = MessageBox:new(window.w/2 - 200, window.h/2 - 75, 400, 150, "Confirm Exit", text)
	local b1 = Button:new(0, 0, 90, 30, {text = "Yes", font = font["Arcade20"]})
	local b2 = Button:new(0, 0, 90, 30, {text = "No", font = font["Arcade20"]})
	self.box:addButton(b1, 200, 110)
	self.box:addButton(b2, 300, 110)
end

function PlayStateClosePrompt:update(dt)
	--self.box:update(dt)
	if self.box.buttons[1]:update(dt) or keys["return"] then
		self.callback()
		game:pop()
	end
	if self.box.buttons[2]:update(dt) or keys.escape then
		game:pop()
	end
end

function PlayStateClosePrompt:draw()
	--draw the state before it too
	game.states[#game.states-1]:draw()
	self.box:draw()
end
