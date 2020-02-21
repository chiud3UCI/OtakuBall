LauncherBrick = class("LauncherBrick", Brick)

function LauncherBrick:initialize(x, y, ccw, down) --counter-clockwise, facing down
	Brick.initialize(self, x, y)
	self.next = coroutine.wrap(function()
		local n = down and 8 or 0
		local dn = ccw and -1 or 1
		while true do
			coroutine.yield(rects.brick[9+math.floor(n/8)][8+(n%8)], n*360/16)
			n = (n+dn)%16
		end
	end)
	self.rect, self.launcherAngle = self.next()
	self.launcherTimer = 0.1

	self.brickType = "LauncherBrick"
end

function LauncherBrick:update(dt)
	self.launcherTimer = self.launcherTimer - dt
	if self.launcherTimer <= 0 then
		self.launcherTimer = 0.1
		self.rect, self.launcherAngle = self.next()
	end
	Brick.update(self, dt)
end

function LauncherBrick:onDeath()
	local vx, vy = util.rotateVec(0, -750, self.launcherAngle)
	local p = Projectile:new(self.imgstr, self.rect, self.x, self.y, vx, vy, 0, "rectangle", self.w, self.h)
	p:setComponent("piercing")
	p.pierce = "weak"
	p.damage = 1000
	p.strength = 2
	game:emplace("projectiles", p)
	Brick.onDeath(self)
end

