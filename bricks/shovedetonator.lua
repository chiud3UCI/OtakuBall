ShoveDetonatorBrick = class("ShoveDetonatorBrick", Brick)

function ShoveDetonatorBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[7][11]
	self:playAnimation("ShoveDetonatorGlow", true)

	self.brickType = "ShoveDetonatorBrick"
end

function ShoveDetonatorBrick:onDeath()
	local i, j = getGridPos(self:getPos())
	for a = -1, 1, 1 do
		for b = -1, 1, 1 do
			if not (a == 0 and b == 0) then
				ii = i + a
				jj = j + b
				if boundCheck(ii, jj) then
					for _, br in pairs(playstate.brickGrid[ii][jj]) do
						if br ~= self and br.armor < 2 and br.alignedToGrid and not br.isMoving then
							local x, y = getGridPosInverse(ii + a, jj + b)
							br:moveTo2(x, y, 500, "bounce")
							br.bounceDir = {a, b}
							br.drawPriority = 2
						end
					end
				end
			end
		end
	end
	Brick.onDeath(self)
end