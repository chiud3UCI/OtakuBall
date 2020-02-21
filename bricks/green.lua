GreenBrick = class("GreenBrick", Brick)

function GreenBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.imgstr = "brick_menacer_green"
	self.rect = rects.brick[1][1]
	self.timer1 = 50
	self.timer2 = 10/7

	self.health = 80
	self.armor = 2
	self.points = 0 --should be set to original brick points

	self.brickType = "GreenBrick"
end

function GreenBrick:updateAppearance()
	if self.health >= 80 then
		self.rect = rects.brick[1][1]
	else
		self.rect = rects.brick[7][2]
		local j = 1
		for i = 70, 20, -10 do
			if self.health >= i then
				self.rect = rects.brick[j][2]
				break
			end
			j = j + 1
		end
	end
end

function GreenBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:updateAppearance()
	if self.armor == 2 then
		if self.health < 80 then
			self.armor = 1
		else
			self:playAnimation("GreenShine")
		end
	end
end

function GreenBrick:onMenacerHit(menacer, norm)
	Brick.onMenacerHit(self, menacer, norm)
	if menacer.menacerType == "green" then
		self.timer2 = 10/7
		self.health = 80
		self:stopAnimation()
		self:updateAppearance()
	end
end

function GreenBrick:update(dt)
	if self.armor == 2 then
		self.timer1 = self.timer1 - dt
		if self.timer1 <= 0 then
			self.armor = 1
		end
	else
		self.timer2 = self.timer2 - dt
		if self.timer2 <= 0 then
			self.timer2 = 10/7
			self.health = math.max(self.health - 10, 10)
			self:updateAppearance()
		end
	end
	Brick.update(self, dt)
end

function GreenBrick:draw()
	if self.underlay then
		drawBrick(self.underlay.imgstr, self.underlay.rect, self.x, self.y, self.angle, self.w, self.h, nil, nil, nil, nil, self.drawFloor)
	end
	Brick.draw(self)
end