FunkyBrick = class("FunkyBrick", Brick)

function FunkyBrick:initialize(x, y, health)
	Brick.initialize(self, x, y)
	self.health = health
	self.maxHealth = health
	self:updateAppearance()
	self.brickType = "FunkyBrick"
	self.essential = false
end

function FunkyBrick:updateAppearance()
	local i, j
	local ani
	if self.health <= 20 then
		i, j = 6, 1
		ani = "Blue"
		self.points = 100
	elseif self.health <= 30 then
		i, j = 6, 2
		ani = "Green"
		self.points = 120
	else
		i, j = 6, 3
		ani = "Red"
		self.points = 140
	end
	self.rect = rects.brick[i][j]
	self.hitAni = ani.."FunkyShine"
	self.regenAni = ani.."FunkyRegen"
end

function FunkyBrick:onDeath()
	if not self.suppress then
		local br = self:clone()
		br.health = br.maxHealth
		br:playAnimation(self.regenAni)
		local func = function()
			game:emplace("bricks", br)
		end
		game:emplace("callbacks", Callback:new(4, func))
	end

	Brick.onDeath(self)
end

function FunkyBrick:takeDamage(dmg, lvl)
	Brick.takeDamage(self, dmg, lvl)
	self:playAnimation(self.hitAni)
end