SpeedBrick = class("SpeedBrick", Brick)

function SpeedBrick:initialize(x, y, fast)
	Brick.initialize(self, x, y)
	self.fast = fast
	self.rect = rects.brick[7][fast and 13 or 14]
	self.hitSound = fast and "speedupbrick" or "speeddownbrick"
	self.deathSound = self.hitSound
	self.brickType = "SpeedBrick"
end

function SpeedBrick:onBallHit(ball, norm)
	if Brick.onBallHit(self, ball, norm) then
		local mag = 50
		mag = self.fast and mag or -mag
		local spd = ball:getSpeed()
		spd = spd + mag
		ball:scaleVelToSpeed(spd)
		return true
	end
	return false
end

GoldSpeedBrick = class("GoldSpeedBrick", Brick)

function GoldSpeedBrick:initialize(x, y, fast)
	Brick.initialize(self, x, y)
	self.fast = fast
	self.rect = rects.brick[5][fast and 9 or 10]
	self.health = 100
	self.armor = 2
	self.points = 500
	self.hitSound = fast and "speedupbrick" or "speeddownbrick"
	self.deathSound = self.hitSound
	self.brickType = "GoldSpeedBrick"
	self.essential = false
end

function GoldSpeedBrick:onBallHit(ball, norm)
	if Brick.onBallHit(self, ball, norm) then
		local mag = 50
		mag = self.fast and mag or -mag
		local spd = ball:getSpeed()
		spd = spd + mag
		ball:scaleVelToSpeed(spd)
		return true
	end
	return false
end

function GoldSpeedBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:playAnimation(self.fast and "SpeedUpGoldShine" or "SlowDownGoldShine")
end