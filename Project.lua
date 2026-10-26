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
	self.stationIndex = {}
	---@type table<string, Station>
	self.stations = {}

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

---Returns the path to the project file.
---@return string
function Project:getSavePath()
	return "projects/" .. self.name .. ".json"
end

---Returns the path to the project file on the server side.
---@return string
function Project:getServerSavePath()
	return _Settings.simPath .. "scenery/luascript/" .. self.name .. ".json"
end

---Returns the current station, or `nil` if it doesn't exist or isn't selected.
---@param shortcut string? The station shortcut.
---@return Station?
function Project:getStation(shortcut)
	if not shortcut then
		return
	end
	return self.stations[shortcut]
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
	local station = self.stations[shortcut]
	local n = _Utils.iTableGetValueIndex(self.stationIndex, station)
	if not n or n == 1 then
		return
	end
	table.remove(self.stationIndex, n)
	table.insert(self.stationIndex, n - 1, station)
end

---Moves the specified station down on the station list.
---@param shortcut string The station shortcut.
function Project:moveStationDown(shortcut)
	local station = self.stations[shortcut]
	local n = _Utils.iTableGetValueIndex(self.stationIndex, station)
	if not n or n == #self.stationIndex then
		return
	end
	table.remove(self.stationIndex, n)
	table.insert(self.stationIndex, n + 1, station)
end

---Returns a list of stations in their display order.
---@return Station[]
function Project:getStations()
	return self.stationIndex
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
	table.insert(self.stationIndex, station)
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
	local station = self.stations[shortcut]
	local n = _Utils.iTableGetValueIndex(self.stationIndex, station)
	if not n then
		return
	end
	table.remove(self.stationIndex, n)
	self.stations[shortcut] = nil
end

---Updates the `stationsByID` field with correct data.
---@private
function Project:updateStationLists()
	self.stations = {}
	for i, station in ipairs(self.stationIndex) do
		self.stations[station.shortcut] = station
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

	if _Utils.isCtrlPressed() and key == "s" then
		_Commands:saveProject(self)
	end
end

function Project:keyreleased(key)
	local station = self:getCurrentStation()
	if station then
		station:keyreleased(key)
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

function Project:wheelmoved(x, y)
	local station = self:getCurrentStation()
	if station then
		station:wheelmoved(x, y)
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
	self.name = name or self.name
	if not self.name then
		-- Cannot save a project if it has no name...
		return
	end
	self.unsaved = false
	_Utils.saveJson(self:getSavePath(), self:serialize())
	_Notifications:post("Zapisano projekt!")
end

---Exports this project to the simulator directory under the current name.
---If there is no simulator directory specified, nothing happens.
function Project:export()
	if not _Settings.simPath then
		return
	end
	self.synced = true
	_Utils.saveJson(self:getServerSavePath(), self:serialize())
	_Notifications:post("Wyeksportowano projekt!")
end

---Loads a project from the specified name.
---@param name string The project name to be loaded from.
function Project:load(name)
	self.name = name
	local data = _Utils.loadJson(self:getSavePath())
	if not data then
		_Notifications:post("Nie można załadować projektu...", NotificationColor.RED)
		return
	end
	self:deserialize(data)
	self:setCurrentStation(self.stationIndex[1] and self.stationIndex[1].shortcut)
end

---Serializes this Project's data for saving to a file.
---@return table
function Project:serialize()
	local t = {
		version = 5,
		stations = {},
		stationIndex = {}
	}
	for shortcut, station in pairs(self.stations) do
		t.stations[shortcut] = station:serialize()
	end
	for i, station in ipairs(self.stationIndex) do
		t.stationIndex[i] = station.shortcut
	end
	return t
end

---Deserializes the savefile data into this Project.
---@param t table Save data to be loaded.
function Project:deserialize(t)
	self.stationIndex = {}
	self.stations = {}
	if t.version == 5 then
		for shortcut, station in pairs(t.stations) do
			assert(station.shortcut == shortcut, "Shortcut mismatch in file " .. self:getSavePath())
			self.stations[shortcut] = Station(station)
		end
		for i, shortcut in ipairs(t.stationIndex) do
			self.stationIndex[i] = self.stations[shortcut]
		end
	else
		for i, station in ipairs(t.stations) do
			self.stationIndex[i] = Station(station)
		end
		self:updateStationLists()
	end
end

return Project
