ShooterBrick = class("ShooterBrick", FunkyBrick)

local lookup = {red = {rect = rects.brick[7][17], pcolor = {255, 0, 0}, dmg = 10, str = 1},
				green = {rect = rects.brick[7][18], pcolor = {0, 255, 0}, dmg = 100, str = 1},
				blue = {rect = rects.brick[7][19], pcolor = {0, 0, 255}, dmg = 1000, str = 2}}

function ShooterBrick:initialize(x, y, color)
	Brick.initialize(self, x, y)
	self.health = 1000
	self.maxHealth = 1000
	self.armor = 3
	self.shooterColor = color
	self.rect = lookup[color].rect
	self.projColor = lookup[color].pcolor
	self.projDmg = lookup[color].dmg
	self.projStr = lookup[color].str
	self.hitAni = util.cap_first_letter(color).."ShooterShine"
	self.regenAni = util.cap_first_letter(color).."ShooterRegen"

	self.brickType = "ShooterBrick"
	self.essential = false
end

function ShooterBrick:takeDamage(dmg, str)
	FunkyBrick.takeDamage(self, dmg, str)
	local rect = rects.laser["shooter_"..self.shooterColor]
	local w, h = rect.w*2, rect.h*2
	local l = Projectile:new("lasers", rect, self.x - 1, self.y - h/2, 0, -800, 0, "rectangle", w, h)
	l.damage = self.projDmg
	l.strength = self.projStr
	l.laser = true
	self.overlap[l] = 1
	game:emplace("projectiles", l)
end