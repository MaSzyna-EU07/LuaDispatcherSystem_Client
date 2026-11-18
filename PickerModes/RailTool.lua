local Class = require("lua.core.class")

---@class RailTool : Class
---@overload fun(station: Station): RailTool
local RailTool = Class:derive("RailTool")

---Creates a Rail Tool.
---@param station Station The station this tool will be editing.
function RailTool:new(station)
    self.station = station

	self.hoverRailX, self.hoverRailY = nil, nil
	self.dragX, self.dragY = nil, nil
	self.dragEndX, self.dragEndY = nil, nil
	self.dragDir = nil
	self.remove = false
end

---Updates the Rail Tool logic.
---@param dt number Time delta in seconds.
function RailTool:update(dt)
	self.hoverRailX, self.hoverRailY = nil, nil
	self.dragEndX, self.dragEndY = nil, nil
	if not _UI:isMouseInUI() then
		if self.station.hoverX and self.station.hoverY and self.station.hoverPartX and self.station.hoverPartY then
			-- Hover rail tool
			self.hoverRailX, self.hoverRailY = self.station:coordsSnapToCenterAndEdges(self.station.hoverX + self.station.hoverPartX, self.station.hoverY + self.station.hoverPartY, 0.25)
			if self.dragX and self.dragY then
				-- We are dragging, so we need to determine the end position
				local dx, dy = self.hoverRailX - self.dragX, self.hoverRailY - self.dragY
				local angle = -_V.angle(dx, dy)
				local angles = _Dir.dirsToAngles(self:getValidDragDirections())
				local dir = _Dir.angleToDir(_Utils.getClosestAngle(angle, angles))
				local length = math.floor(math.abs(dx) + math.abs(dy)) / 2
				-- Do not consider an irrelevant axis on horizontal drags when calculating length
				if dir == 1 or dir == 5 then
					length = math.abs(dy)
				elseif dir == 3 or dir == 7 then
					length = math.abs(dx)
				end
				self.dragEndX, self.dragEndY = self.dragX + _Dir.DIRS[dir].x * length, self.dragY + _Dir.DIRS[dir].y * length
				self.dragDir = dir
			end
		end
	end
end

---While using the drag tool, returns a list of valid directions to go towards depending on the currently held point.
---Returns an empty list if no point is being held with the rail tool.
---@private
---@return integer[]
function RailTool:getValidDragDirections()
	if not self.dragX or not self.dragY then
		return {}
	end
	local h, v = self.dragX % 1 == 0, self.dragY % 1 == 0
	if h and v then
		-- Corners -> Diagonals
		return {2, 4, 6, 8}
	elseif h and not v then
		-- Left/Right -> Horizontals
		return {3, 7}
	elseif not h and v then
		-- Up/Down -> Verticals
		return {1, 5}
	else
		-- Middle -> All directions
		return {1, 2, 3, 4, 5, 6, 7, 8}
	end
end

---Returns a list of tiles which are affected by the current shape of the line, their affected directions and the resulting IDs.
---The resulting ID can be `nil` if conversion isn't possible.
---@private
---@return {tile: Tile, dirs: integer[], newID: string?}[]
function RailTool:getAffectedDragTiles()
	if not self.dragEndX or not self.dragEndY then
		return {}
	end
	local tiles = {}
	local x, y = self.dragX, self.dragY
	local dir = self.dragDir
	while x ~= self.dragEndX or y ~= self.dragEndY do
		local dx, dy = _Dir.DIRS[dir].x * 0.5, _Dir.DIRS[dir].y * 0.5
		local tile = self.station:getTile(math.floor(x + dx / 2), math.floor(y + dy / 2))
		if not tile then
			break
		end
		if #tiles == 0 or tiles[#tiles].tile ~= tile then
			table.insert(tiles, {tile = tile, dirs = {}})
		end
		table.insert(tiles[#tiles].dirs, (x % 1 ~= 0 and y % 1 ~= 0) and dir or _Dir.invertDir(dir))
		x, y = x + dx, y + dy
	end
	for i, tile in ipairs(tiles) do
		tile.newID = _Picker:getMaskedTrackTileID(tile.tile, _Dir.dirsToBitsum(tile.dirs), self.remove)
	end
	return tiles
end

---Applies the changes suggested by `:getAffectedDragTiles()`.
---@private
function RailTool:confirmDrag()
	local tiles = self:getAffectedDragTiles()
	for i, tile in ipairs(tiles) do
		if tile.newID then
			tile.tile.id = tile.newID
			self.station:markUnsaved()
		end
	end
end

---Handles the left click action.
function RailTool:handleLeftClick()
	if self.dragX and self.dragY and self.remove then
		-- Cancel dragging if we were holding the right mouse button
		self.dragX, self.dragY = nil, nil
	else
		-- Start dragging with the left mouse button
		self.dragX, self.dragY = self.hoverRailX, self.hoverRailY
		self.remove = false
	end
end

---Handles the left click release action.
function RailTool:handleLeftUnclick()
	if self.dragX and self.dragY then
		self:confirmDrag()
		self.dragX, self.dragY = nil, nil
	end
end

---Handles the right click action.
function RailTool:handleRightClick()
	if self.dragX and self.dragY and not self.remove then
		-- Cancel dragging if we were holding the left mouse button
		self.dragX, self.dragY = nil, nil
	else
		-- Start dragging with the right mouse button
		self.dragX, self.dragY = self.hoverRailX, self.hoverRailY
		self.remove = true
	end
end

---Handles the right click release action.
function RailTool:handleRightUnclick()
	if self.dragX and self.dragY then
		self:confirmDrag()
		self.dragX, self.dragY = nil, nil
	end
end

---Draws the guides for the rail tool.
function RailTool:drawHover()
	if _Picker.mode ~= PickerMode.RAILS then
		return
	end
	local dragging = self.dragX and self.dragY
	if not dragging then
		if self.hoverRailX and self.hoverRailY then
			local x, y = self.station:coordsToCanvasPos(self.hoverRailX, self.hoverRailY)
			love.graphics.setColor(0, 1, 1)
			love.graphics.circle("fill", x, y, 3)
		end
	else
		local startX, startY = self.station:coordsToCanvasPos(self.dragX, self.dragY)
		if self.dragEndX and self.dragEndY then
			local endX, endY = self.station:coordsToCanvasPos(self.dragEndX, self.dragEndY)
			love.graphics.setColor(self.remove and 1 or 0, self.remove and 0 or 1, 0)
			love.graphics.setLineWidth(2)
			love.graphics.line(startX, startY, endX, endY)
			love.graphics.setColor(0, 1, 1)
			love.graphics.circle("fill", endX, endY, 3)
		end
		love.graphics.setColor(0, 1, 1)
		love.graphics.circle("fill", startX, startY, 3)
	end
end

---Sets the frame colors for the affected tiles if the rail tool is active.
function RailTool:setTileFrameColors()
	if _Picker.mode ~= PickerMode.RAILS then
		return
	end
	local dragging = self.dragX and self.dragY
	if dragging then
		local tiles = self:getAffectedDragTiles()
		for i, tile in ipairs(tiles) do
			if tile.tile.id ~= tile.newID then
				self.station:setTileFrameColor(tile.tile, tile.newID and TileFrameColor.RAILDRAG_AFFECTED or TileFrameColor.RAILDRAG_CONFLICT)
			end
		end
	end
end

return RailTool