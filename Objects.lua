local Class = require("class")

---Stores all objects existing on the server's simulation and their states over time.
---@class Objects : Class
---@overload fun(): Objects
local Objects = Class:derive("Objects")

function Objects:new()
	---@type table<string, {}>
	self.stations = {}
	---@alias TrackState {occupied: boolean, reserved: boolean}
	---@type table<string, table<integer, TrackState>>
	self.tracks = {}
	---@alias SwitchState {state: boolean}
	---@type table<string, table<integer, SwitchState>>
	self.switches = {}
	---@alias SemaphoreState {speed: Speed, nextSpeed: Speed, image: string}
	---@type table<string, table<integer, SemaphoreState>>
	self.semaphores = {}
end

---Removes all data from the simulation.
function Objects:clear()
	_Utils.emptyTable(self.stations)
	_Utils.emptyTable(self.tracks)
	_Utils.emptyTable(self.switches)
	_Utils.emptyTable(self.semaphores)
end

---Initializes a station.
---@param name string The station name.
function Objects:initStation(name)
	self.stations[name] = {}
end

---Initializes a track.
---@param name string The full track ID.
function Objects:initTrack(name)
	self.tracks[name] = {[0] = {occupied = false, reserved = false}}
end

---Initializes a switch.
---@param name string The full switch ID.
function Objects:initSwitch(name)
	self.switches[name] = {[0] = {state = false}}
end

---Initializes a semaphore.
---@param name string The full semaphore ID.
---@param type SemaphoreType The semaphore type.
function Objects:initSemaphore(name, type)
    local startingImage = type == SemaphoreType.TM and "ms1" or "s1"
	self.semaphores[name] = {[0] = {image = startingImage}}
end

---Sets a new state for the specified track.
---@param trackID string The full track ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param occupied boolean Whether this track is occupied.
---@param reserved boolean Whether this track is reserved.
function Objects:setTrackState(trackID, tick, occupied, reserved)
	self.tracks[trackID][tick] = {occupied = occupied, reserved = reserved}
    print(string.format("[t=%s] %s : occupied=%s reserved=%s", tick, trackID, occupied, reserved))
end

---Sets a new state for the specified switch.
---@param switchID string The full switch ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param state boolean If `true`, "+", otherwise - "-".
function Objects:setSwitchState(switchID, tick, state)
	self.switches[switchID][tick] = {state = state}
    print(string.format("[t=%s] %s : state=%s", tick, switchID, state))
end

---Sets a new state for the specified semaphore.
---@param semaphoreID string The full semaphore ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param speed Speed The current speed on the semaphore.
---@param nextSpeed Speed The next speed on the semaphore.
---@param image string The image on the semaphore.
function Objects:setSemaphoreState(semaphoreID, tick, speed, nextSpeed, image)
	self.semaphores[semaphoreID][tick] = {speed = speed, nextSpeed = nextSpeed, image = image}
    print(string.format("[t=%s] %s : speed=%s nextSpeed=%s image=%s", tick, semaphoreID, speed, nextSpeed, image))
end

---Returns the track state at the given tick.
---@param name string The full track ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return TrackState
function Objects:getTrackState(name, tick)
	local history = self.tracks[name]
	return history and history[_GetMaxLessThan(_GetTableKeys(history), tick or 9999999999)]
end

---Returns the switch state at the given tick.
---@param name string The full switch ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return SwitchState
function Objects:getSwitchState(name, tick)
	local history = self.switches[name]
	return history and history[_GetMaxLessThan(_GetTableKeys(history), tick or 9999999999)]
end

---Returns the semaphore state at the given tick.
---@param name string The full semaphore ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return SemaphoreState
function Objects:getSemaphoreState(name, tick)
	local history = self.semaphores[name]
	return history and history[_GetMaxLessThan(_GetTableKeys(history), tick or 9999999999)]
end

return Objects