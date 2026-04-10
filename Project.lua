local class = require "class"
local Station = require("Station")

---@class Project : Class
---@overload fun(): Project
local Project = class:derive("Project")

function Project:new()
	self.name = nil
	self.unsaved = false
	self.synced = true -- Whether the project file is synchronized with the server
	self.currentStationID = nil

	---@type Station[]
	self.stations = {}
	---@type table<string, Station>
	self.stationsByID = {}

	self:updateStationLists()
end

---Updates the project.
---@param dt number Time delta in seconds.
function Project:update(dt)
	-- Maybe we need updating all stations?
	local station = self:getCurrentStation()
	if station then
		station:update(dt)
	end
end

---Returns the current station, or `nil` if it doesn't exist or isn't selected.
---@param shortcut string? The station shortcut.
---@return Station?
function Project:getStation(shortcut)
	if not shortcut then
		return
	end
	return self.stationsByID[shortcut]
end

---Returns the currently selected station, or `nil` if no station is selected.
---@return Station?
function Project:getCurrentStation()
	return self:getStation(self.currentStationID)
end

---Sets a new current station by shortcut.
---@param shortcut string? The new station shortcut, or `nil` if not station should be selected.
function Project:setCurrentStation(shortcut)
	self.currentStationID = shortcut
	_UI.rightPane:update()
end

---Moves the specified station up on the station list.
---@param shortcut string The station shortcut.
function Project:moveStationUp(shortcut)
	local station = self.stationsByID[shortcut]
	local n = _Utils.iTableGetValueIndex(self.stations, station)
	if not n or n == 1 then
		return
	end
	table.remove(self.stations, n)
	table.insert(self.stations, n - 1, station)
end

---Moves the specified station down on the station list.
---@param shortcut string The station shortcut.
function Project:moveStationDown(shortcut)
	local station = self.stationsByID[shortcut]
	local n = _Utils.iTableGetValueIndex(self.stations, station)
	if not n or n == #self.stations then
		return
	end
	table.remove(self.stations, n)
	table.insert(self.stations, n + 1, station)
end

---Returns a list of stations in their display order.
---@return Station[]
function Project:getStations()
	return self.stations
end

---Creates a new station.
function Project:addStation()
	-- Generate a unique station ID.
	local id = 1
	while self:getStation("St" .. tostring(id)) do
		id = id + 1
	end
	-- Create a new station and add it to the list.
	local station = Station("Station" .. tostring(id), "St" .. tostring(id))
	table.insert(self.stations, station)
	-- Update the reference lists.
	self:updateStationLists()
end

---Renames a station.
---@param shortcut string The shortcut of the station to be changed.
---@param newName string The new name of the station.
---@param newShortcut string The new shortcut of the station.
function Project:renameStation(shortcut, newName, newShortcut)
	local station = self:getStation(shortcut)
	station.name = newName
	station.shortcut = newShortcut
	if self.currentStationID == shortcut then
		self.currentStationID = newShortcut
	end
	self:updateStationLists()
end

---Removes the station with the specified shortcut.
---@param shortcut string The station shortcut.
function Project:deleteStation(shortcut)
	local station = self.stationsByID[shortcut]
	local n = _Utils.iTableGetValueIndex(self.stations, station)
	if not n then
		return
	end
	table.remove(self.stations, n)
	self.stationsByID[shortcut] = nil
end

---Updates the `stationsByID` field with correct data.
---@private
function Project:updateStationLists()
	self.stationsByID = {}
	for i, station in ipairs(self.stations) do
		self.stationsByID[station.shortcut] = station
	end
end

function Project:draw()
	local station = self:getCurrentStation()
	if station then
		station:draw()
	end
end

function Project:keypressed(key)
	local station = self:getCurrentStation()
	if station then
		station:keypressed(key)
	end
end

function Project:mousepressed(x, y, button)
	local station = self:getCurrentStation()
	if station then
		station:mousepressed(x, y, button)
	end
end

function Project:mousereleased(x, y, button)
	local station = self:getCurrentStation()
	if station then
		station:mousereleased(x, y, button)
	end
end

---Marks this project as unsaved and unsynced.
function Project:markUnsaved()
	self.unsaved = true
	self.synced = false
end

---Returns whether this project is synchronized with the server.
---@return boolean
function Project:isSynced()
	return self.synced
end

---Exports this project if it is currently not synchronized with the server.
function Project:sync()
	if not self.synced then
		self:export()
	end
end

---Saves this project under the specified name.
---@param name string? The project name to be saved as. If not specified, the current name will be used.
function Project:save(name)
	name = name or self.name
	if not name then
		-- Cannot save a project if it has no name...
		return
	end
	self.name = name
	self.unsaved = false
	_Utils.saveJson("projects/" .. name .. ".json", self:serialize())
	_Notifications:post("Zapisano projekt!")
end

---Exports this project to the simulator directory under the current name.
---If there is no simulator directory specified, nothing happens.
function Project:export()
	if not _Settings.simPath then
		return
	end
	self.synced = true
	_Utils.saveJson(_Settings.simPath .. "scenery/luascript/" .. self.name .. "_proj.json", self:serialize())
	_Notifications:post("Wyeksportowano projekt!")
end

---Loads a project from the specified name.
---@param name string The project name to be loaded from.
function Project:load(name)
	local data = _Utils.loadJson("projects/" .. name .. ".json")
	if not data then
		_Notifications:post("Nie można załadować projektu...", NotificationColor.RED)
		return
	end
	self.name = name
	self:deserialize(data)
	self:setCurrentStation(self.stations[1].shortcut)
end

---Serializes this Project's data for saving to a file.
---@return table
function Project:serialize()
	local t = {
		stations = {},
		stationIndex = {}
	}
	for i, station in ipairs(self.stations) do
		t.stations[i] = station:serialize()
		t.stationIndex[station.shortcut] = i
	end
	return t
end

---Deserializes the savefile data into this Project.
---@param t table Save data to be loaded.
function Project:deserialize(t)
	self.stations = {}
	for i, station in ipairs(t.stations) do
		self.stations[i] = Station(station)
	end
	self:updateStationLists()
end

return Project
