local Class = require("class")

---@class Picker : Class
---@overload fun(): Picker
local Picker = Class:derive("Picker")

function Picker:new()
    self.x, self.y = 20, 710
    self.margin = 10
	---@alias TileCategory {tiles: string[], startIndex: integer?, display: {image: string?}, properties: table<string, any>?}
	---@type TileCategory[]
	self.tileCategories = {
		{tiles = {""}},
		{tiles = {"track-", "track\\", "track|", "track/"}},
		{tiles = {"track+", "trackX"}},
		{tiles = {"platformP"}},
		{tiles = {"platformF"}},
		{tiles = {"curve1", "curve2", "curve3", "curve4", "curve5", "curve6", "curve7", "curve8"}, startIndex = 3},
		{tiles = {"switchL1", "switchL2", "switchL3", "switchL4", "switchL5", "switchL6", "switchL7", "switchL8"}, startIndex = 3, properties = {maxSpeedPlus = 40}},
		{tiles = {"switchR1", "switchR2", "switchR3", "switchR4", "switchR5", "switchR6", "switchR7", "switchR8"}, startIndex = 3, properties = {maxSpeedPlus = 40}},
		{tiles = {"switchD1", "switchD2", "switchD3", "switchD4"}, startIndex = 2, properties = {maxSpeedPlus = 40, maxSpeedMinus = 100}},
		{tiles = {"switchW1", "switchW2", "switchW3", "switchW4", "switchW5", "switchW6", "switchW7", "switchW8"}, startIndex = 6, properties = {maxSpeedPlus = 40, maxSpeedMinus = 40}},
		{tiles = {"switchDerL1", "switchDerL2", "switchDerL3", "switchDerL4", "switchDerL5", "switchDerL6", "switchDerL7", "switchDerL8"}, startIndex = 3, properties = {maxSpeedPlus = 40}},
		{tiles = {"switchDerR1", "switchDerR2", "switchDerR3", "switchDerR4", "switchDerR5", "switchDerR6", "switchDerR7", "switchDerR8"}, startIndex = 3, properties = {maxSpeedPlus = 40}},
		{tiles = {"buffer1", "buffer2", "buffer3", "buffer4", "buffer5", "buffer6", "buffer7", "buffer8"}, startIndex = 7},
		{tiles = {"derailer1", "derailer2", "derailer3", "derailer4", "derailer5", "derailer6", "derailer7", "derailer8"}, startIndex = 3},
		{tiles = {"derailerL1", "derailerL2", "derailerL3", "derailerL4", "derailerL5", "derailerL6", "derailerL7", "derailerL8"}, startIndex = 3},
		{tiles = {"curveDerL1", "curveDerL2", "curveDerL3", "curveDerL4", "curveDerL5", "curveDerL6", "curveDerL7", "curveDerL8"}, startIndex = 3},
		{tiles = {"curveDerR1", "curveDerR2", "curveDerR3", "curveDerR4", "curveDerR5", "curveDerR6", "curveDerR7", "curveDerR8"}, startIndex = 3},
		{tiles = {"semaphore1", "semaphore2", "semaphore3", "semaphore4", "semaphore5", "semaphore6", "semaphore7", "semaphore8"}, startIndex = 3, display = {image = "s1"}, properties = {semaphoreType = SemaphoreType.SEM}},
		{tiles = {"semaphore1", "semaphore2", "semaphore3", "semaphore4", "semaphore5", "semaphore6", "semaphore7", "semaphore8"}, startIndex = 3, display = {image = "ms1"}, properties = {semaphoreType = SemaphoreType.TM}},
		{tiles = {"blockade1", "blockade2", "blockade3", "blockade4", "blockade5", "blockade6", "blockade7", "blockade8"}, startIndex = 3},
		{tiles = {"arrow3", "arrow7", "arrow-"}, startIndex = 3},
		{tiles = {"loco"}},
		{tiles = {"square"}},
		{tiles = {"letterA", "letterĄ", "letterB", "letterC", "letterĆ", "letterD", "letterE", "letterĘ", "letterF", "letterG", "letterH", "letterI", "letterJ", "letterK", "letterL", "letterŁ", "letterM", "letterN", "letterŃ", "letterO", "letterÓ", "letterP", "letterQ", "letterR", "letterS", "letterŚ", "letterT", "letterU", "letterV", "letterW", "letterX", "letterY", "letterZ", "letterŹ", "letterŻ"}}
	}
    self.tileScale = 2
    self.tileMargin = 2

    self.tileSize = self.tileScale * 14 + self.tileMargin * 2
    self.boxX, self.boxY = self.x - self.margin, self.y - self.margin
    self.boxW, self.boxH = #self.tileCategories * self.tileSize + self.margin * 2, self.tileSize + self.margin * 2
	self.tmpFlip = {
		["switchL1"] = "switchR1", ["switchR1"] = "switchL1",
		["switchL2"] = "switchR2", ["switchR2"] = "switchL2",
		["switchL3"] = "switchR3", ["switchR3"] = "switchL3",
		["switchL4"] = "switchR4", ["switchR4"] = "switchL4",
		["switchL5"] = "switchR5", ["switchR5"] = "switchL5",
		["switchL6"] = "switchR6", ["switchR6"] = "switchL6",
		["switchL7"] = "switchR7", ["switchR7"] = "switchL7",
		["switchL8"] = "switchR8", ["switchR8"] = "switchL8",
		["switchDerL1"] = "switchDerR1", ["switchDerR1"] = "switchDerL1",
		["switchDerL2"] = "switchDerR2", ["switchDerR2"] = "switchDerL2",
		["switchDerL3"] = "switchDerR3", ["switchDerR3"] = "switchDerL3",
		["switchDerL4"] = "switchDerR4", ["switchDerR4"] = "switchDerL4",
		["switchDerL5"] = "switchDerR5", ["switchDerR5"] = "switchDerL5",
		["switchDerL6"] = "switchDerR6", ["switchDerR6"] = "switchDerL6",
		["switchDerL7"] = "switchDerR7", ["switchDerR7"] = "switchDerL7",
		["switchDerL8"] = "switchDerR8", ["switchDerR8"] = "switchDerL8",
		["derailerL1"] = "derailer1", ["derailer1"] = "derailerL1",
		["derailerL2"] = "derailer2", ["derailer2"] = "derailerL2",
		["derailerL3"] = "derailer3", ["derailer3"] = "derailerL3",
		["derailerL4"] = "derailer4", ["derailer4"] = "derailerL4",
		["derailerL5"] = "derailer5", ["derailer5"] = "derailerL5",
		["derailerL6"] = "derailer6", ["derailer6"] = "derailerL6",
		["derailerL7"] = "derailer7", ["derailer7"] = "derailerL7",
		["derailerL8"] = "derailer8", ["derailer8"] = "derailerL8",
		["curveDerL1"] = "curveDerR4", ["curveDerR4"] = "curveDerL1",
		["curveDerL2"] = "curveDerR5", ["curveDerR5"] = "curveDerL2",
		["curveDerL3"] = "curveDerR6", ["curveDerR6"] = "curveDerL3",
		["curveDerL4"] = "curveDerR7", ["curveDerR7"] = "curveDerL4",
		["curveDerL5"] = "curveDerR8", ["curveDerR8"] = "curveDerL5",
		["curveDerL6"] = "curveDerR1", ["curveDerR1"] = "curveDerL6",
		["curveDerL7"] = "curveDerR2", ["curveDerR2"] = "curveDerL7",
		["curveDerL8"] = "curveDerR3", ["curveDerR3"] = "curveDerL8",
		["arrow3"] = "arrow7", ["arrow7"] = "arrow3"
	}

	self.buttons = {
		{x = 20, y = 665, tileX = 1, action = "addRow"},
		{x = 65, y = 665, tileX = 2, action = "delRow"},
		{x = 110, y = 665, tileX = 3, action = "addColumn"},
		{x = 155, y = 665, tileX = 4, action = "delColumn"},
		{x = 200, y = 665, tileX = 5, action = "properties"},
		--{x = 245, y = 665, tileX = 8, action = "electrify"},
		--{x = 290, y = 665, tileX = 9, action = "deelectrify"}
	}

	-- If `nil`, a tile is selected in the picker. Otherwise, a button is pressed, indicating a mode.
	---@type string?
	self.mode = nil

	self.selectedTileCategory = 1
	self.selectedTileOrientation = 1
	self.modeHover = nil
	self.hoveredTileCategory = nil

    self.electrified = true
	self.highlightMode = TileHighlightMode.TRACK
end

function Picker:getTilePos(i)
	return self.x + (i - 1) * self.tileSize, self.y
end

function Picker:update(dt)
	self.modeHover = nil
	self.hoveredTileCategory = nil
	if _Utils.isPointInsideBox(_MouseX, _MouseY, self.boxX, self.boxY, self.boxW, self.boxH) and not _UI:isMouseInUI() then
		for i = 1, #self.tileCategories do
			local x, y = self:getTilePos(i)
			if _Utils.isPointInsideBox(_MouseX, _MouseY, x, y, self.tileSize, self.tileSize) then
				self.hoveredTileCategory = i
				break
			end
		end
	end
	for i, button in ipairs(self.buttons) do
		if _Utils.isPointInsideBox(_MouseX, _MouseY, button.x, button.y, 40, 28) then
			self.modeHover = button.action
		end
	end
end

---Rotates the currently selected tile by the selected amount.
---@param notches integer Number of rotations.
function Picker:rotateSelection(notches)
	if self.mode then
		return
	end
	local orientationCount = #self.tileCategories[self.selectedTileCategory].tiles
	self.selectedTileOrientation = (self.selectedTileOrientation + notches - 1) % orientationCount + 1
end

---Flips the currently selected tile.
function Picker:flipSelection()
	if self.mode then
		return
	end
	local newID = self.tmpFlip[self:getSelectedTileID()]
	if not newID then
		-- The tile is not flippable.
		return
	end
	local category, orientation = self:findTileCategory(newID)
	if not category or not orientation then
		-- This should never happen, but abort in case our flip table points to a nonexistent tile ID.
		return
	end
	self.selectedTileCategory, self.selectedTileOrientation = category, orientation
end

---Selects the specified tile category by index.
---@param index integer The category index.
function Picker:selectCategory(index)
	self.mode = nil
	self.selectedTileCategory = index
	self.selectedTileOrientation = self.tileCategories[index].startIndex or 1
	local station = _Project:getCurrentStation()
	if station then
		station:unselectAllTiles()
	end
end

---Returns the currently selected tile category.
---@return TileCategory
function Picker:getSelectedCategory()
	return self.tileCategories[self.selectedTileCategory]
end

---Returns the tile ID which is currently selected in the picker.
---@return string
function Picker:getSelectedTileID()
	return self.tileCategories[self.selectedTileCategory].tiles[self.selectedTileOrientation]
end

---Returns the picker tile category index and orientation for the given tile ID, or `nil` if no category fits the tile ID.
---@param id string The tile ID to be checked.
---@param properties table<string, any>? If specified, a category matching the properties will be found. If no exact match is found, the search falls back to an unparametred one.
---@return integer?, integer?
function Picker:findTileCategory(id, properties)
	for i, category in ipairs(self.tileCategories) do
		for j, tileID in ipairs(category.tiles) do
			if id == tileID and (not properties or _Utils.tableMatch(category.properties, properties)) then
				return i, j
			end
		end
	end
	if properties then
		-- Fall back.
		return self:findTileCategory(id)
	end
end

---Pick blocks the specified tile.
---@param tile Tile The tile to be picked.
function Picker:pickTile(tile)
	local category, orientation = self:findTileCategory(tile.id, tile:isSemaphore() and {semaphoreType = tile.semaphoreType} or nil)
	if not category or not orientation then
		-- This tile is not pick blockable... Wait, is that ever supposed to happen?
		return
	end
	self.mode = nil
	self.selectedTileCategory, self.selectedTileOrientation = category, orientation
	self.electrified = tile.electrified
	_UI.pickerPane.electrified.value = tile.electrified
end

---Augments the provided tile with the selection. Sets the tile ID, electrified, and any special properties.
---@param tile Tile The tile to be augmented.
function Picker:augmentTile(tile)
	tile.id = self:getSelectedTileID()
	tile.electrified = self.electrified
	local properties = self.tileCategories[self.selectedTileCategory].properties
	if properties then
		for k, v in pairs(properties) do
			tile[k] = v
		end
	end
end

function Picker:draw()
	love.graphics.setColor(0, 0, 1)
	love.graphics.rectangle("fill", self.boxX, self.boxY, self.boxW, self.boxH)
	for i = 1, #self.tileCategories do
		local x, y = self:getTilePos(i)
		if self.selectedTileCategory == i and not self.mode then
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)
		elseif self.hoveredTileCategory == i then
			love.graphics.setColor(0, 1, 1)
			love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)
		end
		local category = self.tileCategories[i]
		local categoryTile = category.tiles[category.startIndex or 1]
		if categoryTile == "" then
			local tx, ty = x + self.tileMargin * self.tileScale, y + self.tileMargin * self.tileScale
			local size = self.tileSize - self.tileMargin * self.tileScale * 2
			love.graphics.setColor(0.4, 0.4, 0.4)
			love.graphics.rectangle("fill", tx, ty, size, size)
			love.graphics.setColor(0.2, 0.2, 0.2)
			love.graphics.setLineWidth(2)
			love.graphics.rectangle("line", tx, ty, size, size)
		else
			local image = category.display and category.display.image
			_DrawTile(x + self.tileMargin, y + self.tileMargin, categoryTile, _Picker.electrified, false, false, false, 0, image, self.tileScale)
		end
	end

	for i, button in ipairs(self.buttons) do
		local tileY = self.mode == button.action and 2 or 1
		_Buttons:drawTile(button.tileX, tileY, button.x, button.y, 2)
	end
end

-- The following function is kept here just in case I ever need to check all of the tile possibilities again.
--[[
function Picker:drawDebug()
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.rectangle("fill", 0, 0, 500, 200)
	for i, data in ipairs(_TileDB.tiles) do
		local x, y = (i - 1) % 16, math.floor((i - 1) / 16)
		_DrawTile(x * 28, y * 28 + 28, i, true, false, false, false, 0, nil, 2)
	end
end
]]

function Picker:keypressed(key)
	if _UI:getFocus() then
		return
	end
	if key == "a" then
		--self.mode = "addRow"
	elseif key == "s" then
		--self.mode = "addColumn"
	elseif key == "z" then
		--self.mode = "delRow"
	elseif key == "x" then
		--self.mode = "delColumn"
	end
	if key == "1" then
		self.highlightMode = TileHighlightMode.TRACK
	elseif key == "2" then
		self.highlightMode = TileHighlightMode.SWITCH
	elseif key == "3" then
		self.highlightMode = TileHighlightMode.SEMAPHORE
	end
end

function Picker:mousepressed(x, y, button)
	if button == 1 then
		if self.hoveredTileCategory then
			self:selectCategory(self.hoveredTileCategory)
		elseif self.modeHover then
			self.mode = self.modeHover
		end
	end
end

function Picker:wheelmoved(x, y)
	self:rotateSelection(-y)
end

return Picker