--game is a singleton object not a class!
require("states/playstate")
require("states/editorstate")
require("states/mainmenustate")
require("states/levelselectstate")
require("states/optionstate")
require("states/backgroundselectstate")
require("states/campaignstate")

game = {}

function game:initialize()
	self.states = {}

	self.newObjects = {}
	for _, str in pairs(listTypes) do
		self[str] = {}
		self.newObjects[str] = {}
	end
	self.paddle = nil
	self.enemySpawner = enemySpawner
	self.config = {}
end

function game:push(state)
	table.insert(self.states, state)
end

function game:pop()
	local top = self:top()
	if top.close then top:close() end
	self.states[#self.states] = nil
end

function game:top()
	return self.states[#self.states]
end

function game:update(dt)
	self:top():update(dt)
end

function game:draw()
	self:top():draw()
end

function game:emplace(str, obj)
	local t = self.newObjects[str]
	table.insert(t, obj)
end

function game:clearObjects(paddle)
	for _, str in pairs(listTypes) do
		util.clear(self[str])
		util.clear(self.newObjects[str])
	end
	if not paddle and self.paddle then
		self.paddle:destructor()
		self.paddle = nil
	end
	monitorManager:clear()
end

function game.destructor(obj)
	obj:onDeath()
	obj:destructor()
end