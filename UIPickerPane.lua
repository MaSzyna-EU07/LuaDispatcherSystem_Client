local Class = require("class")

---@class UIPickerPane : Class
---@overload fun(ui): UIPickerPane
local UIPickerPane = Class:derive("UIPickerPane")

---Constructs the UI picker pane.
---@param ui UI UI which owns this pane.
function UIPickerPane:new(ui)
    self.ui = ui

	self.ui:addPane(nil, "picker", nil, 0, 23, 40, 6)
	-- First column
	self.ui:addCheckbox("picker", "electrified", "Tory zelektryfikowane", 0, 0, 1, 1, self, self.updateElectrified)
	self.ui.elements["picker/electrified"].value = true
	self.ui:addLabel("picker", nil, "Nazwa toru", 0, 1, 5, 1)
	self.ui:addInput("picker", "trackID", 5, 1, 5, 1, self, self.updateTrackID)
	self.ui:addLabel("picker", nil, "Nazwa zwr.", 0, 2, 5, 1)
	self.ui:addInput("picker", "switchID", 5, 2, 5, 1, self, self.updateSwitchID)
	self.ui:addLabel("picker", nil, "Nazwa sem.", 0, 3, 5, 1)
	self.ui:addInput("picker", "semaphoreID", 5, 3, 5, 1, self, self.updateSemaphoreID)
	self.ui:addLabel("picker", nil, "Punkt końc.", 0, 4, 5, 1)
	self.ui:addInput("picker", "itineraryEndID", 5, 4, 5, 1, self, self.updateItineraryEndID)
	self.ui:addLabel("picker", nil, "Sąsiednia st.:", 0, 5, 5, 1)
	self.ui:addInput("picker", "warp", 5, 5, 5, 1, self, self.updateWarp)
	-- Second column
	self.ui:addCheckbox("picker", "electrified2", "Elektr.", 10, 1, 1, 1, self, self.updateElectrified2)
	self.ui:addLabel("picker", nil, "Zamień", 10, 2, 4, 1)
	self.ui:addCheckbox("picker", "switchFlip", "+/-", 13, 2, 1, 1, self, self.updateSwitchFlip)
	self.ui:addCheckbox("picker", "switchFlipABCD", "ab/cd", 16, 2, 1, 1, self, self.updateSwitchFlipABCD)
	self.ui:addLabel("picker", nil, "Typ", 10, 3, 2, 1)
	self.ui:addInput("picker", "semaphoreType", 12, 3, 3, 1, self, self.updateSemaphoreType)
	self.ui.elements["picker/semaphoreType"].tip = "Typ semafora:\n0 = semafor\n1 = tarcza manewrowa"
	self.ui:addCheckbox("picker", "semaphoreNoW24", "Brak W24", 15, 3, 1, 1, self, self.updateSemaphoreNoW24)
	self.ui.elements["picker/semaphoreNoW24"].tip = "Odnosi się do semafora.\nOznacza, że dany semafor NIE posiada wskaźnika W24.\nTaki semafor nie może podać przebiegu wymagającego wyświetlenia tego wskaźnika."
	self.ui:addCheckbox("picker", "trainTarget", "poc.", 10, 4, 1, 1, self, self.updateTrainTarget)
	self.ui:addCheckbox("picker", "shuntTarget", "man.", 13, 4, 1, 1, self, self.updateShuntTarget)
	self.ui:addCheckbox("picker", "targetW24", "W24", 16, 4, 1, 1, self, self.updateTargetW24)
	self.ui.elements["picker/targetW24"].tip = "Odnosi się do punktu docelowego.\nJeżeli przebieg kończy się na tym punkcie, to na semaforze wyświetlony zostanie wskaźnik W24."
	self.ui:addLabel("picker", nil, "Komenda:", 10, 5, 4, 1)
	self.ui:addInput("picker", "command", 14, 5, 6, 1, self, self.updateCommand)
	-- Third column
	self.ui:addLabel("picker", nil, "Zakaz jaz.:", 20, 1, 5, 1)
	self.ui:addCheckbox("picker", "forbidTrain", "poc.", 24, 1, 1, 1, self, self.updateForbidTrain)
	self.ui:addCheckbox("picker", "forbidShunt", "man.", 27, 1, 1, 1, self, self.updateForbidShunt)
	self.ui:addLabel("picker", nil, "Vmax [km/h]", 20, 2, 5, 1)
	self.ui:addInput("picker", "speed", 25, 2, 5, 1, self, self.updateMaxSpeed)
	self.ui:addLabel("picker", nil, "V+", 20, 3, 2, 1)
	self.ui:addInput("picker", "speedPlus", 22, 3, 3, 1, self, self.updateMaxSpeedPlus)
	self.ui:addLabel("picker", nil, "V-", 25, 3, 2, 1)
	self.ui:addInput("picker", "speedMinus", 27, 3, 3, 1, self, self.updateMaxSpeedMinus)
	self.ui:addLabel("picker", nil, "Vskr", 20, 4, 2, 1)
	self.ui:addInput("picker", "semaphoreShortSpeed", 22, 4, 3, 1, self, self.updateSemaphoreShortSpeed)
	self.ui.elements["picker/semaphoreShortSpeed"].tip = "Prędkość dla skróconej drogi hamowania.\nWpisać identyfikator prędkości, nie samą prędkość!\n2 = 40 km/h\n3 = 60 km/h\n4 = 100 km/h"
	self.ui:addCheckbox("picker", "semaphoreFourPhase", "4-stawny", 25, 4, 1, 1, self, self.updateSemaphoreFourPhase)
	self.ui.elements["picker/semaphoreFourPhase"].tip = "Gdy zaznaczony i za dwa semafory jest S1, to zamiast S2 wyświetlony zostanie S3, zamiast S10 - S11, itp."
	-- Fourth column
	self.ui:addLabel("picker", nil, "Możliwość podania:", 30, 0, 10, 1)
	self.ui:addCheckbox("picker", "semaphoreAllowTrain", "poc.", 31, 1, 1, 1, self, self.updateSemaphoreAllowTrain)
	--self.ui.elements["picker/semaphoreAllowTrain"].tip = "Oznacza możliwość wyświetlenia sygnału zezwalającego na jazdę na tym semaforze (np. S2, S5, S13).\nNależy zaznaczyć dla sygnalizatorów półsamoczynnych i sygnalizatorów SBL.\nNie należy zaznaczać dla tarcz manewrowych, semaforów zaporowych i sygnalizatorów Sz."
	self.ui:addCheckbox("picker", "semaphoreAllowShunt", "man.", 34, 1, 1, 1, self, self.updateSemaphoreAllowShunt)
	--self.ui.elements["picker/semaphoreAllowShunt"].tip = "Oznacza możliwość wyświetlenia sygnału zezwalającego na manewry na tym semaforze (Ms2).\nNależy zaznaczyć dla większości semaforów, tarcz manewrowych i tarcz zaporowych.\nNie należy zaznaczać dla semaforów wjazdowych, semaforów bez indeksu \"m\", sygnalizatorów SBL i Sz."
	self.ui:addCheckbox("picker", "semaphoreAllowSz", "Sz", 37, 1, 1, 1, self, self.updateSemaphoreAllowSz)
	--self.ui.elements["picker/semaphoreAllowSz"].tip = "Oznacza możliwość wyświetlenia sygnału zastępczego na tym semaforze (Sz).\nNależy zaznaczyć dla większości semaforów i sygnalizatorów Sz.\nNie należy zaznaczać dla tarcz manewrowych i semaforów nieposiadających fizycznie komory białej (na posterunkach odstępowych, SBL)."
	self.ui:addCheckbox("picker", "semaphoreShape", "Kształ.", 30, 2, 1, 1, self, self.updateSemaphoreShape)
	--self.ui.elements["picker/semaphoreShape"].tip = "Oznacza semafor jako kształtowy.\nSemafory kształtowe nie mają uzależnienia od następnego semafora i potrafią wyświetlić tylko sygnały Sr1, Sr2 i Sr3.\nW chwili obecnej nie wpływa to na wygląd semafora na schemacie."
	self.ui:addCheckbox("picker", "semaphoreNoDanger", "Brak pom.g.k.", 34, 2, 1, 1, self, self.updateSemaphoreNoDanger)
	self.ui.elements["picker/semaphoreNoDanger"].tip = "Oznacza semafor jako nieposiadający górnej pomarańczowej komory.\nOznacza to, że pathfinder nie będzie w stanie wyświetlić sygnału zezwalającego na jazdę\njeżeli kolejny semafor nie zezwala na jazdę z prędkością 100km/h lub Vmax."
end

---Resets all property inputs to their default values.
function UIPickerPane:resetValues()
	self.ui.elements["picker/trackID"].value = ""
	self.ui.elements["picker/switchID"].value = ""
	self.ui.elements["picker/switchFlip"].value = false
	self.ui.elements["picker/switchFlipABCD"].value = false
	self.ui.elements["picker/semaphoreType"].value = ""
	self.ui.elements["picker/semaphoreNoW24"].value = false
	self.ui.elements["picker/semaphoreNoDanger"].value = false
	self.ui.elements["picker/semaphoreID"].value = ""
	self.ui.elements["picker/itineraryEndID"].value = ""
	self.ui.elements["picker/electrified2"].value = false
	self.ui.elements["picker/targetW24"].value = false
	self.ui.elements["picker/trainTarget"].value = false
	self.ui.elements["picker/shuntTarget"].value = false
	self.ui.elements["picker/forbidTrain"].value = false
	self.ui.elements["picker/forbidShunt"].value = false
	self.ui.elements["picker/speed"].value = ""
	self.ui.elements["picker/speedPlus"].value = ""
	self.ui.elements["picker/speedMinus"].value = ""
	self.ui.elements["picker/semaphoreAllowTrain"].value = false
	self.ui.elements["picker/semaphoreAllowShunt"].value = false
	self.ui.elements["picker/semaphoreAllowSz"].value = false
	self.ui.elements["picker/semaphoreShape"].value = false
	self.ui.elements["picker/semaphoreShortSpeed"].value = ""
	self.ui.elements["picker/semaphoreFourPhase"].value = false
	self.ui.elements["picker/warp"].value = ""
	self.ui.elements["picker/command"].value = ""
end

---Sets all property inputs to values from the specified tile.
---@param tile Tile The tile for which to set the input values.
function UIPickerPane:setValuesForTile(tile)
	self.ui.elements["picker/trackID"].value = tile:getTrackID() or ""
	self.ui.elements["picker/switchID"].value = tile:getSwitchID() or ""
	self.ui.elements["picker/switchFlip"].value = tile:getSwitchFlip()
	self.ui.elements["picker/switchFlipABCD"].value = tile:getSwitchFlipABCD()
	self.ui.elements["picker/semaphoreType"].value = tile:isSemaphore() and tostring(tile:getSemaphoreType()) or ""
	self.ui.elements["picker/semaphoreNoW24"].value = tile:getSemaphoreNoW24()
	self.ui.elements["picker/semaphoreNoDanger"].value = tile:getSemaphoreNoDanger()
	self.ui.elements["picker/semaphoreID"].value = tile:getSemaphoreID() or ""
	self.ui.elements["picker/itineraryEndID"].value = tile:getItineraryEndID() or ""
	self.ui.elements["picker/electrified2"].value = tile:isElectrified()
	self.ui.elements["picker/targetW24"].value = tile:isTargetW24()
	self.ui.elements["picker/trainTarget"].value = tile:isTrainTarget()
	self.ui.elements["picker/shuntTarget"].value = tile:isShuntTarget()
	self.ui.elements["picker/forbidTrain"].value = tile:isTrainForbidden()
	self.ui.elements["picker/forbidShunt"].value = tile:isShuntForbidden()
	self.ui.elements["picker/speed"].value = tile:getMaxSpeed() ~= math.huge and tostring(tile:getMaxSpeed()) or ""
	self.ui.elements["picker/speedPlus"].value = tile:getMaxSpeedPlus() ~= math.huge and tostring(tile:getMaxSpeedPlus()) or ""
	self.ui.elements["picker/speedMinus"].value = tile:getMaxSpeedMinus() ~= math.huge and tostring(tile:getMaxSpeedMinus()) or ""
	self.ui.elements["picker/semaphoreAllowTrain"].value = tile:getSemaphoreAllowTrain()
	self.ui.elements["picker/semaphoreAllowShunt"].value = tile:getSemaphoreAllowShunt()
	self.ui.elements["picker/semaphoreAllowSz"].value = tile:getSemaphoreAllowSz()
	self.ui.elements["picker/semaphoreShape"].value = tile:getSemaphoreShape()
	self.ui.elements["picker/semaphoreShortSpeed"].value = tile:getSemaphoreShortSpeed() and tostring(tile:getSemaphoreShortSpeed()) or ""
	self.ui.elements["picker/semaphoreFourPhase"].value = tile:getSemaphoreFourPhase()
	self.ui.elements["picker/warp"].value = tile:getWarp() or ""
	self.ui.elements["picker/command"].value = tile:getCommand() or ""
end

function UIPickerPane:updateElectrified(checkbox)
	_Picker.electrified = checkbox.value
end

function UIPickerPane:forEachTile(f)
	local station = _Project:getCurrentStation()
	if not station then
		return
	end
	for i, coords in ipairs(station.selectedTiles) do
		local tile = station:assertGetTile(coords.x, coords.y)
		f(tile)
	end
end

function UIPickerPane:updateTrackID(input)
	self:forEachTile(function(tile) tile:setTrackID(input.value) end)
end

function UIPickerPane:updateSwitchID(input)
	self:forEachTile(function(tile) tile:setSwitchID(input.value) end)
end

function UIPickerPane:updateSemaphoreID(input)
	self:forEachTile(function(tile) tile:setSemaphoreID(input.value) end)
end

function UIPickerPane:updateItineraryEndID(input)
	self:forEachTile(function(tile) tile:setItineraryEndID(input.value) end)
end

function UIPickerPane:updateElectrified2(checkbox)
	self:forEachTile(function(tile) tile:setElectrified(checkbox.value) end)
end

function UIPickerPane:updateTargetW24(checkbox)
	self:forEachTile(function(tile) tile:setTargetW24(checkbox.value) end)
end

function UIPickerPane:updateSwitchFlip(checkbox)
	self:forEachTile(function(tile) tile:setSwitchFlip(checkbox.value) end)
end

function UIPickerPane:updateSwitchFlipABCD(checkbox)
	self:forEachTile(function(tile) tile:setSwitchFlipABCD(checkbox.value) end)
end

function UIPickerPane:updateSemaphoreType(input)
	self:forEachTile(function(tile) tile:setSemaphoreType(tonumber(input.value)) end)
end

function UIPickerPane:updateSemaphoreNoW24(checkbox)
	self:forEachTile(function(tile) tile:setSemaphoreNoW24(checkbox.value) end)
end

function UIPickerPane:updateSemaphoreNoDanger(checkbox)
	self:forEachTile(function(tile) tile:setSemaphoreNoDanger(checkbox.value) end)
end

function UIPickerPane:updateMaxSpeed(input)
	self:forEachTile(function(tile) tile:setMaxSpeed(tonumber(input.value)) end)
end

function UIPickerPane:updateMaxSpeedPlus(input)
	self:forEachTile(function(tile) tile:setMaxSpeedPlus(tonumber(input.value)) end)
end

function UIPickerPane:updateMaxSpeedMinus(input)
	self:forEachTile(function(tile) tile:setMaxSpeedMinus(tonumber(input.value)) end)
end

function UIPickerPane:updateTrainTarget(checkbox)
	self:forEachTile(function(tile) tile:setTrainTarget(checkbox.value) end)
end

function UIPickerPane:updateShuntTarget(checkbox)
	self:forEachTile(function(tile) tile:setShuntTarget(checkbox.value) end)
end

function UIPickerPane:updateForbidTrain(checkbox)
	self:forEachTile(function(tile) tile:setForbidTrain(checkbox.value) end)
end

function UIPickerPane:updateForbidShunt(checkbox)
	self:forEachTile(function(tile) tile:setForbidShunt(checkbox.value) end)
end

function UIPickerPane:updateSemaphoreAllowTrain(checkbox)
	self:forEachTile(function(tile) tile:setSemaphoreAllowTrain(checkbox.value) end)
end

function UIPickerPane:updateSemaphoreAllowShunt(checkbox)
	self:forEachTile(function(tile) tile:setSemaphoreAllowShunt(checkbox.value) end)
end

function UIPickerPane:updateSemaphoreAllowSz(checkbox)
	self:forEachTile(function(tile) tile:setSemaphoreAllowSz(checkbox.value) end)
end

function UIPickerPane:updateSemaphoreShape(checkbox)
	self:forEachTile(function(tile) tile:setSemaphoreShape(checkbox.value) end)
end

function UIPickerPane:updateSemaphoreShortSpeed(input)
	self:forEachTile(function(tile) tile:setSemaphoreShortSpeed(tonumber(input.value)) end)
end

function UIPickerPane:updateSemaphoreFourPhase(checkbox)
	self:forEachTile(function(tile) tile:setSemaphoreFourPhase(checkbox.value) end)
end

function UIPickerPane:updateWarp(input)
	self:forEachTile(function(tile) tile:setWarp(input.value) end)
end

function UIPickerPane:updateCommand(input)
	self:forEachTile(function(tile) tile:setCommand(input.value) end)
end

return UIPickerPane