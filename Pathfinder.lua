local Class = require("class")

---@class Pathfinder : Class
---@overload fun(): Pathfinder
local Pathfinder = Class:derive("Pathfinder")

function Pathfinder:new()
    self.station = _Project:getCurrentStation()
    ---@type Tile[]
    self.tiles = {}
    for i = 4, 12 do
        table.insert(self.tiles, _Project:getStation("Tp"):getTile(i, 4))
    end
    for i = 2, 6 do
        table.insert(self.tiles, _Project:getStation("Eb"):getTile(i, 12))
    end
end

---Reserves all tracks which have been traversed by this Pathfinder, with the exception of the last tile.
function Pathfinder:reserveTracks()
    for i = 1, #self.tiles - 1 do
        self.tiles[i]:sendTrackState("res")
    end
end

---Returns a set of track IDs which have been traversed by this Pathfinder.
---The last tile is NOT counted.
---@return table<string, true>
function Pathfinder:getTracks()
    local tracks = {}
    for i = 1, #self.tiles - 1 do
        local trackID = self.tiles[i]:getTrackID()
        if trackID then
            tracks[trackID] = true
        end
    end
    return tracks
end

return Pathfinder