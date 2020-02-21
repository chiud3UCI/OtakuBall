LaserEyeBrick = class("LaserEyeBrick", Brick)

function LaserEyeBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[6][15]
	self.health = 20
	self.active = false
	self.laserTimer = 3

	self.brickType = "LaserEyeBrick"
end

function LaserEyeBrick:reset()
	self:stopAnimation()
	self.rect = rects.brick[6][15]
	self.health = 20
	self.active = false
	self.laserTimer = 3
end

function LaserEyeBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	if not self.active and self.health <= 10 then
		self.active = true
		self.rect = rects.brick[6][16]
		self:playAnimation("LaserEyeGlow", true)
	end
end

function LaserEyeBrick:update(dt)
	if self.active then
		self.laserTimer = self.laserTimer - dt
		if self.laserTimer <= 0 then
			self.laserTimer = 3
			local paddle = game.paddle
			local p = Projectile:new("lasereye_laser", nil, self.x, self.y, paddle.x - self.x, paddle.y - self.y, 0, "rectangle", 30, 30)
			p:scaleVelToSpeed(500)
			p.colFlag = {paddle = true}
			p.enemy = true
			p.onPaddleHit = function(proj, _paddle)
				_paddle.stunTimer = 1
				proj:kill()
			end
			game:emplace("projectiles", p)
		end
	end
	Brick.update(self, dt)
end