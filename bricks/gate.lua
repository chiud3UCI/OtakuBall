--Ball goes through a gate, ball comes out through another gate of the same color
--Balls can't enter a dark gate.
--There is a small delay for teleportation.
--When teleporting, the ball is temporarily removed from the list of balls
--and then reinserted once the ball emerges from the gate
--if there are any dark gates, then all regular gates will be directed to a dark gate

--TODO: do something about gate bricks bypassing the ball count
--rare glitch with the ball exiting at an extreme speed
--eh, good enough for now

local lookup = {}
local colors = {"red", "blue", "green", "orange"}
for i, v in ipairs(colors) do
	lookup[v] = {[false] = rects.brick[1][i], [true] = rects.brick[1][4+i]}
end

GateBrick = class("GateBrick", Brick)

GateBrick.ballCount = 0

function GateBrick:initialize(x, y, color, dark)
	Brick.initialize(self, x, y)
	self.gateColor = color
	self.dark = (dark == true)
	self.imgstr = "brick_gate"
	self.rect = lookup[self.gateColor][self.dark]
	self.anistr = util.cap_first_letter(self.gateColor).."GateFlash"
	if self.dark then self.anistr = "Dark"..self.anistr end
	self.health = 1000
	self.armor = 10

	self.ballQueue = Queue:new()
	self.ballCooldown = {}
	self.releaseTimer = 0
	self.flashTimer = 0
	self.flash = false

	self.brickType = "GateBrick"
	self.essential = false
end

-- --specialized method of checking

function GateBrick:checkBallHit(ball)
	if self.dark or ball.stuckToPaddle then return false end
	return Brick.checkBallHit(self, ball)
end

function GateBrick:onBallHit(ball, norm)
	if self.ballCooldown[ball] then return end
	
	local light = {}
	local dark = {}
	for _, br in pairs(game.bricks) do
		if br.gateColor == self.gateColor and br ~= self then
			if br.dark then 
				table.insert(dark, br)
			else 
				table.insert(light, br) 
			end
		end
	end
	candidates = (#dark > 0) and dark or light
	if #candidates > 0 then
		if ball.gateInfo and ball.gateInfo.brick == self then
			local vx, vy = unpack(ball.gateInfo.vel)
			if util.deltaEqual(ball.vx, vx, 0.1) and util.deltaEqual(ball.vy, vy, 0.1) then
				local deg = math.random(-30, 30)
				ball:setVel(util.rotateVec(ball.vx, ball.vy, deg))
			end 
		end
		ball.gateInfo = {brick = self, vel = {ball:getVel()}}

		local target = candidates[math.random(1, #candidates)]
		ball:setPos(target:getPos())
		ball.isTeleporting = true
		if ball.flag.energy then
			ball.energyRecord = {}
			for _, e in pairs(ball.energyBalls) do
				e:setPos(ball:getPos())
			end
		end
		target.ballQueue:pushLeft(ball)
		GateBrick.ballCount = GateBrick.ballCount + 1
		playSound("gateenter1")
		playSound("gateenter2")
	end
end

function GateBrick:checkProjectileHit(proj)
	return false
end

function GateBrick:update(dt)
	local temp = {}
	for ball, time in pairs(self.ballCooldown) do
		local t = time - dt
		if t > 0 then
			temp[ball] = t
		end
	end
	self.ballCooldown = temp

	if self.ballQueue:size() > 0 then
		if not self.flash then
			self.releaseTimer = self.releaseTimer - dt
			if self.releaseTimer <= 0 then
				self.flash = true
				self.flashTimer = 0.5
				self:playAnimation(self.anistr)
			end
		else
			self.flashTimer = self.flashTimer - dt
			if self.flashTimer <= 0 then
				self.flash = false
				self.releaseTimer = 0.5
				local ball = self.ballQueue:popRight()
				ball.bypass_ball_limit = true
				game:emplace("balls", ball)
				ball.isTeleporting = false
				self.overlap[ball] = 1
				GateBrick.ballCount = GateBrick.ballCount - 1
				self.ballCooldown[ball] = 3
			end
		end
	else
		self.releaseTimer = self.releaseTimer - dt
	end

	Brick.update(self, dt)
end