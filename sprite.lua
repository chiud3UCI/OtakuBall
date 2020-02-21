Sprite = class("Sprite")

--function Sprite:initialize(imgstr, _rect, _scale, _x, _y, _vx, _vy, _angle)
function Sprite:initialize(imgstr, rect, w, h, x, y, vx, vy, angle)
	self.imgstr       = imgstr or "clear_pixel"
	self.rect         = rect
	self.w            = w or 1
	self.h            = h or 1
	self.x            = x or 0 --position for the center of the sprite not the top-left corner
	self.y            = y or 0
	self.vx           = vx or 0
	self.vy           = vy or 0
	self.ax           = 0
	self.ay           = 0
	self.angle        = angle or 0 --in radians
	self.dead         = false
	self.destroyed    = false --means you should drop this object as soon as possible
	self.isAnimating  = false
	self.originRect   = nil
	self.originImgstr = nil
	self.aniTimer     = 0
	self.aniScale     = 1 --alters the speed of the animation
	self.aniIter      = nil
	self.gameType     = "default"

	if not self.w or not self.h then
		self.w, self.h = self:getImageDim()
	end

	self.color = {r = 255, g = 255, b = 255, a = 255}
end

function Sprite:destructor()
	self.destroyed = true
	self:removeShape()
end

function Sprite:onDeath()
end

function Sprite:isDead()
	return self.dead
end

function Sprite:kill()
	self.dead = true
end

function Sprite:setColor(r, g, b, a)
	self.color.r = r or self.color.r
	self.color.g = g or self.color.g
	self.color.b = b or self.color.b
	self.color.a = a or self.color.a
end

function Sprite:setShape(shape)
	self:removeShape()
	self.shape = shape
	shape.sprite = self
	self.shape:moveTo(self.x, self.y)
	self.shape:setRotation(self.angle)
end

function Sprite:removeShape()
	if self.shape then
		self.shape.sprite = nil
		self.shape = nil
	end
end

function Sprite:updateShape()
	if (self.shape) then
		self.shape:moveTo(self.x, self.y)
		self.shape:setRotation(self.angle)
	end
end

function Sprite:startAnimation(anistr, loop)
	if self.isAnimating then self:stopAnimation() end
	self.isAnimating = true
	self.currentAnistr = anistr
	self.aniLoop = loop
	self.originRect = self.rect
	self.originImgstr = self.imgstr
	self.imgstr = ani[anistr].imgstr
	self.aniIter = getAniIter(ani[anistr], loop)
	self.rect, self.aniTimer = self.aniIter()
end

function Sprite:playAnimation(anistr, loop)
	self:startAnimation(anistr, loop)
end

function Sprite:stopAnimation()
	if self.isAnimating then
		self.isAnimating = false
		self.currentAnistr = nil
		self.aniLoop = false
		self.rect = self.originRect
		self.imgstr = self.originImgstr
	end
end

function Sprite:getPos()
	return self.x, self.y
end

function Sprite:setPos(x, y)
	if x then self.x = x end
	if y then self.y = y end
	self:updateShape()
end

function Sprite:getVel()
	return self.vx, self.vy
end

function Sprite:setVel(vx, vy)
	if vx then self.vx = vx end
	if vy then self.vy = vy end
end

function Sprite:getSpeed()
	local vx, vy = self:getVel()
	return math.sqrt(vx * vx + vy * vy)
end

function Sprite:scaleVelToSpeed(s2)
	local s1 = self:getSpeed()
	if s1 == 0 then return end
	s2 = math.max(0, s2)
	--if s2 < 1 then return end
	self.vx = self.vx * s2 / s1
	self.vy = self.vy * s2 / s1
end


function Sprite:getDim()
	return self.w, self.h
end

--if a dimension is nil then the dimension wont change
function Sprite:setDim(w, h)
	self.w = w or self.w
	self.h = h or self.h
end

function Sprite:getImageDim()
	local w, h
	if self.rect then
		w, h = self.rect[3], self.rect[4]
	else
		w, h = assets[self.imgstr].img:getDimensions()
	end
	return w, h
end

function Sprite:translate(dx, dy)
	self.x = self.x + dx
	self.y = self.y + dy
	self:updateShape()
end

function Sprite:update(dt)
	if self.isAnimating then
		self.aniTimer = self.aniTimer - (dt * self.aniScale)
		if self.aniTimer <= 0 then
			self.rect, self.aniTimer = self.aniIter()
			if not self.rect then self:stopAnimation() end
		end
	end

	self.x = self.x + (self.vx * dt) + (0.5 * self.ax * dt * dt)
	self.y = self.y + (self.vy * dt) + (0.5 * self.ay * dt * dt)

	self.vx = self.vx + (self.ax * dt)
	self.vy = self.vy + (self.ay * dt)

	self:updateShape()
end

function Sprite:draw()
	legacySetColor(self.color.r, self.color.g, self.color.b, self.color.a)
	draw(self.imgstr, self.rect, self.x, self.y, self.angle, self.w, self.h, nil, nil, nil, nil, self.drawFloor)
end

function Sprite:drawAlt()
	legacySetColor(self.color.r, self.color.g, self.color.b, self.color.a)
	draw(self.imgstr, self.rect, self.x, self.y, self.angle, self.w, self.h, 0, 0, nil, nil, self.drawFloor)
end
