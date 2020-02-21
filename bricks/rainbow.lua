RainbowBrick = class("RainbowBrick", Brick)

function RainbowBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[6][8]

	self.brickType = "RainbowBrick"
end

function RainbowBrick:onDeath()
	local candidates = {}
	local ci, cj = getGridPos(self:getPos())
	for a = -1, 1 do
		for b = -1, 1 do
			if a == 0 and b == 0 then goto continue1 end
			local i, j = ci + a, cj + b
			if not boundCheck(i, j) then goto continue1 end
			if #playstate.brickGrid[i][j] == 0 then
				table.insert(candidates, {i, j})
			end
			::continue1::
		end
	end
	if #candidates > 0 then
		local n = math.random(#candidates)
		for foo = 1, n do
			local index = math.random(#candidates)
			local x, y = getGridPosInverse(unpack(candidates[index]))
			table.remove(candidates, index)
			local br = NormalBrick.randomColorBrick(self.x, self.y)
			br:moveTo(x, y, 0.2, "die")
			game:emplace("bricks", br)
		end
	end
	Brick.onDeath(self)
end