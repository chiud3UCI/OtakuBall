TitleBrick = class("TitleBrick", Brick)

local rec = rects.brick

--naming convention:
-- tlb = top left big
-- brs = bottom right small
-- reg = regular (whole brick)

--each entry is {rect, {points}}
local titleRect = {
	reg = {1, rec[1][1], {0,0, 32,0, 32,16, 0,16}},
	trb = {2, rec[2][1], {0,0, 32,0, 32,16, 16,16}},
	trs = {3, rec[3][1], {16,0, 32,0, 32,16}},
	tlb = {4, rec[2][2], {0,0, 32,0, 16,16, 0,16}},
	tls = {5, rec[3][2], {0,0, 16,0, 0,16}},
	brs = {6, rec[2][3], {32,0, 32,16, 16,16}},
	brb = {7, rec[3][3], {16,0, 32,0, 32,16, 0,16}},
	bls = {8, rec[2][4], {0,0, 16,16, 0,16}},
	blb = {9, rec[3][4], {0,0, 16,0, 32,16, 0,16}}
}

TitleBrick.scale = 0.5

function TitleBrick:initialize(x, y, mode)
	Brick.initialize(self, x, y)
	self.imgstr = "brick_title2"
	self.rect = titleRect[mode][2]
	self.anistr = "TitleBrickShine"..titleRect[mode][1]

	self.w, self.h = 32 * TitleBrick.scale, 16 * TitleBrick.scale
	
	local points = {}
	for i, v in ipairs(titleRect[mode][3]) do
		points[i] = v*TitleBrick.scale
	end
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

	self:setShape(shape)
	self.armor = 2
	self.brickType = "TitleBrick"
end

-- override to apply offset
function TitleBrick:updateShape()
	Brick.updateShape(self)
	self.shape._polygon:move(self.shape_dx, self.shape_dy)
end

function TitleBrick:takeDamage(dmg, str)
	--Brick.takeDamage(self, dmg, str)
	self:playAnimation(self.anistr)
end

function TitleBrick:draw()
	Brick.draw(self)
	--debugging
	-- self.shape:draw("line")
end