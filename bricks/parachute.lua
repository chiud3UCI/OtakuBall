ParachuteBrick = class("ParachuteBrick", Brick)

function ParachuteBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[8][8]
	self.brickType = "ParachuteBrick"
end

function ParachuteBrick:onBallHit(ball, norm)
	Brick.onBallHit(self, ball, norm)
	if self:isDead() and ball:getR() == 7 and not ball.pierce then
		ball:deployParachute()
	end
end