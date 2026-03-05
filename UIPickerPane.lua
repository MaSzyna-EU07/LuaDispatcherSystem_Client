local Class = require("class")

---@class UIPickerPane : Class
---@overload fun(ui): UIPickerPane
local UIPickerPane = Class:derive("UIPickerPane")

---Constructs the UI picker pane.
---@param ui UI UI which owns this pane.
function UIPickerPane:new(ui)
    self.ui = ui

	self.ui:addPane(nil, "picker", nil, 0, 23, 20, 4)
	self.ui:addCheckbox("picker", "picker_electrified", "Tory zelektryfikowane", 0, 0, 1, 1, self, self.updateElectrified)
	self.ui.elements.picker_electrified.value = true
	self.ui:addLabel("picker", nil, "Nazwa toru", 0, 1, 5, 1)
	self.ui:addInput("picker", "picker_trackID", 5, 1, 5, 1, self, self.updateTrackID)
	self.ui:addLabel("picker", nil, "Nazwa zwr.", 0, 2, 5, 1)
	self.ui:addInput("picker", "picker_switchID", 5, 2, 5, 1, self, self.updateSwitchID)
	self.ui:addLabel("picker", nil, "Nazwa sem.", 0, 3, 5, 1)
	self.ui:addInput("picker", "picker_semaphoreID", 5, 3, 5, 1, self, self.updateSemaphoreID)
	self.ui:addLabel("picker", nil, "Pkt końc izol.", 10, 1, 5, 1)
	self.ui:addInput("picker", "picker_itineraryEndID", 15, 1, 5, 1, self, self.updateItineraryEndID)
	self.ui:addLabel("picker", nil, "Zamień:", 10, 2, 5, 1)
	self.ui:addCheckbox("picker", "picker_switchFlip", "+/-", 15, 2, 1, 1, self, self.updateSwitchFlip)
	self.ui:addCheckbox("picker", "picker_switchFlipABCD", "ab/cd", 15, 3, 1, 1, self, self.updateSwitchFlipABCD)
end

function UIPickerPane:updateElectrified(checkbox)
	_Picker.electrified = checkbox.value
end

function UIPickerPane:updateTrackID(input)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setTrackID(input.value)
	end
end

function UIPickerPane:updateSwitchID(input)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSwitchID(input.value)
	end
end

function UIPickerPane:updateSemaphoreID(input)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSemaphoreID(input.value)
	end
end

function UIPickerPane:updateItineraryEndID(input)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setItineraryEndID(input.value)
	end
end

function UIPickerPane:updateSwitchFlip(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSwitchFlip(checkbox.value)
	end
end

function UIPickerPane:updateSwitchFlipABCD(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSwitchFlipABCD(checkbox.value)
	end
end

return UIPickerPane