AlienBrick = class("AlienBrick", Brick)

function AlienBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.imgstr = "brick_alien"
	self.rect = rects.brick[6][6]
	self.health = 50
	self.moveCount = 25
	self.actionTimer = 1.0
	self.prevDir = {0, 0} --same as null
	self.ri, self.rj = 1, 1
	self:updateAppearance()
	self.alienAniTimer = 0.2
	self.hitSound = "alienhit"
	self.deathSound = "aliendeath"

	self.brickType = "AlienBrick"
end

function AlienBrick:updateAppearance()
	local n
	local d
	if     self.health <= 10 then n = 5 d = math.huge
	elseif self.health <= 20 then n = 4 d = 2.5
	elseif self.health <= 30 then n = 3 d = 2.0
	elseif self.health <= 40 then n = 2 d = 1.5
	else                          n = 1 d = 1.0 end
	self.rj = n
	self.rect = rects.brick[self.ri][self.rj]
	self.actionDelay = d
end

function AlienBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:updateAppearance()
end

function AlienBrick:update(dt)
	if self.health > 10 then
		self.actionTimer = self.actionTimer - dt
		if self.actionTimer <= 0 and self.alignedToGrid and not self.isMoving then
			self.actionTimer = self.actionDelay
			local validTargets = {}
			local validDests = {}
			local i0, j0 = getGridPos(self.x, self.y)
			for ii = -1, 1 do
				for jj = -1, 1 do
					local i1, j1 = i0+ii, j0+jj
					if ii == 0 and jj == 0 then goto continue1 end
					if i1 > 32 - 8 then goto continue1 end
					if not boundCheck(i1, j1) then goto continue1 end
					if #playstate.brickGrid[i1][j1] > 0 then goto continue1 end
					if ii == 0 or jj == 0 then --vertical
						table.insert(validTargets, {i1, j1})
					else --diagonal
						table.insert(validDests, {i1, j1, ii, jj}) --append the deltas as well
					end
					::continue1::
				end
			end
			if #validTargets > 0 then
				local t = validTargets[math.random(1, #validTargets)]
				local x, y = getGridPosInverse(t[1], t[2])
				local br = NormalBrick:new(self.x, self.y, 2, 1)
				br.drawPriority = -1
				br:moveTo(x, y, 0.2, "die")
				game:emplace("bricks", br)
				table.insert(playstate.brickGrid[t[1]][t[2]], NullBrick:new(x, y))
			elseif #validDests > 0 and self.moveCount > 0 then
				self.moveCount = self.moveCount - 1
				local t = validDests[math.random(1, #validDests)]
				for i, v in ipairs(validDests) do
					if self.prevDir[1] == v[3] and self.prevDir[2] == v[4] then
						t = v
					end
				end
				self.prevDir[1] = t[3]
				self.prevDir[2] = t[4]
				local x, y = getGridPosInverse(t[1], t[2])
				self:moveTo(x, y, 0.2, "die")
				local br = NormalBrick:new(self.x, self.y, 1, 1)
				br.drawPriority = -1
				game:emplace("bricks", br)
				table.insert(playstate.brickGrid[t[1]][t[2]], NullBrick:new(x, y))
			end
		end
	end
	self.alienAniTimer = self.alienAniTimer - dt
	if self.alienAniTimer <= 0 then
		self.alienAniTimer = 0.2
		if self.ri == 4 then
			self.ri = 1
		else
			self.ri = self.ri + 1
		end
		self.rect = rects.brick[self.ri][self.rj]
	end
	Brick.update(self, dt)
end