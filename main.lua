
editor_backup = 5
time_scale = 1
showforbidden = false --turn on to make forbidden bricks visible
prefs = {}

--love.graphics.setColor() now is range 0-1 instead of 0-255
--THANKS VERSION 11
function legacySetColor(r, g, b, a)
	if type(r) == "table" then
		legacySetColor(r[1], r[2], r[3], r[4])
		return
	end
	if not a then
		a = 255
	end
	love.graphics.setColor(r/255, g/255, b/255, a/255)
end


local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

--all sprites are scaled 2x
--a single brick is 32 pixels wide and 16 pixels high
--a powerup is the same size as a brick
--a regular ball has a radius of 7 pixels
--the game board is 13 bricks wide and 32 bricks high
window = {w = 800, h = 600}
window.deskw, window.deskh = love.window.getDesktopDimensions()
window.lwallx = 192 --(800 - 32*13) / 2
window.rwallx = window.w - window.lwallx
window.ceiling = 88
window.ceil = window.ceiling
window.wallw = window.lwallx
window.boardw = window.rwallx - window.lwallx
window.boardh = window.h - window.ceiling
window.setFullscreen = function(self, v)
	if v then
		if not self.fullscreen then
			local f = {}
			f.scale = window.deskh/window.h
			love.window.setFullscreen(true, "desktop")
			f.offset = (window.deskw - window.w*f.scale) / 2
			self.fullscreen = f
		end
	else
		if self.fullscreen then
			love.window.setFullscreen()
			self.fullscreen = nil
		end
	end
end

--this affects paddle movement
--may be expanded so that the keyboard can navigate buttons
control_mode = "mouse" --mouse, keyboard, smart_keyboard
paddle_speed = 500 --paddle speed for keyboard only (mouse has infinite speed)
global_cursor = nil
difficulty = "normal"

cheats = {
	no_pit = false,
	enemy_debug = false,
}

--disable this in order to get better error messages
require("lovedebug")

class = require("middleclass")
require("my_util")
vector = require("hump.vector") --I only used this for hardoncollider.sat
-- HC = require("hardoncollider")
shapes = require("hardoncollider.shapes")

recentTrace = "empty"
function saveTraceback()
	recentTrace = debug.traceback()
end

function printBox(box)
	print(box[1], box[2], box[3], box[4])
end

function shapes.newRectangleShape(x, y, w, h)
	return shapes.newPolygonShape(x,y, x+w,y, x+w,y+h, x,y+h)
end


--IMPORTANT
--Due to a recent MACOSX update, the love.filesystem.lines() function no longer works on Mac
--Therefore I will replace that function with readlines() in hopes of making the game
--  compatible again.
function readlines(file)
	local str = love.filesystem.read(file)
	local t = {}
	--this ignores empty lines(i don't know how to make it not ignore it)
	--may cause problems in Playlist Select
	for s in str:gmatch("[^\r\n]+") do
		table.insert(t, s)
	end
	return t
end

function saveTest()
	print("Creating file text.txt...")
	local file = love.filesystem.newFile("test.txt")
	file:open("w")
	file:write("this is a test")
	file:close()

	local path = love.filesystem.getSaveDirectory()

	local check = love.filesystem.getInfo("test.txt")
	if check then 
		print("Sucessfully written to computer!")
		print("Please check "..path.." to verify existence of test.txt")
	else
		print("ERROR: File not found! I have failed you...")
	end
end

function generatePlaylist(n, start, finish)
	local file = love.filesystem.newFile("playlists/_Zone"..n)
	file:open("w")
	for i = start, finish do
		local s = ""..i
		if #s == 1 then s = "0"..s end
		file:write("_Round"..n..s.."\n")
	end
	file:close()
end

function loadPreferences()
	local chunk = love.filesystem.load("preferences.lua")
	if chunk then
		prefs = chunk()
	end
	if not prefs.volume then prefs.volume = 20 end
	love.audio.setVolume(prefs.volume/100)
	if not prefs.hide_default then 
		prefs.hide_default = false
	end
end

function savePreferences()
	local file = love.filesystem.newFile("preferences.lua")
	file:open("w")
	file:write("local data = {\n")
	for k, v in pairs(prefs) do
		file:write("\t"..k.." = "..tostring(v)..",\n")
	end
	file:write("}\nreturn data")
end

shapeTypes = {"polygon", "compound", "circle", "point"}

 --not really called by any of my scripts
gameTypes = {"paddle", "ball", "brick", "projectile", "powerup", "particle", "environment"}

--this specifies the order in which the objects are updated (however it shouldn't really matter)
--paddle is updated the last
listTypes = {"balls", "bricks", "projectiles", "powerups", "callbacks", "particles", "environments", "menacers", "enemies"}

--adds an object to an object queue in order to not interfere with any iteration
--make sure its a valid list in the game

function love.load(arg)
	--setcolor test

	love.window.setMode(window.w, window.h, {borderless = false, vsync = false})
	love.filesystem.setIdentity("OtakuBall")
	love.window.setTitle("Otaku-Ball")
	math.randomseed(os.time())
	-- require("lovedebug")
	-- require("my_util")
	require("media")
	require("callback")
	require("sprite")
	require("ball")
	require("projectile")
	require("paddle")
	require("bricks/_init")
	require("powerup")
	require("particle")
	require("environment")
	require("monitor")
	require("enemy")
	require("menacer")
	require("game")
	require("gui")
	require("documentation")

	love.window.setIcon(assets.icon32)

	loadPreferences()
	powerupGenerator:loadDefault()

	main_canvas = love.graphics.newCanvas(window.w, window.h)
	freeze_canvas = love.graphics.newCanvas(window.w, window.h)
	shadow_canvas = love.graphics.newCanvas(window.w, window.h)
	preview_canvas = love.graphics.newCanvas(208, 256)

	--after this is called, the EditorState class will have two class variables: brickData and brickDataLookup
	EditorState:initBrickData()

	--controls
	mouse = {}
	keys = {}
	love.keyboard.setKeyRepeat(true)

	game:initialize()
	game:push(MainMenuState:new())
end

function love.quit()
	if editorstate then
		editorstate:close() --allows the editorstate to save backups
	end
	savePreferences()
end

--all events are done before love.update()

function love.textinput(text)
	keys.lastText = text
end

function love.keypressed(key, code, isrepeat)
	if isrepeat then
		keys[key] = 2
	else
		keys[key] = 1
	end

	--print(key.." "..code.." "..(isrepeat and "repeat" or "no repeat"))
end

function love.wheelmoved(x, y)
	if y > 0 then mouse.scrollup = true end
	if y < 0 then mouse.scrolldown = true end
end

--before the game updates, both the mouse buttons and keyboard buttons have been accounted for

function love.update(dt)
	global_cursor = nil
	--mouse events
	--m1 == 1 means mouse one is clicked
	--m1 ~= nil means mouse one is down
	local buttons = {m1 = 1, 
					 m2 = 2, 
					 m3 = 3}
	for k, v in pairs(buttons) do
		if love.mouse.isDown(v) then
			if not mouse[k] then mouse[k] = 1 else mouse[k] = 2 end
		else
			mouse[k] = false
		end
	end

	-- if dt < 1/60 then love.timer.sleep(1/60 - dt) end --fps cap for debugging reasons

	mouse.x, mouse.y = love.mouse.getPosition()
	local f = window.fullscreen
	if f then
		mouse.x = mouse.x / f.scale - f.offset / f.scale
		mouse.y = mouse.y / f.scale
	end

	dt = math.min(dt, 1/60) --this makes sure that the game will run at least 60 fps
	game:update(dt)

	for k, v in pairs(keys) do
		keys[k] = nil
	end
	keys.lastText = nil
	mouse.scrollup, mouse.scrolldown = nil, nil

	love.mouse.setCursor(global_cursor)
end

function love.draw()
	love.graphics.push("all")
	love.graphics.setCanvas(main_canvas)
	love.graphics.clear()
	game:draw()
	love.graphics.setFont(font["default"])
	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Pokemon16"])
	love.graphics.print("FPS: "..love.timer.getFPS(), 20, window.h - 15)
	legacySetColor(255, 255, 255, 255)
	love.graphics.pop()
	local f = window.fullscreen
	if f then
		love.graphics.translate(f.offset, 0)
		love.graphics.scale(f.scale)
	end
	love.graphics.draw(main_canvas)
	-- love.graphics.setFont(font["Arcade20"])
	-- love.graphics.print("The quick brown fox jumps over the lazy dog", window.lwallx, window.h/2)
	-- love.graphics.setFont(font["Pokemon20"])
	-- love.graphics.print("The quick brown fox jumps over the lazy dog", window.lwallx, window.h/2 + 100)
end