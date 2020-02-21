JumperBrick = class("JumperBrick", Brick)

function JumperBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.imgstr = "brick_jumper"
	self.health = 40
	self.jump = "ready"
	self.jumpCount = 3
	self.brickType = "JumperBrick"
end

function JumperBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)

	if self.jumpCount > 0 and self.jump == "ready" then
		self.jump = "jumpstart"
		self.jumpTimer = 7*0.05
		self.armor = 2
		self.rect = rects.brick[1][5-self.jumpCount]
		self:playAnimation("Jumper"..(4-self.jumpCount))
		self.jumpCount = self.jumpCount - 1
	end

end

function JumperBrick:update(dt)
	if self.jump == "jumpstart" then
		self.jumpTimer = self.jumpTimer - dt
		if self.jumpTimer <= 0 then
			self.jump = "jumpend"
			self.jumpTimer = 7*0.05
			self:teleport()
		end
	elseif self.jump == "jumpend" then
		self.jumpTimer = self.jumpTimer - dt
		if self.jumpTimer <= 0 then
			self.jump = "ready"
			self.armor = 1
			self:stopAnimation()
		end
	end

	Brick.update(self, dt)
end

function JumperBrick:teleport()
	local candidates = {}
	for i = 1, 32-8 do
		for j = 1, 13 do
			if #playstate.brickGrid[i][j] == 0 then
				table.insert(candidates, {i, j})
			end
		end
	end
	if #candidates == 0 then return end
	local x, y = getGridPosInverse(unpack(candidates[math.random(#candidates)]))
	self:setPos(x, y)
end