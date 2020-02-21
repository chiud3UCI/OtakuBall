BackgroundSelectState = class("BackgroundSelectState")
local Back = BackgroundSelectState

function Back:initialize()
	local _w, _h = window.w, window.h
	local widget = {
		x = window.w/2 - _w/2,
		y = window.h/2 - _h/2,
		w = _w,
		h = _h
	}
	local offx = 220
	local slider = {
		r = Slider:new(widget.x+offx, widget.y + 10, 256, 16, 0, 255, 0, 8),
		g = Slider:new(widget.x+offx, widget.y + 30, 256, 16, 0, 255, 0, 8),
		b = Slider:new(widget.x+offx, widget.y + 50, 256, 16, 0, 255, 0, 8)
	}
	slider.r.barColor = {255, 0, 0, 255}
	slider.g.barColor = {0, 255, 0, 255}
	slider.b.barColor = {0, 0, 255, 255}

	local bg = editorstate.background
	slider.r.value = bg.r
	slider.g.value = bg.g
	slider.b.value = bg.b

	for _, s in pairs(slider) do
		s.numBox = NumBox:new(s.x + s.w + 15, s.y, 30, 16, {font = font["Munro20"], limit = 255})
		s.numBox.off = {x = 0, y = -3}
		s.numBox:setNumber(s.value)
	end

	self.tile = bg.tile

	self.backButton = Button:new(widget.x + widget.w - 85, widget.y + widget.h - 40, 75, 30,
		{text = "Back", font = font["Arcade20"]}
	)
	self.applyButton = Button:new(widget.x + widget.w - 170, widget.y + widget.h - 40, 75, 30,
		{text = "Apply", font = font["Arcade20"]}
	)

	self.presets = {
		x = widget.x + 220,
		y = widget.y + 95,
		w = 16,
		h = 16,
		values = {
			{{  0,   0, 128},
			 {128,   0,   0},
			 {  0, 128,   0},
			 {128, 128,   0},
			 {  0, 128, 128},
			 {128,   0, 128},
			 {128, 128, 128},
			 { 64,  64,  64},
			 {128,  64,   0},
			 { 64,   0, 128},
			 {128,   0,  64},
			 {  0, 128,  64}},

			{{  0,   0, 255},
			 {255,   0,   0},
			 {  0, 255,   0},
			 {255, 255,   0},
			 {  0, 255, 255},
			 {255,   0, 255},
			 {200, 200, 200},
			 {255, 255, 255},
			 {255, 128,   0},
			 {128,   0, 255},
			 {255,   0, 128},
			 {  0, 255, 128}},
			
			{{255,  63,   0},
		     {255, 193,   0},
		     {135, 255,   0},
		     {  0, 169, 156},
		     {  0, 128, 255},
		     {193,   0, 255},
		     {186, 175, 113},
		     {252, 197, 142},
		     {116,  76,  40},
		     {165, 124,  85},
		     {114,  98,  88},
		     {199, 178, 155}}
		},
		update = function(p, dt)
			local x, y, w, h = p.x, p.y, p.w, p.h
			local mx, my = mouse.x, mouse.y
			if mouse.m1 == 1 then
				for i, v in ipairs(p.values) do
					local off = (i-1)*h
					if mx > x and mx < x + w * #v and my > y + off and my <= y + off + h then
						local index = math.floor((mx - x) / w) + 1
						self:setColor(unpack(v[index]))
					end
				end
			end
		end,
		draw = function(p)
			for i, t in ipairs(p.values) do
				for j, v in ipairs(t) do
					legacySetColor(unpack(v))
					love.graphics.rectangle("fill", p.x + (j-1)*p.w, p.y + (i-1)*p.h, p.w, p.h)
				end
			end
		end
	}

	self.patterns = {
		x = widget.x + 10,
		y = widget.y + 235,
		w = 32,
		h = 32,
		wrap = 24,
		tiles = {{imgstr = "no", rect = rects.bg[1][1]}},
		update = function(p, dt)
			local x, y, w, h, wrap = p.x, p.y, p.w, p.h, p.wrap
			local mx, my = mouse.x, mouse.y
			if mouse.m1 == 1 then
				local i = math.floor((my - y) / 32)
				local j = math.floor((mx - x) / 32)
				if i >= 0 and j >= 0 and j < wrap then
					local index = i*wrap + j + 1
					if index == 1 then
						self.tile = nil
					else
						local tile = p.tiles[index]
						if tile then
							if not tile.blank then
								self.tile = tile
							end
						end
					end
				end
			end
		end,
		draw = function(p)
			legacySetColor(255, 255, 255, 255)
			for i, v in ipairs(p.tiles) do
				if not v.blank then
					local x = p.x + ((i-1)%p.wrap)*p.w
					local y = p.y + math.floor((i-1)/p.wrap)*p.h
					draw(v.imgstr, v.rect, x, y, 0, p.w, p.h, 0, 0)
				end
			end
		end
	}
	--first set
	for i = 1, 13 do
		for j = 1, 5 do
			local tile = {imgstr = "background", rect = rects.bg[i][j], i = i, j = j}
			table.insert(self.patterns.tiles, tile)
		end
	end
	--remove extra tiles
	for i = 1, 0 do
		table.remove(self.patterns.tiles)
	end
	--padding
	for i = 1, 7 + self.patterns.wrap do
		table.insert(self.patterns.tiles, {blank = true})
	end
	--second set
	for i = 1, 13 do
		for j = 1, 5 do
			local tile = {imgstr = "background2", rect = rects.bg[i][j], i = i, j = j}
			table.insert(self.patterns.tiles, tile)
		end
	end
	--remove extra tiles
	for i = 1, 0 do
		table.remove(self.patterns.tiles)
	end


	self.widget = widget
	self.slider = slider
end

function Back:setColor(r, g, b)
	self.slider.r.value = r
	self.slider.g.value = g
	self.slider.b.value = b
	self.slider.r.numBox:setNumber(r)
	self.slider.g.numBox:setNumber(g)
	self.slider.b.numBox:setNumber(b)
end

function Back:update(dt)
	if keys.escape then
		game:pop()
	end
	local mx, my = mouse.x, mouse.y
	local w = self.widget
	if mouse.m1 == 1 and not (mx >= w.x and mx <= w.x + w.w and my >= w.y and my <= w.y + w.h) then
		editorstate.mouseProtect = true 
		game:pop()
	end
	for _, s in pairs(self.slider) do
		if s:update(dt) then
			s.numBox:setNumber(s.value)
		end
		if s.numBox:update(dt) then
			s.value = s.numBox.num
		end
	end
	self.presets:update(dt)
	if self.backButton:update(dt) then
		game:pop()
	end
	self.patterns:update(dt)
	if self.applyButton:update(dt) then
		local s = self.slider
		editorstate.background = {r = s.r.value, g = s.g.value, b = s.b.value, tile = self.tile}
	end
end

--since the widget won't occupy the entire screen, it will draw the previous editorstate
function Back:draw()
	-- editorstate:draw()
	legacySetColor(200, 200, 200, 255)
	local w = self.widget
	love.graphics.rectangle("fill", w.x, w.y, w.w, w.h)
	local slider = self.slider
	for _, s in pairs(slider) do
		s:draw()
		s.numBox:draw()
	end
	for i = 1, 3 do
		for j = 1, 3 do
			legacySetColor(slider.r.value, slider.g.value, slider.b.value, 255)
			love.graphics.rectangle("fill", w.x + 10 + (j-1)*64, w.y + 10 + (i-1)*64, 64, 64)
			if self.tile then
				legacySetColor(255, 255, 255, 255)
				draw(self.tile.imgstr, self.tile.rect, w.x + 10 + (j-1)*64, w.y + 10 + (i-1)*64, 0, 64, 64, 0, 0)
			end
		end
	end

	self.backButton:draw()
	self.applyButton:draw()

	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Munro20"])
	love.graphics.print("Color Presets:", self.widget.x + 220, self.widget.y + 70)
	self.presets:draw()

	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Munro20"])
	love.graphics.print("Patterns:", self.widget.x + 10, self.widget.y + 210)
	love.graphics.print("Key Plates:", self.widget.x + 10, self.widget.y + 338)
	self.patterns:draw()

	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Arcade30"])
	love.graphics.printf(
		"Background Select",
	    self.widget.x + self.widget.w - 250,
	    self.widget.y + 10,
	    220,
	    "right"
	)
end