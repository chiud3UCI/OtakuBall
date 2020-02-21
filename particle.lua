Particle = class("Particle", Sprite)

function Particle:initialize(imgstr, rect, w, h, x, y, vx, vy, angle, time)
	Sprite.initialize(self, imgstr, rect, w, h, x, y, vx, vy, angle)

	self.timer = time or 1

	self.fadeDelay = 0
	self.fadeRate = 0
	self.angularVel = 0
	self.growthRate = 0
	self.growthAccel = 0

	self.drawPriority = 0
end

function Particle:update(dt)
	self.timer = self.timer - dt
	if self.timer <= 0 then
		self.dead = true
	end

	if self.fadeDelay > 0 then
		self.fadeDelay = self.fadeDelay - dt
	else
		local alpha = self.color.a
		alpha = math.max(0, math.min(255, alpha - self.fadeRate * dt))
		self.color.a = alpha
	end
	local delta = (self.growthRate * dt) + (0.5 * self.growthAccel * dt * dt)
	local ratio = self.h/self.w
	self.w = self.w + delta
	self.h = self.h + delta * ratio
	self.growthRate = self.growthRate + (self.growthAccel * dt)

	Sprite.update(self, dt)
end

function Particle:draw()
	Sprite.draw(self)
end