enemySpawner = {timer = 2, flag = {}}

function enemySpawner:initialize(flag, t0, t1, t2)
	self.flags = {}
	for k, v in pairs(flag) do
		if v then
			if k == "redgreen" then
				table.insert(self.flags, "red")
				table.insert(self.flags, "green")
			else
				table.insert(self.flags, k)
			end
		end
	end
	self.timer = t0 or 2
	self.minTime = t1 or 2
	self.maxTime = t2 or 8
	self.state = "waiting" --waiting, deploying
	-- self.gates = playstate.gates.top
	self.deployment = {}
end

function enemySpawner:update(dt)
	self.timer = self.timer - dt
	if self.timer <= 0 then
		self.timer = math.random(self.minTime, self.maxTime)

		local names = {"cyan", "bronze", "silver", "pewter", "red", "green"}
		local names2 = {"dizzy", "cubic", "gumballtrio", "walkblock"}
		local enemyLookup = util.generateLookup(names2)
		local enemyCount = {}
		local greenBrickCount = 0

		--for menacer droppers: count the # of menacer balls
		--for other enemies: count the # of enemies
		for i, v in ipairs(names) do
			enemyCount[v] = 0
		end
		for i, v in ipairs(names2) do
			enemyCount[v] = 0
		end
		for _, menacer in pairs(game.menacers) do
			local t = menacer.menacerType
			enemyCount[t] = enemyCount[t] + 1
		end
		for _, enemy in pairs(game.enemies) do
			local t = enemy.gameType
			if enemyLookup[t] then
				enemyCount[t] = enemyCount[t] + 1
			end
		end
		for _, br in pairs(game.bricks) do
			if br.brickType == "GreenBrick" then
				greenBrickCount = greenBrickCount + 1
			end
		end

		local choices = {}
		for i, n in ipairs(self.flags) do
			--separates the menacer droppers from the regular enemies
			if enemyCount[n] < 3 then
				if n == "red" then
					if greenBrickCount > 0 then
						table.insert(choices, n)
						table.insert(choices, n) --one more to increase the chances
					end
				elseif n == "cyan" then
					if not game.paddle.flag.shadow then
						table.insert(choices, n)
					end
				else
					table.insert(choices, n)
				end
			end
		end

		if #choices > 0 then
			spawnEnemy(choices[math.random(#choices)])
		end
	end
	--the enemy wont spawn until the gate is fully opened
	util.remove_if(self.deployment, function(dropper)
		if dropper.gate.state == "opened" then
			game:emplace("enemies", dropper)
			return true
		end
		return false
	end)
end

--It is the Enemy Object's responsibility to travel straight downwards from the gate
function enemySpawner:placeInGate(enemy)
	local gates = playstate.gates.top
	local candidates = {}
	for _, gate in ipairs(gates) do
		if not gate.enemy and gate.state == "closed" then
			table.insert(candidates, gate)
		end
	end
	if #candidates == 0 then
		return false
	end
	local gate = candidates[math.random(#candidates)]
	gate.state = "opening"
	gate.target = enemy.w

	local x = gate.middle + 2
	local y = window.ceiling - 16 - enemy.h/2
	enemy:setPos(x, y)
	enemy.gate = gate
	gate.enemy = enemy
	enemy:setState("emerging")

	table.insert(self.deployment, enemy)
	return true
end

function enemySpawner:spawnEnemy(enemyType)
	local lookup = {
		dizzy = Dizzy,
		cubic = Cubic,
		gumballtrio = GumballTrio,
		walkblock = WalkBlock,
		dropball = DropBall,
	}
	local enemyClass = lookup[enemyType]
	local enemy = nil
	if not enemyClass then
		enemy = Dropper:new(0, 0, 0, 0, enemyType)
	else
		enemy = enemyClass:new()
	end
	self:placeInGate(enemy)
end

function spawnEnemy(enemyType)
	enemySpawner:spawnEnemy(enemyType)
end

Enemy = class("Enemy", Sprite)

--[[
Enemies:
	Dizzy(blue cup) is 20 x 32 pixels big
	Cubic
	WalkBlock
	Gumball Trio
]]

Enemy.states = {
	emerging = { --When the enemy enters the board from a gate
		init = function(self)
			self.vx = 0
			self.vy = self.speed
		end,
		update = function(self, dt)
			if self.y - self.h/2 > window.ceiling then
				self:advanceState()
				if self.gate then
					self.gate.state = "closing"
					self.gate.enemy = nil
					self.gate = nil
				end
			end
		end,
	},
	targetmove = { --Moving to a targeted position(better not be the same position)
		init = function(self, x, y, spd)
			local dx, dy = x - self.x, y - self.y
			self.vx = dx
			self.vy = dy
			self:scaleVelToSpeed(spd)
			if dx ~= 0 then
				self.distx = math.abs(dx)
				self.disty = nil
			else
				self.distx = nil
				self.disty = math.abs(dy)
			end
			self.targetx, self.targety = x, y
		end,
		update = function(self, dt)
			check = false
			if self.distx then
				self.distx = self.distx - math.abs(self.vx * dt)
				if self.distx <= 0 then check = true end
			else
				self.disty = self.disty - math.abs(self.vy * dt)
				if self.disty <= 0 then check = true end
			end
			if check then
				self:advanceState()
			end
		end
	},
	circleturn = { --Moving in a circle at a certain speed for a certain angular distance
		--x, y are the center
		init = function(self, x, y, rad, spd)
			local dx, dy = x - self.x, y - self.y
			self.vx, self.vy = 0, 0
			self.cx, self.cy = x, y
			self.cr = math.sqrt(dx*dx + dy*dy)
			self.vtheta = -spd / self.cr
			self.theta = math.atan2(dy, dx)
			self.dtheta = rad
		end,
		update = function(self, dt)
			local dth = self.vtheta*dt
			self.theta = self.theta + dth
			local dx, dy = util.rotateVec2(-self.cr, 0, self.theta)
			self.x, self.y = self.cx + dx, self.cy + dy
			self.dtheta = self.dtheta - math.abs(dth)
			if self.dtheta <= 0 then
				self:advanceState()
			end
		end
	},
	sinemove = { --Move in a horizontal sine wave
		--will automatically bounce back and forth between the borders
		--will also slowly descend (just add a vertical velocity to it)
		init = function(self, dir)
			self.xi = self.x --dy is a function of xi - self.x
			self.yi = self.y
			self.vx = self.spd * ((dir == "right") and 1 or -1)
			self.vy = 10
			self.amp = 50 --amplitude
			self.f = 0.1 --frequency
		end,
		update = function(self, dt)
			local dx = self.xi - self.x
			local dy = self.amp * (math.cos(self.f*dx) - 1)
			self.y = self.yi + dy
			self.yi = self.yi + self.vy * dt
			if self.x - self.w/2 < window.lwallx then
				-- self.y = self.yi
				self.vx = -self.vx
			elseif self.x + self.w/2 > window.rwallx then
				-- self.y = self.yi
				self.vx = -self.vx
			end
		end
	},
	tracingdown = { --Move down until collision with brick
		init = function(self)
			self.vx = 0
			self.vy = self.speed
		end,
		update = function(self, dt)
			local check, norm = self:scanBrickHit()
			if check then
				if self:pTranslate(norm.x, norm.y) then
					self:advanceState()
				else
					self:advanceState{skip = true}
				end
			end
			--scan any bricks that are below the enemy in a straight line
			local x, y, w, h = self.x, self.y, self.w, self.h
			local i1, j1 = getGridPos(x-w/2+2, y)
			local i2, j2 = getGridPos(x+w/2-2, y)
			local check = false
			--i is row, j is col
			for j = j1, j2 do
				for i = i1, 32 do
					if boundCheck(i, j) then
						local t = playstate.brickGrid[i][j]
						for k, brick in pairs(t) do
							if self:canHitBrick(brick) then
								check = true
							end
						end
					end
				end
			end
			if check then 
				self.dropTime = Dizzy.dropTimeLimit
			else
				self.dropTime = self.dropTime - dt
			end
			if self.dropTime <= 0 then
				self:advanceState()
			end
		end
	},
	tracingside = { --Move side to side until there is space below; will bounce off walls and side bricks
		init = function(self)
			if not self.prevSideDir then
				self.prevSideDir = ((math.random(0, 1) == 1) and -1 or 1)
			end
			self.vx = self.speed * self.prevSideDir
			if math.random() > 0.25 then
				self.prevSideDir = self.prevSideDir * -1
			end
			self.vy = 0
			self.dir = nil
		end,
		update = function(self, dt)
			local check, norm = self:scanBrickHit()
			if check then
				self.dir = (norm.x < 0) and "right" or "left"
				if self:pTranslate(norm.x, norm.y) then
					self:advanceState()
				else
					self:advanceState{skip = true}
				end
				return
			end
			if (self.x - self.w/2 < window.lwallx) then
				self.x = self.x + 1
				self.dir = "up"
				self:advanceState()
			end
			if (self.x + self.w/2 > window.rwallx) then
				self.x = self.x - 1
				self.dir = "up"
				self:advanceState()
			end
			--check for bricks below the enemy
			if self.graceTimer then
				self.graceTimer = self.graceTimer - dt
				if self.graceTimer <= 0 then
					self.graceTimer = nil
				end
			else
				self:translate(0, self.h/2)
				local hit = self:scanBrickHit()
				self:translate(0, -self.h/2)
				if not hit then
					self:advanceState()
				end
			end
			-- if self.x - self.w/2 < window.lwallx  then self.vx = math.abs(self.vx) end
			-- if self.x + self.w/2 > window.rwallx  then self.vx = -math.abs(self.vx) end
		end
	},
	tracingup = { --Climb up a stack of bricks until it finds an opening to the side or hits the ceiling
		init = function(self) --left or right?
			self.sideFlag = false
			self.vx = 0
			self.vy = -self.speed
		end,
		update = function(self, dt)
			if self.dir ~= "up" then
				--check if there is an opening to the side
				local off = (self.dir == "right") and self.w/2 or -self.w/2
				self:translate(off, 0)
				local hit = self:scanBrickHit()
				self:translate(-off, 0)
				if not hit then
					self.sideFlag = true
					self:advanceState()
					return
				end
			end
			--check if it hits ceiling or bricks
			if self.y - self.h/2 < window.ceiling then
				self:advanceState()
				return
			end
			local check, norm = self:scanBrickHit()
			if check then
				if self:pTranslate(norm.x, norm.y) then
					self:advanceState()
				else
					self:advanceState{skip = true}
				end
			end
		end
	},
	pause = { --Debug function that freezes the enemy
		init = function(self)
			self.vx = 0
			self.vy = 0
		end,
		update = function(self, dt)
		end
	}
}
for k, v in pairs(Enemy.states) do
	v.name = k
end

function Enemy:initialize(imgstr, rect, w, h, x, y, vx, vy, angle)
	Sprite.initialize(self, imgstr, rect, w, h, x, y, vx, vy, angle)
	self:setShape(shapes.newRectangleShape(0, 0, self.w, self.h))
	self.gameType = "enemy"
	self.state = nil
	self.speed = self:getSpeed() --will be used in some states
	self.health = 10
	self.deathAni = "EnemyDeath2"
	self.deathSound = "enemydeath"
end

function Enemy:destructor()
	if self.gate then
		self.gate.state = "closing"
		self.gate.enemy = nil
	end
	Sprite.destructor(self)
end

function Enemy:onDeath()
	if not self.suppress then
		local p = Particle:new("enemy", rects.enemy.death[5], 32, 32, self.x, self.y, 0, 0, 0, 1)
		p.color.a = 192
		p:playAnimation(self.deathAni)
		game:emplace("particles", p)
		playSound(self.deathSound)
		playstate:incrementScore(100)
	end
	Sprite.onDeath(self)
end

function Enemy:setState(name, ...)
	local args = {...}
	local state = Enemy.states[name]
	if not state then return end
	self.state = state
	self.state.init(self, unpack(args))
end

--pTranslate = Protected Translate
--will translate Enemy by the offset and then check for collision with bricks
--if there is collision, then undo the translate and return false
--otherwise return true
function Enemy:pTranslate(dx, dy)
	self:translate(dx, dy)
	local x, y = self:getPos()
	local w, h = self:getDim()
	w, h = w/4, h/4
	if x + w < window.lwallx or 
	   x - w > window.rwallx or
	   y + h < window.ceiling then
	   self:translate(-dx, -dy)
	   return false
	end
	if self:scanBrickHit() then
		self:translate(-dx, -dy)
		return false
	end
	return true
end

--checks to see if Enemy collides with any bricks
function Enemy:scanBrickHit()
	local bucket = playstate:getBrickBucket(self)
	for br, v in pairs(bucket) do
		local check, norm = self:checkBrickHit(br)
		if check then
			return check, norm, br
		end
	end
	return false
end

local ignore = util.generateLookup({"ForbiddenBrick", "Conveyor"})
function Enemy:canHitBrick(brick)
	if not brick.alignedToGrid then return false end
	local t = brick.brickType
	if ignore[t] then return false end
	if (t == "FlipBrick" or t == "StrongFlipBrick") and not t.state then
		return false
	end
	return true
end

function Enemy:checkBrickHit(brick)
	if not self:canHitBrick(brick) then return false end
	local box1 = {self.shape:bbox()}
	local box2 = {brick.shape:bbox()}
	if not util.bboxOverlap(box1, box2) then return false end
	local check, mtvx, mtvy = self.shape:collidesWith(brick.shape)
	if not check then return false end
	local norm = {x = mtvx, y = mtvy}
	return true, norm
end

function Enemy:onBrickHit(brick, norm)

end

--this works with circular hitboxes i think
function Enemy:checkBallHit(ball)
	return Brick.checkBallHit(self, ball)
end

function Enemy:onBallHit(ball, norm)
	self:kill()
	ball:onEnemyHit(self, norm)
end

function Enemy:checkMenacerHit(menacer)
	if self.menacer == menacer then return false end
	return Brick.checkMenacerHit(self, menacer)
end

function Enemy:onMenacerHit(menacer, norm)
	self:kill()
	menacer:onEnemyHit(self, norm)
end

function Enemy:checkProjectileHit(proj)
	return Brick.checkProjectileHit(self, proj)
end

function Enemy:onProjectileHit(proj, norm)
	if proj.strength >= 1 then
		self.health = self.health - proj.damage
		if self.health <= 0 then
			self:kill()
		end
	end
	proj:onEnemyHit(self, norm)
end

function Enemy:onPaddleHit(paddle)
	self:kill()
end

--this is where the subclasses can be different
function Enemy:advanceState()
	self.state = nil
end

function Enemy:update(dt)
	if self.state then
		self.state.update(self, dt)
	end
	if self.y - self.h > window.h then
		self.suppress = true
		self:kill()
	end
	Sprite.update(self, dt)
end

function Enemy:draw()
	love.graphics.setScissor(0, window.ceiling - 16, window.w, window.h)
	Sprite.draw(self)
	if cheats.enemy_debug and self.state then
		legacySetColor(255, 255, 255, 255)
		love.graphics.setLineStyle("rough")
		love.graphics.setLineWidth(1)
		if self.state.name == "circleturn" then
			love.graphics.circle("line", self.cx, self.cy, self.cr)
		elseif self.state.name == "targetmove" then
			love.graphics.line(self.x, self.y, self.targetx, self.targety)
		elseif self.state.name == "tracingdown" then
			local n = string.format("%.1f", self.dropTime)
			legacySetColor(128, 255, 128)
			love.graphics.setFont(font["Arcade20"])
			love.graphics.print(n, self.x, self.y)
		elseif self.state.name == "sinemove" then
			local points = {}
			for i = window.lwallx, window.rwallx do
				local dy = self.amp * (math.cos(self.f * (self.xi - i)) - 1)
				table.insert(points, i)
				table.insert(points, self.yi + dy)
			end
			love.graphics.points(points)
		end
	end
	love.graphics.setScissor()
end



--Dizzy is 20x32
Dizzy = class("Dizzy", Enemy)

Dizzy.spd = 40
Dizzy.dropTimeLimit = 3
-- Dizzy.sideTimeLimit = 6
function Dizzy:initialize()
	Enemy.initialize(self, "enemy", rects.enemy.dizzy[1], 20, 32, 0, 0, 0, Dizzy.spd)
	self.dropTime = Dizzy.dropTimeLimit
	-- self.sideTime = Dizzy.sideTimeLimit
	self.stage = "down" --up or down
	self:playAnimation("Dizzy", true)
	self.gameType = "dizzy"
end

--tracing down: switch to tracing side when collided with anything
--tracing side: regular hitbox: if still colliding with something, reverse direction
--              regular hitbox+1: if collided with hitbox + 1 then do nothing
--              else: switch to tracing down


--rotate down -> move left/right -> rotate up -> move left/right -> repeat
--rotate down must be larger than rotate up

function Dizzy:advanceState(arg) --arg is a table with named arguments
	if not self.state then return end
	arg = arg or {}

	local name = nil
	local s = self.reverse and -1 or 1
	if arg.skip then
		self.speed = 60
		self:setState("targetmove", self.x, self.y + 100, self.speed)
		self.stage = "special"
	elseif self.state.name == "emerging" then
		if self:scanBrickHit() then
			self.speed = 60
			self:setState("targetmove", self.x, self.y + 100, self.speed)
			self.stage = "special"
		else
			self:setState("tracingdown")
		end
	elseif self.state.name == "tracingdown" then
		if self.dropTime <= 0 then
			self.speed = 60
			if self.x < window.w/2 then
				self:setState("circleturn", self.x + math.random(16, 64), self.y, math.pi/2, self.speed)
			else
				self.reverse = true
				self:setState("circleturn", self.x - math.random(16, 64), self.y, math.pi/2, -self.speed)
			end
		else
			self:setState("tracingside")
			self.dropTime = Dizzy.dropTimeLimit
		end
	elseif self.state.name == "tracingside" then
		if self.dir then
			self:setState("tracingup")
		else
			self:setState("tracingdown")
		end
	elseif self.state.name == "tracingup" then
		if self.sideFlag then
			self:setState("tracingside")
			self.graceTimer = 0.1
		else
			self:setState("tracingdown")
		end
	elseif self.state.name == "circleturn" then
		local stage = self.stage
		if self.reverse then
			stage = (stage == "down") and "up" or "down"
		end
		if stage == "down" then
			self:setState("targetmove", math.random(self.x+10, window.rwallx-32), self.y, self.speed)
		else
			self:setState("targetmove", math.random(window.lwallx+64, self.x-10), self.y, self.speed)
		end
	elseif self.state.name == "targetmove" then
		if self.stage == "down" then
			self.stage = "up"
			self:setState("circleturn", self.x, self.y - math.random(16, 32), math.pi, s*self.speed)
		elseif self.stage == "up" then
			self.stage = "down"
			self:setState("circleturn", self.x, self.y + math.random(32, 64), math.pi, s*self.speed)
		else --self.stage == "special"
			self.stage = "down"
			if self.x < window.w/2 then
				self:setState("circleturn", self.x + math.random(16, 64), self.y, math.pi/2, self.speed)
			else
				self.reverse = true
				self:setState("circleturn", self.x - math.random(16, 64), self.y, math.pi/2, -self.speed)
			end
		end
	end
	if not name then name = self.state.name end
	-- print("Advance: "..name)
end

Cubic = class("Cubic", Dizzy)

function Cubic:initialize()
	Dizzy.initialize(self)
	self.rect = rects.enemy.cubic[1]
	self:setDim(30, 32)
	self:setShape(shapes.newRectangleShape(0, 0, self.w, self.h))
	self:playAnimation("Cubic", true)
	self.gameType = "cubic"
end

--Gumball Trio is composed of 3 sprites rotating around eachother
GumballTrio = class("GumballTrio", Enemy)

GumballTrio.spd = 50
GumballTrio.ballSpd = Ball.defaultSpeed[difficulty]
function GumballTrio:initialize()
	self.r = 8 --this is the distance between the ball's center and the true center
	local w = (self.r + 6)*2
	Enemy.initialize(self, nil, nil, w, w, 0, 0, 0, GumballTrio.spd)
	self:setShape(shapes.newCircleShape(0, 0, self.r + 6))
	self.dropTime = Dizzy.dropTimeLimit
	self.stage = "down" --up or down
	self.angle = 0
	self.angularVel = 100
	self.gumballSpd = GumballTrio.ballSpd
	self.balls = {}
	local ballLookup = {"Red", "Yellow", "Blue"}
	for i = 1, 3 do
		--Gumball is an Enemy but inherits some attributes from Projectile and bouncy
		--Needs to collide with ball, projectile, paddle, brick (maybe not enemy)
		local color = ballLookup[i]
		local rect = rects.enemy.gumball.normal[color:lower()][1]
		local b = Enemy:new("enemy", rect, 12, 12)
		b:setShape(shapes.newCircleShape(0, 0, 6))
		b.shapeType = "circle"
		b.damage = 10
		b.strength = 1
		b.deathAni = "EnemyDeath3"
		b.gametype = "gumball"
		b.ballColor = color
		b:playAnimation(color.."GumballBlink", true)
		b.update = function(ball, dt)
			local check, norm, brick = ball:scanBrickHit()
			if check then
				brick:onProjectileHit(ball, norm)
			end
			local x, y = ball:getPos()
			local r = ball.shape._radius
			if x - r < window.lwallx  then ball:handleCollision( 1,  0) end
			if x + r > window.rwallx  then ball:handleCollision(-1,  0) end
			if y - r < window.ceiling then ball:handleCollision( 0,  1) end
			Enemy.update(ball, dt)
		end
		b.checkBrickHit = function(ball, brick)
			if not ball:canHitBrick(brick) then return false end
			return brick:checkProjectileHit(ball)
		end
		b.onBrickHit = function(ball, brick, norm)
			ball:translate(norm.x, norm.y)
			ball:handleCollision(norm.x, norm.y)
		end
		b.validCollision = Projectile.validCollision
		b.handleCollision = Projectile.handleCollision
		self.balls[i] = b
	end
	self:updateBalls(0)
	self.gameType = "gumballtrio"
end

function GumballTrio:onDeath()
	if not (self.suppress or self.suppressSplit) then
		for i, b in ipairs(self.balls) do
			local vx, vy = util.rotateVec(0, -self.gumballSpd, self.angle + (i-1)*120)
			b:setVel(vx, vy)
			b:playAnimation(b.ballColor.."GumballSplit", true)
			game:emplace("enemies", b)
		end
		self.balls = nil
	end
	Enemy.onDeath(self)
end

function GumballTrio:onPaddleHit(paddle)
	self.suppressSplit = true
	Enemy.onPaddleHit(self, paddle)
end

function GumballTrio:onBallHit(ball, norm)
	self.gumballSpd = ball:getSpeed()
	Enemy.onBallHit(self, ball, norm)
end

function GumballTrio:update(dt)
	self:updateBalls(dt)
	Enemy.update(self, dt)
end

function GumballTrio:updateBalls(dt)
	self.angle = self.angle + self.angularVel*dt
	if self.angle >= 360 then
		self.angle = self.angle - 360
	end
	for i, b in ipairs(self.balls) do
		local dx, dy = util.rotateVec(0, -self.r, self.angle + (i-1)*120)
		b:setPos(self.x + dx, self.y + dy)
		Sprite.update(b, dt) --to get it to animate
	end
end

function GumballTrio:advanceState(arg)
	if not self.state then return end
	arg = arg or {}

	local name = nil
	local s = self.reverse and -1 or 1
	if arg.skip then
		self.speed = 60
		self:setState("targetmove", self.x, self.y + 100, self.speed)
		self.stage = "special"
	elseif self.state.name == "emerging" then
		if self:scanBrickHit() then
			self.speed = 60
			self:setState("targetmove", self.x, self.y + 100, self.speed)
			self.stage = "special"
		else
			self:setState("tracingdown")
		end
	elseif self.state.name == "tracingdown" then
		if self.dropTime <= 0 then
			self.speed = 60
			if self.x < window.w/2 then
				self:setState("circleturn", self.x + math.random(16, 64), self.y, math.pi/2, self.speed)
			else
				self.reverse = true
				self:setState("circleturn", self.x - math.random(16, 64), self.y, math.pi/2, -self.speed)
			end
		else
			self:setState("tracingside")
			self.dropTime = Dizzy.dropTimeLimit
		end
	elseif self.state.name == "tracingside" then
		if self.dir then
			self:setState("tracingup")
		else
			self:setState("tracingdown")
		end
	elseif self.state.name == "tracingup" then
		if self.sideFlag then
			self:setState("tracingside")
			self.graceTimer = 0.1
		else
			self:setState("tracingdown")
		end
	elseif self.state.name == "circleturn" then
		local stage = self.stage
		if self.reverse then
			stage = (stage == "down") and "up" or "down"
		end
		if stage == "down" then
			self:setState("sinemove", "right")
		else
			self:setState("sinemove", "left")
		end
	elseif self.state.name == "sinemove" then
		local dir = (self.vx < 0) and "right" or "left"
		self:setState("sinemove", dir)
	elseif self.state.name == "targetmove" then
		self.stage = "down"
		if self.x < window.w/2 then
			self:setState("circleturn", self.x + math.random(16, 64), self.y, math.pi/2, self.speed)
		else
			self.reverse = true
			self:setState("circleturn", self.x - math.random(16, 64), self.y, math.pi/2, -self.speed)
		end
	end
	if not name then name = self.state.name end
	-- print("Advance: "..name)
end

function GumballTrio:draw()
	love.graphics.setScissor(0, window.ceiling - 16, window.w, window.h)
	for i, b in ipairs(self.balls) do
		b:draw()
	end
	love.graphics.setScissor()
	Enemy.draw(self) --for displaying debug only
end

WalkBlock = class("WalkBlock", Enemy)

WalkBlock.spd = 50
WalkBlock.maxJumpTime = 5

WalkBlock.directions = {
	{"right"          , 0  , true , "WalkBlockLeft"},
	{"diagonal_right" , 45 , true , "WalkBlockDiagonal"},
	{"down"           , 90 , false, "WalkBlockDown"},
	{"diagonal_left"  , 135, false, "WalkBlockDiagonal"},
	{"left"           , 180, false, "WalkBlockLeft"}
}

function WalkBlock:initialize()
	Enemy.initialize(self, "enemy", rects.enemy.walkblock.down[2], 32, 32, 0, 0, 0, WalkBlock.spd)
	self.ignoreBricks = false
	self.gameType = "walkblock"
	self.jumpTimer = WalkBlock.maxJumpTime
	self.hitCheck = false
	self.hitTimer = 0.1
	self.prevRow = -1
end

--n is from 1 to 5
function WalkBlock:setDir(n)
	local dir = WalkBlock.directions[n]
	local vx, vy = util.rotateVec(WalkBlock.spd, 0, dir[2])
	self.dir = n
	self:setVel(vx, vy)
	self.invert = dir[3]
	self:playAnimation(dir[4], true)
	self.walkTimer = 3
end

--switch to another direction
function WalkBlock:changeDir(rand)
	if not self.dir or rand then
		self:setDir(math.random(1, 5))
		return
	end
	local t = {
		{2, 3, 4},
		{1, 3, 4, 5},
		{1, 2, 4, 5},
		{1, 2, 3, 5},
		{2, 3, 4}
	}
	local choices = t[self.dir]
	self:setDir(choices[math.random(1, #choices)])
end

function WalkBlock:jump()
	local i, j = self:getJumpTarget()
	local x, y = getGridPosInverse(i, j)
	local y = y + 8
	local dx, dy = x - self.x, y - self.y
	local vy = -200
	local ay = 1000
	--displacement formula, solve for time
	--quadratic formula ftw
	local dt = (-vy + math.sqrt(vy*vy+2*ay*dy))/ay
	self.jumping = true
	self.jumpTarget = {x = x, y = y}
	self.vx = dx / dt
	self.vy = vy
	self.ay = ay
	self.jumpTimer = WalkBlock.maxJumpTime
end

--this should always return something since it also includes the space below the pit
function WalkBlock:getJumpTarget()
	--remember that the WalkBlock needs 32 x 32 space (2 bricks high)
	local i0, j0 = getGridPos(self.x, self.y + 8)
	for i = i0 + 1, 33 do
		--this will prioritize positions closer to the center
		local order = {j0}
		for n = 1, 3 do
			local j1 = j0 + n
			local j2 = j0 - n
			if j1 <= 13 then
				table.insert(order, j1)
			end
			if j2 >= 1 then
				table.insert(order, j2)
			end
		end
		for _, j in ipairs(order) do
			local hit = false
			for ii = i, i + 1 do
				if ii <= 32 then
					local t = playstate.brickGrid[ii][j]
					for _, br in ipairs(t) do
						if self:canHitBrick(br) then
							hit = true
						end
					end
				end
			end
			if not hit then
				return i, j
			end
		end
	end
	return 33, 7 --as a failsafe
end

function WalkBlock:update(dt)
	if self.state then
		Enemy.update(self, dt)
		return
	end
	if self.jumping then
		if self.y >= self.jumpTarget.y then
			self:setPos(self.jumpTarget.x, self.jumpTarget.y)
			self.jumping = false
			self.ay = 0
			self:changeDir()
		end
		Enemy.update(self, dt)
		return
	end

	self.walkTimer = self.walkTimer - dt
	if self.walkTimer < 0 then
		self:changeDir()
	end

	--update movement first to stop the jittering
	Enemy.update(self, dt)
	
	--a combination of moving the update, flooring, and multiple collisions work
	--when 2 boxes collide, norm.x and norm.y cannot be nonzero at the same time
	local hit = false
	local dx, dy = 0, 0
	local bucket = playstate:getBrickBucket(self)
	for br, v in pairs(bucket) do
		local check, norm = self:checkBrickHit(br)
		if check then
			if norm.x ~= 0 then dx = norm.x end
			if norm.y ~= 0 then dy = norm.y end
		end
	end
	if dx ~= 0 or dy ~= 0 then
		if not self:pTranslate(dx, dy) then
			self:jump()
		end
		hit = true
	end
	if self.x + self.w/2 > window.rwallx then
		self.x = window.rwallx - self.w/2
		hit = true
	elseif self.x - self.w/2 < window.lwallx then
		self.x = window.lwallx + self.w/2
		hit = true
	end

	if self.hitCheck then
		self.hitTimer = self.hitTimer - dt
		if self.hitTimer <= 0 then
			self.hitCheck = false
		end
	end
	if hit then
		self.hitTimer = 0.1
		self.hitCheck = true
	end
	local row = getGridPos(self.x, self.y + 8)
	if self.prevRow == row then
		if self.hitCheck then
			self.jumpTimer = self.jumpTimer - dt
		end
		--if travelling horizontally, then don't reset jumpTimer
	else
		self.jumpTimer = WalkBlock.maxJumpTime
	end
	if self.jumpTimer <= 0 then
		self:jump()
	end
	self.prevRow = row
end

function WalkBlock:advanceState()
	if self.state.name == "emerging" then
		self.state = nil
		self:changeDir()
	end
end

function WalkBlock:draw()
	if self.invert then self.w = -self.w end
	--flooring helps stop the jittering
	local stox, stoy = self.x, self.y
	self.x, self.y = math.floor(self.x), math.floor(self.y)
	Enemy.draw(self)
	if self.invert then self.w = -self.w end
	if cheats.enemy_debug and not self.state then
		local n = string.format("%.1f", self.walkTimer)
		legacySetColor(128, 255, 128)
		love.graphics.setFont(font["Arcade20"])
		love.graphics.print(n, self.x, self.y - 20)

		local n = string.format("%.1f", self.jumpTimer)
		legacySetColor(255, 128, 128)
		love.graphics.setFont(font["Arcade20"])
		love.graphics.print(n, self.x, self.y)

		legacySetColor(255, 255, 255)
		love.graphics.setFont(font["Arcade20"])
		love.graphics.print(self.prevRow, self.x - 30, self.y)
	end
	self.x, self.y = stox, stoy
end

--Drop Ball

DropBall = class("DropBall", Enemy)
DropBall.spd = 50

function DropBall:initialize()
	Enemy.initialize(self, nil, nil, 40, 40, 0, 0, 0, DropBall.spd)
	self.r = 20
	self:setShape(shapes.newCircleShape(0, 0, self.r))

	self.dropState = "float"
	self.dropTimer = 3

	self.gameType = "dropball"
end

DropBall.validCollision = Projectile.validCollision
DropBall.handleCollision = Projectile.handleCollision

--should bounce off balls too
function DropBall:onBallHit(ball, norm)
	ball:onEnemyHit(self, norm)
	-- self:translate(norm.x, norm.y)
	-- self:handleCollision(-norm.x, -norm.y)
end

function DropBall:onProjectileHit(proj, norm)
	proj:onEnemyHit(self, norm)
end

function DropBall:onPaddleHit(paddle)
	if self.vy > 0 then
		self.vy = -self.vy
	end
end

function DropBall:update(dt)
	self.dropTimer = self.dropTimer - dt
	if self.dropTimer <= 0 then
		if self.dropState == "float" then
			--add gravity
			self.dropState = "drop"
			self.ay = 1000
			self.dropTimer = 1
		else
			--slow down and get rid of gravity
			self.dropState = "float"
			self.ay = 0
			self:scaleVelToSpeed(DropBall.spd)
			self.dropTimer = 3
		end
	end

	-- DropBall just bounces off bricks;
	-- does not affect the brick in any way
	local check, norm, brick = self:scanBrickHit()
	if check then
		self:translate(norm.x, norm.y)
		self:handleCollision(norm.x, norm.y)
	end
	local x, y = self:getPos()
	local r = self.r
	if x - r < window.lwallx  then self:handleCollision( 1,  0) end
	if x + r > window.rwallx  then self:handleCollision(-1,  0) end
	if y - r < window.ceiling then self:handleCollision( 0,  1) end

	--DropBall also bounces off DropBalls
	for i, e in ipairs(game.enemies) do
		if e.gameType == "dropball" then
			local check, mtvx, mtvy = self.shape:collidesWith(e.shape)
			if check then
				local nx, ny = mtvx, mtvy
				if self:validCollision(nx, ny) then
					self:handleCollision(nx, ny)
				end
				if e:validCollision(-nx, -ny) then
					e:handleCollision(-nx, -ny)
				end
			end
		end
	end


	Enemy.update(self, dt)
end

function DropBall:draw()
	love.graphics.setScissor(0, window.ceiling - 16, window.w, window.h)
	if self.dropState == "float" then
		love.graphics.setColor(0, 1, 0, 1)
	else
		love.graphics.setColor(1, 0, 0, 1)
	end
	love.graphics.circle("fill", self.x, self.y, self.r)
	love.graphics.setScissor()
end