Brick = class("Brick", Sprite)

function Brick:initialize(x, y)
	Sprite.initialize(self, "brick_spritesheet", rects.brick[1][1], 32, 16, x, y)
	--initial position of shape wont matter since it will be moved to the center of the sprite
	local shape = shapes.newRectangleShape(0, 0, 32, 16)
	self:setShape(shape)
	self.gameType = "brick"
	self.health   = 10
	self.armor    = 1
	self.points   = 20

	self.overlap = {} --this doesnt have to be used by every single brick type
	self.checkOverlap = true
	self.suppress = false --suppressing a brick will usually prevent it doing special things like spawning bricks or dropping powerups

	self.patch = {shield = {},
				  cycle = {},
				  invisible = nil}
	self.shieldSprites = {}

	self.oobcheck = false --Out of Bounds Check (if any part of it is outside the border)
	self.drawPriority = 0
	self.override = {}

	self.hitSound = "blockhit"
	self.deathSound = "blockbreak"

	self.brickType = "Brick"
	self.essential = true --determines whether or not this brick needs to be destroyed in order for the player to beat the level
end

function Brick:setPatches(patches)
	if patches.shield_up then self.patch.shield.up = true end
	if patches.shield_down then self.patch.shield.down = true end
	if patches.shield_left then self.patch.shield.left = true end
	if patches.shield_right then self.patch.shield.right = true end
	if patches.invisible then self.patch.invisible = true end
	if patches.antilaser then self.patch.antilaser = true end
	if patches.movement then
		local m = patches.movement
		self.patch.movement = {dir = m[1], spd = m[2], hit = m[3]}
	end
end

--called right before the game starts; after all the bricks are placed
function Brick:activate()
	local emplace = function(dir, i, j)
		if self.patch.shield[dir] then 
			local shield = Sprite:new("brick_spritesheet", rects.brick[i][j], 32, 16, self.x, self.y)
			local anistr = "Shield"..util.cap_first_letter(dir)
			function shield:playShieldAnimation()
				self:playAnimation(anistr)
			end
			self.shieldSprites[dir] = shield
		end
	end
	emplace("up", 7, 21)
	emplace("down", 6, 21)
	emplace("left", 7, 20)
	emplace("right", 6, 20)
	if self.patch.movement and not self.patch.movement.hit then
		self.alignedToGrid = true
		self:activateMovement()
	end
	if self.patch.antilaser then
		self.lasershield = Sprite:new("patch_antilaser", rects.brick[1][1], 32, 16, self.x, self.y)
	end
end

Brick.speed = {slow = 50, medium = 100, fast = 150}
--new speeds: 75, 150, 300
function Brick:activateMovement()
	if not self.alignedToGrid then return end
	local m = self.patch.movement
	local spd = Brick.speed[m.spd]
	if m.dir == "right" then
		self.vx = spd
	elseif m.dir == "left" then
		self.vx = -spd
	elseif m.dir == "up" then
		self.vy = -spd
	elseif m.dir == "down" then
		self.vy = spd
	end
	self.isMoving = true
	self.moveType = "constant"
end

function Brick:initSnapper()
	self.snapper = Sprite:new(nil, nil, 32, 16, self.x, self.y)
	self.snapper:playAnimation("SnapperMine", true)
end

--if you're extending this, call this function first then modify the copy
function Brick:clone() --something is still not right
	local c = util.copy(self)
	c.snapper = nil
	if self.isAnimating then
		c:playAnimation(self.currentAnistr, self.aniLoop)
	end
	c:setShape(shapes.newRectangleShape(0, 0, self.w, self.h))
	c.patch = {shield = {},
			   cycle = {},
			   invisible = nil,
			   antilaser = nil}
	c.overlap = {}
	return c
end

function Brick:kill()
	self.health = 0
end

function Brick:isDead()
	return self.health <= 0
end

function Brick:onDeath()
	playstate:incrementScore(self.points)

	if self.snapper then
		--explosion hitbox
		local e = Projectile:new("clear_pixel", nil, self.x, self.y, 0, 0, 0, "rectangle", 96, 48)
		e:setComponent("explosion")
		e.damage = 1000
		e.strength = 2
		game:emplace("callbacks", Callback:new(0.03, function() game:emplace("projectiles", e) end))
		--explosion smoke
		local i = math.random(0, 3)
		local smokeStr = "explosion_smoke"
		local p = Particle:new(smokeStr, {i*24, 0, 24, 24}, 50, 50, self.x, self.y, 0, 0, 0, 1)
		p.fadeRate = 750
		p.growthRate = 600
		p.growthAccel = -2000
		p.drawPriority = -1
		game:emplace("particles", p)
		--explosion sprite
		local anistr = "Explosion"
		local p = Particle:new("clear_pixel", nil, 96, 48, self.x, self.y, 0, 0, 0, 0.5)
		p:playAnimation(anistr)
		p.drawPriority = 1
		game:emplace("particles", p)
	end

	--if a gold-strength brick dies, it will spawn a forbidden brick in its place
	--in order to prevent other bricks from spawning in inaccessible places
	if self.armor == 2 then
		local br = ForbiddenBrick:new(self.x, self.y)
		game:emplace("bricks", br)
	end
end

function Brick.getHitSide(norm) --static
	local deg = math.atan2(norm.y, norm.x) * 180 / math.pi
	if deg >= -135 and deg < -45 then return "up"
	elseif deg >= -45 and deg < 45 then return "right"
	elseif deg >= 45 and deg < 135 then return "down"
	else return "left" end
end

function Brick:invisReveal()
	self.patch.invisible = nil
	for i = 1, 30 do
		local dx = math.random(0, 13)
		local dy = math.random(0, 5)
		local x = self.rect.x + dx
		local y = self.rect.y + dy
		local r = make_rect(x, y, 2, 2)
		local rad = math.random() * math.pi * 2
		local mag = math.random(100, 250)
		local p = Particle:new(self.imgstr, r, 3, 3, self.x+math.random(-25, 25), self.y+math.random(-12, 12), mag*math.cos(rad), mag*math.sin(rad), 0, 1.5)
		p.ay = 1000
		game:emplace("particles", p)
	end
	playSound("invisreveal")
end

function Brick:handlePatches(obj, norm)
	if self.patch.movement and self.patch.movement.hit and not self.isMoving then
		self:activateMovement()
	end

	if self.snapper then return true end
	if self.patch.invisible then
		self:invisReveal()
		if obj.strength < self.armor or obj.damage < self.health + 10 then
			return false
		end
	end
	local dir = Brick.getHitSide(norm)
	if self.patch.shield[dir] and obj.strength < 2 then
		self.shieldSprites[dir]:playShieldAnimation()
		return false
	end
	if self.patch.antilaser and obj.laser then
		playSound("antilaser")
		return false
	end
	return true
end

function Brick:checkBallHit(ball)
	if self.intangible then return false end
	--check if their bounding boxes overlap first
	local box1 = {self.shape:bbox()}
	local box2 = {ball.shape:bbox()}
	if not util.bboxOverlap(box1, box2) then return false end
	--then use SAT for more precise check
	local check, mtvx, mtvy = ball.shape:collidesWith(self.shape)
	if not check then return false end
	--checks to see if ball has collided with the brick in the previous frame
	if self.checkOverlap then
		if self.overlap[ball] then
			self.overlap[ball] = 1
			return false
		end
		self.overlap[ball] = 1
	end
	--then check if the normal vector is actually valid
	local norm = {x = mtvx, y = mtvy}
	local dx, dy = self.x - ball.x, self.y - ball.y
	if util.angleBetween(norm.x, norm.y, dx, dy) < math.pi / 2 then return false end
	if not ball:validCollision(norm.x, norm.y) then return false end --redundant, but better safe than sorry
	return true, norm
end

function Brick:onBallHit(ball, norm)
	local check = false
	if self:handlePatches(ball, norm) then
		self:takeDamage(ball.damage, ball.strength)
		check = true
	end
	ball:onBrickHit(self, norm)
	return check
end

function Brick:checkMenacerHit(menacer)
	return self:checkBallHit(menacer)
end

function Brick:onMenacerHit(menacer, norm)
	menacer:onBrickHit(self, norm)
end

function Brick:checkProjectileHit(proj)
	if self.intangible then return false end
	local box1 = {self.shape:bbox()}
	local box2 = {proj.shape:bbox()}
	if not util.bboxOverlap(box1, box2) then return false end
	local check, mtvx, mtvy = proj.shape:collidesWith(self.shape)
	if not check then return false end
	if self.checkOverlap then
		if self.overlap[proj] then
			self.overlap[proj] = 1
			return false
		end
		self.overlap[proj] = 1
	end
	if proj.shapeType ~= "circle" then return true end
	local norm = {x = mtvx, y = mtvy}
	if proj.vx == 0 and proj.vy == 0 then return true, norm end
	local dx, dy = self.x - proj.x, self.y - proj.y
	if util.angleBetween(norm.x, norm.y, dx, dy) < math.pi / 2 then return false end
	if not proj:validCollision(norm.x, norm.y) then return false end
	return true, norm
end

function Brick:onProjectileHit(proj, norm)
	if self:handlePatches(proj, {x=proj.x-self.x, y=proj.y-self.y}) then
		self:takeDamage(proj.damage, proj.strength)
	end
	proj:onBrickHit(self, norm)
end

--damage subtracts from health only if strength is greater than or equal to armor
--NOTE: str means strength
function Brick:takeDamage(dmg, str)
	if self.snapper then self:kill() end
	if self.armor <= str then
		self.health = self.health - dmg
	end

	if self:isDead() then
		playSound(self.deathSound, false, self)
	else
		playSound(self.hitSound, false, self)
	end
end

function Brick:update(dt)
	--intangibility means that projectiles and balls would go through the brick instead of hitting it
	if self.intangible then
		if self.intangibleTimer then
			self.intangibleTimer = self.intangibleTimer - dt
			if self.intangibleTimer <= 0 then
				self.intangible = nil
				self.intangibleTimer = nil
			end
		end
	end
	--optional death timer
	if self.deathTimer then
		self.deathTimer = self.deathTimer - dt
		if self.deathTimer <= 0 then
			self:kill()
		end
	end
	--update shield sprites (if any)
	for _, v in pairs(self.shieldSprites) do
		v:update(dt)
	end
	--processes overlap objects
	for obj, state in pairs(self.overlap) do
		if state == 1 then
			self.overlap[obj] = 0
		else
			self.overlap[obj] = nil
		end
	end

	--movement
	if self.isMoving then
		if self.moveType == "target" then
			self.moveTimer = self.moveTimer - dt
			if self.moveTimer <= 0 then
				self.isMoving = false
				if self.intangibleWhileMoving then
					self.intangible = nil
					self.intangibleWhileMoving = nil
				end
				self:setPos(unpack(self.destination))
				self:updateShape() --makes sure the shape is absolutely aligned before checking
				self.vx, self.vy = 0, 0
				if self.x < window.lwallx 
				or self.x > window.rwallx 
				or self.y < window.ceiling
				or self.y > window.h then
					self:kill()
					self.suppress = true --bricks that are pushed out of bounds shouldn't do anything special
				end
				if self.moveCheck then
					self:moveCheck()
				end
			end
		else --moveType == "constant"
			-- local x, y = self:getPos()
			-- local w, h = self.w/2, self.h/2
			-- if x - w < window.lwallx then self.vx = math.abs(self.vx) end
			-- if x + w > window.rwallx then self.vx = -math.abs(self.vx) end
			-- if y - h < window.ceiling then self.vy = math.abs(self.vy) end
			-- if y + h > window.h then self.vy = -math.abs(self.vy) end
		end
	end

	self.override.vx, self.override.vy = nil, nil
	-- if self.isMoving and self.moveType == "constant" then
	-- 	self.override.vx, self.override.vy = 0, 0
	-- end

	Sprite.update(self, dt)

	if self.override.vx then
		self.vx = self.override.vx
	end
	if self.override.vy then
		self.vy = self.override.vy
	end

	--update snapper
	if self.snapper then
		self.snapper:update(dt)
		self.snapper:setPos(self:getPos())
	end

	for _, s in pairs(self.shieldSprites) do
		s:setPos(self:getPos())
	end

	if self.lasershield then self.lasershield:setPos(self:getPos()) end

	--Out of Bounds check
	local x, y, w, h = self.x, self.y, self.w, self.h
	self.oobcheck =
		x - w/2 < window.lwallx or
		x + w/2 > window.rwallx or
		y - h/2 < window.ceiling or
		y + h/2 > window.h
end

function Brick:draw()
	if self.patch.invisible then return end

	--moving bricks will be cut off outside the border
	--may have conflict with slot machine
	if self.isMoving and self.oobcheck then
		love.graphics.setScissor(window.lwallx, window.ceiling, window.rwallx - window.lwallx, window.h - window.ceiling)
	end

	--specialized drawing method that prevents graphical glitches (maybe obsolete)
	legacySetColor(self.color.r, self.color.g, self.color.b, self.color.a)
	drawBrick(self.imgstr, self.rect, self.x, self.y, self.angle, self.w, self.h, nil, nil, nil, nil, self.drawFloor)
	--drawBrick(self.imgstr, self.rect, math.floor(self.x), math.floor(self.y) + 0.5, self.angle, self.w, self.h, nil, nil, nil, nil, false)
	--drawBrick(self.imgstr, self.rect, math.floor(self.x+0.5), math.floor(self.y+0.5) - 0.5, self.angle, self.w, self.h, nil, nil, nil, nil, false)

	--drawing order of shield sprites matters
	legacySetColor(255, 255, 255, 255)
	local s = self.shieldSprites
	if s.up then s.up:draw() end
	if s.down then s.down:draw() end
	if s.left then s.left:draw() end
	if s.right then s.right:draw() end

	if self.patch.antilaser then
		self.lasershield:draw()
	end

	--snappers
	if self.snapper then
		self.snapper:draw()
	end

	if self.isMoving and self.oobcheck then
		love.graphics.setScissor()
	end
end

--move within a certain time
function Brick:moveTo(x, y, time, funcstr)
	funcstr = funcstr or "null"
	self.isMoving = true
	self.moveType = "target"
	self.vx = (x - self.x) / time
	self.vy = (y - self.y) / time
	self.moveTimer = time
	self.destination = {x, y}
	self.moveCheck = Brick.moveCheck[funcstr]
end

--move at a certain speed
function Brick:moveTo2(x, y, spd, funcstr)
	funcstr = funcstr or "null"
	self.isMoving = true
	self.moveType = "target"
	local dx, dy = x - self.x, y - self.y
	local dist = math.sqrt(dx*dx + dy*dy)
	self.vx = dx / dist * spd
	self.vy = dy / dist * spd
	self.moveTimer = dist / spd
	self.destination = {x, y}
	self.moveCheck = Brick.moveCheck[funcstr]
end

function Brick:inheritMovement(br)
	if not br.isMoving then return end
	self.isMoving = true
	self.moveType = br.moveType
	self.vx = br.vx
	self.vy = br.vy
	self.moveTimer = br.moveTimer
	self.destination = br.destination
	self.moveCheck = br.moveCheck
end

Brick.moveCheck = 
{
	null = function(self)
	end,
	die = function(self) --dies if it overlaps a brick
		local bucket = playstate:getBrickBucket(self)
		local box1 = {self.shape:bbox()}
		for br in pairs(bucket) do
			if br ~= self then
				local box2 = {br.shape:bbox()}
				if util.bboxOverlap(box1, box2) and not br.isMoving then
					self:kill()
					return
				end
			end
		end
	end,
	kill = function(self) --kills all bricks it overlaps
		local bucket = playstate:getBrickBucket(self)
		local box1 = {self.shape:bbox()}
		for br in pairs(bucket) do
			if br ~= self then
				local box2 = {br.shape:bbox()}
				if util.bboxOverlap(box1, box2) and not br.isMoving then
					br:kill()
					br.suppress = true
				end
			end
		end
	end,
	shovedet = function(self) --special shove detonator brick behavior
		local i, j = getGridPos(self:getPos())
		local border = i == 1 or i == 32 or j == 1 or j == 13
		local bucket = playstate:getBrickBucket(self)
		local box1 = {self.shape:bbox()}
		for br in pairs(bucket) do
			if br ~= self then
				local box2 = {br.shape:bbox()}
				if util.bboxOverlap(box1, box2) and not br.isMoving then
					--bounce towards the closest avaliable free space
					local valid = self.shoveValid
					local valid2 = {}
					local minDist = math.huge
					for hash, _ in pairs(valid) do
						local row, col = util.gridHashInv(hash)
						local dist = (i - row) ^ 2 + (j - col) ^ 2
						minDist = math.min(minDist, dist)
						valid2[hash] = dist
					end
					local candidates = {}
					for hash, dist in pairs(valid2) do
						if dist == minDist then
							table.insert(candidates, hash)
						end
					end
					if #candidates == 0 then self:kill() end --this should almost never happen
					local hash = candidates[math.random(#candidates)]
					valid[hash] = nil --prevent other shoved blocks from going here
					local row, col = util.gridHashInv(hash)
					local x, y = getGridPosInverse(row, col)
					self:moveTo2(x, y, 500, "die")
					self.shoveValid = nil
					self.drawPriority = 2
					game.sortflag = true
					break
				end
			end
		end
	end
}

--[[
Assumptions:
	-All bricks are 32 x 16 (This probably needs to be more strictly enforced)
	-All moving bricks are aligned to a row OR a column
	-Only bricks that have been aligned to grid have been moved	
]]

local function compare_x(b1, b2)
	return b1.br.x < b2.br.x
end
local function compare_y(b1, b2)
	return b1.br.y < b2.br.y
end

--only the sign of the delta matters
--cascade is also the current index
--cascade is recursive and only needs to be done on the left side
local function switch_x(b, right, cascade, t)
	if b.switch then return end
	local br = b.br
	if right then
		if br.vx < 0 then
			br.vx = -br.vx
			b.switch = true
		end
	else
		if br.vx > 0 then
			br.vx = -br.vx
			b.switch = true
		end
	end
	if cascade and cascade >= 2 then
		local b2 = t[cascade-1]
		if br.vx < 0 and br.x - b2.br.x <= 32 then
			return switch_x(b2, right, cascade-1, t)
		end
	end

end
local function switch_y(b, down, cascade, t)
	if b.switch then return end
	local br = b.br
	if down then
		if br.vy < 0 then
			br.vy = -br.vy
			b.switch = true
		end
	else
		if br.vy > 0 then
			br.vy = -br.vy
			b.switch = true
		end
	end
	if cascade and cascade >= 2 then
		local b2 = t[cascade-1]
		if br.vy < 0 and br.y - b2.br.y <= 16 then
			return switch_y(b2, down, cascade-1, t)
		end
	end
end

--this handles the COLLISIONS of bricks
--the bricks should have already moved
function Brick.manageMovement()
	local hori = {}
	local vert = {}

	for i = 1, 32 do hori[i] = {} end
	for j = 1, 13 do vert[j] = {} end

	--Add all ALIGNED STATIC BRICKS to the lists
	--{static = true/false, br = brick}
	for _, br in pairs(game.bricks) do
		local check_static = not br.isMoving and br.alignedToGrid
		local check_moving = br.isMoving and br.moveType == "constant"
		if check_static or check_moving then --mutually exclusive
			local i, j = getGridPos(br:getPos())
			i = math.min(math.max(i, 1), 32)
			j = math.min(math.max(j, 1), 13)
			local b = {static = check_static, br = br}
			--static bricks can occupy both horizontal and vertical rows
			if check_static then
				table.insert(hori[i], b)
				table.insert(vert[j], b)
			else
				--In order to make horizontal and vertical bricks collide,
				--add them as static bricks in the opposite tables
				local cx, cy = getGridPosInverse(i, j)
				local b2 = {static = true, br = br}
				if br.vy == 0 then --brick is horizontal moving
					table.insert(hori[i], b)
					table.insert(vert[j], b2)
					-- if br.x < cx and j-1 >= 1 then
					-- 	table.insert(vert[j-1], b2)
					-- elseif br.x > cx and j+1 <= 13 then
					-- 	table.insert(vert[j+1], b2)
					-- end
				else --brick is vertical moving
					table.insert(vert[j], b)
					table.insert(hori[i], b2)
					-- if br.y < cy and i-1 >= 1 then
					-- 	table.insert(hori[i-1], b2)
					-- elseif br.y > cy and i+1 <= 32 then
					-- 	table.insert(hori[i+1], b2)
					-- end
				end
			end
		end
	end

	for i = 1, 32 do
		local t = hori[i]
		local len = #t
		if len > 0 then
			--sort them all by position
			table.sort(t, compare_x)
			--check the intervals between each brick
			--if the interval is < 32 then move one brick apart
			--first, check from left to right, moving bricks to the right
			--second, check from right to left, moving bricks to the left
			--if theres still moving brick overlap, then delete the moving brick
			--order of those two don't matter
			--dont forget to check wall collisions
			--WHAT IF THE LEFT BRICK IS TO THE RIGHT OF THE RIGHT BRICK
			--	then just move the right brick to the right like planned
			local b1 = t[1]
			if not b1.static and b1.br.x < window.lwallx + 16 then
				b1.br.x = window.lwallx + 16
				switch_x(b1, true)
			end
			for i = 1, len-1 do
				local b1, b2 = t[i], t[i+1]
				if not b2.static then
					local br1, br2 = b1.br, b2.br
					if br2.x - br1.x < 32 then
						br2.x = br1.x + 32
						--prevents bricks traveling in exact same velocity from bouncing off of each other
						local same = br1.vx == br2.vx
						switch_x(b2, true)
						if not b1.static and not same then
							switch_x(b1, false, i, t)
						end
					end
				end
			end
			--now do the reverse
			local b1 = t[len]
			if not b1.static and b1.br.x > window.rwallx - 16 then
				b1.br.x = window.rwallx - 16
				switch_x(b1, false)
			end
			for i = len, 2, -1 do
				local b1, b2 = t[i], t[i-1]
				if not b2.static then
					local br1, br2 = b1.br, b2.br
					if br2.x - br1.x > -32 then
						br2.x = br1.x - 32
						switch_x(b2, false)
						if br2.x < window.lwallx + 16 then
							br2:kill()
						end
					end
				end
			end
		end
	end

	--Does the exact same thing but for vertical moving bricks
	for i = 1, 13 do
		local t = vert[i]
		local len = #t
		if len > 0 then
			--sort them all by position
			table.sort(t, compare_y)
			--check whether the first brick overlaps the wall
			local b1 = t[1]
			if not b1.static and b1.br.y < window.ceiling + 8 then
				b1.br.y = window.ceiling + 8
				switch_y(b1, true)
			end
			--up to down
			for i = 1, len-1 do
				local b1, b2 = t[i], t[i+1]
				if not b2.static then
					local br1, br2 = b1.br, b2.br
					if br2.y - br1.y < 16 then
						br2.y = br1.y + 16
						--prevents bricks traveling in exact same velocity from bouncing off of each other
						local same = br1.vy == br2.vy
						switch_y(b2, true)
						if not b1.static and not same then
							switch_y(b1, false, i, t)
						end
					end
				end
			end
			--down to up
			local b1 = t[len]
			if not b1.static and b1.br.y > window.h - 8 then
				b1.br.y = window.h - 8
				switch_y(b1, false)
			end
			for i = len, 2, -1 do
				local b1, b2 = t[i], t[i-1]
				if not b2.static then
					local br1, br2 = b1.br, b2.br
					if br2.y - br1.y > -16 then
						br2.y = br1.y - 16
						switch_y(b2, false)
						if br2.y < window.ceiling + 8 then
							br2:kill()
						end
					end
				end
			end
		end
	end
end

--Null Brick dies after being placed
--used to resolve simultaneous brick placement
NullBrick = class("NullBrick", Brick)

function NullBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.health = 0
	self.armor = 10
	self.points = 0
	self.brickType = "NullBrick"
	self.essential = false
end

function NullBrick:draw()
end

--Forbidden Brick prevents any brick from moving towards that location

ForbiddenBrick = class("ForbiddenBrick", Brick)

function ForbiddenBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.imgstr = "brick_spritesheet"
	self.rect = rects.brick[3][22]
	self.health = 1000
	self.armor = 10
	self.points = 0
	self.brickType = "ForbiddenBrick"
	self.essential = false
end

--Patches will have no effect on this brick
function ForbiddenBrick:setPatches(patches)
end

function ForbiddenBrick:checkBallHit(ball)
	return false
end

function ForbiddenBrick:checkProjectileHit(proj)
	return false
end

function ForbiddenBrick:draw()
	if showforbidden then
		drawBrick(self.imgstr, self.rect, self.x, self.y, self.angle, self.w, self.h, nil, nil, nil, nil, self.drawFloor)
	end
end

