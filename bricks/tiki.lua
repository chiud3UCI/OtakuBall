TikiBrick = class("TikiBrick", Brick)

function TikiBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[7][12]
	self.health = 100
	self.armor = 2
	self.hitCount = 0
	self.hitSound = "tikihit"

	self.brickType = "TikiBrick"
	self.essential = false
end

function TikiBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:playAnimation("TikiFlash")
	self.hitCount = self.hitCount + 1
	if self.hitCount == 3 then
		self.hitCount = 0
		local paddle = game.paddle
		local p = Projectile:new("white_pixel", nil, self.x, self.y, paddle.x - self.x, paddle.y - self.y, 0, "rectangle", 5, 25)
		p:scaleVelToSpeed(1000)
		p.angle = math.atan2(p.vx, -p.vy)
		p:setColor(255, 255, 0)
		p.colFlag = {paddle = true}
		p.enemy = true
		p.onPaddleHit = function(proj, _paddle)
			_paddle:decrementSize()
			proj:kill()
		end
		game:emplace("projectiles", p)
	end
end