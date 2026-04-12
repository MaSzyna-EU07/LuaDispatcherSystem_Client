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

	self.ui:addButton("train", "horn", "Zatrąb", 0, 1, 5, 1, nil, function() self:sendToCurrentTrain("Warning_signal", 1, 1) end)
	self.ui:addButton("train", "radiostop", "RADIOSTOP!", 5, 1, 5, 1, nil, function() self:sendToCurrentTrain("Emergency_brake", 0, 0) end)

	self.timetableID = self.ui:addInput("train", "timetable_id", 0, 2, 5, 1, nil)
	self.ui:addButton("train", "timetable", "Nadaj rozkład", 5, 2, 5, 1, nil, function() self:sendToCurrentTrain("Timetable:luascript/" .. self.timetableID.value, 0, 0) end)

	self.ui:addButton("train", "on", "Włącz pojazd", 0, 3, 5, 1, nil, function() self:sendToCurrentTrain("Prepare_engine", 1, 0) end)
	self.ui:addButton("train", "off", "Wyłącz pojazd", 5, 3, 5, 1, nil, function() self:sendToCurrentTrain("Prepare_engine", 0, 0) end)

	self.ui:addButton("train", "pc2", "Pc2", 0, 4, 5, 1, nil, function() self:sendToCurrentTrain("SetLights", 22, -1) end)
	self.ui:addButton("train", "pc1", "Pc1", 5, 4, 5, 1, nil, function() self:sendToCurrentTrain("SetLights", 21, -1) end)

	self.ui:addButton("train", "wait", "Usuń rozkazy", 0, 5, 5, 1, nil, function() self:sendToCurrentTrain("Wait_for_orders", 0, 0) end)
	self.ui:addButton("train", "shp", "SHP", 5, 5, 5, 1, nil, function() self:sendToCurrentTrain("CabSignal", -1, -1) end)

	self.shuntP1 = self.ui:addInput("train", "shunt_p1", 0, 6, 3, 1, nil)
	self.shuntP2 = self.ui:addInput("train", "shunt_p2", 3, 6, 3, 1, nil)
	self.ui:addButton("train", "shunt", "Shunt", 6, 6, 4, 1, nil, function() self:sendToCurrentTrain("Shunt", tonumber(self.shuntP1.value), tonumber(self.shuntP2.value)); self.shuntP1.value = ""; self.shuntP2.value = "" end)

	self.ui:addButton("train", "shunt_disconnect", "Rozłącz (N)", 0, 7, 5, 1, nil, function() self:sendToCurrentTrain("Shunt", tonumber(self.shuntDisconnectN.value) or 0, 0); self.shuntDisconnectN.value = "" end)
	self.shuntDisconnectN = self.ui:addInput("train", "shunt_disconnect_n", 5, 7, 5, 1, nil)

	self.ui:addButton("train", "shunt_connect_1", "Podł. i spychaj", 0, 8, 5, 1, nil, function() self:sendToCurrentTrain("Shunt", -1, 3) end)
	self.ui:addButton("train", "shunt_connect_2", "Podł. i ciągnij", 5, 8, 5, 1, nil, function() self:sendToCurrentTrain("Shunt", -1, -3) end)

	self.ui:addButton("train", "shunt_connect_3", "Podł. i czekaj", 0, 9, 5, 1, nil, function() self:sendToCurrentTrain("Shunt", -2, 3) end)
	self.ui:addButton("train", "shunt_connect_4", "Podł. i koniec", 5, 9, 5, 1, nil, function() self:sendToCurrentTrain("Shunt", -3, 3) end)

	self.ui:addButton("train", "shunt_stop", "Stój", 0, 10, 5, 1, nil, function() self:sendToCurrentTrain("ShuntVelocity", 0, 0) end)
	self.ui:addButton("train", "change_dir", "Zmień kierun.", 5, 10, 5, 1, nil, function() self:sendToCurrentTrain("Change_direction", 0, 0) end)
end

---Sends a command to all trains on all selected tiles.
---@private
---@param str string The command string.
---@param num1 number? The first number.
---@param num2 number? The second number.
function UITrainPane:sendToCurrentTrain(str, num1, num2)
	local station = _Project:getCurrentStation()
	if not station then
		return
	end
	for i, tile in ipairs(station.selectedTiles) do
		tile:sendTrainCommand(str, num1, num2)
	end
end

return UITrainPane