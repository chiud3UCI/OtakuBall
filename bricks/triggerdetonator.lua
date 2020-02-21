TriggerDetonatorBrick = class("TriggerDetonatorBrick", DetonatorBrick)

function TriggerDetonatorBrick:initialize(x, y)
	DetonatorBrick.initialize(self, x, y, "normal")
	self:stopAnimation()
	self.rect = rects.brick[7][15]
	self.armor = 2
	self.active = false
	self.hitSound = nil

	self.brickType = "TriggerDetonatorBrick"
end

function TriggerDetonatorBrick:updateAppearance()
	if not self.active then self:stopAnimation() end
	self.rect = rects.brick[7][self.active and 16 or 15]
	if self.active then self:playAnimation("TriggerDetonatorGlow", true) end
end

function TriggerDetonatorBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	if not self:isDead() then
		self.active = not self.active
		if self.active then
			playSound("triggerdetoff")
		else
			playSound("triggerdeton")
		end
		self:updateAppearance()
		if self.active then
			local check = false
			for _, br in pairs(game.bricks) do
				if br.brickType == "TriggerDetonatorBrick" and br ~= self then
					check = true
					if br.active then
						self:kill()
						br:kill()
						playSound("detonator")
						break
					end
				end
			end
			if not check then
				self:kill()
				playSound("detonator")
			end
		end
	end
end