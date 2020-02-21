PowerUpBrick = class("PowerUpBrick", Brick)

function PowerUpBrick.test()
	game:emplace("bricks", PowerUpBrick:new(600, 600, 1))
end

function PowerUpBrick:initialize(x, y, id)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[6][5]
	self.powerup = PowerUp:new(x, y, id)
	self.powerup.showName = false
	self.color.a = 128
	self.brickType = "PowerUpBrick"
end

function PowerUpBrick:update(dt)
	self.powerup:setPos(self:getPos())
	Brick.update(self, dt)
end

function PowerUpBrick:onDeath()
	game:emplace("powerups", self.powerup)
	self.powerup.showName = true
	Brick.onDeath(self)
end

function PowerUpBrick:draw()
	self.powerup:draw()
	Brick.draw(self)
end