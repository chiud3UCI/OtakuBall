Menacer = class("Menacer", Sprite)

lookup = {ball = {}, dropper = {}}
local names = {"red", "green", "cyan", "bronze", "silver", "pewter"}
local ref = {{0, 0}, {0, 1}, {0, 2}, {1, 0}, {1, 1}, {1, 2}}
for i, v in ipairs(names) do
	lookup.ball[v] = rects.ball2[(i-1)%3+1][(i <= 3) and 7 or 8]
	local n = ref[i]
	lookup.dropper[v] = 
	{
		before = make_rect(n[2]*(23+1),        n[1]*24, 23, 24),
		after  = make_rect(n[2]*(23+1), 2*24 + n[1]*24, 23, 24)
	}
end

local nameLookup = util.generateLookup(names)
nameLookup.redgreen = true
function Menacer.isMenacer(name)
	return nameLookup[name]
end


function Menacer:initialize(x, y, vx, vy, menacerType)
	Sprite.initialize(self, "ball_spritesheet_new", lookup.ball[menacerType], 14, 14, x, y, vx, vy)
	self:setShape(shapes.newCircleShape(0, 0, 7))
	self.menacerType = menacerType

	self.stuckBounceTimer = 0
	self.storedAngle = 0

	self.gameType = "menacer"
end

function Menacer:update(dt)
	if self.disable then return end

	local r = self:getR()
	local x, y = self:getPos()

	self.stuckBounceTimer = self.stuckBounceTimer + dt

	if x - r < window.lwallx  then self:handleCollision( 1,  0) end
	if x + r > window.rwallx  then self:handleCollision(-1,  0) end
	if y - r < window.ceiling then self:handleCollision( 0,  1) end
	if y - r > window.h 	  then self.dead = true end

	Sprite.update(self, dt)
end

function Menacer:onBrickHit(brick, norm)
	if not brick.patch.invisible then
		local b = nil
		if brick.brickType == "NormalBrick" then
			b = "Normal"
		elseif brick.brickType == "MetalBrick" then
			b = brick.metalType.."Metal"
		elseif brick.brickType == "GreenBrick" then
			b = "GreenMenacer"
		end
		local m = self.menacerType
		if b and (m == "bronze" or m == "silver" or m == "green" or m == "red") then
			local ani = brick.currentAnistr
			--do not coat bricks if they are in the process of being coated
			if not (ani == "BronzeCoating" or ani == "SilverCoating" or ani == "GreenCoating") then
				if m == "bronze" and b ~= "BronzeMetal" then
					brick.suppress = true
					brick:kill()
					local br = MetalBrick:new(brick.x, brick.y, 20)
					br.underlay = {imgstr = brick.imgstr, rect = brick.rect}
					br:playAnimation("BronzeCoating")
					br:inheritMovement(brick)
					game:emplace("bricks", br)
					playSound("menacercoat")
				elseif m == "silver" and b ~= "SilverMetal" then
					brick.suppress = true
					brick:kill()
					local br = MetalBrick:new(brick.x, brick.y, 30)
					br.underlay = {imgstr = brick.imgstr, rect = brick.rect}
					br:playAnimation("SilverCoating")
					br:inheritMovement(brick)
					game:emplace("bricks", br)
					playSound("menacercoat")
				elseif m == "green" and b ~= "GreenMenacer" then
					local points = brick.points
					brick.points = 0
					brick.suppress = true
					brick:kill()
					local br = GreenBrick:new(brick.x, brick.y)
					br.points = points
					br.underlay = {imgstr = brick.imgstr, rect = brick.rect}
					br:playAnimation("GreenCoating")
					br:inheritMovement(brick)
					game:emplace("bricks", br)
					playSound("menacercoat")
				end
			end
			if m == "red" and b == "GreenMenacer" then
				brick:kill()
				playSound("blockbreak")
			end
		end
	end
	self:handleCollision(norm.x, norm.y)
end

function Menacer:onEnemyHit(enemy, norm)
	self:handleCollision(norm.x, norm.y)
	if self.menacerType ~= "red" then
		self:kill()
	end
end

function Menacer:handleCollision(xn, yn)
	--normalize
	local dist = util.dist(xn, yn)
	xn = xn / dist
	yn = yn / dist
	--check to see if collision is valid
	if not Ball.validCollision(self, xn, yn) then return false end --stealing a method from Ball
	--vector reflection
	local dot = self.vx*xn + self.vy*yn
	self.vx = self.vx - (2 * dot * xn)
	self.vy = self.vy - (2 * dot * yn)
	--another check that prevents the ball from bouncing too vertically or horizontally for a long duration
	local angle = math.abs(math.atan2(self.vy, self.vx)*180.0/math.pi)
    local vert = math.floor((angle + 45) / 90) % 2 == 1
    angle = math.min(angle, 180.0 - angle)
    angle = math.min(angle, 90.0 - angle)
    if angle > 10 or not util.deltaEqual(angle, self.storedAngle) then
    	self.stuckBounceTimer = 0
    end
    self.storedAngle = angle
    if self.stuckBounceTimer > 5 then
    	self.stuckBounceTimer = 0
    	local speed = self:getSpeed()
    	local k = vert and "vx" or "vy"
    	local d = (self[k] >= 0 and 1 or -1) * 0.3 * speed
    	self[k] = self[k] + d
    	self:scaleVelToSpeed(speed)
    end
	return true
end

function Menacer:validCollision(xn, yn)
	if xn == 0 and yn == 0 then return false end
	local theta = util.angleBetween(xn, yn, self.vx, self.vy)
	return theta > math.pi / 2
end

function Menacer:getR()
	return self.shape._radius
end

Dropper = class("Dropper", Enemy)

function Dropper:initialize(x, y, vx, vy, menacerType)
	Enemy.initialize(self, "dropper2", lookup.dropper[menacerType].before, 23*2, 24*2, x, y, vx, vy)
	self.speed = 50
	self.menacerType = menacerType
	self.hasDropped = false
	self.drawFloor = true
	self.suppress = false --disables point gain and death sound
	self.health = 15
	self.deathAni = "EnemyDeath1"
	self.deathSound = "menacerdeath"
	self.gameType = "dropper"
end

-- function Dropper:destructor()
-- 	if self.gate then
-- 		self.gate.state = "closing"
-- 		self.gate.dropper = nil
-- 	end
-- 	Enemy.destructor(self)
-- end

function Dropper:onDeath()
	if not self.suppress then
		if self.menacerType == "red" and not self.hasDropped then
			self:dropMenacer()
		end
	end
	Enemy.onDeath(self) --ignore Enemy onDeath
end

function Dropper:dropMenacer()
	self.hasDropped = true
	self.rect = lookup.dropper[self.menacerType].after
	local vx, vy = util.rotateVec(0, 350, math.random(-70, 70))
	local m = Menacer:new(self.x, self.y + 14, vx, vy, self.menacerType)
	game:emplace("menacers", m)
	self.menacer = m
end

function Dropper:update(dt)
	if self.disable then return end

	local x, y = self:getPos()
	local w, h = self:getDim()
	w, h = w/2, h/2
	if x - w < window.lwallx  then self.vx = math.abs(self.vx) end
	if x + w > window.rwallx  then self.vx = -math.abs(self.vx) end
	if y - h < window.ceiling then self.vy = math.abs(self.vy) end --what's the point?
	-- if y - h > window.h       then 
	-- 	self.suppress = true
	-- 	self:kill() 
	-- end

	local p = game.paddle
	if not self.hasDropped and y - h > window.ceiling and x > p.x - p.w/2 and x < p.x + p.w/2 then
		local check = true
		for _, br in pairs(game.bricks) do
			if util.circleRectOverlap(self.x, self.y + 14, 7, br.x, br.y, br.w, br.h) then
				check = false
				break
			end
		end
		if check then
			self:dropMenacer()
		end
	end
	Enemy.update(self, dt)
end

function Dropper:advanceState()
	local vx, vy = util.rotateVec(100, 0, math.random(10, 30))
	if math.random(1, 2) == 1 then vx = -vx end
	self:setVel(vx, vy)
	self.state = nil
end


function Dropper:onPaddleHit(paddle)
	self:kill()
end


