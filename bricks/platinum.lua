PlatinumBrick = class("PlatinumBrick", Brick)

function PlatinumBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[5][11]
	self.health = 1000
	self.armor = 3
	self.points = 500
	self.brickType = "PlatinumBrick"
	self.essential = false
end

function PlatinumBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:playAnimation("PlatinumShine")
end