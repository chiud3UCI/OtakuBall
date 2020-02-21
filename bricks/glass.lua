--Glass Bricks and Ice Bricks are pretty much identical
--only Freeze Detonators can produce Ice Bricks
GlassBrick = class("GlassBrick", Brick)

function GlassBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[6][5]
	self.health = 1
	self.brickType = "GlassBrick"
end

function GlassBrick:onBallHit(ball, norm)
	if self:handlePatches(ball, norm) then
		self:takeDamage(ball.damage, ball.strength)
	end
	ball:onBrickHit(self, norm, self:isDead())
end

IceBrick = class("IceBrick", GlassBrick)

--Alternatively you can call initialize(base) only
function IceBrick:initialize(x, y, base)
	if not y and not base then
		base = x
		GlassBrick.initialize(self, base.x, base.y)
		self:inheritMovement(base)
	else
		GlassBrick.initialize(self, x, y)
	end
	self.underlay = {imgstr = base.imgstr, rect = base.rect}
	self.brickType = "IceBrick"
end

function IceBrick:checkProjectileHit(proj)
	if proj.freeze then return false end
	return GlassBrick.checkProjectileHit(self, proj)
end

function IceBrick:draw()
	--If an IceBrick is the first brick to be drawn, the underlay not pop up for some reason
	legacySetColor(self.color.r, self.color.g, self.color.b, self.color.a)
	draw(self.underlay.imgstr, self.underlay.rect, self.x, self.y, 0, self.w, self.h)
	GlassBrick.draw(self)
end