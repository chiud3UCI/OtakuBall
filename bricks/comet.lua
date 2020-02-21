CometBrick = class("CometBrick", Brick)

function CometBrick:initialize(x, y, mode)
	Brick.initialize(self, x, y)
	self.mode = mode
	local ani
	local i, j
	if mode == "left" then
		i, j = 6, 13
		ani = "LeftCometGlow"
	elseif mode == "right" then
		i, j = 6, 14
		ani = "RightCometGlow"
	elseif mode == "horizontal" then
		i, j = 8, 9
		ani = "HorizontalCometGlow"
	else
		i, j = 8, 10
		ani = "VerticalCometGlow"
	end
	self.rect = rects.brick[i][j]

	self:playAnimation(ani, true)

	self.brickType = "CometBrick"
end

function CometBrick:createComet(dir)
	local deg
	local spd = 1000
	local vx, vy = 0, 0
	if dir == "left" then 
		deg = 0
		vx = -spd
	elseif dir == "down" then 
		deg = 90
		vy = -spd
	elseif dir == "right" then 
		deg = 180
		vx = spd
	else 
		deg = 270 
		vy = spd
	end

	local p = Projectile:new("comet", make_rect(0, 0, 16, 7), self.x, self.y, vx, vy, deg*math.pi/180, "rectangle", self.w - 1, self.h - 1)
	p:setComponent("piercing")
	p.pierce = "strong"
	p.damage = 1000
	p.strength = 2
	p.emberTimer = 0
	p.update = function(proj, dt)
		proj.emberTimer = proj.emberTimer - dt
		if proj.emberTimer <= 0 then
			proj.emberTimer = 0.01
			local vx, vy = util.rotateVec(0, 200, math.random(0, 360))
			local rad = math.random(1, 4) * math.pi/2
			local e = Particle:new("comet_ember", nil, 10, 10, proj.x, proj.y, vx, vy, rad, 2)
			e.growthRate = -10
			e.update = function(particle, dt)
				Particle.update(particle, dt)
				if particle.w <= 0 or particle.y - particle.h > window.h then particle:kill() end
			end
			e.ay = 1000
			game:emplace("particles", e)
		end
		Projectile.update(proj, dt)
	end
	game:emplace("projectiles", p)
	return p
end

function CometBrick:onDeath()
	if self.mode == "left" then
		self:createComet("left")
	elseif self.mode == "right" then
		self:createComet("right")
	elseif self.mode == "horizontal" then
		self:createComet("left")
		self:createComet("right")
	else
		self:createComet("up")
		self:createComet("down")
	end
	Brick.onDeath(self)
end