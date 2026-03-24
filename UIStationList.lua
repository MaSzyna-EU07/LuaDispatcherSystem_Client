local Class = require("class")

---@class UIStationList : Class
---@overload fun(ui): UIStationList
local UIStationList = Class:derive("UIStationList")

---Constructs the UI station list.
---@param ui UI UI which owns this window.
function UIStationList:new(ui)
    self.ui = ui
	self.entries = {}

	self.window = self.ui:createCenteredWindow("sl", "Lista stacji", 25, 20)
	self.ui:addLabel("sl", nil, "Stacje", 0, 1, 12, 1)
	self.stations = self.ui:addComboBox("sl", "stations", 0, 2, 12, 17)

	-- Add a station, rename a station and go to station
	self.ui:addButton("sl", "bAdd", "Dodaj stację", 0, 19, 12, 1, self, self.addStation)

	self.ui:addLabel("sl", nil, "Nazwa", 12, 1, 4, 1)
	self.name = self.ui:addInput("sl", "name", 16, 1, 9, 1, self, nil, self.saveStation)
	self.ui:addLabel("sl", nil, "Identyfikator", 12, 2, 8, 1)
	self.id = self.ui:addInput("sl", "id", 20, 2, 5, 1, self, nil, self.saveStation)
	self.ui:addButton("sl", "bSave", "Zapisz zmiany", 13, 5, 11, 1, self, self.saveStation)
	self.ui:addButton("sl", "bGo", "Skocz do stacji", 13, 6, 11, 1, self, self.goToStation)
	self.ui:addButton("sl", nil, "Usuń stację", 13, 14, 11, 1)

	self:update()
	self.window:hide()
end

function UIStationList:show()
	self.window:show()
	self.window:setlevel()
	self.stations.scrollh:hide()
	self:update()
end

function UIStationList:update()
    local gui = self.ui:getGUI()
	for i, entry in ipairs(self.entries) do
		gui:rem(entry)
	end
	self.entries = {}
	for i, station in ipairs(_Project.stations) do
		local entry = gui:option(station:getFullName(), {0, self.ui.U * (i - 1), self.ui.U * 12 - self.ui.U, self.ui.U}, self.stations, station.shortcut)
		entry.click = function(this)
			this.parent.value = this.value
			self:onEntrySelected(station.shortcut)
		end
		entry.dblclick = function(this)
			self:goToStation()
		end
		table.insert(self.entries, entry)
	end
	-- Set stuff up by updating data about the currently selected station.
	--self.stations.value = _Project.currentStationID
	self:onEntrySelected(self.stations.value or _Project.currentStationID)
end

function UIStationList:onEntrySelected(shortcut)
	local station = _Project:getStation(shortcut)
	self.name.value = station and station.name or ""
	self.id.value = shortcut or ""
end

function UIStationList:addStation()
	_Project:addStation()
	self:update()
end

---Saves the changes made in the station list to the currently selected station.
function UIStationList:saveStation()
	_Project:renameStation(self.stations.value, self.name.value, self.id.value)
	-- Select the renamed entry, otherwise an error will appear.
	self.stations.value = self.id.value
	self:update()
end

---Sets the project's current station to the selected station.
function UIStationList:goToStation()
	_Project:setCurrentStation(self.stations.value)
	self.window:hide()
end

return UIStationList