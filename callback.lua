Callback = class("Callback")

function Callback:initialize(time, func, name)
	self.time = time
	self.func = func
	self.name = name
end

function Callback:destructor() end

function Callback:update(dt)
	self.time = self.time - dt
end

function Callback:isDead()
	return self.time <= 0
end

function Callback:onDeath()
	if self.func then
		self.func()
	end
end

function Callback:cancel()
	self.func = nil
end