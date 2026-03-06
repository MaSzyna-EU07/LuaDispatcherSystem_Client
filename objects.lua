-- TODO: Change this to a class.

---@alias TrackState {occupied: boolean, reserved: boolean}
---@alias SwitchState {state: boolean}
---@alias SemaphoreState {speed: integer, nextSpeed: integer, image: string}

---@type {
--- stations: table<string, {}>,
--- tracks: table<string, table<integer, TrackState>>,
--- switches: table<string, table<integer, SwitchState>>,
--- semaphores: table<string, table<integer, SemaphoreState>>,
--- [any]: function}
local obj = {stations = {}, tracks = {}, switches = {}, semaphores = {}}

---Resets all object history.
function obj.clear()
	obj = {stations = {}, tracks = {}, switches = {}, semaphores = {}}
end



function obj.initStation(stationN)
    -- Do we need this?
	obj.stations[stationN] = {}
end

function obj.initTrack(trackID)
	obj.tracks[trackID] = {[0] = {occupied = false, reserved = false}}
end

function obj.initSwitch(switchID)
	obj.switches[switchID] = {[0] = {state = false}}
end

function obj.initSemaphore(semaphoreID, type)
    local startingImage = type == 1 and "ms1" or "s1"
	obj.semaphores[semaphoreID] = {[0] = {image = startingImage}}
end



function obj.setTrackState(trackID, tick, occupied, reserved)
	obj.tracks[trackID][tick] = {occupied = occupied, reserved = reserved}
    print(string.format("[t=%s] %s : occupied=%s reserved=%s", tick, trackID, occupied, reserved))
end

function obj.setSwitchState(switchID, tick, state)
	obj.switches[switchID][tick] = {state = state}
    print(string.format("[t=%s] %s : state=%s", tick, switchID, state))
end

function obj.setSemaphoreState(semaphoreID, tick, speed, nextSpeed, image)
	obj.semaphores[semaphoreID][tick] = {speed = speed, nextSpeed = nextSpeed, image = image}
    print(string.format("[t=%s] %s : speed=%s nextSpeed=%s image=%s", tick, semaphoreID, speed, nextSpeed, image))
end



---Returns the state of the provided object at the given tick.
---@private
---@param tableID string The index to the `obj` table.
---@param objectID string The object ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return TrackState|SwitchState|SemaphoreState
local function getObjectState(tableID, objectID, tick)
	local history = obj[tableID][objectID]
	return history and history[_GetMaxLessThan(_GetTableKeys(history), tick or 9999999999)]
end




---Returns the track state at the given tick.
---@param trackID string The track ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return TrackState
function obj.getTrackState(trackID, tick)
    return getObjectState("tracks", trackID, tick)
end

---Returns the switch state at the given tick.
---@param switchID string The switch ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return SwitchState
function obj.getSwitchState(switchID, tick)
    return getObjectState("switches", switchID, tick)
end

---Returns the semaphore state at the given tick.
---@param semaphoreID string The semaphore ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return SemaphoreState
function obj.getSemaphoreState(semaphoreID, tick)
    return getObjectState("semaphores", semaphoreID, tick)
end

return obj