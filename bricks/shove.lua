ShoveBrick = class("ShoveBrick", Brick)

function ShoveBrick:initialize(x, y, dir)
	Brick.initialize(self, x, y)
	self.dir = dir
	if self.dir == "left" then
		self.rect = rects.brick[8][12]
	else
		self.rect = rects.brick[8][11]
	end
	self.armor = 2
	self.brickType = "ShoveBrick"
end

function ShoveBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)

	if not self.isMoving and self.alignedToGrid then
		local i, j = getGridPos(self.x, self.y)
		local dj = (self.dir == "left") and -1 or 1
		local affected = {} -- bricks are the KEYS
		while boundCheck(i, j) do
			local t = playstate.brickGrid[i][j]
			local check = false
			for _, br in pairs(t) do
				if not br.isMoving and br.alignedToGrid and (br.armor < 2 or br == self) then
					affected[br] = true
					check = true
				end
			end
			if not check then break end
			j = j + dj
		end
		local dx = (self.dir == "left") and -32 or 32
		for br in pairs(affected) do
			br:moveTo(br.x + dx, br.y, 0.2, "die")
			br.drawPriority = -1
			game.sortflag = true
		end
	end
end