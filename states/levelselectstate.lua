LevelSelectState = class("LevelSelectState")

local function drawWidget(widget)
	local border = 2
	legacySetColor(80, 80, 80, 255)
	love.graphics.rectangle("fill", widget.x, widget.y, widget.w, widget.h)
	legacySetColor(150, 150, 150, 255)
	love.graphics.rectangle("fill", widget.x + border, widget.y + border, widget.w - border*2, widget.h - border*2)
end

local function unpackDim(box)
	return box.x, box.y, box.w, box.h
end

function LevelSelectState.generatePreview(file)
	local chunk = nil
	if file:sub(1, 1) == "_" then
		chunk = love.filesystem.load("default_levels/"..file)
	else
		chunk = love.filesystem.load("levels/"..file)
	end
	if not chunk then return "error" end
	local data = chunk()
	if not data then return "error" end

	local canvas = love.graphics.newCanvas(208, 256)
	love.graphics.setCanvas(canvas)
		local bg = data.background
		if bg then
			legacySetColor(bg.r, bg.g, bg.b, 255)
			love.graphics.rectangle("fill", 0, 0, 208, 256)
			legacySetColor(255, 255, 255, 255)
			if bg.tile then
				local imgstr = bg.tile.imgstr
				local rect = rects.bg[bg.tile.i][bg.tile.j]
				local w = rect.w
				local h = rect.h
				local across = math.ceil(208 / w)
				local down = math.ceil(256 / h)
				for i = 1, down do
					for j = 1, across do
						draw(imgstr, rect, w*(j-1), h*(i-1), 0, w, h, 0, 0)
					end
				end
			end
		else
			legacySetColor(0, 0, 128, 255)
			love.graphics.rectangle("fill", 0, 0, 208, 256)
		end
		legacySetColor(255, 255, 255, 255)
		for _, v in pairs(data.bricks) do
			local i, j, id, patch = unpack(v)
			local x, y = j*16-8, i*8-4
			local brickData = EditorState.brickDataLookup[id]
			brickData:draw(x, y, 16, 8)
			for k, v in pairs(patch) do
				EditorState.drawPatch(k, v, x, y, 16, 8)
			end
		end
	love.graphics.setCanvas()

	--enemy stuff
	local flags = data.menacer
	local check = true
	if not flags then check = false end
	local menacers = {"redgreen", "cyan", "bronze", "silver", "pewter"}
	local enemies = {"dizzy", "cubic", "gumballtrio", "walkblock"} 
	local canvas2 = love.graphics.newCanvas(120, 48)
	love.graphics.setCanvas(canvas2)
		love.graphics.setColor(1, 1, 1)
		for i = 1, 5 do
			if check and data.menacer[menacers[i]] then
				love.graphics.setColor(1, 1, 1)
			else
				love.graphics.setColor(0.25, 0.25, 0.25)
			end
			local rect = make_rect(0, (i-1)*12, 12, 12)
			draw("menacer_editor", rect, (i-1)*24 + 12, 12, 0, 24, 24)
		end
		for i = 1, 4 do
			if check and data.menacer[enemies[i]] then
				love.graphics.setColor(1, 1, 1)
			else
				love.graphics.setColor(0.25, 0.25, 0.25)
			end
			local rect = make_rect((i-1)*12, 0, 12, 12)
			draw("enemy_editor", rect, (i-1)*24 + 12, 36, 0, 24, 24)
		end
	love.graphics.setCanvas()

	love.graphics.setColor(1, 1, 1, 1)

	return canvas, canvas2
end

function LevelSelectState.genEnemyPreview(file)

end

function LevelSelectState.readPlaylist(file)
	if file:sub(1, 1) == "_" then
		return readlines("default_playlists/"..file)
	else
		return readlines("playlists/"..file)
	end
end

function LevelSelectState.savePlaylist(filename, lines)
	local file = love.filesystem.newFile("playlists/"..filename)
	file:open("w")
	for i, line in ipairs(lines) do
		file:write(line.."\n")
	end
	file:close()
end

--self.files is a list of lists containing the filename and preview canvas
--and also the enemy list
function LevelSelectState:loadFileList()
	love.filesystem.createDirectory("levels") --creates a folder in the save directory if missing
	love.filesystem.createDirectory("playlists")

	local default, user
	if self.mode == "playlist" then
		default = love.filesystem.getDirectoryItems("default_playlists")
		user = love.filesystem.getDirectoryItems("playlists")
	else
		default = love.filesystem.getDirectoryItems("default_levels")
		user = love.filesystem.getDirectoryItems("levels")
	end

	if self.mode == "editor_save" or prefs.hide_default then
		default = {}
	end
	
	self.files = {}
	local sz = 0

	for i, f in ipairs(default) do
		self.files[i] = {f}
		sz = sz + 1
	end
	for i, f in ipairs(user) do
		self.files[i+sz] = {f}
	end

	--get rid of the pesky .DS_Store that appears in Mac folders
	util.remove_if(self.files, function(file) return file[1] == ".DS_Store" end)
	self.numfiles = #self.files
end

--returns the index of the file and the index of the closest match
function LevelSelectState:findFile(name)
	local start = (self.mode == "editor_save" or (self.mode == "playlist" and not self.restrict_playlist)) and 2 or 1
	local index, close_index = 0, 0
	--assuming the files are listed in alphabetical order
	local lines, n = self.files, self.numfiles
	for i = start, n do
		local file = lines[i]
		if file[1] == name then
			if index == 0 then
				index = i
			end
		end
		if string.sub(file[1], 1, #name) == name then
			if close_index == 0 then
				close_index = i
			end
		end
	end
	return index, close_index
end

--true means hide default levels
--false means show them

--why not just reset everything? lol
function LevelSelectState:toggleDefault(state)
	local prevstate = self.prevstate --make sure prevstate is not compromised
	prefs.hide_default = state
	self:initialize(self.mode)
	self.prevstate = prevstate
	self.dwidget.hidedefault.state = state
end

function LevelSelectState:togglePlaylistEdit(state)
	if state then
		table.insert(self.playlist[2], "")
		self:initialize("playlist_edit", self.playlist)
	else
		table.remove(self.playlist[2])
		self:initialize("playlist", self.playlist[1])
	end
end

function LevelSelectState:initialize(mode, option)
	self.prevstate = game:top()

	--"level_select", "editor_save", "editor_load", "playlist", "playlist_edit"
	--remember: playlist has 2 modes: 2 buttons and 4 buttons
	--playlist_edit is when you're actually editing the playlist
	self.mode = mode or "level_select"
	self.newFileString = "===NEW FILE==="

	--mode = "playlist" and option = true -> play playlist only
	--mode = "playlist" and option = false -> play and edit playlist
	if self.mode == "playlist" and option then
		self.restrict_playlist = true
		option = nil
	end

	self:loadFileList()
	if self.mode == "editor_save" then
		table.insert(self.files, 1, {self.newFileString, "error"})
		self.numfiles = self.numfiles + 1
	elseif self.mode == "playlist" and not self.restrict_playlist then
		local t = {"Create a new playlist!"}
		for i = 1, 22 do table.insert(t, "") end
		table.insert(t, "What are you waiting for?")
		table.insert(self.files, 1, {self.newFileString, t})
		self.numfiles = self.numfiles + 1
	end
	-- if self.mode == "playlist_edit" then
	-- 	self.playlist = option --remember playlist is a table: {name, lines}
	-- end

	--gwidget is the giant window that contains all 3 widgest
	--lwidget has the file browser
	--rwidget has the preview
	--dwidget has the textbox
	local gwidget, lwidget, rwidget, dwidget


	local text = "Level Select"
	if self.mode == "editor_save" then 
		text = "Save Bricks"
	elseif self.mode == "editor_load" then
		text = "Load Bricks"
	elseif self.mode == "playlist" and self.restrict_playlist then
		text = "Play Playlist"
	else
		text = "Edit Playlist"
	end
	gwidget = MessageBox:new(40, 20, window.w - 80, window.h - 40, text)

	lwidget = {
		n = 23, --# of files that can be displayed at once
		x = 50, 
		y = 50 + 4, 
		w = window.w/2 - 55, 
		h = window.h - 150
	}
	--Munro20 is exactly 18 pixels tall
	lwidget.textbox = {
		focus = true,
		n = lwidget.n,
		x = lwidget.x + 20,
		y = lwidget.y + 20,
		w = lwidget.w - 40 - 20,
		h = lwidget.h - 40 + 4, --now it is tall enough for exactly 23 rows of 18 pixels tall
		index = 1,
		offset = 0
	}
	lwidget.scrollbar = {
		n = lwidget.n,
		x = lwidget.x + 300 + 10,
		y = lwidget.y + 20,
		w = 15,
		h = lwidget.h - 40 + 4,
		textbox = lwidget.textbox
	}
	lwidget.textbox.update = function(tbox, dt)
		local lines, nlines = self.files, self.numfiles
		nlines = math.max(1, nlines)
		if tbox.focus and (keys.up or keys.down) then
			if keys.up then
				tbox.index = math.max(1, tbox.index - 1)
			else
				tbox.index = math.min(nlines, tbox.index + 1)
			end
			tbox.offset = math.max(math.min(tbox.offset, tbox.index - 1), tbox.index - tbox.n)
			dwidget.textbox.text = lines[tbox.index][1]
			tbox.transparent = false
		end
		if mouse.m1 == 1 then
			local mx, my = mouse.x, mouse.y
			if mx > tbox.x and mx < tbox.x + tbox.w and my > tbox.y and my < tbox.y + tbox.h then
				if self.mode == "playlist" or self.mode == "playlist_edit" then
					tbox.focus = true
					rwidget.textbox.focus = false
				end
				local dy = my - tbox.y
				local row = math.floor(dy / 18) + 1
				tbox.index = row + tbox.offset
				tbox.index = math.min(nlines, tbox.index)
				local line = lines[tbox.index]
				dwidget.textbox.text = line[1]
				tbox.transparent = false
			end
		end
	end
	lwidget.textbox.draw = function(tbox)
		local lines = self.files
		legacySetColor(200, 200, 200, 255)
		love.graphics.rectangle("fill", unpackDim(tbox))
		love.graphics.setScissor(unpackDim(tbox))
		legacySetColor(255, 255, 0, tbox.transparent and 128 or 255)
		love.graphics.rectangle("fill", tbox.x, tbox.y + (tbox.index-1-tbox.offset)*18, tbox.w, 18)
		love.graphics.setFont(font["Munro20"])
		for i, line in ipairs(lines) do
			if line[1]:sub(1, 1) == "_" then
				legacySetColor(0, 0, 255, 255)
			else
				legacySetColor(0, 0, 0, 255)
			end
			love.graphics.print(line[1], tbox.x + 2, tbox.y + (i-1-tbox.offset)*18 - 0)
		end
		love.graphics.setScissor()
	end
	lwidget.scrollbar.update = function(sc, dt)
		local lines, nlines = self.files, self.numfiles
		nlines = math.max(1, nlines)
		sc.bar = {}
		local bar = sc.bar
		bar.x = sc.x
		bar.w = sc.w
		bar.h = sc.h * math.min(sc.n / nlines, 1)
		bar.y = sc.y + sc.textbox.offset * sc.h / nlines
		if mouse.m1 == 1 then
			local mx, my = mouse.x, mouse.y
			if mx > bar.x and mx < bar.x + bar.w and my > bar.y and my < bar.y + bar.h then
				sc.drag = {my, sc.textbox.offset}
			end
		elseif mouse.m1 == 2 then
			if sc.drag then
				local offset = sc.textbox.offset
				local dy = mouse.y - sc.drag[1]
				local doff = math.floor((nlines) * (dy / sc.h))
				offset = math.min(math.max(sc.drag[2] + doff, 0), math.max(nlines - sc.n, 0))
				sc.textbox.offset = offset
			end
		else
			sc.drag = nil
		end
		if containPoint(lwidget, mouse.x, mouse.y) then
			if mouse.scrollup then
				sc.textbox.offset = sc.textbox.offset - 1
				sc.textbox.offset = math.min(math.max(sc.textbox.offset, 0), math.max(nlines - sc.n, 0))
			end
			if mouse.scrolldown then
				sc.textbox.offset = sc.textbox.offset + 1
				sc.textbox.offset = math.min(math.max(sc.textbox.offset, 0), math.max(nlines - sc.n, 0))
			end
		end
	end
	lwidget.scrollbar:update(0) --have to call this function to make sure bar is initialized
	lwidget.scrollbar.draw = function(sc)
		legacySetColor(200, 200, 200, 255)
		love.graphics.rectangle("fill", sc.x, sc.y, sc.w, sc.h)
		legacySetColor(110, 110, 110, 255)
		love.graphics.rectangle("fill", sc.bar.x, sc.bar.y, sc.bar.w, sc.bar.h)
	end
	lwidget.update = function(widget, dt)
		widget.textbox:update(dt)
		widget.scrollbar:update(dt)
	end
	lwidget.draw = function(widget)
		drawWidget(widget)
		widget.textbox:draw()
		widget.scrollbar:draw()
	end

	rwidget = {
		x = window.w/2 + 5, 
		y = 50 + 4, 
		w = window.w/2 - 55, 
		h = window.h - 150,
	}
	if not (self.mode == "playlist" or self.mode == "playlist_edit") then
		local pw, ph = 208, 256
		rwidget.preview = {
			x = math.floor(rwidget.x + rwidget.w/2 - pw/2),
			y = math.floor(rwidget.y + 40),
			w = pw,
			h = ph
		}
		rwidget.draw = function(widget)
			local px, py, pw, ph = unpackDim(widget.preview)
			drawWidget(widget)
			legacySetColor(0, 0, 0, 255)
			love.graphics.rectangle("fill", px, py, pw, ph)
			legacySetColor(255, 255, 255, 255)
			draw("border", nil, px+pw/2, py+ph/2-4)
			local index = lwidget.textbox.index
			if index > 0 and index <= self.numfiles then
				local file = self.files[lwidget.textbox.index]
				if not file[2] then
					local board, enemy = LevelSelectState.generatePreview(file[1])
					file[2] = board
					file[3] = enemy
				end
				if type(file[2]) == "string" then
					legacySetColor(255, 255, 255, 255)
					love.graphics.setFont(font["Munro30"])
					love.graphics.printf("No Preview Available", px, py + 20, pw, "center")
				else
					love.graphics.push()
					love.graphics.scale(1, 1)
					love.graphics.draw(file[2], px, py)
					love.graphics.draw(file[3], px, py + 300)
					love.graphics.pop()
				end
				if file[1]:sub(1, 1) == "_" then
					legacySetColor(0, 0, 255, 255)
					love.graphics.setFont(font["Munro20"])
					love.graphics.print("Default Level", px, py + ph)
				end
			end
		end
	else --playlist
		--I can borrow some elements from lwidget to copy a scroll bar
		if self.mode == "playlist_edit" then
			rwidget.n = 22
		else
			rwidget.n = 23
		end
		rwidget.textbox = {
			focus = false,
			n = rwidget.n,
			x = rwidget.x + 20,
			y = rwidget.y + 20 + (23 - rwidget.n)*18,
			w = rwidget.w - 40 - 20,
			h = rwidget.n * 18,
			index = 1,
			offset = 0,
		}
		rwidget.scrollbar = {
			textbox = rwidget.textbox,
			n = rwidget.n,
			x = rwidget.x + 300 + 10,
			y = rwidget.textbox.y,
			w = 15,
			h = rwidget.textbox.h,
			draw = lwidget.scrollbar.draw
		}
		rwidget.ptextbox = TextBox:new(rwidget.x + 80, rwidget.y + 18, 245, 18, {font = font["Munro20"]})
		rwidget.ptextbox.off = {x = 2, y = 0}
		rwidget.ptextbox.selected = false
		rwidget.ptextbox.keepFocus = true
		rwidget.ptextbox.color = TextBox.alwaysWhite
		rwidget.setPlaylist = function(widget, index)
			if index > 0 and index < self.numfiles then
				local file = self.files[index]
				if not file[2] then
					file[2] = LevelSelectState.readPlaylist(file[1])
				end
				self.playlist = file
			else
				self.playlist = {"NULL", {}}
			end
		end
		rwidget.resetScroll = function(widget)
			widget.textbox.offset = 0
			widget.scrollbar:update(0)
		end
		--copied from lwidget except for certain lines
		rwidget.textbox.update = function(tbox, dt)
			if self.mode == "playlist_edit" then
				local lines, nlines = self.playlist[2], #self.playlist[2]
				nlines = math.max(1, nlines)
				if tbox.focus and (keys.up or keys.down) then
					if keys.up then
						tbox.index = math.max(1, tbox.index - 1)
					else
						tbox.index = math.min(nlines, tbox.index + 1)
					end
					tbox.offset = math.max(math.min(tbox.offset, tbox.index - 1), tbox.index - tbox.n)
					tbox.transparent = false
				end
				if mouse.m1 == 1 then
					local mx, my = mouse.x, mouse.y
					if mx > tbox.x and mx < tbox.x + tbox.w and my > tbox.y and my < tbox.y + tbox.h then
						tbox.focus = true
						lwidget.textbox.focus = false
						local dy = my - tbox.y
						local row = math.floor(dy / 18) + 1
						tbox.index = row + tbox.offset
						tbox.index = math.min(nlines, tbox.index)
						local line = lines[tbox.index]
						tbox.transparent = false
					end
				end
			end
		end
		rwidget.textbox.draw = function(tbox)
			lines = self.playlist[2]
			legacySetColor(200, 200, 200, 255)
			love.graphics.rectangle("fill", unpackDim(tbox))
			love.graphics.setScissor(unpackDim(tbox))
			if self.mode == "playlist_edit" then
				legacySetColor(0, 255, 255, tbox.transparent and 128 or 255)
				love.graphics.rectangle("fill", tbox.x, tbox.y + (tbox.index-1-tbox.offset)*18, tbox.w, 18)
				legacySetColor(0, 0, 255, 255)
				love.graphics.rectangle("fill", tbox.x, tbox.y + (tbox.index-1-tbox.offset)*18, tbox.w, 2)
			end
			love.graphics.setFont(font["Munro20"])
			for i, line in ipairs(lines) do
				legacySetColor(0, 0, 0, 255)
				love.graphics.print(line, tbox.x + 2, tbox.y + (i-1-tbox.offset)*18 - 0)
			end
			love.graphics.setScissor()
		end
		rwidget.scrollbar.update = function(sc, dt)
			local lines, nlines = self.playlist[2], #self.playlist[2]
			nlines = math.max(1, nlines)
			sc.bar = {}
			local bar = sc.bar
			bar.x = sc.x
			bar.w = sc.w
			bar.h = sc.h * math.min(sc.n / nlines, 1)
			bar.y = sc.y + sc.textbox.offset * sc.h / nlines
			if mouse.m1 == 1 then
				local mx, my = mouse.x, mouse.y
				if mx > bar.x and mx < bar.x + bar.w and my > bar.y and my < bar.y + bar.h then
					sc.drag = {my, sc.textbox.offset}
				end
			elseif mouse.m1 == 2 then
				if sc.drag then
					local offset = sc.textbox.offset
					local dy = mouse.y - sc.drag[1]
					local doff = math.floor((nlines) * (dy / sc.h))
					offset = math.min(math.max(sc.drag[2] + doff, 0), math.max(nlines - sc.n, 0))
					sc.textbox.offset = offset
				end
			else
				sc.drag = nil
			end
			if containPoint(rwidget, mouse.x, mouse.y) then
				if mouse.scrollup then
					sc.textbox.offset = sc.textbox.offset - 1
					sc.textbox.offset = math.min(math.max(sc.textbox.offset, 0), math.max(nlines - sc.n, 0))
				end
				if mouse.scrolldown then
					sc.textbox.offset = sc.textbox.offset + 1
					sc.textbox.offset = math.min(math.max(sc.textbox.offset, 0), math.max(nlines - sc.n, 0))
				end
			end
		end
		rwidget.update = function(widget, dt)
			widget.textbox:update(dt)
			widget.scrollbar:update(dt)
			if self.mode == "playlist_edit" then
				widget.ptextbox:update(dt)
				if widget.ptextbox.selected then
					dwidget.textbox.selected = false
				end
			end
		end
		rwidget.scrollbar.draw = function(sc)
			legacySetColor(200, 200, 200, 255)
			love.graphics.rectangle("fill", sc.x, sc.y, sc.w, sc.h)
			legacySetColor(110, 110, 110, 255)
			love.graphics.rectangle("fill", sc.bar.x, sc.bar.y, sc.bar.w, sc.bar.h)
		end
		rwidget.draw = function(widget)
			drawWidget(widget)
			widget.textbox:draw()
			widget.scrollbar:draw()
			if self.mode == "playlist_edit" then
				widget.ptextbox:draw()
				legacySetColor(0, 0, 0, 255)
				love.graphics.setFont(font["Munro20"])
				-- love.graphics.print("EDITING: "..self.playlist[1], widget.x + 20, widget.y + 16)
				love.graphics.print("EDITING:", widget.x + 20, widget.y + 18)
			end
		end
		if self.mode ~= "playlist_edit" then
			rwidget:setPlaylist(1)
			rwidget.scrollbar:update(0)
		end
	end

	dwidget = {
		x = 50,
		y = window.h - 90,
		w = window.w - 100,
		h = 60
	}
	-- dwidget.textbox = {
	-- 	x = dwidget.x + 20,
	-- 	y = dwidget.y + 20,
	-- 	w = 300,
	-- 	h = 20,
	-- }
	dwidget.textbox = TextBox:new(dwidget.x + 20, dwidget.y + 10, 300, 18, {font = font["Munro20"]})
	dwidget.textbox.off = {x = 2, y = 0}
	dwidget.textbox.color = TextBox.alwaysWhite
	-- dwidget.textbox.alwaysSelected = true
	dwidget.textbox.selected = true
	dwidget.textbox.keepFocus = true
	if self.numfiles > 0 then dwidget.textbox.text = self.files[1][1] end
	dwidget.playbutton    = Button:new(dwidget.x + 510, dwidget.y + 10, 80, 40, {text = "Play", font = font["Arcade20"]})
	dwidget.savebutton    = Button:new(dwidget.x + 400, dwidget.y + 10, 80, 40, {text = "Save", font = font["Arcade20"]})
	dwidget.loadbutton    = Button:new(dwidget.x + 510, dwidget.y + 10, 80, 40, {text = "Load", font = font["Arcade20"]})
	dwidget.backbutton    = Button:new(dwidget.x + 600, dwidget.y + 10, 80, 40, {text = "Back", font = font["Arcade20"]})
	dwidget.deletebutton  = Button:new(dwidget.x + 490, dwidget.y + 10, 100, 40, {text = "Delete", font = font["Arcade20"]})
	dwidget.peditbutton   = Button:new(dwidget.x + 420, dwidget.y + 10, 70, 40, {text = "Edit", font = font["Arcade20"]})
	dwidget.pinsertbutton = Button:new(dwidget.x + 335, dwidget.y + 10, 90, 40, {text = "Insert", font = font["Arcade20"]})
	dwidget.premovebutton = Button:new(dwidget.x + 430, dwidget.y + 10, 100, 40, {text = "Remove", font = font["Arcade20"]})
	dwidget.psavebutton   = Button:new(dwidget.x + 535, dwidget.y + 10, 70, 40, {text = "Save", font = font["Arcade20"]})
	dwidget.hidedefault   = Checkbox:new(dwidget.x + 330, dwidget.y + 10, prefs.hide_default)
	dwidget.setMessage = function(widget, message, color)
		widget.message = message
		widget.messageColor = color or {0, 0, 0}
		widget.messageTimer = 3
	end
	if self.mode == "playlist_edit" then
		dwidget.backbutton.w = 70
		dwidget.backbutton.x = dwidget.backbutton.x + 10
	end
	if self.mode == "playlist" then
		if self.restrict_playlist then
			dwidget.playbutton.x = dwidget.backbutton.x - 80 - 10
		else
			dwidget.backbutton.w = 70
			dwidget.backbutton.x = dwidget.backbutton.x + 10
			dwidget.deletebutton.text = "Del."
			dwidget.deletebutton.w = 70
			dwidget.deletebutton.x = dwidget.backbutton.x - 70 - 3
			dwidget.peditbutton.w = 70
			dwidget.peditbutton.x = dwidget.deletebutton.x - 70 - 3
			dwidget.playbutton.w = 70
			dwidget.playbutton.x = dwidget.peditbutton.x - 70 - 3
		end
	end
	if self.mode == "editor_save" then
		dwidget.playbutton.x = dwidget.deletebutton.x - 100 - 10
	end
	dwidget.update = function(widget, dt)
		if widget.message then
			widget.messageTimer = widget.messageTimer - dt
			if widget.messageTimer <= 0 then
				widget.message = nil
			end
		end

		local v = widget.textbox:update(dt)
		if v or self.override then
			local tbox = lwidget.textbox
			local text = widget.textbox.text
			local index, close_index = self:findFile(text)
			if self.mode == "editor_save" or (self.mode == "playlist" and not self.restrict_playlist) then
				if index == 0 then index = 1 end
				tbox.index = index
			else
				tbox.index = close_index
				tbox.transparent = (index ~= close_index)
			end
			if tbox.index ~= 0 then
				tbox.offset = math.max(math.min(tbox.offset, tbox.index - 1), tbox.index - tbox.n)
			end
		end
		if keys.tab then
			if lwidget.textbox.transparent then
				lwidget.textbox.transparent = false
				widget.textbox.text = self.files[lwidget.textbox.index][1]
			end
		end
		if self.mode == "editor_save" then
			if widget.textbox.text == self.newFileString then
				widget.textbox.text = ""
			end
			local text = widget.textbox.text
			if text == "" or text:sub(1, 1) == "_" then
				widget.savebutton.disabled = true
				widget.savebutton.state = "idle"
			else
				widget.savebutton.disabled = false
			end
			if widget.savebutton:update(dt) or keys["return"] then
				local tbox = lwidget.textbox
				if text == "" then
					widget:setMessage("ERROR: filename cannot be blank", {255, 0, 0})
				elseif text:sub(1, 1) == "_" then
					widget:setMessage("ERROR: filename cannot start with '_'", {255, 0, 0})
				else
					if tbox.index == 1 then --new file is being created
						editorstate:saveBricks(text)
						local index = 2
						while index <= self.numfiles and text > self.files[index][1] do
							index = index + 1
						end
						local board, enemy = self.generatePreview(text)
						table.insert(self.files, index, {text, board, enemy})
						self.numfiles = self.numfiles + 1
						tbox.index = index
						tbox.offset = math.max(math.min(tbox.offset, tbox.index - 1), tbox.index - tbox.n)
						widget:setMessage("File saved!", {0, 255, 0})
						playSound("boardsaved")
					else --override an old file
						local title = "Override Confirmation"
						local message = "Are you sure you want to override this level?"
						game:push(LevelSelectPrompt:new(title, message, function()
							editorstate:backup(text)
							editorstate:saveBricks(text)
							local board, enemy = self.generatePreview(text)
							self.files[tbox.index][2] = board
							self.files[tbox.index][3] = enemy
							widget:setMessage("File saved!", {0, 255, 0})
							playSound("boardsaved")
						end))
					end
				end
			end
			if text:sub(1, 1) == "_" or lwidget.textbox.index == 1 then
				widget.deletebutton.disabled = true
				widget.deletebutton.state = "idle"
			else
				widget.deletebutton.disabled = false				
			end
			if widget.deletebutton:update(dt) then
				local tbox = self.lwidget.textbox
				if self:findFile(text) == 0 then
					widget:setMessage("ERROR: file not found", {255, 0, 0})
				else
					local title = "Delete Confirmation"
					local message = "Are you sure you want to delete this file?"
					game:push(LevelSelectPrompt:new(title, message, function()
						love.filesystem.remove("levels/"..widget.textbox.text)
						util.remove_if(self.files, function(f)
							return f[1] == text
						end)
						self.numfiles = self.numfiles - 1
						tbox.index = math.min(tbox.index, self.numfiles)
						tbox.offset = math.max(math.min(tbox.offset, tbox.index - 1, self.numfiles - tbox.n), tbox.index - tbox.n, 0)
						widget.textbox.text = self.files[tbox.index][1]
					end))
				end
			end
		elseif self.mode == "editor_load" then
			if lwidget.textbox.index == 0 or lwidget.textbox.transparent then
				widget.loadbutton.disabled = true
				widget.loadbutton.state = "idle"
			else
				widget.loadbutton.disabled = false				
			end
			if widget.loadbutton:update(dt) or keys["return"] then
				if self:findFile(widget.textbox.text) == 0 then
					widget:setMessage("ERROR: file not found", {255, 0, 0})
				else
					editorstate:loadBricks(widget.textbox.text)
					game:pop()
				end
			end
		elseif self.mode == "playlist" then
			if widget.textbox.text == self.newFileString then
				widget.textbox.text = ""
			end
			local check
			if self.restrict_playlist then
				check = lwidget.textbox.index == 0 or lwidget.textbox.transparent
			else
				check = lwidget.textbox.index == 1
			end
			if check then
				widget.playbutton.disabled = true
				widget.playbutton.state = "idle"
			else
				widget.playbutton.disabled = false				
			end
			if widget.playbutton:update(dt) or keys["return"] then
				if self:findFile(widget.textbox.text) == 0 then
					widget:setMessage("ERROR: file not found", {255, 0, 0})
				else
					local index = lwidget.textbox.index
					if index > 0 and index <= self.numfiles then
						local q = Queue:new(self.files[index][2])
						game:push(PlayState:new("play", q))
					end
				end
			end
			if not self.restrict_playlist then
				local text = widget.textbox.text
				if text == "" or text:sub(1, 1) == "_" then
					widget.peditbutton.disabled = true
					widget.peditbutton.state = "idle"
				else
					widget.peditbutton.disabled = false
				end
				widget.peditbutton.text = (lwidget.textbox.index == 1) and "New" or "Edit"
				if widget.peditbutton:update(dt) then
					local tbox = lwidget.textbox
					if text == "" then
						widget:setMessage("ERROR: filename cannot be blank", {255, 0, 0})
					elseif text:sub(1, 1) == "_" then
						widget:setMessage("ERROR: filename cannot start with '_'", {255, 0, 0})
					else
						local state = LevelSelectState:new("playlist_edit")
						if self.playlist[1] == self.newFileString then
							state.playlist = {self.dwidget.textbox.text, {}}
						else
							state.playlist = {self.playlist[1], util.copy(self.playlist[2])}
						end
						table.insert(state.playlist[2], "")
						state.rwidget.ptextbox.text = state.playlist[1]
						state.rwidget.scrollbar:update(0)
						game:push(state)
					end
				end
				if text:sub(1, 1) == "_" or lwidget.textbox.index == 1 then
					widget.deletebutton.disabled = true
					widget.deletebutton.state = "idle"
				else
					widget.deletebutton.disabled = false				
				end
				if widget.deletebutton:update(dt) then
					local tbox = self.lwidget.textbox
					if self:findFile(text) == 0 then
						widget:setMessage("ERROR: file not found", {255, 0, 0})
					else
						local title = "Delete Confirmation"
						local message = "Are you sure you want to delete this file?"
						game:push(LevelSelectPrompt:new(title, message, function()
							love.filesystem.remove("playlists/"..widget.textbox.text)
							util.remove_if(self.files, function(f)
								return f[1] == text
							end)
							self.numfiles = self.numfiles - 1
							tbox.index = math.min(tbox.index, self.numfiles)
							tbox.offset = math.max(math.min(tbox.offset, tbox.index - 1, self.numfiles - tbox.n), tbox.index - tbox.n, 0)
							widget.textbox.text = self.files[tbox.index][1]
							rwidget:setPlaylist(tbox.index)
						end))
					end
				end
			end
		elseif self.mode == "playlist_edit" then
			local pl = self.playlist[2]
			local tbox = self.rwidget.textbox
			local sc = self.rwidget.scrollbar
			if widget.pinsertbutton:update(dt) or keys["return"] then
				table.insert(pl, tbox.index, widget.textbox.text)
				tbox.index = tbox.index + 1
				tbox.offset = math.max(math.min(tbox.offset, tbox.index - 1), tbox.index - tbox.n)
			end
			if widget.premovebutton:update(dt) or keys["delete"] then
				if tbox.index < #pl then
					table.remove(pl, tbox.index, widget.textbox.text)
					tbox.offset = math.max(math.min(tbox.offset, tbox.index - 1, #pl - tbox.n), tbox.index - tbox.n, 0)
				end
			end
			local ptext = rwidget.ptextbox.text
			if ptext:sub(1, 1) == "_" or ptext == "" then
				widget.psavebutton.disabled = true
				widget.psavebutton.state = "idle"
			else
				widget.psavebutton.disabled = false				
			end
			if widget.psavebutton:update(dt) then
				local state = game.states[#game.states-1] --get the underlay state
				local tbox = state.lwidget.textbox
				self.playlist[1] = rwidget.ptextbox.text
				tbox.index = state:findFile(self.playlist[1])
				if tbox.index == 0 then
					tbox.index = 1
				end
				if tbox.index == 1 then --new file is being created
					table.remove(self.playlist[2]) --remove extra blank line
					LevelSelectState.savePlaylist(self.playlist[1], self.playlist[2])
					local index = 2
					while index <= state.numfiles and self.playlist[1] > state.files[index][1] do
						index = index + 1
					end
					local t = {self.playlist[1], self.playlist[2]}
					table.insert(state.files, index, t)
					state.numfiles = state.numfiles + 1
					tbox.index = index
					tbox.offset = math.max(math.min(tbox.offset, tbox.index - 1), tbox.index - tbox.n)
					state.playlist = t
					state.dwidget.textbox.text = self.playlist[1]
					state.dwidget:setMessage("File saved!", {0, 255, 0})
					playSound("boardsaved")
					game:pop()
				else --override
					local title = "Override Confirmation"
					local message = "\'"..self.playlist[1].."\' already exists.\n"
					message = message.."Are you sure you want to replace it?"
					game:push(LevelSelectPrompt:new(title, message, function()
						table.remove(self.playlist[2]) --remove extra blank line
						LevelSelectState.savePlaylist(self.playlist[1], self.playlist[2])
						state.playlist[2] = self.playlist[2]
						state.dwidget.textbox.text = self.playlist[1]
						state.dwidget:setMessage("File saved!", {0, 255, 0})
						playSound("boardsaved")
						game:pop()
					end))
				end
			end
			if widget.backbutton:update(dt) then
				game:pop()
			end
			if widget.textbox.selected then
				rwidget.ptextbox.selected = false
			end
		else --level select
			local text = widget.textbox.text
			if lwidget.textbox.index == 0 or lwidget.textbox.transparent then
				widget.playbutton.disabled = true
				widget.playbutton.state = "idle"
			else
				widget.playbutton.disabled = false				
			end
			if widget.playbutton:update(dt) or keys["return"] then
				if self:findFile(text) == 0 then
					widget:setMessage("ERROR: file not found", {255, 0, 0})
				else
					game:push(PlayState:new("play", text))
				end
			end
		end
		if self.mode ~= "playlist_edit" and widget.backbutton:update(dt) then
			game:pop();
		end
		if not (self.mode == "editor_save" or self.mode == "playlist_edit") then
			local v = widget.hidedefault:update(dt)
			if v ~= nil then
				self:toggleDefault(v)
			end
		end
	end
	dwidget.draw = function(widget)
		drawWidget(widget)
		widget.textbox:draw()
		if widget.message then
			love.graphics.setFont(font["Munro20"])
			legacySetColor(unpack(widget.messageColor))
			love.graphics.print(widget.message, widget.x + 20, widget.y + 30)
		end
		if self.mode == "editor_save" then
			widget.savebutton:draw()
			widget.deletebutton:draw()
		elseif self.mode == "editor_load" then
			widget.loadbutton:draw()
		elseif self.mode == "playlist" then
			widget.playbutton:draw()
			if not self.restrict_playlist then
				widget.peditbutton:draw()
				widget.deletebutton:draw()
			end
		elseif self.mode == "playlist_edit" then
			widget.premovebutton:draw()
			widget.pinsertbutton:draw()
			widget.psavebutton:draw()
		else
			widget.playbutton:draw()
			-- widget.deletebutton:draw()
		end
		widget.backbutton:draw()
		if not (self.mode == "editor_save" or self.mode == "playlist_edit") then
			widget.hidedefault:draw()
			legacySetColor(0, 0, 0, 255)
			love.graphics.setFont(font["Munro20"])
			love.graphics.print("Hide", widget.x + 355, widget.y + 10)
			love.graphics.print("Default", widget.x + 330, widget.y + 30)
		end
	end

	self.gwidget = gwidget
	self.lwidget = lwidget
	self.rwidget = rwidget
	self.dwidget = dwidget

	if option then
		if self.mode ~= "playlist_edit" then --setting the start file for most states
			self.override = true
			dwidget.textbox.text = option
			dwidget:update(0)
			self.override = false
		end
	end

end

function LevelSelectState:update(dt)
	if keys.escape then
		game:pop()
		return
	end

	if self.mode == "playlist" or self.mode == "playlist_edit" then
		local prevIndex = self.lwidget.textbox.index
		self.lwidget:update(dt)
		self.dwidget:update(dt)
		self.rwidget:update(dt)
		if self.mode == "playlist" and prevIndex ~= self.lwidget.textbox.index then
			self.rwidget:setPlaylist(self.lwidget.textbox.index)
			self.rwidget:resetScroll()
		end
	else
		self.lwidget:update(dt)
		self.dwidget:update(dt)
	end
end

function LevelSelectState:draw()
	self.prevstate:draw()
	--dark tint to cover the edges
	if self.mode ~= "playlist_edit" then
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.rectangle("fill", 0, 0, window.w, window.h)
	end

	legacySetColor(255, 255, 255, 255)
	love.graphics.setFont(font["Arcade50"])

	self.gwidget:draw()
	self.dwidget:draw() --draw before lwidget and rwidget to prevent preview stalling
	self.lwidget:draw()
	self.rwidget:draw()
end

LevelSelectPrompt = class("LevelSelectPrompt")

function LevelSelectPrompt:initialize(title, message, callback)
	self.prevstate = game:top()
	self.callback = callback

	self.box = MessageBox:new(window.w/2 - 200, window.h/2 - 75, 400, 150, title, message)
	local b1 = Button:new(0, 0, 90, 30, {text = "Yes", font = font["Arcade20"]})
	local b2 = Button:new(0, 0, 90, 30, {text = "Cancel", font = font["Arcade20"]})

	self.box:addButton(b1, 200, 110)
	self.box:addButton(b2, 300, 110)
end

function LevelSelectPrompt:update(dt)
	--self.box:update(dt)
	if self.box.buttons[1]:update(dt) or keys["return"] then
		self.callback()
		game:pop()
	end
	if self.box.buttons[2]:update(dt) or keys.escape then
		game:pop()
	end
end

function LevelSelectPrompt:draw()
	--draw the state before it too
	self.prevstate:draw()
	self.box:draw()
end