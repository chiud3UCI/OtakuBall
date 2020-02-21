Projectile = class("Projectile", Sprite)

function Projectile:initialize(imgstr, rect, x, y, vx, vy, angle, shapeType, ...)
	local args = {...}
	Sprite.initialize(self, imgstr, rect, nil, nil, x, y, vx, vy, angle)
	self.shapeType = shapeType
	if shapeType == "rectangle" then
		self:setDim(args[1], args[2])
		local shape = shapes.newRectangleShape(0, 0, args[1], args[2])
		self:setShape(shape)
	elseif shapeType == "circle" then
		self:setDim(args[1] * 2, args[1] * 2)
		self.r = args[1]
		local shape = shapes.newCircleShape(0, 0, args[1])
		self:setShape(shape)
	end
	self.colFlag = {brick = true, paddle = false} -- any projectile that can hit bricks can also hit droppers
	self.enemy = false --enemy projectiles are projectiles that can hit the paddle and do bad things to it
	self.health = 10
	self.damage = 10
	self.strength = 1
	self.boundCheck = true
	self.component = pComponents.default
end

function Projectile:destructor()
	if self.gun then
		self.gun:notifyProjectileDeath()
	end
	Sprite.destructor(self)
end

function Projectile:setComponent(c, ...)
	if type(c) == "string" then
		self.component = pComponents[c]
	else
		self.component = c
	end
	if self.component.init then
		self.component.init(self, ...)
	end
end

function Projectile:kill()
	self.health = 0
end

function Projectile:isDead()
	return self.health <= 0
end

function Projectile:onDeath()
	if self.component.onDeath then 
		self.component.onDeath(self) 
	end
end

function Projectile:canHit(obj)
	return true
end

--norm only makes sense if the projectile is a bouncing ball
function Projectile:onBrickHit(brick, norm)
	if self.component.onBrickHit then 
		self.component.onBrickHit(self, brick, norm) 
	end 
end

function Projectile:onEnemyHit(enemy, norm)
	if self.component.onEnemyHit then 
		self.component.onEnemyHit(self, enemy, norm) 
	end 
end

function Projectile:onPaddleHit(paddle)
	if self.component.onPaddleHit then
		self.component.onPaddleHit(self, paddle)
	end
end

function Projectile:update(dt)
	if self.component.update then 
		self.component.update(self, dt) 
	end

	if self.timer then
		self.timer = self.timer - dt
		if self.timer <= 0 then self:kill() end
	end

	if self.boundCheck then
		local box = {self.shape:bbox()}
		if (box[1] < window.lwallx  and self.vx < 0) or
		   (box[3] > window.rwallx  and self.vx > 0) or
		   (box[2] < window.ceiling and self.vy < 0) or
		   (box[2] > window.h       and self.vy > 0) then
			self:kill()
		end
	end

	Sprite.update(self, dt)
end

--only use these if the projectile is a ball
function Projectile:validCollision(xn, yn)
	if xn == 0 and yn == 0 then return false end
	local theta = util.angleBetween(xn, yn, self.vx, self.vy)
	return theta > math.pi / 2
end

function Projectile:handleCollision(xn, yn)
	--normalize
	local dist = util.dist(xn, yn)
	xn = xn / dist
	yn = yn / dist
	--check to see if collision is valid
	if not self:validCollision(xn, yn) then return false end
	--vector reflection
	local dot = self.vx*xn + self.vy*yn
	self.vx = self.vx - (2 * dot * xn)
	self.vy = self.vy - (2 * dot * yn)

	return true
end

pComponents = {}

pComponents.default = 
{
	onBrickHit = function(self, brick, norm)
		self:kill()
	end,
	onEnemyHit = function(self, enemy, norm)
		self:kill()
	end
}

--this function is needed in other places too
--brick can't be frozen if its not dead
function freezeBrick(brick)
	if not brick:isDead() then return end
	local type = brick.brickType
	if type ~= "IceBrick" and type ~= "DetonatorBrick" then
		local points = brick.points
		brick.points = 0
		local ice = IceBrick:new(brick)
		--ice bricks may alter the onDeath() of certain bricks
		--for example, a funky brick will not respawn if frozen
		if brick.brickType == "FunkyBrick" then
			local newFunky = brick:clone()
			newFunky.snapper = nil
			newFunky.points = points
			ice.onDeath = function(iceSelf)
				newFunky:onDeath()
				IceBrick.onDeath(iceSelf)
			end
			brick.onDeath = Brick.onDeath
		elseif brick.brickType == "BoulderBrick" then
			brick.suppress = true
		elseif brick.brickType == "SplitBrick" then
			brick.suppress = true
		elseif brick.brickType == "NormalBrick" then
			ice.onDeath = function(iceSelf)
				if iceSelf.x > window.lwallx and iceSelf.x < window.rwallx and powerupGenerator:canSpawn() then
					local id = powerupGenerator:getId()
					local p = PowerUp:new(iceSelf.x, iceSelf.y, id)
					game:emplace("powerups", p)
				end
				IceBrick.onDeath(iceSelf)
			end
			brick.onDeath = Brick.onDeath
		end
		game:emplace("bricks", ice)
	end
end

pComponents.explosion = 
{
	update = function(self, dt)
		self:kill()
	end,
	onBrickHit = function(self, brick, norm)
		--explosions shouldnt trigger the hit sounds of bricks
		if brick.deathSound ~= "detonator" and brick.deathSound ~= "icedetonator" then 
			if brick.deathSound then
				stopSound(brick.deathSound, false, brick)
			end
			if brick.hitSound then
				stopSound(brick.hitSound, false, brick)
			end
		end
		if self.freeze then freezeBrick(brick) end
	end
}

pComponents.piercing = 
{
	onBrickHit = function(self, brick, norm)
		if self.pierce == "strong" then
			--do nothing
		else --self.pierce == "weak" then
			if not brick:isDead() then
				self:kill()
			end
		end
	end
}

pComponents.bouncy =
{
	init = function(self)
		self.boundCheck = false
		self.floorBounce = false
		self.colFlag.paddle = true
	end,
	onPaddleHit = function(self, paddle)
		self:handleCollision(0, -1)
	end,
	onBrickHit = function(self, brick, norm)
		if self.bounce == "strong" then
			self:translate(norm.x, norm.y)
			self:handleCollision(norm.x, norm.y)
		else
			--if bounce is weak?
			if self.strength >= brick.armor and self.damage > 0 then --if the projectile managed to do damage
				self:kill()
			else
				self:translate(norm.x, norm.y)
				self:handleCollision(norm.x, norm.y)
			end
		end
	end,
	onEnemyHit = function(self, enemy, norm)
		if self.bounce == "strong" then
			self:translate(norm.x, norm.y)
			self:handleCollision(norm.x, norm.y)
		else
			--if bounce is weak?
			if self.damage > 0 then --if the projectile managed to do damage
				self:kill()
			else
				self:translate(norm.x, norm.y)
				self:handleCollision(norm.x, norm.y)
			end
		end
	end,
	update = function(self, dt)
		local x, y = self:getPos()
		local r = self.shape._radius
		if x - r < window.lwallx  then self:handleCollision( 1,  0) end
		if x + r > window.rwallx  then self:handleCollision(-1,  0) end
		if y - r < window.ceiling then self:handleCollision( 0,  1) end
		if self.floorBounce then
			if y + r > window.h then self:handleCollision( 0, -1) end
		else
			if y - r > window.h then self:kill() end
		end
	end
}