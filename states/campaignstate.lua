CampaignState = class("CampaignState")

--savefile contains level, score, lives, route
function CampaignState:save(filename)
	filename = filename or "campaign_save.txt"
	local file = love.filesystem.newFile(filename)
	file:open("w")
	file:write("local data = {\n")

	file:write("\tscore = "..self.score..",\n")
	file:write("\tlives = "..self.lives..",\n")
	file:write("\tlevel = \""..self.level.."\",\n")
	local routestr = util.tableToString(self.route)
	file:write("\troute = "..routestr..",\n")

	file:write("}\n")
	file:write("return data")

	file:close()
end

function CampaignState:load(filename)
	filename = filename or "campaign_save.txt"
	if not love.filesystem.getInfo(filename) then
		-- self:reset()
		return
	end

	local chunk = love.filesystem.load(filename)
	local data = chunk()

	self.score = data.score
	self.lives = data.lives
	self.level = data.level
	self.route = data.route

	--set preview
	if self.level == "zoneselect" then
		self.choices = self.graph[self.route[#self.route]]
		local lines = LevelSelectState.readPlaylist("_Zone"..self:getZone())
		self.info.preview = LevelSelectState.generatePreview(lines[1])
		self:chooseZone()
	else
		self.info.preview = LevelSelectState.generatePreview(self.level)
	end

	local len = #self.route
	for i, n in ipairs(self.route) do
		if i == len then
			self.nodes[n]:setState("current")
			self.otakuball:setPos(self.nodes[n]:getPos())
		else
			self.nodes[n]:setState("beaten")
		end
	end
end

--clears all progress on the campaign
--also does some initialization
function CampaignState:reset()
	self.state = "idle"
	--reset scores and lives
	self.score = 0
	self.lives = 3
	self.route = {'A'}
	self.level = "_RoundA1"
	--set preview
	self.info.preview = LevelSelectState.generatePreview(self.level)
	--reset all nodes
	for _, n in pairs(self.nodes) do
		n:setState("normal")
	end
	self.nodes['A']:setState("current")
	--spawn the OtakuBall character
	self.otakuball = OtakuBall:new(self.nodes['A']:getPos())
end

function CampaignState:initialize()
	campaignstate = self

	self.state = "idle" --idle, zoneselect

	self.callbacks = {}

	local off = 40
	local delta = 60

	local width = window.w/2 - off + delta
	self.map = {
		x = off,
		y = off,
		w = width,
		h = window.h - off*2,
		imgstr = "background",
		rect = rects.bg[13][1],
		draw = function(mself)
			local mx, my, mw, mh = mself.x, mself.y, mself.w, mself.h
			fillrect({216, 216, 216}, mx, my, mw, mh)
			fillrect({64, 64, 64}, mx, my, mw-2, mh-2)
			fillrect({128, 128, 128}, mx+2, my+2, mw-4, mh-4)

			mx, my, mw, mh = mx+2, my+2, mw-6, mh-6

			love.graphics.setColor(1, 1, 1, 1)
			draw("campaign_bg", nil, mx, my, 0, 414, 514, 0, 0)

			-- love.graphics.setScissor(mx, my, mw, mh)
			-- local imgstr, rect = mself.imgstr, mself.rect
			-- legacySetColor(255, 255, 255, 255)
			-- local w = rect.w * 2
			-- local h = rect.h * 2
			-- local across = math.ceil(mw / w)
			-- local down = math.ceil(mh / h)
			-- for i = 1, down do
			-- 	for j = 1, across do
			-- 		draw(imgstr, rect, mx + w*(j-1), my + h*(i-1), 0, w, h, 0, 0)
			-- 	end
			-- end
			-- love.graphics.setScissor()
		end,
	}

	local width = window.w/2 - off*2 - delta
	local info = MessageBox:new(window.w/2 + off + delta, off, width, window.h - off*2, "Round A1")
	self.info = info
	--need to initialize info.preview
	info.draw = function(iself)
		if self.level == "zoneselect" then
			iself.title = "Select Zone"
		else
			iself.title = self.level:sub(2)
		end
		MessageBox.draw(iself)
		local x, y, w, h = iself.x, iself.y, iself.w, iself.h

		local pw, ph = 208, 256
		local px = x + (w - pw)/2
		local py = y + 50
		legacySetColor(255, 255, 255, 255)
		draw("border", nil, px+pw/2, py+ph/2-4)
		love.graphics.push()
		love.graphics.scale(1, 1)
		love.graphics.draw(iself.preview, px, py)
		love.graphics.pop()

		legacySetColor(0, 0, 0, 255)
		love.graphics.setFont(font["Arcade20"])
		love.graphics.print("Score", x + 16, y + 312)

		local scorestr = PlayState.getScoreStr(self.score, .33, 0)
		legacySetColor(255, 255, 255, 255)
		love.graphics.setFont(font["Arcade30"])
		love.graphics.print(scorestr, x + 32, y + 335)

		legacySetColor(0, 0, 0, 255)
		love.graphics.setFont(font["Arcade20"])
		love.graphics.print("Lives", x + 16, y + 375)

		local lives = self.lives
		legacySetColor(255, 255, 255, 255)
		if lives > 5 then
			draw("paddle_life", nil, px+8, py + 350, 0, 32, 16, 0, 0)
			love.graphics.setFont(font["Arcade20"])
			love.graphics.print(lives, px+8 + 32, py + 350)
		else
			for i = 1, lives do
				draw("paddle_life", nil, px+8 + 32*(i-1), py + 350, 0, 32, 16, 0, 0)
			end
		end
	end

	self:initNodes()
	self.route = {"A"}
	self.nodes[self:getZone()].highlighted = true

	--big PLAY button on left
	--small reset and small back buttons on left
	self.playbutton = Button:new(
		info.x + 16,
		info.y + info.h - 65 - 16,
		info.w - 16*2 - 100 - 5,
		65,
		{text = "Play", font = font["Arcade30"]}
	)
	self.resetbutton = Button:new(
		info.x + info.w - 100 - 16,
		info.y + info.h - 65 - 16,
		100,
		30,
		{text = "Reset", font = font["Arcade20"]}
	)
	self.backbutton = Button:new(
		self.resetbutton.x,
		self.resetbutton.y + 35,
		100,
		30,
		{text = "Back", font = font["Arcade20"]}
	)

	self:reset()
	self:load()
end

function CampaignState:initNodes()
	local graph = {
		A = {"B", "C"},
		B = {"D", "E"},
		C = {"E", "F"},
		D = {"G"},
		E = {"G", "H"},
		F = {"H"},
		G = {"I", "J"},
		H = {"J", "K"},
		I = {"L"},
		J = {"L"},
		K = {"L"},
		L = {}
	}
	local nodes = {}
	--initialize all the nodes
	for k, v in pairs(graph) do
		nodes[k] = Node:new(k)
	end
	--link all the nodes
	for n, t in pairs(graph) do
		local node = nodes[n]
		for _, v in ipairs(t) do
			node:add(nodes[v])
		end
	end
	--determine the height of each node (recursively)
	nodes["A"]:calculateHeight()
	--order the nodes based on height and sort them into a logical format
	local layers = {}
	for _, n in pairs(nodes) do
		local h = n.height + 1
		if not layers[h] then
			layers[h] = {}
		end
		table.insert(layers[h], n)
	end
	for i, t in ipairs(layers) do
		table.sort(t, function(a, b) return a.value < b.value end)
		-- local s = {}
		-- for ii, n in ipairs(t) do
		-- 	table.insert(s, n.value)
		-- end
		-- print(unpack(s))
	end
	--assign coordinates to each node so they can be drawn
	local dx, dy = 175, 90
	local ix = self.map.x + self.map.w/2
	local iy = 70
	for i, t in ipairs(layers) do
		local len = #t
		for j, n in ipairs(t) do
			n.x = ix + (j-(len-1)/2-1)*dx
			n.y = iy + (i-1)*dy
		end
	end
	-- nodes["L"].y = nodes["L"].y - dy

	self.nodes = nodes
	self.graph = graph
end

--get the current zone
function CampaignState:getZone()
	return self.route[#self.route]
end

function CampaignState:chooseZone()
	self.state = "zoneselect"
	self.playbutton.disabled = true
	self.nextNodes = {}
	for _, zone in ipairs(self.choices) do
		table.insert(self.nextNodes, self.nodes[zone])
	end
end

function CampaignState:advance(zone)
	self.state = "idle"
	self.playbutton.disabled = false
	self.nodes[self:getZone()]:setState("beaten")
	table.insert(self.route, zone)
	self.nodes[zone]:setState("current")
	self:moveChar()
	--set level to be first level of next zone
	self:record()
end


--called when there is a gameover
--rollback to 1st or 5th level of the zone
function CampaignState:rollback()
	-- if n - 1 is multiple of 4
	--1, 5, 9, 13 ...
	local num = self.level:sub(8)
	num = (math.floor((num-1) / 4)) * 4 + 1
	local newLevel = self.level:sub(1, 7)..num
	print(newLevel)
	self:record(newLevel)
	self.score = 0
	self.lives = 3
end

--if level is nil, get the first level of the next zone
--if level is "zoneselect" do special stuff
--if level is "gameover" rollback and do special stuff
--otherwise, save level in current zone
function CampaignState:record(level)
	--print("record "..level)
	if not level then
		local lines = LevelSelectState.readPlaylist("_Zone"..self:getZone())
		self.level = lines[1]
		self.info.preview = LevelSelectState.generatePreview(self.level)
	elseif level == "zoneselect" then
		self.score = playstate.score
		self.lives = playstate.lives
		self.level = "zoneselect"
	elseif level == "gameover" then
		self.score = 0
		self.lives = 3
		local n = self.level:sub(8)
		n = (math.floor((n-1)/4))*4+1
		self.level = self.level:sub(1, 7)..n
	else
		self.score = playstate.score
		self.lives = playstate.lives
		self.level = level
		self.info.preview = LevelSelectState.generatePreview(self.level)
	end
	
	self:save()
end

--moves Otakuball to the next zone
function CampaignState:moveChar()
	local n = self.nodes[self:getZone()]
	local x, y = n:getPos()
	self.otakuball:moveTo(x, y, 0)
end

function CampaignState:update(dt)
	if self.backbutton:update(dt) or keys.escape then
		game:pop()
		return
	end
	if self.resetbutton:update(dt) then
		game:push(CampaignResetPrompt(
			"Campaign Reset Confirmation",
			"Are you sure you want to reset all progress?",
			function()
				self:reset()
				self:save()
			end
		))
	end
	if self.playbutton:update(dt) then
		local zone = self:getZone()
		local lines = LevelSelectState.readPlaylist("_Zone"..zone)
		local choices = self.graph[zone]
		self.choices = choices
		--if #choices == 0 then choices = nil end
		local queue = Queue:new(lines)
		if self.level ~= "zoneselect" then
			while queue:peekLeft() ~= self.level do
				queue:popLeft()
			end
		end
		-- game:push(PlayState:new("play", queue, choices))
		self.otakuball:stopMoving()
		self.otakuball:stopAnimation()
		self.otakuball.rect = rects.map.char[2][3]
		self.otakuball:playAnimation("OtakuBallFistPump")
		local cb1 = {2, function()
			local ps = PlayState:new("play", queue, choices)
			ps.score = self.score
			ps.lives = self.lives
			ps.round = tonumber(self.level:sub(8))
			game:push(ps)
			self.fadeOut = nil
			self.otakuball.rect = rects.map.char[1][1]
			self.otakuball:playAnimation("OtakuBallIdle", true)
			self.playbutton.disabled = false
			self.resetbutton.disabled = false
		end}
		local cb2 = {1, function()
			self.fadeOut = 0
			self.fadeVel = 255/1
		end}
		self.callbacks = {cb1, cb2}
		self.playbutton.disabled = true
		self.resetbutton.disabled = true
	end
	if self.state == "zoneselect" then
		if mouse.m1 == 1 then
			for _, node in ipairs(self.nextNodes) do
				if node:containMouse() then
					print("selected "..node.value)
					self:advance(node.value)
				end
			end
		end
	end
	for _, n in pairs(self.nodes) do
		n:update(dt)
	end
	self.otakuball:update(dt)
	if self.fadeOut then
		self.fadeOut = math.max(self.fadeOut + dt * self.fadeVel)
	end
	util.remove_if(self.callbacks, function(cb)
		cb[1] = cb[1] - dt
		if cb[1] <= 0 then
			cb[2]()
			return true
		end
		return false
	end)
	-- if self.callback then
	-- 	self.callback[1] = self.callback[1] - dt
	-- 	if self.callback[1] <= 0 then
	-- 		self.callback[2]()
	-- 		self.callback = nil
	-- 	end
	-- end
end

function CampaignState:draw()
	legacySetColor(100, 100, 100, 255)
	love.graphics.rectangle("fill", 0, 0, window.w, window.h)
	self.map:draw()
	--draw edges first
	for _, node in pairs(self.nodes) do
		node:drawEdges()
	end
	--then draw nodes over edges
	for _, node in pairs(self.nodes) do
		--node:drawNode()
		node:draw()
	end
	self.otakuball:draw()
	self.info:draw()
	self.playbutton:draw()
	self.backbutton:draw()
	self.resetbutton:draw()

	if self.state == "zoneselect" then
		legacySetColor(255, 255, 255, 255)
		love.graphics.setFont(font["Arcade30"])
		love.graphics.print("Choose Next Zone", 0, 0)
	end

	if self.fadeOut then
		legacySetColor(0, 0, 0, math.floor(self.fadeOut))
		love.graphics.rectangle("fill", 0, 0, window.w, window.h)
	end
end

Node = class("Node", Sprite)

local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
letterLookup = {}
for i = 1, 26 do
	local l = alphabet:sub(i, i)
	letterLookup[i] = l
	letterLookup[l] = i
end

function Node:initialize(value)
	local index = letterLookup[value]
	Sprite.initialize(self, "campaign_icon", rects.map.icon[1][index], 52, 52)
	self.value = value
	self.edges = {}
	self.state = "normal"
end

function Node:setState(state)
	local index = letterLookup[self.value]
	if state == "current" then
		self.ncolor = 2
		self.rect = rects.map.icon[self.ncolor][index]
		self.flashTimer = 0
	elseif state == "beaten" then
		self.rect = rects.map.icon[3][1]
	else --state == "normal"
		self.rect = rects.map.icon[1][index]
	end
	self.state = state
end

function Node:add(node)
	table.insert(self.edges, node)
end

--finds the height of the node and set it as a variable
function Node:calculateHeight()
	local result = 0
	if #self.edges > 0 then
		local t = {}
		for i, n in ipairs(self.edges) do
			table.insert(t, n:calculateHeight())
		end
		result = 1 + math.max(unpack(t))
	end
	self.height = result
	return result
end

function Node:containMouse()
	return util.dist(self.x, self.y, mouse.x, mouse.y) < 26
end

function Node:update(dt)
	if self.state == "current" then
		self.flashTimer = self.flashTimer + dt
		if self.flashTimer >= 0.5 then
			self.flashTimer = 0
			self.ncolor = (self.ncolor == 1) and 2 or 1
			self.rect = rects.map.icon[self.ncolor][letterLookup[self.value]]
		end
	end
end

function Node:drawEdges()
	love.graphics.setLineStyle("rough")
	love.graphics.setLineWidth(4)
	for _, e in ipairs(self.edges) do
		if self.state ~= "normal" and e.state ~= "normal" then
			legacySetColor(0, 255, 0, 255)
		else
			legacySetColor(255, 0, 0, 255)
		end
		love.graphics.line(self.x, self.y, e.x, e.y)
	end
end

function Node:draw()
	Sprite.draw(self)
	if self.state == "beaten" then
		draw(self.imgstr, rects.map.icon[3][2], self.x, self.y, 0, self.w, self.h)
	end
end

-- function Node:drawNode()
-- 	local r = 20
-- 	local o = 3
-- 	local c = self.highlighted and {0, 0, 255, 255} or {0, 0, 0, 255}
-- 	legacySetColor(unpack(c))
-- 	love.graphics.circle("fill", self.x, self.y, r)
-- 	legacySetColor(100, 100, 100, 255)
-- 	love.graphics.circle("fill", self.x, self.y, r-o)
-- 	legacySetColor(unpack(c))
-- 	local f = font["Munro30"]
-- 	local w, h = f:getWidth(self.value), f:getHeight(self.value)
-- 	love.graphics.setFont(f)
-- 	love.graphics.print(self.value, math.ceil(self.x-w/2), math.ceil(self.y-h/2))
-- end

OtakuBall = class("OtakuBall", Sprite)

function OtakuBall:initialize(x, y)
	Sprite.initialize(
		self, 
		"campaign_char", 
		rects.map.char[1][1],
		42,
		32,
		x,
		y
	)
	self:playAnimation("OtakuBallIdle", true)
	self.move = nil
end

function OtakuBall:moveTo(x, y)
	local spd = 50
	local dx, dy = x - self.x, y - self.y
	local dist = math.sqrt(dx*dx + dy*dy)
	if dist == 0 then return end
	local t = dist / spd
	local vx = dx / dist * spd
	local vy = dy / dist * spd

	self:setVel(vx, vy)
	self:playAnimation("OtakuBallWalkBackward", true)
	self.move = {x = x, y = y, timer = t}
end

function OtakuBall:stopMoving()
	if not self.move then return end
	local move = self.move
	self:setPos(move.x, move.y)
	self:setVel(0, 0)
	self:playAnimation("OtakuBallIdle", true)
	self.move = nil
end

function OtakuBall:update(dt)
	if self.move then
		local move = self.move
		move.timer = move.timer - dt
		if move.timer <= 0 then
			self:stopMoving()
		end
	end
	Sprite.update(self, dt)
end

--add an offset since the sprite is not centered
function OtakuBall:draw()
	love.graphics.push()
	love.graphics.translate(0, 0)
	Sprite.draw(self)
	love.graphics.pop()
end


CampaignResetPrompt = class("CampaignResetPrompt")

function CampaignResetPrompt:initialize(title, message, callback)
	self.callback = callback
	-- local text
	-- if mode == "playlist_edit" then
	-- 	text = "Are you sure you want to override this playlist?"
	-- else
	-- 	text = "Are you sure you want to replace an existing level?"
	-- end
	self.box = MessageBox:new(window.w/2 - 200, window.h/2 - 75, 400, 150, title, message)
	local b1 = Button:new(0, 0, 90, 30, {text = "Yes", font = font["Arcade20"]})
	local b2 = Button:new(0, 0, 90, 30, {text = "Cancel", font = font["Arcade20"]})
	self.box:addButton(b1, 200, 110)
	self.box:addButton(b2, 300, 110)
end

function CampaignResetPrompt:update(dt)
	--self.box:update(dt)
	if self.box.buttons[1]:update(dt) or keys["return"] then
		self.callback()
		game:pop()
	end
	if self.box.buttons[2]:update(dt) or keys.escape then
		game:pop()
	end
end

function CampaignResetPrompt:draw()
	--draw the state before it too
	game.states[#game.states-1]:draw()
	self.box:draw()
end