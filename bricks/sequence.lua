SequenceBrick = class("SequenceBrick", Brick)

--num should be 1, 2, 3, 4, 5 only
function SequenceBrick:initialize(x, y, num)
	Brick.initialize(self, x, y)
	self.num = num
	self.rect = rects.brick[10][15+num]
	self.health = 10

	self.brickType = "SequenceBrick"
end

function SequenceBrick:takeDamage(dmg, str)
	self.armor = 1
	for k, br in pairs(game.bricks) do
		if br.brickType == "SequenceBrick" then
			if br.num < self.num then
				self.armor = 2
				break
			end
		end
	end
	Brick.takeDamage(self, dmg, str)
end
