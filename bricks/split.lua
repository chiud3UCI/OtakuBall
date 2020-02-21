SplitBrick = class("SplitBrick", Brick)

--The red split brick splits into 2 blue split bricks when hit
function SplitBrick:initialize(x, y, blue)
	Brick.initialize(self, x, y)
	self.blue = blue
	self.imgstr = "brick_split"
	if self.blue then
		self.rect = rects.brick[9][3]
		self.intangible = true
		self.color.a = 0
	else
		self.rect = rects.brick[5][2]
		self:playAnimation("RedSplitGlow", true)
		self.deathSound = "dividehit"
	end
	self.brickType = "SplitBrick"
end

--the blue split bricks need to move into place the moment its spawned
function SplitBrick:blueActivate()
	if not self.blue then return end

	self.intangible = false
	self.color.a = 255
	self:playAnimation("BlueSplitShine")

	local bucket = playstate:getBrickBucket(self)
	local box1 = {self.shape:bbox()}
	for br in pairs(bucket) do
		if br ~= self then
			local box2 = {br.shape:bbox()}
			if util.bboxOverlap(box1, box2) then
				self:kill()
				return
			end
		end
	end
	if self.x < window.lwallx or self.x > window.rwallx then
		self:kill()
	end

end

function SplitBrick:onDeath()
	if not self.suppress and not self.blue then
		local br1 = SplitBrick:new(self.x + 32, self.y, true)
		local br2 = SplitBrick:new(self.x - 32, self.y, true)
		local p = Environment:new("clear_pixel", nil, 96, 16, self.x, self.y)
		p:playAnimation("RedBlueSplit")
		p.update = function(pself, dt)
			if not pself.isAnimating then
				pself.dead = true
				br1:blueActivate()
				br2:blueActivate()
			end
			Environment.update(pself, dt)
		end
		game:emplace("bricks", br1)
		game:emplace("bricks", br2)
		game:emplace("environments", p) --the split particle effect is an environment so it can be drawn behind the bricks
	end
	Brick.onDeath(self)
end

function SplitBrick:update(dt)
	if self.blue then
		if not self.intangible and not self.isAnimating then
			self:playAnimation("BlueSplitGlow", true)
		end
	end
	Brick.update(self, dt)
end