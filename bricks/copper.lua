CopperBrick = class("CopperBrick", Brick)

function CopperBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[5][12]
	self.health = 100
	self.armor = 2
	self.points = 500
	self.brickType = "CopperBrick"
	self.essential = false
end

function CopperBrick:onBallHit(ball, norm)
	if self:handlePatches(ball, norm) then
		self:takeDamage(ball.damage, ball.strength)
		local i = ball.flag.irritated
		ball.flag.irritated = "once"
		ball:onBrickHit(self, norm)
		return true
	else
		ball:onBrickHit(self, norm)
		return false
	end
end

function CopperBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:playAnimation("CopperShine")
end
