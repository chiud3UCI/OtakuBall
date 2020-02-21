GoldBrick = class("GoldBrick", Brick)

function GoldBrick:initialize(x, y, plated)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[5][1]
	self.health = 100
	self.points = 500
	if plated then 
		self.plated = true
		self.health = 110
		self.rect = rects.brick[5][8]
	end
	self.armor = 2
	self.brickType = "GoldBrick"
	self.essential = self.plated == true
end

function GoldBrick:takeDamage(dmg, str)
	if self.plated and str == 1 then
		dmg = math.max(0, math.min(dmg, self.health - 100))
		str = 2
	end
	Brick.takeDamage(self, dmg, str)
	self:stopAnimation()
	if self.plated then
		if self.health <= 100 then
			self.plated = false
			self.essential = false
			self.rect = rects.brick[5][1]
			playstate:incrementScore(20)
		end
		self:playAnimation("PlatedGoldShine")
	else
		self:playAnimation("GoldShine")
	end
end