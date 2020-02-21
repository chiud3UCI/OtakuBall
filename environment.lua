--Environment is basically where all the misc objects go. They can only use a custom update function in order to communicate with the game.

Environment = class("Environment", Sprite)

function Environment:initialize(imgstr, rect, w, h, x, y, vx, vy, angle)
	Sprite.initialize(self, imgstr, rect, w, h, x, y, vx, vy, angle)
	self.gameType = "environment"
end