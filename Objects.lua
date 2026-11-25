local Class = require("lua.core.class")
local SemaphoreType = require("lua.core.Enums.SemaphoreType")
local Speed = require("lua.core.Enums.Speed")

---Stores all objects existing on the server's simulation and their states over time.
---@class Objects : Class
---@overload fun(): Objects
local Objects = Class:derive("Objects")

function Objects:new()
	---@type table<string, {}>
	self.stations = {}
	---@alias TrackState {occupied: boolean, reserved: boolean}
	---@type table<string, {current: TrackState, history: table<integer, TrackState>}>
	self.tracks = {}
	---@alias SwitchState {state: boolean, forced: boolean}
	---@type table<string, {current: SwitchState, history: table<integer, SwitchState>}>
	self.switches = {}
	---@alias SemaphoreState {speed: Speed, nextSpeed: Speed, image: string}
	---@type table<string, {current: SemaphoreState, history: table<integer, SemaphoreState>}>
	self.semaphores = {}
	---@alias BlockadeState {direction: boolean?}
	---@type table<string, {current: BlockadeState, history: table<integer, BlockadeState>}>
	self.blockades = {}
	---@type table<string, {}>
	self.vehicles = {}
	---@alias TrackReservationState {semaphoreID: string?}
	---@type table<string, {current: TrackReservationState, history: table<integer, TrackReservationState>}>
	self.trackReservations = {}
	---@type table<string, table<string, integer>>
	self.trackVehicles = {} -- TODO: Cover this by history?
end

---Removes all data from the simulation.
function Objects:clear()
	_Utils.emptyTable(self.stations)
	_Utils.emptyTable(self.tracks)
	_Utils.emptyTable(self.switches)
	_Utils.emptyTable(self.semaphores)
	_Utils.emptyTable(self.blockades)
	_Utils.emptyTable(self.vehicles)
	_Utils.emptyTable(self.trackReservations)
	_Utils.emptyTable(self.trackVehicles)
end

---Initializes a station.
---@param name string The station name.
function Objects:initStation(name)
	self.stations[name] = {}
end

---Initializes a track.
---@param name string The full track ID.
function Objects:initTrack(name)
	local initialState = {occupied = false, reserved = false}
	self.tracks[name] = {current = initialState, history = {[0] = initialState}}
	-- TODO: Merge track and track reservation state by adding partial state update support.
	self:initTrackReservation(name)
end

---Initializes a switch.
---@param name string The full switch ID.
function Objects:initSwitch(name)
	local initialState = {state = false}
	self.switches[name] = {current = initialState, history = {[0] = initialState}}
end

---Initializes a semaphore.
---@param name string The full semaphore ID.
---@param type SemaphoreType The semaphore type.
function Objects:initSemaphore(name, type)
    local startingImage = type == SemaphoreType.TM and "ms1" or "s1"
	local initialState = {speed = Speed.STOP, nextSpeed = Speed.STOP, image = startingImage}
	self.semaphores[name] = {current = initialState, history = {[0] = initialState}}
end

---Initializes a blockade.
---@param name string The full blockade ID.
function Objects:initBlockade(name)
	local initialState = {direction = false}
	self.blockades[name] = {current = initialState, history = {[0] = initialState}}
end

---Initializes a vehicle.
---@param name string The full vehicle ID.
function Objects:initVehicle(name)
	self.vehicles[name] = {}
end

---Initializes a track reservation slot.
---@param name string The full track ID.
function Objects:initTrackReservation(name)
	local initialState = {}
	self.trackReservations[name] = {current = initialState, history = {[0] = initialState}}
end

---Sets a new state for the specified history type.
---@private
---@generic T
---@param history {current: T, history: table<integer, T>} The history table for an object to be used.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param state T New state to be applied.
function Objects:updateHistory(history, tick, state)
	history.history[tick] = state
	-- Update the current state if the newly provided timestamp is the most recent one.
	if _GetMaxLessThan(_Utils.tableGetSortedKeys(history.history), 999999999) == tick then
		history.current = state
	end
end

---Sets a new state for the specified track.
---@param trackID string The full track ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param occupied boolean Whether this track is occupied.
---@param reserved boolean Whether this track is reserved.
function Objects:setTrackState(trackID, tick, occupied, reserved)
	local newState = {occupied = occupied, reserved = reserved}
	self:updateHistory(self.tracks[trackID], tick, newState)
    print(string.format("[t=%s] %s : occupied=%s reserved=%s", tick, trackID, occupied, reserved))
end

---Sets a new state for the specified switch.
---@param switchID string The full switch ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param state boolean If `true`, "+", otherwise - "-".
---@param forced boolean Whether the switch has been forcefully switched ("rozprucie rozjazdu").
function Objects:setSwitchState(switchID, tick, state, forced)
	local newState = {state = state, forced = forced}
	self:updateHistory(self.switches[switchID], tick, newState)
    print(string.format("[t=%s] %s : state=%s forced=%s", tick, switchID, state, forced))
end

---Sets a new state for the specified semaphore.
---@param semaphoreID string The full semaphore ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param speed Speed The current speed on the semaphore.
---@param nextSpeed Speed The next speed on the semaphore.
---@param image string The image on the semaphore.
function Objects:setSemaphoreState(semaphoreID, tick, speed, nextSpeed, image)
	local newState = {speed = speed, nextSpeed = nextSpeed, image = image}
	self:updateHistory(self.semaphores[semaphoreID], tick, newState)
    print(string.format("[t=%s] %s : speed=%s nextSpeed=%s image=%s", tick, semaphoreID, speed, nextSpeed, image))
end

---Sets a new state for the specified blockade.
---@param blockadeID string The full blockade ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param direction boolean? The new blockade direction.
function Objects:setBlockadeState(blockadeID, tick, direction)
	local newState = {direction = direction}
	self:updateHistory(self.blockades[blockadeID], tick, newState)
    print(string.format("[t=%s] %s : direction=%s", tick, blockadeID, direction))
end

---Sets a new "reserved by" state for the specified track.
---@param trackID string The full track ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param semaphoreID string? The new semaphore (or lack thereof) by which this track is reserved.
function Objects:setTrackReservationState(trackID, tick, semaphoreID)
	local newState = {semaphoreID = semaphoreID}
	self:updateHistory(self.trackReservations[trackID], tick, newState)
    print(string.format("[t=%s] %s : reserved by semaphoreID=%s", tick, trackID, semaphoreID))
end

---Increases the vehicle counter for the specified track and the specified vehicle.
---@param trackID string The full track ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param vehicleID string The vehicle ID to increment.
function Objects:incTrackVehicle(trackID, tick, vehicleID)
	self.trackVehicles[trackID] = self.trackVehicles[trackID] or {}
	self.trackVehicles[trackID][vehicleID] = (self.trackVehicles[trackID][vehicleID] or 0) + 1
    print(string.format("[t=%s] %s : incremented vehicle %s", tick, trackID, vehicleID))
end

---Decreases the vehicle counter for the specified track and the specified vehicle.
---@param trackID string The full track ID.
---@param tick integer The tick on which this state is set. This state is valid until the next change.
---@param vehicleID string The vehicle ID to decrease.
function Objects:decTrackVehicle(trackID, tick, vehicleID)
	self.trackVehicles[trackID] = self.trackVehicles[trackID] or {}
	self.trackVehicles[trackID][vehicleID] = (self.trackVehicles[trackID][vehicleID] or 0) - 1
	if self.trackVehicles[trackID][vehicleID] == 0 then
		self.trackVehicles[trackID][vehicleID] = nil
	end
    print(string.format("[t=%s] %s : decremented vehicle %s", tick, trackID, vehicleID))
end

---Returns the track state at the given tick, or `nil` if the provided track doesn't exist.
---@param name string The full track ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return TrackState?
function Objects:getTrackState(name, tick)
	local history = self.tracks[name]
	return history and (tick and history.history[_GetMaxLessThan(_Utils.tableGetSortedKeys(history.history), tick)] or history.current)
end

---Returns the switch state at the given tick, or `nil` if the provided switch doesn't exist.
---@param name string The full switch ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return SwitchState?
function Objects:getSwitchState(name, tick)
	local history = self.switches[name]
	return history and (tick and history.history[_GetMaxLessThan(_Utils.tableGetSortedKeys(history.history), tick)] or history.current)
end

---Returns the semaphore state at the given tick, or `nil` if the provided semaphore doesn't exist.
---@param name string The full semaphore ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return SemaphoreState?
function Objects:getSemaphoreState(name, tick)
	local history = self.semaphores[name]
	return history and (tick and history.history[_GetMaxLessThan(_Utils.tableGetSortedKeys(history.history), tick)] or history.current)
end

---Returns the blockade state at the given tick, or `nil` if the provided blockade doesn't exist.
---@param name string The full blockade ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return BlockadeState?
function Objects:getBlockadeState(name, tick)
	local history = self.blockades[name]
	return history and (tick and history.history[_GetMaxLessThan(_Utils.tableGetSortedKeys(history.history), tick)] or history.current)
end

---Returns the track reservation state at the given tick, or `nil` if the provided track doesn't exist.
---@param name string The full blockade ID.
---@param tick integer? The tick for which the state should be returned. If not specified, the current state will be returned.
---@return TrackReservationState?
function Objects:getTrackReservationState(name, tick)
	local history = self.trackReservations[name]
	return history and (tick and history.history[_GetMaxLessThan(_Utils.tableGetSortedKeys(history.history), tick)] or history.current)
end

---Returns the list of vehicles currently on the given track, alongside with counters.
---If there are no vehicles, returns an empty table.
---@param name string The track ID to fetch the vehicle list from.
---@return table<string, integer>?
function Objects:getTrackVehicleState(name)
	-- Prepend an empty table once.
	self.trackVehicles[name] = self.trackVehicles[name] or {}
	return self.trackVehicles[name]
end

return Objects