local Class = require("lua.core.class")

---@class TileList : Class
---@overload fun(): TileList
local TileList = Class:derive("TileList")

---Creates a new Tile List.
function TileList:new()
    ---@type Tile[]
    self.items = {}
end

---Returns the `n`-th item, if it exists.
---@param n integer The item index.
---@return Tile?
function TileList:get(n)
    return self.items[n]
end

---Returns the items contained in this list.
---@return Tile[]
function TileList:getItems()
    return self.items
end

---Adds an item to the list.
---@param item Tile The item to be added to this list.
---@param n integer? Optional, if provided, the added tile will be `n`-th on the list.
function TileList:insert(item, n)
    table.insert(self.items, n or #self.items + 1, item)
end

---Removes an item from the list and returns it.
---@param n integer? The item to be removed from the list. If not specified, the last item will be removed.
---@return Tile?
function TileList:remove(n)
    return table.remove(self.items, n)
end

---Removes the first occurrence of the specified item from the list and returns it.
---@param item Tile The item to be removed.
---@return Tile?
function TileList:removeFirst(item)
    return _Utils.iTableRemoveFirstValue(self.items, item)
end

---Empties the entire list.
function TileList:empty()
    _Utils.emptyTable(self.items)
end

---Returns whether this list is empty.
---@return boolean
function TileList:isEmpty()
    return #self.items == 0
end

---Returns the amount of items in the list.
---@return integer
function TileList:size()
    return #self.items
end

---Returns whether this list contains the specified item.
---@param item Tile The item to be found.
---@return boolean
function TileList:contains(item)
    return _Utils.isValueInTable(self.items, item)
end

---Executes a function for each item in the list.
---@param f fun(item: Tile) The function to be executed.
function TileList:forEachItem(f)
    for i, item in ipairs(self.items) do
        f(item)
    end
end

---Returns a copy of this list.
---@return TileList
function TileList:copy()
    local newList = TileList()
    newList.items = _Utils.copyTable(self.items)
    return newList
end

---Sorts the items in this list using a comparison function.
---@param f fun(a: Tile, b: Tile): boolean The comparison function.
function TileList:sort(f)
    table.sort(self.items, f)
end



-- Tile-specific functions (everything above is designed to be abstracted out)

---Returns `true` if this list has at least one track tile.
---@return boolean
function TileList:hasTrackTile()
	for i, tile in ipairs(self.items) do
		if tile:isTrack() then
			return true
		end
	end
	return false
end

---Returns `true` if this list has at least one switch tile.
---@return boolean
function TileList:hasSwitchTile()
	for i, tile in ipairs(self.items) do
		if tile:isSwitch() then
			return true
		end
	end
	return false
end

---Returns `true` if this list has at least one semaphore tile.
---@return boolean
function TileList:hasSemaphoreTile()
	for i, tile in ipairs(self.items) do
		if tile:isSemaphore() then
			return true
		end
	end
	return false
end

---Returns `true` if this list has at least one exit point tile.
---@return boolean
function TileList:hasExitPointTile()
	for i, tile in ipairs(self.items) do
		if tile:isExitPoint() then
			return true
		end
	end
	return false
end

---Returns `true` if this list has at least one blockade generator tile.
---@return boolean
function TileList:hasBlockadeGeneratorTile()
	for i, tile in ipairs(self.items) do
		if tile:isBlockadeGenerator() then
			return true
		end
	end
	return false
end

return TileList