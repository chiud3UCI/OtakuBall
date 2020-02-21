DetonatorBrick = class("DetonatorBrick", Brick)


function DetonatorBrick:initialize(x, y, type)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[6][4]
	self.detType = type
	if self.detType == "freeze" then
		self:playAnimation("FreezeDetonatorGlow", true)
	elseif self.detType == "neo" then
		self:playAnimation("NeoDetonatorGlow", true)
	else
		self:playAnimation("DetonatorGlow", true)
	end

	if self.detType == "freeze" then
		self.deathSound = "icedetonator"
	else
		self.deathSound = "detonator"
	end

	self.brickType = "DetonatorBrick"
end

--explosion size should be 3 times bigger than a standard brick
--neo detonator should be 5 times bigger
function DetonatorBrick:onDeath()
	--the damaging explosion projectile is invisible; the particle provides the explosion sprite
	local w, h = 96, 48
	if self.detType == "neo" then
		w, h = 160, 80
	end
	local e = Projectile:new("clear_pixel", nil, self.x, self.y, 0, 0, 0, "rectangle", w, h)
	e:setComponent("explosion")
	e.damage = 1000
	e.strength = 2
	if self.detType == "freeze" then
		e.freeze = true
	end
	game:emplace("callbacks", Callback:new(0.03, function() game:emplace("projectiles", e) end))

	--explosion smoke
	local i = math.random(0, 3)
	local sw, sh = 50, 50
	local rw = 24
	local smokeStr = "explosion_smoke"
	if self.smokeStrdetType == "freeze" then
		smokeStr = smokeStr.."_freeze"
	elseif self.detType == "neo" then
		smokeStr = smokeStr.."_mega"
		sw, sh = 100, 100
		rw = 36
	end
	local p = Particle:new(smokeStr, {i*rw, 0, rw, rw}, sw, sh, self.x, self.y, 0, 0, 0, 1)
	p.fadeRate = 750
	p.growthRate = 600
	p.growthAccel = -2000
	p.drawPriority = -1
	game:emplace("particles", p)

	--explosion sprite
	local anistr = "Explosion"
	if self.detType == "freeze" then
		anistr = "FreezeExplosion"
	end
	local p = Particle:new("clear_pixel", nil, w, h, self.x, self.y, 0, 0, 0, 0.5)
	p:playAnimation(anistr)
	p.drawPriority = 1
	game:emplace("particles", p)

	Brick.onDeath(self)
end