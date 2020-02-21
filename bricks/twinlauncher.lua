TwinLauncherBrick = class("TwinLauncherBrick", Brick)

function TwinLauncherBrick:initialize(x, y, blue)
	Brick.initialize(self, x, y)
	self.isBlue = blue
	self.active = false
	self:updateAppearance()
	self.armor = 2
	self.hitSound = nil
	self.brickType = "TwinLauncherBrick"
end

function TwinLauncherBrick:updateAppearance()
	if not self.active then self:stopAnimation() end
	local col = self.isBlue and 13 or 14
	local off = self.active and 2 or 0
	self.rect = rects.brick[8][col+off]
	if self.active then
		self:playAnimation((self.isBlue and "Blue" or "Yellow").."TwinLauncherGlow", true)
	end
end

function TwinLauncherBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	if self:isDead() then return end
	self.active = not self.active
	if self.active then
		playSound("triggerdetoff")
	else
		playSound("triggerdeton")
	end
	self:updateAppearance()
	local check = false
	if self.active then
		for _, br in pairs(game.bricks) do
			if br.brickType == "TwinLauncherBrick" and br ~= self then
				check = true
				if br.active then
					self:launch(br)
					break
				end
			end
		end
		if not check then self:launch() end
	end
end

function TwinLauncherBrick:launch(other)
	local spd = 800
	if not other then
		local vx, vy = util.rotateVec(0, spd, math.random(1, 360))
		local p = Projectile:new(self.imgstr, self.rect, self.x, self.y, vx, vy, 0, "rectangle", self.w, self.h)
		p:setComponent("piercing")
		p.pierce = "weak"
		p.damage = 1000
		p.strength = 2
		game:emplace("projectiles", p)
		self:kill()
		return
	end
	local dx, dy = other.x - self.x, other.y - self.y
	local dist = math.sqrt(dx*dx + dy*dy)
	local vx, vy = spd*dx/dist, spd*dy/dist
	if self.isBlue == other.isBlue then
		vx, vy = -vx, -vy
	end
	local p1 = Projectile:new(self.imgstr, self.rect, self.x, self.y, vx, vy, 0, "rectangle", self.w, self.h)
	local p2 = Projectile:new(other.imgstr, other.rect, other.x, other.y, -vx, -vy, 0, "rectangle", self.w, self.h)
	for _, p in pairs({p1, p2}) do
		p:setComponent("piercing")
		p.pierce = "weak"
		p.damage = 1000
		p.strength = 2
		p.update = function(proj, dt)
			if proj.partner then
				if util.bboxOverlap({proj.shape:bbox()}, {proj.partner.shape:bbox()}) then 
					proj:kill()
					proj.partner:kill()
				end
			end
			Projectile.update(proj, dt)
		end
		p.destructor = function(proj)
			if proj.partner then proj.partner.partner = nil end
			Projectile.destructor(proj)
		end
	end
	p1.partner = p2
	p2.partner = p1
	game:emplace("projectiles", p1)
	game:emplace("projectiles", p2)
	self:kill()
	other:kill()
end