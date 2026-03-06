local Class = require("class")

---@class Pathfinder : Class
---@overload fun(start: Tile, target: Tile): Pathfinder
local Pathfinder = Class:derive("Pathfinder")

---Creates a new Pathfinder.
---@param start Tile The starting tile.
---@param target Tile The tile to target.
function Pathfinder:new(start, target)
    self.start = start
    self.target = target
    self.targetSpeed = 160

    ---@alias TraversalPossibility {tile: Tile, direction: integer, prevDirection: integer?, path: {tile: Tile, dir1: integer?, dir2: integer?}[], speed: number?, cost: number}
    ---@type TraversalPossibility[]
    self.possibilities = {} -- List of traversal possibilities
    ---@type TraversalPossibility
    self.winner = nil -- The possiblity which is the first found path.

    self.possibilitySortFn = function(a, b) return a.cost < b.cost end

    ---@type table<string, true>
    self.tracks = {} -- Set of track IDs to be reserved
    ---@type table<string, boolean>
    self.switches = {} -- Maps switch IDs to their states
end

---Calculates the path based on the provided start and end point of this Pathfinder.
---Currently this is hacked together and the list of tiles is hardcoded. Yay!
function Pathfinder:calculatePath()
    self:createInitialPossibilities()
    while #self.possibilities > 0 do
        -- Get the possibility which has the lowest cost.
        table.sort(self.possibilities, self.possibilitySortFn)
        local possibility = table.remove(self.possibilities, 1)
        if self:isWinningPossibility(possibility) then
            self.winner = possibility
            -- HACK: Manually add the last tile to have a complete path.
            -- TODO: Extend the route to the nearest semaphore.
            table.insert(self.winner.path, {tile = self.target, dir1 = _InvertDir(self.winner.path[#self.winner.path].dir2)})
            break
        end
        self:evaluatePossibility(possibility)
    end

    if not self.winner then
        print("We did not find a path :(")
        return
    end

    print("Path found:")
    for i, node in ipairs(self.winner.path) do
        print(node.tile.x, node.tile.y, node.dir1, node.dir2)
        -- Add a track to the list.
        local track = node.tile:getTrackID()
        if track then
            self.tracks[track] = true
        end
        -- Check if we have to consider a switch state on this tile.
        local switchStates = node.tile:getSwitchStatesForDirections(node.dir1, node.dir2)
        for suffix, state in pairs(switchStates) do
            self.switches[node.tile:getSwitchID() .. suffix] = state
        end
    end
end

---Creates the initial possibilities starting from this Pathfinder's first tile.
---@private
function Pathfinder:createInitialPossibilities()
    -- See which directions we can go towards.
    local directions = self.start:getTrackDirections()
    -- Each direction is a single possibility.
    for i, direction in ipairs(directions) do
        local newPossibility = {tile = self.start, direction = direction, path = {{tile = self.start, dir2 = direction}}, directions = {direction}, cost = 0}
        table.insert(self.possibilities, newPossibility)
    end
end

---Evaluates the specified traveral possibility and adds new possibilities if any are discovered, with updated statistics.
---The specified possibility is NOT removed from the list.
---@private
---@param possibility TraversalPossibility The traversal possibility to be evaluated.
function Pathfinder:evaluatePossibility(possibility)
    -- This is the tile we are stepping on.
    local tile = possibility.tile:getNeighbor(possibility.direction)
    -- See which directions we can go next.
    local directions = tile:getPossibleTrackDirections(_InvertDir(possibility.direction))
    -- Each direction is a single possibility.
    for i, direction in ipairs(directions) do
        -- Copy the paths and add our new tile to it.
        local path = _Utils.copyTable(possibility.path)
        table.insert(path, {tile = tile, dir1 = _InvertDir(possibility.direction), dir2 = direction})
        -- Check if we need to lower the speed.
        local speed = possibility.speed
        local prevTileSpeed = possibility.tile:getSpeedForDirections(possibility.prevDirection and _InvertDir(possibility.prevDirection), possibility.direction)
        if prevTileSpeed then
            speed = speed and math.min(speed, prevTileSpeed) or prevTileSpeed
        end
        -- Assemble the possiblity and add it to the list.
        local newPossibility = {tile = tile, direction = direction, prevDirection = possibility.direction, path = path, speed = speed}
        newPossibility.cost = self:calculateCost(newPossibility)
        table.insert(self.possibilities, newPossibility)
    end
end

---Calculates the cost for the specified traversal possibility.
---@private
---@param possibility TraversalPossibility The traversal possibility to be evaluated.
---@return number
function Pathfinder:calculateCost(possibility)
    -- Calculate the cost (what we went through so far).
    local cost = 0
    for i, node in ipairs(possibility.path) do
        if node.tile:isDoubleSwitch() then
            cost = cost + 8
        elseif node.tile:isSwitch() then
            cost = cost + 4
        else
            cost = cost + 1
        end
    end
    local speedPenaltyMult = possibility.speed and math.max(self.targetSpeed / possibility.speed, 1) or 1
    cost = cost * speedPenaltyMult
    -- Calculate the heuristic (estimate cost to go).
    local tile = possibility.tile:getNeighbor(possibility.direction)
    local dx, dy = math.abs(self.target.x - tile.x), math.abs(self.target.y - tile.y)
    local heuristic = (dx + dy) * 2
    -- Return the total value.
    return cost + heuristic
end

---Returns `true` if the specified traversal possiblity is a winner (points to the target tile).
---@private
---@param possibility TraversalPossibility The traversal possibility to be evaluated.
---@return boolean
function Pathfinder:isWinningPossibility(possibility)
    return possibility.tile:getNeighbor(possibility.direction) == self.target
end

---Reserves all tracks which have been traversed by this Pathfinder, with the exception of the last tile.
---@private
function Pathfinder:reserveTracks()
    for id, _ in pairs(self.tracks) do
        _Com.sendCommand("t " .. id .. " res")
    end
end

---Switches all switches this Pathfinder has found to their desired states.
---@private
function Pathfinder:switchSwitches()
    for id, state in pairs(self.switches) do
		_Com.sendCommand("j " .. id .. " " .. (state and "+" or "-"))
    end
end

---Sets the semaphore at the beginning of this path to display a clear signal.
---@private
function Pathfinder:setSemaphore()
    local nextSpeed = 1
    local lastTile = self.winner.path[#self.winner.path].tile
    print("Last tile", lastTile.semaphoreID, lastTile.trackID)
    if lastTile:isSemaphore() then
        nextSpeed = lastTile:getSemaphoreState().speed
    end
    self.winner.path[1].tile:sendSemaphoreState(_SpeedToID(self.winner.speed), nextSpeed)
end

---Reserves all tracks, sets all switches and displays a clear signal on the semaphore.
function Pathfinder:sendPath()
    self:reserveTracks()
    self:switchSwitches()
    self:setSemaphore()
end

return Pathfinder