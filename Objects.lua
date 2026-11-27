local Class = require("lua.core.class")
local Blockade = require("lua.Blockade")
local Station = require("Station") -- TODO: Rename stations to schematics in the client
local Timetable = require("lua.Timetable")
local Track = require("lua.Track")
local Switch = require("lua.Switch")
local Semaphore = require("lua.Semaphore")
local Vehicle = require("lua.Vehicle")

---Stores all objects existing on the server's simulation and their states over time.
---@class Objects : Class
---@overload fun(): Objects
local Objects = Class:derive("Objects")

function Objects:new()
    ---@type table<string, Blockade>
    self.blockades = {}
    ---@type table<string, Station>
    self.stations = {}
    ---@type table<string, Timetable>
    self.timetables = {}
    -- Keys for `tracks`, `switches` and `semaphores` are guaranteed to be lowercase.
    ---@type table<string, Track>
    self.tracks = {}
    ---@type table<string, Switch>
    self.switches = {}
    ---@type table<string, Semaphore>
    self.semaphores = {}
	---@type table<string, Vehicle>
	self.vehicles = {}
end

---Removes all data from the simulation.
function Objects:clear()
	_Utils.emptyTable(self.blockades)
	_Utils.emptyTable(self.stations)
	_Utils.emptyTable(self.timetables)
	_Utils.emptyTable(self.tracks)
	_Utils.emptyTable(self.switches)
	_Utils.emptyTable(self.semaphores)
	_Utils.emptyTable(self.vehicles)
end

---Adds a blockade to the blockade list. The index is the blockade name, e.g. "Eb-Tp".
---Returns the created object.
---@param id string The blockade ID (shortcut).
---@param data table The blockade data.
---@return Blockade
function Objects:addBlockade(id, data)
    self.blockades[id] = Blockade(id, data)
    return self.blockades[id]
end

---Adds a station to the station list. The index is the station name, e.g. "Sulejówek Miłosna".
---Returns the created object.
---@param id string The station ID (its full name).
---@return Station
function Objects:addStation(id)
    self.stations[id] = Station(id)
    return self.stations[id]
end

---Adds a timetable to the timetable list. The index is the timetable name, e.g. "ROJ55101".
---Returns the created object.
---@param id string The timetable ID (its full name).
---@param data table The timetable data.
---@param startTime string The starting timetable time, e.g. `"10:30"`. Fractions are allowed, like `"10:30.5"`.
---@return Timetable
function Objects:addTimetable(id, data, startTime)
    self.timetables[id] = Timetable(id, data, startTime)
    return self.timetables[id]
end

---Adds a track to the track list. The index is the track ID, converted to lowercase, e.g. "Eb_It2" -> "eb_it2".
---Returns the created object.
---@param id string The track ID.
---@return Track
function Objects:addTrack(id)
    self.tracks[string.lower(id)] = Track(id)
    return self.tracks[string.lower(id)]
end

---Adds a switch to the switch list. The index is the switch ID, converted to lowercase, e.g. "Eb_25ab" -> "eb_25ab".
---Returns the created object.
---@param id string The switch ID.
---@return Switch
function Objects:addSwitch(id)
    self.switches[string.lower(id)] = Switch(id)
    return self.switches[string.lower(id)]
end

---Adds a semaphore to the semaphore list. The index is the semaphore ID, converted to lowercase, e.g. "Eb_A" -> "eb_a".
---Returns the created object.
---@param id string The semaphore ID.
---@param data table The semaphore data.
---@return Semaphore
function Objects:addSemaphore(id, data)
    self.semaphores[string.lower(id)] = Semaphore(id, data)
    return self.semaphores[string.lower(id)]
end

---Adds a vehicle to the vehicle list. The index is the vehicle name, e.g. "EN76-049a".
---Returns the created object.
---@param id string The vehicle ID.
---@return Vehicle
function Objects:addVehicle(id)
    self.vehicles[id] = Vehicle(id)
    return self.vehicles[id]
end

---Returns a Blockade based on its simulation name, or `nil` if it's not found.
---@param name string Blockade ID.
---@return Blockade?
function Objects:getBlockade(name)
	return self.blockades[name]
end

---Returns a Blockade based on its simulation name, or throws an error if it's not found.
---@param name string Blockade ID.
---@return Blockade
function Objects:assertGetBlockade(name)
	local blockade = assert(self:getBlockade(name), "Tried to access a nonexistent blockade: " .. tostring(name))
    return blockade
end

---Returns a Station based on its simulation name, or `nil` if it's not found.
---@param name string Station ID.
---@return Station?
function Objects:getStation(name)
	return self.stations[name]
end

---Returns a Station based on its simulation name, or throws an error if it's not found.
---@param name string Station ID.
---@return Station
function Objects:assertGetStation(name)
	local station = assert(self:getStation(name), "Tried to access a nonexistent station: " .. tostring(name))
    return station
end

---Returns a Timetable based on its name (number), or `nil` if it's not found.
---@param name string Timetable shortcut.
---@return Timetable?
function Objects:getTimetable(name)
	return self.timetables[name]
end

---Returns a Timetable based on its name (number), or throws an error if it's not found.
---@param name string Timetable shortcut.
---@return Timetable
function Objects:assertGetTimetable(name)
    local timetable = assert(self:getTimetable(name), "Tried to access a nonexistent timetable: " .. tostring(name))
    return timetable
end

---Returns a Track based on its simulation name, or `nil` if it is not found.
---@param name string For example: `"Eb_It2"`. Case-insensitive.
---@return Track?
function Objects:getTrack(name)
	return self.tracks[string.lower(name)]
end

---Returns a Track based on its simulation name, or throws an error if it is not found.
---@param name string For example: `"Eb_It2"`. Case-insensitive.
---@return Track
function Objects:assertGetTrack(name)
	local track = assert(self:getTrack(name), "Tried to access an invalid track: " .. tostring(name):lower())
    return track
end

---Returns a Switch based on its simulation name, or `nil` if it is not found.
---@param name string For example: `"Eb_39"`. Case-insensitive.
---@return Switch?
function Objects:getSwitch(name)
	return self.switches[string.lower(name)]
end

---Returns a Switch based on its simulation name, or throws an error if it is not found.
---@param name string For example: `"Eb_39"`. Case-insensitive.
---@return Switch
function Objects:assertGetSwitch(name)
	local switch = assert(self:getSwitch(name), "Tried to access an invalid switch: " .. tostring(name):lower())
    return switch
end

---Returns a Semaphore based on its simulation name, or `nil` if it is not found.
---@param name string For example: `"Eb_A"`. Case-insensitive.
---@return Semaphore?
function Objects:getSemaphore(name)
	return self.semaphores[string.lower(name)]
end

---Returns a Semaphore based on its simulation name, or throws an error if it is not found.
---@param name string For example: `"Eb_A"`. Case-insensitive.
---@return Semaphore
function Objects:assertGetSemaphore(name)
	local semaphore = assert(self:getSemaphore(name), "Tried to access an invalid semaphore: " .. tostring(name):lower())
    return semaphore
end

---Returns a Vehicle based on its simulation name, or `nil` if it is not found.
---@param name string For example: `"EN76-049a"`.
---@return Vehicle?
function Objects:getVehicle(name)
	return self.vehicles[string.lower(name)]
end

---Returns a Vehicle based on its simulation name, or throws an error if it is not found.
---@param name string For example: `"EN76-049a"`.
---@return Vehicle
function Objects:assertGetVehicle(name)
	local vehicle = assert(self:getVehicle(name), "Tried to access an invalid vehicle: " .. tostring(name))
    return vehicle
end

---Returns a list of blockade IDs, sorted alphabetically.
---@return string[]
function Objects:getBlockadeList()
	return _Utils.tableGetSortedKeys(self.blockades)
end

---Returns a list of station IDs, sorted alphabetically.
---@return string[]
function Objects:getStationList()
	return _Utils.tableGetSortedKeys(self.stations)
end

---Returns a list of timetable IDs, sorted alphabetically.
---@return string[]
function Objects:getTimetableList()
	return _Utils.tableGetSortedKeys(self.timetables)
end

---Returns a list of track IDs, sorted alphabetically.
---@return string[]
function Objects:getTrackList()
	return _Utils.tableGetSortedKeys(self.tracks)
end

---Returns a list of switch IDs, sorted alphabetically.
---@return string[]
function Objects:getSwitchList()
	return _Utils.tableGetSortedKeys(self.switches)
end

---Returns a list of semaphore IDs, sorted alphabetically.
---@return string[]
function Objects:getSemaphoreList()
	return _Utils.tableGetSortedKeys(self.semaphores)
end

---Returns a list of vehicle IDs, sorted alphabetically.
---@return string[]
function Objects:getVehicleList()
	return _Utils.tableGetSortedKeys(self.vehicles)
end

return Objects