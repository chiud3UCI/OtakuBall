ConveyorBrick = class("ConveyorBrick", Brick)

function ConveyorBrick:initialize(x, y, dir, spd)
	Brick.initialize(self, x, y)

	--capitalizes the first letter of the word
	dir = util.cap_first_letter(dir)
	spd = util.cap_first_letter(spd)

	self.dir, self.spd = dir, spd
	local mag
	if self.spd == "Fast" then 
		mag = 4000
	elseif self.spd == "Medium" then
		mag = 2000
	else --self.spd == "Slow" then
		mag = 1000
	end

	if self.dir == "Up" then
		self.fy = -mag
	elseif self.dir == "Down" then
		self.fy = mag
	elseif self.dir == "Left" then
		self.fx = -mag
	else --self.dir == "Right" then
		self.fx = mag
	end

	self.health = 1000
	self.armor = 10

	self.checkOverlap = false

	anistr = "Conveyor"..self.dir..self.spd
	self:playAnimation(anistr, "brick_spritesheet", true)

	self.brickType = "ConveyorBrick"
	self.essential = false
end

function ConveyorBrick:onBallHit(ball, norm)
	ball.fx, ball.fy = self.fx, self.fy
end

function ConveyorBrick:checkProjectileHit(proj)
	return false
end