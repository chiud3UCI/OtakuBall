EditorState = class("EditorState")

function EditorState:resetAllLevels()
	override = true
	local default = love.filesystem.getDirectoryItems("default_levels")
	for i, f in ipairs(default) do
		self:loadBricks(f)
		self:saveBricks("A"..f)
	end
	override = false
end

--save files are lua files that can be executed as a chunk
--when the chunk is executed, it will return a single table that contains data
--  for bricks, menacer spawn, and powerup weights(optional)
function EditorState:saveBricks(filename)
	local tableToString = util.tableToString
	local prefix = ""

	function join(lines)
		local str = ''
		for k, v in pairs(lines) do
			str = str .. prefix .. v .. "\n"
		end
		return str
	end

	-- function tableToString(table)
	-- 	local str = "{"
	-- 	for k, v in pairs(table) do
	-- 		local vstr = tostring(v)
	-- 		if type(v) == "table" then
	-- 			vstr = tableToString(v)
	-- 		elseif type(v) == "string" then
	-- 			vstr = "\""..vstr.."\""
	-- 		end
	-- 		if type(k) == "number" then
	-- 			str = str..vstr..", "
	-- 		else
	-- 			str = str..k.." = "..vstr..", "
	-- 		end
	-- 	end
	-- 	str = str:sub(1, #str - 2).."}"
	-- 	return str
	-- end

	self.lastFile = filename
	local file = love.filesystem.newFile("levels/"..filename)
	file:open("w")

	file:write("local data = {}\n")

	local lines = {"data.bricks = {"}
	for i = 1, 32 do
		for j = 1, 13 do
			local node = self.grid[i][j]
			if node.brickData then
				table.insert(lines, "\t".."{"..i..", "..j..", "..node.id..", "..tableToString(node.patch).."},")
			end
		end
	end
	if #lines > 1 then
		local temp = lines[#lines]
		lines[#lines] = temp:sub(1, #temp - 1)
	end
	table.insert(lines, "}")
	file:write(join(lines))

	--not sure if it is necessary to replace "data.menacer" with "data.enemies"
	local names = self.menacerButton.names
	local line = "data.menacer = {"
	for _, name in pairs(names) do
		line = line..name.." = "..tostring(self.menacerButton.flag[name])..", "
	end
	line = line:sub(1, -3)
	file:write(line.."}\n")

	if not self.menacerButton:checkDefault() then
		local line = "data.menacerTimer = {"
		local t = {self.menacerButton:unpackValues()}
		for i = 2, 4 do
			line = line..t[i]..", "
		end
		line = line:sub(1, -3)
		file:write(line.."}\n")
	end

	file:write("data.config = {}\n")
	file:write("data.config.slot_blue = "..tableToString(game.config.slot_blue).."\n")
	file:write("data.config.slot_yellow = "..tableToString(game.config.slot_yellow).."\n")

	file:write("data.powerup = {\n")
	if self.pBind2.state and not override then
		file:write("\toverall_chance = "..(self.numBox2.num/100)..",\n")
	end
	if self.pBind.state and not override then
		file:write("\tweights = {\n\t\t")
		for i = 1, 135 do
			file:write(self.numBoxes[i].num..", ")
			if i ~= 135 and i % 27 == 0 then 
				file:write("\n\t\t") 
			end
		end
		file:write("\n\t}\n")
	end
	file:write("}\n")

	local bg = self.background
	file:write("data.background = {r = "..bg.r..", g = "..bg.g..", b = "..bg.b.."}\n")
	if bg.tile then
		local t = bg.tile
		file:write("data.background.tile = {imgstr = \""..t.imgstr.."\", i = "..t.i..", j = "..t.j.."}\n")
	end

	file:write("return data")

	file:close()
end

function EditorState:loadBricks(filename)
	local chunk = nil
	if filename:sub(1, 1) == "_" then
		chunk = love.filesystem.load("default_levels/"..filename)
	else
		self.lastFile = filename
		chunk = love.filesystem.load("levels/"..filename)
	end
	if not chunk then
		print("ERROR: file \""..filename.."\" not found")
		self.lastFile = nil
		return
	end
	local data = chunk()
	for i = 1, 32 do
		for j = 1, 13 do
			self.grid[i][j].brickData = nil
		end
	end
	for _, v in pairs(data.bricks) do
		local i, j, id, patch = unpack(v)
		local node = self.grid[i][j]
		node.brickData = self.brickDataLookup[id]
		node.patch = patch
	end
	GridNode.Cycler:reset(self.grid)
	self.menacerButton:reset()
	if data.menacer then
		for k, v in pairs(data.menacer) do
			self.menacerButton.flag[k] = v
		end
	end
	self.menacerButton:defaultNum()
	if data.menacerTimer then
		self.menacerButton:setNum(unpack(data.menacerTimer))
	end
	if data.powerup then
		if data.powerup.overall_chance then
			self.numBox2:setNumber(data.powerup.overall_chance*100)
			self.pBind2.state = true
		else
			self.pBind2.state = false
		end
		if data.powerup.weights then
			for i, v in ipairs(data.powerup.weights) do
				self.numBoxes[i]:setNumber(v)
				self.weights[i] = v
			end
			self.percentages:update(self.weights)
			self.pBind.state = true
		else
			self.pBind.state = false
		end
	else
		self.pBind2.state = false
		self.pBind.state = false
	end
	self:togglePowerupButtons(self.pBind.state)
	if not self.pBind.state then
		for i = 1, 135 do
			local w = powerupGenerator.default_weights[i]
			self.backup_weights[i] = 0
			self.numBoxes[i]:setNumber(w)
			self.weights[i] = w
		end
		self.percentages:update(self.weights)
	end
	if self.pBind2.state then
		self.numBox2.hidden = nil
	else
		self.backup_overall_chance = 0
		self.numBox2:setNumber(powerupGenerator.default_overall_chance*100)
		self.numBox2.hidden = "show_text"
	end
	if data.config then
		for k, v in pairs(data.config) do
			game.config[k] = v
		end
	end
	if data.background then
		self.background = data.background
		if self.background.tile then
			local tile = self.background.tile
			tile.rect = rects.bg[tile.i][tile.j]
		end
	else
		self.background = {r = 0, g = 0, b = 128}
	end
	self.undoStack:clear()
	self.redoStack:clear()
end

function EditorState:startGame()
	for i = 1, 32 do
		for j = 1, 13 do
			local brick = self.grid[i][j]:makeBrick()
			if brick then
				table.insert(game.bricks, brick)
			end
		end
	end
	local playstate = PlayState:new("test")
	powerupGenerator:initialize(self.numBox2.num / 100, self.weights)
	game.enemySpawner:initialize(self.menacerButton:unpackValues())
	playstate.background = self.background
	game:push(playstate)
end

function EditorState:togglePowerupButtons(state)
	if state then
		self.numBox4.hidden = nil
		self.numBox5.hidden = nil
		self.powerupReplace.hidden = nil
		self.powerupSetAll.hidden = nil
		self.numBox3.hidden = nil
		self.disableInactive.hidden = nil
		self.pSave.hidden = nil
		self.pLoad.hidden = nil
		self.pLoadDefault.hidden = nil
		for i, n in ipairs(self.numBoxes) do
			n.hidden = nil
		end
	else
		self.numBox4.hidden = true
		self.numBox5.hidden = true
		self.powerupReplace.hidden = true
		self.powerupSetAll.hidden = true
		self.numBox3.hidden = true
		self.disableInactive.hidden = true
		self.pSave.hidden = true
		self.pLoad.hidden = true
		self.pLoadDefault.hidden = true
		for i, n in ipairs(self.numBoxes) do
			n.hidden = "show_text"
		end
	end
end

--required so that the PlayState can load levels directly from a save file
--should be called only once during love.load()
local staticId = 1
local coloredCandidates = {}
function EditorState:initBrickData()
	local rawdata = {}
	for i = 1, 21 do
		for j = 1, 4 do
			table.insert(rawdata, {j, i, "NormalBrick", {j, i}})
		end
	end
	rawdata[#rawdata] = nil
	rawdata[#rawdata] = nil

	local rawdata1a = {}
	for i = 1, 19 do
		table.insert(rawdata1a, {1, i, "NormalBrick", {1, i, "brick_grey"}})
	end

	local rawdata1b = {}
	for i = 1, 19 do
		table.insert(rawdata1b, {1, i, "NormalBrick", {1, i, "brick_bright"}})
	end

	local rawdata2 = {{5, 2, "MetalBrick", {20}},
					  {5, 3, "MetalBrick", {30}},
					  {5, 4, "MetalBrick", {40}},
					  {5, 5, "MetalBrick", {50}},
					  {5, 6, "MetalBrick", {60}},
					  {5, 7, "MetalBrick", {70}},
					  {5, 1, "GoldBrick", {}},
					  {5, 8, "GoldBrick", {true}},
					  {5, 11, "PlatinumBrick", {}},
					  {5, 12, "CopperBrick", {}},
					  {4, 21, "OneWayBrick", {"up"}},
					  {5, 21, "OneWayBrick", {"down"}},
					  {4, 22, "OneWayBrick", {"left"}},
					  {5, 22, "OneWayBrick", {"right"}},
					  {5, 9, "GoldSpeedBrick", {true}},
					  {5, 10, "GoldSpeedBrick", {false}},
					  {7, 13, "SpeedBrick", {true}},
					  {7, 14, "SpeedBrick", {false}},
					  {6, 1, "FunkyBrick", {20}},
					  {6, 2, "FunkyBrick", {30}},
					  {6, 3, "FunkyBrick", {40}},
					  {6, 5, "GlassBrick", {}},
					  {6, 4, "DetonatorBrick", {"normal"}},
					  {6, 19, "DetonatorBrick", {"freeze"}},
					  {6, 18, "DetonatorBrick", {"neo"}},
					  {7, 17, "ShooterBrick", {"red"}},
					  {7, 18, "ShooterBrick", {"green"}},
					  {7, 19, "ShooterBrick", {"blue"}},
					  {6, 6, "AlienBrick", {}},
					  {8, 11, "ShoveBrick", {"right"}},
					  {8, 12, "ShoveBrick", {"left"}},
					  {7, 8, "FactoryBrick", {}},
					  {6, 13, "CometBrick", {"left"}},
					  {6, 14, "CometBrick", {"right"}},
					  {8, 9, "CometBrick", {"horizontal"}},
					  {8, 10, "CometBrick", {"vertical"}},
					  {8, 19, "OnixBrick", {"Full"}},
					  {9, 20, "OnixBrick", {"TopRight"}},
					  {9, 21, "OnixBrick", {"TopLeft"}},
					  {8, 20, "OnixBrick", {"BottomRight"}},
					  {8, 21, "OnixBrick", {"BottomLeft"}},
					  {7, 12, "TikiBrick", {}},
					  {6, 15, "LaserEyeBrick", {}},
					  {6, 17, "BoulderBrick", {}},
					  {8, 13, "TwinLauncherBrick", {true}},
					  {8, 14, "TwinLauncherBrick", {false}},
					  {7, 15, "TriggerDetonatorBrick", {}},
					  {5, 13, "JumperBrick", {}},
					  {6, 8, "RainbowBrick", {}},
					  {8, 17, "SlotMachineBrick", {true}},
					  {8, 18, "SlotMachineBrick", {false}},
					  {8, 8, "ParachuteBrick", {}},
					  {7, 11, "ShoveDetonatorBrick", {}},
					  {3, 22, "ForbiddenBrick", {}}
					 }
	local rawdata3 = {{7,  5, "SwitchBrick", {"red"}},
					  {8,  5, "SwitchBrick", {"green"}},
					  {9,  5, "SwitchBrick", {"blue"}},
					  {10,  5, "SwitchBrick", {"purple"}},
					  {11, 5, "SwitchBrick", {"orange"}},
					  {7,  7, "TriggerBrick", {"red"}},
					  {8,  7, "TriggerBrick", {"green"}},
					  {9,  7, "TriggerBrick", {"blue"}},
					  {10,  7, "TriggerBrick", {"purple"}},
					  {11, 7, "TriggerBrick", {"orange"}},
					  {7,  1, "FlipBrick", {"red", false}},
					  {8,  1, "FlipBrick", {"green", false}},
					  {9,  1, "FlipBrick", {"blue", false}},
					  {10,  1, "FlipBrick", {"purple", false}},
					  {11, 1, "FlipBrick", {"orange", false}},
					  {7,  2, "FlipBrick", {"red", true}},
					  {8,  2, "FlipBrick", {"green", true}},
					  {9,  2, "FlipBrick", {"blue", true}},
					  {10,  2, "FlipBrick", {"purple", true}},
					  {11, 2, "FlipBrick", {"orange", true}},
					  {7,  3, "StrongFlipBrick", {"red", false}},
					  {8,  3, "StrongFlipBrick", {"green", false}},
					  {9,  3, "StrongFlipBrick", {"blue", false}},
					  {10,  3, "StrongFlipBrick", {"purple", false}},
					  {11, 3, "StrongFlipBrick", {"orange", false}},
					  {7,  4, "StrongFlipBrick", {"red", true}},
					  {8,  4, "StrongFlipBrick", {"green", true}},
					  {9,  4, "StrongFlipBrick", {"blue", true}},
					  {10,  4, "StrongFlipBrick", {"purple", true}},
					  {11, 4, "StrongFlipBrick", {"orange", true}}
					 }
	local rawdata3a= {{10, 16, "SequenceBrick", {1}},
					  {10, 17, "SequenceBrick", {2}},
					  {10, 18, "SequenceBrick", {3}},
					  {10, 19, "SequenceBrick", {4}},
					  {10, 20, "SequenceBrick", {5}}
					 }
	local rawdata4 = {{4, 3, "ConveyorBrick", {"up", "fast"}},
					  {4, 2, "ConveyorBrick", {"up", "medium"}},
					  {4, 1, "ConveyorBrick", {"up", "slow"}},
					  {3, 3, "ConveyorBrick", {"down", "fast"}},
					  {3, 2, "ConveyorBrick", {"down", "medium"}},
					  {3, 1, "ConveyorBrick", {"down", "slow"}},
					  {2, 3, "ConveyorBrick", {"left", "fast"}},
					  {2, 2, "ConveyorBrick", {"left", "medium"}},
					  {2, 1, "ConveyorBrick", {"left", "slow"}},
					  {1, 3, "ConveyorBrick", {"right", "fast"}},
					  {1, 2, "ConveyorBrick", {"right", "medium"}},
					  {1, 1, "ConveyorBrick", {"right", "slow"}}
					 }
	local rawdata5 = {{1, 1, "GateBrick", {"red", false}},
					  {1, 2, "GateBrick", {"blue", false}},
					  {1, 3, "GateBrick", {"green", false}},
					  {1, 4, "GateBrick", {"orange", false}},
					  {1, 5, "GateBrick", {"red", true}},
					  {1, 6, "GateBrick", {"blue", true}},
					  {1, 7, "GateBrick", {"green", true}},
					  {1, 8, "GateBrick", {"orange", true}}
					 }
	local rawdata6 = {{1, 1, "LauncherBrick", {false, false}},
					  {1, 2, "LauncherBrick", {true, false}},
					  {2, 1, "LauncherBrick", {false, true}},
					  {2, 2, "LauncherBrick", {true, true}},
					 }

	self.brickDataLookup = {}

	function processData(imgstr, raw)
		local brickData = {}
		for k, v in pairs(raw) do
			local data = BrickData:new(imgstr, unpack(v))
			self.brickDataLookup[data.id] = data
			table.insert(brickData, data)
		end
		return brickData 
	end

	local brickData = {
		processData("brick_spritesheet", rawdata),
		processData("brick_grey",        rawdata1a),
		processData("brick_bright",      rawdata1b),
		processData("brick_spritesheet", rawdata2),
		processData("brick_spritesheet", rawdata3),
		processData("brick_spritesheet", rawdata3a),
		processData("conveyor_editor",   rawdata4),
		processData("brick_gate",        rawdata5),
		processData("launcher_editor",   rawdata6)
	}

	--some last minute changes to the onewaybrick sprites
	for _, d in pairs(brickData[4]) do
		if d.type == "OneWayBrick" then
			d.rect = make_rect(d.rect.x - 16*20, d.rect.y - 8*3, d.rect.w, d.rect.h)
			d.imgstr = "brick_oneway_editor"
		end
	end

	brickData["jetblack"] = BrickData:new("brick_jetblack", 1, 1, "NormalBrick", {1, 1, "brick_jetblack"})
	self.brickDataLookup[brickData.jetblack.id] = brickData.jetblack

	--this PowerUpBrick button is more complex than the other button because you can select which powerup to fill up the brick
	for i = 1, 135 do
		local data = BrickData:new("brick_spritesheet", 6, 5, "PowerUpBrick", {i})
		data.draw = function(self, x, y, w, h)
			local imgstr = "powerup_spritesheet"
			local rect = rects.powerup_ordered[self.args[1]]
			draw(imgstr, rect, x, y, 0, w, h)
			legacySetColor(255, 255, 255, 128)
			draw(self.imgstr, self.rect, x, y, 0, w, h)
			legacySetColor(255, 255, 255, 255)
		end
		self.brickDataLookup[data.id] = data
		brickData["pow"..i] = data
	end

	--remember that the order you create the BrickData is important in order to preserve old savefiles
	brickData["split"] = BrickData:new("brick_split", 5, 2, "SplitBrick", {})
	brickData["ghost"] = BrickData:new("brick_ghost_editor", 1, 1, "GhostBrick", {})
	self.brickDataLookup[brickData.split.id] = brickData.split
	self.brickDataLookup[brickData.ghost.id] = brickData.ghost

	brickData["whiter"] = BrickData:new("brick_white", 1, 1, "NormalBrick", {1, 1, "brick_white"})
	brickData["whitest"] = BrickData:new("brick_white", 1, 2, "NormalBrick", {1, 2, "brick_white"})
	self.brickDataLookup[brickData.whiter.id] = brickData.whiter
	self.brickDataLookup[brickData.whitest.id] = brickData.whitest

	for id, data in ipairs(self.brickDataLookup) do
		if data.type == "NormalBrick" then
			table.insert(coloredCandidates, id)
		end
	end

	self.brickData = brickData
end

function randomColoredBrick()
	local lookup = editorstate.brickDataLookup
	local c = coloredCandidates
	return lookup[c[math.random(#c)]]
end

local ref_patch = {
	shield_up = {7, 21},
	shield_down = {6, 21},
	shield_left = {7, 20},
	shield_right = {6, 20},
	invisible = {2, 22},
	slow = 1,
	medium = 2,
	fast = 3,
	right = 1,
	left = 2,
	down = 3,
	up = 4,
}
function EditorState.drawPatch(key, value, x, y, w, h)
	local i, j = 0, 0
	local imgstr = "brick_spritesheet"
	if key == "antilaser" then
		i, j = 1, 1
		imgstr = "patch_antilaser"
	elseif key == "movement" then
		i, j = ref_patch[value[1]], ref_patch[value[2]]
		imgstr = value[3] and "patch_mobile_hit" or "patch_mobile"
	else
		i, j = unpack(ref_patch[key])
	end
	draw(imgstr, rects.brick[i][j], x, y, 0, w, h)
end

function EditorState:initialize()
	editorstate = self --make itself public to the global space
	self.stateName = "editorstate"

	self.background = {r = 0, g = 0, b = 128}
	--these determine the powerups in the SlotMachineBrick
	game.config.slot_blue = {1, 2, 3}
	game.config.slot_yellow = {1, 2, 3}

	self.buttons = {}
	self.patchButtons = {}
	self.toolButtons = {}

	self:placeButtons(self.brickData[1], window.rwallx + 32, 64, 24, 12, 4, true)
	self:placeButtons(self.brickData[2], window.rwallx + 152, 64, 24, 12.01, 1) --this tiny 0.01 offset helps make the pixels look "better" for some reason
	self:placeButtons(self.brickData[3], window.rwallx + 80, 64, 24, 12.01, 1) --12.01
	self:placeButtons(self.brickData[4], window.rwallx + 32, 328, 24, 12, 6)
	self:placeButtons(self.brickData[5], window.rwallx + 32, 436, 24, 12, 5)
	self:placeButtons(self.brickData[6], window.rwallx + 152, 436, 24, 12, 1)
	self:placeButtons(self.brickData[7], window.rwallx + 32, 532, 24, 12, 3)
	self:placeButtons(self.brickData[8], window.rwallx + 32, 508, 24, 12, 4)
	self:placeButtons(self.brickData[9], window.rwallx + 104, 532, 24, 12.01, 1) --12.01

	--jet black brick is its own independent button
	table.insert(self.buttons, BrickButton:new(self.brickData.jetblack, window.rwallx + 80, 304, 24, 12))
	table.insert(self.buttons, BrickButton:new(self.brickData.whiter, window.rwallx + 128, 292, 24, 12.01))
	table.insert(self.buttons, BrickButton:new(self.brickData.whitest, window.rwallx + 152, 292, 24, 12.01))

	table.insert(self.buttons, BrickButton:new(self.brickData.split, window.rwallx + 128, 508, 24, 12))
	table.insert(self.buttons, BrickButton:new(self.brickData.ghost, window.rwallx + 128, 520, 24, 12))

	--this PowerUpBrick button is more complex than the other button because you can select which powerup to fill up the brick
	self.buttons.powerup = BrickButton:new(self.brickData.pow1, window.rwallx + 152, 496, 24, 12)

	--a special rainbow brick that becomes random colored when placed (not to be confused with RainbowBrick)
	self.rainbowData = BrickData:new("brick_rainbow2", 1, 1, "Rainbow", {})
	self.rainbowData.id = -1
	staticId = staticId - 1 --to make sure it doesn't affect the ids of real bricks
	table.insert(self.buttons, BrickButton:new(self.rainbowData, window.rwallx + 104, 304, 24, 12))

	self.rainbowData = BrickData:new("brick_rainbow", 1, 1, "Rainbow2", {})
	self.rainbowData.id = -2
	staticId = staticId - 1 --to make sure it doesn't affect the ids of real bricks
	table.insert(self.buttons, BrickButton:new(self.rainbowData, window.rwallx + 128, 304, 24, 12))


	self.selectMode = "button" --or "patch"

	self.selectedButton = self.buttons[1]
	self.selectedButton.selected = true


	local patchShields = {
		{7, 21, "shield_up", true},
        {6, 21, "shield_down", true},
        {7, 20, "shield_left", true},
        {6, 20, "shield_right", true},
	}

	local patchMovement = {
		{1, 1, "movement", {"right", "slow", false}},
		{1, 2, "movement", {"right", "medium", false}},
		{1, 3, "movement", {"right", "fast", false}},
		{2, 1, "movement", {"left" , "slow", false}},
		{2, 2, "movement", {"left" , "medium", false}},
		{2, 3, "movement", {"left" , "fast", false}},
		{3, 1, "movement", {"down" , "slow", false}},
		{3, 2, "movement", {"down" , "medium", false}},
		{3, 3, "movement", {"down" , "fast", false}},
		{4, 1, "movement", {"up"   , "slow", false}},
		{4, 2, "movement", {"up"   , "medium", false}},
		{4, 3, "movement", {"up"   , "fast", false}},
	}
	local patchMovement2 = {}
	for _, p in ipairs(patchMovement) do
		local p2 = util.copy(p)
		p2[4] = util.copy(p[4])
		p2[4][3] = true
		table.insert(patchMovement2, p2)
	end

	local button =  PatchButton:new("invisible", true, "brick_spritesheet", rects.brick[2][22], window.rwallx + 32, 100, 32, 16)
	table.insert(self.patchButtons, button)
	for i, v in ipairs(patchShields) do
		local button = PatchButton:new(v[3], v[4], "brick_spritesheet", rects.brick[v[1]][v[2]], window.rwallx + 32 + (i-1)*32, 150, 32, 16)
		table.insert(self.patchButtons, button)
	end
	for i, v in ipairs(patchMovement) do
		local row = math.floor((i-1)/3)
		local col = (i-1)%3
		local button = PatchButton:new(v[3], v[4], "patch_mobile", rects.brick[v[1]][v[2]], window.rwallx + 32 + col*32, 200 + row*16, 32, 16)
		table.insert(self.patchButtons, button)
	end
	for i, v in ipairs(patchMovement2) do
		local row = math.floor((i-1)/3)
		local col = (i-1)%3
		local button = PatchButton:new(v[3], v[4], "patch_mobile_hit", rects.brick[v[1]][v[2]], window.rwallx + 32 + col*32, 300 + row*16, 32, 16)
		table.insert(self.patchButtons, button)
	end
	button = PatchButton:new("antilaser", true, "patch_antilaser", rects.brick[1][1], window.rwallx + 32, 400, 32, 16)
	table.insert(self.patchButtons, button)

	self.selectedPatch = self.patchButtons[1]
	self.selectedPatch.selected = true

	--tabs
	local pad = 8
	local border = 2
	self.widget = {}
	self.widget.main = {
		x = window.rwallx + 16 + pad,
		y = window.ceiling - 32,
		w = window.w - pad - (window.rwallx + 16 + pad) + 2,
		h = window.h - pad - (window.ceiling - 32),
		draw = function(self)
			-- legacySetColor(0, 0, 0)
			-- love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
			-- legacySetColor(240, 240, 240)
			-- love.graphics.rectangle("fill", self.x+border, self.y+border, self.w-border*2, self.h-border*2)

			local x, y, w, h, b = self.x, self.y, self.w, self.h, border
			--local fillrect = Button.fillrect
			fillrect(32, x, y, w, h)
			fillrect(255, x, y, w-b, h-b)
			fillrect(100, x+b, y+b, w-b*2, h-b*2)
			fillrect(220, x+b, y+b, w-b*3, h-b*3)
		end
	}
	local wm = self.widget.main
	self.widget.brickTab = {
		x = wm.x,
		y = wm.y - 48 + border,
		w = 56,
		h = 48,
		selected = true,
		containPoint = function(self, x, y)
			return containPoint(self, x, y)
		end,
		drawTab = function(self)
			local x, y, w, h, b = self.x, self.y, self.w, self.h, border
			--local fillrect = Button.fillrect
			if self.selected then
				w = w + b*1
				fillrect(32, x, y, w, h-b)
				fillrect(255, x, y, w-b, h)
				fillrect(100, x+b, y+b, w-b*2, h-b)
				fillrect(220, x+b, y+b, w-b*3, h-b)
			else
				x = x + b*1
				y = y + b*1
				w = w - b*2
				h = h - b*2
				fillrect(32, x, y, w+b, h)
				fillrect(255, x, y, w, h)
				fillrect(100, x+b, y+b, w-b, h-b)
				fillrect(187, x+b, y+b, w-b*2, h-b)
			end
		end,
		draw = function(self)
			self:drawTab()
			local offx, offy = 0, 0
			if self.selected then
				offx, offy = 0, -2
			end
			legacySetColor(255, 255, 255, 255)
			draw("button_icon", rects.icon[2][1], self.x + self.w/2 + offx, self.y + self.h/2 + offy, 0, 32, 32)
		end
	}
	self.widget.patchTab = {
		x = wm.x + self.widget.brickTab.w - border*2,
		y = wm.y - 48 + border,
		w = 56,
		h = 48,
		selected = false,
		containPoint = function(self, x, y)
			return containPoint(self, x, y)
		end,
		drawTab = self.widget.brickTab.drawTab,
		draw = function(self)
			self:drawTab()
			local offx, offy = 0, 0
			if self.selected then
				offx, offy = 0, -2
			end
			legacySetColor(255, 255, 255, 255)
			draw("button_icon", rects.icon[2][2], self.x + self.w/2 + offx, self.y + self.h/2 + offy, 0, 32, 32)
		end
	}
	self.widget.enemyTab = {
		x = wm.x + (self.widget.brickTab.w*2) - border*4,
		y = wm.y - 48 + border,
		w = 56,
		h = 48,
		selected = false,
		containPoint = function(self, x, y)
			return containPoint(self, x, y)
		end,
		drawTab = self.widget.brickTab.drawTab,
		draw = function(self)
			self:drawTab()
			local offx, offy = 0, 0
			if self.selected then
				offx, offy = 0, -2
			end
			legacySetColor(255, 255, 255, 255)
			draw("button_icon", rects.icon[2][3], self.x + self.w/2 + offx, self.y + self.h/2 + offy, 0, 32, 32)
		end
	}

	local toolNames = {"free", "line", "rect", "fillrect", "fill", "replace", "cut", "copy", "paste", "eyedropper"}
	local wrap = 5
	for i, name in ipairs(toolNames) do
		local button = ToolButton:new(name, "editor_tool", make_rect(16*(i-1), 0, 16, 16), 10 + 32*((i-1)%wrap), 125 + 65 + 32*(math.floor((i-1)/wrap)), 32, 32)
		table.insert(self.toolButtons, button)
	end

	self.selectedToolButton = self.toolButtons[1]
	self.selectedToolButton.selected = true
	self.tool = self.selectedToolButton.tool

	--9 enemies: 5 menacers + 4 others + and maybe more
	local _names = {"redgreen", "cyan", "bronze", "silver", "pewter", "dizzy", "cubic", "gumballtrio", "walkblock"}
	local _flag = {}
	for i, n in ipairs(_names) do
		_flag[n] = false
	end
	local _rects = {}
	for i = 1, 5 do
		_rects[i] = make_rect(0, (i-1)*12, 12, 12)
	end
	local wm = self.widget.main
	local _x, _y = wm.x + 10, wm.y + 20
	local _off = {x = 0, y = -3}
	self.menacerButton = {
		names = _names,
		flag = _flag,
		x = _x,
		y = _y,
		w = 120, 
		h = 96,
		rects = _rects,
		xrect = make_rect(12, 0, 12, 12),
 		crect = make_rect(24, 0, 12, 12),
 		numBox1  = NumBox:new(_x+50, _y+152, 32, 16, {font = font["Munro20"], off = _off}),
 		numBox2a = NumBox:new(_x+44, _y+228, 32, 16, {font = font["Munro20"], off = _off}),
 		numBox2b = NumBox:new(_x+104, _y+228, 32, 16, {font = font["Munro20"], off = _off}),
 		defaultButton = Button:new(_x, _y + 260, 80, 30, {text = "Default", font = font["Munro20"],
 			color = {idle = 200, hovered = 200, clicked = 240}}),
 		unpackValues = function(self)
 			return self.flag, self.numBox1.num, self.numBox2a.num, self.numBox2b.num
 		end,
 		reset = function(self)
 			for k, v in pairs(self.flag) do
 				self.flag[k] = false
 			end
 		end,
 		setNum = function(self, a, b, c)
 			self.numBox1:setNumber(a)
 			self.numBox2a:setNumber(b)
 			self.numBox2b:setNumber(c)
 		end,
 		defaultNum = function(self)
 			self:setNum(2, 2, 8)
 		end,
 		checkDefault = function(self)
 			local t = {self:unpackValues()}
 			return t[2] == 2 and t[3] == 2 and t[4] == 8
 		end,
		handleInput = function(self, dt)
	 		local x, y = mouse.x, mouse.y
	 		local dx, dy = x - self.x, y - self.y
	 		if dx > 0 and dx < self.w then
	 			if dy > 0 and dy < self.h/2 then
		 			local name = nil
		 			local dw = self.w/5
		 			for i = 1, 5 do
		 				if dx < dw * i then
		 					name = self.names[i]
		 					break
		 				end
		 			end
		 			if name and mouse.m1 == 1 then
		 				self.flag[name] = not self.flag[name]
		 			end
		 			tooltipManager:selectEnemy(name)
		 		elseif dy > self.h/2 and dy < self.h then
		 			local name = nil
		 			local dw = self.w/5
		 			for i = 1, 4 do
		 				if dx < dw * i then
		 					name = self.names[i+5]
		 					break
		 				end
		 			end
		 			if name and mouse.m1 == 1 then
		 				self.flag[name] = not self.flag[name]
		 			end
		 			tooltipManager:selectEnemy(name)
		 		end
			end
			self.numBox1:update(dt)
			self.numBox2a:update(dt)
			self.numBox2b:update(dt)
			if self.defaultButton:update(dt) then
				self:defaultNum()
			end
		end,
		draw = function(self)
			for i = 1, 5 do
				local n = self.names[i]
				local r = self.flag[n] and self.crect or self.xrect
				draw("menacer_editor", self.rects[i], self.x + (i-1)*24, self.y, 0, 24, 24, 0, 0)
				draw("menacer_editor", r, self.x + (i-1)*24, self.y + 24, 0, 24, 24, 0, 0)
			end
			draw("enemy_editor", nil, self.x, self.y + 48, 0, 96, 24, 0, 0)
			for i = 1, 4 do
				local n = self.names[i+5]
				local r = self.flag[n] and self.crect or self.xrect
				draw("menacer_editor", r, self.x + (i-1)*24, self.y + 72, 0, 24, 24, 0, 0)
			end
			legacySetColor(0, 0, 0, 255)
			love.graphics.setFont(font["Munro20"])
			love.graphics.printf("Initial Spawn Delay:", self.x, self.y + 125, self.w)
			love.graphics.printf("Subsequent Spawn Delay: from", self.x, self.y + 180, self.w)
			love.graphics.print("to", self.x + 80, self.y + 225)
			love.graphics.print("s", self.x + 120, self.y + 225)
			self.numBox1:draw()
			self.numBox2a:draw()
			self.numBox2b:draw()
			self.defaultButton:draw()
		end,
	}
	self.menacerButton:defaultNum()
	-- local mt = {
	-- 	__index = function(t, k)
	-- 		return rawget(t, self.menacerButton.names[k])
	-- 	end
	-- }
	-- setmetatable(self.menacerButton.flag, mt)

	self.grid = {}
	for i = 1, 32 do
		self.grid[i] = {}
		for j = 1, 13 do
			self.grid[i][j] = GridNode:new(i, j)
			self.grid[i][j].grid = self.grid
		end
	end

	--init undo and redo stacks
	local advance = function(self)
		if #self:top() > 0 then
			self:push({})
		end
	end
	local pop2 = function(self)
		if self:size() > 1 then
			self:pop()
			local t = self:top()
			self.data[#self.data] = {}
			return t
		end
		return nil
	end
	local clear = function(self)
		self.data = {}
		self:push({})
	end
	local emplace = function(self, _i, _j, _old, _new)
		table.insert(self:top(), {i = _i, j = _j, old = _old, new = _new})
	end
	local include = function(stack)
		stack.pop2 = pop2
		stack.advance = advance
		stack.emplace = emplace
		stack.clear = clear
	end
	
	self.undoStack = Stack:new()
	self.undoStack:push({})
	include(self.undoStack)

	self.redoStack = Stack:new()
	self.redoStack:push({})
	include(self.redoStack)

	--Set PowerUp Weights Overlay

	self.powerupOverlay = false
	--self.powerupButton = Button:new(70, 252, 90, 50, {text = "Set PowerUp Weights", font = font["Arcade12"], wrap = 3}, function()
	-- self.powerupButton = Button:new(10, 305, 120, 50, {text = "PowerUp Chances", font = font["Arcade20"], wrap = 2}, function()
	-- 	self.powerupOverlay = true
	-- end)
	local options = {
		image = {imgstr = "button_icon", rect = rects.icon[1][2], w = 32, h = 32, offx = -2, offy = -2},
		color = {idle = 150, hovered = 150, clicked = 200}
	}
	self.powerupButton = Button:new(10, 200 + 65, 50, 50, options, function()
		self.powerupOverlay = true
	end)
	self.powerupButton.update = function(butt, dt)
 		if butt:containMouse() then
 			tooltipManager:selectButton("powerup")
 		end
 		return Button.update(butt, dt)
 	end

	self.powerupSetAll   = Button:new(600, 200, 100, 25, {text = "Set All To:", font = font["Munro20"], wrap = 1})
	self.powerupReplace  = Button:new(600, 235,  75, 25, {text = "Replace", font = font["Munro20"]})
	self.pSave           = Button:new(600, 270, 150, 40, {text = "Save", font = font["Munro30"]})
	self.pLoad           = Button:new(600, 320, 150, 40, {text = "Load", font = font["Munro30"]})
	self.pLoadDefault    = Button:new(600, 370, 150, 40, {text = "Load Default", font = font["Munro20"], wrap = 1})
	self.disableInactive = Button:new(600, 420, 150, 50, {text = "Disable Useless PowerUps", font = font["Munro20"], wrap = 2})
	self.powerupExit     = Button:new(600, 535, 150, 40, {text = "Exit", font = font["Munro30"]})
	
	self.pBind           = Checkbox:new(600, 165, false)
	self.pBind2          = Checkbox:new(600, 140, false)

	self.weights = {}
	for i = 1, 135 do
		self.weights[i] = 0
	end
	function self.weights:sum()
		local sum = 0
		for i = 1, 135 do
			sum = sum + self[i]
		end
		return sum
	end

	self.backup_weights = {}
	for i = 1, 135 do
		self.backup_weights[i] = 0
	end

	self.percentages = {}
	for i = 1, 135 do
		self.percentages[i] = 0
	end
	function self.percentages:update(weights)
		local sum = weights:sum()
		if sum == 0 then
			for i = 1, 135 do self[i] = 0 end
		end
		for i = 1, 135 do
			local p = 0
			if weights[i] > 0 then
				p = 100 * weights[i] / sum
			end
			self[i] = p
		end
	end

	--these have to be repositioned if resized
	self.numBoxes = {}

	local wrap = 45
	local w = 20
	local h = 10
	local dx = 170
	local dy = 1
	for i = 1, 135 do
		local ii = (i-1)%wrap
		local jj = math.floor((i-1)/wrap)
		local x, y = jj * (w + dx) + 25, ii * (h + dy) + 68
		local n = NumBox:new(x + w + 80, y, 30, h, {font = font["Munro10"]})
		n.i = i
		n.type = "weight"
		table.insert(self.numBoxes, n)
	end
	local default = powerupGenerator.default_weights
	for i = 1, 135 do
		local w = default[i]
		self.numBoxes[i]:setNumber(w)
		self.weights[i] = w
	end
	self.percentages:update(self.weights)

	self.numBox2 = NumBox:new(670, 105, 60, 30, {font = font["Munro30"], limit = 100})
	self.numBox2.type = "global_chance"
	self.numBox2:setNumber(powerupGenerator.default_overall_chance * 100)
	self.numBox2.hidden = "show_text"
	self.backup_overall_chance = 0

	self.numBox3 = NumBox:new(710, 203, 40, 20, {font = font["Munro20"]})
	self.numBox3.type = "setall"

	self.numBox4 = NumBox:new(680, 238, 30, 20, {font = font["Munro20"]})
	self.numBox4.type = "replace_before"

	self.numBox5 = NumBox:new(760, 238, 30, 20, {font = font["Munro20"]})
	self.numBox5.type = "replace_after"

	self.selectedNumBox = nil

	self:togglePowerupButtons(false)


	--Play/Stop buttons(subject to change)
	local options = {
		image = {imgstr = "button_icon", rect = rects.icon.play[1], w = 36, h = 33, offx = -50, offy = -1},
		color = {idle = 150, hovered = 150, clicked = 200},
		text = "Play",
		font = font["Arcade30"],
		offx = 20
	}
	self.playButton = Button:new(10, 45, 155, 50, options)
	local options = {
		image = {imgstr = "button_icon", rect = rects.icon.stop[1], w = 24, h = 22, offx = -1, offy = -1},
		color = {idle = 150, hovered = 150, clicked = 200},
	}
	self.stopButton = Button:new(55, 200, 40, 36, options)

	--Save Bricks Buttons:
	self.saveButton = Button:new(10, 420, 75, 40, {text = "Save", font = font["Arcade20"]})
	self.loadButton = Button:new(90, 420, 75, 40, {text = "Load", font = font["Arcade20"]})
	self.lastFile = nil

	--Change Background Button:
	--self.backgroundButton = Button:new(70, 312, 90, 50, {text = "Change Background", font = font["Arcade10"], wrap = 2})
	-- self.backgroundButton = Button:new(10, 360, 90, 50, {text = "BG Select", font = font["Arcade20"], wrap = 2})
 	local options = {
		image = {imgstr = "button_icon", rect = rects.icon[1][1], w = 32, h = 32, offx = -1, offy = -1},
		color = {idle = 150, hovered = 150, clicked = 200}
	}
 	self.backgroundButton = Button:new(65, 200 + 65, 50, 50, options)
 	self.backgroundButton.update = function(butt, dt)
 		if butt:containMouse() then
 			tooltipManager:selectButton("background")
 		end
 		return Button.update(butt, dt)
 	end
 
	--back
	self.backButton = Button:new(10, 500, 155, 40, {text = "Main Menu", font = font["Arcade20"]})
	--when first entering this state, the mouse might be already held down causing unwanted brick placement on the board.
	--this makes sure that the mouse is released before allowing the board to be drawn on
	self.mouseProtect = true 
end

function EditorState:update(dt)
	tooltipManager:clear()
	if self.mouseProtect then
		if not mouse.m1 then
			self.mouseProtect = nil
		else
			mouse.m1 = false
		end
	end

	if self.powerupOverlay then
		self:update2(dt)
		return
	end

	if self.choosePowerUpBrick then
		self:update3(dt)
		return
	end

	self.powerupButton:update(dt)

	if self.playButton:update(dt) then
		self:startGame()
		return
	end
	-- if self.stopButton:update(dt) then
	-- 	print("Stop")
	-- end
	if self.saveButton:update(dt) then
		game:push(LevelSelectState:new("editor_save", self.lastFile))
	end
	if self.loadButton:update(dt) then
		game:push(LevelSelectState:new("editor_load", self.lastFile))
	end
	if self.backgroundButton:update(dt) then
		game:push(BackgroundSelectState:new())
	end

	if self.backButton:update(dt) then
		game:pop()
	end

	--input handling
	if keys.escape then
		--start the game!!!
		self:startGame()
		return
	elseif keys.tab then
		if self.selectMode == "patch" then
			self.widget.brickTab.selected = true
			self.widget.patchTab.selected = false
			self.selectMode = "button"
		else
			self.widget.brickTab.selected = false
			self.widget.patchTab.selected = true
			self.selectMode = "patch"
		end
	end

	-------------------------------
	----------LEFT SECTION---------
	-------------------------------
	if mouse.x < window.lwallx then
		for _, button in pairs(self.toolButtons) do
			if button:containPoint(mouse.x, mouse.y) then
				tooltipManager:selectTool(button)
				if mouse.m1 == 1 then
					self.selectedToolButton.selected = false
					self.selectedToolButton = button
					self.tool = self.selectedToolButton.tool
					self.selectedToolButton.selected = true
					check = true
				end
				break
			end
		end
	end
	-------------------------------
	---------RIGHT SECTION---------
	-------------------------------
	if self.widget.brickTab.selected then
		local check = false
		for _, button in pairs(self.buttons) do
			if button:containPoint(mouse.x, mouse.y) then
				check = true
				tooltipManager:selectBrick(button.brickData)
				break
			end
		end
		local mode = tooltipManager.mode
		if not check and mode == nil then
			tooltipManager:selectBrick(self.selectedButton.brickData)
		end
	elseif self.widget.patchTab.selected then
		local check = false
		for _, button in pairs(self.patchButtons) do
			if button:containPoint(mouse.x, mouse.y) then
				check = true
				tooltipManager:selectPatch(button)
				break
			end
		end
		local mode = tooltipManager.mode
		if not check and mode == nil then
			tooltipManager:selectPatch(self.selectedPatch)
		end
	elseif self.widget.enemyTab.selected then
		self.menacerButton:handleInput(dt)
		local mode = tooltipManager.mode
		if mode == nil then
			tooltipManager:selectBrick(self.selectedButton.brickData)
		end
	end

	if mouse.x > window.rwallx then
		local name = nil
		if self.widget.brickTab:containPoint(mouse.x, mouse.y) then
			name = "bricktab"
		elseif self.widget.patchTab:containPoint(mouse.x, mouse.y) then
			name = "patchtab"
		elseif self.widget.enemyTab:containPoint(mouse.x, mouse.y) then
			name = "enemytab"
		end
		if name then
			tooltipManager:selectButton(name)
		end
		if mouse.m1 == 1 then
			if self.widget.brickTab:containPoint(mouse.x, mouse.y) then
				self.widget.brickTab.selected = true
				self.widget.patchTab.selected = false
				self.widget.enemyTab.selected = false
				self.selectMode = "button"
			elseif self.widget.patchTab:containPoint(mouse.x, mouse.y) then
				self.widget.brickTab.selected = false
				self.widget.patchTab.selected = true
				self.widget.enemyTab.selected = false
				self.selectMode = "patch"
			elseif self.widget.enemyTab:containPoint(mouse.x, mouse.y) then
				self.widget.brickTab.selected = false
				self.widget.patchTab.selected = false
				self.widget.enemyTab.selected = true
				self.selectMode = "enemy"
			end
			if self.widget.brickTab.selected then
				for _, button in pairs(self.buttons) do
					if button:containPoint(mouse.x, mouse.y) then
						tooltipManager:selectBrick(button.brickData)
						if button.brickData.type == "PowerUpBrick" and self.selectedButton == button then
							self.choosePowerUpBrick = "pow"
						elseif button.brickData.type == "SlotMachineBrick" and self.selectedButton == button then
							self.choosePowerUpBrick = "slot"
							self.chooseSlotColor = button.brickData.args[1] and "slot_blue" or "slot_yellow"
							self.tempSlotPowerUps = {}
						end
						self.selectedButton.selected = false
						self.selectedButton = button
						self.selectedButton.selected = true
						goto stop1
					end
				end
			elseif self.widget.patchTab.selected then
				for _, button in pairs(self.patchButtons) do
					if button:containPoint(mouse.x, mouse.y) then
						if self.selectedPatch then
							self.selectedPatch.selected = false
						end
						self.selectedPatch = button
						self.selectedPatch.selected = true
						goto stop1
					end
				end
			elseif self.widget.enemyTab.selected then
				--brick should be selected
			end
			::stop1::
		end
	end
	----------------------
	----MIDDLE SECTION----
	----------------------
	for i = 1, 32 do
		for j = 1, 13 do
			self.grid[i][j].highlighted = false
		end
	end

	local i, j = getGridPos(mouse.x, mouse.y)
	local node = nil
	if boundCheck(i, j) then
		node = self.grid[i][j]
		node.highlighted = true
	end

	if not self.nodes then self.nodes = {} end
	if not self.copyData then self.copyData = {} end

	if self.tool == "paste" and boundCheck(i, j) then
		if node then node.highlighted = false end
		for _, v in pairs(self.copyData) do
			if v.brickData then
				local ii, jj = i+v.di, j+v.dj
				if boundCheck(ii, jj) then
					self.grid[ii][jj].highlighted = true
				end
			end
		end
	end

	if self.tool == "eyedropper" then
		if mouse.x > window.lwallx and mouse.x < window.rwallx and mouse.y > window.ceiling then
			local i, j = getGridPos(mouse.x, mouse.y)
			local node = self.grid[i][j]
			if node.brickData then
				local data = node.brickData
				tooltipManager:selectBrick(data)
				if mouse.m1 == 1 then
					if data.type == "PowerUpBrick" then
						self.selectedButton.selected = false
						self.selectedButton = self.buttons.powerup
						self.selectedButton.selected = true
						self.buttons.powerup.brickData = data
					else
						for _, b in pairs(self.buttons) do
							if b.brickData == data then
								self.selectedButton.selected = false
								self.selectedButton = b
								self.selectedButton.selected = true
								break
							end
						end
					end
				end
			end
		end
	end

	if mouse.m1 or mouse.m2 then
		self.nodes = {}
		if mouse.x > window.lwallx and mouse.x < window.rwallx and mouse.y > window.ceiling then
			self.mouseFlag = true
			if self.tool == "free" then
				node.highlighted = false
				if self.last_i ~= i or self.last_j ~= j then
					if self.selectMode == "patch" then
						local key, value = self.selectedPatch.key, self.selectedPatch.value
						if mouse.m2 then
							key = "clear"
						end
						node:setPatch(key, value)
					else
						local old = node.brickData
						local new = nil
						if mouse.m1 then 
							new = self.selectedButton.brickData
						end
						if old ~= new then
							if new then --rainbow option
								if new.id == -1 then
									new = randomColoredBrick()
								elseif new.id == -2 then
									if not self.storedRainbow then
										self.storedRainbow = randomColoredBrick()
									end
									new = self.storedRainbow
								end
							end
							node.brickData = new
							self.undoStack:emplace(i, j, old, new)
						end
					end
				end
				self.last_i, self.last_j = i, j --could possible be extended for more optimization
			elseif self.tool == "fill" then
				self.mouseMode = mouse.m1 and 1 or 2
				local id = node.id
				local temp = {node}
				node.highlighted = false
				while #temp > 0 do
					local n = temp[1]
					if n.id == id and not n.highlighted then
						table.insert(temp, n.up)
						table.insert(temp, n.down)
						table.insert(temp, n.left)
						table.insert(temp, n.right)
						table.insert(self.nodes, n)
						n.highlighted = true
					end
					table.remove(temp, 1)
				end
			elseif self.tool == "replace" then
				self.mouseMode = mouse.m1 and 1 or 2
				local id = node.id
				for i = 1, 32 do
					for j = 1, 13 do
						local n = self.grid[i][j]
						if n.id == id then
							table.insert(self.nodes, n)
						end
					end
				end
			else
				if not self.start then
					self.start = node
					self.mouseMode = mouse.m1 and 1 or 2
				end
				self.finish = node
				if self.tool == "line" then
					--Bresenham's line algorithm
					local x0, y0 = self.start.i, self.start.j
					local x1, y1 = self.finish.i, self.finish.j
					local dx = math.abs(x1 - x0)
					local dy = math.abs(y1 - y0)
					local sx = x0 < x1 and 1 or -1 --ternary operation
					local sy = y0 < y1 and 1 or -1
					local err = (dx > dy and dx or -dy) / 2
					local e2 = nil
					while true do
						if not boundCheck(x0, y0) then break end
						table.insert(self.nodes, self.grid[x0][y0])
						if x0 == x1 and y0 == y1 then break end
						e2 = err
						if e2 > -dx then
							err = err - dy
							x0 = x0 + sx
						end
						if e2 < dy then
							err = err + dx
							y0 = y0 + sy
						end
					end
				elseif self.tool == "rect" or self.tool == "fillrect" or self.tool == "cut" or self.tool == "copy" then
					local i0, j0 = self.start.i, self.start.j
					local i1, j1 = self.finish.i, self.finish.j
					if i0 > i1 then i0, i1 = i1, i0 end
					if j0 > j1 then j0, j1 = j1, j0 end
					local c
					if self.tool == "cut" or self.tool == "copy" then
						self.copyData = {}
						c = {i = i0+math.floor((i1-i0)/2), j = j0+math.floor((j1-j0)/2)}
					end
					for ii = i0, i1 do
						for jj = j0, j1 do
							if self.tool == "rect" then
								if ii ~= i0 and ii ~= i1 and jj ~= j0 and jj ~= j1 then
									goto continue1
								end
							end
							if self.tool == "cut" or self.tool == "copy" then
								table.insert(self.copyData, {di=ii-c.i, dj=jj-c.j, brickData = self.grid[ii][jj].brickData})
								if self.tool == "copy" then
									self.grid[ii][jj].highlighted = true
									goto continue1
								else
									self.mouseMode = 2
								end
							end
							table.insert(self.nodes, self.grid[ii][jj])
							::continue1::
						end
					end
				end
			end
			for k, v in pairs(self.nodes) do
				v.highlighted = true
			end
		end
	else
		if self.mouseFlag then
			self.mouseFlag = false
			self.last_i, self.last_j = nil, nil
			self.storedRainbow = nil
			self.start = nil
			self.finish = nil
			local new = nil
			if self.mouseMode == 1 then
				new = self.selectedButton.brickData
			end
			local key, value
			if self.selectMode == "patch" then
				key, value = self.selectedPatch.key, self.selectedPatch.value
				if self.mouseMode == 2 then
					key = "clear"
				end
			end
			for _, n in pairs(self.nodes) do
				if self.selectMode == "patch" then
					n:setPatch(key, value)
				else
					local old = n.brickData
					if old ~= new then
						local temp = new
						if new then
							if new.id == -1 then
								temp = randomColoredBrick()
							elseif new.id == -2 then
								new = randomColoredBrick()
								temp = new
							end
						end
						n.brickData = temp
						self.undoStack:emplace(n.i, n.j, old, temp)
					end
				end
			end
			if self.tool == "paste" then
				for k, v in pairs(self.copyData) do
					if v.brickData then
						local ii, jj = i+v.di, j+v.dj
						if boundCheck(ii, jj) then
							local n = self.grid[ii][jj]
							local old = n.brickData
							local new = nil
							if self.mouseMode == 1 then
								new = v.brickData
							end
							if old ~= new then
								n.brickData = new
								self.undoStack:emplace(ii, jj, old, new)
							end
						end
					end
				end
			end

			-- for k, v in pairs(self.undoStack:top()) do
			-- 	if v.new then
			-- 		if v.new.id == -1 then
			-- 			local data = randomColoredBrick()
			-- 			v.new = data
			-- 			self.grid[v.i][v.j].brickData = data
			-- 		end
			-- 	end
			-- end

			self.undoStack:advance()
			util.clear(self.redoStack.data)
			self.redoStack:push({})
			self.mouseMode = nil
		end

		if keys.z then
			local undoData = self.undoStack:pop2()
			if undoData then
				for _, v in pairs(undoData) do
					local node = self.grid[v.i][v.j]
					node.brickData = v.old
					v.old, v.new = v.new, v.old
				end
				local r = self.redoStack.data
				r[#r] = undoData
				self.redoStack:advance()
			end
		elseif keys.x then
			local redoData = self.redoStack:pop2()
			if redoData then
				for _, v in pairs(redoData) do
					local node = self.grid[v.i][v.j]
					node.brickData = v.old
					v.old, v.new = v.new, v.old
				end
				local r = self.undoStack.data
				r[#r] = redoData
				self.undoStack:advance()
			end
		end
	end
	for i = 1, 32 do
		for j = 1, 13 do
			self.grid[i][j]:update(dt)
		end
	end
end

function EditorState:update2()
	if keys.escape then
		self.powerupOverlay = false
		return
	end
	if self.powerupExit:update(dt) then
		self.powerupOverlay = false
		return
	end
	if self.powerupSetAll:update(dt) then
		local n = self.numBox3.num
		for i = 1, 135 do
			self.numBoxes[i]:setNumber(n)
			self.weights[i] = n
		end
		self.percentages:update(self.weights)
	end
	if self.powerupReplace:update(dt) then
		local n1 = self.numBox4.num
		local n2 = self.numBox5.num
		for i = 1, 135 do
			if self.numBoxes[i].num == n1 then
				self.numBoxes[i]:setNumber(n2)
				self.weights[i] = n2
			end
		end
		self.numBox4:setNumber(n2)
		self.percentages:update(self.weights)
	end
	if self.disableInactive:update(dt) then
		local dep = PowerUp.dependencies
		local brick = {}
		for n, b in pairs(dep.brick) do
			brick[PowerUp.namesInverse[n]] = {b}
		end
		for i = 1, 32 do
			for j = 1, 13 do
				local node = self.grid[i][j]
				if node.brickData then
					local t = node.brickData.type
					for k, v in pairs(brick) do
						if v[1][t] then
							v[2] = true
						end
					end
				end
			end
		end
		for k, v in pairs(brick) do
			if not v[2] then
				self.numBoxes[k]:setNumber(0)
				self.weights[k] = 0
			end
		end
		local enemy = false
		for k, v in pairs(self.menacerButton.flag) do
			if v then
				enemy = true
				break
			end
		end
		if not enemy then
			for k, v in pairs(dep.enemy) do
				local id = PowerUp.namesInverse[k]
				self.numBoxes[id]:setNumber(0)
				self.weights[id] = 0
			end
		end
		self.percentages:update(self.weights)
	end
	if self.pSave:update(dt) then
		local file = love.filesystem.newFile("powerup_chances.txt")
		file:open("w")
		file:write(self.numBox2.text .. "\n")
		for i = 1, 135 do
			file:write(self.numBoxes[i].text .. "\n")
		end
		file:close()
	end
	if self.pLoad:update(dt) then
		if love.filesystem.getInfo("powerup_chances.txt") then
			local i = 0
			local lines = readlines("powerup_chances.txt")
			for _, line in ipairs(lines) do
				if i == 0 then
					self.numBox2:setText(line)
				else
					self.numBoxes[i]:setText(line)
					self.weights[i] = self.numBoxes[i].num
				end
				i = i + 1
			end
			self.percentages:update(self.weights)
		end
	end
	if self.pLoadDefault:update(dt) then
		local default = powerupGenerator.default_weights
		for i = 1, 135 do
			self.numBoxes[i]:setNumber(default[i])
			self.weights[i] = default[i]
		end
		self.percentages:update(self.weights)
	end

	local flag = false
	for _, n in pairs(self.numBoxes) do
		if n:update(dt) then
			flag = true
			self.weights[n.i] = n.num
		end
	end
	if flag then self.percentages:update(self.weights) end
	self.numBox2:update(dt)
	self.numBox3:update(dt)
	self.numBox4:update(dt)
	self.numBox5:update(dt)

	local state = self.pBind:update(dt)
	if state ~= nil then
		self:togglePowerupButtons(state)
		if state then
			for i = 1, 135 do
				local w = self.backup_weights[i]
				self.numBoxes[i]:setNumber(w)
				self.weights[i] = w
			end
		else
			local default = powerupGenerator.default_weights
			for i = 1, 135 do
				self.backup_weights[i] = self.weights[i]
				local w = default[i]
				self.numBoxes[i]:setNumber(w)
				self.weights[i] = w
			end
		end
		self.percentages:update(self.weights)
	end

	state = self.pBind2:update(dt)
	if state ~= nil then
		if state then
			self.numBox2:setNumber(self.backup_overall_chance)
			self.numBox2.hidden = nil
		else
			self.backup_overall_chance = self.numBox2.num
			self.numBox2:setNumber(powerupGenerator.default_overall_chance*100)
			self.numBox2.hidden = "show_text"
		end
	end
end

function EditorState:update3(dt)
	if keys.escape then
		self.choosePowerUpBrick = false
	end
	if mouse.m1 == 1 then
		local id = PlayState.getPowerUpId(mouse.x, mouse.y)
		if self.choosePowerUpBrick == "pow" then
			if id > 0 then
				self.buttons.powerup.brickData = self.brickData["pow"..id]
			end
			self.choosePowerUpBrick = false
			self.mouseProtect = true
		else
			if id > 0 then
				local check = true
				for _, v in pairs(self.tempSlotPowerUps) do
					if v == id then check = false end
				end
				if check then
					table.insert(self.tempSlotPowerUps, id)
					if #self.tempSlotPowerUps == 3 then
						game.config[self.chooseSlotColor] = self.tempSlotPowerUps
						self.choosePowerUpBrick = false
						self.mouseProtect = true
					end
				end
			else
				self.choosePowerUpBrick = false
				self.mouseProtect = true
			end 
		end
	end
end

function EditorState:draw()
	legacySetColor(self.background.r, self.background.g, self.background.b)
	love.graphics.rectangle("fill", window.lwallx, window.ceiling, window.boardw, window.boardh)
	if self.background.tile then
		local tile = self.background.tile
		local imgstr, rect = tile.imgstr, tile.rect
		legacySetColor(255, 255, 255, 255)
		local w = rect.w * 2
		local h = rect.h * 2
		local across = math.ceil(window.boardw / w)
		local down = math.ceil(window.boardh / h)
		for i = 1, down do
			for j = 1, across do
				draw(imgstr, rect, window.lwallx + w*(j-1), window.ceiling + h*(i-1), 0, w, h, 0, 0)
			end
		end
	end
	
	if self.powerupOverlay then
		self:draw2()
		return
	end
	legacySetColor(187, 187, 187, 255)
	love.graphics.rectangle("fill", 0, 0, window.wallw, window.h)
	love.graphics.rectangle("fill", window.rwallx, 0, window.wallw, window.h)
	love.graphics.rectangle("fill", window.lwallx, 0, window.boardw, window.ceiling)
	legacySetColor(255, 255, 255, 255)
	draw(
		"border", 
		nil, 
		window.w/2, 
		window.ceiling + (window.h - window.ceiling) / 2 - 8, 
		0, 
		224*2,--window.rwallx - window.lwallx + 32, 
		264*2--window.h - window.ceiling + 32
	)

	tooltipManager:draw()

	
	legacySetColor(0, 0, 0, 255)

	love.graphics.setFont(font["Windows32"])
	love.graphics.print("Editor Mode", 10, 10)

	love.graphics.setFont(font["Windows16"])
	love.graphics.print("Press ESC to Play", 10, 40 + 65)
	love.graphics.print("Left-Click to Place", 10, 55 + 65)
	love.graphics.print("Right-Click to Erase", 10, 70 + 65)
	love.graphics.print("Press Z to Undo (Stack: "..(self.undoStack:size()-1)..")", 10, 85 + 65)
	love.graphics.print("Press X to Redo (Stack: "..(self.redoStack:size()-1)..")", 10, 100 + 65)

	-- love.graphics.setFont(font["Windows32"])
	-- love.graphics.print("Tools:", 10, 120)

	-- love.graphics.setFont(font["Windows32"])
	-- love.graphics.printf("Menacer Spawn:", 10, 210, 120, "left")

	-- love.graphics.setFont(font["Munro20"])
	-- love.graphics.print("Undo Stack Size: "..self.undoStack:size()-1, 10, 210)
	-- love.graphics.print("Redo Stack Size: "..self.redoStack:size()-1, 10, 227)

	
	legacySetColor(255, 255, 255, 255)
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(1)
	--draw grid lines
	--horizontal
	for i = 0, 31 do
		love.graphics.line(window.lwallx, window.ceiling + i*16, window.rwallx, window.ceiling + i*16)
	end
	--vertical
	for i = 0, 12 do
		love.graphics.line(window.lwallx+(i*32), window.ceiling, window.lwallx+(i*32), window.h)
	end

	legacySetColor(255, 255, 255, 255)
	love.graphics.setLineWidth(2)

	if self.choosePowerUpBrick then
		local powerupBox = PlayState.powerupBox
		local pow_scale = PlayState.pow_scale

		local function drawPowBox(id)
			legacySetColor(255, 255, 0)
			love.graphics.setLineWidth(2)
			local rect = rects.powerup_ordered[id]
			love.graphics.rectangle("line", powerupBox[1] + (rect.x-16*4*8)*pow_scale, powerupBox[2] + rect.y*pow_scale, rect.w*pow_scale, rect.h*pow_scale)
		end

		legacySetColor(255, 255, 255, 255)
		local height = (window.h-window.ceiling)/320
		draw2("powerup_editor", nil, powerupBox[1], powerupBox[2], 0, pow_scale, pow_scale, 0, 0, 0, 0)

		-- legacySetColor(255, 255, 255, 255)
		-- for _, v in ipairs(PlayState.finishedPowerUpSprites) do
		-- 	local rect, x, y = unpack(v)
		-- 	draw2("powerup_spritesheet", rect, x, y, 0, pow_scale, pow_scale, 0, 0)
		-- end

		if self.choosePowerUpBrick == "pow" then
			drawPowBox(self.buttons.powerup.brickData.args[1])
		else
			if #self.tempSlotPowerUps == 0 then
				for _, v in pairs(game.config[self.chooseSlotColor]) do
					drawPowBox(v)
				end
			else
				for _, v in pairs(self.tempSlotPowerUps) do
					drawPowBox(v)
				end
			end
		end

		love.graphics.setLineWidth(1)
	else
		local w = self.widget
		w.main:draw()
		if w.brickTab.selected then
			w.patchTab:draw()
			w.enemyTab:draw()
			w.brickTab:draw()
		elseif w.patchTab.selected then
			w.brickTab:draw()
			w.enemyTab:draw()
			w.patchTab:draw()
		elseif w.enemyTab.selected then
			w.brickTab:draw()
			w.patchTab:draw()
			w.enemyTab:draw()
		end
		-- self.widget.main:draw()
		-- self.widget.brickTab:draw()
		-- self.widget.patchTab:draw()
		-- self.widget.enemyTab:draw()
		legacySetColor(255, 255, 255, 255)
		if self.widget.brickTab.selected then
			for k, v in pairs(self.buttons) do v:draw() end
			self.selectedButton:drawHighlight()
		elseif self.widget.patchTab.selected then
			for k, v in pairs(self.patchButtons) do v:draw() end
			self.selectedPatch:drawHighlight()
		elseif self.widget.enemyTab.selected then
			self.menacerButton:draw()
		end
	end
	for k, v in pairs(self.toolButtons) do v:draw() end
	self.selectedToolButton:drawHighlight()
	self.powerupButton:draw()

	for i = 1, 32 do
		for j = 1, 13 do
			self.grid[i][j]:draw()
		end
	end

	self.playButton:draw()
	-- self.stopButton:draw()
	self.saveButton:draw()
	self.loadButton:draw()
	self.backgroundButton:draw()
	self.backButton:draw()

	
end

function EditorState:draw2()
	legacySetColor(187, 187, 187, 255)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)

	local wrap = 45
	local w = 20
	local h = 10
	local dx = 170
	local dy = 1
	for i = 1, 135 do
		local r = rects.powerup_ordered[i]
		local ii = (i-1)%wrap
		local jj = math.floor((i-1)/wrap)
		local x, y = jj * (w + dx) + 20, ii * (h + dy) + 68
		legacySetColor(255, 255, 255, 255)
		draw("powerup_spritesheet", r, x, y, 0, w, h, 0, 0)
		legacySetColor(0, 0, 0, 255)
		love.graphics.setFont(font["Munro10"])
		love.graphics.print(PowerUp.names[i], (x + w + 3), (y + 1), 0)
		love.graphics.print(string.format("%8.4f", self.percentages[i]).."%", (x + 140), (y + 1))
		self.numBoxes[i].y = y
		self.numBoxes[i]:draw()
		love.graphics.setFont(font["Arcade40"])
		love.graphics.printf("Edit PowerUp Weights", 0, 20, 800, "center")
	end

	love.graphics.setFont(font["Munro30"])
	--love.graphics.print("Overall Spawn Rate:", 625, 70)
	love.graphics.printf("Overall Spawn Rate:", 600, 70, 200, "left")
	love.graphics.setFont(font["Munro30"])
	love.graphics.print("%", 730, 105)
	love.graphics.setFont(font["Munro20"])
	if self.pBind.state then
		love.graphics.print("with", 715, 235)
	end
	self.numBox4:draw()
	self.numBox5:draw()
	self.powerupReplace:draw()
	self.numBox2:draw()
	self.powerupSetAll:draw()
	self.numBox3:draw()
	self.disableInactive:draw()
	self.pSave:draw()
	self.pLoad:draw()
	self.powerupExit:draw()
	self.pLoadDefault:draw()
	self.pBind:draw()
	self.pBind2:draw()
	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Munro20"])
	love.graphics.print("Custom Weights", 625, 165)
	love.graphics.print("Custom Rate", 625, 140)
end

--if filename is nil then backup the current level
function EditorState:backup(filename)
	if editor_backup <= 0 then return end
	if not filename then
		local empty = true
		for i = 1, 32 do
			for j = 1, 13 do
				local node = self.grid[i][j]
				if node.brickData then
					empty = false
				end
			end
		end
		if empty then return end
	end
	local prev = ""
	for i = 1, editor_backup do
		if love.filesystem.getInfo("levels/!backup"..i..".txt") then
			local temp = love.filesystem.read("levels/!backup"..i..".txt")
			love.filesystem.write("levels/!backup"..i..".txt", prev)
			prev = temp
		else
			love.filesystem.write("levels/!backup"..i..".txt", prev)
			break
		end
	end
	if filename then
		local temp = love.filesystem.read("levels/"..filename)
		love.filesystem.write("levels/!backup1.txt", temp)
	else
		self:saveBricks("!backup1.txt")
	end
end

function EditorState:close()
	--make backups because I keep forgetting to save
	editorstate = nil
	self:backup()
end

function EditorState:placeButtons(dataList, xi, yi, w, h, wrap, special)
	for index, v in ipairs(dataList) do
		index = index - 1
		local i = index % wrap
		local j = math.floor(index / wrap)
		if special then --for use with brickData[1] only
			if i >= 2 and j <= 18 then
				i = i + 1
			end
		end
		local x = xi + (i * w)
		local y = yi + (j * h)
		local button = BrickButton:new(v, x, y, w, h)
		table.insert(self.buttons, button)
	end
end

function containPoint(rect, x, y)
	return x > rect.x and
		   x < rect.x + rect.w and
		   y > rect.y and
		   y < rect.y + rect.h
end

--does NOT provide boundary checks
function getGridPos(x, y)
	local i = math.floor((y - window.ceiling) / 16)
	local j = math.floor((x - window.lwallx) / 32)
	return i+1, j+1
end

function getGridPosInverse(i, j)
	return window.lwallx - 16 + (32 * j), window.ceiling - 8 + (16 * i)
end

function boundCheck(i, j)
	return i >= 1 and i <= 32 and j >= 1 and j <= 13
end

function getNearestPos(i, j)
	return math.max(1, math.min(32, i)), math.max(1, math.min(13, j))
end

--BrickData is a table that has these 4 parameters:
--	imgstr
--  rect: (should be something from rects.brick; never nil)
--  type
--  args

BrickData = class("BrickData")

function BrickData:initialize(imgstr, i, j, type, args)
	self.imgstr = imgstr
	self.rect = rects.brick[i][j]
	self.type = type
	self.args = args
	self.id = staticId
	staticId = staticId + 1
end

function BrickData:draw(x, y, w, h)
	draw(self.imgstr, self.rect, x, y, 0, w, h)
end

BrickButton = class("BrickButton")

--note that x and y denote the top left corners of the button
function BrickButton:initialize(brickData, x, y, w, h)
	self.brickData = brickData
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.selected = false
end

function BrickButton:containPoint(x, y)
	return x >= self.x and
		   x <= self.x + self.w and
		   y >= self.y and
		   y <= self.y + self.h
end

function BrickButton:draw()
	self.brickData:draw(self.x + self.w/2, self.y + self.h/2, self.w, self.h)
end

function BrickButton:drawHighlight()
	legacySetColor(255, 255, 0, 255)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.w-1, self.h-1)
	legacySetColor(255, 255, 255, 255)
end

PatchButton = class("PatchButton")

function PatchButton:initialize(key, value, imgstr, rect, x, y, w, h)
	self.key = key
	self.value = value
	self.imgstr = imgstr
	self.rect = rect
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.selected = false
end

function PatchButton:containPoint(x, y)
	return x >= self.x and
		   x <= self.x + self.w and
		   y >= self.y and
		   y <= self.y + self.h
end

function PatchButton:draw()
	--note that x and y is the location of the top corner of the image
	draw(self.imgstr, self.rect, self.x, self.y, 0, self.w, self.h, 0, 0)
end

function PatchButton:drawHighlight()
	legacySetColor(255, 255, 0, 255)
	love.graphics.rectangle("line", self.x, self.y, self.w-1, self.h-1)
	legacySetColor(255, 255, 255, 255)
end


ToolButton = class("ToolButton")

function ToolButton:initialize(tool, imgstr, rect, x, y, w, h)
	self.tool = tool
	self.imgstr = imgstr
	self.rect = rect
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.selected = false
end

function ToolButton:containPoint(x, y)
	return x >= self.x and
		   x <= self.x + self.w and
		   y >= self.y and
		   y <= self.y + self.h
end

function ToolButton:draw()
	local rw, rh = self.rect[3], self.rect[4]
	--note that x and y is the location of the top corner of the image
	draw(self.imgstr, self.rect, self.x, self.y, 0, self.w, self.h, 0, 0)
end

function ToolButton:drawHighlight()
	legacySetColor(255, 255, 0, 255)
	love.graphics.rectangle("line", self.x, self.y, self.w, self.h-1)
	legacySetColor(255, 255, 255, 255)
end


--GridNode doesn't use Middleclass due to it having a special __index metamethod
--Now that Middleclass has supports __index, I could update this.
GridNode = {}

GridNode.__index = function(node, k)
	if k == "id" then
		if node.brickData then
			return node.brickData.id
		else
			return 0
		end
	elseif k == "up" or k == "down" or k == "left" or k == "right" then
		--requires a reference to "grid"
		if not node.grid then return nil end
		local i, j = node.i, node.j
		if k == "up" then
			i = i - 1
		elseif k == "down" then
			i = i + 1
		elseif k == "left" then
			j = j - 1
		else
			j = j + 1
		end
		if boundCheck(i, j) then
			return node.grid[i][j]
		else
			return nil
		end
	else
		return rawget(GridNode, k)
	end
end

--clear patch when assigned new brickdata from nil
GridNode.__newindex = function(t, k, v)
	if k == "brickData" then
		t:setPatch("clear")
	end
	rawset(t, k, v)
end

--bitwise OR function used for bit masking using bits where you or bits together to get another bits 
function bitOr(a, b)
    local p, c = 1 , 0
    while a + b > 0 do
        local ra, rb= a % 2, b % 2
        if ra + rb > 0 then c = c + p end
        a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
    end
    return c
end
--bitwise AND
function bitAnd(a, b)
    local p, c = 1, 0
    while a > 0 and b > 0 do
        local ra, rb = a % 2, b % 2
        if ra + rb > 1 then c = c + p end
        a , b, p = (a - ra) / 2, (b - rb) / 2, p * 2
    end
    return c
end

--the cycler will keep track of grid node patches and make them cycle through
--each catagory for better visibility
GridNode.Cycler = {set = {}}
GridNode.Cycler.kti = { --key to int
	invisible = 1, 
	shield_up = 2, 
	shield_down = 2, 
	shield_left = 2, 
	shield_right = 2,
	movement = 4,
	antilaser = 8
}
GridNode.Cycler.itk = {
	[1] = "invisible",
	[2] = "shield",
	[4] = "movement",
	[8] = "antilaser"
}
GridNode.Cycler.cycle = {
	["invisible"] = "shield",
	["shield"] = "movement",
	["movement"] = "antilaser",
	["antilaser"] = "invisible"
}
GridNode.Cycler.delay = 0.8
GridNode.Cycler.updatePatch = function(self, node, before, after, key)
	--if before == after then return end

	local set = self.set
	if before ~= 0 then
		if not set[before] then set[before] = {} end
		set[before][node] = nil --sometimes causes problems
	end
	if after ~= 0 then
		if not set[after] then set[after] = {} end
		set[after][node] = true
	end
	if key ~= "clear" then
		if key == "shield_up" 
		or key == "shield_down" 
		or key == "shield_left" 
		or key == "shield_right" then
			key = "shield"
		end
		for node, v in pairs(set[after]) do
			node.patchCycleTimer = 0
			node.patchCycleMode = key
		end
	end
end
GridNode.Cycler.reset = function(self, grid)
	local set = self.set
	util.clear(set)
	for i = 1, 32 do
		for j = 1, 13 do
			local node = grid[i][j]
			local mask = 0
			if node.brickData then
				for k, v in pairs(node.patch) do
					mask = bitOr(mask, self.kti[k])
				end
				if mask ~= 0 then
					if not set[mask] then set[mask] = {} end
					set[mask][node] = true
					node.patchCycleTimer = 0
					for _, i in ipairs({1, 2, 4, 8}) do
						if bitAnd(mask, i) ~= 0 then
							node.patchCycleMode = (self.itk[i])
							break
						end
					end
				end
			end
		end
	end
end

function GridNode:new(i, j)
	local node = {}
	node.i = i
	node.j = j
	node.x = window.lwallx + 16 + ((j-1) * 32)
	node.y = window.ceiling + 8 + ((i-1) * 16)
	node.patch = {}
	node.patchCycleTimer = 0
	node.patchCycleMode = nil
	setmetatable(node, self)
	return node
end

--modified so that it affects the cycler
function GridNode:setPatch(key, value)
	local mask_before = 0
	local mask_after = 0
	for k, v in pairs(self.patch) do mask_before = bitOr(mask_before, GridNode.Cycler.kti[k]) end

	if key == "clear" then
		util.clear(self.patch)
	else
		self.patch[key] = value
		mask_after = bitOr(mask_before, GridNode.Cycler.kti[key])
	end

	GridNode.Cycler:updatePatch(self, mask_before, mask_after, key)
end

--currently update will be used for cycling patches
function GridNode:update(dt)
	if next(self.patch) then --checks if the patch table is not empty
		self.patchCycleTimer = self.patchCycleTimer + dt
		if self.patchCycleTimer >= GridNode.Cycler.delay then
			self.patchCycleTimer = 0
			local patch = self.patch

			local shield = patch["shield_up"] or patch["shield_down"] or patch["shield_left"] or patch["shield_right"]
			local mode, check = self.patchCycleMode, false
			repeat
				mode = GridNode.Cycler.cycle[mode]
				if mode == "shield" then
					check = shield
				else
					check = patch[mode] ~= nil
				end
			until (check)
			self.patchCycleMode = mode
		end
	end
end

function GridNode:draw()
	legacySetColor(255, 255, 255, 255)
	if self.brickData then
		self.brickData:draw(self.x, self.y, 32, 16)

		if next(self.patch) then
			if self.patchCycleMode == "shield" then
				for _, key in ipairs({"shield_up", "shield_down", "shield_left", "shield_right"}) do
					local value = self.patch[key]
					if value then
						EditorState.drawPatch(key, value, self.x, self.y, 32, 16)
					end
				end
			else
				local key = self.patchCycleMode
				local value = self.patch[key]
				if value then
					EditorState.drawPatch(key, value, self.x, self.y, 32, 16)
				end
			end
		end
	end

	if self.highlighted then
		legacySetColor(255, 255, 255, 128)
		love.graphics.rectangle("fill", self.x - 16, self.y - 8, 32, 16)
	end
end

function GridNode:makeBrick()
	if not self.brickData then
		return nil
	end
	local Constructor = _G[self.brickData.type]
	local brick = Constructor:new(self.x, self.y, unpack(self.brickData.args))
	brick:setPatches(self.patch)
	return brick
end