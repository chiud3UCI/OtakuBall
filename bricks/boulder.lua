BoulderBrick = class("BoulderBrick", Brick)

local boulderRect =
{
	make_rect(1, 5, 5, 5),
	make_rect(8, 4, 7, 7),
	make_rect(17, 3, 9, 9),
	make_rect(28, 2, 12, 12),
	make_rect(42, 1, 14, 14)
}

local boulderRadius = {5, 7, 9, 12, 14}

function BoulderBrick:initialize(x, y)
	Brick.initialize(self, x, y)
	self.rect = rects.brick[6][17]
	self.health = 20
	self.deathSound = "boulderbreak"

	self.brickType = "BoulderBrick"
end

function BoulderBrick:onDeath()
	if not self.suppress then
		for i = 1, 4 do
			local index = math.random(1, 5)
			local vx, vy = util.rotateVec(0, 100, math.random(1, 360))
			local p = Projectile:new("boulder", boulderRect[index], self.x, self.y, vx, vy, 0, "circle", boulderRadius[index])
			p.boulder = true
			p:setComponent("bouncy")
			p.colFlag = {paddle = true}
			p.ay = 1000
			p.active = true
			p.enemy = true
			p.onPaddleHit = function(proj, _paddle)
				if proj.active then
					proj.active = false
					proj.enemy = false
					_paddle.stunTimer = 2
					proj.vy = proj.vy * -0.3
				end
			end
			game:emplace("projectiles", p)
		end
	end
	Brick.onDeath(self)
end