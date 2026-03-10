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
function Itinerary:addSwitch(name, state)
    self.switches[name] = state
end

---Sets the starting semaphore on this itinerary.
---@param name string The semaphore ID.
function Itinerary:setSemaphore(name)
    self.semaphore = name
end

---Sets the speed of this itinerary.
---@param speed Speed The speed for the semaphore to display.
function Itinerary:setSpeed(speed)
    self.speed = speed
end

---Sets whether to display the W24 sign when this itinerary is dispatched.
---@param w24 boolean Whether the W24 signal should be displayed.
function Itinerary:setW24(w24)
    self.w24 = w24
end

---Sets the next semaphore or speed on this itinerary.
---@param next string|Speed The next semaphore ID or speed.
function Itinerary:setNext(next)
    self.next = next
end

---Returns whether this Itinerary can be dispatched.
---@return boolean
function Itinerary:canBeDispatched()
    -- All tracks must be clear.
    for track, _ in pairs(self.tracks) do
        local state = _Obj:getTrackState(track)
        if state.occupied or state.reserved then
            return false
        end
    end
    return true
end

---Dispatches this Itinerary if it can be dispatched.
function Itinerary:dispatch()
    if not self:canBeDispatched() then
        return
    end
    assert(self.semaphore, "Semaphore missing")
    assert(self.speed, "Speed missing")
    -- Reserve all tracks.
    for track, _ in pairs(self.tracks) do
        _Com.sendCommand("tr " .. track .. " " .. self.semaphore)
    end
    -- Switch all switches.
    for switch, state in pairs(self.switches) do
		_Com.sendCommand("j " .. switch .. " " .. (state and "+" or "-"))
    end
    -- Dispatch the semaphore.
    _Com.sendCommand("s " .. self.semaphore .. " " .. self.speed .. " " .. (self.next or "") .. (self.w24 and " w24" or ""))
end

return Itinerary