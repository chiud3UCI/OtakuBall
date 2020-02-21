PowerUp = class("PowerUp", Sprite)

powerup_fall_speed = 100
powerup_font_size = 12

local bad = {8, 12, 16, 30, 31, 37, 39, 40, 44, 48, 51, 53, 75, 76, 77, 85, 91, 94, 95, 98, 99, 106, 107, 117, 124, 125, 127, 130, 131, 134}
PowerUp.bad = util.generateLookup(bad)
PowerUp.good = {}
for i = 1, 135 do
	if not PowerUp.bad[i] then
		PowerUp.good[i] = true
	end
end

PowerUp.names =
	{"Acid", "AntiGravity", "Assist", "Attract", "Autopilot", "Ball Cannon", "Barrier", "Blackout", "Beam", "Blossom",
	 "Bomber", "Bulk", "Bypass", "Cannon", "Catch", "Change", "Chaos", "Column Bomber", "Combo", "Control",
	 "Disarm", "Disrupt", "Domino", "Drill Missile", "Drop", "EMP Ball", "Energy", "Erratic Missile", "Extend", "Fast",
	 "Freeze", "Fireball", "Forcefield", "Frenzy", "Gelato", "Generator Ball", "Ghost", "Giga", "Glue", "Gravity",
	 "Hold Once", "Hacker", "Halo", "HaHa", "Heaven", "Ice Ball", "Illusion", "Indigestion", "Intelligent Shadow", "Invert",
	 "Irritate", "Javelin", "Junk", "Jewel", "Joker", "Kamikaze", "Knocker", "Laceration", "Large Ball", "Laser",
	 "Laser Plus", "Laser Ball", "Lock", "Luck", "Magnet", "Mega", "Missile", "Mobility", "Multiple", "Mystery",
	 "Nano", "Nebula", "New Ball", "Node", "Normal Ball", "Normal Ship", "Nervous", "Oldie", "Open", "Orbit",
	 "Particle", "Pause", "Player", "Probe", "Poison", "Protect", "Quake", "Quasar", "Quadruple", "Rapidfire",
	 "Restrict", "Regenerate", "Re-Serve", "Reset", "Risky Mystery", "Rocket", "Row Bomber", "Shrink", "Shadow", "Shotgun",
	 "Sight Laser", "Slow", "Snapper", "Slug", "Terraform", "Time Warp", "Trail", "Tractor", "Transform", "Triple",
	 "Twin", "Two", "Ultraviolet", "Unification", "Undead", "Unlock", "Undestructible", "Vendetta", "Vector", "Venom",
	 "Volt", "Voodoo", "Warp", "Weak", "Weight", "Wet Storm", "Whisky", "X-Bomb", "X-Ray", "Yoyo",
	 "Yoga", "Y-Return", "Buzzer", "Zeal", "Zen Shove"}
PowerUp.namesInverse = {}
for k, v in pairs(PowerUp.names) do
	PowerUp.namesInverse[v] = k
end
local gen = util.generateLookup
PowerUp.dependencies = {
	brick = {
		["Chaos"]     = gen{"DetonatorBrick", "CometBrick", "TriggerDetonatorBrick", "ShoveDetonatorBrick"},
		["Disarm"]    = gen{"FunkyBrick", "SwitchBrick", "TriggerBrick", "FactoryBrick", "AlienBrick", "LaserEyeBrick", "BoulderBrick", "TikiBrick", "JumperBrick"},
		["Hacker"]    = gen{"ShooterBrick", "ShoveBrick", "FactoryBrick", "JumperBrick", "RainbowBrick", "SplitBrick", "SlotMachineBrick", "LauncherBrick", "TwinLauncherBrick", "CometBrick"},
		["Protect"]   = gen{"LaserEyeBrick", "BoulderBrick", "TikiBrick"},
		["Slug"]      = gen{"LaserEyeBrick", "BoulderBrick", "TikiBrick"},
		["Terraform"] = gen{"MetalBrick", "GoldBrick", "CopperBrick", "GoldSpeedBrick", "SpeedBrick", "AlienBrick", "GeneratorBrick", "TikiBrick", "LaserEyeBrick", "BoulderBrick", "JumperBrick", "RainbowBrick", "ParachuteBrick", "SequenceBrick", "SplitBrick"},
		["Transform"] = gen{"MetalBrick", "GoldBrick", "CopperBrick", "GoldSpeedBrick", "SpeedBrick", "AlienBrick", "GeneratorBrick", "TikiBrick", "LaserEyeBrick", "BoulderBrick", "JumperBrick", "RainbowBrick", "ParachuteBrick", "SequenceBrick", "SplitBrick"},
	},
	enemy = {
		["Laceration"] = true,
		["Mobility"] = true,
	}
}

function pow(name)
	PowerUp.funcTable[PowerUp.namesInverse[name]]()
end

function PowerUp:initialize(x, y, id)
	Sprite.initialize(self, "powerup_spritesheet", rects.powerup_ordered[id], 32, 16, x, y, 0, powerup_fall_speed)
	local shape = shapes.newRectangleShape(0, 0, 32, 16)
	self:setShape(shape)
	self.gameType = "powerup"
	self.id = id
	self.name = PowerUp.names[id]
	self.nameTimer = 1.5
	self.showName = true
	self.isBad = PowerUp.bad[id] == true

	self:playAnimation("P"..id, true)
end

function PowerUp:update(dt)
	self.nameTimer = self.nameTimer - dt
	if self.nameTimer <= 0 then
		self.showName = false
	end
	if self.y - self.h/2 > window.h then
		self.dead = true
	end
	Sprite.update(self, dt)
end

function PowerUp:activate()
	if not self.suppress then
		local name
		if self.isBad then
			playstate:incrementScore(2000)
			if playstate.scoreModifier == 0.5 then name = "1000"
			elseif playstate.scoreModifier == 2.0 then name = "4000"
			else name = "2000" end
		else
			playstate:incrementScore(200)
			if playstate.scoreModifier == 0.5 then name = "100"
			elseif playstate.scoreModifier == 2.0 then name = "400"
			else name = "200" end
		end
		if self.id == 83 then
			name = "1up"
		end
		local score = Particle:new("powerup_score_small", rects.score[name], 30, 12, self.x, self.y, 0, -40, 0, 1)
		game:emplace("particles", score)
	end
	local func = PowerUp.funcTable[self.id]
	if func then func(self) end --most functions dont utilize "self", but whatever
	self.dead = true
end

function PowerUp:draw()
	Sprite.draw(self)
	if not self.showName then return end
	local wrap = 85
	love.graphics.setFont(font["Pokemon"..powerup_font_size])
	love.graphics.printf(self.name, math.floor(self.x) - 20 - wrap, math.floor(self.y) - 8, wrap, "right")
end

powerupGenerator = {}

function powerupGenerator:loadDefault()
	self.default_overall_chance = 0
	self.default_weights = {}
	if love.filesystem.getInfo("default_powerup_chances.txt") then
		local i = 0
		local lines = readlines("default_powerup_chances.txt")
		for _, line in ipairs(lines) do
			if i == 0 then
				self.default_overall_chance = tonumber(line) / 100
			else
				self.default_weights[i] = tonumber(line)
			end
			i = i + 1
		end
	end
end

function powerupGenerator:initialize(overall_chance, weights)
	self.overall_chance = overall_chance or self.default_overall_chance
	weights = weights or self.default_weights
	self.weights = {}
	self.sum = 0
	for i = 1, 135 do
		self.weights[i] = weights[i]
		self.sum = self.sum + self.weights[i]
	end
	self.luck = nil
end

function powerupGenerator:canSpawn()
	return self.sum > 0 and (math.random() < self.overall_chance)
end

function powerupGenerator:getId()
	local n = self.sum * math.random()
	local id = nil
	for i = 1, 135 do
		id = i
		n = n - self.weights[i]
		if n <= 0 then
			break
		end
	end
	return id
end


PowerUp.funcTable = {}
local f = PowerUp.funcTable


--Paddle Gun Powerups

f[60] = function() --Laser
	local paddle = game.paddle
	local flag = false
	if paddle.gun then
		local gun = paddle.gun
		if gun.gunType == "PaddleLaser" or gun.gunType == "PaddleLaserPlus" then
			flag = true
			gun.maxBullets = gun.maxBullets + 2
		end
	end
	if not flag then
		paddle:clearPowerups()
		paddle:setGun(PaddleLaser:new())
		paddle.imgstr = "paddle_powerup2"
		paddle.rect = rects.paddle[32]
	end
	playSound("lasercollected")
end

f[61] = function() --Laser Plus
	local paddle = game.paddle
	local flag = false
	if paddle.gun then
		local gun = paddle.gun
		if gun.gunType == "PaddleLaser" or gun.gunType == "PaddleLaserPlus" then
			flag = true
			gun.gunType = "PaddleLaserPlus"
			paddle.rect = rects.paddle[28]
			gun.maxBullets = gun.maxBullets + 2
		end
	end
	if not flag then
		paddle:clearPowerups()
		paddle:setGun(PaddleLaser:new(true))
		paddle.imgstr = "paddle_powerup2"
		paddle.rect = rects.paddle[28]
	end
	playSound("lasercollected")
end

f[90] = function() --Rapidfire
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle:setGun(PaddleRapid:new())
	paddle.imgstr = "paddle_powerup"
	paddle.rect = rects.paddle[5]
end

f[100] = function() --Shotgun
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle:setGun(PaddleShotgun:new())
	paddle.imgstr = "paddle_powerup"
	paddle.rect = rects.paddle[27]
	playSound("shotguncollected")
end

f[6] = function() --Ball Cannon
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle:setGun(PaddleBallCannon:new())
	paddle.imgstr = "paddle_powerup2"
	paddle.rect = rects.paddle[27]
	playSound("cannoncollected")
end

f[24] = function() --Drill Missile
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle:setGun(PaddleDrillMissile:new())
	paddle.imgstr = "paddle_powerup"
	paddle.rect = rects.paddle[25]
	playSound("drillcollected")
end

f[67] = function() --Missile
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle:setGun(PaddleMissile:new(false))
	paddle.imgstr = "paddle_powerup"
	paddle.rect = rects.paddle[24]
	playSound("missilecollected")
end

f[28] = function() --Erratic Missile
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle:setGun(PaddleMissile:new(true))
	paddle.imgstr = "paddle_powerup"
	paddle.rect = rects.paddle[25]
	playSound("missilecollected")
end

f[52] = function() --Javelin
	--this powerup does not override other powerups
	local paddle = game.paddle
	paddle.javelin = true
	paddle.javelinTimer = 6
	paddle.javelinEmitterTimer = 0
	playSound("javelincharge")
	--temporary
	local m = Monitor:new("Javelin", paddle.javelinTimer)
	function m:update()
		local paddle = game.paddle
		if not paddle.javelin then
			return true
		end
		self.value = paddle.javelinTimer
	end
	monitorManager:add(m)
end

f[128] = function() --X-Bomb
	local paddle = game.paddle
	paddle:initXBomb()
	playSound("xbombcollected")
end

--Paddle Ect
f[76] = function() --Normal Ship
	game.paddle:normal()
	playSound("reset")
end

f[29] = function() --Extend
	game.paddle:incrementSize()
	playSound("extend")
end

f[91] = function() --Restrict
	game.paddle:decrementSize()
	playSound("restrict")
end

f[15] = function() --Catch
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.catch = true
	paddle.imgstr = "paddle_powerup2"
	paddle.rect = rects.paddle[11]
	playSound("catchactivated")
end

f[41] = function() --Hold Once
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.catch = "holdonce"
	paddle.imgstr = "paddle_powerup"
	paddle.rect = rects.paddle[31]
	playSound("catchactivated")
end

f[14] = function() --Cannon
	local paddle = game.paddle
	paddle:clearPowerups()
	playSound("cannoncollected")
	if #paddle.stuckBalls > 0 then
		local ball = paddle.stuckBalls[1][1]
		util.remove_if(paddle.stuckBalls, function(p)
			return p[1] == ball
		end)
		paddle:attachCannonBall(ball)
		paddle.imgstr = "paddle_powerup"
		paddle.rect = rects.paddle[32]
		playSound("cannonprep", true)
		return
	end
	paddle.flag.cannon = "loading"
	paddle.imgstr = "paddle_powerup"
	paddle.rect = rects.paddle[32]
end

f[39] = function() --Glue
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.catch = "glue"
	paddle.glueTimer = 5
	paddle.imgstr = "paddle_powerdown"
	paddle.rect = rects.paddle[17]
	local m = Monitor:new("Glue", 5)
	function m:update()
		local paddle = game.paddle
		if paddle.flag.catch ~= "glue" then
			return true
		end
		self.value = paddle.glueTimer
	end
	monitorManager:add(m)
	playSound("glue")
end

f[135] = function() --Zen Shove
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.zenShove = true
end

f[93] = function() --Re-Serve
	local paddle = game.paddle
	for _, ball in pairs(game.balls) do
		if ball:getR() == 14 then
			ball:normal()
		end
		paddle:attachBall(ball, "random")
	end
	playSound("reserve")
end

f[119] = function() --Vector
	local paddle = game.paddle
	if paddle.flag.vector then
		paddle.vectorTimer = paddle.vectorTimer + 10
	else
		paddle:clearPowerups()
		paddle.flag.vector = "rising"
		paddle.vectorTimer = 10
		paddle.imgstr = "paddle_powerup"
		paddle.rect = rects.paddle[1]
		local m = Monitor:new("Vector", 10)
		function m:update()
			if not game.paddle.flag.vector then return true end
			self.value = game.paddle.vectorTimer
			return false
		end
		monitorManager:add(m)
	end
	playSound("vector")
end

f[125] = function() --Weight
	local paddle = game.paddle
	paddle.speedLimit.x = 500
	paddle.imgstr = "paddle_powerdown"
	paddle.rect = rects.paddle[32]
	playSound("weight")
end

f[131] = function() --Yoga
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.yoga = true
	paddle.imgstr = "paddle_powerdown"
	paddle.rect = rects.paddle[23]
	playSound("yoyoga")
end

f[45] = function() --Heaven
	local paddle = game.paddle
	if paddle.heavenPaddle then
		paddle.heavenPaddle:setColor(nil, nil, nil, 255)
	else
		paddle:clearPowerups()
		paddle:initHeavenPaddle()
	end
	paddle.flag.heaven = true
	playSound("halo")
end

f[47] = function() --Illusion
	local paddle = game.paddle
	if not paddle.flag.illusion then
		paddle:clearPowerups()
		paddle.imgstr = "paddle_powerup"
		paddle.rect = rects.paddle[18]
		paddle.flag.illusion = true
		paddle:addIllusionPaddle()
	end
	paddle:addIllusionPaddle()
	playSound("illusion")
end

f[50] = function() --Invert
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.invert = true
	paddle.invertTimer = 0
	paddle.imgstr = "paddle_powerup2"
	paddle.rect = rects.paddle[5]
	playSound("invertpickup")

	local m = Monitor:new("Invert CD", paddle.invertTimer)
	function m:update()
		local paddle = game.paddle
		if not paddle.flag.invert then
			return true
		end
		self.value = paddle.invertTimer
	end
	monitorManager:add(m)
end

f[16] = function() --Change
	game.paddle.flag.change = true
	playSound("change")
end

f[9] = function() --Beam
	local paddle = game.paddle
	if paddle.flag.beam then
	else
		paddle:clearPowerups()
		paddle.imgstr = "paddle_powerup"
		paddle.rect = rects.paddle[21]
		paddle.flag.beam = true
		paddle.beamWidth = 32
		paddle.beamState = "off"
		paddle.beamTimeMax = 5
		paddle.beamTime = paddle.beamTimeMax
		paddle.beamRegen = 1
	end
	playSound("beamcollected")
end

f[20] = function() --Control
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.imgstr = "paddle_powerup2"
	paddle.rect = rects.paddle[18]
	paddle.flag.control = true
	paddle.controlCooldown = 0

	local m = Monitor:new("Control CD", paddle.controlCooldown)
	function m:update()
		local paddle = game.paddle
		if not paddle.flag.control then
			return true
		end
		self.value = paddle.controlCooldown
	end
	monitorManager:add(m)
end

f[96] = function() --Rocket
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.imgstr = "paddle_powerup"
	paddle.rect = rects.paddle[1]
	paddle.flag.rocket = "ready"
end

f[65] = function() --Magnet
	local paddle = game.paddle
	paddle.magnet = true
	playSound("attract")
end

f[5] = function() --Autopilot
	local paddle = game.paddle
	if paddle.autopilot then
		paddle.autopilotTimer = paddle.autopilotTimer + 10
	else
		paddle.autopilot = true
		paddle.autopilotTimer = 10
	end
	local m = Monitor:new("Autopilot", paddle.autopilotTimer)
	function m:update()
		local paddle = game.paddle
		if not paddle.autopilot then
			return true
		end
		self.value = paddle.autopilotTimer
	end
	monitorManager:add(m)
end

f[92] = function() --Regenerate
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.regenerate = true
	paddle.regenTimer = 5

	local m = Monitor:new("Regenerate", paddle.regenTimer)
	function m:update()
		local paddle = game.paddle
		if not paddle.flag.regenerate then
			return true
		end
		self.value = paddle.regenTimer
	end
	monitorManager:add(m)
	playSound("beamcollected")
end

f[99] = function() --Shadow
	local paddle = game.paddle
	if not paddle.flag.shadow then
		playSound("shadow")
	end
	paddle:clearPowerups()
	paddle.flag.shadow = true
	paddle.shadowTimer = 20
	paddle.imgstr = "paddle_shadow"
	paddle.color.a = 64
	paddle.rect = rects.paddle[1]

	local m = Monitor:new("Shadow", paddle.shadowTimer)
	function m:update()
		local paddle = game.paddle
		if not paddle.flag.shadow then
			return true
		end
		self.value = paddle.shadowTimer
	end
	-- playSound("shadow")
	monitorManager:add(m)
end

f[31] = function() --Freeze
	local paddle = game.paddle
	paddle.freeze = true
	paddle.freezeTimer = 2
	playSound("freeze")
end

f[77] = function() --Nervous
	local paddle = game.paddle
	paddle.flag.nervous = true
	paddle.nervousTimer = 0
	paddle.imgstr = "paddle_powerdown"
	paddle.rect = rects.paddle[5]

	local m = Monitor:new("Nervous", 20)
	function m:update()
		local paddle = game.paddle
		if not paddle.flag.nervous then
			return true
		end
		self.value = 20 - paddle.nervousTimer
	end
	monitorManager:add(m)
	playSound("nervous")
end

f[37] = function() --Ghost
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.ghost = true
	paddle.ghostTimer = 20
	paddle.ghostDecay = 500
	paddle.ghostGrowth = 1000
	paddle.ghostThreshold = 10
	paddle.imgstr = "paddle_powerdown"
	paddle.rect = rects.paddle[7]

	local m = Monitor:new("Ghost", 20)
	function m:update()
		local paddle = game.paddle
		if not paddle.flag.ghost then
			return true
		end
		self.value = paddle.ghostTimer
	end
	monitorManager:add(m)
	playSound("ghost")
end

f[80] = function() --Orbit
	local paddle = game.paddle
	if not paddle.flag.orbit then
		paddle.flag.orbit = true
		paddle.orbitBalls = {}
		paddle.orbitRadius = math.max(70, paddle.w * 0.75)
	end
	playSound("orbit")
end

f[82] = function() --Pause
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.pause = true
	paddle.pausecd = 0

	local m = Monitor:new("Pause CD", paddle.pausecd)
	function m:update()
		local paddle = game.paddle
		if not paddle.flag.pause then
			return true
		end
		self.value = paddle.pausecd
	end
	monitorManager:add(m)
	playSound("pausecollected")
end

--[[Hackable Bricks:
	Shooter
	Shove
	Factory
	Jumper
	Rainbow
	Split
	Slot Machine
	Launcher
	Twin Launcher
	Comet]]
f[42] = function() --Hacker
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.hacker = true
	paddle.imgstr = "paddle_powerup2"
	paddle.rect = rects.paddle[6]
	paddle.hackerOffset = 0
	paddle.hackerCandidates = util.generateLookup({
		"ShooterBrick",
		"ShoveBrick",
		"FactoryBrick",
		"JumperBrick",
		"RainbowBrick",
		"SplitBrick",
		"SlotMachineBrick",
		"LauncherBrick",
		"TwinLauncherBrick",
		"CometBrick"
	})
	playSound("hackercollected")
end

f[85] = function() --Poison
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.flag.poison = true
	paddle.color.a = 128
	paddle.imgstr = "paddle_powerdown"
	paddle.rect = rects.paddle[5]
	paddle.poisonTimer = 4

	local m = Monitor:new("Poison", 4)
	function m:update()
		local paddle = game.paddle
		if not paddle.flag.poison then
			return true
		end
		self.value = paddle.poisonTimer
	end
	playSound("poison")
	monitorManager:add(m)
end

f[86] = function() --Protect
	local paddle = game.paddle
	paddle.protect = 3
	paddle.protectColor = {r = 255, g = 255, b = 0, a = 255}
	playSound("protect")
end

f[109] = function() --Transform
	local valid = {
		"MetalBrick", 
		"GoldBrick",
		"CopperBrick",
		"GoldSpeedBrick",
		"SpeedBrick",
		"AlienBrick",
		"GeneratorBrick",
		"TikiBrick",
		"LaserEyeBrick",
		"BoulderBrick",
		"JumperBrick",
		"RainbowBrick",
		"ParachuteBrick",
		"SequenceBrick",
		"SplitBrick"
	}
	local paddle = game.paddle
	paddle:clearPowerups()
	paddle.imgstr = "paddle_powerup"
	paddle.rect = rects.paddle[25]
	paddle.flag.transform = true
	paddle.transformCandidates = util.generateLookup(valid)
	paddle.transformProgress = 0
end

f[111] = function() --Twin
	game.paddle:initTwin()
end

--Ball Splitting Powerups

f[22] = function() --Disrupt
	Ball.split(8)
	playSound("mediumsplit")
end

f[34] = function() --Frenzy
	Ball.split(24)
	playSound("largesplit")
end

f[69] = function() --Multiple
	Ball.split(3, true)
	playSound("smallsplit")
end

f[110] = function() --Triple
	Ball.split(3)
	playSound("smallsplit")
end

f[112] = function() --Two
	Ball.split(2, true)
	playSound("smallsplit")
end

--Ball upgrades
f[66] = function() --Mega
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.damage = 1000
		ball.strength = 2
		ball.pierce = true
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[8][6]
		ball.flag.mega = true
	end
	playSound("megaball")
end

f[38] = function() --Giga
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.damage = 10000
		ball.strength = 3
		ball.pierce = true
		ball.flag.giga = true
		ball.gigaFlashTimer = 0

		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[7][2]

		ball:initGigaProjectile()
	end
	playSound("gigaball")
end

f[59] = function() --Large Ball
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.damage = 34
		ball.strength = 2
		ball:setR(14)
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball_large
	end
	playSound("largeball")
end

f[62] = function() --Laser Ball
	local cd = {0.5, 0.25, 0.1, 0.05, 0.025, 0.01}
	for k, ball in pairs(game.balls) do
		if ball.flag.laser then
			local i = ball.flag.laser
			i = math.min(#cd, i + 1)
			ball.flag.laser = i
			ball.laserCooldown = cd[i]
			ball.laserTimer = 0.01
		else
			ball:normal()
			ball.flag.laser = 1
			ball.laserCooldown = cd[1]
			ball.laserTimer = 0.01
			ball.imgstr = "ball_spritesheet_new"
			ball.rect = rects.ball2[8][5]
		end
	end
	playSound("laserball")
end

f[74] = function() --Node
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[7][9]
		ball.flag.node = true
		ball.nodeTimer = 0
	end
end

f[4] = function() --Attract
	for k, ball in pairs(game.balls) do
		ball.flag.attract = true
	end
	playSound("attract")
end

f[56] = function() --Kamikaze
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[7][1]
		ball.flag.kamikaze = true
		ball.kamikazeMag = 25 --25
	end
	playSound("kamikaze")
end

f[132] = function() --Y-Return
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[7][5]
		ball.flag.yreturn = true
	end
	playSound("yreturn")
end

f[121] = function() --Volt
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[7][3]
		ball.flag.volt = true
	end
	playSound("voltcollected")
end

f[32] = function() --Fireball
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[7][1]
		ball.flag.fireball = true
		ball.damage = 1000
		ball.strength = 2
		ball.flag.fire = true
	end
	playSound("fireball")
end

f[46] = function() --Ice Ball
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[8][2]
		ball.flag.iceball = true
		ball.damage = 1000
		ball.strength = 2
	end
	playSound("iceballcollect")
end

f[103] = function() --Snapper
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[7][3]
		ball.damage = 0
		ball.flag.snapper = true
	end
	playSound("beamcollected")
end

f[36] = function() --Generator
	for k, ball in pairs(game.balls) do
		if ball.flag.generator then 
			ball:rechargeGeneratorSprites()
		else
			ball:normal()
			ball.flag.generator = true
			ball:initGeneratorSprites()
		end
	end
	playSound("generatorball")
end

f[27] = function() --Energy
	for k, ball in pairs(game.balls) do
		if ball.flag.energy then
			ball.energyLimit = 6
			ball:rechargeEnergyBalls()
		else
			ball:normal()
			ball.imgstr = "ball_spritesheet_new"
			ball.rect = rects.ball2[7][10]
			ball.flag.energy = true
			ball.energyLimit = 3
			ball:initEnergyBalls()
		end
	end
	playSound("energy")
end

f[19] = function() --Combo
	for k, ball in pairs(game.balls) do
		if (ball.flag.combo) then
			ball.flag.combo = ball.flag.combo + 10
		else
			ball.flag.combo = 10
			ball.comboSpeed = 1500
			ball.comboActive = false
		end
	end
	playSound("combopickup")
end

f[23] = function() --Domino
	for k, ball in pairs(game.balls) do
		if ball.flag.domino then
			if ball.dominoState == "charging" then
				ball.dominoState = "ready"
			end
		else
			ball:normal()
			ball.flag.domino = true
			ball.dominoState = "ready"
		end
	end
	playSound("domino")
end


f[10] = function() --Blossom
	for k, ball in pairs(game.balls) do
		if ball.flag.blossom then
			ball.blossomState = "ready"
		else
			ball:normal()
			ball.imgstr = "ball_spritesheet_new"
			ball.rect = rects.ball2[8][1]
			ball.flag.blossom = true
			ball:initBlossomSprites()
			ball.blossomState = "ready"
		end
	end
end

f[1] = function() --Acid
	for k, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[7][5]
		ball.flag.acid = true
		ball.damage = 1000
		ball.strength = 2
		ball.flag.acid = true
	end
	playSound("acidball")
end

f[11] = function() --Bomber
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[8][8]
		ball.flag.bomb = "circle"
		ball:initBomberFuse()
		playSound("bomberfuse", true, ball)
	end
	playSound("armbomberball")
end

f[18] = function() --Column Bomber
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[8][8]
		ball.flag.bomb = "column"
		ball:initBomberFuse()
		playSound("bomberfuse", true, ball)
	end
	playSound("armbomberball")
end

f[97] = function() --Row Bomber
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[8][8]
		ball.flag.bomb = "row"
		ball:initBomberFuse()
		playSound("bomberfuse", true, ball)
	end
	playSound("armbomberball")
end

f[57] = function() --Knocker
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[8][4]
		ball.flag.knocker = true
		ball.maxKnockerCount = 3
		ball.knockerCount = ball.maxKnockerCount
		ball.knockerDelay = 0.1
		ball.knockerTimer = ball.knockerDelay
		ball.knockerRX = 0
	end
	playSound("knocker")
end

--Ball downgrades
f[75] = function() --Normal Ball
	for _, ball in pairs(game.balls) do
		ball:normal()
	end
	playSound("reset")
end

f[51] = function() --Irritate
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[10][1]
		ball.flag.irritated = true
	end
	playSound("irritate")
end

f[98] = function() --Shrink
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball_mini
		ball:setR(3)
		ball.damage = 5
	end
	playSound("small")
end

f[40] = function() --Gravity
	for _, ball in pairs(game.balls) do
		ball.flag.gravity = true
		ball.flag.antigravity = false
		ball.gravityTimer = 10
	end
	local m = Monitor:new("Gravity", 10)
	function m:update()
		local v = 0
		local check = false
		for _, ball in pairs(game.balls) do
			if ball.flag.gravity then
				v = math.max(v, ball.gravityTimer)
				check = true
			end
		end
		if not check then return true end
		self.value = v
		return false
	end
	monitorManager:add(m)
	playSound("gravity")
end

f[2] = function() --AntiGravity
	for _, ball in pairs(game.balls) do
		ball.flag.antigravity = true
		ball.flag.gravity = false
		ball.gravityTimer = 10
	end
	local m = Monitor:new("AntiGravity", 10)
	function m:update()
		local v = 0
		local check = false
		for _, ball in pairs(game.balls) do
			if ball.flag.antigravity then
				v = math.max(v, ball.gravityTimer)
				check = true
			end
		end
		if not check then return true end
		self.value = v
		return false
	end
	monitorManager:add(m)
	playSound("antigravity")
end

f[26] = function() --EMP
	for _, ball in pairs(game.balls) do
		if ball.flag.emp then
			ball.empArmed = true
		else
			ball:normal()
			ball.flag.emp = true
			ball.empArmed = true
			ball.empFlash = true
			ball.empFlashDelay = 0.08
			ball.empFlashTimer = ball.empFlashDelay
			ball.imgstr = "ball_spritesheet_new"
			ball.rect = rects.ball2[7][2]
		end
	end
	playSound("armemp")
end

f[127] = function() --Whisky
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.flag.whisky = true
		ball.whiskyTimer = 0
		ball.whiskyEmitterTimer = 0
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[9][3]
	end
	playSound("whisky")
end

f[107] = function() --Trail
	for _, ball in pairs(game.balls) do
		if not ball.flag.trail then ball.flag.trail = 0 end
		ball.flag.trail = ball.flag.trail + 10
	end
	playSound("trail")
end

f[43] = function() --Halo
	for _, ball in pairs(game.balls) do
		if not ball.flag.halo then
			ball:normal()
			ball.flag.halo = true
			ball.haloState = "inactive"
			if ball.stuckToPaddle then
				ball.haloState = "active"
				ball.intangible = true
			end
		end
	end
	playSound("halo")
end

f[124] = function() --Weak
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.flag.weak = 0.4
		ball.weakTimer = 20
		if math.random() < ball.flag.weak then
			ball.damage = 0
		end
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[9][2]
	end

	local m = Monitor:new("Weak", 20)
	function m:update()
		local v = 0
		local check = false
		for _, ball in pairs(game.balls) do
			if ball.flag.weak then
				v = math.max(v, ball.weakTimer)
				check = true
			end
		end
		if not check then return true end
		self.value = v
		return false
	end
	monitorManager:add(m)
	playSound("weak")
end

f[122] = function() --Voodoo
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.flag.voodoo = true
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[7][2]
	end
	playSound("voodoo")
end

f[81] = function() --Particle
	for _, ball in pairs(game.balls) do
		if ball.flag.particle then
			ball:addParticleBall()
		else
			ball:normal()
			ball.flag.particle = true
			ball:addParticleBall()
			ball:addParticleBall()
		end
	end
	playSound("particle")
end

f[84] = function() --Probe
	local paddle = game.paddle
	if not paddle.probes then
		paddle.probes = {}
	end
	for _, ball in pairs(game.balls) do
		if not ball.flag.probe then
			ball:normal()
			ball.flag.probe = true
			ball:makeProbe()
		end
	end
end

--Ball Spawning
f[73] = function() --New Ball
	local b = Ball:new(0, 0, 0, Ball.defaultSpeed[difficulty])
	game.paddle:attachBall(b, "random")
	game:emplace("balls", b)
	playSound("reserve")
end

f[89] = function() --Quadruple
	local paddle = game.paddle
	local deg = {-15, -5, 5, 15}
	for i, v in ipairs(deg) do
		local vx, vy = util.rotateVec(0, -Ball.defaultSpeed[difficulty], v)
		local ball = Ball:new(paddle.x, paddle.y - 14, vx, vy)
		game:emplace("balls", ball)
	end
	playSound("smallsplit")
end

--Ball speed modifiers
f[30] = function() --Fast
	for _, ball in pairs(game.balls) do
		ball:scaleVelToSpeed(ball:getSpeed() + 150)
	end
	playSound("fast")
end

f[102] = function() --Slow
	for _, ball in pairs(game.balls) do
		ball:scaleVelToSpeed(ball:getSpeed() - 150)
	end
	playSound("slow")
end

f[134] = function() --Zeal
	for _, ball in pairs(game.balls) do
		ball:scaleVelToSpeed(ball:getSpeed() + 600)
	end
	playSound("fast")
end

f[130] = function() --YoYo
	for _, ball in pairs(game.balls) do
		ball:normal()
		ball.imgstr = "ball_spritesheet_new"
		ball.rect = rects.ball2[10][7]
		ball.flag.yoyo = true
	end
	playSound("yoyoga")
end

--Environment
f[79] = function() --Open
	for i = 1, 13 do
		local off = (i < 7) and -32 or 32
		if i ~= 7 then
			for j = 1, 32 do
				local t = playstate.brickGrid[j][i]
				for k, brick in pairs(t) do
					if brick.armor <= 2 and brick.alignedToGrid and not brick.isMoving then
						brick:moveTo(brick.x + off, brick.y, 0.2, "die")
						brick.drawPriority = -1
						game.sortflag = true
					end
				end
			end
		end
	end
	game:emplace("callbacks", Callback:new(0.2, function()
		for i = 1, 32 do
			for _, j in ipairs({1, 13}) do
				local t = playstate.brickGrid[i][j]
				for _, brick in pairs(t) do
					if brick.armor >= 2 then
						brick:kill()
					end
				end
			end
		end
	end))
	playSound("open")
end

f[118] = function() --Vendetta
	--scanning
	local targets = {}
	local max = 0
	for i = 1, 32 do
		targets[i] = 0
		for j = 1, 13 do
			local t = playstate.brickGrid[i][j]
			for _, brick in pairs(t) do
				if brick.armor <= 2 then
					targets[i] = targets[i] + 1
				end
			end
		end
		max = math.max(targets[i], max)
	end
	local candidates = {}
	for i, v in ipairs(targets) do
		if v == max then
			table.insert(candidates, i)
		end
	end
	local choice = candidates[math.random(1, #candidates)]
	--launching drill
	local drill = Projectile:new(
		"drill_vendetta", 
		make_rect(0, 0, 41, 16), 
		window.lwallx, 
		window.ceiling - 8 + (16 * choice), 
		300, 
		0, 
		0, 
		"rectangle", 
		82, 
		32
	)
	drill:setShape(shapes.newRectangleShape(0, 0, 80, 16))
	drill:setComponent("piercing")
	drill.pierce = "strong"
	drill.damage = 1000
	drill.strength = 2
	drill:playAnimation("DrillVendetta")
	game:emplace("projectiles", drill)
	playSound("drill")
end

f[35] = function() --Gelato
	--scanning
	local targets = {}
	local max = 0
	for i = 1, 32 do
		targets[i] = 0
		for j = 1, 13 do
			local t = playstate.brickGrid[i][j]
			for _, brick in pairs(t) do
				if brick.armor <= 2  and brick.brickType ~= "IceBrick" then
					targets[i] = targets[i] + 1
				end
			end
		end
		max = math.max(targets[i], max)
	end
	local candidates = {}
	for i, v in ipairs(targets) do
		if v == max then
			table.insert(candidates, i)
		end
	end
	local choice = candidates[math.random(1, #candidates)]
	local p = Projectile:new(
		"gelato", 
		nil,
		window.lwallx + 16,
		window.ceiling - 8 + (16*choice),
		1000,
		0,
		0,
		"rectangle",
		32,
		16
	)
	p:setComponent("piercing")
	p.pierce = "strong"
	p.freeze = true
	p.damage = 1000
	p.strength = 2
	p.onBrickHit = function(self, brick, norm)
		Projectile.onBrickHit(self, brick, norm)
		freezeBrick(brick)
	end
	game:emplace("projectiles", p)
	playSound("gelato")
end

f[71] = function() --Nano
	local func = function()
		local m = (math.random(1,2)==1) and 1 or -1
		local vec =
		{{util.rotateVec(m, 0, m*55)},
		 {util.rotateVec(m, 0, m*60)},
		 {util.rotateVec(m, 0, m*65)}}
		for _, v in ipairs(vec) do
			local n = Projectile:new(
				"ball_nova", 
				nil, 
				(m==1) and (window.lwallx+7) or (window.rwallx-7), 
				window.ceiling, 
				v[1]*800, 
				v[2]*800, 
				0, 
				"circle", 
				7
			)
			n:setComponent("bouncy")
			n.colFlag.brick = false
			n.onPaddleHit = function(proj, paddle)
				proj:kill()
				local ball = Ball:new(proj.x, proj.y, proj.vx, proj.vy)
				ball.damage = 1000
				ball.strength = 2
				ball.pierce = true
				ball.imgstr = "ball_spritesheet_new"
				ball.rect = rects.ball2[8][6]
				ball.bypass_ball_limit = true
				ball.flag.mega = true
				--ball.skip_sound = true
				game:emplace("balls", ball)
				--playSound("nanocatch")
			end
			game:emplace("projectiles", n)
		end
		playSound("nanolaunch")
	end
	game:emplace("callbacks", Callback:new(0.5, func))
	playSound("nanocatch")
end

f[88] = function() --Quasar
	local quasar = Environment:new("quasar", nil, 50, 50, window.w/2, window.h/2 - 16)
	quasar.r = 25
	quasar.vr = 250
	quasar.ar = -250
	function quasar:update(dt)
		self.r = self.r + (self.vr * dt) + (0.5 * self.ar * dt * dt)
		self.vr = self.vr + (self.ar * dt)
		if self.r < 1 then 
			self:kill()
			return
		end
		self.w, self.h = self.r*2, self.r*2
		self.angle = self.angle + 5 * dt

		for _, br in ipairs(game.bricks) do
			if util.circleRectOverlap(self.x, self.y, self.r, br.x, br.y, br.w, br.h) then
				if br.armor <= 2 then
					br.suppress = true
					br:kill()
					local p = Particle:new(br.imgstr, br.rect, br.w, br.h, br.x, br.y, 0, 0, 0, 100)
					p.orbit =
					{
						center = {x = self.x, y = self.y},
						angle = math.atan2(br.y - self.y, br.x - self.x),
						radius = util.dist(self.x, self.y, br.x, br.y)
					}
					p.orbit.vr = -0.005 * math.pow(p.orbit.radius, 2)
					p.fadeDelay = 0.9
					p.fadeRate = 450
					p.growthAccel = -25
					function p:update(dt)
						self.x = self.orbit.center.x + self.orbit.radius * math.cos(self.orbit.angle)
						self.y = self.orbit.center.y + self.orbit.radius * math.sin(self.orbit.angle)
						self.orbit.angle = self.orbit.angle + 2 * dt
						self.orbit.radius = self.orbit.radius + dt * p.orbit.vr
						if self.orbit.radius < 0 then self:kill() end
						Particle.update(self, dt)
					end
					game:emplace("particles", p)
				end
			end
		end
	end

	game:emplace("environments", quasar)
	playSound("quasar")
end

f[8] = function() --Blackout
	for _, e in pairs(game.environments) do
		if e.blackout then return end
	end
	local maxTime = 10
	local fadeTime = 1
	local b = Environment:new()
	b.blackout = true
	b.alpha = 0
	b.timer = maxTime
	b.update = function(self, dt)
		if self.timer > maxTime - fadeTime then
			self.alpha = (maxTime - self.timer) / fadeTime * 255
		elseif self.timer > fadeTime then
			self.alpha = 255
		else
			self.alpha = self.timer / fadeTime * 255
		end
		self.timer = self.timer - dt
		if self.timer <= 0 then self.dead = true end
	end
	b.draw = function(self)
		legacySetColor(0, 0, 0, self.alpha)
		love.graphics.rectangle("fill", window.lwallx, window.ceiling, window.rwallx - window.lwallx, window.h - window.ceiling)
	end
	game:emplace("environments", b)
	local m = Monitor:new("Blackout", maxTime)
	function m:update()
		if b.dead then return true end
		self.value = b.timer
	end
	monitorManager:add(m)
	playSound("blackout")
end

f[7] = function() --Barrier
	playSound("barrier")
	for _, e in pairs(game.environments) do
		if e.barrier then
			e.timer = e.timer + 10
			return
		end
	end
	local b = Environment:new("white_pixel", nil, window.rwallx-window.lwallx, 16, window.w/2, window.h - 24)
	b.barrier = true
	b:setColor(0, 128, 0)
	b.timer = 10
	b.update = function(self, dt)
		for _, ball in pairs(game.balls) do
			if util.circleRectOverlap(ball.x, ball.y, ball:getR(), self.x, self.y, self.w, self.h) and ball.vy > 0 then
				ball:handleCollision(0, -1)
			end
		end
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.dead = true
		end
	end
	b.draw = function(self)
		Environment.draw(self)
		legacySetColor(255, 255, 255, 255)
		for i = 1, 13 do
			draw("brick_barrier", nil, window.lwallx + i * 32 - 16, self.y, 0, 32, 16)
		end
	end
	game:emplace("environments", b)
	local m = Monitor:new("Barrier", 10)
	function m:update()
		if b.dead then return true end
		self.value = b.timer
	end
	monitorManager:add(m)
end

f[44] = function(self) --HaHa
	local candidates = {}
	for i = 1, 32-8 do
		for j = 1, 13 do
			if #playstate.brickGrid[i][j] == 0 then
				table.insert(candidates, {i, j})
			end
		end
	end
	for i = 0, 14 do
		if #candidates == 0 then break end
		local n = math.random(1, #candidates)
		local ii, jj = unpack(candidates[n])
		table.remove(candidates, n)
		local x, y = getGridPosInverse(ii, jj)
		local br = NormalBrick.randomColorBrick(self.x, self.y)
		br:moveTo2(x, y, 500, "kill")
		br.intangible = true
		br.intangibleWhileMoving = true
		game:emplace("callbacks", Callback:new(i * 0.05, function() game:emplace("bricks", br) end))
		local fb = ForbiddenBrick:new(x, y)
		fb.deathTimer = i * 0.05 + util.dist(self.x, self.y, x, y) / 500
		game:emplace("bricks", fb)
	end
	playSound("haha")
end

f[83] = function() --Player
	playstate.lives = playstate.lives + 1
	playSound("oneup")
end

f[53] = function() --Junk
	local m = playstate.scoreModifier
	playstate.scoreModifier = math.max(0.5, m * 0.5)
	playSound("junk")
end

f[54] = function() --Jewel
	local m = playstate.scoreModifier
	playstate.scoreModifier = math.min(2.0, m * 2.0)
	playSound("jewel")
end

f[55] = function() --Joker
	for _, p in pairs(game.powerups) do
		if p.isBad or p.id == 55 then
			p.dead = true
		else
			p:activate()
		end
	end
	playSound("joker")
end

f[70] = function(self) --Mystery
	local exclude = util.generateLookup({55, 70, 95})

	--old way with uniform chances
	-- local choices = {}
	-- for i = 1, 135 do
	-- 	if PowerUp.good[i] and not exclude[i] then
	-- 		table.insert(choices, i)
	-- 	end
	-- end
	-- local id = choices[math.random(#choices)]
	-- f[id](self)

	--new way that respects the weights
	local weights = powerupGenerator.weights
	local gen = {sum = 0, weights = {}}
	for i = 1, 135 do
		if PowerUp.good[i] and not exclude[i] then
			gen.sum = gen.sum + weights[i]
			gen.weights[i] = weights[i]
		else
			gen.weights[i] = 0
		end
	end
	if gen.sum > 0 then
		local id = powerupGenerator.getId(gen)
		f[id](self)
	end
end

f[95] = function(self) --Risky Mystery

	
	local exclude = util.generateLookup({55, 70, 95})
	--old way with uniform chances
	-- local choices = {}
	-- for i = 1, 135 do
	-- 	if not exclude[i] then
	-- 		table.insert(choices, i)
	-- 	end
	-- end
	-- local id = choices[math.random(#choices)]
	-- f[id](self)

	--new way that respects the weights
	local weights = powerupGenerator.weights
	local gen = {sum = 0, weights = {}}
	for i = 1, 135 do
		if not exclude[i] then
			gen.sum = gen.sum + weights[i]
			gen.weights[i] = weights[i]
		else
			gen.weights[i] = 0
		end
	end
	if gen.sum > 0 then
		local id = powerupGenerator.getId(gen)
		f[id](self)
	end
end

f[64] = function() --Luck
	if powerupGenerator.luck then return end
	powerupGenerator.luck = true
	local weights = powerupGenerator.weights
	local sum = 0
	for k, v in pairs(weights) do
		if PowerUp.good[k] then
			weights[k] = 1
			sum = sum + 1
		else
			weights[k] = 0
		end
	end
	powerupGenerator.sum = sum
	powerupGenerator.overall_chance = powerupGenerator.overall_chance * 1.6
	playSound("luck")
end

f[114] = function() --Unification
	for _, br in pairs(game.bricks) do
		if br.brickType == "NormalBrick" and br.imgstr ~= "brick_unification" and not br.bulk then
			local index = 1
			local ri, rj = br.ri, br.rj
			if br.imgstr == "brick_spritesheet" then
				if rj < 20 then
					index = rj
				else
					if rj == 20 then
						index = 20 + ri
					elseif ri == 1 then
						index = 24
					else
						index = 20
					end
				end
			elseif br.imgstr == "brick_grey" or br.imgstr == "brick_bright" then
				index = rj
			elseif br.imgstr == "brick_jetblack" then
				index = 24
			elseif br.imgstr == "brick_white" then
				index = 20
			end
			br.imgstr = "brick_unification"
			br.rect = rects.brick[1][index]
			br.points = 250
		end
	end
	playSound("unification")
end

f[12] = function() --Bulk
	for _, br in pairs(game.bricks) do
		if br.brickType == "NormalBrick" or br.brickType == "MetalBrick" then
			br:bulkUp()
		end
	end
	playSound("bulk")
end

f[21] = function() --Disarm
	for _, br in pairs(game.bricks) do
		local i, j, imgstr = nil, nil, "brick_spritesheet"
		if     br.brickType == "FunkyBrick" then
			br.suppress = true
			if     br.maxHealth == 20 then i, j = 1, 12
			elseif br.maxHealth == 30 then i, j = 1, 10
			elseif br.maxHealth == 40 then i, j = 1, 1
			end
		elseif br.brickType == "SwitchBrick" then
			br:kill()
		elseif br.brickType == "TriggerBrick" then
			if 	   br.switchColor == "red"    then i, j = 2, 1
			elseif br.switchColor == "green"  then i, j = 2, 9
			elseif br.switchColor == "blue"   then i, j = 2, 15
			elseif br.switchColor == "purple" then i, j = 2, 16
			elseif br.switchColor == "orange" then i, j = 2, 3
			end
		-- elseif br.brickType == "FlipBrick" then
		-- elseif br.brickType == "StrongFlipBrick" then
		elseif br.brickType == "FactoryBrick" then
			i, j = 1, 15
			imgstr = "brick_grey"
		elseif br.brickType == "AlienBrick" then
			local choices = {{2, 7}, {2, 9}, {2, 14}, {1, 20}}
			i, j = unpack(choices[math.random(1, 4)])
		elseif br.brickType == "LaserEyeBrick" then
			i, j = 3, 20
		elseif br.brickType == "BoulderBrick" then
			br.suppress = true
			i, j = 1, 5
		elseif br.brickType == "TikiBrick" then
			i, j = 1, 5
			imgstr = "brick_grey"
		elseif br.brickType == "JumperBrick" then
			i, j = 2, 6
		end
		if i and j then
			local normal = NormalBrick:new(br.x, br.y, i, j, imgstr)
			normal:inheritMovement(br)
			game:emplace("bricks", normal)
			br:kill()
		end
	end
	playSound("disarm")
end

f[94] = function() --Reset
	--calls both normal paddle and normal ball
	f[75]()
	f[76]()
end

f[48] = function() --Indigestion
	for _, br in pairs(game.bricks) do
		if br.brickType == "NormalBrick" and br.alignedToGrid and not br.isMoving then
			local targets = {}
			local i0, j0 = getGridPos(br.x, br.y)
			for a = -1, 1 do
				for b = -1, 1 do
					local i, j = i0 + a, j0 + b
					if (a == 0 or b == 0) and boundCheck(i, j) and i <= 32 - 8 then
						if #playstate.brickGrid[i][j] == 0 then
							table.insert(targets, {i, j})
						end
					end
				end
			end
			for _, v in pairs(targets) do
				local i, j = v[1], v[2]
				local x, y = getGridPosInverse(i, j)
				-- local br2 = NormalBrick:new(br.x, br.y, br.ri, br.rj, br.imgstr)
				local br2 = br:clone()
				br2:moveTo(x, y, 0.2, "die")
				game:emplace("bricks", br2)
				local n = NullBrick:new(x, y)
				table.insert(playstate.brickGrid[i][j], n)
			end
		end
	end
	playSound("indigestion")
end

f[120] = function() --Venom
	local function check1(br)
		local t = br.brickType
		return t == "DetonatorBrick" or t == "CometBrick" 
	end
	local function check2(bricks)
		for _, br in pairs(bricks) do
			if check1(br) then return false end
			if br.armor > 2 then return false end
		end
		return true
	end
	for _, br in pairs(game.bricks) do
		if check1(br) and br.alignedToGrid and not br.isMoving then
			local targets = {}
			local i0, j0 = getGridPos(br.x, br.y)
			for a = -1, 1 do
				for b = -1, 1 do
					local i, j = i0 + a, j0 + b
					if (a == 0 or b == 0) and boundCheck(i, j) and i <= 32 - 8 then
						if check2(playstate.brickGrid[i][j]) then
							table.insert(targets, {i, j})
						end
					end
				end
			end
			for _, v in pairs(targets) do
				local i, j = v[1], v[2]
				local x, y = getGridPosInverse(i, j)
				local br2 = br:clone()
				br2:moveTo(x, y, 0.2, "kill")
				game:emplace("bricks", br2)
				local n = NullBrick:new(x, y)
				table.insert(playstate.brickGrid[i][j], n)
			end
		end
	end
	playSound("beamcollected")
end

f[17] = function() --Chaos
	local brickTypes = {"DetonatorBrick", "CometBrick", "TriggerDetonatorBrick", "ShoveDetonatorBrick"}
	local check = util.generateLookup(brickTypes)
	for _, br in pairs(game.bricks) do
		if check[br.brickType] then
			-- br:kill()
			br:takeDamage(1000, 1) --need to do this in order to trigger sounds
		end
	end
	playSound("beamcollected")
end

f[106] = function() --Time Warp
	playstate.timeWarp = 0

	local m = Monitor:new("Time Warp", 15)
	function m:update()
		if not playstate.timeWarp then return true end
		self.value = 15 - playstate.timeWarp
	end
	monitorManager:add(m)
end

f[101] = function() --Sight Laser
	for _, ball in pairs(game.balls) do
		ball.flag.sightlaser = true
	end
	playSound("sightlaser")
end

f[25] = function() --Drop
	local candidates = {}
	for _, br in pairs(game.bricks) do
		if br.brickType == "NormalBrick" and not br.suppress then
			table.insert(candidates, br)
		end
	end

	local count = math.random(3, 6)
	while #candidates > 0 and count > 0 do
		local index = math.random(1, #candidates)
		local br = candidates[index]
		local id = powerupGenerator:getId()
		local p = PowerUp:new(br.x, br.y, id)
		game:emplace("powerups", p)
		br.suppress = true
		count = count - 1
		table.remove(candidates, index)
	end
	playSound("drop")
end

f[108] = function() --Tractor
	local tractor = Environment:new()
	tractor.hits = 3
	tractor.y = window.h - 16
	tractor.update = function(self, dt)
		for _, ball in pairs(game.balls) do
			if ball.vy > 0 and ball.y > self.y then
				ball.vy = -ball.vy
				self.hits = self.hits - 1
				if self.hits <= 0 then
					self.dead = true
				end
			end
		end
	end
	tractor.draw = function(self)
		drawLightning(window.lwallx, self.y, window.rwallx, self.y, "tractor")
	end
	game:emplace("environments", tractor)
	playSound("tractor")
end

f[126] = function() --Wet Storm
	local function rain_drop()
		local p = Projectile:new("wet_storm", nil, math.random(window.lwallx + 3, window.rwallx - 3), -21, 0, 400, 0, "rectangle", 10, 42)
		p.damage = 1000
		p.strength = 1
		p.onBrickHit = function(self, brick, norm)
			if brick:isDead() then
				self:kill()
			end
		end
		game:emplace("projectiles", p)
		playSound("raindrop")
	end
	for i = 1, 20 do
		game:emplace("callbacks", Callback:new((i-1) * 0.5, function()
			rain_drop()
		end))
	end
end

f[33] = function() --Forcefield
	for _, env in pairs(game.environments) do
		if env.envType == "forcefield" then return end
	end
	local ff = Environment:new(nil, nil, window.rwallx - window.lwallx, 16, window.w/2, window.h - 104)
	ff.envType = "forcefield"
	ff.update = function(self)
		for _, ball in pairs(game.balls) do
			if not ball.forcefield and ball.vy > 0 and util.circleRectOverlap(ball.x, ball.y, ball:getR(), self.x, self.y, self.w, self.h) then
				--the moment the ball collides with something
				--revert the ball back to its original velocity
				ball.forcefield = {ball.vx, ball.vy}
				ball.vy = util.dist(ball.vx, ball.vy) / 5
				ball.vy = math.max(Ball.speedLimit.low, ball.vy)
				ball.vx = 0
			end
		end
	end
	ff.draw = function(self)
		legacySetColor(230, 230, 138, 128)
		love.graphics.rectangle("fill", self.x - self.w/2, self.y - self.h/2, self.w, self.h)
	end
	game:emplace("environments", ff)
end

f[78] = function() --Oldie
	for _, e in pairs(game.environments) do
		if e.oldie then return end
	end
	for _, br in pairs(game.bricks) do
		br.oldieMark = nil
		if br.brickType == "NormalBrick" then
			if math.random() < 0.9 then
				br.oldieMark = true
			end
		elseif br.brickType == "MetalBrick" then
			br.oldieMark = true
		end
	end

	local oldie = Environment:new(nil, nil, window.rwallx - window.lwallx, 32, window.w/2, window.h + 16)
	oldie.update = function(self, dt)
		self.y = self.y - dt * 1000
		if self.y + self.h/2 < window.ceiling then
			self.dead = true
		end
		for _, br in pairs(game.bricks) do
			if br.oldieMark and br.y > self.y then
				br.oldieMark = nil
				if br.brickType == "NormalBrick" then
					br:kill()
				elseif br.brickType == "MetalBrick" then
					br:weaken()
				end
			end
		end
	end
	oldie.draw = function(self)
		legacySetColor(255, 255, 255, 255)
		love.graphics.setScissor(window.lwallx, window.ceiling, window.rwallx - window.lwallx, window.h - window.ceiling)
		love.graphics.rectangle("fill", self.x - self.w/2, self.y - self.h/2, self.w, self.h)
		love.graphics.setScissor()
	end
	oldie.oldie = true
	game:emplace("environments", oldie)
	playSound("oldie")
end

f[72] = function() --Nebula
	for _, e in pairs(game.environments) do
		if e.nebula then return end
	end

	local nebula = Environment:new()
	nebula.nebula = true
	nebula.x, nebula.y = window.w/2, window.ceiling + (window.h - window.ceiling)/2 + 10
	nebula.radius = util.dist(window.rwallx - window.lwallx, window.h - window.ceiling)/2
	nebula.circles = Queue:new({nebula.radius})
	nebula.circleTimer = 0.4
	nebula.timer = 10
	nebula.sound = true
	nebula.update = function(self, dt)
		self.timer = self.timer - dt
		if self.timer <= 0 then
			if self.sound then
				stopSound("control", true, self)
				self.sound = false
			end
			if self.circles:empty() then
				self.dead = true
			end
		else
			for _, ball in pairs(game.balls) do
				local dist = util.dist(self.x, self.y, ball.x, ball.y)
				local nx, ny = (self.x - ball.x) / dist, (self.y - ball.y) / dist
				local mag = math.pow(ball:getSpeed(), 2) / 100
				ball.fx = nx * mag
				ball.fy = ny * mag
				local deg = math.deg(util.angleBetween(ball.vx, ball.vy, self.x - ball.x, self.y - ball.y))
				if dist > 10 and deg > 90 then
					local dot = ball.vx * -(self.y - ball.y) + ball.vy * (self.x - ball.x) --not really the dot product
					local sign = dot < 0 and -1 or 1
					local mag = (deg - 90) * math.pow(ball:getSpeed(), 2) / 10000
					local nx, ny = util.normalize(util.rotateVec(self.x - ball.x, self.y - ball.y, sign * 90))
					ball.fx = ball.fx + nx * mag
					ball.fy = ball.fy + ny * mag
				end
			end
			self.circleTimer = self.circleTimer - dt
			if self.circleTimer <= 0 then
				self.circleTimer = 0.4
				self.circles:pushLeft(self.radius)
			end
		end
		local count = 0
		for k, v in pairs(self.circles.data) do
			v = v - dt * 200
			if v <= 0 then count = count + 1 end
			self.circles.data[k] = v
		end
		for i = 1, count do
			self.circles:popRight()
		end
	end
	nebula.draw = function(self)
		love.graphics.setScissor(window.lwallx, window.ceiling, window.rwallx - window.lwallx, window.h - window.ceiling)
		legacySetColor(0, 255, 200, 255)
		love.graphics.setLineStyle("rough")
		love.graphics.setLineWidth(5)
		for k, v in pairs(self.circles.data) do
			love.graphics.circle("line", self.x, self.y, v)
		end
		--love.graphics.circle("line", self.x, self.y, self.radius)
		love.graphics.setScissor()
	end
	playSound("control", true, nebula)
	game:emplace("environments", nebula)

	local m = Monitor:new("Nebula", nebula.timer)
	function m:update()
		if nebula.timer <= 0 then
			return true
		end
		self.value = nebula.timer
	end
	monitorManager:add(m)
end

f[49] = function() --Intelligent Shadow
	for _, e in pairs(game.environments) do
		if e.shadow then
			e.timer = e.timer + 10
			return
		end
	end

	local shadow = Environment:new("paddle_powerdown", rects.paddle[28], 80, 16, game.paddle.x, Paddle.baseline + 16)
	shadow.shadow = true
	shadow.timer = 10
	shadow:setShape(shapes.newRectangleShape(0, 0, shadow.w, shadow.h))
	shadow.update = function(self, dt)
		local mx = Paddle.autopilotUpdate(self, true)
		local sx = 1500 * dt
		local dx = self.x - mx
		if dx < -sx then
			mx = self.x + sx
		elseif dx > sx then
			mx = self.x - sx
		end
		mx = math.min(window.rwallx - self.w/2, math.max(window.lwallx + self.w/2, mx))
		self.x = mx
		for _, ball in pairs(game.balls) do
			if util.bboxOverlap({ball.shape:bbox()}, {self.shape:bbox()}) then
				if ball.shape:collidesWith(self.shape) and not ball.shape:collidesWith(game.paddle.shape) then
					if ball.vy < 0 and not ball.isParachuting then return end

					local spd = ball:getSpeed()
					local vx = paddle_strength * (ball.x - self.x) / self.w
					ball.vx, ball.vy = vx, -1.0
					ball:scaleVelToSpeed(spd)

					ball:onPaddleHit(self)
				end
			end
		end

		self.timer = self.timer - dt
		if self.timer <= 0 then
			self:kill()
		end

		Environment.update(self, dt)
	end
	shadow.draw = function(self)
		Paddle.drawPaddle(self)
	end
	local m = Monitor:new("I. Shadow", shadow.timer)
	function m:update()
		if shadow.timer <= 0 then
			return true
		end
		self.value = shadow.timer
	end
	monitorManager:add(m)
	game:emplace("environments", shadow)
	playSound("intshadow")
end

f[3] = function() --Assist
	for _, e in pairs(game.environments) do
		if e.assist then
			return
		end
	end
	local gate = {}
	gate[1] = playstate:openGate("left", 5, 50)
	gate[2] = playstate:openGate("right", 5, 50)
	local y = window.ceiling - 16 + gateOffset.side[5]*2 + 2
	local x = {window.lwallx - 22 - 16, window.rwallx + 22 + 16}
	local mul = {1, -1}
	for i = 1, 2 do
		local assist = Environment:new("assist", rects.assist.base, 44, 44, x[i], y)
		assist.assist = true
		assist.state = "waiting"
		assist.offset = 64
		assist.gun = Sprite:new("assist", rects.assist.gun, 14, 16)
		assist.burstcd = 0
		assist.burstcdmax = 2
		assist.cd = 0
		assist.burst = 3
		assist.update = function(self, dt)
			if self.state == "waiting" then
				if gate[i].state == "opened" then
					self.state = "moving"
				end
			elseif self.state == "moving" then
				local dx = dt*100
				self.x = self.x + dx * mul[i]
				self.offset = self.offset - dx
				if self.offset <= 0 then
					self.x = self.x + self.offset * mul[i]
					self.state = "recharging"
					gate[i].state = "closing"
				end
			elseif self.state == "recharging" then
				self.burstcd = self.burstcd - dt
				if self.burstcd <= 0 then
					self.burstcd = self.burstcdmax
					self.state = "firing"

					local ignore = function(br)
						if br.brickType == "OneWayBrick" then
							return true
						elseif br.brickType == "ForbiddenBrick" then
							return true
						elseif br.brickType == "FlipBrick" or br.brickType == "StrongFlipBrick" then
							if not br.state then
								return true
							end
						end
						return false
					end

					local candidates = Stack:new()
					local indestructibles = Stack:new()
					for _, br in pairs(game.bricks) do
						if br.armor <= 1 then
							candidates:push(br)
						elseif not ignore(br) then
							indestructibles:push(br)
						end
					end

					local function compare(a, b)
						local a_dist = math.pow(a.x-self.x, 2) + math.pow(a.y-self.y, 2)
						local b_dist = math.pow(b.x-self.x, 2) + math.pow(b.y-self.y, 2)
						return a_dist > b_dist
					end

					table.sort(candidates.data, compare)

					local w = 16
					self.targets = {}
					for i = 1, 3 do
						local target = nil
						while target == nil and not candidates:empty() do
							target = candidates:pop()
							local dx, dy = target.x - self.x, target.y - self.y
							for _, br in pairs(indestructibles.data) do
								local dx2, dy2 = br.x - self.x, br.y - self.y
								if dx*dx + dy*dy > dx2*dx2 + dy2*dy2 then
									local nx, ny = util.normalize(dx2, dy2)
									nx, ny = nx*w/2, ny*w/2
									local vx1, vy1 = util.rotateVec(nx, ny, 90)
									local vx2, vy2 = util.rotateVec(nx, ny, -90)
									local x1, y1 = self.x + vx1, self.y + vy1
									local x2, y2 = self.x + vx2, self.y + vy2
									if br.shape:intersectsRay(x1, y1, dx, dy) or
									   br.shape:intersectsRay(x2, y2, dx, dy) then
										target = nil
										break
									end
								end
							end
						end
						if not target then break end
						table.insert(self.targets, target)
					end
					if #self.targets > 0 and #self.targets < 3 then
						while #self.targets < 3 do
							table.insert(self.targets, self.targets[1])
						end
					end
				end
			else
				--assuming that the delay between burst is longer than the burst itself
				self.burstcd = self.burstcd - dt
				self.cd = self.cd - dt
				if self.cd <= 0 then
					self.cd = 0.1
					self.burst = self.burst - 1
					if self.burst == 0 then
						self.burst = 3
						self.state = "recharging"
					end
					if #self.targets > 0 then
						local target = table.remove(self.targets)
						local x1, y1 = self:getPos()
						local x2, y2 = target:getPos()
						local theta = -(math.atan2(x2-x1, y2-y1)) + math.pi
						self.gun.angle = theta
						local vx, vy = util.rotateVec(0, -500, math.deg(theta))
						local laser = Projectile:new("assist", rects.assist.laser, x1, y1, vx, vy, theta, "rectangle", 16, 18)
						game:emplace("projectiles", laser)
						playSound("laser")
					end
				end
			end
			self.gun:setPos(self:getPos())
			Environment.update(self, dt)
		end
		assist.draw = function(self)
			love.graphics.setScissor(window.lwallx - 16, window.ceiling - 16, window.boardw + 32, window.boardh + 16)
			Environment.draw(self)
			self.gun:draw()
			love.graphics.setScissor()
		end
		game:emplace("environments", assist)
	end
	playSound("assistopen")
end

f[13] = function() --Bypass
	openGate("bottom", 2)
	local callback = Callback:new(62/100, function() playstate.bypass = "standby" end)
	game:emplace("callbacks", callback)
	playSound("bypass")
end

f[123] = function() --Warp
	openGate("bottom", 2)
	local callback = Callback:new(62/100, function() playstate.bypass = "standby"; playstate.warp = true end)
	game:emplace("callbacks", callback)
	playSound("bypass")
end

f[58] = function() --Laceration
	--first I need to get rid of Mobility
	for _, e in pairs(game.environments) do
		if e.mobility then
			e.suppress = true
			e:kill()
		end
	end
	for _, e in pairs(game.enemies) do
		if e.menacerType ~= "red" then
			e:kill()
		end
	end
	for _, m in pairs(game.menacers) do
		if m.menacerType ~= "red" then
			m:kill()
		end
	end
	local flag = enemySpawner.flag
	flag["cyan"] = false
	flag["bronze"] = false
	flag["silver"] = false
	flag["pewter"] = false
	flag["green"] = false
	local flash = Particle:new(
		"white_pixel", 
		nil, 
		window.boardw, 
		window.boardh, 
		window.w/2, 
		window.ceiling + window.boardh/2,
		0,
		0,
		0,
		0.5
	)
	flash:setColor(153, 102, 51, 255)
	flash.fadeRate = 510
	game:emplace("particles", flash)
	playSound("laceration")
end

f[63] = function() --Lock
	for _, br in pairs(game.bricks) do
		if br.isMoving and br.moveType == "constant" then
			local i, j = getGridPos(br:getPos())
			local x, y = getGridPosInverse(i, j)
			br:moveTo2(x, y, 500, "die")
		end
	end
	playSound("lock")
end

f[68] = function() --Mobility
	for _, e in pairs(game.environments) do
		if e.mobility then return end
	end
	local mobility = Environment:new()
	mobility.mobility = true
	local flag = enemySpawner.flag
	mobility.flag = util.copy(flag)
	flag["cyan"] = false
	flag["bronze"] = false
	flag["silver"] = false
	flag["pewter"] = false
	flag["green"] = false
	mobility.timer = 20
	mobility.onDeath = function(self)
		if self.suppress then return end

		for k, v in pairs(self.flag) do
			enemySpawner.flag[k] = v
		end
		for _, m in pairs(game.menacers) do
			m.disable = nil
		end
		for _, e in pairs(game.enemies) do
			e.disable = nil
		end
	end
	mobility.update = function(self, dt)
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self:kill()
		end
		for _, m in pairs(game.menacers) do
			if m.menacerType ~= "red" then m.disable = true end
		end
		for _, e in pairs(game.enemies) do
			if e.menacerType ~= "red" then e.disable = true end
		end
	end
	game:emplace("environments", mobility)
	local m = Monitor:new("Mobility", mobility.timer)
	function m:update()
		if mobility.dead then return true end
		self.value = mobility.timer
	end
	monitorManager:add(m)
end

f[87] = function() --Quake
	local function getValidBrick(i, j)
		local bucket = playstate.brickGrid[i][j]
		for _, br in pairs(bucket) do
			if not br.isMoving and br.alignedToGrid and (br.brickType == "NormalBrick" or br.brickType == "MetalBrick") then
				return br
			end
		end
		return nil
	end
	--get table of adjacent pairs of bricks
	local btable = {}
	local btableinv = {}
	local blist = {}
	for i = 1, 32 do
		for j = 1, 12 do
			local b1 = getValidBrick(i, j)
			local b2 = getValidBrick(i, j+1)
			if b1 and b2 then
				btable[b1] = b2
				btableinv[b2] = b1
			end
		end
	end
	for k in pairs(btable) do
		table.insert(blist, k)
	end
	for i = 1, 10 do
		if #blist == 0 then
			break
		end
		local b1 = blist[math.random(#blist)]
		local b2 = btable[b1]
		local b0 = btableinv[b1]
		util.remove_if(blist, function(x) return x == b2 or x == b1 or x == b0 end)
		b1:moveTo(b2.x, b2.y, 0.1, "die")
		b2:moveTo(b1.x, b1.y, 0.1, "die")
	end
	for n = 0, 1 do
		local callback = Callback:new(0.2 + 0.3*n, function()
			for i = 23, 1, -1 do
				for j = 1, 13 do
					local t = playstate.brickGrid[i][j]
					local t2 = playstate.brickGrid[i+1][j]
					for _, br in pairs(t) do
						local canMove = false
						if not br.isMoving and br.alignedToGrid and br.armor <= 1 then
							canMove = true
							for _, br2 in pairs(t2) do
								if br2.alignedToGrid and not br2.isMoving then
									canMove = false
									break
								end
							end
						end
						if canMove then
							br:moveTo(br.x, br.y + 16, 0.1, "die")
						end
					end
				end
			end
		end)
		game:emplace("callbacks", callback)
	end
	playstate:screenShake(2, 1)
	playSound("quake")
end

f[104] = function() --Slug
	for _, e in pairs(game.environments) do
		if e.slug then return end
	end
	local slug = Environment:new()
	slug.update = function(self, dt)
		for _, p in pairs(game.projectiles) do
			if p.enemy and not p.slug then
				p.vx = p.vx * 0.33
				p.vy = p.vy * 0.33
				if p.boulder then
					p.ay = p.ay * 0.33
				end
				p.slug = true
			end
		end
	end
	game:emplace("environments", slug)
	playSound("slow")
end

f[105] = function() --Terraform
	local valid = {
		"MetalBrick", 
		"GoldBrick",
		"CopperBrick",
		"GoldSpeedBrick",
		"SpeedBrick",
		"AlienBrick",
		"GeneratorBrick",
		"TikiBrick",
		"LaserEyeBrick",
		"BoulderBrick",
		"JumperBrick",
		"RainbowBrick",
		"ParachuteBrick",
		"SequenceBrick",
		"SplitBrick"
	}
	valid = util.generateLookup(valid)
	local greens = {}
	for i = 1, 4 do
		for j = 8, 9 do
			table.insert(greens, {i, j})
		end
	end
	for _, br in pairs(game.bricks) do
		if valid[br.brickType] then
			local i, j = unpack(greens[math.random(#greens)])
			local n = NormalBrick:new(br.x, br.y, i, j, "brick_spritesheet")
			n:inheritMovement(br)
			br.suppress = true
			br:kill()
			game:emplace("bricks", n)
		end
	end
	playSound("terraform")
end

f[113] = function() --Ultraviolet
	for _, e in pairs(game.environments) do
		if e.ultraviolet then
			e.count = e.count + 10
			return
		end
	end
	local uv = Environment:new()
	uv.count = 10
	uv.timer = 0
	uv.delay = 0.1
	uv.update = function(self, dt)
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self.timer = self.delay
			self.count = self.count - 1
			if self.count <= 0 then
				self:kill()
			end
			local candidates = {}
			for _, br in pairs(game.bricks) do
				if br.brickType == "NormalBrick" and not br.uv then
					table.insert(candidates, br)
				end
			end
			if #candidates > 0 then
				local br = candidates[math.random(#candidates)]
				br:ultraviolet()
			else
				self:kill()
			end
		end
	end
	game:emplace("environments", uv)
	playSound("microwave")
end


f[129] = function() --X-Ray
	local candidates = {}
	for _, br in pairs(game.bricks) do
		if br.brickType == "NormalBrick" then
			table.insert(candidates, br)
		end
	end
	local count = math.ceil(#candidates * 0.3)
	for i = 1, count do
		local br = table.remove(candidates, math.random(#candidates))
		local id = powerupGenerator:getId()
		local pbrick = PowerUpBrick:new(br.x, br.y, id)
		pbrick:inheritMovement(br)
		br.suppress = true
		br:kill()
		game:emplace("bricks", pbrick)
	end
	playSound("xray")
end

f[117] = function() --Undestructible
	for _, e in pairs(game.environments) do
		if e.undestructible then
			e.timer = 4
			return
		end
	end
	local exclude = util.generateLookup({"NullBrick", "ForbiddenBrick"})
	local u = Environment:new()
	u.undestructible = true
	u.timer = 4
	u.alpha = 128
	u.record = {}
	u.onDeath = function(self)
		for br, v in pairs(self.record) do
			br.armor = v
			br.undestructible = nil
		end
	end
	u.update = function(self, dt)
		for _, br in pairs(game.bricks) do
			if not exclude[br.brickType] and not br.undestructible then
				self.record[br] = br.armor
				br.armor = 10
				br.undestructible = true
			end
		end
		util.remove_if(self.record, function(br) return br:isDead() end)
		self.timer = self.timer - dt
		if self.timer <= 0 then
			self:kill()
		elseif self.timer <= 1 then
			self.alpha = 128 * self.timer
		end
	end
	u.draw = function(self)
		legacySetColor(255, 200, 0, self.alpha)
		for br in pairs(self.record) do
			love.graphics.rectangle("fill", br.x-br.w/2, br.y-br.h/2, br.w, br.h)
		end
	end
	game:emplace("environments", u)
	local m = Monitor:new("Undestructible", 4)
	function m:update()
		if u.dead then return true end
		self.value = u.timer
	end
	monitorManager:add(m)
	playSound("undestructable")
end

f[115] = function() --Undead
	for _, e in pairs(game.environments) do
		if e.undead then
			return
		end
	end
	local u = Environment:new("white_pixel", nil, window.rwallx-window.lwallx, 16, window.w/2, window.h - 8)
	u.undead = true
	u.greyscale = gradient({direction = 'horizontal';{1, 1, 1};{.2, .2, .2};})
	u.update = function(self, dt)
		for _, ball in pairs(game.balls) do
			if ball.y > self.y then
				game.paddle:attachBall(ball, "random")
				self:kill()
				break
			end
		end
	end
	u.draw = function(self)
		legacySetColor(255, 255, 255, 255)
		drawinrect(self.greyscale, self.x-self.w/2, self.y-self.h/2, self.w, self.h)
	end
	game:emplace("environments", u)
	playSound("undead")
end

f[116] = function() --Unlock
	-- local speeds = {}
	-- for _, s in ipairs(Brick.speeds) do
	-- 	table.insert(speeds, s)
	-- 	table.insert(speeds, -s)
	-- end
	local speed = Brick.speed.medium
	for _, br in pairs(game.bricks) do
		if (br.brickType == "NormalBrick" or br.brickType == "MetalBrick") and not br.isMoving then
			local i, j = getGridPos(br:getPos())
			if i % 2 == 0 then
				br.vx = speed
			else
				br.vx = -speed
			end
			br.isMoving = true
			br.moveType = "constant"
		end
	end
	playSound("lock")
end

f[133] = function() --Buzzer
	local angle = math.random(30, 60)
	if math.random() > 0.5 then
		angle = 180 - angle
	end
	local vx, vy = util.rotateVec(-500, 0, angle)
	local r = 48
	local x = math.random(window.lwallx + r, window.rwallx - r)
	local rect1 = make_rect(0, 0, 48, 48)
	local rect2 = make_rect(50, 0, 48, 48)
	local t = 0.2
	local p = Projectile:new("buzzer", rect1, x, window.h + r, vx, vy, 0, "circle", r)
	p.spinTimer = t
	p.spin = true
	p.damage = 10000
	p.strength = 1
	p:setComponent("piercing")
	p.pierce = "strong"
	p.boundCheck = false
	p.onDeath = function(self)
		stopSound("buzzer", true)
		Projectile.onDeath(self)
	end
	p.update = function(self, dt)
		local r = self.shape._radius
		local x, y = self:getPos()
		if x - r < window.lwallx  then self:handleCollision( 1,  0) end
		if x + r > window.rwallx  then self:handleCollision(-1,  0) end
		if y - r < window.ceiling then self:handleCollision( 0,  1) end
		if y - r > window.h and self.vy > 0 then
			self:kill() 
		end
		p.spinTimer = p.spinTimer - dt
		if p.spinTimer <= 0 then
			p.spinTimer = t
			if p.spin then
				self.rect = rect1
			else
				self.rect = rect2
			end
			p.spin = not p.spin
		end
		Projectile.update(self, dt)
	end
	-- p.draw = function(self)
	-- 	local r = self.shape._radius
	-- 	legacySetColor(255, 255, 255, 255)
	-- 	love.graphics.circle("fill", self.x, self.y, r)
	-- end
	game:emplace("projectiles", p)
	playSound("buzzer")
end
