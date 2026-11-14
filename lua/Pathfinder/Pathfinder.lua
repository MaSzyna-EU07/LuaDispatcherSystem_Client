local Class = require("class")
local TraversalPossibility = require("lua.Pathfinder.TraversalPossibility")

---@class Pathfinder : Class
---@overload fun(start: Tile, target: Tile): Pathfinder
local Pathfinder = Class:derive("Pathfinder")

---Creates a new Pathfinder.
---@param start Tile The starting tile.
---@param target Tile The tile to target.
function Pathfinder:new(start, target)
    self.start = start
    self.target = target
    self.speed = 160
    self.mode = PathMode.TRAIN
    self.electrified = false

    -- v1

    ---@type TraversalPossibility[]
    self.possibilities = {} -- List of traversal possibilities
    ---@type Itinerary[]
    self.itineraries = {} -- The list of itineraries corresponding to the winning path.

    self.possibilitySortFn = function(a, b) return a.cost < b.cost end

    -- v2

    -- TODO: Move this to the initial possibility function
    local dirFrom = assert(self.start:getSemaphoreDirection(), "First tile must be a semaphore")
    -- Total cost is calculated like this: `total = base * speedPenaltyMult + heuristic`
    ---@type table<Tile, {cost: {base: number, speedPenaltyMult: number, heuristic: number, total: number}, explored: boolean, speed: integer, dirFrom: integer}>
    self.tiles = {
        [self.start] = {cost = {base = 0, speedPenaltyMult = 1, heuristic = self:getHeuristic(self.start), total = self:getHeuristic(self.start)}, explored = false, speed = math.huge, dirFrom = _Dir.invertDir(dirFrom)}
    }
end

---Sets the dispatching mode for this Pathfinder. This affects the possible paths and the displayed signal.
---@param mode PathMode The mode to be set.
function Pathfinder:setMode(mode)
    self.mode = mode
end

---Sets whether this Pathfinder is for an electric train. If so, it will not pathfind through non-electrified tiles.
---@param electrified boolean The electrification mode to be set.
function Pathfinder:setElectrified(electrified)
    self.electrified = electrified
end

---Finds the best path considering the constraints.
---Returns the path if it has been found, `nil` otherwise.
---Throws an error after 100,000 iterations, which means there's a very possible infinite loop.
---@return Path?
function Pathfinder:findPath()
    local n = 0
    while true do
        local result = self:findPathStep()
        if result == false then
            _LogWrite("Path not found!", Severity.FAIL, 1)
            return
        elseif result == true then
            _LogWrite("Path found!", Severity.SUCCESS, 1)
            break
        end
        -- Infinite loop check
        n = n + 1
        assert(n < 100000, "Pathfinder took too long!!!")
    end

    -- If we've got here, we've found the path !!
    local path = assert(self:getPath(self.target))
    _LogWrite("Path found:", Severity.SUCCESS, 1)
    for i, node in ipairs(path) do
        _LogWrite(string.format("    %s: pos=%s,%s dirs=%s,%s", i, node.tile.x, node.tile.y, node.dir1, node.dir2), Severity.SUCCESS, 1)
    end
    return path
end

---Returns the already calculated path from the following tile.
---Returns `nil` if the specified tile hasn't been explored and as such found a way to.
---@param tile Tile The tile to be calculated from.
---@return Path?
function Pathfinder:getPath(tile)
    if not self.tiles[tile] then
        return
    end
    -- Work our way backwards.
    ---@type Path
    local path = {}
    local curTile = tile
    while true do
        table.insert(path, 1, {tile = curTile, dir1 = self.tiles[curTile].dirFrom, dir2 = path[1] and _Dir.invertDir(path[1].dir1)})
        if curTile == self.start then
            break
        end
        curTile = assert(curTile:getNeighbor(self.tiles[curTile].dirFrom))
    end
    return path
end

---Does a single step of the pathfinding procedure.
---Returns `true` if we've found the target tile, `false` if there are no tiles left to explore, and `nil` if the pathfinder should keep going.
---@return boolean?
function Pathfinder:findPathStep()
    -- Find the unexplored tile with the lowest cost and explore it.
    -- TODO: Separate the queue?
    local tile = self:getNextUnexploredTile()
    if not tile then
        return false
    end
    self:exploreTile(tile)
    if tile == self.target then
        return true
    end
end

---Explores the possibilities for the specified tile and registers new tiles if anything new is found.
---If this tile is not in the tile list or is marked as already explored, returns without doing anything.
---@param tile Tile The tile to be explored.
function Pathfinder:exploreTile(tile)
    --print("---- Exploring: " .. tile:getLocation())
    local entry = self.tiles[tile]
    if not entry then
        --print("No entry found!")
        return
    end
    -- Get all directions we can go towards
    local directions = tile:getPossibleTrackDirections(entry.dirFrom)
    --print("Directions: " .. table.concat(directions, ", "))
    for i, direction in ipairs(directions) do
        local nextTile = tile:getNeighbor(direction)
        if nextTile and self:canEnterTile(nextTile) then
            -- For each neighbor tile that exists, make a new entry to fill stuff into.
            local nextEntry = {
                cost = {base = entry.cost.base, speedPenaltyMult = entry.cost.speedPenaltyMult, heuristic = self:getHeuristic(nextTile), total = nil},
                explored = false,
                speed = entry.speed,
                dirFrom = _Dir.invertDir(direction)
            }
            -- Add a base cost.
            if nextTile:isDoubleSwitch() then
                nextEntry.cost.base = nextEntry.cost.base + 4
            elseif nextTile:isSwitch() then
                nextEntry.cost.base = nextEntry.cost.base + 4
            else
                nextEntry.cost.base = nextEntry.cost.base + 1
            end
            -- Check the maximum speed for the PREVIOUS tile, as we don't know where we'll go from the tile we are stepping on.
            local speed = tile:getSpeedForDirections(entry.dirFrom, direction)
            -- Check if that's a reduction from the currently known maximum speed. If so, incur a penalty.
            if speed < entry.speed then
                _LogWrite(string.format("Tile %s reduces speed from %s to %s", tile:getLocation(), entry.speed, speed))
                nextEntry.cost.speedPenaltyMult = entry.speed and math.max(self.speed / entry.speed, 1) or 1
                nextEntry.speed = speed
            end
            -- Also check if we will reset the maximum speed on this tile, if it's a new semaphore tile.
            if nextTile:isSemaphore() and nextTile:getSemaphoreDirection() == direction and (self.mode == PathMode.SHUNT or nextTile.semaphoreType ~= SemaphoreType.TM) then
                nextEntry.speed = math.huge
            end
            -- Calculate the total cost.
            nextEntry.cost.total = nextEntry.cost.base * nextEntry.cost.speedPenaltyMult + nextEntry.cost.heuristic
            -- Check if we've already been on that tile.
            -- In such case, only consider the less costly option. In other words, if we've just discovered a less optimal option, discard it.
            if not self.tiles[nextTile] or nextEntry.cost.total < self.tiles[nextTile].cost.total then
                self.tiles[nextTile] = nextEntry
            end
        end
    end
    -- This entry has been explored. That's it.
    entry.explored = true
end

---Returns the heuristic cost for the specified tile for this pathfinder.
---@private
---@param tile Tile The tile for which to calculate the heuristic.
---@return number
function Pathfinder:getHeuristic(tile)
    local dx, dy = math.abs(self.target.x - tile.x), math.abs(self.target.y - tile.y)
    return (dx + dy) * 2
end

---Returns the next unexplored tile with the lowest cost.
---If there are no tiles to explore left, returns `nil`.
---@private
---@return Tile?
function Pathfinder:getNextUnexploredTile()
    local lowest = nil
    for tile, entry in pairs(self.tiles) do
        if not entry.explored and (not lowest or entry.cost.total < self.tiles[lowest].cost.total) then
            lowest = tile
        end
    end
    return lowest
end

---Returns whether this Pathfinder can enter the specified tile.
---@private
---@param tile Tile The tile to be entered.
---@param prevTile Tile? The previous tile that this tile is entered from.
---@return boolean
function Pathfinder:canEnterTile(tile, prevTile)
    if tile:isEmpty() then
        -- We've reached a desert.
        _LogWrite(string.format("At %s: Empty tile!", tile:getLocation()))
        return false
    end
    if self.mode == PathMode.TRAIN and tile:isTrackClear() == false then
        -- The track is for sure occupied when in train mode.
        _LogWrite(string.format("At %s: Track occupied!", tile:getLocation()))
        return false
    elseif self.mode == PathMode.SHUNT and tile:isTrackClear() and prevTile and prevTile:isTrackClear() == false then
        -- We went past the occupied segment when shunting. Unfortunately current technology doesn't permit us to jump over a train...
        _LogWrite(string.format("At %s: Went past a train in shunting mode!", tile:getLocation()))
        return false
    end
    if not tile:isPathModeAllowed(self.mode) then
        -- The track is not allowing this dispatching mode (i.e. forbids shunting or trains)
        _LogWrite(string.format("At %s: Mode forbidden!", tile:getLocation()))
        return false
    end
    if self.electrified and not tile.electrified then
        -- The track is not electrified while pathfinding for an electric train.
        _LogWrite(string.format("At %s: Not electrified!", tile:getLocation()))
        return false
    end
    return true
end

---Calculates the path based on the provided start and end point of this Pathfinder. If a path is found, generates itineraries for it.
---Returns `true` if the path has been found, `false` otherwise.
---@return boolean
function Pathfinder:calculatePath()
    self:createInitialPossibility()
    ---@type TraversalPossibility?
    local winner = nil
    while #self.possibilities > 0 do
        -- Get the possibility which has the lowest cost.
        table.sort(self.possibilities, self.possibilitySortFn)
        ---@type TraversalPossibility
        local possibility = table.remove(self.possibilities, 1)
        if possibility:isWinning() then
            -- We won!
            possibility:finalize()
            possibility:notifyLastSemaphore()
            winner = possibility
            break
        end
        local newPossibilities = possibility:evaluate()
        _Utils.tableAddInplace(self.possibilities, newPossibilities)
    end

    if not winner then
        _LogWrite("Path not found!", Severity.FAIL, 1)
        return false
    end

    _LogWrite("Path found:", Severity.SUCCESS, 1)
    for i, node in ipairs(winner.path) do
        _LogWrite(string.format("    %s: pos=%s,%s dirs=%s,%s", i, node.tile.x, node.tile.y, node.dir1, node.dir2), Severity.SUCCESS, 1)
    end
    self.itineraries = winner:generateItineraries()
    return true
end

---Creates the initial possibility starting from this Pathfinder's first tile.
---@private
function Pathfinder:createInitialPossibility()
    local direction = self.start:getSemaphoreDirection()
    if not direction then
        -- The first tile is not a semaphore. This is currently a requirement.
        return
    end
    table.insert(self.possibilities, TraversalPossibility(self, self.start, direction))
end

return Pathfinder