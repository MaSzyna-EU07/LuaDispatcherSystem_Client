local Class = require("lua.core.class")

---@class UIStationList : Class
---@overload fun(ui): UIStationList
local UIStationList = Class:derive("UIStationList")

---Constructs the UI station list.
---@param ui UI UI which owns this window.
function UIStationList:new(ui)
    self.ui = ui

	self.window = self.ui:createCenteredWindow("sl", "Lista stacji", 30, 20)
	self.ui:addLabel("sl", nil, "Stacje", 0, 1, 17, 1)
	self.stations = self.ui:addComboBox("sl", "stations", 0, 2, 17, 17)

	-- Add a station, rename a station and go to station
	self.ui:addButton("sl", "bAdd", "Dodaj stację", 0, 19, 17, 1, self, self.addStation)

	self.ui:addLabel("sl", nil, "Nazwa", 17, 1, 4, 1)
	self.name = self.ui:addInput("sl", "name", 21, 1, 9, 1, self, nil, self.saveStation)
	self.ui:addLabel("sl", nil, "Identyfikator", 17, 2, 8, 1)
	self.id = self.ui:addInput("sl", "id", 25, 2, 5, 1, self, nil, self.saveStation)
	self.ui:addButton("sl", "bSave", "Zapisz zmiany", 18, 5, 11, 1, self, self.saveStation)
	self.ui:addButton("sl", "bGo", "Skocz do stacji", 18, 6, 11, 1, self, self.goToStation)
	self.ui:addButton("sl", "bMoveUp", "Przenieś do góry", 18, 7, 11, 1, self, self.moveStationUp)
	self.ui:addButton("sl", "bMoveDown", "Przenieś na dół", 18, 8, 11, 1, self, self.moveStationDown)
	self.ui:addButton("sl", nil, "Usuń stację", 18, 14, 11, 1, self, self.deleteStation)
end

---Shows this window.
function UIStationList:show()
	self.window:show()
	self.window:setlevel()
	self.stations.scrollh:hide()
	self:updateList()
	self:selectCurrentStation()
end

---Hides this window.
function UIStationList:hide()
	self.window:hide()
end

function UIStationList:updateList()
	self.ui:removeElementChildren("sl/stations")
	for i, station in ipairs(_Project:getStations()) do
		self.ui:addEntry("sl/stations", station.shortcut, station:getFullName(), 0, i - 1, 16, 1, self, self.onEntrySelected, self.goToStation)
	end
end

function UIStationList:selectCurrentStation()
	self:select(_Project.currentStationID)
end

function UIStationList:onEntrySelected(entry)
	self:select(entry.value)
end

function UIStationList:select(shortcut)
	local station = _Project:getStation(shortcut)
	self.name.value = station and station.name or ""
	self.id.value = shortcut or ""
	self.stations.value = shortcut
end

function UIStationList:addStation()
	_Project:addStation()
	self:updateList()
end

---Saves the changes made in the station list to the currently selected station.
function UIStationList:saveStation()
	if _Project:getStation(self.id.value) then
		-- This check exists so that pressing Enter straight away does not display this message.
		if self.stations.value ~= self.id.value then
			_Notifications:post(string.format("Skrót stacji `%s` jest już zajęty!", self.id.value), NotificationColor.RED)
		end
		return
	end
	_Project:renameStation(self.stations.value, self.name.value, self.id.value)
	-- Select the renamed entry, otherwise an error will appear.
	self.stations.value = self.id.value
	self:updateList()
end

---Sets the project's current station to the selected station.
function UIStationList:goToStation()
	_Project:setCurrentStation(self.stations.value)
	self:hide()
end

---Moves the selected station up on the list.
function UIStationList:moveStationUp()
	_Project:moveStationUp(self.stations.value)
	self:updateList()
end

---Moves the selected station down on the list.
function UIStationList:moveStationDown()
	_Project:moveStationDown(self.stations.value)
	self:updateList()
end

---Deletes the selected station from the project.
function UIStationList:deleteStation()
	_Project:deleteStation(self.stations.value)
	self:updateList()
end

return UIStationList