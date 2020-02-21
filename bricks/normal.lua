NormalBrick = class("NormalBrick", Brick)

function NormalBrick:initialize(x, y, i, j, imgstr)
	Brick.initialize(self, x, y)
	imgstr = imgstr or "brick_spritesheet"
	self.imgstr = imgstr
	self.rect = rects.brick[i][j]
	self.ri, self.rj = i, j
	self.brickType = "NormalBrick"
end

function NormalBrick:onDeath()
	if not self.suppress then
		if self.x > window.lwallx and self.x < window.rwallx and powerupGenerator:canSpawn() then
			local id = powerupGenerator:getId()
			local p = PowerUp:new(self.x, self.y, id)
			game:emplace("powerups", p)
		end
	end
	Brick.onDeath(self)
end

function NormalBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	if self.bulk then
		if self.health <= 10 then
			self.bulk = nil
		end
	end
end

function NormalBrick:update(dt)
	if self.uv then
		self.uvTimer = self.uvTimer - dt
		if self.uvTimer <= 0 then
			self.uvTimer = 0
			self:kill()
			self:ultravioletDeath()
			playSound("ultraviolet")
		end
	end
	Brick.update(self, dt)
end

function NormalBrick:draw()
	if self.uv then
		shader.glow:send("target", {204/255, 0/255, 255/255})
		shader.glow:send("mag", 1 - self.uvTimer)
		love.graphics.setShader(shader.glow)
	end
	if self.bulk then
		local tempImgstr, tempRect = self.imgstr, self.rect
		self.imgstr, self.rect = self.bulk.imgstr, self.bulk.rect
		Brick.draw(self)
		self.imgstr, self.rect = tempImgstr, tempRect
	else
		Brick.draw(self)
	end
	love.graphics.setShader()
end

function NormalBrick:bulkUp() --called by the Bulk powerup
	if self.bulk or self.imgstr == "brick_unification" then return end
	local bulk = {imgstr = "brick_bulk"}
	local ri, rj = 1, 1
	if self.imgstr == "brick_spritesheet" then
		ri, rj = self.ri, self.rj
	elseif self.imgstr == "brick_grey" then
		ri, rj = 5, self.rj
	elseif self.imgstr == "brick_bright" then
		ri, rj = 6, self.rj
	elseif self.imgstr == "brick_jetblack" then
		ri, rj = 3, 21
	elseif self.imgstr == "brick_white" then
		ri, rj = 2, 21
	end
	self.bulk = {imgstr = "brick_bulk", rect = rects.brick[ri][rj]}
	self.health = 20
end

function NormalBrick:unify() --called by the Unification powerup
	self.unification = true
end

function NormalBrick:ultraviolet() --called by the Ultaviolet powerup
	self.uv = true
	self.uvTimer = 1
end

function NormalBrick:ultravioletDeath()
	for i = 1, 2 do
		for j = 1, 4 do
			local rx = self.rect.x + 4*(j-1)
			local ry = self.rect.y + 4*(i-1)
			local x = self.x - self.w/2 + 8*j - 4
			local y = self.y - self.h/2 + 8*i - 4
			if j == 4 then rx = rx - 1 end
			if i == 2 then ry = ry - 1 end
			local rad = math.random() * math.pi * 2
			local mag = math.random(100, 250)
			local vx = mag*math.cos(rad)
			local vy = mag*math.sin(rad)
			local p = Particle:new(self.imgstr, make_rect(rx, ry, 4, 4), 8, 8, x, y, vx, vy, 0, 1.5)
			p.ay = 1000
			game:emplace("particles", p)
		end
	end
end

function NormalBrick.randomColorBrick(x, y)
	local n = math.random(0, 80)
	return NormalBrick:new(x, y, n%4+1, math.floor(n/4)+1)
end