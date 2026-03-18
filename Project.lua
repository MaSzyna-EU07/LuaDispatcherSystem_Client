local class = require "class"

---@class Project : Class
---@overload fun(): Project
local Project = class:derive("Project")

local Station = require("Station")

function Project:new()
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

function Project:save()
	_Utils.saveJson("savefile.json", self:serialize())
	_Notifications:post("Zapisano projekt!")
end

function Project:load()
	self:deserialize(_Utils.loadJson("savefile.json"))
end

function Project:serialize()
	local t = {
		stations = {}
	}
	for i, station in ipairs(self.stations) do
		t.stations[i] = station:serialize()
	end
	
	return t
end

function Project:deserialize(t)
	self.stations = {}
	if t.stations then
		for i, station in ipairs(t.stations) do
			self.stations[i] = Station(station)
		end
	else
		self.stations[1] = Station(t.station)
	end
	self:updateStationLists()
end

return Project
