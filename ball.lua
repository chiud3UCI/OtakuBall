Ball = class("Ball", Sprite)

--fast and slow increment speed by 150
Ball.defaultSpeed = {
	easy = 250,
	normal = 400,
	hard = 400,
	very_hard = 550
}
Ball.acceleration = 150/30
Ball.accelerationLimit = {
	hard = 400 + 150*5,
	very_hard = 550 + 150*5
}
Ball.speedLimit = {low = 100, high = 1900}

--static
function Ball.split(num, all)
	if num < 2 or #game.balls == 0 then
		return
	end
	local input
	local deg  = 360 / num
	if all then
		input = game.balls
	else
		local high = game.balls[1]
		for _, ball in pairs(game.balls) do
			if ball.y < high.y then
				high = ball
			end
		end
		input = {high}
	end
	for _, ball in pairs(input) do
		local vx, vy = ball:getVel()
		for i = 1, num - 1 do
			vx, vy = util.rotateVec(vx, vy, deg)
			local newBall = ball:clone()
			newBall.vx, newBall.vy = vx, vy
			newBall.stuckToPaddle = false
			game:emplace("balls", newBall)
		end
	end
end

--default speed: 500
function Ball:initialize(x, y, vx, vy)
	Sprite.initialize(self, "ball_spritesheet_new", rects.ball2[3][3], 14, 14, x, y, vx, vy)
	local shape = shapes.newCircleShape(0, 0, 7)
	self:setShape(shape)
	self.gameType = "ball"
	self.damage   = 10
	self.strength = 1
	self.fx = nil
	self.fy = nil
	self.override = {} --used for temporarily overriding the ball speed

	self.stuckBounceTimer = 0
	self.storedAngle = 0

	self.drawFloor = false

	self.flag = {} --flag should contain primitive values; no tables (unless they're constant tables)
end

function Ball:clone()
	local copy = util.copy(self)
	copy:setShape(shapes.newCircleShape(0, 0, self:getR()))
	copy.flag = util.copy(self.flag)
	copy.override = util.copy(self.override)
	copy.color = util.copy(self.color)
	--rects do not have to be copied because they are constant
	if self.flag.giga then
		copy:initGigaProjectile()
	end
	if self.flag.generator then
		copy:initGeneratorSprites()
	end
	if self.flag.energy then
		copy.energyLimit = self.energyLimit
		copy:initEnergyBalls()
	end
	if self.flag.particle then
		copy.particleBalls = nil
		for i = 1, #self.particleBalls do
			copy:addParticleBall()
		end
	end
	if self.isParachuting then
		copy:closeParachute()
	end
	if self.flag.blossom then
		copy:initBlossomSprites()
		if self.blossomState == "charging" then 
			copy.blossomState = "charging"
		else
			copy.blossomState = "ready"
		end
		copy.blossomGuns = nil
	end
	if self.flag.probe then
		copy:makeProbe()
	end
	if self.flag.bomb then
		copy:initBomberFuse()
	end
	return copy
end

function Ball:destructor()
	self:deleteGigaProjectile()
	self:deleteParticleBalls()
	self:deleteProbe()
	stopSound(nil, nil, self)
	Sprite.destructor(self)
end

function Ball:canHit(other)
	return not (self.isParachuting or self.stuckToPaddle or self.intangible)
end

function Ball:scaleVelToSpeed(s2)
	s2 = math.max(Ball.speedLimit.low, math.min(Ball.speedLimit.high, s2))
	Sprite.scaleVelToSpeed(self, s2)
end

--handles all things related to bouncing off the borders of the screen
function Ball:wallBounce()
	local r = self:getR()
	local x, y = self:getPos()

	if x - r < window.lwallx  then self:handleCollision( 1,  0) end
	if x + r > window.rwallx  then self:handleCollision(-1,  0) end
	if y - r < window.ceiling then self:handleCollision( 0,  1) end
	if y - r > window.h       then self.dead = true end

	if cheats.no_pit then
		if y + r > window.h   then self:handleCollision(0, -1) end
	end
end

function Ball:update(dt)
	-- local r = self:getR()
	-- local x, y = self:getPos()

	if self.paused then
		self.paused = self.paused - dt
		if self.paused <= 0 then
			self.paused = nil
		end
		dt = dt * 0.1
	end

	self.stuckBounceTimer = self.stuckBounceTimer + dt

	self:wallBounce()
	-- if x - r < window.lwallx  then self:handleCollision( 1,  0) end
	-- if x + r > window.rwallx  then self:handleCollision(-1,  0) end
	-- if y - r < window.ceiling then self:handleCollision( 0,  1) end
	-- if y - r > window.h       then self.dead = true end

	-- if cheats.no_pit then
	-- 	if y + r > window.h   then self:handleCollision(0, -1) end
	-- end

	if self.flag.probe and not self.stuckToPaddle then
		if mouse.m1 == 1 then
			self:releaseProbe()
		end
	end

	if self.flag.weak then
		self.weakTimer = self.weakTimer - dt
		if self.weakTimer <= 0 then
			self:normal()
		end
	end

	if self.flag.giga then
		local g = self.gigaProjectile
		g:setPos(self:getPos())
		g:updateShape()

		self.gigaFlashTimer = self.gigaFlashTimer - dt
		if self.gigaFlashTimer <= 0 then
			self.gigaFlashTimer = 0.05
			self.gigaDraw = not self.gigaDraw
		end
	end

	if self.flag.node then
		local sz = #game.balls + #game.newObjects.balls
		if sz < 3 then
			self.nodeTimer = self.nodeTimer - dt
			if self.nodeTimer <= 0 then
				if sz == 1 then
					local deg = 10
					local vx, vy = self:getVel()
					local ball1 = self:clone()
					local ball2 = self:clone()
					ball1:setVel(util.rotateVec(vx, vy, deg))
					ball2:setVel(util.rotateVec(vx, vy, -deg))
					ball1.stuckToPaddle = false
					ball2.stuckToPaddle = false
					game:emplace("balls", ball1)
					game:emplace("balls", ball2)
					playSound("node")
				elseif sz == 2 then
					local vx, vy = self:getVel()
					local ball = self:clone()
					ball:setVel(util.rotateVec(vx, vy, 10))
					ball.stuckToPaddle = false
					game:emplace("balls", ball)
					playSound("node")
				end
			end
		else
			self.nodeTimer = 0.5
		end
	end

	if self.flag.yreturn and self.vy > 0 then
		local mag = 10
		local mx, my = game.paddle:getCursor()
		self.fx = mag * (mx - self.x)
		self.fy = mag * (game.paddle.y - self.y)
	end

	if self.flag.kamikaze or self.flag.attract then
		local closest = nil
		local storedDist = math.huge
		for _, br in pairs(game.bricks) do
			if br.armor < 2 then
				local dist = math.pow(br.x-self.x, 2) + math.pow(br.y-self.y, 2)
				if dist < storedDist then
					storedDist = dist
					closest = br
				end
			end
		end
		if self.flag.kamikaze then
			if closest then
				self.fx = (closest.x-self.x)*self.kamikazeMag
				self.fy = (closest.y-self.y)*self.kamikazeMag
			end
			self.kamikazeMag = self.kamikazeMag + dt * 10
		else
			if closest then
				local dist = util.dist(self.x, self.y, closest.x, closest.y)
				local mag = 15 * math.max(1 - dist / 200, 0)
			
				self.fx = (closest.x-self.x) * mag
				self.fy = (closest.y-self.y) * mag
			end
		end
	end

	if self.flag.volt then
		if self.stuckToPaddle then
			self.voltTarget = nil
			stopSound("volt", false, self)
		else
			local skip = false
			if self.voltTarget then
				if not self.voltTarget:isDead() then
					local t = self.voltTarget
					local x, y = self.x, self.y
					local pow = math.pow
					if pow(t.x-x,2) + pow(t.y-y,2) < pow(150, 2) then
						skip = true
					end
				end
			end
			if not skip then
				stopSound("volt", false, self)
				self.voltTarget = nil
				local storedDist = math.pow(150, 2) --maximum range
				for _, br in pairs(game.bricks) do
					if br.armor < 2 then
						local dist = math.pow(br.x-self.x, 2) + math.pow(br.y-self.y, 2)
						if dist < storedDist then
							storedDist = dist
							self.voltTarget = br
						end
					end
				end
				if self.voltTarget then playSound("volt", true, self) end
			end
			if self.voltTarget then
				local br = self.voltTarget
				br:takeDamage(dt*50, 1)
				stopSound(br.hitSound, false, br)
				-- stopSound(br.deathSound, false, br)
			end
		end
	else
		stopSound("volt", false, self)
	end

	if self.flag.generator then
		self.generatorTimer = self.generatorTimer + dt
		local timer = self.generatorTimer
		for i, b in ipairs(self.generatorSprites) do
			b.x = self.x + math.cos(timer + i*math.pi/3) * 20
			b.y = self.y + math.sin(timer + i*math.pi/3) * 20
		end
	end

	if self.flag.energy then
		self:updateEnergyBalls(dt)
	end

	if self.flag.particle then
		self:updateParticleBalls(dt)
	end

	if self.flag.gravity then
		self.fy = 2000 * (self:getSpeed() / 500) ^ 2
		self.gravityTimer = self.gravityTimer - dt
		if self.gravityTimer <= 0 then
			self.flag.gravity = false
		end
	end

	if self.flag.antigravity then
		self.fy = -2000 * (self:getSpeed() / 500) ^ 2
		self.gravityTimer = self.gravityTimer - dt
		if self.gravityTimer <= 0 then
			self.flag.antigravity = false
		end
	end

	if self.flag.blossom then
		if self.blossomState == "ready" then
			if mouse.m1 == 1 and not self.stuckToPaddle then
				self.blossomState = "firing"
				self.blossomBurst = 3
				self.blossomCd = 0
				self.blossomPos = {self.x, self.y}
				playSound("controlcollected")
			end
			self.blossomOrbitTimer = self.blossomOrbitTimer + dt
			local timer = self.blossomOrbitTimer
			local theta = timer * 50
			local dx, dy = util.rotateVec(20, 0, theta)
			for i, b in ipairs(self.blossomSprites) do
				b.x = self.x + dx
				b.y = self.y + dy
				b.angle = math.rad(theta + i*60 + 30)
				dx, dy = util.rotateVec(dx, dy, 60)
			end
		end
		if self.blossomState == "firing" then
			self.blossomCd = self.blossomCd - dt
			if self.blossomCd <= 0 then
				self.blossomCd = 0.1
				self.blossomBurst = self.blossomBurst - 1
				if self.blossomBurst == 0 then
					self.blossomState = "charging"
				end
				local n = 24
				local da = 360/n
				local x, y = unpack(self.blossomPos)
				local vx, vy = util.rotateVec(0, 200, da/2 + ((2-self.blossomBurst)*(da/3)))
				for i = 1, n do
					local angle = math.rad(i*360/n)
					local p = Projectile:new("blossom", nil, x, y, vx, vy, angle, "rectangle", 8, 14)
					p.damage = 4
					p.timer = 3
					game:emplace("projectiles", p)
					vx, vy = util.rotateVec(vx, vy, da)
				end
			end
		end
	end

	if self.flag.emp then
		local dark
		if self.empArmed then
			self.empFlashTimer = self.empFlashTimer - dt
			if self.empFlashTimer <= 0 then
				self.empFlash = not self.empFlash
				self.empFlashTimer = self.empFlashDelay
			end
			dark = self.empFlash and 255 or 160
		else
			dark = 160
		end
		self.color.r, self.color.g, self.color.b = dark, dark, dark
	end

	if self.flag.halo then
		if self.haloState == "active" and self.vy > 0 then
			local i, j = getGridPos(self:getPos())
			local check = true
			local target = {}
			if boundCheck(i, j) then
				local bucket = playstate.brickGrid[i][j]
				for _, br in pairs(bucket) do
					if br.alignedToGrid and self.strength >= br.armor then
						table.insert(target, br)
					else
						check = false
					end
				end
			end
			if check then
				for _, br in pairs(target) do br:kill() end
				self.haloState = "inactive"
				self.intangible = false
			end
		end
	end

	if self.flag.knocker and self.knockerCount > 0 then
		self.knockerTimer = self.knockerTimer - dt
		if self.knockerTimer <= 0 then
			self.knockerTimer = self.knockerDelay
			self.knockerRX = (self.knockerRX == 0) and 13 or 0
		end
	end

	if self.flag.bomb then
		self:updateBomberFuse(dt)
	end

	if self.stuckToPaddle then dt = 0 end
	--all powerups after this line will be suspended when the ball is stuck on a paddle

	if self.flag.mega or self.flag.acid or self.flag.fire then
		if not self.trailTimer then self.trailTimer = 0 end
		if self.trailTimer >= 0.01 then
			self.trailTimer = self.trailTimer - 0.01
			local p = Particle:new(self.imgstr, self.rect, self.w, self.h, self.x, self.y, 0, 0, 0, 1)
			p.color.a = 128
			p.fadeRate = 256 * 2
			game:emplace("particles", p)
		else
			self.trailTimer = self.trailTimer + dt
		end
	end

	if self.flag.laser then
		self.laserTimer = self.laserTimer - dt
		if self.laserTimer <= 0 then
			self.laserTimer = self.laserCooldown
			local theta = math.random() * math.pi * 2
			local spd = 800
			local sx = math.sin(theta)
			local sy = -math.cos(theta)
			local rect = rects.laser.ball
			local w, h = rect.w*2, rect.h*2
			local l = Projectile:new("lasers", rect, self.x, self.y, sx * spd, sy * spd, theta, "rectangle", w, h)
			l:setColor(120, 0, 200)
			l.laser = true
			game:emplace("projectiles", l)
			playSound("laser")
		end
	end

	if self.flag.yoyo then
		local modifier = (1-self.y/900)^2*5.0+0.8
		self.override.vx = self.vx * modifier
		self.override.vy = self.vy * modifier
	end

	if self.flag.whisky then
		local deg = math.sin(15 * self.whiskyTimer / (math.pi)) * 0.15 * dt * 750
		self.vx, self.vy = util.rotateVec(self.vx, self.vy, deg)
		self.whiskyTimer = self.whiskyTimer  + dt
		self.whiskyEmitterTimer = self.whiskyEmitterTimer - dt
		if self.whiskyEmitterTimer <= 0 then
			self.whiskyEmitterTimer = self.whiskyEmitterTimer + 0.015
			local r = rects.whisky[math.random(1, 4)]
			local vx, vy = util.rotateVec(0, -math.random() * 100, math.random(-60, 60))
			local dx, dy = util.rotateVec(0, math.random() * self:getR() * 1.2, math.random(1, 360))
			local p = Particle:new("whisky_bubbles", r, r.w*2, r.h*2, self.x + dx, self.y + dy, vx, vy, 0, 0.3)
			p:setColor(nil, nil, nil, 180)
			p.fadeDelay = 0.1
			p.fadeRate = 1000
			game:emplace("particles", p)
		end
	end

	if self.flag.trail then
		local i, j = getGridPos(self:getPos())
		if boundCheck(i, j) and i <= 32-8 then
			if #playstate.brickGrid[i][j] == 0 then
				self.flag.trail = self.flag.trail - 1
				if self.flag.trail <= 0 then
					self.flag.trail = nil
				end
				local brick = NormalBrick.randomColorBrick(getGridPosInverse(i, j))
				brick.overlap[self] = 1
				table.insert(playstate.brickGrid[i][j], brick)
				game:emplace("bricks", brick)
			end
		end
	end

	if self.flag.domino then
		if self.dominoState == "active" then
			local x, y = unpack(self.dominoTarget)
			local dx, dy = x - self.x, y - self.y
			if (self.dominoDir == 1 and dx < 0) or (self.dominoDir == -1 and dx > 0) then
				local i, j = getGridPos(x, y)
				j = j + self.dominoDir
				local check = false
				if boundCheck(i, j) then
					local bucket = playstate.brickGrid[i][j]
					for _, br in pairs(bucket) do
						if br.alignedToGrid then
							check = true
						end
					end
				end
				if check then
					self.dominoTarget = {getGridPosInverse(i, j)}
				else
					self.dominoState = "charging"
					self.vx, self.vy = unpack(self.dominoStoredVel)
				end
			else
				local dist = util.dist(dx, dy)
				local spd = self:getSpeed()
				self.vx = dx / dist * spd
				self.vy = dy / dist * spd
			end
		end
	end

	if self.fx or self.fy then
		local spd = self:getSpeed()
		if self.fx then
			self.vx = self.vx + (self.fx * dt)
		end
		if self.fy then
			self.vy = self.vy + (self.fy * dt)
		end
		self:scaleVelToSpeed(spd)
		self.fx, self.fy = nil, nil
	end

	local spd = self:getSpeed()
	if spd < Ball.speedLimit.low or spd > Ball.speedLimit.high then
		spd = math.max(Ball.speedLimit.low, math.min(Ball.speedLimit.high, spd))
		if self.vx == 0 and self.vy == 0 then
			self.vx, self.vy = 1, 1
		end
		self:scaleVelToSpeed(spd)
	end
	--todo: fix the acceleration limit thinging
	if difficulty == "hard" or difficulty == "very_hard" then
		local spd = self:getSpeed()
		local limit = Ball.accelerationLimit[difficulty]
		if spd < limit then
			spd = spd + Ball.acceleration * dt
			spd = math.min(spd, limit)
			self:scaleVelToSpeed(spd)
		end
	end

	-- if self.forcefield then
	-- 	if self.vy < 0 then self.vy = -self.vy end
	-- 	local spd = self:getSpeed() / 5
	-- 	spd = math.max(Ball.speedLimit.low, spd)
	-- 	self.override.vx = 0
	-- 	self.override.vy = spd
	-- end

	if self.flag.cannon then
		self.override.vx = 0
		self.override.vy = -1000
	end

	if self.comboActive then
		local check = true
		if self.comboDelay then
			check = false
			self.override.vx = 0
			self.override.vy = 0
			self.comboDelay = self.comboDelay - dt
			if self.comboDelay <= 0 then
				self.comboDelay = nil
			end
		end
		if check then
			self.comboTimeout = self.comboTimeout - dt
			if self.comboTimeout <= 0 then
				self.comboActive = nil
			end
			local spd = self:getSpeed()
			local comboSpeed = self.comboSpeed
			if spd < comboSpeed then
				self.override.vx = self.vx * comboSpeed / spd
				self.override.vy = self.vy * comboSpeed / spd
			end
		end
	end

	if self.isParachuting then
		self.override.vx = 0
		self.override.vy = 100
		self.paraTimer = self.paraTimer - dt
		if self.paraTimer <= 0 then
			self.paraTimer = 0.2
			self.paraIndex, self.paraRect = self.paraIter()
		end
	end

	--sometimes the ball's velocity might be overrided by an external factor
	if self.override.vx then
		self.storedvx = self.vx
		self.vx = self.override.vx
	end
	if self.override.vy then
		self.storedvy = self.vy
		self.vy = self.override.vy
	end
	Sprite.update(self, dt)
	if self.override.vx then
		self.vx = self.storedvx
		self.storedvx, self.override.vx = nil, nil
	end
	if self.override.vy then
		self.vy = self.storedvy
		self.storedvy, self.override.vy = nil, nil
	end
end

function Ball:draw()
	--love.graphics.setScissor(window.lwallx - 16, window.ceiling - 16, window.boardw + 32, window.boardh + 16)

	if self.isParachuting then
		legacySetColor(self.color.r, self.color.g, self.color.b, self.color.a)
		draw("ball_parachute2", self.paraRect, self.x, self.y - 14, 0, 30, 30)
		local off = paraOffset[self.paraIndex]
		draw(self.imgstr, self.rect, self.x + off[1]*2, self.y + off[2]*2 - 14, 0, 14, 14)
		goto continue1
	end
	if self.flag.energy then
		for i, e in pairs(self.energyBalls) do
			e:draw()
		end
	end
	if self.flag.particle then
		for _, p in ipairs(self.particleBalls) do
			p:draw()
		end
	end

	if self.flag.knocker and self.knockerCount > 0 then
		draw("knocker", make_rect(self.knockerRX, 0, 13, 13), self.x, self.y, 0, 26, 26)
	end

	--Sprite.draw(self)
	do
		if self.flag.halo and self.haloState == "active" then
			legacySetColor(self.color.r, self.color.g, self.color.b, 128)
		else
			legacySetColor(self.color.r, self.color.g, self.color.b, self.color.a)
		end
		draw(self.imgstr, self.rect, self.x, self.y, self.angle, self.w, self.h, nil, nil, nil, nil, self.drawFloor)
		legacySetColor(255, 255, 255, 255)
    end

	if self.flag.giga and self.gigaDraw then
		legacySetColor(255, 255, 255, 128)
		draw("ball_giga", nil, self.x, self.y, 0, 42, 42)
	end

	--since the ball is drawn last, the probe will always be visible
	if self.flag.probe then
		self.probe:draw()
	end

	if self.flag.sightlaser then
		self:drawSightLaser()
	end

	::continue1::
	
	if self.flag.volt and self.voltTarget then
		legacySetColor(255, 255, 255)
		-- love.graphics.line(self.x, self.y, self.voltTarget.x, self.voltTarget.y)
		drawLightning(self.x, self.y, self.voltTarget.x, self.voltTarget.y, "volt")
	end

	if self.flag.generator then
		for i, b in pairs(self.generatorSprites) do
			b:draw()
		end
	end

	if self.flag.blossom and self.blossomState == "ready" then
		for i, b in pairs(self.blossomSprites) do
			b:draw()
		end
	end

	if self.flag.bomb then
		self:drawBomberFuse()
	end

	--love.graphics.setScissor()
end

function Ball:handleCollision(xn, yn)
	self.comboActive = nil
	if self.stuckToPaddle then return false end
	if self.forcefield then
		self.vx, self.vy = unpack(self.forcefield)
		self.forcefield = nil
	end
	--normalize
	local dist = util.dist(xn, yn)
	xn = xn / dist
	yn = yn / dist
	--check to see if collision is valid
	if not self:validCollision(xn, yn) then return false end

	--cannonball transform into fireball upon reflection
	if self.flag.cannon then
		self:normal()
		self.imgstr = "ball_spritesheet_new"
		self.rect = rects.ball2[7][1]
		self.flag.fireball = true
		self.damage = 1000
		self.strength = 2
		--self.flag.irritated = "once"
		local spd = self:getSpeed()
		self.vx, self.vy = util.rotateVec(xn, yn, math.random(-45, 45))
		self:scaleVelToSpeed(spd)
	end
	
	--vector reflection
	if self.flag.irritated then
		--bounces at a random angle if irritated
		local spd = self:getSpeed()
		xn, yn = util.rotateVec(xn, yn, math.random(-90, 90))
		self.vx, self.vy = xn*spd, yn*spd
		if self.flag.irritated == "once" then
			self.flag.irritated = nil
		end
	else
		local dot = self.vx*xn + self.vy*yn
		self.vx = self.vx - (2 * dot * xn)
		self.vy = self.vy - (2 * dot * yn)
		--another check that prevents the ball from bouncing too vertically or horizontally for a long duration
		local angle = math.abs(math.atan2(self.vy, self.vx)*180.0/math.pi)
        local vert = math.floor((angle + 45) / 90) % 2 == 1
        angle = math.min(angle, 180.0 - angle)
        angle = math.min(angle, 90.0 - angle)
        if angle > 10 or not util.deltaEqual(angle, self.storedAngle) then
        	self.stuckBounceTimer = 0
        end
        self.storedAngle = angle
        if self.stuckBounceTimer > 5 then
        	self.stuckBounceTimer = 0
        	local speed = self:getSpeed()
        	local k = vert and "vx" or "vy"
        	local d = (self[k] >= 0 and 1 or -1) * 0.3 * speed
        	self[k] = self[k] + d
        	self:scaleVelToSpeed(speed)
        end
	end
	return true
end

--angle between the velocity vector and the normal vector must be greater than 90 degrees
--this may be called multiple times for safety
function Ball:validCollision(xn, yn)
	if xn == 0 and yn == 0 then return false end
	local theta = util.angleBetween(xn, yn, self.vx, self.vy)
	return theta > math.pi / 2
end

function Ball:onBrickHit(brick, norm, pierce_override)
	if brick:isDead() then
		if self.flag.kamikaze then
			self.kamikazeMag = 25
		end
		if self.flag.acid and brick.brickType == "NormalBrick" then
			pierce_override = true
		end
	end

	if self.flag.weak then
		if math.random() < self.flag.weak then
			self.damage = 0
		else
			self.damage = 10
		end
	end

	if self.flag.voodoo and self.strength >= brick.armor then
		local candidates = {}
		for _, br in pairs(game.bricks) do
			if br ~= brick and br.armor < 2 then
				table.insert(candidates, br)
			end
		end
		local targets = {}
		for i = 1, 2 do
			if #candidates == 0 then break end
			targets[i] = table.remove(candidates, math.random(#candidates))
		end
		for _, br in pairs(targets) do
			local p = Projectile:new(nil, nil, br.x, br.y, 0, 0, 0, "rectangle", 32, 16)
			game:emplace("projectiles", p)
		end
	end

	if self.flag.bomb then
		local border_cx = window.w/2
		local border_cy = window.ceiling + (window.h - window.ceiling)/2
		local border_w = window.rwallx - window.lwallx
		local border_h = window.h - window.ceiling
		if self.flag.bomb == "row" then
			local e = Projectile:new(nil, nil, border_cx, brick.y, 0, 0, 0, "rectangle", border_w, 16)
			e:setComponent("explosion")
			e.damage = 1000
			e.strength = 2
			game:emplace("projectiles", e)

			local p = Particle:new("white_pixel", nil, border_w, 16, border_cx, brick.y)
			p.shrinkTimer = 0.1
			p.update = function(part, dt)
				part.shrinkTimer = part.shrinkTimer - dt
				if part.shrinkTimer <= 0 then
					part.h = part.h - (dt * 160)
					if part.h <= 0 then
						part.dead = true
					end
				end
			end
			game:emplace("particles", p)
		elseif self.flag.bomb == "column" then
			local e = Projectile:new(nil, nil, brick.x, border_cy, 0, 0, 0, "rectangle", 32, border_h)
			e:setComponent("explosion")
			e.damage = 1000
			e.strength = 2
			game:emplace("projectiles", e)

			local p = Particle:new("white_pixel", nil, 32, border_h , brick.x, border_cy)
			p.shrinkTimer = 0.1
			p.update = function(part, dt)
				part.shrinkTimer = part.shrinkTimer - dt
				if part.shrinkTimer <= 0 then
					part.w = part.w - (dt * 160 * 2)
					if part.w <= 0 then
						part.dead = true
					end
				end
			end
			game:emplace("particles", p)
		else
			local i0, j0 = getGridPos(brick.x, brick.y)
			for n = 0, 3 do
			for i = -n, n do
			for j = -n, n do
				if math.abs(i) + math.abs(j) == n then
					local i1, j1 = i0 + i, j0 + j
					if boundCheck(i1, j1) then
						local x, y = getGridPosInverse(i1, j1)
						local e = Projectile:new(nil, nil, x, y, 0, 0, 0, "rectangle", 32, 16)
						e:setComponent("explosion")
						e.damage = 1000
						e.strength = 2
						game:emplace("projectiles", e)

						local p = Particle:new("white_pixel", nil, 32, 16, x, y)
						p.shrinkTimer = 0.1
						p.grow = true
						p.update = function(part, dt)
							local rate = 160
							part.shrinkTimer = part.shrinkTimer - dt
							if part.shrinkTimer <= 0 then
								part.w = part.w - (dt * rate * 2)
								part.h = part.h - (dt * rate)
								if part.w <= 0 then
									part.dead = true
								end
							end
						end
						game:emplace("particles", p)
					end
				end
			end
			end
			end
		end
		stopSound(brick.hitSound, true)
		stopSound(brick.deathSound, true)
		playSound("bomber")
		self:normal()
	end

	if self.flag.fireball then
		local e = Projectile:new(nil, nil, brick.x, brick.y, 0, 0, 0, "rectangle", 96, 48)
		e:setComponent("explosion")
		e.damage = 1000
		e.strength = 2
		--modifies the function such that the brick that the fireball hits
		--does not get affected by the explosion
		e.onBrickHit = function(proj, br, norm)
			if br ~= brick then
				Projectile.onBrickHit(proj, br, norm)
			end
		end
		game:emplace("projectiles", e)
		-- if not brick:isDead() then playSound(brick.hitSound); print(brick.hitSound) end
	end

	if self.flag.iceball and brick.brickType ~= "IceBrick" then
		-- local e = Projectile:new(nil, nil, brick.x, brick.y, 0, 0, 0, "rectangle", 32, 16)
		-- e:setComponent("explosion")
		-- e.freeze = true
		-- e.damage = 1000
		-- e.strength = 2
		-- game:emplace("projectiles", e)
		if brick:isDead() then
			freezeBrick(brick)
			if brick.deathSound ~= "detonator" and brick.deathSound ~= "icedetonator" then 
				if brick.deathSound then
					stopSound(brick.deathSound, false, brick)
				end
				if brick.hitSound then
					stopSound(brick.hitSound, false, brick)
				end
				playSound("iceballfreeze")
			end
		end
	end

	if self.flag.emp and self.empArmed then
		self.empArmed = false
		--explosion hitbox
		local e = Projectile:new("clear_pixel", nil, brick.x, brick.y, 0, 0, 0, "rectangle", 96, 48)
		e:setComponent("explosion")
		e.damage = 1000
		e.strength = 2
		game:emplace("callbacks", Callback:new(0.03, function() game:emplace("projectiles", e) end))
		--explosion smoke
		local i = math.random(0, 3)
		local smokeStr = "explosion_smoke"
		local p = Particle:new(smokeStr, {i*24, 0, 24, 24}, 50, 50, brick.x, brick.y, 0, 0, 0, 1)
		p.fadeRate = 750
		p.growthRate = 600
		p.growthAccel = -2000
		p.drawPriority = -1
		game:emplace("particles", p)
		--explosion sprite
		local anistr = "Explosion"
		local p = Particle:new("clear_pixel", nil, 96, 48, brick.x, brick.y, 0, 0, 0, 0.5)
		p:playAnimation(anistr)
		p.drawPriority = 1
		game:emplace("particles", p)
		stopSound(brick.hitSound, true, brick)
		stopSound(brick.deathSound, true, brick)
		playSound("detonator")
	end

	if self.flag.snapper and not brick.snapper and brick.armor <= 2 then
		stopSound(brick.hitSound, true, brick)
		brick.hitSound = nil
		brick.deathSound = "detonator"
		brick:initSnapper()
		playSound("snapperplaced")
	end

	if self.flag.generator and brick:isDead() then
		local len = #self.generatorSprites
		if len > 0 then
			self.generatorSprites[len] = nil
			local b = Projectile:new("ball_spritesheet_new", rects.ball_mini, self.x, self.y, self.vx, self.vy, 0, "circle", 3)
			b:setComponent("bouncy")
			b.bounce = "strong"
			b.damage = 0
			b.strength = 0
			b.onPaddleHit = function(proj, paddle)
				local newBall = Ball:new(proj.x, proj.y, proj.vx, proj.vy)
				game:emplace("balls", newBall)
				proj:kill()
			end
			game:emplace("projectiles", b)
		end
	end

	if self.flag.energy then
		for k, v in pairs(self.energyBalls) do
			-- v.vx, v.vy = self.vx, self.vy
			game:emplace("projectiles", v)
			self.energyBalls[k] =  nil
		end
	end

	if self.flag.combo and brick:isDead() then
		local target = nil
		local storedDist = math.huge
		for _, br in pairs(game.bricks) do
			if br ~= brick and self.damage >= br.health and self.strength >= br.armor then
				--makes the ball more likely to hit bricks to the left/right instead of up/down
				local dist = math.pow((br.x-self.x)/2, 2) + math.pow(br.y-self.y, 2)
				if dist < storedDist then
					target = br
					storedDist = dist
				end
			end
		end
		if target then
			local spd = self:getSpeed()
			local dist = util.dist(self.x, self.y, target.x, target.y)
			local dx, dy = target.x - self.x, target.y - self.y
			self.vx = dx * spd / dist
			self.vy = dy * spd / dist
			self.flag.combo = self.flag.combo - 1
			if self.flag.combo == 0 then
				self.flag.combo = nil
			end
			self.comboActive = true
			self.comboDelay = 0.2
			self.comboTimeout = dist / self.comboSpeed
			pierce_override = true

			playSound("comboball")
		end
	end

	if self.flag.domino then
		if self.dominoState == "ready" then
			if brick:isDead() and brick.alignedToGrid then
				self.dominoDir = (self.vx > 0) and 1 or -1
				local i, j = getGridPos(brick:getPos())
				j = j + self.dominoDir
				local check = false
				if boundCheck(i, j) then
					local bucket = playstate.brickGrid[i][j]
					for _, br in pairs(bucket) do
						if br.alignedToGrid then
							check = true
						end
					end
				end
				if check then
					self.dominoTarget = {brick:getPos()}
					self.dominoStoredVel = {self.vx, -self.vy}
					self.dominoState = "active"
					pierce_override = true
				end
			end
		elseif self.dominoState == "active" then
			if brick:isDead() then
				pierce_override = true
			else
				self.dominoState = "charging"
				self.vx, self.vy = unpack(self.dominoStoredVel)
			end
		end
	end

	if self.flag.knocker and brick:isDead() and self.knockerCount > 0 then
		self.knockerCount = self.knockerCount - 1
		pierce_override = true
	end

	if (self.pierce or pierce_override) and brick:isDead() then return end
	self:translate(norm.x, norm.y)
	self:handleCollision(norm.x, norm.y)
	
end

function Ball:onEnemyHit(enemy, norm)
	if self.pierce and enemy:isDead() then return end
	self:translate(norm.x, norm.y)
	self:handleCollision(norm.x, norm.y)
end

function Ball:onPaddleHit(paddle)
	self.comboActive = nil
	if self.isParachuting then
		self:closeParachute()
	end
	if self.flag.energy then
		self:rechargeEnergyBalls()
	end
	if self.flag.generator then
		self:rechargeGeneratorSprites()
	end
	if self.flag.blossom then
		self.blossomState = "ready"
	end
	if self.flag.emp then
		self.empArmed = true
	end
	if self.flag.domino then
		self.dominoState = "ready"
	end
	if self.flag.halo then
		self.haloState = "active"
		self.intangible = true
	end
	if self.flag.knocker then
		self.knockerCount = self.maxKnockerCount
	end
	if self.flag.probe then
		if self.probe.attach == game.paddle then
			self:attachProbe(self.probe)
		end
	end
end

function Ball:normal()
	for k, _ in pairs(self.flag) do
		self.flag[k] = nil
	end
	self.intangible = false
	self.pierce = nil
	self:setR(7)
	self.imgstr = "ball_spritesheet_new"
	self.rect = rects.ball2[3][3]
	self.damage = 10
	self.strength = 1
	self.color = {r = 255, g = 255, b = 255, a = 255}

	self:deleteGigaProjectile()
	self:deleteParticleBalls()
	self:deleteGeneratorSprites()
	self:deleteBlossomSprites()
	self:deleteBomberFuse()
	self.energyBalls = nil

	stopSound(nil, nil, self)
end

function Ball:getR()
	--workaround
	if not self.shape then
		print("shape not found")
		saveTraceback()
		return 7
	end
	return self.shape._radius
end

function Ball:setR(r)
	self.shape._radius = r
	self:setDim(r*2, r*2)
end

function Ball:initBomberFuse()
	--bomber fuse particles are drawn OVER the ball, so it can't be placed in game.particles
	self.fuseTimer = 0
	self.fuseMax = 0.05
	self.fuseParticles = {}
end

function Ball:deleteBomberFuse()
	self.fuseParticles = nil
end

function Ball:updateBomberFuse(dt)
	util.remove_if(self.fuseParticles, function(p)
		p:update(dt)
		return p.dead == true
	end)
	self.fuseTimer = self.fuseTimer - dt
	if self.fuseTimer <= 0 then
		self.fuseTimer = self.fuseMax
		local vx, vy = util.rotateVec(math.random(25, 50), 0, -math.random(30, 150))
		local p = Particle:new("white_pixel", nil, 2, 2, 0, -self:getR(), vx, vy, 0, 0.2)
		local r = 255
		local g = math.random(0, 255)
		local b = math.random(0, g)
		p:setColor(r, g, b)
		table.insert(self.fuseParticles, p)
	end
end

function Ball:drawBomberFuse()
	love.graphics.push()
	love.graphics.translate(self.x, self.y)
	for i, p in ipairs(self.fuseParticles) do
		p:draw()
	end
	love.graphics.pop()

end



function Ball:initGigaProjectile()
	local p = Projectile:new("clear_pixel", nil, self.x, self.y, 0, 0, 0, "circle", 21)
	p.damage = 10000
	p.strength = 3
	p.onBrickHit = function() end
	p.update = function() end
	self.gigaProjectile = p
	game:emplace("projectiles", p)
end

function Ball:deleteGigaProjectile()
	if self.gigaProjectile then
		self.gigaProjectile:kill()
		self.gigaProjectile = nil
	end
end

function Ball:initGeneratorSprites()
	self.generatorTimer = 0
	self.generatorSprites = {}
	self:rechargeGeneratorSprites()
end

function Ball:rechargeGeneratorSprites()
	local len = #self.generatorSprites
	for i = len, 6 - 1 do
		local b = Sprite:new("ball_spritesheet_new", rects.ball_mini, 6, 6, self.x, self.y)
		table.insert(self.generatorSprites, b)
	end
end

function Ball:deleteGeneratorSprites()
	self.generatorSprites = nil
end

function Ball:initBlossomSprites()
	self.blossomOrbitTimer = 0
	self.blossomSprites = {}
	for i = 1, 6 do
		local b = Sprite:new("blossom", nil, 8, 14, self.x, self.y)
		table.insert(self.blossomSprites, b)
	end
end

function Ball:deleteBlossomSprites()
	self.blossomSprites = nil
end

function Ball:initEnergyBalls()
	self.energyBalls = {}
	self.energyRecord = {}
	self:rechargeEnergyBalls()
end

function Ball:rechargeEnergyBalls()
	while #self.energyBalls < self.energyLimit do
		local e = Projectile:new("energy_ball", nil, self.x, self.y, self.vx, self.vy, 0, "circle", 7)
		e.energy = true
		e:setColor(nil, nil, nil, 200)
		e:setComponent("bouncy")
		e.bounce = "weak"
		e.timer = 5
		table.insert(self.energyBalls, e)
	end
end

function Ball:updateEnergyBalls(dt)
	local index = 1
	local delay = 0.05
	local energyIndex = 1
	local record = self.energyRecord
	while index <= #record do
		local e = record[index]
		if #self.energyBalls == 0 then break end
		if energyIndex <= #self.energyBalls and e.t > energyIndex * delay then
			local b = self.energyBalls[energyIndex]
			b:setPos(e.x, e.y)
			b:setVel(e.vx, e.vy)
			energyIndex = energyIndex + 1
			if energyIndex > #self.energyBalls then
				break
			end
		end
		e.t = e.t + dt
		index = index + 1
	end
	for i = index, #record do
		record[i] = nil
	end
	table.insert(self.energyRecord, 1, {t = 0, x = self.x, y = self.y, vx = self.vx, vy = self.vy})
end

function Ball:deleteEnergyBalls()
	self.energyBalls = nil
	self.energyRecord = nil
end

function Ball:addParticleBall()
	if not self.particleBalls then
		self.particleBalls = {}
	end
	local vx, vy = util.rotateVec(self:getSpeed(), 0, math.random(360))
	local pball = Projectile:new(nil, nil, self.x, self.y, vx, vy, 0, "circle", 3.5)
	pball.draw = function(pself)
		legacySetColor(255, 255, 255, 255)
		love.graphics.circle("fill", pself.x, pself.y, pself.r)
	end
	pball:setComponent("bouncy")
	pball.bounce = "strong"
	pball.floorBounce = true
	table.insert(self.particleBalls, pball)
	game:emplace("projectiles", pball)
	-- self:updateParticleBalls(0)
end

function Ball:updateParticleBalls(dt)
	-- for i, pball in ipairs(self.particleBalls) do
	-- 	local mag = 10000 * math.pow(self:getSpeed(), 2) / 250000
	-- 	local px, py = pball:getPos()
	-- 	local bx, by = self:getPos()
	-- 	local fx, fy = util.normalize(bx-px, by-py)
	-- 	fx, fy = fx*mag, fy*mag
	-- 	local spd = self:getSpeed() * 1.5
	-- 	pball.vx = pball.vx + fx*dt
	-- 	pball.vy = pball.vy + fy*dt
	-- 	pball:scaleVelToSpeed(spd)
	-- end
	for i, pball in ipairs(self.particleBalls) do
		local spd = self:getSpeed()
		local pspd = pball:getSpeed()
		if pspd > 1.8*spd then
			pball:scaleVelToSpeed(1.8*spd)
		end
		local mag = 2000 * spd * spd / (400*400)
		local px, py = pball:getPos()
		local bx, by = self:getPos()
		local fx, fy = util.normalize(bx-px, by-py)
		local ax, ay = fx * mag, fy * mag
		pball.ax, pball.ay = ax, ay
	end
end

function Ball:deleteParticleBalls()
	if self.particleBalls then
		for _, p in ipairs(self.particleBalls) do
			p.bounce = "weak"
			p.floorBounce = false
			p.ax, p.ay = 0, 0
			p:scaleVelToSpeed(self:getSpeed())
			p.timer = 5
		end
		self.particleBalls = nil
	end
end

function Ball:makeProbe()
	local paddle = game.paddle
	local probe = Projectile:new("probe", nil, self.x, self.y, 0, 0, 0, "circle", 8)
	probe:setComponent("piercing")
	probe.pierce = "strong"
	probe.destructor = function(self)
		paddle.probes[self] = nil
		Projectile.destructor(self)
	end
	probe.canHit = function(self, obj)
		return self.attach == nil
	end
	probe.update = function(self, dt)
		if self.attach then
			self:setPos(self.attach:getPos())
		else
			local mag = 25
			local fx = mag * (paddle.x - self.x)
			local fy = mag * (paddle.y - self.y)
			local spd = self:getSpeed()
			self.vx = self.vx + fx * dt
			self.vy = self.vy + fy * dt
			self:scaleVelToSpeed(spd)
		end
		Sprite.update(self, dt)
		if not self.attach then
			if self.shape:collidesWith(paddle.shape) then
				self.attach = paddle
				self:setVel(0, 0)
			end
		end
	end
	self:attachProbe(probe)
	game:emplace("projectiles", probe)
end

function Ball:attachProbe(probe)
	if not probe then
		probe = self.probe 
	else
		self.probe = probe
	end
	probe.attach = self
	self.probeAttached = true
	game.paddle.probes[probe] = nil
	playSound("probeapply")
end

function Ball:releaseProbe()
	if self.probeAttached then
		self.probeAttached = false
		self.probe.attach = nil
		self.probe:setVel(self:getVel())
	end
end

function Ball:deleteProbe()
	if self.probe then
		self.probe:kill()
		self.probe = nil
	end
end

paraRect = {}
-- for i = 1, 5 do
-- 	paraRect[i] = make_rect((i-1)*18, 0, 18, 20)
-- end
for i = 1, 5 do
	paraRect[i] = make_rect(5 + (i-1)*(15+1), 2, 15, 15)
end

paraOffset = 
{
	{-6, 7},
	{-3, 8},
	{0, 8},
	{3, 8},
	{6, 7}
}

function Ball:deployParachute()
	self.paraIter = coroutine.wrap(function()
		while true do
			for i = 1, 5 do
				coroutine.yield(i, paraRect[i])
			end
			for i = 4, 2, -1 do
				coroutine.yield(i, paraRect[i])
			end
		end
	end)
	self.paraIndex, self.paraRect = self.paraIter()
	self.paraTimer = 0
	self.isParachuting = true
end

function Ball:closeParachute()
	self.isParachuting = false
end

local function Point(_x, _y)
	return {x = _x, y = _y}
end

function Ball:drawSightLaser()
	if self.vy <= 0 then return end
	legacySetColor(255, 255, 0, 255)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(2)
	love.graphics.setScissor(window.lwallx, window.ceiling, window.rwallx - window.lwallx, window.h - window.ceiling)

	local paddle = game.paddle
	local spd = self:getSpeed()
	local vx, vy = self.vx / spd, self.vy / spd
	if self.forcefield then
		vx, vy = 0, 1
	end
	local x1, y1 = self.x, self.y
	local x2, y2 = nil, nil
	local r = self:getR()
	local lwall = window.lwallx + r
	local rwall = window.rwallx - r
	local floor = window.h


	local storedi = 0
	for i = 1, 10 do --limit of 10 lines ber ball
		storedi = i
		local check, px, py = self:raycast(game.paddle, x1, y1, vx, vy)
		if check and vy > 0 then
			vx = paddle_strength * (px - paddle.x) / paddle.w
			vy = -1.0
			local dist = util.dist(vx, vy)
			vx, vy = vx / dist, vy / dist
			x2, y2 = px, py
			love.graphics.line(x1, y1, x2, y2)
			x1, y1 = x2, y2
		else
			if vx == 0 then --stops division by zero
				love.graphics.line(x1, y1, x1, (vy > 0) and floor or window.ceiling)
				break
			end
			local wall = vx < 0 and lwall or rwall
			local dx = wall - x1
			local dy = dx * vy / vx
			x2, y2 = x1 + dx, y1 + dy
			love.graphics.line(x1, y1, x2, y2)
			x1, y1 = x2, y2
			vx = -vx
			if y1 > floor or y1 < 0 then break end
		end
	end
	-- love.graphics.print(storedi, 5, 600) --debugging
	love.graphics.setScissor()

end

function Ball:raycast(obj, x1, y1, vx, vy)
	--step 1: create an expanded hitbox with rounded corners
	local x, y = obj:getPos()
	local w, h = obj:getDim()
	local r = self:getR()
	local corners =
	{
		Point(x - w/2, y - h/2),
		Point(x - w/2, y + h/2),
		Point(x + w/2, y + h/2),
		Point(x + w/2, y - h/2)
	}
	local rects =
	{
		shapes.newRectangleShape(0, 0, r*2, h),
		shapes.newRectangleShape(0, 0, w, r*2),
		shapes.newRectangleShape(0, 0, r*2, h),
		shapes.newRectangleShape(0, 0, w, r*2)
	}
	rects[1]:moveTo(x - w/2, y)
	rects[2]:moveTo(x, y - h/2)
	rects[3]:moveTo(x + w/2, y)
	rects[4]:moveTo(x, y + h/2)
	local shapes2 = {}
	for i = 1, 4 do
		local corner = corners[i]
		local circle = shapes.newCircleShape(corner.x, corner.y, r)
		shapes2[i] = circle
		shapes2[i+4] = rects[i]
	end
	--step 2: check to see if a ray collides with the hitbox
	local check = false
	local mag = math.huge
	for i = 1, 8 do
		local shape = shapes2[i]
		-- shape:draw("line")
		local intersecting, mag2 = shape:intersectsRay(x1, y1, vx, vy)
		if intersecting then
			if mag2 < mag and mag2 >= 0 then
				check = true
				mag = mag2
			end
		end
	end
	local tx, ty = x1 + vx * mag, y1 + vy * mag
	return check, tx, ty
end