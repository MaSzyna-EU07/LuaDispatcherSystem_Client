local class = require "class"
local Tile = require("Tile")
local Pathfinder = require("Pathfinder")

---@class Station : Class
---@overload fun(name, shortcut): Station
local Station = class:derive("Station")

function Station:new(name, shortcut)
	self.x, self.y = 40, 40
	self.SCALE = 1.5
	self.TILE_SIZE = 14

	if type(name) == "table" then
		self:deserialize(name)
	else
		self.name = name
		self.shortcut = shortcut
		self.w, self.h = 25, 10
		---@type Tile[][]
		self.tiles = {}

		-- Populate the station with empty tiles.
		for x = 1, self.w do
			self.tiles[x] = {}
			for y = 1, self.h do
				self.tiles[x][y] = Tile(self, x, y)
			end
		end
	end

	self.hoverX, self.hoverY = nil, nil
	self.hoverPartX, self.hoverPartY = nil, nil
	---@type {x: integer, y: integer}[]
	self.selectedTiles = {}
	self.activeX, self.activeY = nil, nil

	self.canvas = nil
	self:generateCanvas()
end

---Generates a new canvas for all of the tiles to be drawn on.
---This should be called each time the station size changes.
function Station:generateCanvas()
	self.canvas = love.graphics.newCanvas(self.TILE_SIZE * self.w + 2, self.TILE_SIZE * self.h + 2)
end

---Updates the Station's logic.
---@param dt number Time delta in seconds.
function Station:update(dt)
	self.hoverX, self.hoverY = nil, nil
	self.hoverPartX, self.hoverPartY = nil, nil
	if not _UI:isMouseInUI() then
		self.hoverX, self.hoverY = self:posToCoords(_MouseX, _MouseY)
		self.hoverPartX, self.hoverPartY = self:posToPartCoords(_MouseX, _MouseY)
	end
end

---Returns the full display name of this station.
---@return string
function Station:getFullName()
	return string.format("%s [%s]", self.name, self.shortcut)
end

---Returns the coordinates of the tile based on the global onscreen position.
---If there is no tile (out of bounds), returns `nil`.
---@param x number Global X position within the window.
---@param y number Global Y position within the window.
---@return integer?, integer?
function Station:posToCoords(x, y)
	local tileX, tileY = math.floor((x - self.x) / (self.TILE_SIZE * self.SCALE)) + 1, math.floor((y - self.y) / (self.TILE_SIZE * self.SCALE)) + 1
	if tileX >= 1 and tileY >= 1 and tileX <= self.w and tileY <= self.h then
		return tileX, tileY
	end
end

---Returns the partial coordinates within the hovered tile, from 0 to 1.
---@param x number Global X position within the window.
---@param y number Global Y position within the window.
---@return number, number
function Station:posToPartCoords(x, y)
	local partX, partY = ((x - self.x) / (self.TILE_SIZE * self.SCALE)) % 1, ((y - self.y) / (self.TILE_SIZE * self.SCALE)) % 1
	return partX, partY
end

---Returns the global onscreen position of the top left corner of the specified tile.
---@param tileX integer Tile X coordinate.
---@param tileY integer Tile Y coordinate.
---@return number, number
function Station:coordsToPos(tileX, tileY)
	return self.x + (tileX - 1) * self.TILE_SIZE * self.SCALE, self.y + (tileY - 1) * self.TILE_SIZE * self.SCALE
end

---Returns the on-canvas position of the top left corner of the specified tile.
---@param tileX integer Tile X coordinate.
---@param tileY integer Tile Y coordinate.
---@return number, number
function Station:coordsToCanvasPos(tileX, tileY)
	return (tileX - 1) * self.TILE_SIZE + 1, (tileY - 1) * self.TILE_SIZE + 1
end

---Returns a tile from this station based on coordinates, or `nil` if no tile lies at that location.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@return Tile?
function Station:getTile(x, y)
	return self.tiles[x] and self.tiles[x][y]
end

---Sets a tile at provided coordinates.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@param tile Tile? The tile to be set at position. If not specified, an empty Tile will be placed instead.
function Station:setTile(x, y, tile)
	self.tiles[x][y] = tile or Tile(self, x, y)
	if tile then
		tile.x, tile.y = x, y
	end
end

---Recalculates tiles' internal X and Y coordinates to make sure they align with the station's layout.
---@private
function Station:recalculateTilePositions()
	for x = 1, self.w do
		for y = 1, self.h do
			local tile = self.tiles[x][y]
			tile.x, tile.y = x, y
		end
	end
end

---Returns the currently hovered tile, if any.
---@return Tile?
function Station:getHoveredTile()
	return self:getTile(self.hoverX, self.hoverY)
end

---Returns whether the tile at provided coordinates is currently selected.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@return boolean
function Station:isTileSelected(x, y)
	for i, coords in ipairs(self.selectedTiles) do
		if coords.x == x and coords.y == y then
			return true
		end
	end
	return false
end

---Returns whether exactly one tile is selected.
---@return boolean
function Station:isSingleSelecting()
	return #self.selectedTiles == 1
end

---Returns whether two or more tiles are selected.
---@return boolean
function Station:isMultiSelecting()
	return #self.selectedTiles >= 2
end

---Selects a tile at provided coordinates, if it is not selected yet.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
function Station:selectTile(x, y)
	if self:isTileSelected(x, y) then
		return
	end
	table.insert(self.selectedTiles, {x = x, y = y})
	_UI:onTileSelected(assert(self:getTile(x, y), "There is no tile at (" .. x .. ", " .. y .. ")"))
end

---Unselects a tile at provided coordinates, if it is currently selected.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
function Station:unselectTile(x, y)
	for i, coords in ipairs(self.selectedTiles) do
		if coords.x == x and coords.y == y then
			table.remove(self.selectedTiles, i)
			return
		end
	end
end

---Unselects all tiles.
function Station:unselectAllTiles()
	_Utils.emptyTable(self.selectedTiles)
end

---Moves a single tile selection by provided amount of tiles.
---@param dx integer Amount of tiles to move horizontally.
---@param dy integer Amount of tiles to move vertically.
function Station:moveSingleSelection(dx, dy)
	if not self:isSingleSelecting() then
		return
	end
	local ox, oy = self.selectedTiles[1].x, self.selectedTiles[1].y
	local x, y = ox + dx, oy + dy
	if self:getTile(x, y) then
		self:unselectTile(ox, oy)
		self:selectTile(x, y)
	end
end

---Adds a new column at the specified position and fills it with empty tiles.
---@param x integer? The column index at which the new column will be placed. If not specified, a new column will be created on the right side.
function Station:addColumn(x)
	self.w = self.w + 1
	x = x or self.w
	table.insert(self.tiles, x, {})
	for y = 1, self.h do
		self.tiles[x][y] = Tile(self, x, y)
	end
	self:recalculateTilePositions()
	self:generateCanvas()
end

---Adds a new row at the specified position and fills it with empty tiles.
---@param y integer? The row index at which the new row will be placed. If not specified, a new column will be created at the bottom.
function Station:addRow(y)
	self.h = self.h + 1
	y = y or self.h
	for x = 1, self.w do
		table.insert(self.tiles[x], y, Tile(self, x, y))
	end
	self:recalculateTilePositions()
	self:generateCanvas()
end

---Removes a column at the specified index. All tiles belonging to that column will be IRRETRIEVABLY deleted.
---@param x integer? The column index which will be removed. If not specified, the rightmost column will be deleted.
function Station:deleteColumn(x)
	-- Avoid having 0 size.
	if self.w == 1 then
		return
	end
	x = x or self.w
	table.remove(self.tiles, x)
	self.w = self.w - 1
	self:recalculateTilePositions()
	self:generateCanvas()
end

---Removes a row at the specified index. All tiles belonging to that row will be IRRETRIEVABLY deleted.
---@param y integer? The row index which will be removed. If not specified, the bottommost row will be deleted.
function Station:deleteRow(y)
	-- Avoid having 0 size.
	if self.h == 1 then
		return
	end
	y = y or self.h
	for x = 1, self.w do
		table.remove(self.tiles[x], y)
	end
	self.h = self.h - 1
	self:recalculateTilePositions()
	self:generateCanvas()
end

---Handles the left click action.
---@private
function Station:handleLeftClick()
	-- Left click: action dependant on the current mode
	if self.hoverX and self.hoverY then
		if type(_Picker.selection) == "number" then
			local tile = Tile(self, self.hoverX, self.hoverY, _Picker.selection, _Picker.electrified)
			self:setTile(self.hoverX, self.hoverY, tile)
		elseif _Picker.selection == "addColumn" then
			-- TODO: Make hovered horizontal/vertical lines discrete state instead of calculating it everywhere!
			local hx = self.hoverX + math.floor(self.hoverPartX * 2)
			self:addColumn(hx)
		elseif _Picker.selection == "addRow" then
			-- TODO: Make hovered horizontal/vertical lines discrete state instead of calculating it everywhere!
			local hy = self.hoverY + math.floor(self.hoverPartY * 2)
			self:addRow(hy)
		elseif _Picker.selection == "delColumn" then
			self:deleteColumn(self.hoverX)
		elseif _Picker.selection == "delRow" then
			self:deleteRow(self.hoverY)
		elseif _Picker.selection == "properties" then
			if not love.keyboard.isDown("lshift") and not love.keyboard.isDown("rshift") then
				self:unselectAllTiles()
			end
			if not self:isTileSelected(self.hoverX, self.hoverY) then
				self:selectTile(self.hoverX, self.hoverY)
			else
				self:unselectTile(self.hoverX, self.hoverY)
			end
		end
	else
		if _Picker.selection == "properties" then
			self:unselectAllTiles()
		end
	end
end

---Handles the right click action.
---@private
function Station:handleRightClick()
	-- Right click: remove a tile, flip selection or switch a switch
	if self.hoverX and self.hoverY then
		if type(_Picker.selection) == "number" then
			local tile = assert(self:getHoveredTile())
			if tile.id == 0 then
				_Picker:flipSelection()
			else
				self:setTile(self.hoverX, self.hoverY)
			end
		elseif _Picker.selection == "properties" then
			local tile = assert(self:getHoveredTile())
			if tile:isSwitch() then
				local suffix = nil
				if tile:isDoubleSwitch() then
					local shift = love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")
					suffix = shift and "cd" or "ab"
				end
				tile:sendSwitchState(not tile:getSwitchState(suffix), suffix)
			elseif tile:isSemaphore() then
				self.activeX, self.activeY = self.hoverX, self.hoverY
			elseif self.activeX and self.activeY then
				local itineraryEndID = tile:getItineraryEndID()
				if itineraryEndID then
					local pathfinder = Pathfinder(assert(self:getTile(self.activeX, self.activeY)), tile)
					pathfinder:calculatePath()
					pathfinder:sendPath()
				end
				self.activeX, self.activeY = nil, nil
			end
		end
	end
end

---Handles the middle click action.
---@private
function Station:handleMiddleClick()
	-- Middle click: tile pick
	if self.hoverX and self.hoverY then
		_Picker.selection = self:getHoveredTile().id
	end
end

---Executed when a key is pressed.
---@param key string The key code.
function Station:keypressed(key)
	if _UI:getFocus() then
		return
	end
	if key == "left" then
		self:moveSingleSelection(-1, 0)
	elseif key == "right" then
		self:moveSingleSelection(1, 0)
	elseif key == "up" then
		self:moveSingleSelection(0, -1)
	elseif key == "down" then
		self:moveSingleSelection(0, 1)
	end
end

---Executed when a mouse button is pressed.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button.
function Station:mousepressed(x, y, button)
	if _UI:isMouseInUI() then
		return
	end
	if button == 1 then
		self:handleLeftClick()
	elseif button == 2 then
		self:handleRightClick()
	elseif button == 3 then
		self:handleMiddleClick()
	end
end

---Serializes the Station's data to be saved as a file.
---@return table
function Station:serialize()
	local t = {
		name = self.name,
		shortcut = self.shortcut,
		w = self.w,
		h = self.h,
		tiles = {}
	}
	for x, column in ipairs(self.tiles) do
		for y, tile in ipairs(column) do
			t.tiles[tostring(x) .. "," .. tostring(y)] = tile:serialize()
		end
	end
	return t
end

---Deserializes the Station's data to be restored from a file.
---@param t table The saved data.
function Station:deserialize(t)
	self.name = t.name
	self.shortcut = t.shortcut
	self.w, self.h = t.w, t.h
	self.tiles = {}
	for x = 1, self.w do
		self.tiles[x] = {}
		for y = 1, self.h do
			self.tiles[x][y] = Tile(self, x, y, t.tiles[tostring(x) .. "," .. tostring(y)])
		end
	end
end

--##########################################--
---------------- D R A W I N G ---------------
--##########################################--

---Draws the Station's components.
function Station:draw()
	love.graphics.setCanvas(self.canvas)
	self:drawBackground()
	self:drawTracks()
	self:drawHover()
	self:drawSelection()
	self:drawActive()
	self:drawClickable()
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.canvas, self.x + 0.5, self.y + 0.5, 0, self.SCALE)
end

---Draws the Station's background.
---@private
function Station:drawBackground()
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			tile:drawBackground()
		end
	end
end

---Draws the Station's tracks.
---@private
function Station:drawTracks()
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			tile:draw()
		end
	end
end

---Draws the Station's hovered tile frame, and also some helpers when adding/removing rows, tile ghosts, etc.
---@private
function Station:drawHover()
	if not self.hoverX or not self.hoverY then
		return
	end
	if type(_Picker.selection) == "number" then
		local x, y = self:coordsToCanvasPos(self.hoverX, self.hoverY)
		self:getHoveredTile():drawHover()
		-- Draw tile ghost.
		_DrawTile(x, y, _Picker.selection, _Picker.electrified, false, false, 0, "s1", 1, 0.5)
	elseif _Picker.selection == "addColumn" then
		-- TODO: Make hovered horizontal/vertical lines discrete state instead of calculating it everywhere!
		local hx = self.hoverX + math.floor(self.hoverPartX * 2)
		local x1, y1 = self:coordsToCanvasPos(hx, 1)
		local x2, y2 = self:coordsToCanvasPos(hx, self.h + 1)
		love.graphics.setColor(0, 1, 0)
		love.graphics.setLineWidth(2)
		love.graphics.line(x1, y1, x2, y2)
	elseif _Picker.selection == "addRow" then
		-- TODO: Make hovered horizontal/vertical lines discrete state instead of calculating it everywhere!
		local hy = self.hoverY + math.floor(self.hoverPartY * 2)
		local x1, y1 = self:coordsToCanvasPos(1, hy)
		local x2, y2 = self:coordsToCanvasPos(self.w + 1, hy)
		love.graphics.setColor(0, 1, 0)
		love.graphics.setLineWidth(2)
		love.graphics.line(x1, y1, x2, y2)
	elseif _Picker.selection == "delColumn" then
		local x, y = self:coordsToCanvasPos(self.hoverX, 1)
		local w, h = self.TILE_SIZE, self.TILE_SIZE * self.h
		love.graphics.setColor(1, 0, 0, 0.5)
		love.graphics.rectangle("fill", x, y, w, h)
		love.graphics.setColor(1, 0, 0)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", x, y, w, h)
	elseif _Picker.selection == "delRow" then
		local x, y = self:coordsToCanvasPos(1, self.hoverY)
		local w, h = self.TILE_SIZE * self.w, self.TILE_SIZE
		love.graphics.setColor(1, 0, 0, 0.5)
		love.graphics.rectangle("fill", x, y, w, h)
		love.graphics.setColor(1, 0, 0)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", x, y, w, h)
	end
end

---Draws the selection frame for all selected tiles.
---@private
function Station:drawSelection()
	for i, coords in ipairs(self.selectedTiles) do
		self:getTile(coords.x, coords.y):drawSelection()
	end
end

---Draws the currently active tile's frame.
---@private
function Station:drawActive()
	if not self.activeX or not self.activeY then
		return
	end
	self:getTile(self.activeX, self.activeY):drawActive()
end

---Draws the clickable tile frames.
---@private
function Station:drawClickable()
	if not self.activeX or not self.activeY then
		return
	end
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			if tile:getItineraryEndID() then
				tile:drawClickable()
			end
		end
	end
end

return Station
