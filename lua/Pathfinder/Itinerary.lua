local Class = require("class")

---A tile-agnostic class which is the result of pathfinding.
---Itineraries are currently fully transient; this might change in the future but without compromising the automation (i.e. caching is a viable option).
---@class Itinerary : Class
---@overload fun(): Itinerary
local Itinerary = Class:derive("Itinerary")

function Itinerary:new()
    ---@type table<string, true>
    self.tracks = {}
    ---@type table<string, boolean>
    self.switches = {}
    ---@type table<string, string>
    self.switchesToTracks = {}
    ---@type string
    self.semaphore = nil
    ---@type Speed
    self.speed = nil
    ---@type boolean
    self.w24 = false
    ---@type string|Speed
    self.next = nil
end

---Adds a track to this itinerary. Duplicates are ignored.
---@param name string The track ID.
function Itinerary:addTrack(name)
    self.tracks[name] = true
end

---Adds a switch to this itinerary.
---@param name string The switch ID.
---@param state boolean `false` = "-", `true` = "+".
---@param track string The track ID associated with this switch.
function Itinerary:addSwitch(name, state, track)
    self.switches[name] = state
    self.switchesToTracks[name] = track
end

---Sets the starting semaphore on this itinerary.
---@param name string The semaphore ID.
function Itinerary:setSemaphore(name)
    self.semaphore = name
end

---Sets the speed of this itinerary.
---@param speed integer The speed for the semaphore to display.
function Itinerary:setSpeed(speed)
    self.speed = speed
end

---Decreases the speed of this itinerary. Speeds like Ms2, Sz, etc. are untouched.
---@param speed integer The speed for the semaphore to be decreased to.
function Itinerary:decreaseSpeed(speed)
    self.speed = self.speed > 9 and math.min(self.speed, speed) or self.speed
end

---Sets whether to display the W24 sign when this itinerary is dispatched.
---@param w24 boolean Whether the W24 signal should be displayed.
function Itinerary:setW24(w24)
    self.w24 = w24
end

---Sets the next semaphore or speed on this itinerary.
---@param next string|integer The next semaphore ID or speed.
function Itinerary:setNext(next)
    self.next = next
end

---Prints diagnostic information for this itinerary.
function Itinerary:examine()
    _LogWrite("Itinerary information:")
    _LogWrite(" - Semaphore: " .. self.semaphore .. " (speed: " .. tostring(self.speed) .. ", W24: " .. tostring(self.w24) .. ", next: " .. tostring(self.next) .. ")")
    _LogWrite(" - Tracks: " .. table.concat(_Utils.tableGetSortedKeys(self.tracks), ", "))
    _LogWrite(" - Switches:")
    for i, switch in ipairs(_Utils.tableGetSortedKeys(self.switches)) do
        _LogWrite("   - " .. switch .. (self.switches[switch] and "+" or "-") .. " => " .. self.switchesToTracks[switch])
    end
end

return Itinerary