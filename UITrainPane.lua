local Class = require("class")

---@class UITrainPane : Class
---@overload fun(ui): UITrainPane
local UITrainPane = Class:derive("UITrainPane")

---Constructs the UI bottom pane.
---@param ui UI UI which owns this pane.
function UITrainPane:new(ui)
    self.ui = ui

	self.ui:addPane(nil, "train", nil, 42, 23, 10, 12)
	self.ui:addLabel("train", nil, "Komendy pociągów", 0, 0, 10, 1)

	self.ui:addButton("train", "train_horn", "Zatrąb", 0, 1, 5, 1, nil, function() self:sendToCurrentTrain("Warning_signal", 1, 1) end)
	self.ui:addButton("train", "train_radiostop", "RADIOSTOP!", 5, 1, 5, 1, nil, function() self:sendToCurrentTrain("Emergency_brake", 0, 0) end)

	self.ui:addInput("train", "train_timetable_id", 0, 2, 5, 1, nil)
	self.ui:addButton("train", "train_timetable", "Nadaj rozkład", 5, 2, 5, 1, nil, function() self:sendToCurrentTrain("Timetable:luascript/" .. self.ui.elements.train_timetable_id.value, 0, 0) end)

	self.ui:addButton("train", "train_on", "Włącz pojazd", 0, 3, 5, 1, nil, function() self:sendToCurrentTrain("Prepare_engine", 1, 0) end)
	self.ui:addButton("train", "train_off", "Wyłącz pojazd", 5, 3, 5, 1, nil, function() self:sendToCurrentTrain("Prepare_engine", 0, 0) end)

	self.ui:addButton("train", "train_pc2", "Pc2", 0, 4, 5, 1, nil, function() self:sendToCurrentTrain("SetLights", 22, -1) end)
	self.ui:addButton("train", "train_pc1", "Pc1", 5, 4, 5, 1, nil, function() self:sendToCurrentTrain("SetLights", 21, -1) end)

	self.ui:addButton("train", "train_change_dir", "Zmień kierunek", 0, 5, 5, 1, nil, function() self:sendToCurrentTrain("Change_direction", 0, 0) end)
	self.ui:addButton("train", "train_shp", "SHP", 5, 5, 5, 1, nil, function() self:sendToCurrentTrain("CabSignal", -1, -1) end)

	self.ui:addInput("train", "train_shunt_p1", 0, 6, 3, 1, nil)
	self.ui:addInput("train", "train_shunt_p2", 3, 6, 3, 1, nil)
	self.ui:addButton("train", "train_shunt", "Shunt", 6, 6, 4, 1, nil, function() self:sendToCurrentTrain("Shunt", tonumber(self.ui.elements.train_shunt_p1.value), tonumber(self.ui.elements.train_shunt_p2.value)) end)
end

---Sends a command to all trains on all selected tiles.
---@private
---@param str string The command string.
---@param num1 number? The first number.
---@param num2 number? The second number.
function UITrainPane:sendToCurrentTrain(str, num1, num2)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		assert(station:getTile(coords.x, coords.y)):sendTrainCommand(str, num1, num2)
	end
end

return UITrainPane