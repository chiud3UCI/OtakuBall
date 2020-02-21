ani = {}
assets = {}
rects = {}
font = {default = love.graphics.getFont()}
shader = {}
cursors = {}
sounds = {}

--the sound monitor makes sure only 3 instances of a sound can be played at once
--and that that they can't be played within 0.05 seconds of eachother
max_sounds = 3
soundMonitor = {
	active = false,
	limit = 0.05,
	lastPlayed = {},
	update = function(self, dt)
		for k, v in pairs(self.lastPlayed) do
			self.lastPlayed[k] = v + dt
		end
	end,
	activate = function(self)
		self.active = true
		for k, v in pairs(self.lastPlayed) do
			self.lastPlayed[k] = 0
		end
	end,
	deactivate = function(self)
		self.active = false
	end,
	canPlay = function(self, name)
		t = self.lastPlayed[name]
		return t >= self.limit
	end,
	updateSound = function(self, name)
		self.lastPlayed[name] = 0
	end
}

function loadSound(name, path, stream)
	if not love.filesystem.getInfo(path) then
		error("unable to load sound \""..path.."\"")
	end
	local atype = stream and "stream" or "static"
	local queue = Queue:new()
	sounds[name] = queue
	for i = 1, max_sounds do
		sound = love.audio.newSource(path, atype)
		queue:pushLeft(sound)
	end
	soundMonitor:updateSound(name)
end

 soundTable = {} --keeps track of which objects are associated with which sounds

--can pass an object as an argument to keep track of who played the sound
function playSound(name, loop, object)
	if not name then return end
	if soundMonitor.active then
		if not soundMonitor:canPlay(name) then return end
		soundMonitor:updateSound(name)
	end

	local queue = sounds[name]
	local sound = queue:popRight()
	sound:stop()
	soundTable[sound] = object
	sound:setLooping(loop == true)
	sound:play()
	queue:pushLeft(sound)
end

--single only stops the most recent instance of the sound
--if object is provided, only remove the sounds that are associated with the object
--if name is nil and object is not nil, then remove all sounds that belong to the object
function stopSound(name, single, object)
	if name then
		local queue = sounds[name]
		if object then
			--single does not affect this
			for _, v in pairs(queue.data) do
				---this might mess up the order of the sound queue, but does it matter?
				if soundTable[v] == object then
					v:stop()
					soundTable[v] = nil
				end
			end
		else
			if single then
				local sound = queue:popLeft()
				sound:stop()
				queue:pushRight(sound)
			else
				for _, v in pairs(queue.data) do
					v:stop()
				end
			end
		end
	else
		if object == nil then return end
		for k, queue in pairs(sounds) do
			for _, v in pairs(queue.data) do
				if soundTable[v] == object then
					v:stop()
				end
			end
		end
	end
end


function loadImage(name, path)
	if not love.filesystem.getInfo(path) then
		error("unable to load image \""..path.."\"")
	end
	local image = love.graphics.newImage(path)
	local iw, ih = image:getDimensions()
	assets[name] = {img  = image, 
					quad = love.graphics.newQuad(0, 0, iw, ih, iw, ih)}
end

function drawBrick(imgstr, rect, x, y, r, w, h, ox, oy, kx, ky, flooring)
	-- if y - math.floor(y) == 0.5 then y = y - 0.05 end --weird graphical glitches appear if drawn at values ending in .5
	-- if x%1==0 then x = x - 0.05 end --bricks are weird ok?
	draw(imgstr, rect, x, y, r, w, h, ox, oy, kx, ky, flooring)
end

--unless specified, the x and y coordinates denote the center of the image
--set ox and oy to 0 if you want x, y to be the top left corner instead
function draw(imgstr, rect, x, y, r, w, h, ox, oy, kx, ky, flooring)
	if flooring then
		x = math.floor(x)
		y = math.floor(y)
	end
	local image = assets[imgstr].img
	if rect then
		local quad = assets[imgstr].quad
		local iw, ih = rect[3], rect[4]
		w = w or iw
		h = h or ih
		ox = ox or iw/2
		oy = oy or ih/2
		quad:setViewport(unpack(rect))
		love.graphics.draw(image, quad, x, y, r, w/iw, h/ih, ox, oy, kx, ky)
	else
		local iw, ih = image:getDimensions()
		w = w or iw
		h = h or ih
		ox = ox or iw/2
		oy = oy or ih/2
		love.graphics.draw(image, x, y, r, w/iw, h/ih, ox, oy, kx, ky)
	end
end

--drawing with scaling instead of dimensions
function draw2(imgstr, rect, x, y, r, sx, sy, ox, oy, kx, ky)
	if y - math.floor(y) == 0.5 then y = y - 0.1 end --weird graphical glitches appear if drawn at values ending in .5
	local image = assets[imgstr].img
	if rect then
		local quad = assets[imgstr].quad
		local w, h = rect[3], rect[4]
		ox = ox or w/2
		oy = oy or h/2
		quad:setViewport(unpack(rect))
		love.graphics.draw(image, quad, x, y, r, sx, sy, ox, oy, kx, ky)
	else
		local w, h = image:getDimensions()
		ox = ox or w/2
		oy = oy or h/2
		love.graphics.draw(image, x, y, r, sx, sy, ox, oy, kx, ky)
	end
end

function point(_x, _y)
	return {x=_x, y=_y}
end

function drawLightning(x1, y1, x2, y2, mode)
	local dist = util.dist(x1, y1, x2, y2)
	local angle = -(math.atan2(x2-x1,y2-y1)*180/math.pi) + 90
	if mode == "volt" then
		local test = {point(x1,y1), point(x1+dist,y1)}
		shockify(test, 0)
		for i, v in ipairs(test) do
			test[i] = point(util.rotatePoint(x1, y1, v.x, v.y, angle))
		end
		drawLines(test, {255, 255, 255})
		local test = {point(x1,y1), point(x1+dist,y1)}
		shockify(test, -20)
		for i, v in ipairs(test) do
			test[i] = point(util.rotatePoint(x1, y1, v.x, v.y, angle))
		end
		drawLines(test, {255, 255, 0})
		local test = {point(x1,y1), point(x1+dist,y1)}
		shockify(test, 20)
		for i, v in ipairs(test) do
			test[i] = point(util.rotatePoint(x1, y1, v.x, v.y, angle))
		end
		drawLines(test, {255, 255, 0})
	elseif mode == "tractor" then
		local test = {point(x1,y1), point(x1+dist,y1)}
		shockify(test, 0)
		for i, v in ipairs(test) do
			test[i] = point(util.rotatePoint(x1, y1, v.x, v.y, angle))
		end
		drawLines(test, {51, 153, 51})
		local test = {point(x1,y1), point(x1+dist,y1)}
		shockify(test, 0)
		for i, v in ipairs(test) do
			test[i] = point(util.rotatePoint(x1, y1, v.x, v.y, angle))
		end
		drawLines(test, {153, 204, 153})
	end
end

function shockify(points, off)
	if #points ~= 2 then return end
	local sin, cos = math.sin, math.cos
	local dist = points[2].x - points[1].x
	local baseY = points[1].y
	local y = baseY
	local x = points[1].x
	local baseX = x
	local last = points[2]
	points[1], points[2] = nil, nil
	local flip = (math.random(1,2)==1) and 1 or -1
	while x < last.x do
		x = x + math.random(3, 6)
		y = baseY + (off * sin((x - baseX) * math.pi / dist)) + (10 * sin(x / 2.5 + x)) + flip * (math.random(2, 12))
		points[#points+1] = point(x, y)
		flip = (flip == 1) and -1 or 1
	end
	points[#points] = nil
	points[#points+1] = last
end

function unpackPoints(points, i)
	i = i or 1
	if points[i] then
		return points[i].x, points[i].y, unpackPoints(points, i + 1)
	end
end

function drawLines(points, color)
	if #points < 2 then return end
	color = color or {255, 255, 255}
	love.graphics.setLineWidth(2)
	legacySetColor(unpack(color))
	love.graphics.line(unpackPoints(points))
end

function gradient(colors)
    local direction = colors.direction or "horizontal"
    if direction == "horizontal" then
        direction = true
    elseif direction == "vertical" then
        direction = false
    else
        error("Invalid direction '" .. tostring(direction) "' for gradient.  Horizontal or vertical expected.")
    end
    local result = love.image.newImageData(direction and 1 or #colors, direction and #colors or 1)
    for i, color in ipairs(colors) do
        local x, y
        if direction then
            x, y = 0, i - 1
        else
            x, y = i - 1, 0
        end
        result:setPixel(x, y, color[1], color[2], color[3], color[4] or 255)
    end
    result = love.graphics.newImage(result)
    result:setFilter('linear', 'linear')
    return result
end

function drawinrect(img, x, y, w, h, r, ox, oy, kx, ky)
    return -- tail call for a little extra bit of efficiency
    love.graphics.draw(img, x, y, r, w / img:getWidth(), h / img:getHeight(), ox, oy, kx, ky)
end


function getAniIter(t, loop)
	return coroutine.wrap(function()
		repeat
			for i, v in ipairs(t) do
				coroutine.yield(v[1], v[2])
			end
		until not loop
	end)
end

function setDeltaTime(t, dt)
	for i, v in ipairs(t) do
		v[2] = dt
	end
end

shader.glow = love.graphics.newShader[[
	extern number mag;
	extern vec3 target;
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
	{
		vec4 pixel = Texel(texture, texture_coords);
		pixel.r = pixel.r + (target.r - pixel.r) * mag;
		pixel.g = pixel.g + (target.g - pixel.g) * mag;
		pixel.b = pixel.b + (target.b - pixel.b) * mag;
		return pixel;
	}
]]
shader.glow:send("mag", 0)
shader.glow:send("target", {1, 1, 1})

shader.hacker = love.graphics.newShader[[
	extern vec2 center;
	extern number offset;
	vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
	{
		vec4 pixel = Texel(texture, texture_coords);
		number d = distance(center, pixel_coords);
		number mag = (sin(d / 5.0 + offset) + 1.0) / 2.0;
		pixel.r = mag;
		pixel.g = 1;
		pixel.b = 0;
		return pixel;
	}
]]
shader.hacker:send("center", {1, 2})
shader.hacker:send("offset", 0)

shader.outline = love.graphics.newShader[[
	vec4 resultCol;
	extern vec2 stepSize;

	vec4 effect( vec4 col, Image texture, vec2 texturePos, vec2 screenPos )
	{
		// get color of pixels:
		number alpha = 4*texture2D( texture, texturePos ).a;
		alpha -= texture2D( texture, texturePos + vec2( stepSize.x, 0.0f ) ).a;
		alpha -= texture2D( texture, texturePos + vec2( -stepSize.x, 0.0f ) ).a;
		alpha -= texture2D( texture, texturePos + vec2( 0.0f, stepSize.y ) ).a;
		alpha -= texture2D( texture, texturePos + vec2( 0.0f, -stepSize.y ) ).a;

		// calculate resulting color
		resultCol = vec4( 1.0f, 1.0f, 0.1f, alpha );
		// return color for current pixel
		return resultCol;
	}
]]
shader.outline:send("stepSize", {0.1, 0.1})

love.graphics.setDefaultFilter("nearest", "nearest", 0)


--format: generateFonts(file, name, {start, end, step}, {}, ...}
function generateFonts(name, file, ...)
	local args = {...}
	local path = "media/fonts/"..file
	for _, t in ipairs(args) do
		for i = t[1], t[2], t[3] do
			font[name..i] = love.graphics.newFont(path, i, "mono")
		end
	end
end

local genFonts = generateFonts

-- genFonts("Nov"     , "November.ttf",               {1, 30, 1}, {32, 64, 8})
genFonts("Arcade"  , "ARCADEPI.ttf",               {10, 50, 10})
genFonts("Pokemon" , "Pokemon Card GB Part B.ttf", {12, 12, 1}, {8, 32, 8})
genFonts("Munro"   , "Munro.ttf",                  {10, 50, 10})
genFonts("Origami" , "Origami.ttf",                {10, 100, 10})
genFonts("Rune"    , "runescape_uf.ttf",           {16, 64, 16})
genFonts("Windows" , "windows_command_prompt.ttf", {16, 64, 16})

font["mono16"] = love.graphics.newImageFont("media/fonts/mono16.png", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 :-!.,\"?>_", 0)
font["mono16"]:setLineHeight(1)

font["dialog"] = love.graphics.newImageFont("media/fonts/dialog.png", " abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,!?-+/():;%&`_*#=[]'{}", 1)
font["dialog"]:setLineHeight(.6)

font["tiny"] = love.graphics.newImageFont("media/fonts/tiny.png", " 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.-,!:()[]{}<>", 1)
font["tiny"]:setLineHeight(.8)

assets.icon32 = love.image.newImageData("media/gameicon32x32.png")

loadImage("border"                 , "media/OtakuBallBorder.png")
loadImage("background"             , "media/background.png")
loadImage("background2"            , "media/background2.png")
loadImage("title_temp"             , "media/otakuballtitledraft.png")
loadImage("brick_title"            , "media/otakuballtitleblocks.png")
loadImage("brick_title2"           , "media/otakuballtitleblocks2.png")
loadImage("menu_bg"                , "media/otakuballbgproject.png")
loadImage("campaign_bg"            , "media/campaignbg.png")
loadImage("title_sub"              , "media/otakuballtitlesubtext.png")
loadImage("menu_edit"              , "media/menu_edit.png")
loadImage("menu_play"              , "media/menu_play.png")
loadImage("menu_campaign"          , "media/menu_campaign.png")
loadImage("menu_playlist"          , "media/PlayPlaylist.png")
loadImage("menu_editlist"          , "media/Playlist Editor.png")
loadImage("menu_options"           , "media/Options.png")

loadImage("white_pixel"            , "media/whitepixel.png")
loadImage("white_circle"           , "media/whitecircle.png")
loadImage("clear_pixel"            , "media/clearpixel.png")
loadImage("no"                     , "media/no.png")

loadImage("campaign_char"          , "media/otakuball_map_char.png")
loadImage("campaign_icon"          , "media/otakuball_map_icons.png")

loadImage("editor_tool"            , "media/editorbuttons.png")
loadImage("conveyor_editor"        , "media/ConveyorBlockSpeedsinEditor.png")
loadImage("launcher_editor"        , "media/LauncherBlocksEditorView.png")
loadImage("powerup_editor"         , "media/Powerups.png")
loadImage("menacer_editor"         , "media/OtakuBallMeancerBallSetup.png")
loadImage("enemy_editor"           , "media/enemyeditor.png")
loadImage("checkbox"               , "media/checkboxes.png")
loadImage("checkradio"             , "media/checkradio.png")
loadImage("button_icon"            , "media/otakuballEditorUIicons2.png")
loadImage("quit_icon"              , "media/quitbuttonicon.png")

loadImage("powerup_spritesheet"    , "media/OtakuBallPowerupsSpritesheet.png")
loadImage("powerup_score"          , "media/OtakuBallPowerupPickupScoreValues.png")
loadImage("powerup_score_double"   , "media/OtakuBallPowerupPickupScoreValuesJewel.png")
loadImage("powerup_score_half"     , "media/OtakuBallPowerupPickupScoreValuesJunk.png")
loadImage("powerup_score_small"    , "media/OtakuBallScoreSmall.png")

loadImage("ball_nova"              , "media/NovaBallSprite.png")
loadImage("ball_spritesheet"       , "media/Characters.png")
loadImage("ball_spritesheet_new"   , "media/new_balls.jpg")
loadImage("ball_powerup"           , "media/OtakuBallPowerUpandPowerDown.png")
loadImage("ball_large"             , "media/OtakuballLarge.png")
loadImage("ball_giga"              , "media/GigaBallForcefield.png")
loadImage("ball_mini"              , "media/OtakuBallInactiveBall.png")
loadImage("ball_parachute"         , "media/OtakuBallParachute.png")
loadImage("ball_parachute2"        , "media/OtakuBallParachuteRedone.png")
loadImage("invert"                 , "media/OtakuBallInvertForcefield.png")

loadImage("dropper"                , "media/OtakuBalMeancerFillerGraphics.png")
loadImage("dropper2"               , "media/OtakuBallMenacerbase.png")

loadImage("enemy"                  , "media/enemies.png")

loadImage("paddle_powerup"         , "media/PaddlePoweruped.png")
loadImage("paddle_powerup2"        , "media/PaddlePoweruped2.png")
loadImage("paddle_powerdown"       , "media/PaddlePowerdowned.png")
loadImage("paddle_shadow"          , "media/ShadowPaddle.png")
loadImage("paddle_heaven"          , "media/HeavenPaddle.png")
loadImage("paddle_outline"         , "media/PaddleBorder.png")
loadImage("paddle_ice"             , "media/OtakuBallIce.png")
loadImage("paddle_life"            , "media/paddlelife.png")

loadImage("brick_spritesheet"      , "media/OtakuBallBricksRedone.png")
loadImage("brick_grey"             , "media/OtakuBallGreydBlocks.png")
loadImage("brick_bright"           , "media/OtakuBallBrighterThirdLevelColoredBlocks.png")
loadImage("brick_jetblack"         , "media/OtakuBallJetBlackBrick.png")
loadImage("brick_unification"      , "media/OtakuBallUnificationBlocks.png")
loadImage("brick_bulk"             , "media/OtakuBallBulkBlocks.png")
loadImage("brick_shine"            , "media/OtakuballShineBricks.png")
loadImage("brick_shine2"           , "media/OtakuBallAnimatedBlocksSet2.png")
loadImage("brick_regen"            , "media/OtakuBallRegenBlocks.png")
loadImage("brick_glow"             , "media/OtakuBallGlowingExplosionBlocks.png")
loadImage("brick_gate"             , "media/OtakuBallAnimatedGateBlocks.png")
loadImage("brick_alien"            , "media/OtakuBallAnimatedAlienBlocks.png")
loadImage("brick_factory"          , "media/FactoryBlockHitAnimation.png")
loadImage("brick_onix"             , "media/OtakuBallOnixBlocksAniamted.png")
loadImage("brick_led"              , "media/OtakuBallAnimatedLED_Blocks.png")
loadImage("brick_tiki"             , "media/OtakuBallAnimatedTikiBlocks.png")
loadImage("brick_jumper"           , "media/OtakuBallJumperBlockAnimation.png")
loadImage("brick_slotmachine"      , "media/OtakuBallSlotBlocksAnimated.png")
loadImage("brick_menacer_coating"  , "media/MenacerCoatingaBlock.png")
loadImage("brick_menacer_green"    , "media/MetallicGreen.png")
loadImage("brick_ghost_shine"      , "media/GhostShine.png")
loadImage("brick_ghost_editor"     , "media/GhostEditor.png")
loadImage("brick_split"            , "media/SplitBrick.png")
loadImage("brick_white"            , "media/WhiteBrick.png")
loadImage("brick_rainbow"          , "media/rainbow1.png")
loadImage("brick_rainbow2"         , "media/rainbow2.png")
loadImage("brick_oneway_editor"    , "media/onewayeditor.png")
loadImage("brick_barrier"          , "media/barrierblock.png")

loadImage("patch_mobile"           , "media/Mobilepatchesnew.png")
loadImage("patch_mobile_hit"       , "media/Mobilepatcheshit.png")
loadImage("patch_antilaser"        , "media/OtakuBallAntiLaserPatch.png")

loadImage("brick_snapper"          , "media/OtakuBallSnapper.png")
loadImage("shield_shine"           , "media/OtakuBallBlockShieldHit.png")

loadImage("explosion"              , "media/ExplosionBlockBlast.png")
loadImage("explosion_smoke"        , "media/ExplosionSmoke.png")
loadImage("explosion_smoke_freeze" , "media/ExplosionSmokeFreeze.png")
loadImage("explosion_smoke_mega"   , "media/ExplosionSmokeMega.png")
-- loadImage("rapidfire_bullet"       , "media/OtakuBallRapidFireProjectileSprite.png")
loadImage("shotgun_pellet"         , "media/OtakuBallShotgunSprite.png")
loadImage("comet"                  , "media/CometArrows.png")
loadImage("comet_ember"            , "media/OtakuBallCometBlockEmber.png")
loadImage("ballcannon_large"       , "media/OtakuBallBallCannonBalllargecopy.png")
loadImage("ballcannon_small"       , "media/OtakuBallBallCannonBall.png")
loadImage("drill_missile"          , "media/OtakuBallDrillMissle.png")
loadImage("drill_vendetta"         , "media/OtakuBallVendetta.png")
loadImage("missile"                , "media/OtakuBallNormalandEraticMissiles.png")
loadImage("lasereye_laser"         , "media/LazereyeBlockSprite.png")
loadImage("quasar"                 , "media/OtakuBallQuasar.png")
loadImage("boulder"                , "media/OtakuBallBoulderBlockDebris.png")
loadImage("energy_ball"            , "media/OtakuBallEnergyBall.png")
loadImage("whisky_bubbles"         , "media/OtakuBallWhiskyBubbles.png")
loadImage("javelin"                , "media/OtakuBallJavelin.png")
loadImage("wet_storm"              , "media/OtakuBallWetStorm.png")
loadImage("lasers"                 , "media/lasers.png")
loadImage("gelato"                 , "media/GelatoPower.png")
loadImage("knocker"                , "media/knocker.png")
loadImage("probe"                  , "media/OtakuBallProbe.png")
loadImage("blossom"                , "media/blossombullet.png")
loadImage("assist"                 , "media/Assist.png")

loadImage("rapidfire_bullet" , "media/RapidfireLazers.png")
loadImage("buzzer" , "media/Buzzer.png")

loadImage("control"                , "media/ControlCross2.png")
cursors["control"] = love.mouse.newCursor("media/ControlCross2.png", 32, 32)


--default paddle and brick hit sounds
loadSound("paddlehit"        , "audio/gameplay/Paddle Bounce.wav")
loadSound("blockhit"         , "audio/gameplay/Block Armor.wav")
loadSound("blockbreak"       , "audio/gameplay/Block Destroyed.wav")
loadSound("paddledeath"      , "audio/gameplay/Paddle Death 1.wav")
loadSound("paddledeath2"     , "audio/gameplay/Paddle Death 2.wav")

loadSound("paddlecatch"      , "audio/gameplay/Paddle Catches Ball.wav")
loadSound("alienhit"         , "audio/gameplay/AlienBlockHit.wav")
loadSound("aliendeath"       , "audio/gameplay/AlienBlockDeath.wav")
loadSound("detonator"        , "audio/gameplay/Bomber Block.wav")
loadSound("boulderbreak"     , "audio/gameplay/Boulder Block Break.wav")
loadSound("dividehit"        , "audio/gameplay/Divide Block Hit.wav")
loadSound("icedetonator"     , "audio/gameplay/Ice Bomber Block.wav")
loadSound("invisreveal"      , "audio/gameplay/Reveal Invisible Block.wav")
loadSound("speeddownbrick"   , "audio/gameplay/Speeddown Block.wav" )
loadSound("speedupbrick"     , "audio/gameplay/Speedup Block.wav" )
loadSound("tikihit"          , "audio/gameplay/TikiBlock.wav")
loadSound("gateenter1"       , "audio/gameplay/GateBlockentry1.wav")
loadSound("gateenter2"       , "audio/gameplay/GateBlockentry2.wav")
loadSound("bomber"           , "audio/gameplay/Bomber Balls.wav")
loadSound("stalemate"        , "audio/gameplay/Powerup Deposited.wav")
loadSound("slothit"          , "audio/gameplay/Slot Block Hit.wav")
loadSound("slotmatch"        , "audio/gameplay/Slot Block Match.wav")
loadSound("boardsaved"       , "audio/gameplay/BoardSaved.ogg")
loadSound("menacerdeath"     , "audio/gameplay/Menacer Death.wav")
loadSound("menacercoat"      , "audio/gameplay/Menacer Ball Converts Block.wav")
loadSound("antilaser"        , "audio/gameplay/Antilaser Reflect.wav")
loadSound("enemydeath"       , "audio/gameplay/Enemy Death.wav")

loadSound("beam"             , "audio/powerup/Beam.wav")
loadSound("beamcollected"    , "audio/powerup/Beam Collected.wav")
loadSound("iceballfreeze"    , "audio/powerup/Block Frozen.wav")
loadSound("armbomberball"    , "audio/powerup/Bomber Ball Activated.wav")
loadSound("bypass"           , "audio/powerup/Bypass.wav")
loadSound("bypassexit"       , "audio/powerup/Bypass Exit.wav")
loadSound("cannonball"       , "audio/powerup/Cannon Blast.wav")
loadSound("comboball"        , "audio/powerup/Combo.wav")
loadSound("drill"            , "audio/powerup/DrillMissile.wav")
loadSound("drillexplode"     , "audio/powerup/DrillMissileExplode.wav")
loadSound("gigaball"         , "audio/powerup/Giga Ball.wav")
loadSound("haha"             , "audio/powerup/Haha.mp3")
loadSound("javelinfire"      , "audio/powerup/Javelin Fired.wav")
loadSound("javelincharge"    , "audio/powerup/JavelinCharge.wav")
loadSound("joker"            , "audio/powerup/Joker.wav")
loadSound("kamikaze"         , "audio/powerup/Kamikaze.wav")
loadSound("largeball"        , "audio/powerup/Large Ball.wav")
loadSound("laser"            , "audio/powerup/Laser.wav")
loadSound("laserplus"        , "audio/powerup/LaserPlus.wav")
loadSound("oneup"            , "audio/powerup/Player 1UP.wav")
loadSound("rapidfire"        , "audio/powerup/Rapidfire.wav")
loadSound("missile"          , "audio/powerup/Missile Weapon.wav")
loadSound("erraticmissile"   , "audio/powerup/Erratic Missile.wav")
loadSound("shotgun"          , "audio/powerup/Shotgun.wav")
loadSound("smallsplit"       , "audio/powerup/Small Divide.wav")
loadSound("snapperplaced"    , "audio/powerup/Snapper Placed.wav")
loadSound("transform"        , "audio/powerup/Transform.wav")
loadSound("vector"           , "audio/powerup/Vector.wav")
loadSound("voltcollected"    , "audio/powerup/Volt Collected.wav")
loadSound("volt"             , "audio/powerup/Volt.wav")
loadSound("xbomblaunch"      , "audio/powerup/XBombLaunched.wav")
loadSound("xbombexplode"     , "audio/powerup/XBombDetonates.wav")
loadSound("rocket"           , "audio/powerup/Rocket.wav")
loadSound("barrier"          , "audio/powerup/Barrier.wav")
loadSound("buzzer"           , "audio/powerup/Buzzer Launched.wav")
loadSound("gelato"           , "audio/powerup/Gelato.wav")
loadSound("raindrop"         , "audio/powerup/Wet Storm Raindrop.wav")
loadSound("change"           , "audio/powerup/Change.wav")
loadSound("laceration"       , "audio/powerup/Laceration.wav")
loadSound("lock"             , "audio/powerup/Lock.wav")
loadSound("luck"             , "audio/powerup/Luck.wav")
loadSound("quake"            , "audio/powerup/Quake.wav")
loadSound("unification"      , "audio/powerup/Unification.wav")
loadSound("freeze"           , "audio/powerup/Freeze.wav")
loadSound("bulk"             , "audio/powerup/Bulk.wav")
loadSound("ballcannonshot"   , "audio/powerup/Ball Cannon.wav")
loadSound("cannonprep"       , "audio/powerup/Cannon Collect-Wait.wav")
loadSound("illusionhit"      , "audio/powerup/Illusion Paddle Hit.wav")
loadSound("nanolaunch"       , "audio/powerup/Nano Ball Launch.wav")
loadSound("nanocatch"        , "audio/powerup/Nano collected.wav")
loadSound("node"             , "audio/powerup/Node Split.wav")
loadSound("tractor"          , "audio/powerup/Tractor.wav")
loadSound("ultraviolet"      , "audio/powerup/Ultraviolet Block Burst.wav")
loadSound("microwave"        , "audio/powerup/Ultraviolet Collected.wav")
loadSound("reserve"          , "audio/powerup/Re-Serve.wav")
loadSound("knocker"          , "audio/powerup/Knocker.wav")
loadSound("oldie"            , "audio/powerup/Oldie.wav")
loadSound("pausecollected"   , "audio/powerup/Pause Collected.wav")
loadSound("pauseactivated"   , "audio/powerup/Pause Activated.wav")
loadSound("ghost"            , "audio/powerup/Ghost.wav")
loadSound("xbombcollected"   , "audio/powerup/X Bomb Collected.wav")
loadSound("shotguncollected" , "audio/powerup/Shotgun Collected.wav")
loadSound("weak"             , "audio/powerup/Weak.wav")
loadSound("particle"         , "audio/powerup/Particle Ball.wav")
loadSound("disarm"           , "audio/powerup/Disarm.wav")
loadSound("energy"           , "audio/powerup/Energy.wav")
loadSound("hackercollected"  , "audio/powerup/Hacker Collected.wav")
loadSound("iceballcollect"   , "audio/powerup/Ice Ball.wav")
loadSound("indigestion"      , "audio/powerup/Indigestion.wav")
loadSound("poison"           , "audio/powerup/Poison.wav")
loadSound("shadow"           , "audio/powerup/Shadow.wav")
loadSound("yoyoga"           , "audio/powerup/Yoyo Yoga.wav")
loadSound("control"          , "audio/powerup/Control Deployed.wav")
loadSound("glue"             , "audio/powerup/Glue.wav")
loadSound("assistopen"       , "audio/powerup/Assist Collected.wav")
loadSound("open"             , "audio/powerup/Open.wav")
loadSound("antigravity"      , "audio/powerup/AntiGravity.wav")
loadSound("attract"          , "audio/powerup/Attract and Magnet.wav")
loadSound("bomberfuse"       , "audio/powerup/Bomber Ball Looped.wav")
loadSound("drillcollected"   , "audio/powerup/Drill Missile Pickup.wav")
loadSound("gravity"          , "audio/powerup/Gravity.wav")
loadSound("illusion"         , "audio/powerup/Illusion.wav")
loadSound("irritate"         , "audio/powerup/Irritate.wav")
loadSound("jewel"            , "audio/powerup/Jewel.wav")
loadSound("junk"             , "audio/powerup/Junk.wav")
loadSound("missilecollected" , "audio/powerup/Missile and Eratic M Pickup.wav")
loadSound("orbit"            , "audio/powerup/Orbit.wav")
loadSound("voodoo"           , "audio/powerup/Voodoo.wav")
loadSound("whisky"           , "audio/powerup/Whisky.wav")
loadSound("undead"           , "audio/powerup/Undead.wav")
loadSound("heavenhit"        , "audio/powerup/Heaven Paddle Hit.wav")
loadSound("nervous"          , "audio/powerup/Nervous.wav")
loadSound("intshadow"        , "audio/powerup/Intelligent Shadow.wav")
loadSound("invert"           , "audio/powerup/Invert Ricochets.wav")
loadSound("cannoncollected"  , "audio/powerup/Cannon Equipped.wav")
loadSound("domino"           , "audio/powerup/Domino Pickup.wav")
loadSound("lasercollected"   , "audio/powerup/Laser Equipped.wav")
loadSound("trail"            , "audio/powerup/Trail.wav")
loadSound("sightlaser"       , "audio/powerup/Sight Laser.wav")
loadSound("weight"           , "audio/powerup/Weight.wav")

loadSound("blackout"         , "audio/new/Blackout.wav")
loadSound("combopickup"      , "audio/new/Combo pickup.wav")
loadSound("drop"             , "audio/new/Drop Pickup.wav")
loadSound("halo"             , "audio/new/Halo and Heaven.wav")
loadSound("invertpickup"     , "audio/new/Invert Pickup.wav")
loadSound("protect"          , "audio/new/Protect.wav")
loadSound("quasar"           , "audio/new/Quasar.wav")
loadSound("terraform"        , "audio/new/Terraform.wav")
loadSound("undestructable"   , "audio/new/Undestructable.wav")
loadSound("xray"             , "audio/new/Xray.wav")
loadSound("yreturn"          , "audio/new/Y-Return.wav")

loadSound("acidball"         , "audio/powerup/ricochet/Acid Ball.wav")
loadSound("generatorball"    , "audio/powerup/ricochet/Ball Generator Ball.wav")
loadSound("catchactivated"   , "audio/powerup/ricochet/Catch Activated.wav")
loadSound("armemp"           , "audio/powerup/ricochet/EMP Bomb Ball.wav")
loadSound("extend"           , "audio/powerup/ricochet/Extend.wav")
loadSound("fast"             , "audio/powerup/ricochet/Fast.wav")
loadSound("fireball"         , "audio/powerup/ricochet/Fire Ball.wav")
loadSound("largesplit"       , "audio/powerup/ricochet/Large Divide.wav")
loadSound("laserball"        , "audio/powerup/ricochet/Laser Ball.wav")
loadSound("mediumsplit"      , "audio/powerup/ricochet/Medium Divide.wav")
loadSound("megaball"         , "audio/powerup/ricochet/Mega Ball.wav")
loadSound("reset"            , "audio/powerup/ricochet/Normal Ball Ship Reset.wav")
loadSound("restrict"         , "audio/powerup/ricochet/Restrict.wav")
loadSound("slow"             , "audio/powerup/ricochet/Slow.wav")
loadSound("small"            , "audio/powerup/ricochet/Small Ball.wav")
loadSound("triggerdeton"     , "audio/powerup/ricochet/T Detonator and T Launcher Turned Off.wav")
loadSound("triggerdetoff"    , "audio/powerup/ricochet/T Detonator and T Launcher Turned On.wav")




--quads are required to be tied to an image
--rects are just simple tables with (x, y, w, h)
--partition rects

local mt = {}
mt.__index = function(t, k)
	if k == "x" then
		return t[1]
	elseif k == "y" then
		return t[2]
	elseif k == "w" then
		return t[3]
	elseif k == "h" then
		return t[4]
	else
		return rawget(t, k)	end
end

function make_rect(x, y, w, h)
	local r = {x, y, w, h}
	setmetatable(r, mt)
	return r
end

rects.bg = {}
for i = 1, 20 do
	rects.bg[i] = {}
	for j = 1, 5 do
		rects.bg[i][j] = make_rect((j-1)*32, (i-1)*32, 32, 32)
	end
end

rects.ball = {}
for i = 1, 100 do
	rects.ball[i] = {}
	for j = 1, 100 do
		rects.ball[i][j] = make_rect((j-1)*12, (i-1)*12, 12, 12)
	end
end

rects.ball2 = {}
for i = 1, 10 do
	rects.ball2[i] = {}
	for j = 1, 10 do
		rects.ball2[i][j] = make_rect((j-1)*8, (i-1)*8, 7, 7)
	end
end

rects.ball_large = make_rect(17, 1, 14, 14)

rects.ball_mini = make_rect(24, 16, 3, 3)

rects.paddle = {}
for i = 1, 100 do
	rects.paddle[i] = make_rect(0, (i-1)*8, 64, 8, iw, ih)
end

rects.brick = {}
for i = 1, 100 do
	rects.brick[i] = {}
	for j = 1, 100 do
		rects.brick[i][j] = make_rect((j-1)*16, (i-1)*8, 16, 8)
	end
end

rects.powerup = {}
for i = 1, 100 do
	rects.powerup[i] = {}
	for j = 1, 100 do
		--padding due to a weird graphical glitch
		rects.powerup[i][j] = make_rect((j-1)*16+0.001, (i-1)*8, 16-0.001, 8)
	end
end

rects.whisky =
{
	make_rect(1, 1, 9, 9),
    make_rect(11, 2, 7, 7),
    make_rect(19, 3, 6, 6),
    make_rect(26, 4, 4, 4)
}

rects.score = {}
local names = {"100", "200", "400", "500", "1000", "2000", "4000", "5000", "1up"}
local index = 1

for j = 1, 3 do
	for i = 1, 3 do
		rects.score[names[index]] = make_rect((j-1)*17, (i-1)*8, 15, 6)
		index = index + 1
	end
end

rects.laser =
{
	regular       = make_rect(0, 0, 3, 10),
	plus          = make_rect(3, 0, 4, 10),
	ball          = make_rect(7, 0, 3, 7),
	shooter_red   = make_rect(0, 11, 2, 5),
	shooter_green = make_rect(2, 11, 2, 7),
	shooter_blue  = make_rect(4, 11, 4, 9)
}

rects.assist = {
	base  = make_rect(0, 0, 22, 22),
	gun   = make_rect(23, 10, 6, 8),
	laser = make_rect(23, 0, 6, 8)
}

rects.menacer_editor = {
	redgreen = make_rect(0, 12, 24, 12),
	red = make_rect(0, 12, 12, 12),
	green = make_rect(12, 12, 12, 12),
	cyan = make_rect(24, 12, 12, 12),
	bronze = make_rect(0, 24, 12, 12),
	silver = make_rect(12, 24, 12, 12),
	pewter = make_rect(24, 24, 12, 12)
}

rects.enemy = {
	dizzy = {},
	cubic = {},
	gumball = {normal = {}, split = {}},
	walkblock = {},
	death = {}
}
for i = 1, 8 do
	local x, y, w, h = 3 + 16*(i-1), 0, 10, 16
	rects.enemy.dizzy[i] = make_rect(x, y, w, h)
end

for i = 1, 8 do
	local x, y, w, h = 0 + 16*(i-1), 16, 15, 16
	rects.enemy.cubic[i] = make_rect(x, y, w, h)
end

for i, color in ipairs({"red", "yellow", "blue"}) do
	local g = rects.enemy.gumball
	g.normal[color] = {}
	g.split[color] = {}
	for j = 1, 3 do
		g.normal[color][j] = make_rect(49 + 7*(i-1), 33 + 7*(j-1), 6, 6)
	end
	for j = 1, 8 do
		g.split[color][j] = make_rect(81 + 7*(j-1), 33 + 7*(i-1), 6, 6)
	end
end

for i, dir in ipairs({"down", "diagonal", "left"}) do
	local w = rects.enemy.walkblock
	w[dir] = {}
	for j = 1, 3 do
		w[dir][j] = make_rect(0 + (i-1)*16, 32 + (j-1)*16, 16, 16)
	end
end

for i = 1, 5 do
	rects.enemy.death[i] = make_rect(0 + 16*(i-1), 80, 16, 16)
end

rects.enemy_editor = {
	dizzy = make_rect(0, 0, 12, 12),
	cubic = make_rect(12, 0, 12, 12),
	gumballtrio = make_rect(24, 0, 12, 12),
	walkblock = make_rect(36, 0, 12, 12),
}

rects.icon = {}
for i = 1, 5 do
	rects.icon[i] = {}
	for j = 1, 3 do
		rects.icon[i][j] = make_rect(16*(j-1), 16*(i-1), 16, 16)
	end
end
rects.icon.play = {}
rects.icon.stop = {}
for i = 1, 3 do
	rects.icon.play[i] = make_rect(2,  35 + 16*(i-1), 12, 11)
	rects.icon.stop[i] = make_rect(18, 35 + 16*(i-1), 12, 11)
end

rects.map = {char = {}, icon = {}}
local icon, char = rects.map.icon, rects.map.char
for i = 1, 3 do
	icon[i] = {}
	for j = 1, 26 do
		icon[i][j] = make_rect(26*(j-1), 26*(i-1), 26, 26)
	end
end
for i = 1, 4 do
	char[i] = {}
	for j = 1, 3 do
		char[i][j] = make_rect(21*(j-1), 16*(i-1), 21, 16)
	end
end


--right side determines the duration in which the animation stays on that frame
--left side is the quad of the image to display

--powerup animations
rects.powerup_ordered = {}
local row, col
for i = 0, 134 do
	local str = "P"..(i+1)
	if i < 80 then
		row = i % 40
		col = math.floor(i / 40)
	else
		row = (i - 80) % 37
		col = math.floor((i - 80) / 37) + 2
	end
	rects.powerup_ordered[i+1] = rects.powerup[row+1][col+1+(8*4)]
	ani[str] = {imgstr = "powerup_spritesheet"}
	for j = 0, 16 do
		local jj = (j + 8) % 17
		table.insert(ani[str], {rects.powerup[row+1][col+1+(jj*4)], 0.05})
	end
end

--powerup score animations
local names = {"200", "500", "2000", "1UP"}
for i, v in ipairs(names) do
	local str = "PowerUp"..v
	ani[str] = {imgstr = "powerup_score"}
	for j = 1, 5 do
		table.insert(ani[str], {make_rect((j-1)*32, (i-1)*16, 24, 16), 0.075})
	end
	for j = 4, 2, -1 do
		table.insert(ani[str], {make_rect((j-1)*32, (i-1)*16, 24, 16), 0.075})
	end
end

--enemy animations
ani["Dizzy"] = {imgstr = "enemy"}
for i = 1, 8 do
	table.insert(ani["Dizzy"], {rects.enemy.dizzy[i], 0.15})
end
ani["Cubic"] = {imgstr = "enemy"}
for i = 1, 8 do
	table.insert(ani["Cubic"], {rects.enemy.cubic[i], 0.2})
end
for i, n in ipairs({"Down", "Diagonal", "Left"}) do
	local str1 = string.lower(n)
	local str2 = "WalkBlock"..n
	ani[str2] = {imgstr = "enemy"}
	table.insert(ani[str2], {rects.enemy.walkblock[str1][1], 0.25})
	table.insert(ani[str2], {rects.enemy.walkblock[str1][2], 0.25})
	table.insert(ani[str2], {rects.enemy.walkblock[str1][3], 0.25})
	table.insert(ani[str2], {rects.enemy.walkblock[str1][2], 0.25})
end
local names = {"Red", "Yellow", "Blue"}
for i = 1, 3 do
	local blink = names[i].."GumballBlink"
	local split = names[i].."GumballSplit"
	ani[blink] = {imgstr = "enemy"}
	local r = rects.enemy.gumball.normal[names[i]:lower()]
	table.insert(ani[blink], {r[1], 0.5})
	table.insert(ani[blink], {r[2], 0.5})
	table.insert(ani[blink], {r[3], 0.5})
	ani[split] = {imgstr = "enemy"}
	local r = rects.enemy.gumball.split[names[i]:lower()]
	for j = 1, 8 do
		table.insert(ani[split], {r[j], 0.1})
	end
end
local addRect = function(a, b)
	table.insert(ani["EnemyDeath"..a], {rects.enemy.death[b], 1/30})
end
for i = 1, 3 do
	ani["EnemyDeath"..i] = {imgstr = "enemy"}
	for j = i, 4 do
		addRect(i, j)
		addRect(i, 5)
	end
end
--brick animations
local names = {"BlueFunky", "GreenFunky", "RedFunky", "Gold",
			   "BronzeMetal", "SilverMetal", "BlueMetal", "PinkMetal", "PurpleMetal", "GreenMetal",
			   "PlatedGold", "SpeedUpGold", "SlowDownGold", "Platinum"}

for i, v in ipairs(names) do
	local str = v.."Shine"
	ani[str] = {imgstr = "brick_shine"}
	for j = 1, 7 do
		table.insert(ani[str], {rects.brick[j][i], 0.05})
	end
end

local names = {"Copper", "RedFlip", "GreenFlip", "BlueFlip", "PurpleFlip", "OrangeFlip",
			   "Menacer", "RedShooter", "GreenShooter", "BlueShooter"}

for i, v in ipairs(names) do
	local str = v.."Shine"
	ani[str] = {imgstr = "brick_shine2"}
	for j = 1, 7 do
		table.insert(ani[str], {rects.brick[j][i], 0.05})
	end
end

local names = {"BlueFunky", "GreenFunky", "RedFunky", "RedShooter", "GreenShooter", "BlueShooter"}

for i, v in ipairs(names) do
	local str = v.."Regen"
	ani[str] = {imgstr = "brick_regen"}
	for j = 1, 8 do
		table.insert(ani[str], {rects.brick[j][i], 0.033})
	end
end

local names = {"Right", "Left", "Down", "Up"}
local names2 = {Fast = 0.1, Medium = 0.2, Slow = 0.4}

for i, dir in ipairs(names) do
	for spd, delay in pairs(names2) do
		local str = "Conveyor"..dir..spd
		ani[str] = {imgstr = "brick_spritesheet"}
		for j = 23, 25 do
			table.insert(ani[str], {rects.brick[i][j], delay})
		end
	end
end

local names = {"Detonator", "NeoDetonator", "FreezeDetonator", "LeftComet", "RightComet", "HorizontalComet", "VerticalComet", "ShoveDetonator"}

for i, v in ipairs(names) do
	local str = v.."Glow"
	ani[str] = {imgstr = "brick_glow"}
	for j = 1, 10 do
		table.insert(ani[str], {rects.brick[j][i], 0.065})
	end
	for j = 9, 2, -1 do
		table.insert(ani[str], {rects.brick[j][i], 0.065})
	end
end

local names = {"LaserEye", "TriggerDetonator", "BlueTwinLauncher", "YellowTwinLauncher"}

for i, v in ipairs(names) do
	local str = v.."Glow"
	ani[str] = {imgstr = "brick_led"}
	for j = 1, 4 do
		table.insert(ani[str], {rects.brick[j][i], 0.075})
	end
	for j = 3, 2, -1 do
		table.insert(ani[str], {rects.brick[j][i], 0.075})
	end
end

local names = {"Red", "Blue", "Green", "Orange"}

for i, v in ipairs(names) do
	local str = v.."GateFlash"
	ani[str] = {imgstr = "brick_gate"}
	for j = 1, 7 do
		local ii, jj
		if j % 2 == 1 then ii, jj = 1, i else ii, jj = 2, i end
		table.insert(ani[str], {rects.brick[ii][jj], 0.5/7})
	end
	str = "Dark"..str
	ani[str] = {imgstr = "brick_gate"}
	for j = 1, 7 do
		local ii, jj
		if j % 2 == 1 then ii, jj = 1, 4+i else ii, jj = 2, i end
		table.insert(ani[str], {rects.brick[ii][jj], 0.5/7})
	end
end

local names = {"Green", "Yellow", "Red"}

for i = 1, 3 do
	str = names[i].."FactoryFlash"
	ani[str] = {imgstr = "brick_factory"}
	for j = 1, 3 do
		table.insert(ani[str], {rects.brick[j][i], 0.05})
	end
	for j = 2, 1, -1 do
		table.insert(ani[str], {rects.brick[j][i], 0.05})
	end
end

local names = {"Full", "BottomRight", "BottomLeft", "TopRight", "TopLeft"}

for i, v in ipairs(names) do
	local str = v.."OnixShine"
	ani[str] = {imgstr = "brick_onix"}
	for j = 1, 6 do
		table.insert(ani[str], {rects.brick[j][i], 0.05})
	end
end

ani["TikiFlash"] = {imgstr = "brick_tiki"}
for i = 1, 5 do
	table.insert(ani["TikiFlash"], {rects.brick[i][1], 0.075})
end

for i = 1, 3 do
	local str = "Jumper"..i
	ani[str] = {imgstr = "brick_jumper"}
	for j = 1, 14 do
		table.insert(ani[str], {rects.brick[j][i], 0.05})
	end
end

local names = {"Blue", "Yellow"}

for i, v in ipairs(names) do
	local str = v.."SlotMachine"
	ani[str] = {imgstr = "brick_slotmachine"}
	table.insert(ani[str], {rects.brick[2][i], 0.125})
	table.insert(ani[str], {rects.brick[1][i], 0.125})
end

ani["SnapperMine"] = {imgstr = "brick_snapper"}
for i = 1, 5 do
	table.insert(ani["SnapperMine"], {rects.brick[i][1], 0.1})
end
for i = 4, 2, -1 do
	table.insert(ani["SnapperMine"], {rects.brick[i][1], 0.1})
end

local names = {"ShieldRight", "ShieldLeft", "ShieldDown", "ShieldUp"}

for i, v in ipairs(names) do
	ani[v] = {imgstr = "shield_shine"}
	local j0, j1
	if i % 2 == 1 then
		j0, j1 = 1, 9
	else
		j0, j1 = 2, 10
	end
	i = math.floor((i+1)/2)
	for j = j0, j1, 2 do
		table.insert(ani[v], {rects.brick[j][i], 0.03})
	end
	for j = j1 - 2, j0, -2 do
		table.insert(ani[v], {rects.brick[j][i], 0.03})
	end
end

local names = {"Bronze", "Silver", "Green"}
for i, v in ipairs(names) do
	local str = v.."Coating"
	ani[str] = {imgstr = "brick_menacer_coating"}
	for j = 1, 7 do
		table.insert(ani[str], {rects.brick[j][i], 0.1})
	end
end

ani["GreenShine"] = {imgstr = "brick_menacer_green"}
for i = 1, 7 do
	table.insert(ani["GreenShine"], {rects.brick[i][1], 0.05})
end

ani["GhostShine"] = {imgstr = "brick_ghost_shine"}
for i = 1, 5 do
	table.insert(ani["GhostShine"], {rects.brick[i][1], 0.05})
end

ani["RedSplitGlow"] = {imgstr = "brick_split"}
for i = 5, 1, -1 do
	table.insert(ani["RedSplitGlow"], {rects.brick[i][2], 0.065})
end
for i = 2, 4 do
	table.insert(ani["RedSplitGlow"], {rects.brick[i][2], 0.065})
end

ani["RedBlueSplit"] = {imgstr = "brick_split"}
for i = 1, 3 do
	table.insert(ani["RedBlueSplit"], {make_rect(0, 40 + (i-1)*8, 48, 8), 0.05})
end

ani["BlueSplitGlow"] = {imgstr = "brick_split"}
for i = 6, 1, -1 do
	table.insert(ani["BlueSplitGlow"], {rects.brick[i+8][3], 0.065})
end
for i = 2, 5 do
	table.insert(ani["BlueSplitGlow"], {rects.brick[i+8][3], 0.065})
end

ani["BlueSplitShine"] = {imgstr = "brick_split"}
for i = 1, 6 do
	table.insert(ani["BlueSplitShine"], {rects.brick[i+8][1], 0.05})
end

--Title Brick Shine
local indices = {{1,1}, {2,1}, {3,1}, {2,2}, {3,2}, {2,3}, {3,3}, {2,4}, {3,4}}
for i, v in ipairs(indices) do
	local t = {imgstr = "brick_title2"}
	for j = 1, 4 do
		table.insert(t, {rects.brick[v[1]][v[2]+(j-1)*4], 0.05})
	end
	for j = 3, 2 do
		table.insert(t, {rects.brick[v[1]][v[2]+(j-1)*4], 0.05})
	end
	ani["TitleBrickShine"..i] = t
end

--misc animations
local names = {"Explosion", "FreezeExplosion"}

for i, v in ipairs(names) do
	local str = v
	ani[str] = {imgstr = "explosion"}
	for j = 1, 8 do
		local r = make_rect((i-1)*48, (j-1)*24, 48, 24)
		table.insert(ani[str], {r, 0.04})
	end
end

ani["DrillMissile"] = {imgstr = "drill_missile"}
for i = 1, 42 do
	table.insert(ani["DrillMissile"], {make_rect(16*(i-1), 0, 16, 41), 0.075})
end

ani["DrillVendetta"] = {imgstr = "drill_vendetta"}
for i = 1, 42 do
	table.insert(ani["DrillVendetta"], {make_rect(0, 16*(i-1), 41, 16), 0.075})
end

local names = {"RegularMissile", "ErraticMissile"}
for i, v in ipairs(names) do
	ani[v] = {imgstr = "missile"}
	for j = 1, 3 do
		local r = make_rect((j-1)*16, (i-1)*40, 16, 40)
		table.insert(ani[v], {r, 0.1})
	end
end

ani["Invert"] = {imgstr = "invert"}
for i = 1, 5 do
	table.insert(ani["Invert"], {make_rect(9*(i-1), 0, 9, 26), 0.1})
end

local names = {"Idle", "FistPump", "WalkForward", "WalkBackward"}
local char = rects.map.char
for i, v in ipairs(names) do
	local fullname = "OtakuBall"..v
	ani[fullname] = {imgstr = "campaign_char"}
	if v == "Idle" then
		table.insert(ani[fullname], {char[1][1], 0.15})
		table.insert(ani[fullname], {char[1][3], 0.15})
		table.insert(ani[fullname], {char[1][1], 0.15})
		table.insert(ani[fullname], {char[1][2], 0.45})
		for i = 1, 3 do
			table.insert(ani[fullname], {char[1][1], 0.45})
			table.insert(ani[fullname], {char[1][2], 0.45})
		end
	elseif v == "FistPump" then
		for i = 1, 3 do
			table.insert(ani[fullname], {char[2][i], 0.15})
		end
	elseif v == "WalkForward" then
		for i = 1, 3 do
			table.insert(ani[fullname], {char[3][i], 0.2})
		end
	else --WalkBackward
		for i = 1, 3 do
			table.insert(ani[fullname], {char[4][i], 0.2})
		end
	end
end



