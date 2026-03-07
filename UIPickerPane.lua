local Class = require("class")

---@class UIPickerPane : Class
---@overload fun(ui): UIPickerPane
local UIPickerPane = Class:derive("UIPickerPane")

---Constructs the UI picker pane.
---@param ui UI UI which owns this pane.
function UIPickerPane:new(ui)
    self.ui = ui

	self.ui:addPane(nil, "picker", nil, 0, 23, 30, 4)
	self.ui:addCheckbox("picker", "picker_electrified", "Tory zelektryfikowane", 0, 0, 1, 1, self, self.updateElectrified)
	self.ui.elements.picker_electrified.value = true
	-- First column
	self.ui:addLabel("picker", nil, "Nazwa toru", 0, 1, 5, 1)
	self.ui:addInput("picker", "picker_trackID", 5, 1, 5, 1, self, self.updateTrackID)
	self.ui:addLabel("picker", nil, "Nazwa zwr.", 0, 2, 5, 1)
	self.ui:addInput("picker", "picker_switchID", 5, 2, 5, 1, self, self.updateSwitchID)
	self.ui:addLabel("picker", nil, "Nazwa sem.", 0, 3, 5, 1)
	self.ui:addInput("picker", "picker_semaphoreID", 5, 3, 5, 1, self, self.updateSemaphoreID)
	-- Second column
	self.ui:addLabel("picker", nil, "Pkt końc izol.", 10, 0, 5, 1)
	self.ui:addInput("picker", "picker_itineraryEndID", 15, 0, 5, 1, self, self.updateItineraryEndID)
	self.ui:addLabel("picker", nil, "Zamień", 10, 2, 4, 1)
	self.ui:addCheckbox("picker", "picker_switchFlip", "+/-", 13, 2, 1, 1, self, self.updateSwitchFlip)
	self.ui:addCheckbox("picker", "picker_switchFlipABCD", "ab/cd", 16, 2, 1, 1, self, self.updateSwitchFlipABCD)
	-- Third column
	self.ui:addLabel("picker", nil, "Pkt końc.:", 20, 0, 5, 1)
	self.ui:addCheckbox("picker", "picker_trainTarget", "poc.", 24, 0, 1, 1, self, self.updateTrainTarget)
	self.ui:addCheckbox("picker", "picker_shuntTarget", "man.", 27, 0, 1, 1, self, self.updateShuntTarget)
	self.ui:addLabel("picker", nil, "Zakaz jaz.:", 20, 1, 5, 1)
	self.ui:addCheckbox("picker", "picker_forbidTrain", "poc.", 24, 1, 1, 1, self, self.updateForbidTrain)
	self.ui:addCheckbox("picker", "picker_forbidShunt", "man.", 27, 1, 1, 1, self, self.updateForbidShunt)
	self.ui:addLabel("picker", nil, "Vmax [km/h]", 20, 2, 5, 1)
	self.ui:addInput("picker", "picker_speed", 25, 2, 5, 1, self, self.updateMaxSpeed)
	self.ui:addLabel("picker", nil, "V+", 20, 3, 2, 1)
	self.ui:addInput("picker", "picker_speedPlus", 22, 3, 3, 1, self, self.updateMaxSpeedPlus)
	self.ui:addLabel("picker", nil, "V-", 25, 3, 2, 1)
	self.ui:addInput("picker", "picker_speedMinus", 27, 3, 3, 1, self, self.updateMaxSpeedMinus)
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

function UIPickerPane:updateMaxSpeed(input)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setMaxSpeed(tonumber(input.value))
	end
end

function UIPickerPane:updateMaxSpeedPlus(input)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setMaxSpeedPlus(tonumber(input.value))
	end
end

function UIPickerPane:updateMaxSpeedMinus(input)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setMaxSpeedMinus(tonumber(input.value))
	end
end

function UIPickerPane:updateTrainTarget(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setTrainTarget(checkbox.value)
	end
end

function UIPickerPane:updateShuntTarget(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setShuntTarget(checkbox.value)
	end
end

function UIPickerPane:updateForbidTrain(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setForbidTrain(checkbox.value)
	end
end

function UIPickerPane:updateForbidShunt(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setForbidShunt(checkbox.value)
	end
end

return UIPickerPane