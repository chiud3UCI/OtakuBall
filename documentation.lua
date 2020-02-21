--This contains documentation for bricks, menacers, and powerups

tooltipManager = {}
local tooltips = {}

--ordered based on appearance in the editor
tooltips.brick = {
	NormalBrick           = {"Normal Brick"            , "A standard brick that comes in many colors. It has a chance to drop a PowerUp when destroyed."},
	Rainbow               = {"Rainbow Normal Brick"    , "Not really a brick. When placed, it will transform into a random-colored Normal Brick. The color will change for each individual brick."},
	Rainbow2              = {"Rainbow Normal Brick"    , "Not really a brick. When placed, it will transform into a random-colored Normal Brick. The color will change for each group of bricks."},
	MetalBrick            = {"Metallic Brick"          , "A stronger brick that requires multiple hits for it to be destroyed."},
	GoldBrick             = {"Gold Brick"              , "An indestructible brick that only be damaged by a few objects."},
	PlatinumBrick         = {"Platinum Brick"          , "A super indestructible brick that is immune to all damage except for the Giga Ball."},
	CopperBrick           = {"Copper Brick"            , "A Gold-strength brick that causes the ball to bounce off at a random angle when hit."},
	OneWayBrick           = {"One Way Panel"           , "A panel that forces the ball to travel in one direction."},
	SpeedBrick            = {"Speed Brick"             , "A standard brick that alters the speed of the ball when hit."},
	GoldSpeedBrick        = {"Gold Speed Brick"        , "A Gold-strength brick that alters the speed of the ball when hit."},
	FunkyBrick            = {"Funky Brick"             , "This brick regenerates a few seconds after being destroyed."},
	GlassBrick            = {"Glass Brick"             , "An especially weak brick that even normal balls can pierce through."},
	DetonatorBrick        = {"Detonator Brick"         , "Explodes when hit, destroying nearby bricks."},
	ShooterBrick          = {"Shooter Brick"           , "A Platinum-strength brick that fires a laser upwards when hit."},
	AlienBrick            = {"Alien Brick"             , "Wanders around the board spawning Normal Bricks in its path. Takes 5 hits to destroy."},
	ShoveBrick            = {"Shove Brick"             , "Shoves Normal-strength bricks to the left or right. If a brick moves into an indestructible brick or the wall, it will die."},
	FactoryBrick          = {"Factory Brick"           , "When hit by a ball, it will eject a Normal Brick from the opposite side it was hit in. Dies in 7 hits"},
	CometBrick            = {"Comet Brick"             , "When destroyed, it releases a comet projectile that destroys all bricks in its path."},
	OnixBrick             = {"Onix Brick"              , "A Gold-strength slanted brick that can deflect balls at an angle."},
	TikiBrick             = {"Tiki Brick"              , "A Gold-stength brick. If it is hit 3 times, it will get mad and shrink the paddle."},
	LaserEyeBrick         = {"Laser Eye Brick"         , "Hiting the brick once will activate it, causing it to periodically shoot stun lasers. Hitting it a second time will destroy it."},
	BoulderBrick          = {"Boulder Brick"           , "When destroyed, it will drop boulders that can stun the paddle. Can withstand 2 hits."},
	TwinLauncherBrick     = {"Twin Launcher Brick"     , "Hitting it will switch the brick on or off. When two bricks on the board are activated, they will either attract or repel based on their colors."},
	TriggerDetonatorBrick = {"Trigger Detonator Brick" , "Hitting it will switch the brick on or off. It will only explode when two of them are activated."},
	JumperBrick           = {"Jumper Brick"            , "Hitting it will cause it to teleport to a random spot on the board. Can teleport three times before giving up."},
	RainbowBrick          = {"Rainbow Brick"           , "Releases a bunch of Normal Bricks into adjacent spaces when destroyed."},
	SlotMachineBrick      = {"Slot Machine Brick"      , "Cycles through one 3 powerups when hit. When every Slot Machine Brick (of the same color) has the same powerup, they will all be destroyed, releasing the powerup. DOUBLE CLICK TO SELECT POWERUP"},
	ParachuteBrick        = {"Parachute Brick"         , "When destroyed by a ball, it supplies the ball with a parachute that allows it to gently descend onto the paddle."},
	ShoveDetonatorBrick   = {"Shove Detonator Brick"   , "Shoves all adjacent bricks outwards when destroyed."},
	ForbiddenBrick        = {"Forbidden Brick"         , "Invisible and intagible, but can be placed to prevent other bricks from moving or spawning into a space."},
	SwitchBrick           = {"Switch Brick"            , "An indestructible brick that will flip the states of Flip Bricks of the same color."},
	TriggerBrick          = {"Trigger Brick"           , "Functions the same as the Switch Brick, but dies after one hit."},
	FlipBrick             = {"Flip Brick"              , "A Normal-strength brick that switches between tangible and intangible when flipped."},
	StrongFlipBrick       = {"Strong Flip Brick"       , "An indestructible Flip Brick."},
	SequenceBrick         = {"Sequence Brick"          , "A brick that can't be destroyed unless all other lower-numbered Sequence Brick are gone."},
	PowerUpBrick          = {"PowerUp Brick"           , "A brick that contains a garunteed powerup. DOUBLE CLICK TO SELECT POWERUP."},
	GateBrick             = {"Gate Brick"              , "Transports the ball to another Gate Brick of the same color"},
	ConveyorBrick         = {"Conveyor Brick"          , "A panel that gradually steers the ball in a certain direction. Comes in 3 different speeds."},
	LauncherBrick         = {"Launcher Brick"          , "Has an rotating arrow. When hit, the brick will launch itself in the direction of the arrow, destroying any brick in its path."},
	SplitBrick            = {"Split Brick"             , "Splits into two lesser bricks when hit."},
	GhostBrick            = {"Ghost Brick"             , "An invisible Platinum-strength brick."}
}

tooltips.brickSecondary = {
	MetalBrick = {_compare = 1,
		[20] = "This brick can withstand 2 hits before dying.",
		[30] = "This brick can withstand 3 hits before dying.",
		[40] = "This brick can withstand 4 hits before dying.",
		[50] = "This brick can withstand 5 hits before dying.",
		[60] = "This brick can withstand 6 hits before dying.",
		[70] = "This brick can withstand 7 hits before dying."
	},
	GoldBrick = {_compare = 1,
		[true] = "This brick has a normal-strength plate that must be destroyed to beat the level."
	},
	SpeedBrick = {_compare = 1,
		[true] = "This will make the ball go faster.",
		[false] = "This will make the ball go slower."
	},
	GoldSpeedBrick = {_compare = 1,
		[true] = "This will make the ball go faster.",
		[false] = "This will make the ball go slower."
	},
	FunkyBrick = {_compare = 1,
		[20] = "The blue variant can take 2 hits.",
		[30] = "The green variant can take 3 hits.",
		[40] = "The red variant can take 4 hits."
	},
	DetonatorBrick = {_compare = 1,
		["normal"] = "The Standard Detonator destroys all bricks in a 3x3 square.",
		["freeze"] = "The Freeze Detonator freezes all bricks in a 3x3 square, turning them into Ice Bricks.",
		["neo"] = "The Neo Detonator destroys all bricks in a 5x5 square."
	},
	ShooterBrick = {_compare = 1,
		["red"] = "The red Shooter lasers can destroy standard bricks.",
		["green"] = "The green Shooter lasers can destroy multi-hit bricks in one shot.",
		["blue"] = "The blue Shooter lasers can destroy Gold-strength bricks in one shot."
	},
	CometBrick = {_compare = 1,
		["left"] = "This variant fires a comet to the left.",
		["right"] = "This variant fires a comet to the right.",
		["horizontal"] = "This variant fires one comet to the left and one to the right.",
		["vertical"] = "This variant fires one comet up and one comet down."
	},
	FlipBrick = {_compare = 2,
		[true] = "This brick starts out in a tangible state.",
		[false] = "This brick starts out in an intangible state.",
	},
	StrongFlipBrick = {_compare = 2,
		[true] = "This brick starts out in a tangible state.",
		[false] = "This brick starts out in an intangible state.",
	},
	GateBrick = {_compare = 2,
		[true] = "This gate is exit only and does not accept new balls."
	},
	LauncherBrick = {_compare = 1,
		[true] = "This brick will spin counter-clockwise.",
		[false] = "This brick will spin clockwise."
	}
}

tooltips.patch = {
	shield    = {"Shield Patch"     , "Makes the brick indestructible on one side. Can be stacked."},
	invisible = {"Invisible Patch"  , "Makes the brick invisible. It will reveal itself after being hit once."},
	movement  = {"Mobile Patch"     , "Makes the brick move in one direction at a constant speed and bounce off of walls and other bricks."},
	movement2 = {"Mobile Patch"     , "Makes the brick move in one direction at a constant speed and bounce off of walls and other bricks. This variant will not make the brick move until it gets hit."},
	antilaser = {"Anti-Laser Patch" , "Makes the brick immune to lasers."}
}

tooltips.tool = {
	free       = {"Free Tool"           , "Freely place bricks at the cursor."},
	line       = {"Line Tool"           , "Place bricks in a line."},
	rect       = {"Rectangle Tool"      , "Place bricks in a rectangle outline."},
	fillrect   = {"Fill Rectangle Tool" , "Place bricks in a filled rectangle."},
	fill       = {"Fill"                , "Replaces same adjacent bricks with another brick."},
	replace    = {"Replace"             , "Replaces all same bricks with another brick."},
	cut        = {"Cut"                 , "Copies a selection of bricks and removes them from the board."},
	copy       = {"Copy"                , "Copies a selection of bricks to be pasted later."},
	paste      = {"Paste"               , "Pastes a previously copied selection of bricks."},
	eyedropper = {"Eyedropper"          , "Determines which brick button is used to place the selected brick."}
}

tooltips.enemy = {
	redgreen    = {"Red and Green Menacer" , "Green Menacers turn bricks into indestructible green bricks. Red Menacers destroy those green bricks."},
	cyan        = {"Cyan Menacer"          , "Turns your paddle invisible."},
	bronze      = {"Bronze Menacer"        , "Transforms Normal and Metallic bricks into Bronze bricks."},
	silver      = {"Silver Menacer"        , "Transforms Normal and Metallic bricks into Silver bricks."},
	pewter      = {"Pewter Menacer"        , "Does nothing."},
	dizzy       = {"Dizzy"                 , "Traces along the bricks and then floats around once there is enough space."},
	cubic       = {"Cubic"                 , "Traces along the bricks and then floats around once there is enough space."},
	gumballtrio = {"Gumball Trio"          , "Splits into 3 balls when hit."},
	walkblock   = {"Walk Block"            , "Walks around until it exits through the bottom."}
}

tooltips.button = {
	background = {1, 1, "Background Select Menu" , "Each pattern also has a transparent counterpart that can be set to any color."},
	powerup    = {1, 2, "Powerup Weights Menu"   , "Edit the drop rates of each powerup for this level. Most levels use the default powerup setting."},
	bricktab   = {2, 1, "Brick Tab"              , "Mortar not included."},
	patchtab   = {2, 2, "Patch Tab"              , "Patches can be placed over bricks to give them special properties."},
	enemytab   = {2, 3, "Enemy Tab"              , "Select which enemies to spawn for this level as well as their spawning frequency."},
}

tooltips.powerup = {
	{"Acid"               , "Turns the ball into an Acid Ball that can destroy indestructible bricks and pierce through Normal Bricks."},
	{"AntiGravity"        , "Makes the ball curve upwards for a short duration."},
	{"Assist"             , "Summons two turrets that automatically shoot bricks."},
	{"Attract"            , "Makes the ball curve slightly towards nearby bricks."},
	{"Autopilot"          , "Makes the paddle move on its own, accurately rebounding balls to the nearest brick."},
	{"Ball Cannon"        , "Gives the paddle the ability to shoot a spread of bouncy balls."},
	{"Barrier"            , "Creates a barrier at the bottom of the board that can rebound balls for 10 seconds."},
	{"Blackout"           , "Prevents the player from seeing anything besides the paddle and balls."},
	{"Beam"               , "Gives the paddle the ability to create a traction beam that can pull balls towards the center."},
	{"Blossom"            , "Makes the ball scatter plasma pellets on command. After firing, the ball must recharge by hitting the paddle."},
	{"Bomber"             , "Arms the ball with a powerful bomb that can destroy a 7x7 circle of bricks."},
	{"Bulk"               , "Increases the strength of all Normal Bricks by one hit."},
	{"Bypass"             , "Opens up an exit door at the bottom right of the board that allows the player to skip the current level."},
	{"Cannon"             , "Transforms the next ball to hit the paddle into a Cannonball that can travel directly upwards, destroying all bricks in its path."},
	{"Catch"              , "Enables the paddle to catch balls and release them on command."},
	{"Change"             , "Inverts paddle controls."},
	{"Chaos"              , "Detonates all explosive bricks."},
	{"Column Bomber"      , "Arms the ball with a powerful bomb that can destroy an entire column of bricks."},
	{"Combo"              , "Makes the ball automatically zoom towards the nearest brick after destroying a brick."},
	{"Control"            , "Gives the paddle the ability to create a gravity well that can trap the ball in a single location for a few seconds."},
	{"Disarm"             , "Converts Funky Bricks, Switch Bricks, and Generator Bricks into normal bricks."},
	{"Disrupt"            , "Splits a ball into 8 balls."},
	{"Domino"             , "Gives the ball the ability to drill through an unbroken row of bricks whenever it hits a brick."},
	{"Drill Missile"      , "Gives the paddle the ability to fire a Drill Missile that can clear entire columns of bricks."},
	{"Drop"               , "Causes a random selection of Normal Bricks to drop their powerups."},
	{"EMP Ball"           , "Arms the ball with a bomb that can destroy a 3x3 square of bricks. Can be recharged by hitting the paddle."},
	{"Energy"             , "Creates 3 energy balls that trails the ball. When the ball hits a brick, the energy balls are released. Can be recharged by hitting the paddle."},
	{"Erratic Missile"    , "Gives the paddle the ability to shoot homing missiles."},
	{"Extend"             , "Increases the size of the paddle."},
	{"Fast"               , "Increases the speed of the ball."},
	{"Freeze"             , "Freezes the paddle in place for 2 seconds."},
	{"Fireball"           , "Turns the ball into a Fire Ball that can destroy a 3x3 square of bricks with every hit."},
	{"Forcefield"         , "Creates a forcefield that's positioned slightly above the paddle. It will cause all returning balls to drop downwards at a reduced speed."},
	{"Frenzy"             , "Splits a ball into 24 balls."},
	{"Gelato"             , "Freezes a random row of bricks."},
	{"Generator Ball"     , "Turns the ball into a Generator Ball that can generate a ball after killing a brick. The balls need to be activated by the paddle first."},
	{"Ghost"              , "Makes the paddle more transparent whenever it stands still. The paddle won't be able to rebound balls if it's completely invisible."},
	{"Giga"               , "Turns the ball into a Giga Ball that can destroy every brick, including Platinum Bricks."},
	{"Glue"               , "Similar to Catch, but prevents the paddle from releasing balls until the end of its duration."},
	{"Gravity"            , "Makes the ball curve downwards for a short duration."},
	{"Hold Once"          , "Similar to Catch, but the paddle can only catch a ball once before turning back to normal."},
	{"Hacker"             , "Gives the paddle the ability to hack certain bricks, triggering their special abilities."},
	{"Halo"               , "Gives the ball the ability to become intangible whenever it hits the paddle and reform when it hits the top of the board."},
	{"HaHa"               , "Scatters 15 random Normal Bricks across the board."},
	{"Heaven"             , "Spawns a Heaven Paddle that floats above the paddle and can rebound balls."},
	{"Ice Ball"           , "Turns the ball into an Ice Ball that can freeze bricks, turning them into ice bricks. Can freeze indestructibles too."},
	{"Illusion"           , "Spawns two Illusion Paddles that slowly trail the paddle and can rebound balls."},
	{"Indigestion"        , "Causes every Normal Brick to spawn another Normal Brick in each direction."},
	{"Intelligent Shadow" , "Summons a Shadow Paddle that can automatically rebound balls."},
	{"Invert"             , "Gives the paddle the ability to invert the vertical velocity of the ball every few seconds."},
	{"Irritate"           , "Causes the ball to bounce off of surfaces at an unpredictable angle."},
	{"Javelin"            , "Arms the paddle with an Energy Javelin that can clear an entire column of bricks."},
	{"Junk"               , "Halves the amount of points gained."},
	{"Jewel"              , "Doubles the amount of points gained."},
	{"Joker"              , "When collected, it will instantly collect all other good powerups and destroy the bad ones."},
	{"Kamikaze"           , "Makes the ball aggressively home in on nearby bricks."},
	{"Knocker"            , "Gives the ball a sawblade that can piece through three bricks. It can be recharged by hitting the paddle."},
	{"Laceration"         , "Destroys all enemies and prevents any more of them from spawning for the rest of the stage."},
	{"Large Ball"         , "Increases the size of the ball, triples its damage, and allows for the ball to damage indestructible bricks."},
	{"Laser"              , "Gives the paddle the ability to shoot red lasers that can destroy regular bricks."},
	{"Laser Plus"         , "Gives the paddle the ability to shoot pink lasers that can destroy multi-hit bricks in one hit."},
	{"Laser Ball"         , "Makes the ball periodically fire lasers from itself."},
	{"Lock"               , "Stops all moving bricks."},
	{"Luck"               , "Makes only good powerups spawn for the remainder of the stage."},
	{"Magnet"             , "Makes the paddle attract good powerups towards it for the remainder of the stage."},
	{"Mega"               , "Turns the ball into a Mega Ball that can pierce through indestructible bricks."},
	{"Missile"            , "Gives the paddle the ability to shoot explosive missiles that can destroy indestructibles."},
	{"Mobility"           , "Temporarily freezes all enemies in place for 20 seconds."},
	{"Multiple"           , "Splits ALL balls on screen into three balls."},
	{"Mystery"            , "Activates a random good powerup."},
	{"Nano"               , "Spawn three fast-traveling Nano Balls that turn into Mega Balls if they touch the paddle."},
	{"Nebula"             , "Spawns a large gravity well that slowly pulls in all balls towards the center."},
	{"New Ball"           , "Spawns a new ball directly on the paddle."},
	{"Node"               , "Splits a ball into 3 balls. Whenever there are less than 3 balls in play, one of them will split to recover the missing balls."},
	{"Normal Ball"        , "Resets all effects on the ball."},
	{"Normal Ship"        , "Resets all effects on the paddle."},
	{"Nervous"            , "Makes the paddle shuffle sideways for a few seconds."},
	{"Oldie"              , "Instantly destroy 90% of the Normal Bricks on collection."},
	{"Open"               , "Opens a gap in the center of the board, shoving aside all bricks."},
	{"Orbit"              , "Surrounds the paddle with a large bubble that can rebound balls."},
	{"Particle"           , "Surrounds the ball with two particles that can bounce around and destroy bricks."},
	{"Pause"              , "Gives the paddle the ability to drastically slow down the ball for a few seconds."},
	{"Player"             , "Gives a new life."},
	{"Probe"              , "Attaches a Probe to the ball that can be recalled back to the paddle, destroying all bricks in its path."},
	{"Poison"             , "Makes the paddle unable to hit back balls for 4 seconds. Extremely dangerous."},
	{"Protect"            , "Gives the paddle a shield that can protect it from hostile projectiles."},
	{"Quake"              , "Shuffles the bricks slightly and shifts them down two rows."},
	{"Quasar"             , "Summons a singularity that sucks in all bricks in the center of the screen."},
	{"Quadruple"          , "Immediately launches four new balls from the paddle."},
	{"Rapidfire"          , "Gives the paddle the ability to rapidly shoot out bullets that do half-damage to regular bricks."},
	{"Restrict"           , "Decreases the size of the paddle."},
	{"Regenerate"         , "Gives the paddle the ability to spawn a new ball every five seconds."},
	{"Re-Serve"           , "Warps all active balls back to the paddle to be re-served again."},
	{"Reset"              , "Resets the paddle and all balls back to normal."},
	{"Risky Mystery"      , "Activates a random powerup, good or bad."},
	{"Rocket"             , "Gives the paddle the one-time ability to launch in the air destroying all bricks it touches."},
	{"Row Bomber"         , "Arms the ball with a powerful bomb that can destroy an entire row of bricks."},
	{"Shrink"             , "Shrinks the size of the ball and make it deal only half as much damage."},
	{"Shadow"             , "Turns the paddle black and almost invisible."},
	{"Shotgun"            , "Gives the paddle the ability to shoot out a spread of 6 pellets that do half damage to bricks."},
	{"Sight Laser"        , "Reveals the path of the ball in advance as well as its trajectory when it hits the paddle."},
	{"Slow"               , "Decreases the speed of the ball."},
	{"Snapper"            , "Turns the ball into a Snapper Ball that can lay Snapper Mines on bricks. The mined bricks have to be hit again in order for it to detonate."},
	{"Slug"               , "Slows down all enemy projectiles for the rest of the stage."},
	{"Terraform"          , "Transforms select specialty bricks into Normal Bricks."},
	{"Time Warp"          , "Causes the flow of time to warp between slow and fast every few seconds."},
	{"Trail"              , "Causes the ball spawn 5 bricks in its path."},
	{"Tractor"            , "Creates a shield at the bottom of the board that can deflect a ball 3 times."},
	{"Transform"          , "Gives the paddle the ability to transform specialty bricks into Normal Bricks."},
	{"Triple"             , "Splits a ball into 3 balls."},
	{"Twin"               , "Adds another paddle besides the paddle that mimics some functions of the the original paddle."},
	{"Two"                , "Splits ALL balls on screen into 2 balls."},
	{"Ultraviolet"        , "Destroys 10 random bricks on screen."},
	{"Unification"        , "Transforms Normal Bricks into special Gemstone Bricks that provide 2.5 times the points of the original brick."},
	{"Undead"             , "Creates a shield at the bottom of the board that can catch a single ball and warp it back to the paddle."},
	{"Unlock"             , "Causes all bricks on screen to start moving sidways."},
	{"Undestructible"     , "For four seconds, all bricks become indestructible."},
	{"Vendetta"           , "Summons a drill that can destroy a random row of bricks."},
	{"Vector"             , "Allows the paddle to move in all directions for 10 seconds."},
	{"Venom"              , "Causes all explosive bricks to spread to the nearest space in all directions."},
	{"Volt"               , "Turns the ball into a Volt Ball that is capable of shocking nearby bricks, dealing damage over time."},
	{"Voodoo"             , "Turns the ball into a Voodoo ball that randomly damages two other bricks every time it hits a brick."},
	{"Warp"               , "Opens up an exit door at the bottom right of the board that allows the player to skip two levels."},
	{"Weak"               , "Makes the ball occasionally unable to damage bricks for 20 seconds."},
	{"Weight"             , "Makes the paddle move slower."},
	{"Wet Storm"          , "Causes rain projectiles to fall from the top of the board, destroying any brick it hit."},
	{"Whisky"             , "Causes the ball to become drunk and swerve around."},
	{"X-Bomb"             , "Arms the paddle with a X-Bomb that can be fired onto any space and destroy the row, column, and diagonals for that space."},
	{"X-Ray"              , "Turns a random number of Normal Bricks into Powerup Bricks that are garunteed to drop a powerup."},
	{"Yoyo"               , "Drastically speeds up the ball the farther it is from the paddle."},
	{"Yoga"               , "Increases the sensitivity of the paddle, causing it to move farther than expected."},
	{"Y-Return"           , "Causes the ball to home in on the paddle whenever it is traveling downwards."},
	{"Buzzer"             , "Launches a giant sawblade that bounces around the board, destroying all bricks in its path, before exiting from the bottom of the screen."},
	{"Zeal"               , "Drastically increases the speed of the ball."},
	{"Zen Shove"          , "Causes all bricks to shift down by one row every time a ball hits the paddle."}
}

function tooltipManager:clear()
	self.mode = nil
	self.imgstr = nil
	self.rect = nil
	self.title = nil
	self.text = nil
end

function tooltipManager:selectBrick(brickData)
	self.mode = nil
	if not brickData then return end

	local t = tooltips.brick[brickData.type]
	if not t then return end

	self.mode = "brick"
	self.imgstr = brickData.imgstr
	self.rect = brickData.rect
	self.title = t[1]
	self.text = t[2]

	t = tooltips.brickSecondary[brickData.type]
	if not t then return end

	local str = t[brickData.args[t._compare]]
	if str then self.text = self.text.." "..str end
end

function tooltipManager:selectPatch(button)
	local patch = button.key
	local arg = button.value
	local t
	if patch == "movement" then
		if arg[3] then
			t = tooltips.patch["movement2"]
		else
			t = tooltips.patch["movement"]
		end
	elseif patch == "shield_up" or patch == "shield_down" or patch == "shield_left" or patch == "shield_right" then
		t = tooltips.patch["shield"]
	else
		t = tooltips.patch[patch]
	end
	self.mode = "patch"
	self.imgstr = button.imgstr
	self.rect = button.rect
	self.title = t[1]
	self.text = t[2]
end

function tooltipManager:selectTool(button)
	local t = tooltips.tool[button.tool]
	self.mode = "tool"
	self.imgstr = button.imgstr
	self.rect = button.rect
	self.title = t[1]
	self.text = t[2]
end

function tooltipManager:selectEnemy(enemy)
	self.mode = nil
	local desc = tooltips.enemy[enemy]
	if not desc then return end

	local lookup = util.generateLookup({"dizzy", "cubic", "gumballtrio", "walkblock"})
	self.mode = "enemy"
	if lookup[enemy] then
		self.imgstr = "enemy_editor"
		self.rect = rects.enemy_editor[enemy]
	else
		self.imgstr = "ball_spritesheet"
		self.rect = rects.menacer_editor[enemy]
	end
	self.title = desc[1]
	self.text = desc[2]
end

function tooltipManager:selectButton(name)
	self.mode = nil
	local desc = tooltips.button[name]
	if not desc then return end

	self.mode = "button"
	self.imgstr = "button_icon"
	self.rect = rects.icon[desc[1]][desc[2]]
	self.title = desc[3]
	self.text = desc[4]
end

function tooltipManager:selectPowerUp(pid)
	self.mode = nil
	local desc = tooltips.powerup[pid]
	if not desc then return end

	self.mode = "powerup"
	self.imgstr = "powerup_spritesheet"
	self.rect = rects.powerup_ordered[pid]
	self.title = desc[1]
	self.text = desc[2]
end

function tooltipManager:draw()
	if not self.mode then return end

	legacySetColor(255, 255, 255, 255)
	local r = self.rect
	draw(self.imgstr, self.rect, window.lwallx, 10, 0, r.w*2, r.h*2, 0, 0)

	love.graphics.setFont(font["Arcade20"])
	legacySetColor(0, 0, 0, 255)
	love.graphics.print(self.title, window.lwallx + r.w*2 + 10, 10)

	love.graphics.setFont(font["dialog"])
	love.graphics.printf(self.text, window.lwallx, r.h*2 + 14, window.boardw)
end

