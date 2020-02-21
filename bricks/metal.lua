MetalBrick = class("MetalBrick", Brick)

function MetalBrick:initialize(x, y, health)
	Brick.initialize(self, x, y)
	self.health = health
	self.maxHealth = health
	self:updateAppearance()
	self.brickType = "MetalBrick"
end

function MetalBrick:updateAppearance()
	local j
	local str
	local p
	if self.health <= 20 then
		j = 2
		p = 100
		str = "Bronze"
	elseif self.health <= 30 then
		j = 3
		p = 120
		str = "Silver"
	elseif self.health <= 40 then
		j = 4
		p = 140
		str = "Blue"
	elseif self.health <= 50 then
		j = 5
		p = 160
		str = "Pink"
	elseif self.health <= 60 then
		j = 6
		p = 180
		str = "Purple"
	else
		j = 7
		p = 200
		str = "Green"
	end
	self.rect = rects.brick[5][j]
	self.hitAni = str.."MetalShine"
	self.metalType = str
	self.points = p
end

function MetalBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:playAnimation(self.hitAni)
end

function MetalBrick:bulkUp()
	self.maxHealth = math.min(70, self.maxHealth + 10)
	self.health = self.maxHealth
	self:updateAppearance()
end

function MetalBrick:weaken()
	self.maxHealth = math.max(20, self.maxHealth - 10)
	self.health = self.maxHealth
	self:updateAppearance()
end

function MetalBrick:draw()
	if self.underlay then
		drawBrick(self.underlay.imgstr, self.underlay.rect, self.x, self.y, self.angle, self.w, self.h, nil, nil, nil, nil, self.drawFloor)
	end
	Brick.draw(self)
end

