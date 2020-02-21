SlotMachineBrick = class("SlotMachineBrick", Brick)
local SMB = SlotMachineBrick --alias

SMB.turnTime = 0.5
SMB.checkTime = 0.5

function initAllSlotMachines()
	SMB[true], SMB[false] = {bricks = {}, powerups = {}}, {bricks = {}, powerups = {}}
	-- OLD VERSION
	-- local powerups = util.copy(finished_powerups)
	-- for i = 1, 6 do --make sure there are at least 6 finished powerups
	-- 	local b = i % 2 == 0
	-- 	local n = math.random(1, #powerups)
	-- 	table.insert(SMB[b].powerups, powerups[n])
	-- 	table.remove(powerups, n)
	-- end
	SMB[true].powerups = util.copy(game.config.slot_blue)
	SMB[false].powerups = util.copy(game.config.slot_yellow)
	for _, br in pairs(game.bricks) do
		if br.brickType == "SlotMachineBrick" then
			table.insert(SMB[br.isBlue].bricks, br)
		end
	end
	for i = 1, 2 do
		local b = i == 1
		local n = 2
		for _, br in pairs(SMB[b].bricks) do
			local n2 = n --to capture the variable
			br.next = coroutine.wrap(function()
				local index = n2
				local p = SMB[b].powerups
				while true do
					index = (index+1)%3
					coroutine.yield(p[index+1])
				end
			end)
			n = (n + 1) % 3
		end
	end
end

function SlotMachineBrick:initialize(x, y, blue)
	Brick.initialize(self, x, y)
	self.imgstr = "brick_slotmachine"
	self.rect = rects.brick[1][blue and 1 or 2]
	self.anistr = (blue and "Blue" or "Yellow").."SlotMachine"
	self.top = Sprite:new("powerup_spritesheet", nil, 32, 16, self.x, self.y - 16)
	self.bottom = Sprite:new("powerup_spritesheet", nil, 32, 16, self.x, self.y)
	local function foo(s, id)
		s.rect = rects.powerup_ordered[id]
		s.powId = id
	end
	self.top.setPow = foo
	self.bottom.setPow = foo
	self.isBlue = blue
	self.isTurning = false
	self.isChecking = false
	self.turnTimer = 0
	self.checkTimer = 0
	self.next = nil
	self.armor = 3
	self.brickType = "SlotMachineBrick"
end

function SlotMachineBrick:destructor()
	util.remove_if(self[self.isBlue].bricks, function(v) return v == self end, util.nullfunc)
	Brick.destructor(self)
end

function SlotMachineBrick:activate()
	self.bottom:setPow(self.next())
	self.top:setPow(self.next())
	Brick.activate(self)
end

function SlotMachineBrick:getPowId()
	return self.bottom.powId
end

function SlotMachineBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	if not self.isTurning then
		self.isTurning = true
		self.isChecking = false
		self.turnTimer = self.turnTime
		self:playAnimation(self.anistr, true)
		playSound("slothit")
	end
end

function SlotMachineBrick:update(dt)
	if self.isTurning then
		self.top.y = self.y - (16 * self.turnTimer / self.turnTime)
		self.bottom.y = self.top.y + 16
		self.turnTimer = self.turnTimer - dt
		if self.turnTimer <= 0 then
			self.isTurning = false
			self.isChecking = true
			self.checkTimer = self.checkTime
			self.top.y = self.y - 16
			self.bottom.y = self.y
			self.bottom:setPow(self.top.powId)
			self.top:setPow(self.next())
			self:stopAnimation()
		end
	end
	if self.isChecking then
		self.checkTimer = self.checkTimer - dt
		if self.checkTimer <= 0 then
			self.isChecking = false
			local bricks = self[self.isBlue].bricks
			local id = self:getPowId()
			local check = true
			for _, br in pairs(bricks) do
				if id ~= br:getPowId() then
					check = false
				end
			end
			if check then
				for _, br in pairs(bricks) do
					br:kill()
				end
				game:emplace("powerups", PowerUp:new(self.x, self.y, id))
				playSound("slotmatch")
			end
		end
	end
	Brick.update(self, dt)
end

function SlotMachineBrick:draw()
	if self.isTurning then
		love.graphics.setScissor(self.x-16, self.y-8, 32, 16)
		self.top:draw()
		self.bottom:draw()
		love.graphics.setScissor()
	else
		self.bottom:draw()
	end
	Brick.draw(self)
end