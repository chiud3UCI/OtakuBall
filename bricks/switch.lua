--Contains 4 types:
--	Trigger: causes flip bricks to flip upon hit; dissapears after activation
--  Switch: causes flip bricks to flip everytime it's hit; invincible(platinum-level armor)
--  Flip: can be either switched on or off; acts like a normal brick if on, but will let balls pass through if off
--  Strong Flip: just like a flip brick but is as strong as a gold brick

local lookup = {}
local names = {"normalOff", "normalOn", "strongOff", "strongOn", "switchOff", "switchOn", "trigger"}
local colors = {"red", "green", "blue", "purple", "orange"}
for i, name in ipairs(names) do
	lookup[name] = {}
	for j, color in ipairs(colors) do
		lookup[name][color] = rects.brick[6+j][i]
	end
end

local function flipBricks(switchColor)
	local switchCount = 0
	local targets = {}
	for k, br in pairs(game.bricks) do
		local t = br.brickType
		if br.switchColor == switchColor then
			if (t == "SwitchBrick" or t == "TriggerBrick") and not br:isDead() then
				switchCount = switchCount + 1
			end
			if (t == "FlipBrick" or t == "StrongFlipBrick") then
				table.insert(targets, br)
			end
		end
	end
	if switchCount == 0 then
		for k, br in pairs(targets) do
			if br.brickType == "FlipBrick" then
				br.state = true
			else
				br.state = false
			end
			br:updateAppearance()
		end
	else
		for k, br in pairs(targets) do
			br:flip()
		end
	end
end

------------------------------------------------------------------------------------------------
------SWITCH BRICK------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
SwitchBrick = class("SwitchBrick", Brick)

function SwitchBrick:initialize(x, y, switchColor)
	Brick.initialize(self, x, y)
	self.switchColor = switchColor
	self.state = false
	self:updateAppearance()
	self.health = 1000
	self.armor = 3

	self.brickType = "SwitchBrick"
	self.essential = false
end

function SwitchBrick:updateAppearance()
	local str = "switch"
	str = str..(self.state and "On" or "Off")
	self.rect = lookup[str][self.switchColor]
end

function SwitchBrick:flip()
	self.state = not self.state
	self:updateAppearance()
end

function SwitchBrick:onProjectileHit(proj, norm)
	if proj.energy then
		self.ignore = true
	end
	Brick.onProjectileHit(self, proj, norm)
end

function SwitchBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	if self.ignore then
		self.ignore = nil
	else
		self:flip()
		flipBricks(self.switchColor)
	end
end

function SwitchBrick:kill()
	Brick.kill(self)
	flipBricks(self.switchColor)
end

------------------------------------------------------------------------------------------------
------TRIGGER BRICK-----------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
TriggerBrick = class("TriggerBrick", Brick)

function TriggerBrick:initialize(x, y, switchColor)
	Brick.initialize(self, x, y)
	self.switchColor = switchColor
	self.rect = lookup["trigger"][self.switchColor]

	self.brickType = "TriggerBrick"
end

function TriggerBrick:onDeath()
	flipBricks(self.switchColor)
	Brick.onDeath(self)
end

------------------------------------------------------------------------------------------------
------FLIP BRICK--------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
FlipBrick = class("FlipBrick", Brick)

function FlipBrick:initialize(x, y, switchColor, state)
	Brick.initialize(self, x, y)
	self.switchColor = switchColor
	self.state = state
	self:updateAppearance()

	self.brickType = "FlipBrick"
end

function FlipBrick:onDeath()
	if not self.suppress then
		if self.x > window.lwallx and self.x < window.rwallx and powerupGenerator:canSpawn() then
			local id = powerupGenerator:getId()
			local p = PowerUp:new(self.x, self.y, id)
			game:emplace("powerups", p)
		end
	end
	Brick.onDeath(self)
end

function FlipBrick:updateAppearance()
	local str = "normal"
	str = str..(self.state and "On" or "Off")
	self.rect = lookup[str][self.switchColor]
	if self.state then self.armor = 1 else self.armor = 2 end
end

function FlipBrick:flip()
	self.state = not self.state
	self:updateAppearance()
end

function FlipBrick:checkBallHit(ball)
	if not self.state then return false end
	return Brick.checkBallHit(self, ball)
end

function FlipBrick:checkProjectileHit(proj)
	if not self.state then return false end
	return Brick.checkProjectileHit(self, proj)
end

------------------------------------------------------------------------------------------------
------STRONG FLIP BRICK-------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
StrongFlipBrick = class("StrongFlipBrick", Brick)

function StrongFlipBrick:initialize(x, y, switchColor, state)
	Brick.initialize(self, x, y)
	self.switchColor = switchColor
	self.state = state
	self:updateAppearance()
	local ani = self.switchColor
	self.hitAni = util.cap_first_letter(ani).."FlipShine"
	self.health = 100
	self.armor = 2

	self.brickType = "StrongFlipBrick"
end

function StrongFlipBrick:updateAppearance()
	self:stopAnimation()
	local str = "strong"
	str = str..(self.state and "On" or "Off")
	self.rect = lookup[str][self.switchColor]
end

function StrongFlipBrick:flip()
	self.state = not self.state
	self:updateAppearance()
end

function StrongFlipBrick:checkBallHit(ball)
	if not self.state then return false end
	return Brick.checkBallHit(self, ball)
end

function StrongFlipBrick:checkProjectileHit(proj)
	if not self.state then return false end
	return Brick.checkProjectileHit(self, proj)
end

function StrongFlipBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:playAnimation(self.hitAni)
end