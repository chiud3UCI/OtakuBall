FactoryBrick = class("FactoryBrick", Brick)

function FactoryBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.imgstr = "brick_factory"
	self.health = 70
	self:updateAppearance()
	self.cooldown = 0.2

	self.brickType = "FactoryBrick"
end

function FactoryBrick:updateAppearance()
	local c
	local i, j
	if self.health <= 10 then
		c = "Red"
		i, j = 1, 3
	elseif self.health <= 20 then
		c = "Yellow"
		i, j = 1, 2
	else
		c = "Green"
		i, j = 1, 1
	end
	self.hitAni = c.."FactoryFlash"
	self.rect = rects.brick[i][j]
end

function FactoryBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:stopAnimation()
	self:updateAppearance()
	self:playAnimation(self.hitAni)
end

local oppositeDir = {
	left = "right",
	right = "left",
	up = "down",
	down = "up"
}

function FactoryBrick:onBallHit(ball, norm)
	local check = Brick.onBallHit(self, ball, norm)
	if check and self.cooldown <= 0 and not self.isMoving and self.alignedToGrid then
		local dir = Brick.getHitSide(norm)
		--brick comes out from the OPPOSITE SIDE
		self:generateBrick(oppositeDir[dir])
	end
	return check
end

function FactoryBrick:generateBrick(dir)
	if self.cooldown <= 0 and not self.isMoving and self.alignedToGrid then
		self.cooldown = 0.2
		local i, j = getGridPos(self.x, self.y)
		local br = NormalBrick.randomColorBrick(self.x, self.y)
		br.drawPriority = -1
		br.alignedToGrid = true
		game:emplace("bricks", br)
		table.insert(playstate.brickGrid[i][j], br)
		local di, dj, dx, dy
		if dir == "right" then
			di, dj = 0, 1
			dx, dy = 32, 0
		elseif dir == "left" then
			di, dj = 0, -1
			dx, dy = -32, 0
		elseif dir == "down" then
			di, dj = 1, 0
			dx, dy = 0, 16
		elseif dir == "up" then
			di, dj = -1, 0
			dx, dy = 0, -16
		end
		local affected = {} -- bricks are the KEYS
		while boundCheck(i, j) do
			local t = playstate.brickGrid[i][j]
			local check = false
			for _, br in pairs(t) do
				if br ~= self and not br.isMoving and br.alignedToGrid and br.armor < 2 then
					affected[br] = true
					check = true
				end
			end
			if not check then break end
			i = i + di
			j = j + dj
		end
		for br in pairs(affected) do
			br:moveTo(br.x + dx, br.y + dy, 0.2, "die")
		end
	end
end

function FactoryBrick:update(dt)
	self.cooldown = self.cooldown - dt
	Brick.update(self, dt)
end