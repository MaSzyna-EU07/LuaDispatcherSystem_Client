local class = require "class"
local Station = require("Station")

---@class Project : Class
---@overload fun(): Project
local Project = class:derive("Project")

function Project:new()
	self.name = nil
	self.stations = {}
	---@type table<string, Station>
	self.stationsByID = {}
	self.currentStationID = nil

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

function Project:setCurrentStation(shortcut)
	self.currentStationID = shortcut
	_UI.rightPane:update()
end

function Project:getStationNames()
	local names = {}
	for i, station in ipairs(self.stations) do
		table.insert(names, station:getFullName())
	end
	return names
end

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

function Project:renameStation(shortcut, newName, newShortcut)
	local station = self:getStation(shortcut)
	station.name = newName
	station.shortcut = newShortcut
	if self.currentStationID == shortcut then
		self.currentStationID = newShortcut
	end
	self:updateStationLists()
end

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

---Saves this project under the specified name.
---@param name string? The project name to be saved as. If not specified, the current name will be used.
function Project:save(name)
	name = name or self.name
	if not name then
		-- Cannot save a project if it has no name...
		return
	end
	_Utils.saveJson("projects/" .. name .. ".json", self:serialize())
	_Notifications:post("Zapisano projekt!")
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
end

---Serializes this Project's data for saving to a file.
---@return table
function Project:serialize()
	local t = {
		stations = {}
	}
	for i, station in ipairs(self.stations) do
		t.stations[i] = station:serialize()
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
