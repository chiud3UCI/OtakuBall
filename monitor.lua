Monitor = class("Monitor")

function Monitor:initialize(name, value)
	name = name or "null"
	value = value or 0
	self.name = name
	self.value = value
	self.dead = false
end

function Monitor:update()
end

monitorManager = {monitors = {}}

function monitorManager:add(monitor)
	util.remove_if(self.monitors, function(m)
		return m.name == monitor.name
	end)
	table.insert(self.monitors, monitor)
end

--updates monitors as well as removing them if they're dead
function monitorManager:update()
	util.remove_if(self.monitors, function(m)
		return m:update()
	end)
end

function monitorManager:clear()
	self.monitors = {}
end

function monitorManager:draw()
	legacySetColor(0, 0, 0)
	local x, y = 10, 400
	local dy = 18
	for _, m in pairs(self.monitors) do
		local str = m.name..": "..string.format("%.2f", m.value)
		love.graphics.setFont(font["Munro20"])
		love.graphics.print(str, x, y)
		y = y + dy
	end
end
