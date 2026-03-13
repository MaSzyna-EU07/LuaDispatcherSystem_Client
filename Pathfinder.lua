local Class = require("class")
local Itinerary = require("Itinerary")

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

    ---@alias TraversalPossibility {tile: Tile, direction: integer, prevDirection: integer?, path: {tile: Tile, dir1: integer?, dir2: integer?}[], speed: number, cost: number, lastSemaphore: Tile?, segments: {start: integer, speed: number}[]}
    ---@type TraversalPossibility[]
    self.possibilities = {} -- List of traversal possibilities
    ---@type Itinerary[]
    self.itineraries = {} -- The list of itineraries corresponding to the winning path.

    self.possibilitySortFn = function(a, b) return a.cost < b.cost end
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

---Calculates the path based on the provided start and end point of this Pathfinder.
---Currently this is hacked together and the list of tiles is hardcoded. Yay!
function Pathfinder:calculatePath()
    self:createInitialPossibilities()
    local winner = nil
    while #self.possibilities > 0 do
        -- Get the possibility which has the lowest cost.
        table.sort(self.possibilities, self.possibilitySortFn)
        local possibility = table.remove(self.possibilities, 1)
        if self:isWinningPossibility(possibility) then
            self:finalizePossibility(possibility)
            winner = possibility
            break
        end
        self:evaluatePossibility(possibility)
    end

    if not winner then
        _Notifications:post("Pathfinding failed! :(", NotificationColor.RED)
        return
    end

    print("Path found:")
    for i, node in ipairs(winner.path) do
        print(string.format("    %s: pos=%s,%s dirs=%s,%s", i, node.tile.x, node.tile.y, node.dir1, node.dir2))
    end
    self:generateItineraries(winner)
end

---Creates the initial possibilities starting from this Pathfinder's first tile.
---@private
function Pathfinder:createInitialPossibilities()
    -- See which directions we can go towards.
    local directions = self.start:getTrackDirections()
    -- Each direction is a single possibility.
    for i, direction in ipairs(directions) do
        ---@type TraversalPossibility
        local newPossibility = {tile = self.start, direction = direction, path = {{tile = self.start, dir2 = direction}}, speed = math.huge, cost = 0, lastSemaphore = self.start, segments = {{start = 1, speed = math.huge}}}
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
        -- Check if we can go there in the first place.
        local nextTile = tile:getNeighbor(direction)
        -- The track must be clear (unless we are in shunting mode), must not prohibit our path mode and must be electrified if we are pathfinding for an electric vehicle.
        if (nextTile:isTrackClear() or not nextTile:getTrackState() or self.mode == PathMode.SHUNT) and nextTile:isPathModeAllowed(self.mode) and not (self.electrified and not nextTile:isElectrified()) then
            -- Copy the paths and add our new tile to it.
            local path = _Utils.copyTable(possibility.path)
            table.insert(path, {tile = tile, dir1 = _InvertDir(possibility.direction), dir2 = direction})
            -- Check the latest semaphore and update the segment splits.
            local lastSemaphore = possibility.lastSemaphore
            local segments = _Utils.copyTable(possibility.segments)
            for j, segment in ipairs(segments) do
                segments[j] = _Utils.copyTable(segment)
            end
            -- A segment splits occurs on a semaphore tile. The semaphore must be faced in our direction. We ignore shunting-only semaphores in train mode.
            if tile:isSemaphore() and tile:getSemaphoreDirection() == direction and (self.mode == PathMode.SHUNT or tile:getSemaphoreType() ~= SemaphoreType.TM) then
                lastSemaphore = tile
                table.insert(segments, {start = #path, speed = math.huge})
            end
            -- Check if we need to lower the speed, globally and for this segment.
            local prevTileSpeed = possibility.tile:getSpeedForDirections(possibility.prevDirection and _InvertDir(possibility.prevDirection), possibility.direction)
            local speed = math.min(possibility.speed, prevTileSpeed)
            segments[#segments].speed = math.min(segments[#segments].speed, prevTileSpeed)
            -- If the segment we're on mandates speeds less than 100 km/h, and the previous semaphore does not allow that, this entire possibility will not pass.
            local valid = true
            local segmentSpeed = _SpeedToID(segments[#segments].speed)
            if #segments >= 2 and segmentSpeed ~= Speed.VMAX and segmentSpeed ~= Speed["100"] and path[segments[#segments - 1].start].tile:getSemaphoreNoDanger() then
                valid = false
            end
            -- Assemble the possiblity and add it to the list.
            if valid then
                local newPossibility = {tile = tile, direction = direction, prevDirection = possibility.direction, path = path, speed = speed, lastSemaphore = lastSemaphore, segments = segments}
                newPossibility.cost = self:calculateCost(newPossibility)
                table.insert(self.possibilities, newPossibility)
            end
        end
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
            cost = cost + 4
        elseif node.tile:isSwitch() then
            cost = cost + 4
        else
            cost = cost + 1
        end
    end
    local speedPenaltyMult = possibility.speed and math.max(self.speed / possibility.speed, 1) or 1
    cost = cost * speedPenaltyMult
    -- Calculate the heuristic (estimate cost to go).
    local tile = possibility.tile:getNeighbor(possibility.direction)
    local dx, dy = math.abs(self.target.x - tile.x), math.abs(self.target.y - tile.y)
    local heuristic = (dx + dy) * 2
    -- Return the total value.
    return cost + heuristic
end

---Returns `true` if the specified traversal possiblity is a winner (points to the target tile with conditions such as W24 being present on the last semaphore).
---@private
---@param possibility TraversalPossibility The traversal possibility to be evaluated.
---@return boolean
function Pathfinder:isWinningPossibility(possibility)
    return possibility.tile:getNeighbor(possibility.direction) == self.target and self.target:isTargetForW24(not possibility.lastSemaphore:getSemaphoreNoW24())
end

---Finalizes a traversal possibility by adding additional tiles to the path until a semaphore or a dead end is found.
---@private
---@param possibility TraversalPossibility The traversal possibility to be finalized.
function Pathfinder:finalizePossibility(possibility)
    local n = 0
    while not possibility.tile:isSemaphore() do
        local tile = possibility.tile:getNeighbor(possibility.direction)
        local directions = tile:getPossibleTrackDirections(_InvertDir(possibility.direction))
        local direction = directions[1]
        table.insert(possibility.path, {tile = tile, dir1 = _InvertDir(possibility.direction), dir2 = direction})
        if not direction then
            -- Dead end.
            break
        end
        possibility.tile = tile
        possibility.prevDirection = possibility.direction
        possibility.direction = direction
        n = n + 1
        assert(n < 10000, "Infinite loop")
    end
    _Notifications:post(string.format("Last semaphore: %s, %s", possibility.lastSemaphore.x, possibility.lastSemaphore.y), NotificationColor.GREEN)
    local segmentText = ""
    for i, segment in ipairs(possibility.segments) do
        segmentText = segmentText .. (i > 1 and ", " or "") .. "[start=" .. segment.start .. ",speed=" .. segment.speed .. "]"
    end
    _Notifications:post("Segments: " .. segmentText)
end

---Generates itineraries based on the specified possibility.
---@private
---@param possibility TraversalPossibility The traversal possibility to be the basis for generated itineraries.
function Pathfinder:generateItineraries(possibility)
    -- Iterate through all segments and generate an itinerary for each one.
    for i, segment in ipairs(possibility.segments) do
        local startIndex = segment.start
        local endIndex = possibility.segments[i + 1] and possibility.segments[i + 1].start or #possibility.path
        -- Prepare a new itinerary for this segment.
        local itinerary = Itinerary()
        for j = startIndex, endIndex do
            local node = possibility.path[j]
            -- Determine which tracks should be reserved. Last tile is exempt.
            if j < endIndex then
                local track = node.tile:getTrackID()
                if track then
                    itinerary:addTrack(track)
                end
            end
            -- Check if we have to consider a switch state on this tile.
            local switchStates = node.tile:getSwitchStatesForDirections(node.dir1, node.dir2)
            for suffix, state in pairs(switchStates) do
                itinerary:addSwitch(node.tile:getSwitchID() .. suffix, state)
            end
            -- First tile determines the semaphore.
            if j == startIndex then
                itinerary:setSemaphore(assert(node.tile:getSemaphoreID(), "Missing semaphore on starting tile!"))
                if self.mode == PathMode.TRAIN then
                    itinerary:setSpeed(node.tile:getSemaphoreAllowTrain() and _SpeedToID(segment.speed) or Speed.SZ)
                elseif self.mode == PathMode.SHUNT then
                    itinerary:setSpeed(Speed.MS2)
                end
            end
            -- Last tile determines the next semaphore, if it exists, and also determines whether W24 will be displayed.
            if j == endIndex then
                itinerary:setNext(node.tile:getSemaphoreID() or 1)
                itinerary:setW24(node.tile:isTargetW24())
            end
        end
        -- Add the itinerary to the list.
        table.insert(self.itineraries, 1, itinerary)
    end
end

---Reserves all tracks, sets all switches and displays a clear signal on the semaphore.
function Pathfinder:dispatch()
    for i, itinerary in ipairs(self.itineraries) do
        itinerary:dispatch()
    end
end

return Pathfinder