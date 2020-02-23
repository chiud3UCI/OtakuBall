ShoveDetonatorBrick = class("ShoveDetonatorBrick", Brick)

function ShoveDetonatorBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[7][11]
	self:playAnimation("ShoveDetonatorGlow", true)

	self.brickType = "ShoveDetonatorBrick"
end

function ShoveDetonatorBrick:onDeath()
	local i, j = getGridPos(self:getPos())

	-- generate valid positions beforehand
	local valid = {}
	for a = 1, 32 do
		for b = 1, 13 do
			bricks = playstate.brickGrid[a][b]
			if #bricks == 0 then
				valid[util.gridHash(a, b)] = true
			end
		end
	end
	for a = -1, 1, 1 do
		for b = -1, 1, 1 do
			local ii, jj = i + a, j + b
			if boundCheck(ii, jj) then
				valid[util.gridHash(ii, jj)] = nil
			end
		end
	end

	-- shove all surrounding bricks
	for a = -1, 1, 1 do
		for b = -1, 1, 1 do
			if not (a == 0 and b == 0) then
				local ii = i + a
				local jj = j + b
				if boundCheck(ii, jj) then
					for _, br in pairs(playstate.brickGrid[ii][jj]) do
						if br ~= self and br.armor < 2 and br.alignedToGrid and not br.isMoving then
							local row, col = ii + a, jj + b
							if boundCheck(row, col) then
								--shoveValid will be shared across all bricks
								--this can prevent bricks from bouncing
								--to the same location
								local x, y = getGridPosInverse(row, col)
								br:moveTo2(x, y, 500, "shovedet")
								br.shoveValid = valid
								br.drawPriority = 2
							end	
						end
					end
				end
			end
		end
	end
	Brick.onDeath(self)
end