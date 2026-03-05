local class = require "class"

---@class Project : Class
---@overload fun(): Project
local Project = class:derive("Project")

local Station = require("Station")

function Project:new()
	self.stations = {
		Station("Pruszcz Gdański", "PrG")
	}
	---@type table<string, Station>
	self.stationsByID = {}
	self.currentStationID = "PrG"

	self:updateStationLists()
end

function Project:update(dt)
	-- Maybe we need updating all stations?
	self:getCurrentStation():update(dt)
end

function Project:getStation(shortcut)
	return self.stationsByID[shortcut]
end

function Project:getCurrentStation()
	return self:getStation(self.currentStationID)
end

function Project:setCurrentStation(shortcut)
	self.currentStationID = shortcut
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
	self:updateStationLists()
end

function Project:updateStationLists()
	self.stationsByID = {}
	for i, station in ipairs(self.stations) do
		self.stationsByID[station.shortcut] = station
	end
end

function Project:draw()
	self:getCurrentStation():draw()
end

function Project:keypressed(key)
	self:getCurrentStation():keypressed(key)
end

function Project:mousepressed(x, y, button)
	self:getCurrentStation():mousepressed(x, y, button)
end

function Project:save()
	_Utils.saveJson("savefile.json", self:serialize())
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
