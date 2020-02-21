GhostBrick = class("GhostBrick", Brick)

function GhostBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[11][8] --this references an invisible section of the spritesheet
	self.health = 100
	self.points = 500
	self.armor = 3
	self.brickType = "GhostBrick"
	self.essential = false
end

function GhostBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:playAnimation("GhostShine")
end
