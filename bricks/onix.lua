OnixBrick = class("OnixBrick", Brick)

function OnixBrick:initialize(x, y, mode)
	Brick.initialize(self, x, y)
	self.onixMode = mode
	local points
	local i, j

	--the first point (2 values) are the anchor
	if mode == "TopLeft" then
		points = {0,0,  32,0,  0,16}
		i, j = 9, 21
	elseif mode == "TopRight" then
		points = {0,0,  32,0,  32,16}
		i, j = 9, 20
	elseif mode == "BottomLeft" then
		points = {0,0,  32,16,  0,16}
		i, j = 8, 21
	elseif mode == "BottomRight" then
		points = {32,0,  32,16,  0,16}
		i, j = 8, 20
	else --mode == "Full"
		points = {0,0,  32,0,  32,16,  0,16}
		i, j = 8, 19
	end

	--For most sprites, the hitbox's center is attached to the center
	--of the sprite. However, for bricks like OnixBrick and TitleBrick,
	--the the hitbox is not supposed to be centered, so there needs
	--to be an offset
	local shape = shapes.newPolygonShape(unpack(points))
	local vertices = shape._polygon.vertices
	local index = 0
	--locate the index of anchor in the polygon
	for i, v in ipairs(vertices) do
		if v.x == points[1] and v.y == points[2] then
			index = i
			break
		end
	end
	self:setShape(shape)
	local v = shape._polygon.vertices[index]
	--calculate offset from centroid
	self.shape_dx = points[1] + self.x - self.w/2 - v.x
	self.shape_dy = points[2] + self.y - self.h/2 - v.y
	self.shape:move(self.shape_dx, self.shape_dy)
	
	self.rect = rects.brick[i][j]
	self.hitAni = mode.."OnixShine"
	self.health = 100
	self.armor = 2
	self.points = 500
	self.brickType = "OnixBrick"
	self.essential = false
end

-- override to apply offset
function OnixBrick:updateShape()
	Brick.updateShape(self)
	self.shape._polygon:move(self.shape_dx, self.shape_dy)
end

function OnixBrick:takeDamage(dmg, str)
	Brick.takeDamage(self, dmg, str)
	self:playAnimation(self.hitAni)
end

--debugging
--comment out for normal appearance

-- function OnixBrick:draw()
-- 	self.shape:draw("line")
-- end