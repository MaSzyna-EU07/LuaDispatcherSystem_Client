local Class = require("class")
local TraversalPossibility = require("TraversalPossibility")

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
        if possibility:isWinning() then
            possibility:finalize()
            possibility:notifyLastSemaphore()
            winner = possibility
            break
        end
        local newPossibilities = possibility:evaluate()
        _Utils.tableAddInplace(self.possibilities, newPossibilities)
    end

    if not winner then
        _Notifications:post("Pathfinding failed! :(", NotificationColor.RED)
        return
    end

    print("Path found:")
    for i, node in ipairs(winner.path) do
        print(string.format("    %s: pos=%s,%s dirs=%s,%s", i, node.tile.x, node.tile.y, node.dir1, node.dir2))
    end
    _Utils.tableAddInplace(self.itineraries, winner:generateItineraries())
end

---Creates the initial possibilities starting from this Pathfinder's first tile.
---@private
function Pathfinder:createInitialPossibilities()
    -- See which directions we can go towards.
    local directions = self.start:getTrackDirections()
    -- Each direction is a single possibility.
    for i, direction in ipairs(directions) do
        table.insert(self.possibilities, TraversalPossibility(self, self.start, direction))
    end
end

---Reserves all tracks, sets all switches and displays a clear signal on the semaphore.
function Pathfinder:dispatch()
    for i, itinerary in ipairs(self.itineraries) do
        itinerary:dispatch()
    end
end

return Pathfinder