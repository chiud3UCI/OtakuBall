Button = class("Button")

Button.defaultColor = {
	border = {0, 0, 0},
	idle = {bg = {255, 255, 255}, text = {0, 0, 0}},
	hovered = {bg = {255, 255, 0}, text = {0, 0, 0}},
	clicked = {bg = {255, 178, 102}, text = {0, 0, 0}}
}

Button.defaultColorToggle = {
	border = {0, 0, 0},
	idle = {on = {bg = {0, 255, 0}, text = {0, 0, 0}},
			off = {bg = {255, 0, 0}, text = {0, 0, 0}}},
	hovered = {bg = {255, 255, 0}, text = {0, 0, 0}},
	clicked = {bg = {255, 178, 102}, text = {0, 0, 0}}
}

local function containMouse(box)
	return mouse.x > box.x 
	   and mouse.x < box.x + box.w 
	   and mouse.y > box.y 
	   and mouse.y < box.y + box.h
end

function fillrect(color, x, y, w, h)
	legacySetColor(color, color, color, 255)
	love.graphics.rectangle("fill", x, y, w, h)
end

--Button.fillrect = fillrect

function Button:initialize(x, y, w, h, options, callback)
	if type(x) == "table" then
		self.x, self.y, self.w, self.h = unpack(x)
		options, callback = y, w
	else
		self.x, self.y, self.w, self.h = x, y, w, h
	end
	self.callback = callback or util.nullfunc

	self.state = "idle"

	options = options or {} --maybe set default options table
	self.text = options.text --or nil
	self.subtext = options.subtext -- used for drawing text outside of the button
	self.offx = options.offx or 0 --this is for text only; image is below
	self.offy = options.offy or 0
	self.image = options.image --{imgstr=, rect=, w=, h=, offx=, offy=}
	if self.image then
		if not self.image.offx then self.image.offx = 0 end
		if not self.image.offy then self.image.offy = 0 end
	end
	self.color = options.color or {}
	if self.color then
		local col = self.color
		col.disabled = col.disabled or 150
		col.idle     = col.idle     or 128
		col.hovered  = col.hovered  or 128
		col.clicked  = col.clicked  or 160
	end
	self.font = options.font or font["Arcade30"]
	self.border = options.border or 2
	self.wrap = options.wrap or 1 --how many lines will the text wrap around
	self.hidden = false
	self.disabled = false
end

function Button:containMouse()
	return containMouse(self)
end

function Button:update(dt)
	if self.hidden or self.disabled then return false end
	local hit = false
	if containMouse(self) then
		if mouse.m1 then
			if mouse.m1 == 1 then
				self.state = "clicked"
			elseif self.state ~= "clicked" then
				self.state = "hovered"
			end
		elseif self.state == "clicked" then
			self.callback()
			hit = true
			self.state = "hovered"
		else
			self.state = "hovered"
		end
	elseif not (self.state == "clicked" and mouse.m1) then
		self.state = "idle"
	end
	return hit
end
--testing
function Button:draw()
	if self.hidden then return end
	local x, y, w, h = self.x, self.y, self.w, self.h
	local b = 2
	local offx, offy = 0, 0
	local color = self.color
	if self.disabled then
		fillrect(32, x, y, w, h)
		fillrect(255, x, y, w-b, h-b)
		fillrect(64, x+b, y+b, w-b*2, h-b*2)
		fillrect(color.disabled, x+b, y+b, w-b*3, h-b*3)
	elseif self.state == "idle" then
		fillrect(32, x, y, w, h)
		fillrect(255, x, y, w-b, h-b)
		fillrect(64, x+b, y+b, w-b*2, h-b*2)
		fillrect(color.idle, x+b, y+b, w-b*3, h-b*3)
	elseif self.state == "hovered" then
		fillrect(32, x, y, w, h)
		fillrect(255, x+b, y+b, w-b*3, h-b*3)
		fillrect(64, x+b*2, y+b*2, w-b*4, h-b*4)
		fillrect(color.hovered, x+b*2, y+b*2, w-b*5, h-b*5)
	elseif self.state == "clicked" then
		fillrect(255, x, y, w, h)
		fillrect(32, x, y, w-b, h-b)
		fillrect(100, x+b, y+b, w-b*2, h-b*2)
		fillrect(color.clicked, x+b*2, y+b*2, w-b*3, h-b*3)
		offx, offy = b, b
	end
	if self.text then
		if self.disabled then
			legacySetColor(100, 100, 100, 255)
		else
			legacySetColor(0, 0, 0, 255)
		end
		love.graphics.setFont(self.font)
		love.graphics.printf(self.text, self.x + self.offx + offx, self.y + self.offy + offy + (self.h - self.font:getHeight() * self.wrap)/2, self.w, "center")
	end
	if self.subtext then
		local st = self.subtext
		love.graphics.setColor(0, 0, 0, 1)
		love.graphics.setFont(st.font)
		love.graphics.print(st.text, self.x + st.offx, self.y + st.offy)
	end
	if self.image then
		legacySetColor(255, 255, 255, 255)
		local im = self.image
		draw(im.imgstr, im.rect, self.x + self.w/2 + im.offx + offx, self.y + self.h/2 + im.offy + offy, 0, im.w, im.h)
	end
end


TextBox = class("TextBox")

TextBox.defaultColor = {
	idle = {bg = {255, 255, 255}, text = {0, 0, 0}},
	selected = {bg = {255, 255, 0}, text = {0, 0, 0}}
}
TextBox.alwaysWhite = {
	idle = {bg = {255, 255, 255}, text = {0, 0, 0}},
	selected = {bg = {255, 255, 255}, text = {0, 0, 0}}
}

--callback is called whenever enter is pressed
--options is a table with named arguments
function TextBox:initialize(x, y, w, h, options)
	self.x, self.y, self.w, self.h = x, y, w, h
	self.font = options.font or font["Munro20"]
	self.text = ""
	self.color = TextBox.defaultColor
	self.selected = false
	self.fixedScale = nil
	self.off = options.off or {x = 0, y = 0}
	self.alwaysSelected = false --used for specific cases
	self.keepFocus = false --will not go out of focus if mouse clicks outside
	self.hidden = nil
	self.caret = 0
	self.caretBlink = true
	self.caretTimer = 0
end

function TextBox:containMouse()
	return containMouse(self)
end

function TextBox:update(dt)
	if self.hidden then return end

	local result = nil

	if mouse.m1 == 1 then
		if self:containMouse() then
			self.selected = true
			self.caretBlink = true
			self.caretTimer = 0
		else
			if not self.keepFocus then
				self.selected = false
			end
		end
	end

	if self.selected or self.alwaysSelected then
		if keys.lastText then
			self.text = self.text .. keys.lastText
			result = keys.lastText
		end
		if keys.backspace then
			if self.text:len() > 0 then
				if love.keyboard.isDown("lshift", "rshift") then
					self.text = ""
				else
					self.text = self.text:sub(1, -2)
				end
			end
			result = "backspace"
		end
	end

	if self.caret then
		self.caret = self.font:getWidth(self.text) - 4
		if result then
			self.caretBlink = true
			self.caretTimer = 0
		else
			self.caretTimer = self.caretTimer + dt
			if self.caretTimer > 0.5 then
				self.caretTimer = 0
				self.caretBlink = not self.caretBlink
			end
		end
	end

	return result
end

function TextBox:draw()
	local color = self.color[self.selected and "selected" or "idle"]
	if not self.hidden then
		legacySetColor(color.bg)
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
	end
	if not self.hidden or self.hidden == "show_text" then
		legacySetColor(color.text)
		love.graphics.setFont(self.font)
		love.graphics.print(self.text, self.x + self.off.x, self.y + self.off.y)
		if self.caret and self.caretBlink and (self.selected or self.alwaysSelected) then
			love.graphics.print("|", self.x + self.off.x + self.caret, self.y + self.off.y)
		end
	end
end


--NumBox = class("NumBox", TextBox)

NumBox = class("NumBox", TextBox)

--i could have used the tonumber function but whatever
NumBox.digits = util.generateLookup({"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"})

function NumBox:initialize(x, y, w, h, options)
	TextBox.initialize(self, x, y, w, h, options)
	self.text = "0"
	self.num = 0
	self.limit = options.limit or math.huge
	self.caret = nil
end

function NumBox:update(dt) --returns true if the value is changed
	if self.hidden then return false end

	if mouse.m1 == 1 then
		self.selected = containMouse(self)
	end

	if self.selected then
		local oldNum = self.num
		if keys.lastText and NumBox.digits[keys.lastText] then
			local digit = keys.lastText
			if self.text == "0" then 
				self.text = "" 
			end
			self.text = self.text .. digit
		elseif keys["."] then
			if not self.period then 
				self.text = self.text .. "."
				self.period = true
			end
		elseif keys.backspace then
			if self.text:len() > 0 then
				if self.text:sub(-1) == "." then
					self.period = false
				end
				self.text = self.text:sub(1, -2)
			end
			if self.text == "" then
				self.text = "0"
			end
		end
		if tonumber(self.text) > self.limit then
			self.num = self.limit
			self.text = tostring(self.limit)
			self.period = self.text:find(".") == nil
		else
			self.num = tonumber(self.text)
		end
		return oldNum ~= self.num
	end
	return false
end

--assuming the arguments are valid
function NumBox:setText(text)
	self.text = text
	self.num = tonumber(text)
	self:updatePeriod()
end 

function NumBox:setNumber(n)
	self.text = tostring(n)
	self.num = n
	self:updatePeriod()
end

function NumBox:updatePeriod()
	self.period = false
	for i = 1, #self.text do
		if self.text:sub(i,i) == "." then
			self.period = true
		end
	end
end

Checkbox = class("Checkbox")

function Checkbox:initialize(x, y, state)
	self.x = x
	self.y = y
	self.w = 22
	self.h = 22
	self.rect = make_rect(0, 0, 11, 11)
	self.state = state == true --should be boolean
	self.manual = manual == true --instead of toggling, you can make the checkbox return whether or not it was pressed
end

--returns true, false, or nil
function Checkbox:update(dt)
	if containMouse(self) and mouse.m1 == 1 then
		self.state = not self.state
		return self.state
	end
	return nil
end

function Checkbox:draw()
	legacySetColor(255, 255, 255, 255)
	self.rect[1] = self.state and 11 or 0
	draw("checkradio", self.rect, self.x + self.w/2, self.y + self.h/2, 0, self.w, self.h)
end

Radio = class("Radio")

function Radio:initialize(x, y, state, group, value)
	self.x = x
	self.y = y
	self.w = 20
	self.h = 20
	self.group = group --group should be a list of associated radios
	self.value = value
	self.rect = make_rect(0, 11, 10, 10)
	self.state = state == true --should be boolean
	self.manual = manual == true --instead of toggling, you can make the checkbox return whether or not it was pressed
end

--returns true or nil
function Radio:update(dt)
	if containMouse(self) and mouse.m1 == 1 then
		self.state = true
		if self.group then
			for i, r in ipairs(self.group) do
				if r ~= self then
					r.state = false
				end
			end
		end
		return true
	end
	return nil
end

function Radio:draw()
	legacySetColor(255, 255, 255, 255)
	self.rect[1] = self.state and 10 or 0
	draw("checkradio", self.rect, self.x + self.w/2, self.y + self.h/2, 0, self.w, self.h)
end

Slider = class("Slider")

function Slider:initialize(x, y, w, h, min, max, initial, tics)
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.min = min
	self.max = max
	self.value = initial
	self.tics = tics or 10
	self.barw = 10
	self.barColor = {255, 255, 255, 255}
end

function Slider:valueToX(value)
	value = value or self.value
	return self.x + self.w * (self.value - self.min) / (self.max - self.min)
end

function Slider:xToValue(x)
	x = x or self.x
	local dx = x - self.x
	return self.min + (dx / self.w) * (self.max - self.min)
end

function Slider:update(dt)
	if mouse.m1 then
		local mx, my = mouse.x, mouse.y
		if mouse.m1 == 1 and 
		   mx > self.x - self.barw/2 and 
		   mx < self.x + self.w + self.barw/2 and 
		   my > self.y and 
		   my < self.y + self.h then
			self.drag = true
		end
		if self.drag then
			self.drag = true
			self.value = self:xToValue(mx)
			self.value = math.max(self.min, math.min(self.max, math.floor(self.value + 0.5)))
			return self.value
		end
	else
		self.drag = nil
	end
end

function Slider:draw()
	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("rough")
	legacySetColor(0, 0, 0, 255)

	local x, y, w, h = self.x, self.y, self.w, self.h
	love.graphics.line(x, y, x, y+h)
	love.graphics.line(x, y+h/2, x+w, y+h/2)
	love.graphics.line(x+w, y, x+w, y+h)

	love.graphics.setLineWidth(1)
	for i = 0, self.tics do
		local dx = i*w/self.tics
		love.graphics.line(x+dx, y+h/4, x+dx, y+3*h/4)
	end

	legacySetColor(unpack(self.barColor))
	local min, max, barw = self.min, self.max, self.barw
	local barx = self:valueToX()
	love.graphics.rectangle("fill", barx - barw/2, y, barw, h)
end

MessageBox = class("MessageBox")

function MessageBox:initialize(x, y, w, h, title, text)
	self.x = x
	self.y = y
	self.w = w
	self.h = h
	self.title = title or ""
	self.text = text or ""
	self.buttons = {}
end

--dx and dy are offsets based on the messagebox position
function MessageBox:addButton(button, dx, dy)
	button.x, button.y = self.x + dx, self.y + dy
	table.insert(self.buttons, button)
end

function MessageBox:update(dt)
	for i, b in ipairs(self.buttons) do
		b:update(dt)
	end
end

function MessageBox:draw()
	local x, y, w, h = self.x, self.y, self.w, self.h
	local b = 2
	fillrect(32, x, y, w, h)
	fillrect(192, x, y, w-b, h-b)
	fillrect(64, x+b, y+b, w-b*2, h-b*2)
	fillrect(255, x+b, y+b, w-b*3, h-b*3)
	fillrect(128, x+b*2, y+b*2, w-b*4, h-b*4)
	legacySetColor(0, 0, 128, 255)
	love.graphics.rectangle("fill", x+b*3, y+b*3, w-b*6, 24)
	legacySetColor(255, 255, 255, 255)
	love.graphics.setFont(font["Arcade20"])
	love.graphics.print(self.title, x+b*4, y+b*4)
	legacySetColor(0, 0, 0, 255)
	love.graphics.setFont(font["Munro20"])
	love.graphics.printf(self.text, x+b*3, y+b*3 + 24, w-b*6, "left")

	for i, b in ipairs(self.buttons) do
		b:draw()
	end
end