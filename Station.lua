local class = require "class"
local Tile = require("Tile")

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

	self.synced = true

	self.hoverX, self.hoverY = nil, nil
	self.hoverPartX, self.hoverPartY = nil, nil
	self.hoverLineX, self.hoverLineY = nil, nil
	---@type Tile[]
	self.selectedTiles = {}
	self.dragX, self.dragY = nil, nil
	self.activeX, self.activeY = nil, nil
	self.activeMode = PathMode.TRAIN
	self.activeW24 = true

	self.canvas = nil
	self:generateCanvas()
end

---Generates a new canvas for all of the tiles to be drawn on.
---This should be called each time the station size changes.
---@private
function Station:generateCanvas()
	self.canvas = love.graphics.newCanvas(self.TILE_SIZE * self.w + 2, self.TILE_SIZE * self.h + 2)
end

---Updates the Station's logic.
---@param dt number Time delta in seconds.
function Station:update(dt)
	self.hoverX, self.hoverY = nil, nil
	self.hoverPartX, self.hoverPartY = nil, nil
	self.hoverLineX, self.hoverLineY = nil, nil
	if not _UI:isMouseInUI() then
		self.hoverX, self.hoverY = self:posToCoords(_MouseX, _MouseY)
		self.hoverPartX, self.hoverPartY = self:posToPartCoords(_MouseX, _MouseY)
		if self.hoverX and self.hoverY and self.hoverPartX and self.hoverPartY then
			self.hoverLineX, self.hoverLineY = self.hoverX + math.floor(self.hoverPartX * 2), self.hoverY + math.floor(self.hoverPartY * 2)
		end
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

---Returns `true` if the specified coordinates are inside of the schematic bounds, `false` otherwise.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@return boolean
function Station:isTileInBounds(x, y)
	return _Utils.isPointInsideBox(x, y, 1, 1, self.w - 1, self.h - 1)
end

---Returns a tile from this station based on coordinates, or `nil` if no tile lies at that location.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@return Tile?
function Station:getTile(x, y)
	return self.tiles[x] and self.tiles[x][y]
end

---Returns a tile from this station based on coordinates, or throws an error if no tile lies at that location.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@return Tile
function Station:assertGetTile(x, y)
	return assert(self:getTile(x, y), string.format("There is no tile at (%s, %s)", x, y))
end

---Destroys a tile at provided coordinates. Note that it is not replaced!
---Use `:setTile()` instead.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
function Station:destroyTile(x, y)
	self:unselectTile(x, y)
end

---Sets a tile at provided coordinates. This destroys the tile that was there previously.
---If a tile is specified that was previously somewhere on the schematic, it will be replaced with an empty tile to prevent duplication.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@param tile Tile? The tile to be set at position. If not specified, an empty Tile will be placed instead.
---@param move boolean? If `true`, the `tile` will be moved there, and its previous position will be replaced by an empty tile.
function Station:setTile(x, y, tile, move)
	self:destroyTile(x, y)
	self.tiles[x][y] = tile or Tile(self, x, y)
	if tile then
		if move then
			-- Replace the previous position with an empty tile.
			self.tiles[tile.x][tile.y] = Tile(self, tile.x, tile.y)
		end
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

---Returns the currently hovered tile, or throws an error if no tile is hovered.
---@return Tile
function Station:assertGetHoveredTile()
	return self:assertGetTile(self.hoverX, self.hoverY)
end

---Returns whether the tile at provided coordinates is currently selected.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@return boolean
function Station:isTileSelected(x, y)
	return _Utils.isValueInTable(self.selectedTiles, self:getTile(x, y))
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
	local tile = self:assertGetTile(x, y)
	table.insert(self.selectedTiles, tile)
	_UI:onTileSelected(tile)
end

---Unselects a tile at provided coordinates, if it is currently selected.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
function Station:unselectTile(x, y)
	_Utils.iTableRemoveFirstValue(self.selectedTiles, self:getTile(x, y))
	if _Utils.tableIsEmpty(self.selectedTiles) then
		_UI:onAllTilesUnselected()
	end
end

---Unselects all tiles.
function Station:unselectAllTiles()
	_Utils.emptyTable(self.selectedTiles)
	_UI:onAllTilesUnselected()
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

local TILE_SORT_FUNCTIONS = {
	xInc = function(a, b) return a.x < b.x end,
	xDec = function(a, b) return a.x > b.x end,
	yInc = function(a, b) return a.y < b.y end,
	yDec = function(a, b) return a.y > b.y end
}

---Moves all selected tiles by specified offset.
---If tiles are moving onto another tile, that tile is destroyed.
---If any of the moving tiles move outside of the schematic, they are destroyed.
---All empty spaces are replaced with empty tiles.
---@param tiles Tile[] The list of tiles to be moved up.
---@param dx integer Amount of tiles to move horizontally.
---@param dy integer Amount of tiles to move vertically.
function Station:moveTiles(tiles, dx, dy)
	-- Copy and sort the list.
	tiles = _Utils.copyTable(tiles)
	table.sort(tiles, TILE_SORT_FUNCTIONS[dx > 0 and "xDec" or (dx < 0 and "xInc" or (dy > 0 and "yDec" or "yInc"))])
	-- Move each tile and replace the starting tile with an empty tile.
	for i, tile in ipairs(tiles) do
		local x, y = tile.x, tile.y
		if self:isTileInBounds(x + dx, y + dy) then
			self:setTile(x + dx, y + dy, tile, true)
		else
			self:setTile(x, y)
		end
	end
end

---Returns whether just a single tile is selected in the current rectangle selection.
---@return boolean
function Station:rectSelectIsSingleTile()
	return self.dragX and self.dragY and self.hoverX == self.dragX and self.hoverY == self.dragY or false
end

---Executes a function for each selected tile.
---@param f fun(tile: Tile) The function to be executed.
function Station:forEachSelectedTile(f)
	for i, tile in ipairs(self.selectedTiles) do
		f(tile)
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
	for y, tile in ipairs(self.tiles[x]) do
		self:destroyTile(x, y)
	end
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
		self:destroyTile(x, y)
		table.remove(self.tiles[x], y)
	end
	self.h = self.h - 1
	self:recalculateTilePositions()
	self:generateCanvas()
end

---Returns the first found tile with the specified warp ID on this schematic.
---If none of the tiles have this ID, returns `nil`.
---TODO: When schematics are brought over here from the server, use the index from there.
---@param warpID string The warp ID to be looked for.
---@return Tile?
function Station:getTileWithWarpID(warpID)
	for x = 1, self.w do
		for y = 1, self.h do
			local tile = self:assertGetTile(x, y)
			if tile.warpID == warpID then
				return tile
			end
		end
	end
end

---Marks this Station as unsynced.
function Station:markUnsaved()
	self.synced = false
	_Project:markUnsaved()
end

---Synchronizes this Station and the entire project with the server to make sure pathfinding works correctly.
---@param force boolean? Whether the station should be resynced even if it is already marked as synced.
function Station:sync(force)
	if self.synced and not force then
		return
	end
	self.synced = true
	_Project:sync()
	_Com.sendCommand("r " .. self.shortcut)
end

---Handles the left click action.
---@private
function Station:handleLeftClick()
	-- Left click: action dependant on the current mode
	if self.hoverX and self.hoverY then
		if not _Picker.mode then
			-- Replace the tile (erases all properties)
			--local tile = Tile(self, self.hoverX, self.hoverY)
			--_Picker:augmentTile(tile)
			--self:setTile(self.hoverX, self.hoverY, tile)
			-- Keep the properties
			local tile = self:getTile(self.hoverX, self.hoverY)
			if tile then
				_Picker:augmentTile(tile)
				self:markUnsaved()
			end
		elseif _Picker.mode == "addColumn" then
			self:addColumn(self.hoverLineX)
			self:markUnsaved()
		elseif _Picker.mode == "addRow" then
			self:addRow(self.hoverLineY)
			self:markUnsaved()
		elseif _Picker.mode == "delColumn" then
			self:deleteColumn(self.hoverX)
			self:markUnsaved()
		elseif _Picker.mode == "delRow" then
			self:deleteRow(self.hoverY)
			self:markUnsaved()
		elseif _Picker.mode == "properties" then
			if not _Utils.isShiftPressed() and not _Utils.isCtrlPressed() then
				self:unselectAllTiles()
			end
			if not self:isTileSelected(self.hoverX, self.hoverY) then
				self:selectTile(self.hoverX, self.hoverY)
			else
				self:unselectTile(self.hoverX, self.hoverY)
			end
			self.dragX, self.dragY = self.hoverX, self.hoverY
		end
	else
		if _Picker.mode == "properties" then
			self:unselectAllTiles()
		end
	end
end

---Handles the left click release action.
---@private
function Station:handleLeftUnclick()
	if _Picker.mode == "properties" then
		if self.dragX and self.dragY then
			if self.hoverX and self.hoverY and not self:rectSelectIsSingleTile() then
				for x = math.min(self.dragX, self.hoverX), math.max(self.dragX, self.hoverX) do
					for y = math.min(self.dragY, self.hoverY), math.max(self.dragY, self.hoverY) do
						if _Utils.isCtrlPressed() then
							self:unselectTile(x, y)
						else
							self:selectTile(x, y)
						end
					end
				end
			end
			self.dragX, self.dragY = nil, nil
		end
	end
end

---Handles the right click action.
---@private
function Station:handleRightClick()
	-- Right click: remove a tile, flip selection or switch a switch
	if self.hoverX and self.hoverY then
		if not _Picker.mode then
			local tile = self:assertGetHoveredTile()
			if tile.id == "" then
				_Picker:flipSelection()
			else
				self:setTile(self.hoverX, self.hoverY)
				self:markUnsaved()
			end
		elseif _Picker.mode == "properties" then
			local tile = self:assertGetHoveredTile()
			if tile:isSwitch() then
				if tile:isSwitchForced() then
					tile:sendSwitchUnforce()
				else
					local suffix = nil
					if tile:isDoubleSwitch() then
						suffix = _Utils.isShiftPressed() and "cd" or "ab"
					end
					local state = tile:getSwitchState(suffix)
					if state then
						tile:sendSwitchState(not state.state, suffix)
						self:sync()
					end
				end
			elseif tile:isSemaphore() then
				if tile:isTrackReserved() then
					tile:sendSemaphoreUnreserve()
				elseif not tile:isSemaphoreStop() then
					tile:sendSemaphoreStop()
				else
					local allowTrain = tile.semaphoreAllowTrain or tile.semaphoreAllowSz
					local allowShunt = tile.semaphoreAllowShunt
					if allowTrain or allowShunt then
						self.activeX, self.activeY = self.hoverX, self.hoverY
						-- If only one mode is available, select it. Otherwise, Shift will force shunting mode.
						self.activeMode = PathMode.TRAIN
						if not allowTrain or (allowShunt and _Utils.isShiftPressed()) then
							self.activeMode = PathMode.SHUNT
						end
						self.activeW24 = not tile.semaphoreNoW24
					end
				end
			elseif self.activeX and self.activeY then
				if tile:isTargetForMode(self.activeMode) then
					local track1 = self:assertGetTile(self.activeX, self.activeY):getSemaphorePrevTrackID()
					local track2 = tile.trackID
					self:sync()
					if track1 and track2 then
						-- Pathfind by two tracks. Fancy!
						_Com.sendCommand("p " .. self.shortcut .. " " .. track1 .. " " .. track2 .. " " .. (self.activeMode == PathMode.TRAIN and "t" or "s"))
					else
						-- Pathfind the old way, by coordinates.
						_Com.sendCommand("pm " .. self.shortcut .. " " .. self.activeX .. " " .. self.activeY .. " " .. tile.x .. " " .. tile.y .. " " .. (self.activeMode == PathMode.TRAIN and "t" or "s"))
					end
					_Notifications:post("Sent pathfinding request.", NotificationColor.GRAY)
				end
				self.activeX, self.activeY = nil, nil
			elseif tile.warp then
				local station = _Project:getStation(tile.warp)
				if station then
					_Project:setCurrentStation(tile.warp)
					station:unselectAllTiles()
					local targetTile = station:getTileWithWarpID(tile.warpTargetID)
					if targetTile then
						station:selectTile(targetTile.x, targetTile.y)
					else
						_Notifications:post(string.format("Nie znaleziono punktu końcowego: %s:%s", tile.warp, tile.warpTargetID), NotificationColor.RED)
					end
				end
			elseif tile.command then
				tile:sendCustomCommand()
			end
		end
	else
		if _Picker.mode == "properties" then
			self.activeX, self.activeY = nil, nil
		end
	end
end

---Handles the middle click action.
---@private
function Station:handleMiddleClick()
	-- Middle click: tile pick
	local tile = self:getHoveredTile()
	if tile then
		_Picker:pickTile(tile)
	end
end

---Executed when a key is pressed.
---@param key string The key code.
function Station:keypressed(key)
	if _UI:getFocus() then
		return
	end
	if _Utils.isShiftPressed() then
		if key == "left" then
			self:moveTiles(self.selectedTiles, -1, 0)
		elseif key == "right" then
			self:moveTiles(self.selectedTiles, 1, 0)
		elseif key == "up" then
			self:moveTiles(self.selectedTiles, 0, -1)
		elseif key == "down" then
			self:moveTiles(self.selectedTiles, 0, 1)
		end
	else
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

---Executed when a mouse button is released.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button.
function Station:mousereleased(x, y, button)
	if button == 1 then
		self:handleLeftUnclick()
	end
end

---Executed when the mouse cursor is moved.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param dx integer The X movement, in pixels.
---@param dy integer The Y movement, in pixels.
function Station:mousemoved(x, y, dx, dy)
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
	self:drawRectSelection()
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.canvas, self.x + 0.5, self.y + 0.5, 0, self.SCALE)
	self:drawFrame()
end

---Draws the Station's tile backgrounds.
---@private
function Station:drawBackground()
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			self:drawTileBackground(tile, self:getTileBackgroundColor(tile))
		end
	end
end

---Draws the Station's tracks.
---@private
function Station:drawTracks()
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			self:drawTile(tile)
		end
	end
end

---Draws the Station's hovered tile frame, and also some helpers when adding/removing rows, tile ghosts, etc.
---@private
function Station:drawHover()
	if not self.hoverX or not self.hoverY then
		return
	end
	if not _Picker.mode then
		local x, y = self:coordsToCanvasPos(self.hoverX, self.hoverY)
		self:drawTileFrame(self:assertGetHoveredTile(), TileFrameColor.HOVER)
		-- Draw tile ghost.
		local category = _Picker:getSelectedCategory()
		local image = category.display and category.display.image or "s1"
		_DrawTile(x, y, _Picker:getSelectedTileID(), _Picker.electrified, false, false, false, 0, image, 1, 0.5)
	elseif _Picker.mode == "addColumn" then
		local x1, y1 = self:coordsToCanvasPos(self.hoverLineX, 1)
		local x2, y2 = self:coordsToCanvasPos(self.hoverLineX, self.h + 1)
		love.graphics.setColor(0, 1, 0)
		love.graphics.setLineWidth(2)
		love.graphics.line(x1, y1, x2, y2)
	elseif _Picker.mode == "addRow" then
		local x1, y1 = self:coordsToCanvasPos(1, self.hoverLineY)
		local x2, y2 = self:coordsToCanvasPos(self.w + 1, self.hoverLineY)
		love.graphics.setColor(0, 1, 0)
		love.graphics.setLineWidth(2)
		love.graphics.line(x1, y1, x2, y2)
	elseif _Picker.mode == "delColumn" then
		local x, y = self:coordsToCanvasPos(self.hoverX, 1)
		local w, h = self.TILE_SIZE, self.TILE_SIZE * self.h
		love.graphics.setColor(1, 0, 0, 0.5)
		love.graphics.rectangle("fill", x, y, w, h)
		love.graphics.setColor(1, 0, 0)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", x, y, w, h)
	elseif _Picker.mode == "delRow" then
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
	for i, tile in ipairs(self.selectedTiles) do
		self:drawTileFrame(tile, TileFrameColor.SELECTION)
	end
end

---Draws the currently active tile's frame.
---@private
function Station:drawActive()
	if not self.activeX or not self.activeY then
		return
	end
	local color = self.activeMode == PathMode.SHUNT and TileFrameColor.ACTIVE_SHUNT or TileFrameColor.ACTIVE
	self:drawTileFrame(self:assertGetTile(self.activeX, self.activeY), color)
end

---Draws the clickable tile frames.
---@private
function Station:drawClickable()
	if not self.activeX or not self.activeY then
		return
	end
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			if tile:isTargetForMode(self.activeMode) then
				self:drawTileFrame(tile, TileFrameColor.CLICKABLE)
			end
		end
	end
end

---Draws the rectangular selection frame.
---@private
function Station:drawRectSelection()
	if not self.dragX or not self.dragY or not self.hoverX or not self.hoverY then
		return
	end
	-- Do not display the frame if we are not selecting more than one tile.
	if self:rectSelectIsSingleTile() then
		return
	end
	for x = math.min(self.dragX, self.hoverX), math.max(self.dragX, self.hoverX) do
		for y = math.min(self.dragY, self.hoverY), math.max(self.dragY, self.hoverY) do
			self:drawTileFrame(self:assertGetTile(x, y), TileFrameColor.RECT_SELECTION)
		end
	end
end

---Draws the Station's frame, when the schematic is not synced with the server.
---@private
function Station:drawFrame()
	if self.synced then
		return
	end
	love.graphics.setColor(1, 1, 0)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", self.x, self.y, self.canvas:getWidth() * self.SCALE + 1, self.canvas:getHeight() * self.SCALE + 1)
end

--####################################################--
---------------- T I L E   D R A W I N G ---------------
--####################################################--

---Returns the position of the top left corner of the specified tile on the station canvas.
---@param tile Tile The tile to be drawn.
---@return number, number
function Station:getTilePos(tile)
	return self:coordsToCanvasPos(tile.x, tile.y)
end

---Returns the background color to be used for the specified Tile.
---@param tile Tile The tile to be drawn.
---@return TileBackgroundColor
function Station:getTileBackgroundColor(tile)
	if _Picker.highlightMode == TileHighlightMode.OFF or _Picker.mode ~= "properties" then
		return TileBackgroundColor.REGULAR
	end
	local trackWarning = tile.trackID and (not tile:isTrack() and not tile:isBlockadeGenerator() and not tile:isExitPoint())
	local switchWarning = tile.switchID and not tile:isSwitch()
	local semaphoreWarning = tile.semaphoreID and (not tile:isSemaphore() and not tile:isExitPoint())
	if trackWarning or switchWarning or semaphoreWarning then
		return TileBackgroundColor.WARNING
	end
	if tile.trackID and _Picker.highlightMode == TileHighlightMode.TRACK then
		return TileBackgroundColor.OK
	elseif tile.switchID and _Picker.highlightMode == TileHighlightMode.SWITCH then
		return TileBackgroundColor.OK
	elseif tile.semaphoreID and _Picker.highlightMode == TileHighlightMode.SEMAPHORE then
		return TileBackgroundColor.OK
	end
	return TileBackgroundColor.REGULAR
end

---Draws the specified Tile at the specified position.
---@param tile Tile The tile to be drawn.
function Station:drawTile(tile)
	local data = tile:getData()
	local x, y = self:getTilePos(tile)
	-- Calculate switch dim bits
	local switchDimBits = 0
	if data.tracks then
		for i = 1, 8 do
			if not tile:hasTraversibleTrackInDirection(i) then
				switchDimBits = switchDimBits + 2 ^ (i - 1)
			end
		end
	end
	local visible = not tile:isDimmedBySwitch()
	local occupied = visible and tile:isTrackOccupied()
	local reserved = visible and tile:isTrackReserved()
	local forced = tile:isSwitchForced()
	local semState = tile:getSemaphoreState()
	_DrawTile(x + tile.offset, y + tile.offset, tile.id, tile.electrified, occupied, reserved, forced, switchDimBits, semState)
end

---Draws the specified Tile's background at the specified position.
---@param tile Tile The tile to be drawn.
---@param color TileBackgroundColorEntry The background color set.
function Station:drawTileBackground(tile, color)
	local x, y = self:getTilePos(tile)
	love.graphics.setColor(color.fill)
	love.graphics.rectangle("fill", x, y, tile.size, tile.size)
	love.graphics.setColor(color.border)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x, y, tile.size, tile.size)
end

---Draws the specified Tile's frame at the specified position.
---@param tile Tile The tile to be drawn.
---@param color TileFrameColor The frame color.
function Station:drawTileFrame(tile, color)
	local x, y = self:getTilePos(tile)
	love.graphics.setColor(color[1], color[2], color[3], 0.2)
	love.graphics.rectangle("fill", x, y, tile.size, tile.size)
	love.graphics.setColor(color)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x, y, tile.size, tile.size)
end

--####################################--
---------------- D A T A ---------------
--####################################--

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
			local tile = Tile(self, x, y)
			tile:deserialize(t.tiles[tostring(x) .. "," .. tostring(y)])
			self.tiles[x][y] = tile
		end
	end
end

return Station
