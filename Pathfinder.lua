local Class = require("class")

---@class Pathfinder : Class
---@overload fun(): Pathfinder
local Pathfinder = Class:derive("Pathfinder")

function Pathfinder:new()
    --self.station = _Project:getStation("Tp")
    --self.x, self.y = 4, 3
    --self.direction = 3
    --self.mockDirections = {3, 3, 3, 4, 3, 3, 3, 3}

    --self.station = _Project:getStation("Eb")
    --self.x, self.y = 6, 12
    --self.direction = 3
    --self.mockDirections = {3, 2, 3, 3, 3, 4, 3, 3, 3, 3, 3}

    self.station = _Project:getStation("Eb")
    self.x, self.y = 17, 12
    self.direction = 3
    self.mockDirections = {3, 3, 3, 3, 3, 3, 3, 4, 3, 3, 4, 4, 4, 3, 3, 3}

    ---@type Tile[]
    self.tiles = {} -- List of traversed tiles
    ---@type table<string, true>
    self.tracks = {} -- Set of track IDs to be reserved
    ---@type table<string, boolean>
    self.switches = {} -- Maps switch IDs to their states
    self.maxSpeed = nil -- Maximum speed limit, or `nil` if no speed limit
end

---Calculates the path based on the provided start and end point of this Pathfinder.
---Currently this is hacked together and the list of tiles is hardcoded. Yay!
function Pathfinder:calculatePath()
    table.insert(self.tiles, self.station:getTile(self.x, self.y))
    for i, direction in ipairs(self.mockDirections) do
        -- First, we are evaluating the tile we are currently on, and only at the end we move on to the next tile.
        local tile = self.tiles[#self.tiles]
        -- Add a track to the list.
        local track = tile:getTrackID()
        if track then
            self.tracks[track] = true
        end
        -- Check if we have to consider a switch state on this tile.
        local dir1 = _InvertDir(self.mockDirections[i - 1] or 3)
        local dir2 = direction
        local switchStates = tile:getSwitchStatesForDirections(dir1, dir2)
        for suffix, state in pairs(switchStates) do
            self.switches[tile:getSwitchID() .. suffix] = state
        end
        -- See how fast can we go there and lower the limit accordingly.
        local speed = tile:getSpeedForSwitchStates(switchStates)
        if speed then
            self.maxSpeed = self.maxSpeed and math.min(self.maxSpeed, speed) or speed
        end
        -- Move on to the next tile.
        local dx, dy = _DIRS[direction].x, _DIRS[direction].y
        self.x, self.y = self.x + dx, self.y + dy
        table.insert(self.tiles, assert(self.station:getTile(self.x, self.y)))
    end
end

---Reserves all tracks which have been traversed by this Pathfinder, with the exception of the last tile.
function Pathfinder:reserveTracks()
    for id, _ in pairs(self.tracks) do
        _Com.sendCommand("t " .. id .. " res")
    end
end

---Switches all switches this Pathfinder has found to their desired states.
function Pathfinder:switchSwitches()
    for id, state in pairs(self.switches) do
		_Com.sendCommand("j " .. id .. " " .. (state and "+" or "-"))
    end
end

---Sets the semaphore at the beginning of this path to display a clear signal.
function Pathfinder:setSemaphore()
    local nextSpeed = 1
    local lastTile = self.tiles[#self.tiles]
    print("Last tile", lastTile.semaphoreID, lastTile.trackID)
    if lastTile:isSemaphore() then
        nextSpeed = lastTile:getSemaphoreState().speed
    end
    self.tiles[1]:sendSemaphoreState(_SpeedToID(self.maxSpeed), nextSpeed)
end

return Pathfinder