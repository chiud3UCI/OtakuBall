Paddle = class("Paddle", Sprite)

Paddle.baseline = window.h - 32 --the y-position of the paddle

Paddle.sizes = {[-3] = 32,
				[-2] = 48,
				[-1] = 64,
				[0]  = 80,
				[1]  = 96,
				[2]  = 112,
				[3]  = 128,
				[4]  = 144}

function Paddle:initialize()
	--w = 128, h = 16
	Sprite.initialize(self, "paddle_powerup", rects.paddle[11], 80, 16, window.w/2, Paddle.baseline)
	self.stuckBalls = {}
	self:setSize(0)
	self.speedLimit = {x = nil, y = 500}
	self.gameType   = "paddle"

	self.flag = {} --flag should contain primitive values; no tables!

	self.illusionPaddles = {}

	self:resetCursor()
end

function Paddle:destructor()
	self:clearSounds()
	if self.rocketProjectile then
		self.rocketProjectile:kill()
		self.rocketProjectile = nil
	end
	Sprite.destructor(self)
end

--clears any lingering sounds created by the paddle
function Paddle:clearSounds()
	stopSound("beam")
	stopSound("cannonprep")
end

--now the paddle's shape and stuck balls will keep up with its size change
function Paddle:setDim(w, h)
	local ratio = w / self.w
	Sprite.setDim(self, w, h)
	self:setShape(shapes.newRectangleShape(0, 0, self.w, self.h))
	for _, v in pairs(self.stuckBalls) do
		v[2] = v[2] * ratio
	end
	if self.flag and self.flag.orbit then
		self.orbitRadius = math.max(70, self.w * 0.75)
	end
end

function Paddle:setSize(s)
	s = s or 0
	s = math.max(-3, math.min(4, s))
	self.size = s
	self:setDim(Paddle.sizes[s], nil)
end

function Paddle:incrementSize()
	self:setSize(self.size + 1)
end

function Paddle:decrementSize()
	self:setSize(self.size - 1)
end

function Paddle:onProjectileHit(proj)
	if self.protect and proj.enemy then
		self.protect = self.protect - 1
		if self.protect == 2 then
			self.protectColor.g = 180
		elseif self.protect == 1 then
			self.protectColor.g = 100
		elseif self.protect == 0 then
			self.protect = nil
		end
		proj:kill()
	else
		proj:onPaddleHit(self)
	end
end

--this function determines whether or not the controller is sending a fire input
function Paddle.canFire(auto, bound_check)
	if control_mode == "mouse" then
		if bound_check and not (mouse.x > window.lwallx and mouse.x < window.rwallx and mouse.y > window.ceiling) then
			return false
		end
		if auto then
			return mouse.m1
		else
			return mouse.m1 == 1
		end
	else
		if auto then
			return love.keyboard.isDown("space")
		else
			return keys.space == 1
		end
	end
end


--The x component is the OFFSET and the y component is the COORDINATE
function Paddle:resetCursor()
	self.cursor = {x = 0, y = window.h/2}
end

--retrieves the coordinates for certain targeted attacks
--has to work with keyboard controls too
function Paddle:getCursor()
	if control_mode == "mouse" then
		return mouse.x, mouse.y
	else
		return self.x + self.cursor.x, self.cursor.y
	end
end


local canFire = Paddle.canFire

function Paddle:onDeath() -- call this to spawn a deadly particle effect
	--does not use emplace due to special circumstances
	self:normal()
	--copying certain attributes for a copy sprite
	local death = Particle:new(self.imgstr, self.rect, self.w, self.h, self.x, self.y, 0, 0, 0, 10)
	death.growthRateX = 250
	death.growthAccelX = -750
	death.glowRate = 1.5
	death.glow = 0
	death.shake = false
	death.shakeMag = 0
	death.shakeTimer = 0.5
	death.update = function(part, dt)
		if not (part.w <= 40 and part.growthRateX < 0) then
			part.w = part.w + (part.growthRateX * dt) + (0.5 * part.growthAccelX * dt * dt)
			part.growthRateX = part.growthRateX + part.growthAccelX * dt
			-- part.w = math.max(40, part.w)
		else
			part.w = 40
			part.shake = true
			part.shakeTimer = part.shakeTimer - dt
			part.shakeMag = part.shakeMag + 10 * dt
			if part.shakeTimer <= 0 then
				part.dead = true
				for i = 1, 8 do
					--the orbs that travel in a straight line as well as accelerate
					local vx, vy = util.rotateVec(150, 0, 45 * (i-1))
					local orb = Particle:new("white_circle", nil, 14, 14, part.x, part.y, vx, vy, 0, 3)
					local accel = 1750
					orb.ax = accel * math.cos(math.rad(45*(i-1)))
					orb.ay = accel * math.sin(math.rad(45*(i-1)))
					game:emplace("particles", orb)

					--the orbs that travel in a spiral as well as grow bigger
					orb = Particle:new("white_circle", nil, 14, 14, part.x, part.y, 0, 0, 0, 3)
					orb.origin = {x = part.x, y = part.y}
					orb.growthRate = 40
					orb.spd = 600
					orb.angle = 45 * (i-1) + 22.5
					orb.angularVel = 100
					orb.update = function(obj, dt)
						local ox, oy = obj.origin.x, obj.origin.y
						local dist = util.dist(ox, oy, obj.x, obj.y)
						obj.angle = obj.angle + obj.angularVel * dt
						dist = dist + obj.spd * dt
						local dx, dy = util.rotateVec(dist, 0, obj.angle)
						obj.x, obj.y = ox + dx, oy + dy
						Particle.update(obj, dt)
					end
					game:emplace("particles", orb)
				end
				playSound("paddledeath2")
			end
		end
		death.glow = math.min(1, death.glow + death.glowRate * dt)
		Particle.update(part, dt)
	end
	death.draw = function(part)
		shader.glow:send("mag", death.glow)
		love.graphics.setShader(shader.glow)
		Paddle.drawPaddle(part)
		love.graphics.setShader()
	end
	game:emplace("particles", death)
	Sprite.onDeath(self)
	playSound("paddledeath")
end

function Paddle:canCollectPowerUp(powerup)
	return self.flag.rocket ~= "active" and self.flag.rocket ~= "falling"
end

--the only purpose of this function is to notify Twin
function Paddle:collectPowerUp(powerup)
	powerup:activate()
	if self.twin then
		-- self:twinCollectPowerUp(powerup)
		self:syncTwinPowerUp()
	end
end

function Paddle:checkBallHit(ball)
	if self.flag.orbit then return false end
	if self.flag.ghost then
		if self.color.a <= self.ghostThreshold then return false end
	end
	if self.flag.poison then
		return false
	end
	return ball.shape:collidesWith(self.shape)
end

paddle_strength = 2.4
function Paddle:onBallHit(ball)
	if ball.vy < 0 and not ball.isParachuting then return end
	local catch = false

	if ball.forcefield then
		ball.vx, ball.vy = unpack(ball.forcefield)
		ball.forcefield = nil
	end

	local spd = ball:getSpeed()
	local vx = paddle_strength * (ball.x - self.x) / self.w
	ball.vx, ball.vy = vx, -1.0
	ball:scaleVelToSpeed(spd)

	if self.flag.cannon == "loading" then
		self:attachCannonBall(ball)
		playSound("cannonprep", true)
	end
	if self.flag.catch and not (canFire(true) and self.flag.catch ~= "glue") then
		self:attachBall(ball, "contact")
		if self.flag.catch == "holdonce" then
			self:clearPowerups()
		end
		catch = true
	end

	if self.flag.zenShove then
		for i = 23, 1, -1 do
			for j = 1, 13 do
				local t = playstate.brickGrid[i][j]
				local t2 = playstate.brickGrid[i+1][j]
				for _, br in pairs(t) do
					local canMove = false
					if not br.isMoving and br.alignedToGrid and br.armor <= 1 then
						canMove = true
						for _, br2 in pairs(t2) do
							if br2.alignedToGrid and not br2.isMoving then
								canMove = false
								break
							end
						end
					end
					if canMove then
						br:moveTo(br.x, br.y + 16, 0.2, "die")
					end
				end
			end
		end
	end

	if playstate then
		playstate.stalemateTimer = playstate.maxStalemate
	end

	ball:onPaddleHit(self)

	if ball.skip_sound then
		ball.skip_sound = nil
		return
	end
	if catch then
		playSound("paddlecatch")
	else
		playSound("paddlehit")
	end
end

function Paddle:onMenacerHit(menacer)
	if menacer.vy < 0 then return end

	local spd = menacer:getSpeed()
	local vx = paddle_strength * (menacer.x - self.x) / self.w
	menacer.vx, menacer.vy = vx, -1.0
	menacer:scaleVelToSpeed(spd)

	if menacer.menacerType == "cyan" then
		PowerUp.funcTable[99]() --calls the Shadow Powerup
	end

	playSound("paddlehit")
end

function Paddle:update(dt)
	local ballCount = #self.stuckBalls --To prevent triggering powerups if there are still balls stuck

	if self.freeze then
		self.freezeTimer = self.freezeTimer - dt
		if self.freezeTimer <= 0 then
			self.freeze = nil
		end
		return
	end

	if self.stunTimer then
		self.stunTimer = self.stunTimer - dt
		if self.stunTimer <= 0 then
			self.stunTimer = nil
			self.shake = nil
		else
			self.shake = true
			self.shakeMag = 2
		end
	end

	if canFire(true, true) and not self.spawnOrbs then
		if self.flag.catch ~= "glue" then
			if #self.stuckBalls > 0 then
				playSound("paddlehit")
			end
			for k, p in pairs(self.stuckBalls) do
				p[1].stuckToPaddle = false
				self.stuckBalls[k] = nil
			end
			
		end
		if self.flag.cannon == "ready" then
			self:fireCannonBall()
		end
	end

	if self.flag.shadow then
		self.shadowTimer = self.shadowTimer - dt
		if self.shadowTimer <= 0 then
			self:clearPowerups()
		end
	end

	if self.flag.cannon == "ready" then
		local ball = self.cannonBall
		ball.x, ball.y = self.x, self.y
	end

	if self.xBomb then
		self.xBomb.x, self.xBomb.y = self.x, self.y
		if canFire(true, true) then
			self:fireXBomb(getGridPosInverse(getGridPos(self:getCursor())))
		end
	end

	if self.flag.catch == "glue" then
		self.glueTimer = self.glueTimer - dt
		if self.glueTimer <= 0 then
			self:clearPowerups()
		end
	end

	if self.flag.beam then
		if canFire(true) and self.beamTime > (self.beamTrigger and 0 or 1) then
			if not self.beamTrigger then
				playSound("beam", true)
				self.beamTrigger = true
			end
			self.beamTime = math.max(0, self.beamTime - dt)
			self.beamState = "on"
			local beam_left = self.x - self.beamWidth/2
			local beam_right = self.x + self.beamWidth/2
			for _, ball in pairs(game.balls) do
				local ball_left = ball.x - ball:getR()
				local ball_right = ball.x + ball:getR()
				if     beam_left >= ball_left and beam_left <= ball_right then
					if ball:validCollision(1, 0) then
						local spd = ball:getSpeed()
						ball.vx = 0
						ball.vy = ball.vy > 0 and spd or -spd
					end
				elseif beam_right >= ball_left and beam_right <= ball_right then
					if ball:validCollision(-1, 0) then
						local spd = ball:getSpeed()
						ball.vx = 0
						ball.vy = ball.vy > 0 and spd or -spd
					end
				end
				if ball.x < self.x then
					ball.fx = 2000
				else
					ball.fx = -2000
				end
			end
		else
			self.beamTime = math.min(self.beamTimeMax, self.beamTime + dt * self.beamRegen)
			self.beamState = "off"
			self.beamTrigger = false
			stopSound("beam")
		end
	end

	if self.flag.control then
		self.controlCooldown = self.controlCooldown - dt
		if self.controlCooldown <= 0 then
			if control_mode == "mouse" then
				global_cursor = cursors["control"]
			else
				self.drawControl = true
			end
			self.controlCooldown = 0
			if canFire(false, true) then
				self.controlCooldown = 8
				for _, e in pairs(game.environments) do
					if e.suction then e.timer = 0 end
				end
				local suction = Environment:new()
				suction.suction = true
				suction.x, suction.y = self:getCursor()
				suction.radius = 50
				suction.circles = Queue:new({suction.radius})
				suction.circleTimer = 0.4
				suction.timer = 3
				suction.stoppedSound = false
				suction.update = function(self, dt)
					self.timer = self.timer - dt
					if self.timer <= 0 then
						if not self.stoppedSound then
							self.stoppedSound = true
							stopSound("control", nil, self)
						end
						if self.circles:empty() then
							self.dead = true
						end
					else
						for _, ball in pairs(game.balls) do
							local dist = util.dist(self.x, self.y, ball.x, ball.y)
							if dist < self.radius then
								local nx, ny = (self.x - ball.x) / dist, (self.y - ball.y) / dist
								local mag = math.pow(ball:getSpeed(), 2) / 50
								ball.fx = nx * mag
								ball.fy = ny * mag
							elseif dist < self.radius + ball:getR() then
								if ball:handleCollision(self.x - ball.x, self.y - ball.y) then
									local rad = util.angleBetween(ball.vx, ball.vy, self.x - ball.x, self.y - ball.y)
									local dot = ball.vx * -(self.y - ball.y) + ball.vy * (self.x - ball.x) --not really the dot product
									local sign = dot < 0 and -1 or 1
									local deg = math.deg(rad)
									--print(math.deg(rad), sign)
									ball.vx, ball.vy = util.rotateVec(ball.vx, ball.vy, sign * (90 - deg) / 3)
								end
							end
						end
						self.circleTimer = self.circleTimer - dt
						if self.circleTimer <= 0 then
							self.circleTimer = 0.4
							self.circles:pushLeft(self.radius)
						end
					end
					local count = 0
					for k, v in pairs(self.circles.data) do
						v = v - dt * 75
						if v <= 0 then count = count + 1 end
						self.circles.data[k] = v
					end
					for i = 1, count do
						self.circles:popRight()
					end
				end
				suction.draw = function(self)
					legacySetColor(0, 200, 255, 255)
					love.graphics.setLineStyle("rough")
					love.graphics.setLineWidth(3)
					for k, v in pairs(self.circles.data) do
						love.graphics.circle("line", self.x, self.y, v)
					end
					--love.graphics.circle("line", self.x, self.y, self.radius)
				end
				suction.destructor = function(self)
					Environment.destructor(self)
					stopSound("control", nil, self)
				end
				game:emplace("environments", suction)
				playSound("control", true, suction)
			end
		end
	end

	if self.flag.hacker then
		self.hackerTarget = nil
		local minDist = math.huge
		local mx, my = mouse.x, mouse.y
		for _, br in pairs(game.bricks) do
			if self.hackerCandidates[br.brickType] then
				local dist = math.pow(br.x-mx,2)+math.pow(br.y-my,2)
				if dist < minDist then
					self.hackerTarget = br
					minDist = dist
				end
			end
		end
		if mouse.m1 == 1 and self.hackerTarget then
			self.hackerTarget:takeDamage(10, 1)
			if self.hackerTarget.brickType == "FactoryBrick" then
				self.hackerTarget:generateBrick("up")
			end
		end
		self.hackerOffset = self.hackerOffset + dt*20
		if self.hackerOffset >= 2*math.pi then
			self.hackerOffset = self.hackerOffset - 2*math.pi
		end
	end

	if self.flag.transform then
		if self.transformTarget then
			if self.transformTarget:isDead() then
				self.transformTarget = nil
				self.transformProgress = 0
			end
		end
		if mouse.m1 then
			if not self.transformTarget then
				local minDist = math.huge
				local mx, my = mouse.x, mouse.y
				for _, br in pairs(game.bricks) do
					if self.transformCandidates[br.brickType] then
						local dist = math.pow(br.x-mx,2)+math.pow(br.y-my,2)
						if dist < minDist then
							self.transformTarget = br
							minDist = dist
						end
					end
				end
			else
				self.transformProgress = self.transformProgress + dt
				if self.transformProgress >= 1 then
					self.transformProgress = 0
					local br = self.transformTarget
					local n = NormalBrick:new(br.x, br.y, 2, 3, "brick_spritesheet")
					n:inheritMovement(br)
					br.suppress = true
					br:kill()
					game:emplace("bricks", n)
					self.transformTarget = nil
					playSound("transform")
				end
			end
		else
			self.transformProgress = 0 
			self.transformTarget = nil
		end
	end

	if self.javelin then
		self.javelinTimer = self.javelinTimer - dt
		if canFire() or (self.javelinTimer <= 0) then
			self:fireJavelin()
			self.javelin = nil
		end
		self.javelinEmitterTimer = self.javelinEmitterTimer - dt
		if self.javelinEmitterTimer <= 0 then
			self.javelinEmitterTimer = 0.2 * self.javelinTimer / 6
			local spd = 300
			local dist = 70
			local time = dist / spd
			local vx, vy = util.rotateVec(0, spd, math.random(1, 360))
			local x, y = self.x - vx * dist / spd, self.y - vy * dist / spd
			local p = Particle:new("white_circle", nil, 5, 5, x, y, vx, vy, 0, time)
			p.growthRate = 50
			p.growthAccel = 500
			local old_update = p.update;
			p.update = function(self, dt)
				local dx = self.paddle.x - self.oldPaddleX
				local dy = self.paddle.y - self.oldPaddleY
				self.oldPaddleX = self.paddle.x
				self.oldPaddleY = self.paddle.y
				self.x = self.x + dx
				self.y = self.y + dy
				old_update(self, dt)
			end
			p.paddle = self
			p.oldPaddleX = self.x
			p.oldPaddleY = self.y
			game:emplace("particles", p)
		end
	end

	if self.gun then
		self.gun:update(dt)
	end

	if self.flag.invert then
		if self.invertTimer <= 0 then
			if canFire() then
				self.invertTimer = 2
				for _, ball in pairs(game.balls) do
					ball.vy = -ball.vy
					local p = Particle:new(nil, nil, 18, 52, ball.x, ball.y, nil, nil, math.rad(90), 1)
					p:playAnimation("Invert")
					game:emplace("particles", p)
				end
				playSound("invert")
			end
		else
			self.invertTimer = math.max(0, self.invertTimer - dt)
		end
	end

	if self.flag.rocket == "ready" then
		if canFire() then
			self.flag.rocket = "active"
			local proj = Projectile:new("clear_pixel", nil, self.x, self.y, 0, 0, 0, "rectangle", self.w, self.h)
			proj.damage = 1000
			proj.strength = 2
			proj:setComponent("piercing")
			proj.pierce = "strong"
			self.rocketProjectile = proj
			game:emplace("projectiles", proj)
			playSound("rocket")
		end
	end

	if self.heavenPaddle then
		local hp = self.heavenPaddle
		hp.w = self.w
		hp.x = self.x
		if hp.y > self.y - (8 * 16) then
			hp.y = hp.y - (128 * dt)
		else
			hp.y = self.y - (8 * 16)
		end
		for _, ball in pairs(game.balls) do
			if util.circleRectOverlap(ball.x, ball.y, ball:getR(), hp.x, hp.y, hp.w, hp.h) and ball.vy > 0 then
				local spd = ball:getSpeed()
				local vx = paddle_strength * (ball.x - hp.x) / hp.w
				ball.vx, ball.vy = vx, -1.0
				ball:scaleVelToSpeed(spd)
				playSound("heavenhit")
			end
		end
		if not self.flag.heaven then
			hp.fadeTimer = hp.fadeTimer - dt
			if hp.fadeTimer <= 0 then
				self.heavenPaddle = nil
			else
				hp:setColor(nil, nil, nil, 255 * hp.fadeTimer / 2)
			end
		end
	end

	if self.flag.illusion then
		for i, p in ipairs(self.illusionPaddles) do
			p.y = self.y
			p.w = self.w
			local spd = 200
			local sx = spd * dt
			local dx = self.x - p.x
			local w = p.w * i
			if dx < -w then
				p.x = self.x + w
			elseif dx > w then
				p.x = self.x - w
			end
			if dx < -sx then
				p.x = p.x - sx
			elseif dx > sx then
				p.x = p.x + sx
			else
				p.x = self.x
			end

			for _, ball in pairs(game.balls) do
				if util.circleRectOverlap(ball.x, ball.y, ball:getR(), p.x, p.y, p.w, p.h/2) and ball.vy > 0 then
					ball.vy = -ball.vy
					playSound("illusionhit")
				end
			end
		end
	end

	if self.flag.regenerate and ballCount == 0 then
		self.regenTimer = self.regenTimer - dt
		if self.regenTimer <= 0 then
			self.regenTimer = 5
			local ball = Ball:new(0, 0, 0, Ball.defaultSpeed[difficulty])
			self:attachBall(ball, "random")
			game:emplace("balls", ball)
			playSound("reserve")
		end
	end

	if self.magnet then
		for _, p in pairs(game.powerups) do
			if not p.isBad and not p.suppress then
				local vel = 0
				if p.x > self.x + 2 then 
					vel = -200
				elseif p.x < self.x - 2 then 
					vel = 200
				end
				p.x = p.x + vel * dt
			end
		end
	end

	if self.flag.pause then
		if self.pauseAura then
			local aura = self.pauseAura
			aura.r = aura.r + 1000*dt
			if aura.r >= 800 then
				self.pauseAura = nil
			end
			for _, ball in pairs(game.balls) do
				local dist = math.pow(ball.x - aura.x, 2) + math.pow(ball.y - aura.y, 2)
				if dist < (aura.r*aura.r) and not ball.paused then
					ball.paused = 2
				end
			end
		end
		self.pausecd = math.max(0, self.pausecd - dt)
		if mouse.m1 == 1 and self.pausecd <= 0 and ballCount == 0 then
			self.pausecd = 6
			self.pauseAura = {r = 0, x = self.x, y = self.y, w = 2}
			playSound("pauseactivated")
		end
	end

	--update paddle and ball positions

	local mx, my
	local spd = paddle_speed
	if control_mode == "mouse" then
		mx, my = mouse.x, mouse.y
	else
		mx, my = self.x, self.y
		local mag = spd * dt
		if self.flag.yoga then mag = mag * 3 end
		if self.flag.change then mag = -mag end
		local cx, cy = self.cursor.x, self.cursor.y
		if love.keyboard.isDown("left", "a") then
			if control_mode == "smart_keyboard" then
				local x, dty = self:autopilotUpdate(true, true)
				if dty and x < self.x then
					if dty > 0.01 then
						mag = math.abs(x - self.x)/dty*dt
					end
				end
			end
			mx = self.x - mag
			cx = math.min(0, cx)
			if mx - self.w/2 < window.lwallx then
				cx = math.max(-self.w/2 + 1, cx - mag)
			end
		elseif love.keyboard.isDown("right", "d") then
			if control_mode == "smart_keyboard" then
				local x, dty = self:autopilotUpdate(true, true)
				if dty and x > self.x then
					if dty > 0.01 then
						mag = math.abs(x - self.x)/dty*dt
					end
				end
			end
			mx = self.x + mag
			cx = math.max(0, cx)
			if mx + self.w/2 > window.rwallx then
				cx = math.min(self.w/2 - 1, cx + mag)
			end
		end
		if love.keyboard.isDown("up", "w") then
			my = self.y - mag
			cy = math.max(window.ceiling, cy - mag)
		elseif love.keyboard.isDown("down", "s") then
			my = self.y + mag
			cy = math.min(window.h, cy + mag)
		end
		self.cursor.x = cx
		self.cursor.y = cy
	end


	if self.flag.change and control_mode == "mouse" then
		local dx = -window.w/2 + mx
		mx = window.w/2 - dx
	end

	if self.flag.yoga and control_mode == "mouse" then
		local dx = mx - window.w/2
		mx = mx + dx * 3
		local dy = my - window.h/2
		my = my + dy * 3
	end
	
	if self.flag.vector then
		if self.flag.vector == "rising" then
			if my >= self.y then
				self.flag.vector = "stable"
				self.speedLimit.y = nil
			end
		end
		my = math.max(window.ceiling + self.h/2, my)
		self.vectorTimer = self.vectorTimer - dt
		if self.vectorTimer <= 0 then
			self:clearPowerups()
			self.flag.vector = nil
		end
	else
		my = Paddle.baseline
	end

	if self.twin then
		self:updateTwin(dt)
	end

	if self.autopilot then
		my = Paddle.baseline
		mx = self:autopilotUpdate()
		self.autopilotTimer = self.autopilotTimer - dt
		if self.autopilotTimer <= 0 then
			self.autopilot = false
		end
	end
	if self.speedLimit.x or self.autopilot or self.stunTimer then
		local sx = self.speedLimit.x
		if self.autopilot then sx = 1500 end
		if self.stunTimer then sx = 100 end
		sx = sx * dt
		local dx = self.x - mx
		if dx < -sx then
			mx = self.x + sx
		elseif dx > sx then
			mx = self.x - sx
		end
	end
	if self.flag.nervous then
		self.nervousTimer = self.nervousTimer + dt
		if self.nervousTimer >= 20 then
			self:clearPowerups()
		end
		local off
		if control_mode == "mouse" then
			off = math.sin(self.nervousTimer * 10) * 50
		else
			off = math.sin(self.nervousTimer * 10) * 250 * dt
		end
		mx = math.min(window.rwallx - self.w/2, math.max(window.lwallx + self.w/2, mx))
		mx = mx + off
	end
	if self.flag.orbit then
		for _, ball in pairs(game.balls) do
			if not ball.stuckToPaddle then
				if util.dist(self.x, window.h, ball.x, ball.y) < self.orbitRadius then
					local theta = math.deg(math.atan2(ball.vx, -ball.vy))
					local angle = math.deg(math.atan2(ball.x - self.x, window.h - ball.y))
					if math.abs(theta - angle) > 90 then
						-- print(angle, theta)
						local spd = ball:getSpeed()
						ball.vx, ball.vy = util.rotateVec(0, -spd, angle)
						ball.stuckToPaddle = true
						ball:onPaddleHit(self)
						self.orbitBalls[ball] = {spd = spd, angle = angle, cw = theta - angle > 0}
					end
				end
			end
		end
		for ball, v in pairs(self.orbitBalls) do
			local a = v.angle
			if v.cw then
				a = (a + 90 + dt*100) % 180 - 90
			else
				a = (a - 90 - dt*100) % -180 + 90
			end
			local dx, dy = util.rotateVec(0, -self.orbitRadius, a)
			ball:setPos(self.x + dx, window.h + dy)
			ball.vx, ball.vy = util.rotateVec(0, -v.spd, a)
			v.angle = a
		end
		if mouse.m1 == 1 then
			for ball, v in pairs(self.orbitBalls) do
				ball.stuckToPaddle = false
				self.orbitBalls[ball] = nil
			end
		end
		if playstate and next(self.orbitBalls) then
			playstate.stalemateTimer = playstate.maxStalemate
		end
	end

	if self.bob and not self.bob.done then
		local bob = self.bob
		my = self.y + bob.vy*dt + 0.5*bob.ay*dt*dt
		bob.vy = bob.vy + bob.ay*dt

		local base = Paddle.baseline
		if bob.up then
			if my <= base then
				bob.up = not bob.up
				if bob.queue:empty() then
					bob.done = true
				else
					bob.ay = bob.queue:popLeft()
				end
			end
		else
			if my >= base then
				bob.up = not bob.up
				if bob.queue:empty() then
					bob.done = true
				else
					bob.ay = -bob.queue:popLeft()
				end
			end
		end
		if bob.done then
			local ball = Ball:new(window.w/2, window.h/2, Ball.defaultSpeed[difficulty], 0)
			ball.color.a = 0
			self:attachBall(ball, "random")
			table.insert(game.balls, ball)
		end
	elseif self.flag.rocket == "active" then
		my = self.y - 1500 * dt
		self.rocketProjectile:setPos(self:getPos())
		if self.y - 12.5 < window.ceiling then
			self.flag.rocket = "falling"
			self.rocketProjectile:kill()
			self.rocketProjectile = nil
		end
	elseif self.flag.rocket == "falling" then
		my = self.y + 1500 * dt
		if self.y > Paddle.baseline then
			my = Paddle.baseline
			self:clearPowerups()
		end
	elseif self.speedLimit.y then
		local sy = self.speedLimit.y * dt
		local dy = self.y - my
		if dy < -sy then
			my = self.y + sy
		elseif dy > sy then
			my = self.y - sy
		end
	end

	local w = self.w / 2
	local twinoff = 0
	if self.twin then
		twinoff = self.twin.w + self.twin.gap
	end
	mx = math.min(window.rwallx - w, math.max(window.lwallx + w + twinoff, mx)) --constrains the paddle to within the borders

	if self.flag.ghost then
		self.ghostTimer = self.ghostTimer - dt
		if self.ghostTimer <= 0 then
			self:clearPowerups()
		else
			local dx = math.abs(mx - self.x)
			self.color.a = math.min(255, self.color.a + (dx * self.ghostGrowth * dt))
			self.color.a = math.max(0, self.color.a - self.ghostDecay * dt)
		end
	end

	if self.flag.poison then
		self.poisonTimer = self.poisonTimer - dt
		if self.poisonTimer <= 0 then
			self:clearPowerups()
		end
	end

	if self.bypass then
		if self.bypass == "left" then
			self.x = self.x - 100*dt
		else
			self.x = self.x + 100*dt
		end
		self.y = Paddle.baseline
	else
		self.x = mx
		self.y = my
	end

	if playstate and #self.stuckBalls > 0 then
		playstate.stalemateTimer = playstate.maxStalemate
	end

	util.remove_if(self.stuckBalls, function(p)
		if p[1].destroyed then return true end
		p[1].x = self.x + p[2]
		p[1].y = self.y - self.h/2 - p[1]:getR()
		return false
	end)

	if self.bob and self.bob.done and self.spawnOrbs and not self.spawnOrbs.done then
		local dir = {{1, 0}, {0, 1}, {-1, 0}, {0, -1}}
		local ball = self.stuckBalls[1][1]
		local mag = self.spawnOrbs.dist
		for i = 1, 4 do
			self.spawnOrbs[i]:setPos(ball.x + dir[i][1] * mag, ball.y + dir[i][2] * mag)
		end
		self.spawnOrbs.dist = self.spawnOrbs.dist - self.spawnOrbs.vel * dt
		if self.spawnOrbs.dist <= 0 then
			self.spawnOrbs.done = true
		end
	end

	Sprite.update(self, dt)
end

--68 x 12
--edge is 6
function Paddle:drawOutline(color)
	legacySetColor(color.r, color.g, color.b, color.a)

	local lrect = make_rect( 0, 0,  6, 12)
	local mrect = make_rect( 6, 0, 56, 12)
	local rrect = make_rect(62, 0,  6, 12)

	local height = 24
	local edge = 12
	local off = self.w + 8 - edge

	draw("paddle_outline", mrect, self.x      , self.y, 0, off - edge, height)
	draw("paddle_outline", lrect, self.x-off/2, self.y, 0, edge      , height)
	draw("paddle_outline", rrect, self.x+off/2, self.y, 0, edge      , height)
end

function Paddle.drawPaddle(paddle) --static function; wait a minute, they're all static!!!
	legacySetColor(paddle.color.r, paddle.color.g, paddle.color.b, paddle.color.a)

	local px, py = paddle.x, paddle.y
	if paddle.shake then
		local mag = paddle.shakeMag
		px = px + math.random(-mag, mag)
		py = py + math.random(-mag, mag)
		-- px = px + (math.random()*mag*2) - mag
		-- py = py + (math.random()*mag*2) - mag
	end

	--need to splice the rect into 3 sections
	local x, y = paddle.rect.x, paddle.rect.y
	local lrect = make_rect(x   , y, 10, 8)
	local mrect = make_rect(x+10, y, 44, 8)
	local rrect = make_rect(x+54, y, 10, 8)

	--middle section needs to be elongated
	local height = paddle.h
	local edge = 20
	local off = paddle.w - edge

	draw(paddle.imgstr, mrect, px      , py, 0, off - edge, height)--, nil, nil, nil, nil, true)
	draw(paddle.imgstr, lrect, px-off/2, py, 0, edge      , height)--, nil, nil, nil, nil, true)
	draw(paddle.imgstr, rrect, px+off/2, py, 0, edge      , height)--, nil, nil, nil, nil, true)
end


function Paddle:draw()
	if self.bypass then
		love.graphics.setScissor(window.lwallx - 16, window.ceiling - 16, window.boardw + 32, window.boardh + 16)
	end

	if self.flag.illusion then
		local rt = {}
		local n = #self.illusionPaddles
		for i, v in ipairs(self.illusionPaddles) do
			rt[n+1-i] = v
		end
		for _, v in pairs(rt) do
			Paddle.drawPaddle(v)
		end
	end

	if self.javelin then
		shader.glow:send("mag", 1 - (self.javelinTimer / 6))
		shader.glow:send("target", {1, 1, 1})
		love.graphics.setShader(shader.glow)
	end
	local tempx, tempy
	Paddle.drawPaddle(self)
	love.graphics.setShader()
	if self.protect then
		self:drawOutline(self.protectColor)
	end

	if self.bob and self.bob.done and self.spawnOrbs then
		for i = 1, 4 do
			self.spawnOrbs[i]:draw()
		end
	end

	if self.heavenPaddle then
		Paddle.drawPaddle(self.heavenPaddle)
	end

	if self.twin then
		self:drawTwin()
	end

	if self.xBomb then
		self.xBomb:draw() 
		local mx, my = self:getCursor()
		local i, j = getGridPos(mx, my)
		if boundCheck(i, j) then
			local x, y = getGridPosInverse(i, j)
			legacySetColor(255, 255, 255, 128)
			draw("white_pixel", nil, x, y, 0, 32, 16)
		end
	end

	if self.flag.beam then
		if self.beamState == "on" then
			local width = self.beamWidth
			legacySetColor(0, 255, 0, 128)
			love.graphics.rectangle("fill", self.x - width/2, window.ceiling, width, self.y - window.ceiling - self.h/2)
		end
		local ratio = self.beamTime / self.beamTimeMax
		local length = self.w - 24
		length = length * ratio
		legacySetColor(0, 255, 0, 255)
		love.graphics.rectangle(
			"fill", 
			self.x - length/2, 
			self.y - 6, 
			length,
			6*2
		)
	end

	--a canvas is used in order to draw the ice block with correct alpha blending
	if self.freeze then
		local lrect = make_rect(0, 0, 24, 24)
		local mrect = make_rect(24, 0, 1, 24)
		local rrect = make_rect(38, 0, 24, 24)
		local off = 0
		love.graphics.push("all")
		love.graphics.setCanvas(freeze_canvas)
			love.graphics.clear()
			legacySetColor(255, 255, 255, 255)
			draw("paddle_ice", mrect, self.x, self.y, 0, self.w + off*2 + 48, 48)
			draw("paddle_ice", lrect, self.x - self.w/2 - off, self.y, 0, 48, 48)
			draw("paddle_ice", rrect, self.x + self.w/2 + off, self.y, 0, 48, 48)
		love.graphics.pop()
		legacySetColor(255, 255, 255, 180)
		love.graphics.draw(freeze_canvas)
	end

	if self.flag.orbit then
		legacySetColor(255, 255, 255, 255)
		love.graphics.setLineWidth(2)
		love.graphics.setLineStyle("rough")
		love.graphics.circle("line", self.x, window.h, self.orbitRadius)
	end

	if self.drawControl then
		self.drawControl = nil
		legacySetColor(255, 255, 255, 255)
		local x, y = self:getCursor()
		draw("control", nil, x, y, 0, 64, 64)
	end

	if self.flag.pause then
		if self.pauseAura then
			local aura = self.pauseAura
			legacySetColor(255, 255, 255, 255)
			love.graphics.setLineWidth(aura.w)
			love.graphics.setLineStyle("rough")
			love.graphics.circle("line", aura.x, aura.y, aura.r)
		end
	end

	if self.flag.hacker then
		if self.hackerTarget then
			local px, py = self:getPos()
			local bx, by = self.hackerTarget:getPos()
			legacySetColor(0, 255, 0, 255)
			love.graphics.setLineWidth(2)
			love.graphics.setLineStyle("rough")
			shader.hacker:send("center", {bx, by})
			shader.hacker:send("offset", self.hackerOffset)
			love.graphics.setShader(shader.hacker)
			love.graphics.line(px, py, bx, by)
			love.graphics.setShader()
		end
	end

	if self.flag.transform then
		if self.transformTarget then
			local off = 16
			local px, py = self:getPos()
			local w = self.w
			local bx, by = self.transformTarget:getPos()
			local bw, bh = self.transformTarget:getDim()
			local a = self.transformProgress * 255
			legacySetColor(255, 255, 255, a)
			love.graphics.rectangle("fill", bx - bw/2, by - bh/2, bw, bh)
			legacySetColor(255, 150, 0, 255)
			love.graphics.setLineWidth(2)
			love.graphics.setLineStyle("rough")
			love.graphics.line(px+w/2-off, py, bx, by)
			love.graphics.line(px-w/2+off, py, bx, by)
		end
	end

	love.graphics.setScissor()
	legacySetColor(255, 255, 255, 255)
end

--modes: random(default), contact
function Paddle:attachBall(ball, mode)
	if ball.forcefield then
		ball.vx, ball.vy = unpack(ball.forcefield)
		ball.forcefield = nil
	end
	ball.stuckToPaddle = true
	ball.comboActive = nil
	ball.y = self.y - ball:getR() - (self.h/2)
	local left = self.x - self.w/2
	local right = self.x + self.w/2
	if mode == "contact" then
		ball.x = math.max(left, math.min(right, ball.x))
	else
		ball.x = math.random() * (right - left) + left
	end
	local spd = ball:getSpeed()
	local vx = paddle_strength * (ball.x - self.x) / self.w
	ball.vx, ball.vy = vx, -1.0
	ball:scaleVelToSpeed(spd)
	table.insert(self.stuckBalls, {ball, ball.x - self.x})
end

function Paddle:attachCannonBall(ball)
	ball.stuckToPaddle = true
	ball.comboActive = nil
	ball.x, ball.y = self.x, self.y
	ball:normal()
	ball.flag.cannon = true
	local spd = ball:getSpeed()
	ball.vx, ball.vy = 0, -spd
	ball.damage = 1000
	ball.strength = 2
	ball.pierce = true
	ball.imgstr = "ball_spritesheet_new"
	ball.rect = rects.ball2[8][10]
	self.flag.cannon = "ready"
	self.cannonBall = ball
end

function Paddle:fireCannonBall()
	self.flag.cannon = nil
	self.cannonBall.stuckToPaddle = false
	self.cannonBall = nil
	playSound("cannonball")
	self:clearPowerups()
end

function Paddle:autopilotUpdate(ignore_powerups, smart_keyboard)
	--find the ball that will reach the paddle in the least amount of time
	local base = self.y --Paddle.baseline
	local ball = nil
	local stody = math.huge
	for _, b in pairs(game.balls) do
		local dy = base - self.h/2 - b:getR() - b.y
		if b.vy > 1 then --the ball can't have an extremely tiny vertical velocity or it might cause the game to freeze
			if not ball or (dy / b.vy < stody / ball.vy) then
				ball = b
				stody = dy
			end
		end
	end

	local powerup = nil

	if not ignore_powerups and (not ball or stody / ball.vy > 0.2) then--if the ball can reach the paddle in x many seconds or less then forget the powerups
		for _, p in pairs(game.powerups) do
			local dy = base - self.h/2 - p.h/2 - p.y
			if p.y < self.y then
				if (ball and (dy / p.vy < stody / ball.vy)) or (powerup and (dy / p.vy < stody / powerup.vy)) then
					ball = nil
					powerup = p
					stody = dy
				end
			end
		end
	end
	
	if powerup then return powerup.x end
	if not ball then return self.x end

	--calculate where exactly the ball will hit
	local dy = stody
	--dy = math.max(0, dy)
	local dt = dy / ball.vy
	local dx = ball.vx * dt
	local bl, br = window.lwallx + ball:getR(), window.rwallx - ball:getR()
	local db = br - bl
	local mirror = false

	local x = ball.x + dx
	while x > br do
		x = x - db
		mirror = not mirror
	end
	while x < bl do
		x = x + db
		mirror = not mirror
	end
	if mirror then
		x = br - (x - bl)
	end

	if smart_keyboard then return x, dt end

	--determine paddle offset to hit a viable brick 
	local target = nil
	local storedDist = math.huge
	for _, br in pairs(game.bricks) do
		local dx = br.x - x
		local dy = br.y - (self.y - self.h/2 - ball:getR())
		local dist = dx*dx + dy*dy
		if dy < 0 and ball.strength >= br.armor and dist < storedDist then
			target = br
			storedDist = dist
		end
	end

	if not target then return x end
	
	-- local spd = ball:getSpeed()
	-- local vx = paddle_strength * (ball.x - self.x) / self.w
	local vx = (target.x - self.x) / (self.y - target.y)
	local dx = vx * self.w / paddle_strength
	dx = math.max(math.min(dx, self.w/2), -self.w/2)

	return x - dx
end

function Paddle:initXBomb()
	--I am making the bomb a particle as it can be drawn over the paddle
	self.xBomb = Particle:new("powerup_spritesheet", rects.powerup_ordered[128], 32, 16, self.x, self.y)
	self.xBomb.update = function(bomb, dt)
		Particle.update(bomb, dt)
		if bomb:isDead() then
			playSound("xbombexplode")
			for di = -1, 1 do
				for dj = -1, 1 do
					local i, j = getGridPos(bomb.target.x, bomb.target.y)
					i, j = i + di, j + dj
					local delay = 0.01
					local t = delay
					while boundCheck(i, j) do
						local x, y = getGridPosInverse(i, j)
						local e = Projectile:new(nil, nil, x, y, 0, 0, 0, "rectangle", 32, 16)
						e:setComponent("explosion")
						e.damage = 1000
						e.strength = 2

						local p = Particle:new("white_pixel", nil, 2, 1, x, y)
						p.growRate = 300
						p.shrinkRate = 300
						p.shrinkDelay = 0.3
						p.grow = true
						p.update = function(part, dt)
							if part.grow then
								part.w = part.w + (part.growRate * 2 * dt)
								part.h = part.h + (part.growRate * dt)
								if part.w >= 32 then
									part.w = 32
									part.h = 16
									part.grow = false
									game:emplace("projectiles", e)
								end
							else
								p.shrinkDelay = p.shrinkDelay - dt
								if p.shrinkDelay <= 0 then
									part.w = part.w - (part.shrinkRate * 2 * dt)
									part.h = part.h - (part.shrinkRate * dt)
									if part.w <= 0 then
										part.dead = true
									end
								end
							end
						end
						if di == 0 and dj == 0 then 
							game:emplace("particles", p)
							break 
						else
							game:emplace("callbacks", Callback:new(t, function() game:emplace("particles", p) end))
						end
						i, j = i + di, j + dj
						t = t + delay
					end
				end
			end
		end
	end
end

function Paddle:fireXBomb(_x, _y)
	--assume _x and _y are aligned to grid
	local time = 1 --it will always take the same amount of time to hit the target
	local rate = 300
	local vx = (_x - self.x) / time
	local vy = (_y - self.y) / time
	self.xBomb.vx = vx 
	self.xBomb.vy = vy
	self.xBomb.timer = time
	self.xBomb.target = {x = _x, y = _y}
	self.xBomb.growthRate = rate
	self.xBomb.growthAccel = -2 * rate / time
	--self.xBomb:playAnimation("P128")
	game:emplace("particles", self.xBomb)
	self.xBomb = nil
	playSound("xbomblaunch")
end

function Paddle:setGun(gun)
	self.gun = gun
	gun.paddle = self
end

function Paddle:clearPowerups()
	if self.flag.cannon == "ready" then
		self:fireCannonBall()
	end
	for k, _ in pairs(self.flag) do
		self.flag[k] = nil
	end
	self.rect = rects.paddle[11]
	self.imgstr = "paddle_powerup"
	self:setColor(255, 255, 255, 255)
	self.gun = nil
	if self.heavenPaddle then
		self.heavenPaddle.fadeTimer = 2
	end
	self.illusionPaddles = {}
	if self.rocketProjectile then
		self.rocketProjectile:kill()
		self.rocketProjectile = nil
	end
	if self.orbitBalls then
		for ball, v in pairs(self.orbitBalls) do
			ball.stuckToPaddle = false
			self.orbitBalls[ball] = nil
		end
		self.orbitBalls = nil
	end
	self.pauseAura = nil
	self.speedLimit = {x = nil, y = 500}

	self:clearSounds()
end

function Paddle:normal()
	self:clearPowerups()
	self:setSize(0)
	self.protect = nil
	self:deleteTwin()
end

function Paddle:initHeavenPaddle()
	local hp = Sprite:new("paddle_heaven", rects.paddle[1], 80, 16, self.x, self.y)
	self.heavenPaddle = hp
end

function Paddle:addIllusionPaddle()
	local i = Sprite:new(self.imgstr, self.rect, self.w, self.h, self.x, self.y)
	i:setColor(nil, nil, nil, 128)
	table.insert(self.illusionPaddles, i)
end

function Paddle:fireJavelin()
	local mx, my = self:getCursor()
	local x = math.max(self.x - self.w/2, math.min(self.x + self.w/2 - 1, mx))
	x = getGridPosInverse(getGridPos(x, 0))
	local j = Projectile:new("javelin", nil, x, self.y, 0, -1500, 0, "rectangle", 46, 146)
	j:setShape(shapes.newRectangleShape(0, 0, 32, 146))
	j:setComponent("piercing")
	j.pierce = "strong"
	j.damage = 1000
	j.strength = 2
	j.boundCheck = false
	j.update = function(proj, dt)
		if proj.y + proj.h/2 < 0 then proj:kill() end
		Projectile.update(proj, dt)
	end
	game:emplace("projectiles", j)
	stopSound("javelincharge")
	playSound("javelinfire")
end
--[[Twin roadmap:
	Due to the fact that every method is static, I can make the twin paddle
	call whatever methods neccessary
	Supported Effects:
		Size change
		All Guns (duplicate guns)
		Catch
	Obstacles:
		Autopilot: delete twin?
		Enemy projectiles
		Just projectiles in general
]]
function Paddle:initTwin()
	if self.twin then return end
	local twin = Sprite:new(self.imgstr, self.rect, self.w, self.h, self.x, self.y)
	twin:setShape(shapes.newRectangleShape(0, 0, twin.w, twin.h))
	twin.gap = 32
	twin.flag = {}
	twin.stuckBalls = {}
	twin.clearPowerups = function(_twin)
		for k, _ in pairs(_twin.flag) do
			_twin.flag[k] = nil
		end
		_twin.rect = rects.paddle[11]
		_twin.imgstr = "paddle_powerup"
		_twin.gun = nil
	end
	twin.attachBall = Paddle.attachBall
	twin.twin = true

	--for use with drill missile only
	twin.getCursor = function(t)
		local mx, my = self:getCursor()
		mx = mx - t.w - t.gap
		return mx, my
	end

	self.twin = twin
end

--needs to release balls it caught
function Paddle:deleteTwin()
	if not self.twin then return end
	local twin = self.twin
	for k, p in pairs(twin.stuckBalls) do
		p[1].stuckToPaddle = false
	end
	self.twin = nil
end

local gen = util.generateLookup
local twinPowerUps = {
	catch = gen{"Catch", "Hold Once"}, --Glue probably isn't needed
	--Drill Missile might cause some bugs
	weapon = gen{"Laser", "Laser Plus", "Rapidfire", "Shotgun", "Ball Cannon", "Missile", "Erratic Missile", "Drill Missile"}
}

--currently not used
function Paddle:twinCollectPowerUp(pow)
	local twin = self.twin
	local check = false
	local catagory = nil
	for k, v in pairs(twinPowerUps) do
		if v[pow.name] then
			check = true
			catagory = k
		end
	end
	if not check then return end
	twin:clearPowerups()
	if catagory == "catch" then
		for k, v in pairs(self.flag) do
			twin.flag[k] = v
		end
		twin.imgstr = self.imgstr
		twin.rect = self.rect
	elseif catagory == "weapon" then
		twin.imgstr = self.imgstr
		twin.rect = self.rect
		twin.gun = self.gun:clone()
		twin.gun.paddle = twin
	end
end

function Paddle:syncTwinPowerUp()
	local twin = self.twin
	local check = false
	for k, v in pairs(self.flag) do
		if k == "catch" and v ~= "glue" then
			check = "flag"
			break
		end
	end
	if self.gun then
		check = "gun"
	end
	if check then
		twin:clearPowerups()
		twin.imgstr = self.imgstr
		twin.rect = self.rect
		if check == "gun" then
			twin.gun = self.gun:clone()
			twin.gun.paddle = twin
		elseif check == "flag" then
			for k, v in pairs(self.flag) do
				twin.flag[k] = v
			end
		end
	end
end

--twin powerup collection is implemented in playstate because it is more urgent.
function Paddle:updateTwin(dt)
	local twin = self.twin
	if twin.w ~= self.w then
		Paddle.setDim(twin, self.w, self.h)
	end
	twin.x = self.x - self.w - twin.gap
	twin.y = self.y
	twin.shape:moveTo(twin.x, twin.y)
	for _, ball in pairs(game.balls) do
		if Paddle.checkBallHit(twin, ball) then
			Paddle.onBallHit(twin, ball)
		end
	end
	for _, ball in pairs(game.menacers) do
		if Paddle.checkBallHit(twin, ball) then
			Paddle.onMenacerHit(twin, ball)
		end
	end

	--the following sections are borrowed from Paddle:update()
	if canFire(true, true) then
		if twin.flag.catch ~= "glue" then
			if #twin.stuckBalls > 0 then
				playSound("paddlehit")
			end
			for k, p in pairs(twin.stuckBalls) do
				p[1].stuckToPaddle = false
				twin.stuckBalls[k] = nil
			end
		end
	end

	if twin.gun then
		twin.gun:update(dt)
	end

	util.remove_if(twin.stuckBalls, function(p)
		if p[1].destroyed then return true end
		p[1].x = twin.x + p[2]
		p[1].y = twin.y - twin.h/2 - p[1]:getR()
		return false
	end)
end

function Paddle:drawTwin()
	Paddle.drawPaddle(self.twin)
end

PaddleGun = class("PaddleGun") -- "abstract" class

function PaddleGun:notifyProjectileDeath()
	self.bulletCount = self.bulletCount - 1
end

function PaddleGun:clone()
	return _G[self.gunType]:new()
end

PaddleLaser = class("PaddleLaser", PaddleGun)

function PaddleLaser:initialize(plus)
	self.gunType = plus and "PaddleLaserPlus" or "PaddleLaser"
	self.bulletCount = 0
	self.maxBullets = plus and 6 or 4
end

function PaddleLaser:clone()
	local gun = PaddleLaser:new(self.gunType == "PaddleLaserPlus")
	gun.maxBullets = self.maxBullets
	return gun
end

function PaddleLaser:update(dt)
	if canFire() then
		local x = self.paddle.w/2-17
		local off = {-x, x}
		if self.bulletCount < self.maxBullets then
			for i = 1, 2 do
				local rect = rects.laser[(self.gunType == "PaddleLaser") and "regular" or "plus"]
				local w, h = rect.w*2, rect.h*2
				local l = Projectile:new("lasers", rect, self.paddle.x + off[i], self.paddle.y - h, 0, -800, 0, "rectangle", w, h)
				if self.gunType == "PaddleLaserPlus" then
					l.damage = 100
				end
				l.gun = self
				l.laser = true
				self.bulletCount = self.bulletCount + 1
				game:emplace("projectiles", l)
			end
			if self.gunType == "PaddleLaser" then
				playSound("laser")
			else
				playSound("laserplus")
			end
		end
	end
end

PaddleRapid = class("PaddleRapid", PaddleGun)

PaddleRapid.firerate = 5
PaddleRapid.bulletw = 20
PaddleRapid.bulleth = 30
PaddleRapid.dmg = 5
PaddleRapid.switchPeriod = 1
PaddleRapid.bulletSpeed = 1000

function PaddleRapid:initialize()
	self.gunType = "PaddleRapid"
	self.cd = 0
	self.switchTimer = self.switchPeriod
	self.switch = true
end

function PaddleRapid:update(dt)
	if canFire(true) and self.cd <= 0 then
		self.cd = (1 / PaddleRapid.firerate)
		local pinkrect = make_rect(0, 0, 10, 15)
		local bluerect = make_rect(12, 0, 10, 15)
		local off = (self.paddle.w/2-15) * (self.switch and 1 or -1)
		local l = Projectile:new("rapidfire_bullet", pinkrect, self.paddle.x - off, self.paddle.y - 12, 0, -self.bulletSpeed, 0, "rectangle", self.bulletw, self.bulleth)
		--l:setShape(shapes.newRectangleShape(0, 0, 10, 16))
		l.damage = self.dmg
		l.drawFloor = true
		game:emplace("projectiles", l)
		local l = Projectile:new("rapidfire_bullet", bluerect, self.paddle.x + off, self.paddle.y - 12, 0, -self.bulletSpeed, 0, "rectangle", self.bulletw, self.bulleth)
		--l:setShape(shapes.newRectangleShape(0, 0, 10, 16))
		l.damage = self.dmg
		l.drawFloor = true
		game:emplace("projectiles", l)
		playSound("rapidfire")
	end
	self.cd = self.cd - dt
	self.switchTimer = self.switchTimer - dt
	if self.switchTimer <= 0 then
		self.switch = not self.switch
		self.switchTimer = self.switchPeriod
	end
end

PaddleShotgun = class("PaddleShotgun", PaddleGun)

function PaddleShotgun:initialize()
	self.gunType = "PaddleShotgun"
	self.bulletCount = 0
	self.maxBullets = 12
end

function PaddleShotgun:update(dt)
	if canFire() and self.bulletCount < self.maxBullets then
		local deg = {-25, -15, -5, 5, 15, 25}
		for i, v in ipairs(deg) do
			local vx, vy = util.rotateVec(0, -800, v)
			local p = Projectile:new("shotgun_pellet", nil, self.paddle.x, self.paddle.y, vx, vy, 0, "circle", 5)
			p.damage = 5
			p.gun = self
			self.bulletCount = self.bulletCount + 1
			game:emplace("projectiles", p)
		end
		playSound("shotgun")
	end
end

PaddleBallCannon = class("PaddleBallCannon", PaddleGun)

function PaddleBallCannon:initialize()
	self.gunType = "PaddleBallCannon"
	self.bulletCount = 0
	self.maxBullets = 8
end

function PaddleBallCannon:update(dt)
	if canFire() and self.bulletCount < self.maxBullets then
		for i = -15, 15, 10 do
			local vx, vy = util.rotateVec(0, -800, i)
			local b = Projectile:new("ballcannon_small", nil, self.paddle.x, self.paddle.y, vx, vy, 0, "circle", 12)
			b:setComponent("bouncy")
			b.bounce = "strong"
			b.timer = 3
			game:emplace("projectiles", b)
			b.gun = self
		end
		self.bulletCount = self.bulletCount + 4
		playSound("ballcannonshot")
	end
end

PaddleDrillMissile = class("PaddleDrillMissile", PaddleGun)

function PaddleDrillMissile:initialize()
	self.gunType = "PaddleDrillMissile"
	self.bulletCount = 0
	self.maxBullets = 1
end

function PaddleDrillMissile:update(dt)
	local mx, my = self.paddle:getCursor()
	if canFire() and self.bulletCount < self.maxBullets then
		local x = math.max(self.paddle.x - self.paddle.w/2, math.min(self.paddle.x + self.paddle.w/2 - 1, mx))
		x = getGridPosInverse(getGridPos(x, 0))
		local p = Projectile:new("drill_missile", make_rect(0, 0, 16, 41), x, self.paddle.y, 0, -250, 0, "rectangle", 32, 82)
		p:setShape(shapes.newRectangleShape(0, 0, 32, 82))
		p:setComponent("piercing")
		p.pierce = "weak"
		p.onDeath = function(proj)
			local i = math.random(0, 3)
			local sw, wh = 50, 50
			local rw = 24
			local smokeStr = "explosion_smoke"
			local smoke = Particle:new(smokeStr, {i*rw, 0, rw, rw}, sw, wh, proj.x, proj.y, 0, 0, 0, 1)
			smoke.fadeRate = 750
			smoke.growthRate = 600
			smoke.growthAccel = -2000
			smoke.drawPriority = -1
			game:emplace("particles", smoke)
			Projectile.onDeath(proj)
			playSound("drillexplode")
		end
		p.damage = 1000
		p.strength = 2
		self.bulletCount = self.bulletCount + 1
		p.gun = self
		p:playAnimation("DrillMissile", true)
		game:emplace("projectiles", p)
		playSound("drill")
	end
end

PaddleMissile = class("PaddleMissile", PaddleGun)

function PaddleMissile:initialize(erratic)
	self.gunType = "PaddleMissile"
	self.erratic = erratic
	self.bulletCount = 0
	self.maxBullets = 4
end

function PaddleMissile:clone()
	local gun = PaddleMissile:new(self.erratic)
	return gun
end

function PaddleMissile:update(dt)
	if canFire() and self.bulletCount < self.maxBullets then
		local off = self.paddle.w/2-17
		for i = -1, 1, 2 do
			local p = Projectile:new("missile", nil, self.paddle.x + off*i, self.paddle.y - 20, 0, -500, 0, "rectangle", 16, 40)
			if self.erratic then
				p.damage = 10
				p.strength = 1
				p.update = function(proj, dt)
					proj.target = nil
					local storedDist = math.huge
					for _, br in pairs(game.bricks) do
						if br.armor < 2 then
							local dist = math.pow(br.x - proj.x, 2) + math.pow(br.y - proj.y, 2)
							if dist < storedDist then
								proj.target = br
								storedDist = dist
							end
						end
					end
					if proj.target then
						local mag = 10
						fx = (proj.target.x - proj.x) * mag
						fy = (proj.target.y - proj.y) * mag

						local spd = proj:getSpeed()
						proj.vx = proj.vx + (fx * dt)
						proj.vy = proj.vy + (fy * dt)
						proj:scaleVelToSpeed(spd)

						proj.angle = math.atan2(proj.vx, -proj.vy)
					end
					Projectile.update(proj, dt)
				end
				p:playAnimation("ErraticMissile", true)
			else
				p.vy = -50
				p.ay = -1000
				p.damage = 0
				p.strength = 0
				p.onBrickHit = function(proj, brick)
					stopSound(brick.hitSound)
					if proj:isDead() then return end
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
					playSound("detonator")
					proj:kill()
				end
				p.update = function(proj, dt)
					proj.aniScale = (proj.vy / -1000) + 0.25
					Projectile.update(proj, dt)
				end
				p:playAnimation("RegularMissile", true)
			end
			p.gun = self
			game:emplace("projectiles", p)
			self.bulletCount = self.bulletCount + 1
		end
		if self.erratic then
			--stopSound("erraticmissile")
			playSound("erraticmissile")
		else
			--stopSound("missile")
			playSound("missile")
		end
	end
end
