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
	---@type table<string, TrackState>
	self.tracks = {}
	---@alias SwitchState {state: boolean, forced: boolean}
	---@type table<string, SwitchState>
	self.switches = {}
	---@alias SemaphoreState {speed: Speed, nextSpeed: Speed, image: string}
	---@type table<string, SemaphoreState>
	self.semaphores = {}
	---@alias BlockadeState {direction: boolean?}
	---@type table<string, BlockadeState>
	self.blockades = {}
	---@type table<string, {}>
	self.vehicles = {}
	---@alias TrackReservationState {semaphoreID: string?}
	---@type table<string, TrackReservationState>
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
	self.tracks[name] = {occupied = false, reserved = false}
	-- TODO: Merge track and track reservation state.
	self:initTrackReservation(name)
end

---Initializes a switch.
---@param name string The full switch ID.
function Objects:initSwitch(name)
	self.switches[name] = {state = false}
end

---Initializes a semaphore.
---@param name string The full semaphore ID.
---@param type SemaphoreType The semaphore type.
function Objects:initSemaphore(name, type)
    local startingImage = type == SemaphoreType.TM and "ms1" or "s1"
	self.semaphores[name] = {speed = Speed.STOP, nextSpeed = Speed.STOP, image = startingImage}
end

---Initializes a blockade.
---@param name string The full blockade ID.
function Objects:initBlockade(name)
	self.blockades[name] = {direction = false}
end

---Initializes a vehicle.
---@param name string The full vehicle ID.
function Objects:initVehicle(name)
	self.vehicles[name] = {}
end

---Initializes a track reservation slot.
---@param name string The full track ID.
function Objects:initTrackReservation(name)
	self.trackReservations[name] = {}
end

---Sets a new state for the specified track.
---@param trackID string The full track ID.
---@param occupied boolean Whether this track is occupied.
---@param reserved boolean Whether this track is reserved.
function Objects:setTrackState(trackID, occupied, reserved)
	self.tracks[trackID] = {occupied = occupied, reserved = reserved}
    print(string.format("%s : occupied=%s reserved=%s", trackID, occupied, reserved))
end

---Sets a new state for the specified switch.
---@param switchID string The full switch ID.
---@param state boolean If `true`, "+", otherwise - "-".
---@param forced boolean Whether the switch has been forcefully switched ("rozprucie rozjazdu").
function Objects:setSwitchState(switchID, state, forced)
	self.switches[switchID] = {state = state, forced = forced}
    print(string.format("%s : state=%s forced=%s", switchID, state, forced))
end

---Sets a new state for the specified semaphore.
---@param semaphoreID string The full semaphore ID.
---@param speed Speed The current speed on the semaphore.
---@param nextSpeed Speed The next speed on the semaphore.
---@param image string The image on the semaphore.
function Objects:setSemaphoreState(semaphoreID, speed, nextSpeed, image)
	self.semaphores[semaphoreID] = {speed = speed, nextSpeed = nextSpeed, image = image}
    print(string.format("%s : speed=%s nextSpeed=%s image=%s", semaphoreID, speed, nextSpeed, image))
end

---Sets a new state for the specified blockade.
---@param blockadeID string The full blockade ID.
---@param direction boolean? The new blockade direction.
function Objects:setBlockadeState(blockadeID, direction)
	self.blockades[blockadeID] = {direction = direction}
    print(string.format("%s : direction=%s", blockadeID, direction))
end

---Sets a new "reserved by" state for the specified track.
---@param trackID string The full track ID.
---@param semaphoreID string? The new semaphore (or lack thereof) by which this track is reserved.
function Objects:setTrackReservationState(trackID, semaphoreID)
	self.trackReservations[trackID] = {semaphoreID = semaphoreID}
    print(string.format("%s : reserved by semaphoreID=%s", trackID, semaphoreID))
end

---Increases the vehicle counter for the specified track and the specified vehicle.
---@param trackID string The full track ID.
---@param vehicleID string The vehicle ID to increment.
function Objects:incTrackVehicle(trackID, vehicleID)
	self.trackVehicles[trackID] = self.trackVehicles[trackID] or {}
	self.trackVehicles[trackID][vehicleID] = (self.trackVehicles[trackID][vehicleID] or 0) + 1
    print(string.format("%s : incremented vehicle %s", trackID, vehicleID))
end

---Decreases the vehicle counter for the specified track and the specified vehicle.
---@param trackID string The full track ID.
---@param vehicleID string The vehicle ID to decrease.
function Objects:decTrackVehicle(trackID, vehicleID)
	self.trackVehicles[trackID] = self.trackVehicles[trackID] or {}
	self.trackVehicles[trackID][vehicleID] = (self.trackVehicles[trackID][vehicleID] or 0) - 1
	if self.trackVehicles[trackID][vehicleID] == 0 then
		self.trackVehicles[trackID][vehicleID] = nil
	end
    print(string.format("%s : decremented vehicle %s", trackID, vehicleID))
end

---Returns the track state at the given tick, or `nil` if the provided track doesn't exist.
---@param name string The full track ID.
---@return TrackState?
function Objects:getTrackState(name)
	return self.tracks[name]
end

---Returns the switch state at the given tick, or `nil` if the provided switch doesn't exist.
---@param name string The full switch ID.
---@return SwitchState?
function Objects:getSwitchState(name)
	return self.switches[name]
end

---Returns the semaphore state at the given tick, or `nil` if the provided semaphore doesn't exist.
---@param name string The full semaphore ID.
---@return SemaphoreState?
function Objects:getSemaphoreState(name)
	return self.semaphores[name]
end

---Returns the blockade state at the given tick, or `nil` if the provided blockade doesn't exist.
---@param name string The full blockade ID.
---@return BlockadeState?
function Objects:getBlockadeState(name)
	return self.blockades[name]
end

---Returns the track reservation state at the given tick, or `nil` if the provided track doesn't exist.
---@param name string The full blockade ID.
---@return TrackReservationState?
function Objects:getTrackReservationState(name)
	return self.trackReservations[name]
end

---Returns the list of vehicles currently on the given track, alongside with counters.
---If there are no vehicles, returns an empty table.
---@param name string The track ID to fetch the vehicle list from.
---@return table<string, integer>?
function Objects:getTrackVehicleState(name)
	return self.trackVehicles[name]
end

return Objects