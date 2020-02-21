--Separating Axis Theorem test used as an alternative to the GJK
--Reason: The ball doesnt bounce accurately enough from the corners
--        of a polygon with GJK

--This file requires the full vector library (hump/vector)
local vector = require("hump.vector")

sat = {}

--determines the overlap between two projections
--each projection "vector" contains the min dot product and max dot product
function sat.overlap(v1, v2)
	if v2.y > v1.x then
		return v1.y - v2.x
	else
	    return v2.y - v1.x
	end
end

--determines whether or not a given point is left(-1), right(1), or in the middle(0) of
--a given line segment
function sat.getVornoiRegion(point, p1, p2)
	local vec = point - p1
	local base = p2 - p1
	local dot = vec * base
	if dot < 0 then return -1 end
	if dot > base:len2() then return 1 end
	return 0
end

--determines whether or not a given point is to the left of a line
function sat.isLeft(point, p1, p2)
	return ((p2.x-p1.x)*(point.y-p1.y)-(p2.y-p1.y)*(point.x-p1.x)) >= 0
end


--for a convex polygon, return a vector containing the min and max dot products
--NOTE: In order to be accurate, the axis must be normalized
function sat.getProjection(points, axis)
	local min_dot = points[1] * axis
	local max_dot = min_dot
	for _, v in pairs(points) do
		local vec = vector.new(v.x, v.y)
		local dot = vec * axis
		if dot < min_dot then 
			min_dot = dot
		elseif dot > max_dot then
			max_dot = dot
		end
	end
	return vector.new(min_dot, max_dot)
end

--get the projection of a circle onto an axis
function sat.getProjectionCircle(center, radius, axis)
	local center_dot = center * axis
	return vector.new(center_dot - radius, center_dot + radius)
end

function sat.getAxes(points1, points2)
	local axes = {}
	local p1, p2, edge, norm
	for i, v in pairs(points1) do
		p1 = points1[i]
		if i + 1 > #points1 then p2 = points1[1]
		else p2 = points1[i+1] end
		edge = p1 - p2
		norm = edge:perpendicular():normalized()
		axes[#axes+1] = norm
	end
	for i, v in pairs(points2) do
		p1 = points2[i]
		if i + 1 > #points2 then p2 = points2[1]
		else p2 = points2[i+1] end
		edge = p1 - p2
		norm = edge:perpendicular():normalized()
		axes[#axes+1] = norm
	end
	return axes
end

function sat.getAxesCircle(points, center)
	local axes = {}
	local region = 0
	for i = 1, #points do
		local i2, i3 = i+1, i+2
		if i2 > #points then i2 = i2 - #points end
		if i3 > #points then i3 = i3 - #points end
		local p1, p2, p3 = points[i], points[i2], points[i3]
		local vr = sat.getVornoiRegion(center, p2, p3)
		if vr == -1 then
			if sat.getVornoiRegion(center, p1, p2) == 1 then
				region = i2*2-1
			end
		elseif vr == 0 then
			if not sat.isLeft(center, p2, p3) then
				region = i2*2
			end
		end
		local edge, norm
		edge = center - p1
		norm = edge:normalized()
		axes[#axes+1] = norm
		edge = p1 - p2
		norm = edge:perpendicular():normalized()
		axes[#axes+1] = norm
	end
	return region, axes 
end

--hasn't been tested yet; might not work
function sat.collide(shape1, shape2)
	local points1, points2 = {}, {}
	for k, v in pairs(shape1._polygon.vertices) do
		points1[k] = vector.new(v.x, v.y)
	end
	for k, v in pairs(shape2._polygon.vertices) do
		points2[k] = vector.new(v.x, v.y)
	end
	local axes = sat.getAxes(points1, points2)
	local tempOverlap, storedOverlap = nil, math.huge
	local norm = nil
	for i, axis in pairs(axes) do
		local p1 = sat.getProjection(points1, axis)
		local p2 = sat.getProjection(points2, axis)
		tempOverlap = sat.overlap(p1, p2)
		if (tempOverlap < 0) then
			return false
		end
		if tempOverlap < storedOverlap then
			storedOverlap = tempOverlap
			norm = axis
		end
	end
	local mag = sat.overlap(sat.getProjection(points1, norm), sat.getProjection(points2, norm))

	return true, -norm, mag
end

function sat.collideCircle(circle, shape)
	local storedOverlap = math.huge
	local tempOverlap = nil
	local norm = nil
	local mag = nil
	local points = {}
	for k, v in pairs(shape._polygon.vertices) do
		points[k] = vector.new(v.x, v.y)
	end
	-- if not sat.isClockwise(points) then
	-- 	local newPoints = {}
	-- 	local sz = #points
	-- 	for i, v in ipairs(points) do
	-- 		newPoints[sz + 1 - i] = v
	-- 	end
	-- 	points = newPoints
	-- 	-- assert(sat.isClockwise(points))
	-- end
	local center = vector.new(circle._center.x, circle._center.y)
	local radius = circle._radius
	local region, axes = sat.getAxesCircle(points, center)
	for i, axis in pairs(axes) do
		if i % 2 == 0 or i == region then
			local p1 = sat.getProjection(points, axis)
			local p2 = sat.getProjectionCircle(center, radius, axis)
			tempOverlap = sat.overlap(p1, p2)
			if tempOverlap < 0 then
				return false
			end
			if region == 0 and tempOverlap < storedOverlap then
				storedOverlap = tempOverlap
				norm = axis
			end
		end
	end
	if region >= 1 then
		norm = axes[region]
	end
	local mag = sat.overlap(sat.getProjection(points, norm), sat.getProjectionCircle(center, radius, norm))
	if mag <= 1e-2 then return false end
	return true, norm, mag
end


--alternate version that's compatible with the original Hardon Collider
function sat.collideCircle2(circle, shape)
	local col, norm, mag = sat.collideCircle(circle, shape)
	if col then
		return true, norm.x * mag, norm.y * mag
	else
		return false, nil, nil
	end
end

function sat.isClockwise(vertices)
	local sum = 0
	for i = 1, #vertices do
		local p1 = vertices[i]
		local p2 = nil
		if i == #vertices then
			p2 = vertices[1]
		else
			p2 = vertices[i+1]
		end
		sum = sum + (p2.x-p1.x) * (p2.y+p2.y)
	end
	return sum
end





