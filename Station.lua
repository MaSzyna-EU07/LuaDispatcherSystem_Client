local class = require "lua.core.class"
local Tile = require("lua.core.Tile")
local TileList = require("TileList")
local Tooltip = require("Tooltip")
local RailTool = require("PickerModes.RailTool")
local Pathfinder = require("lua.core.Pathfinder.Pathfinder")
local PathMode = require("lua.core.Enums.PathMode")

---@class Station : Class
---@overload fun(name, shortcut): Station
local Station = class:derive("Station")

function Station:new(name, shortcut)
	self.x, self.y = 5, 61
	self.TILE_SIZE = 14
	self.CANVAS_MARGIN = 2

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
	self.selectedTiles = TileList()
	self.dragX, self.dragY = nil, nil
	self.railTool = RailTool(self)
	self.activeX, self.activeY = nil, nil
	self.activeMode = PathMode.TRAIN
	self.activeW24 = true
	---@alias TileHighlight {x: integer, y: integer, type: integer, t: number, delQueue: boolean?}
	---@type TileHighlight[]
	self.tileHighlights = {}
	---@type table<Tile, TileColorEntry>
	self.tileFrameColors = {}
	---@type table<Tile, Tooltip>
	self.tileTooltips = {}
	self.tileTooltipsEnabled = false
	---@type Path?
	self.pathTest = nil
	---@type Pathfinder?
	self.pathfinderTest = nil

	self.canvas = nil
	self:generateCanvas()
end

---Generates a new canvas for all of the tiles to be drawn on.
---This should be called each time the station size changes.
---@private
function Station:generateCanvas()
	self.canvas = love.graphics.newCanvas(self.TILE_SIZE * self.w + self.CANVAS_MARGIN * 2, self.TILE_SIZE * self.h + self.CANVAS_MARGIN * 2)
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
	end
	self.railTool:update(dt)

	-- Update the tooltip.
	local hoveredTile = self:getHoveredTile()
	if hoveredTile then
		local text = self:getTileTooltip(hoveredTile)
		if text then
			_Tooltip:setText(text)
			_Tooltip:setPos(self:coordsToPos(hoveredTile.x + 0.5, hoveredTile.y))
			_Tooltip:setAnchor(0.5, 1)
		end
	end

	-- Update the tile highlights.
	for i, highlight in ipairs(self.tileHighlights) do
		highlight.t = highlight.t + dt
		if highlight.t >= 1 then
			highlight.delQueue = true
		end
	end
	_Utils.removeDeadObjects(self.tileHighlights)

	-- Update the pathfinder test.
	if self.pathfinderTest then
		local tile = self.pathfinderTest:getNextUnexploredTile()
		self.pathTest = self.pathfinderTest:getPath(tile)
		local result = self.pathfinderTest:findPathStep()
		if result ~= nil then
			if result then
				self.pathfinderTest:extendPath(self.pathTest)
				local itineraries = self.pathfinderTest:getItineraries(self.pathTest)
				for i, itinerary in ipairs(itineraries) do
					itinerary:examine()
				end
			end
			self.pathfinderTest = nil
			print(result and "SUCCESS" or "FAILURE")
		end
	end
end

---Returns the full display name of this station.
---@return string
function Station:getFullName()
	return string.format("%s [%s]", self.name, self.shortcut)
end

---Returns the coordinates of the tile based on the global onscreen position, including fractions.
---If there is no tile (out of bounds), returns `nil`.
---@param x number Global X position within the window.
---@param y number Global Y position within the window.
---@return number?, number?
function Station:posToFullCoords(x, y)
	local tileX = (x - self.x - self.CANVAS_MARGIN * _Settings.scale) / (self.TILE_SIZE * _Settings.scale) + 1
	local tileY = (y - self.y - self.CANVAS_MARGIN * _Settings.scale) / (self.TILE_SIZE * _Settings.scale) + 1
	if tileX >= 1 and tileY >= 1 and tileX < self.w + 1 and tileY < self.h + 1 then
		return tileX, tileY
	end
end

---Returns the coordinates of the tile based on the global onscreen position.
---If there is no tile (out of bounds), returns `nil`.
---@param x number Global X position within the window.
---@param y number Global Y position within the window.
---@return integer?, integer?
function Station:posToCoords(x, y)
	local tileX, tileY = self:posToFullCoords(x, y)
	if tileX and tileY then
		return math.floor(tileX), math.floor(tileY)
	end
end

---Returns the partial coordinates within the hovered tile, from 0 to 1.
---If there is no tile (out of bounds), returns `nil`.
---@param x number Global X position within the window.
---@param y number Global Y position within the window.
---@return number?, number?
function Station:posToPartCoords(x, y)
	local tileX, tileY = self:posToFullCoords(x, y)
	if tileX and tileY then
		return tileX % 1, tileY % 1
	end
end

---Returns the global onscreen position of the top left corner of the specified tile.
---@param tileX integer Tile X coordinate.
---@param tileY integer Tile Y coordinate.
---@return number, number
function Station:coordsToPos(tileX, tileY)
	local canvasX, canvasY = self:coordsToCanvasPos(tileX, tileY)
	return self.x + canvasX * _Settings.scale, self.y + canvasY * _Settings.scale
end

---Returns the on-canvas position of the top left corner of the specified tile.
---@param tileX integer Tile X coordinate.
---@param tileY integer Tile Y coordinate.
---@return number, number
function Station:coordsToCanvasPos(tileX, tileY)
	return (tileX - 1) * self.TILE_SIZE + self.CANVAS_MARGIN, (tileY - 1) * self.TILE_SIZE + self.CANVAS_MARGIN
end

---Returns the specified position snapped to the tile edge or center.
---@param x number X coordinate.
---@param y number Y coordinate.
---@param margin number Number in range [0, 0.5]. The margin of edge attraction at the cost of attraction to the center, in tiles.
---@return number, number
function Station:coordsSnapToCenterAndEdges(x, y, margin)
	if x % 1 >= 1 - margin then
		x = math.ceil(x)
	elseif x % 1 >= margin then
		x = math.floor(x) + 0.5
	else
		x = math.floor(x)
	end
	if y % 1 >= 1 - margin then
		y = math.ceil(y)
	elseif y % 1 >= margin then
		y = math.floor(y) + 0.5
	else
		y = math.floor(y)
	end
	return x, y
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
	local tile = assert(self:getTile(x, y), string.format("There is no tile at (%s, %s)", x, y))
	return tile
end

---Destroys a tile at provided coordinates. Note that it is not replaced!
---Use `:setTile()` instead.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
function Station:destroyTile(x, y)
	self:unselectTile(x, y)
	-- Unmark the destroyed tile.
	if self.activeX == x and self.activeY == y then
		self.activeX, self.activeY = nil, nil
	end
	if self.dragX == x and self.dragY == y then
		self.dragX, self.dragY = nil, nil
	end
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

---Returns the currently active tile, if any.
---@return Tile?
function Station:getActiveTile()
	return self:getTile(self.activeX, self.activeY)
end

---Returns the currently active tile, or throws an error if no tile is active.
---@return Tile
function Station:assertGetActiveTile()
	return self:assertGetTile(self.activeX, self.activeY)
end

---Returns whether the tile at provided coordinates is currently selected.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
---@return boolean
function Station:isTileSelected(x, y)
	return self.selectedTiles:contains(self:assertGetTile(x, y))
end

---Returns whether exactly one tile is selected.
---@return boolean
function Station:isSingleSelecting()
	return self.selectedTiles:size() == 1
end

---Returns whether two or more tiles are selected.
---@return boolean
function Station:isMultiSelecting()
	return self.selectedTiles:size() >= 2
end

---Selects a tile at provided coordinates, if it is not selected yet.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
function Station:selectTile(x, y)
	self.selectedTiles:insertOnce(self:assertGetTile(x, y))
	_UI:onSelectedTilesChanged(self.selectedTiles)
end

---Unselects a tile at provided coordinates, if it is currently selected.
---@param x integer X coordinate of the tile.
---@param y integer Y coordinate of the tile.
function Station:unselectTile(x, y)
	self.selectedTiles:removeFirst(self:assertGetTile(x, y))
	_UI:onSelectedTilesChanged(self.selectedTiles)
end

---Selects a rectangle of tiles at provided coordinates.
---@param x integer X coordinate of the tile at the top left corner.
---@param y integer Y coordinate of the tile at the top left corner.
---@param w integer Width of the selection, in tiles.
---@param h integer Height of the selection, in tiles.
function Station:selectRectTiles(x, y, w, h)
	for ox = 0, w - 1 do
		for oy = 0, h - 1 do
			self.selectedTiles:insertOnce(self:assertGetTile(x + ox, y + oy))
		end
	end
	_UI:onSelectedTilesChanged(self.selectedTiles)
end

---Unselects a rectangle of tiles at provided coordinates.
---@param x integer X coordinate of the tile at the top left corner.
---@param y integer Y coordinate of the tile at the top left corner.
---@param w integer Width of the selection, in tiles.
---@param h integer Height of the selection, in tiles.
function Station:unselectRectTiles(x, y, w, h)
	for ox = 0, w - 1 do
		for oy = 0, h - 1 do
			self.selectedTiles:removeFirst(self:assertGetTile(x + ox, y + oy))
		end
	end
	_UI:onSelectedTilesChanged(self.selectedTiles)
end

---Unselects all tiles.
function Station:unselectAllTiles()
	self.selectedTiles:empty()
	_UI:onSelectedTilesChanged(self.selectedTiles)
end

---Clears all selected tiles and replaces them with empty ones.
function Station:clearSelectedTiles()
	for i = self.selectedTiles:size(), 1, -1 do
		local tile = assert(self.selectedTiles:get(i))
		self:setTile(tile.x, tile.y)
	end
end

---Moves a single tile selection by provided amount of tiles.
---@param dx integer Amount of tiles to move horizontally.
---@param dy integer Amount of tiles to move vertically.
function Station:moveSingleSelection(dx, dy)
	if not self:isSingleSelecting() then
		return
	end
	local tile = assert(self.selectedTiles:get(1))
	local x, y = tile.x + dx, tile.y + dy
	if self:getTile(x, y) then
		self:unselectTile(tile.x, tile.y)
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
---@param tiles TileList The list of tiles to be moved up.
---@param dx integer Amount of tiles to move horizontally.
---@param dy integer Amount of tiles to move vertically.
function Station:moveTiles(tiles, dx, dy)
	-- Copy and sort the list.
	tiles = tiles:copy()
	tiles:sort(TILE_SORT_FUNCTIONS[dx > 0 and "xDec" or (dx < 0 and "xInc" or (dy > 0 and "yDec" or "yInc"))])
	-- Move each tile and replace the starting tile with an empty tile.
	for i, tile in ipairs(tiles:getItems()) do
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
	self.selectedTiles:forEachItem(f)
end

---Briefly highlights the given tile.
---@param x integer X coordinate of the tile that should be highlighted.
---@param y integer Y coordinate of the tile that should be highlighted.
---@param type integer The highlight type.
function Station:highlightTile(x, y, type)
	table.insert(self.tileHighlights, {x = x, y = y, t = 0, type = type})
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
	self:afterSizeChange()
end

---Adds a new row at the specified position and fills it with empty tiles.
---@param y integer? The row index at which the new row will be placed. If not specified, a new column will be created at the bottom.
function Station:addRow(y)
	self.h = self.h + 1
	y = y or self.h
	for x = 1, self.w do
		table.insert(self.tiles[x], y, Tile(self, x, y))
	end
	self:afterSizeChange()
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
	self:afterSizeChange()
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
	self:afterSizeChange()
end

---Does stuff after changing the station size to make sure internally cached values are right.
---@private
function Station:afterSizeChange()
	self:recalculateTilePositions()
	self:generateCanvas()
end

---Zooms the schematic in or out.
---@param steps integer Positive values increase the zoom, negative ones decrease it.
function Station:zoom(steps)
	_Settings.scale = _Utils.clamp(_Settings.scale + steps * 0.25, 1, 4)
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

---Returns another station of this project, or `nil` if there is none with that shortcut.
---The shared `Tile` code resolves warps through this function.
---@param shortcut string The station shortcut.
---@return Station?
function Station:findSchematic(shortcut)
	return _Project:getStation(shortcut)
end

---Returns the exit point tile with the given ID on this station, or `nil` if there is none.
---The shared `Tile` code resolves warps through this function.
---@param exitID string The exit point ID.
---@return Tile?
function Station:getExitTile(exitID)
	return self:getTileWithWarpID(exitID)
end

---Returns the tooltip text for the specified tile, if any.
---@param tile Tile The tile to generate tooltip for.
---@return string?
function Station:getTileTooltip(tile)
	local lines = {}
	if tile.stationName then
		local str = "Stacja: " .. tile.stationName
		if tile.stationTrack then
			str = str .. " t" .. tile.stationTrack
		end
		if tile.stationPlatform then
			str = str .. " p" .. tile.stationPlatform
		end
		table.insert(lines, str)
	end
	if tile:isSwitch() and tile.switchID then
		table.insert(lines, "Rozjazd: " .. tile.switchID)
	end
	if tile:isSemaphore() and tile.semaphoreID then
		table.insert(lines, "Semafor: " .. tile.semaphoreID)
	end
	if tile:isBlockadeGenerator() and tile.blockadeID then
		table.insert(lines, "Blokada: " .. tile.blockadeID)
		local state = tile:getBlockadeState()
		if state then
			if state.direction then
				table.insert(lines, "    Kierunek: N")
			elseif state.direction == false then
				table.insert(lines, "    Kierunek: P")
			else
				table.insert(lines, "    Kierunek: X")
			end
		end
	end
	if tile.warp then
		local station = _Project:getStation(tile.warp)
		table.insert(lines, string.format("-> %s (%s) [%s] -> [%s]", station and station.name or "<Nieznana stacja>", tile.warp, tile.warpID or "???", tile.warpTargetID or "???"))
	end
	if tile:isTrack() and tile.trackID then
		table.insert(lines, "Tor: " .. tile.trackID)
		if tile:isTrackOccupied() then
			table.insert(lines, "    Zajęty")
		end
		if tile:isTrackReserved() then
			local reservationState = tile:getTrackReservationState()
			if reservationState and reservationState.semaphoreID then
				table.insert(lines, "    Zarezerwowany (" .. reservationState.semaphoreID .. ")")
			else
				table.insert(lines, "    Zarezerwowany")
			end
		end
		local vehicles = tile:getTrackVehicleState()
		if vehicles and not _Utils.tableIsEmpty(vehicles) then
			table.insert(lines, "Pojazdy:")
			for i, vehicle in ipairs(_Utils.tableGetSortedKeys(vehicles)) do
				table.insert(lines, string.format("  - %s (%s)", vehicle, vehicles[vehicle]))
			end
		end
	end
	if _Debug then
		--table.insert(lines, string.format("DEBUG: %s, %s (%s)", tile.x, tile.y, tile.id))
		local speed = tile:getSpeed()
		if speed then
			--table.insert(lines, "Current Speed: " .. tostring(speed))
		end
		local semaphoreDirection = tile:getSemaphoreDirection()
		if semaphoreDirection then
			--table.insert(lines, "Semaphore Direction: " .. tostring(semaphoreDirection))
		end
		local warpExitDirection = tile:getWarpExitDirection()
		if warpExitDirection then
			table.insert(lines, string.format("Warp Exit: %s", warpExitDirection))
		end
	end
	return #lines > 0 and _Utils.strJoin(lines, "\n") or nil
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

---Summons a test pathfinder from the active tile to the hovered tile.
function Station:pathfindTest()
	local hoveredTile = self:getHoveredTile()
	local activeTile = self:getActiveTile()
	if not hoveredTile or not activeTile then
		return
	end
	local pathfinder = Pathfinder(activeTile, hoveredTile)
	pathfinder:setMode(self.activeMode)
	local itineraries = pathfinder:findPathAndGetItineraries()
	if not itineraries then
		self.pathTest = nil
		return
	end
	for i, itinerary in ipairs(itineraries) do
		itinerary:examine()
	end
end

---Summons a test pathfinder from the active tile to the hovered tile.
---One exploration is done per frame, instead of calculating everything instantly.
function Station:slowPathfindTest()
	local hoveredTile = self:getHoveredTile()
	local activeTile = self:getActiveTile()
	if not hoveredTile or not activeTile then
		return
	end
	self.pathfinderTest = Pathfinder(activeTile, hoveredTile)
	self.pathfinderTest:setMode(self.activeMode)
end

---Handles the left click action.
---@private
function Station:handleLeftClick()
	-- Left click: action dependant on the current mode
	if self.hoverX and self.hoverY then
		if _Picker.mode == PickerMode.TILE then
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
		elseif _Picker.mode == PickerMode.ADD_COLUMN then
			self:addColumn(self.hoverLineX)
			self:markUnsaved()
		elseif _Picker.mode == PickerMode.ADD_ROW then
			self:addRow(self.hoverLineY)
			self:markUnsaved()
		elseif _Picker.mode == PickerMode.DEL_COLUMN then
			self:deleteColumn(self.hoverX)
			self:markUnsaved()
		elseif _Picker.mode == PickerMode.DEL_ROW then
			self:deleteRow(self.hoverY)
			self:markUnsaved()
		elseif _Picker.mode == PickerMode.PROPERTIES then
			if not _Utils.isShiftPressed() and not _Utils.isCtrlPressed() then
				self:unselectAllTiles()
			end
			if not self:isTileSelected(self.hoverX, self.hoverY) then
				self:selectTile(self.hoverX, self.hoverY)
			else
				self:unselectTile(self.hoverX, self.hoverY)
			end
			self.dragX, self.dragY = self.hoverX, self.hoverY
		elseif _Picker.mode == PickerMode.ELECTRIFY or _Picker.mode == PickerMode.DEELECTRIFY then
			self.dragX, self.dragY = self.hoverX, self.hoverY
		elseif _Picker.mode == PickerMode.RAILS then
			self.railTool:handleLeftClick()
		end
	else
		if _Picker.mode == PickerMode.PROPERTIES then
			self:unselectAllTiles()
		end
	end
end

---Handles the left click release action.
---@private
function Station:handleLeftUnclick()
	if _Picker.mode == PickerMode.PROPERTIES then
		if self.dragX and self.dragY then
			if self.hoverX and self.hoverY and not self:rectSelectIsSingleTile() then
				local x1, y1 = assert(math.min(self.dragX, self.hoverX)), assert(math.min(self.dragY, self.hoverY))
				local x2, y2 = assert(math.max(self.dragX, self.hoverX)), assert(math.max(self.dragY, self.hoverY))
				if _Utils.isCtrlPressed() then
					self:unselectRectTiles(x1, y1, x2 - x1 + 1, y2 - y1 + 1)
				else
					self:selectRectTiles(x1, y1, x2 - x1 + 1, y2 - y1 + 1)
				end
			end
			self.dragX, self.dragY = nil, nil
		end
	elseif _Picker.mode == PickerMode.ELECTRIFY or _Picker.mode == PickerMode.DEELECTRIFY then
		if self.dragX and self.dragY then
			if self.hoverX and self.hoverY then
				for x = math.min(self.dragX, self.hoverX), math.max(self.dragX, self.hoverX) do
					for y = math.min(self.dragY, self.hoverY), math.max(self.dragY, self.hoverY) do
						local tile = self:getTile(x, y)
						tile.electrified = _Picker.mode == PickerMode.ELECTRIFY
					end
				end
				self:markUnsaved()
			end
			self.dragX, self.dragY = nil, nil
		end
	elseif _Picker.mode == PickerMode.RAILS then
		self.railTool:handleLeftUnclick()
	end
end

---Handles the right click action.
---@private
function Station:handleRightClick()
	-- Right click: remove a tile, flip selection or switch a switch
	if self.hoverX and self.hoverY then
		if _Picker.mode == PickerMode.TILE then
			local tile = self:assertGetHoveredTile()
			if tile.id == "" then
				_Picker:flipSelection()
			else
				self:setTile(self.hoverX, self.hoverY)
				self:markUnsaved()
			end
		elseif _Picker.mode == PickerMode.PROPERTIES then
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
				local allowTrain = tile.semaphoreAllowTrain or tile.semaphoreAllowSz
				local allowShunt = tile.semaphoreAllowShunt
				if allowTrain or allowShunt then
					if tile:isTrackReserved() then
						tile:sendSemaphoreUnreserve()
					elseif tile:isSemaphoreStop() == false then
						tile:sendSemaphoreStop()
					else
						self.activeX, self.activeY = self.hoverX, self.hoverY
						-- If only one mode is available, select it. Otherwise, Shift will force shunting mode.
						self.activeMode = PathMode.TRAIN
						if not allowTrain or (allowShunt and _Utils.isShiftPressed()) then
							self.activeMode = PathMode.SHUNT
						end
						self.activeW24 = not tile.semaphoreNoW24
					end
				end
			elseif tile:isBlockadeGenerator() then
				local blockadeState = tile:getBlockadeState()
				if blockadeState then
					if _Utils.isShiftPressed() then
						tile:sendBlockadeDirection(blockadeState.direction == nil or nil)
					else
						tile:sendBlockadeDirection(blockadeState.direction == false)
					end
				end
			elseif self.activeX and self.activeY then
				if tile:isTargetForMode(self.activeMode) then
					local track1 = self:assertGetActiveTile():getSemaphorePrevTrackID()
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
		elseif _Picker.mode == PickerMode.RAILS then
			self.railTool:handleRightClick()
		end
	else
		if _Picker.mode == PickerMode.PROPERTIES then
			self.activeX, self.activeY = nil, nil
		end
	end
end

---Handles the right click release action.
---@private
function Station:handleRightUnclick()
	if _Picker.mode == PickerMode.RAILS then
		self.railTool:handleRightUnclick()
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
			self:markUnsaved()
		elseif key == "right" then
			self:moveTiles(self.selectedTiles, 1, 0)
			self:markUnsaved()
		elseif key == "up" then
			self:moveTiles(self.selectedTiles, 0, -1)
			self:markUnsaved()
		elseif key == "down" then
			self:moveTiles(self.selectedTiles, 0, 1)
			self:markUnsaved()
		elseif key == "p" then
			self:slowPathfindTest()
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
		elseif key == "kp+" then
			self:zoom(1)
		elseif key == "kp-" then
			self:zoom(-1)
		elseif key == "delete" then
			self:clearSelectedTiles()
			self:markUnsaved()
		elseif key == "p" then
			self:pathfindTest()
		end
	end
	if key == "tab" then
		self.tileTooltipsEnabled = true
	end
end

---Executed when a key is released.
---@param key string The key code.
function Station:keyreleased(key)
	if key == "tab" then
		self.tileTooltipsEnabled = false
	end
end

---Executed when a mouse button is pressed.
---@param x integer The X coordinate of mouse position.
---@param y integer The Y coordinate of mouse position.
---@param button integer The mouse button.
function Station:mousepressed(x, y, button)
	if _UI:isMouseInUI() or _Picker:isMouseInUI() then
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
	elseif button == 2 then
		self:handleRightUnclick()
	end
end

---Executed when the mouse wheel is scrolled.
---@param x integer The X movement.
---@param y integer The Y movement.
function Station:wheelmoved(x, y)
	if _Utils.isCtrlPressed() then
		self:zoom(y)
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
	self:resetTileFrameColors()
	self:drawFrameHover()
	self:drawFrameSelection()
	self:drawFrameActive()
	self:drawFrameClickable()
	self.railTool:setTileFrameColors()
	love.graphics.setCanvas(self.canvas)
	self:drawBackground()
	self:drawTileBackgrounds()
	self:drawTiles()
	self:drawTileFrameBackgrounds()
	self:drawTileFrames()
	self:drawRectSelection()
	self:drawSizeToolHover()
	self.railTool:drawHover()
	self:drawTileGhost()
	self:drawTileHighlights()
	self:drawTilePathTest()
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.canvas, self.x, self.y, 0, _Settings.scale)
	self:updateTileTooltips()
	self:drawTileTabTooltips()
end

---Draws the Station's background.
function Station:drawBackground()
	love.graphics.setColor(0, 1, 1)
	if not self.synced then
		love.graphics.setColor(1, 1, 0)
	end
	love.graphics.rectangle("fill", 0, 0, self.canvas:getWidth(), self.canvas:getHeight())
end

---Draws the Station's tile backgrounds.
---@private
function Station:drawTileBackgrounds()
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			self:drawTileBackground(tile)
		end
	end
end

---Draws the Station's tile frames.
---@private
function Station:drawTileFrames()
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			self:drawTileFrame(tile)
		end
	end
end

---Draws the Station's tile frame backgrounds.
---@private
function Station:drawTileFrameBackgrounds()
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			self:drawTileFrameBackground(tile)
		end
	end
end

---Draws the Station's tracks.
---@private
function Station:drawTiles()
	for i, column in ipairs(self.tiles) do
		for j, tile in ipairs(column) do
			self:drawTile(tile)
		end
	end
end

---Draws the picker's tile ghost.
---@private
function Station:drawTileGhost()
	if _Picker.mode ~= PickerMode.TILE or not self.hoverX or not self.hoverY then
		return
	end
	local x, y = self:coordsToCanvasPos(self.hoverX, self.hoverY)
	local category = _Picker:getSelectedCategory()
	local image = category.display and category.display.image or "s1"
	_Draw.drawTile(x, y, _Picker:getSelectedTileID(), _Picker.electrified, false, false, false, 0, image, true, 1, 0.5)
end

---Draws hover helpers when adding/removing rows.
---@private
function Station:drawSizeToolHover()
	if not self.hoverX or not self.hoverY then
		return
	end
	if _Picker.mode == PickerMode.ADD_COLUMN then
		local x1, y1 = self:coordsToCanvasPos(self.hoverLineX, 1)
		local x2, y2 = self:coordsToCanvasPos(self.hoverLineX, self.h + 1)
		love.graphics.setColor(0, 1, 0)
		love.graphics.setLineWidth(2)
		love.graphics.line(x1, y1, x2, y2)
	elseif _Picker.mode == PickerMode.ADD_ROW then
		local x1, y1 = self:coordsToCanvasPos(1, self.hoverLineY)
		local x2, y2 = self:coordsToCanvasPos(self.w + 1, self.hoverLineY)
		love.graphics.setColor(0, 1, 0)
		love.graphics.setLineWidth(2)
		love.graphics.line(x1, y1, x2, y2)
	elseif _Picker.mode == PickerMode.DEL_COLUMN then
		local x, y = self:coordsToCanvasPos(self.hoverX, 1)
		local w, h = self.TILE_SIZE, self.TILE_SIZE * self.h
		love.graphics.setColor(1, 0, 0, 0.5)
		love.graphics.rectangle("fill", x, y, w, h)
		love.graphics.setColor(1, 0, 0)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", x, y, w, h)
	elseif _Picker.mode == PickerMode.DEL_ROW then
		local x, y = self:coordsToCanvasPos(1, self.hoverY)
		local w, h = self.TILE_SIZE * self.w, self.TILE_SIZE
		love.graphics.setColor(1, 0, 0, 0.5)
		love.graphics.rectangle("fill", x, y, w, h)
		love.graphics.setColor(1, 0, 0)
		love.graphics.setLineWidth(2)
		love.graphics.rectangle("line", x, y, w, h)
	end
end

---Draws the rectangular selection frame.
---@private
function Station:drawRectSelection()
	if not self.dragX or not self.dragY or not self.hoverX or not self.hoverY then
		return
	end
	local x1, y1 = assert(math.min(self.dragX, self.hoverX)), assert(math.min(self.dragY, self.hoverY))
	local x2, y2 = assert(math.max(self.dragX, self.hoverX)) + 1, assert(math.max(self.dragY, self.hoverY)) + 1
	x1, y1 = self:coordsToCanvasPos(x1, y1)
	x2, y2 = self:coordsToCanvasPos(x2, y2)
	love.graphics.setColor(0, 1, 0)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x1, y1, x2 - x1, y2 - y1)
end

---Draws the currently active tile highlights.
---@private
function Station:drawTileHighlights()
	for i, highlight in ipairs(self.tileHighlights) do
		local x, y = self:coordsToCanvasPos(highlight.x, highlight.y)
		love.graphics.setColor(1, 1, 1, _Utils.mapc(1, 0, 0, 0.4, highlight.t))
		love.graphics.rectangle("fill", x, y, self.TILE_SIZE, self.TILE_SIZE)
	end
end

---Draws the test path, if it exists.
---@private
function Station:drawTilePathTest()
	if not self.pathTest then
		return
	end
	love.graphics.setColor(1, 0, 0)
	love.graphics.setLineWidth(2)
	for i, node in ipairs(self.pathTest) do
		if node.tile.schematic == self then
			local x, y = self:coordsToCanvasPos(node.tile.x + 0.5, node.tile.y + 0.5)
			if node.dir1 then
				local x1, y1 = self:coordsToCanvasPos(node.tile.x + 0.5 + _Dir.DIRS[node.dir1].x * 0.5, node.tile.y + 0.5 + _Dir.DIRS[node.dir1].y * 0.5)
				love.graphics.line(x1, y1, x, y)
			end
			if node.dir2 then
				local x2, y2 = self:coordsToCanvasPos(node.tile.x + 0.5 + _Dir.DIRS[node.dir2].x * 0.5, node.tile.y + 0.5 + _Dir.DIRS[node.dir2].y * 0.5)
				love.graphics.line(x, y, x2, y2)
			end
		end
	end
end

---Updates the list of tooltips to be displayed. Also shows and hides them depending on `self.tileTooltipsEnabled`.
function Station:updateTileTooltips()
	_Utils.emptyTable(self.tileTooltips)
	if not self.tileTooltipsEnabled then
		return
	end
	for x = 1, self.w do
		for y = 1, self.h do
			local tile = self:assertGetTile(x, y)
			if tile:isSemaphore() and tile.semaphoreID then
				local tooltip = Tooltip()
				local id = _Utils.strSplit(tile.semaphoreID, "_")
				tooltip:setPos(self:coordsToPos(x + 0.5, y + 0.5))
				tooltip:setAnchor(0.5, 0.5)
				tooltip:setMargin(2, 1)
				tooltip:setText(id[#id])
				self.tileTooltips[tile] = tooltip
			end
		end
	end
end

---Draws tile tooltip when the Tab key is held down.
---@private
function Station:drawTileTabTooltips()
	for tile, tooltip in pairs(self.tileTooltips) do
		tooltip:draw()
	end
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
---@return TileColorEntry
function Station:getTileBackgroundColor(tile)
	if _Picker.highlightMode == TileHighlightMode.OFF then
		return (tile.x + tile.y) % 2 == 0 and TileBackgroundColor.REGULAR or TileBackgroundColor.REGULAR_ODD
	end
	local trackWarning = tile.trackID and (not tile:isTrack() and not tile:isBlockadeGenerator() and not tile:isExitPoint())
	local switchWarning = tile.switchID and not tile:isSwitch()
	local semaphoreWarning = tile.semaphoreID and (not tile:isSemaphore() and not tile:isExitPoint())
	if trackWarning or switchWarning or semaphoreWarning then
		return TileBackgroundColor.WARNING
	end
	if _Picker.highlightMode == TileHighlightMode.TRACK then
		if tile.trackID then
			return TileBackgroundColor.OK
		elseif tile:isTrack() then
			return TileBackgroundColor.MISSING
		end
	elseif _Picker.highlightMode == TileHighlightMode.SWITCH then
		if tile.switchID then
			return TileBackgroundColor.OK
		elseif tile:isSwitch() then
			return TileBackgroundColor.MISSING
		end
	elseif _Picker.highlightMode == TileHighlightMode.SEMAPHORE then
		if tile.semaphoreID then
			return TileBackgroundColor.OK
		elseif tile:isSemaphore() then
			return TileBackgroundColor.MISSING
		end
	end
	return (tile.x + tile.y) % 2 == 0 and TileBackgroundColor.REGULAR or TileBackgroundColor.REGULAR_ODD
end

---Sets the frame color for the specified tile.
---@param tile Tile The tile for which to change the frame color.
---@param color TileColorEntry The frame color to be applied.
function Station:setTileFrameColor(tile, color)
	self.tileFrameColors[tile] = color
end

---Returns the frame color for the specified tile, or `nil` if the tile has no frame.
---@param tile Tile The tile for which to change the frame color.
---@return TileColorEntry?
function Station:getTileFrameColor(tile)
	return self.tileFrameColors[tile]
end

---Resets the tile frame colors.
function Station:resetTileFrameColors()
	_Utils.emptyTable(self.tileFrameColors)
end

---Sets the frame color for all selected tiles.
---@private
function Station:drawFrameSelection()
	for i, tile in ipairs(self.selectedTiles:getItems()) do
		self:setTileFrameColor(tile, TileFrameColor.SELECTION)
	end
end

---Sets the frame color for the currently active tile.
---@private
function Station:drawFrameActive()
	if not self.activeX or not self.activeY then
		return
	end
	local color = self.activeMode == PathMode.SHUNT and TileFrameColor.ACTIVE_SHUNT or TileFrameColor.ACTIVE
	self:setTileFrameColor(self:assertGetActiveTile(), color)
end

---Sets the frame color for the clickable tiles.
---@private
function Station:drawFrameClickable()
	if self.activeX and self.activeY then
		for i, column in ipairs(self.tiles) do
			for j, tile in ipairs(column) do
				if tile:isTargetForMode(self.activeMode) then
					self:setTileFrameColor(tile, TileFrameColor.CLICKABLE)
				end
			end
		end
	else
		if _Picker.mode == PickerMode.PROPERTIES then
			for i, column in ipairs(self.tiles) do
				for j, tile in ipairs(column) do
					if tile:isSemaphore() then
						--self:setTileFrameColor(tile, TileFrameColor.CLICKABLE)
					end
				end
			end
		end
	end
end

---Sets the frame color for the currently hovered tile.
---@private
function Station:drawFrameHover()
	local hoveredTile = self:getHoveredTile()
	if hoveredTile and (_Picker.mode == PickerMode.TILE or _Picker.mode == PickerMode.PROPERTIES or _Picker.mode == PickerMode.ELECTRIFY or _Picker.mode == PickerMode.DEELECTRIFY) then
		self:setTileFrameColor(hoveredTile, TileFrameColor.HOVER)
	end
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
	local blkState = tile:getBlockadeState()
	_Draw.drawTile(x + tile.offset, y + tile.offset, tile.id, tile.electrified, occupied, reserved, forced, switchDimBits, semState, blkState)
end

---Draws the specified Tile's background.
---@param tile Tile The tile to be drawn.
function Station:drawTileBackground(tile)
	local x, y = self:getTilePos(tile)
	local color = self:getTileBackgroundColor(tile)
	if color.fill then
		love.graphics.setColor(color.fill)
		love.graphics.rectangle("fill", x, y, tile.size, tile.size)
	end
	if color.border then
		love.graphics.setColor(color.border)
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", x + 0.5, y + 0.5, tile.size - 1, tile.size - 1)
	end
	if not color.fill and not color.border then
		_Draw.drawTileBackground(x, y)
	end
end

---Draws the specified Tile's frame.
---@param tile Tile The tile to be drawn.
function Station:drawTileFrame(tile)
	local x, y = self:getTilePos(tile)
	local color = self:getTileFrameColor(tile)
	if color and color.border then
		love.graphics.setColor(color.border)
		love.graphics.setLineWidth(1)
		love.graphics.rectangle("line", x + 0.5, y + 0.5, tile.size - 1, tile.size - 1)
	end
end

---Draws the specified Tile's frame background.
---@param tile Tile The tile to be drawn.
function Station:drawTileFrameBackground(tile)
	local x, y = self:getTilePos(tile)
	local color = self:getTileFrameColor(tile)
	if color and color.fill then
		love.graphics.setColor(color.fill)
		love.graphics.rectangle("fill", x, y, tile.size, tile.size)
	end
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
