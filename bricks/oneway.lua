OneWayBrick = class("OneWayBrick", Brick)

function OneWayBrick:initialize(x, y, dir)
	Brick.initialize(self, x, y)
	local i, j
	dir = dir:lower()
	if dir == "up" then
		i, j = 4, 21
	elseif dir == "down" then
		i, j = 5, 21
	elseif dir == "left" then
		i, j = 4, 22
	else --dir == "right"
		i, j = 5, 22
	end
	self.color.a = 179
	self.rect = rects.brick[i][j]
	self.health = 1000
	self.armor = 10
	self.dir = dir
	self.brickType = "OneWayBrick"
	self.essential = false
end

function OneWayBrick:onBallHit(ball, norm)
	local xn, yn
	if     self.dir == "up" then
		xn, yn = 0, -1
	elseif self.dir == "down" then
		xn, yn = 0, 1
	elseif self.dir == "left" then 
		xn, yn = -1, 0
	else --self.dir == "right"
		xn, yn = 1, 0
	end
	ball:handleCollision(xn, yn)
end

function OneWayBrick:checkProjectileHit(proj)
	return false
end

function OneWayBrick:draw()
	if playstate.background.tile then
		self.color.a = 255
	end
	Brick.draw(self)
end