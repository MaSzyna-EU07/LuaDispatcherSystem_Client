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
	self.electrified = self.ui:addCheckbox("picker", "electrified", "Tory zelektryfikowane", 0, 0, 1, 1, self, self.updateElectrified)
	self.electrified.value = true
	self.ui:addLabel("picker", nil, "Nazwa toru", 0, 1, 5, 1)
	self.trackID = self.ui:addInput("picker", "trackID", 5, 1, 5, 1, self, self.updateTrackID)
	self.ui:addLabel("picker", nil, "Nazwa zwr.", 0, 2, 5, 1)
	self.switchID = self.ui:addInput("picker", "switchID", 5, 2, 5, 1, self, self.updateSwitchID)
	self.ui:addLabel("picker", nil, "Nazwa sem.", 0, 3, 5, 1)
	self.semaphoreID = self.ui:addInput("picker", "semaphoreID", 5, 3, 5, 1, self, self.updateSemaphoreID)
	self.ui:addLabel("picker", nil, "Punkt końc.", 0, 4, 5, 1)
	self.itineraryEndID = self.ui:addInput("picker", "itineraryEndID", 5, 4, 5, 1, self, self.updateItineraryEndID)
	self.ui:addLabel("picker", nil, "Sąsiednia st.:", 0, 5, 5, 1)
	self.warp = self.ui:addInput("picker", "warp", 5, 5, 5, 1, self, self.updateWarp)
	-- Second column
	self.electrified2 = self.ui:addCheckbox("picker", "electrified2", "Elektr.", 10, 1, 1, 1, self, self.updateElectrified2)
	self.ui:addLabel("picker", nil, "Zamień", 10, 2, 4, 1)
	self.switchFlip = self.ui:addCheckbox("picker", "switchFlip", "+/-", 13, 2, 1, 1, self, self.updateSwitchFlip)
	self.switchFlipABCD = self.ui:addCheckbox("picker", "switchFlipABCD", "ab/cd", 16, 2, 1, 1, self, self.updateSwitchFlipABCD)
	self.ui:addLabel("picker", nil, "Typ", 10, 3, 2, 1)
	self.semaphoreType = self.ui:addInput("picker", "semaphoreType", 12, 3, 3, 1, self, self.updateSemaphoreType)
	self.semaphoreType.tip = "Typ semafora:\n0 = semafor\n1 = tarcza manewrowa"
	self.semaphoreNoW24 = self.ui:addCheckbox("picker", "semaphoreNoW24", "Brak W24", 15, 3, 1, 1, self, self.updateSemaphoreNoW24)
	self.semaphoreNoW24.tip = "Odnosi się do semafora.\nOznacza, że dany semafor NIE posiada wskaźnika W24.\nTaki semafor nie może podać przebiegu wymagającego wyświetlenia tego wskaźnika."
	self.trainTarget = self.ui:addCheckbox("picker", "trainTarget", "poc.", 10, 4, 1, 1, self, self.updateTrainTarget)
	self.shuntTarget = self.ui:addCheckbox("picker", "shuntTarget", "man.", 13, 4, 1, 1, self, self.updateShuntTarget)
	self.targetW24 = self.ui:addCheckbox("picker", "targetW24", "W24", 16, 4, 1, 1, self, self.updateTargetW24)
	self.targetW24.tip = "Odnosi się do punktu docelowego.\nJeżeli przebieg kończy się na tym punkcie, to na semaforze wyświetlony zostanie wskaźnik W24."
	self.ui:addLabel("picker", nil, "Komenda:", 10, 5, 4, 1)
	self.command = self.ui:addInput("picker", "command", 14, 5, 6, 1, self, self.updateCommand)
	-- Third column
	self.ui:addLabel("picker", nil, "Zakaz jaz.:", 20, 1, 5, 1)
	self.forbidTrain = self.ui:addCheckbox("picker", "forbidTrain", "poc.", 24, 1, 1, 1, self, self.updateForbidTrain)
	self.forbidShunt = self.ui:addCheckbox("picker", "forbidShunt", "man.", 27, 1, 1, 1, self, self.updateForbidShunt)
	self.ui:addLabel("picker", nil, "Vmax [km/h]", 20, 2, 5, 1)
	self.speed = self.ui:addInput("picker", "speed", 25, 2, 5, 1, self, self.updateMaxSpeed)
	self.ui:addLabel("picker", nil, "V+", 20, 3, 2, 1)
	self.speedPlus = self.ui:addInput("picker", "speedPlus", 22, 3, 3, 1, self, self.updateMaxSpeedPlus)
	self.ui:addLabel("picker", nil, "V-", 25, 3, 2, 1)
	self.speedMinus = self.ui:addInput("picker", "speedMinus", 27, 3, 3, 1, self, self.updateMaxSpeedMinus)
	self.ui:addLabel("picker", nil, "Vskr", 20, 4, 2, 1)
	self.semaphoreShortSpeed = self.ui:addInput("picker", "semaphoreShortSpeed", 22, 4, 3, 1, self, self.updateSemaphoreShortSpeed)
	self.semaphoreShortSpeed.tip = "Prędkość dla skróconej drogi hamowania.\nWpisać identyfikator prędkości, nie samą prędkość!\n2 = 40 km/h\n3 = 60 km/h\n4 = 100 km/h"
	self.semaphoreFourPhase = self.ui:addCheckbox("picker", "semaphoreFourPhase", "4-stawny", 25, 4, 1, 1, self, self.updateSemaphoreFourPhase)
	self.semaphoreFourPhase.tip = "Gdy zaznaczony i za dwa semafory jest S1, to zamiast S2 wyświetlony zostanie S3, zamiast S10 - S11, itp."
	-- Fourth column
	self.ui:addLabel("picker", nil, "Możliwość podania:", 30, 0, 10, 1)
	self.semaphoreAllowTrain = self.ui:addCheckbox("picker", "semaphoreAllowTrain", "poc.", 31, 1, 1, 1, self, self.updateSemaphoreAllowTrain)
	--self.semaphoreAllowTrain.tip = "Oznacza możliwość wyświetlenia sygnału zezwalającego na jazdę na tym semaforze (np. S2, S5, S13).\nNależy zaznaczyć dla sygnalizatorów półsamoczynnych i sygnalizatorów SBL.\nNie należy zaznaczać dla tarcz manewrowych, semaforów zaporowych i sygnalizatorów Sz."
	self.semaphoreAllowShunt = self.ui:addCheckbox("picker", "semaphoreAllowShunt", "man.", 34, 1, 1, 1, self, self.updateSemaphoreAllowShunt)
	--self.semaphoreAllowShunt.tip = "Oznacza możliwość wyświetlenia sygnału zezwalającego na manewry na tym semaforze (Ms2).\nNależy zaznaczyć dla większości semaforów, tarcz manewrowych i tarcz zaporowych.\nNie należy zaznaczać dla semaforów wjazdowych, semaforów bez indeksu \"m\", sygnalizatorów SBL i Sz."
	self.semaphoreAllowSz = self.ui:addCheckbox("picker", "semaphoreAllowSz", "Sz", 37, 1, 1, 1, self, self.updateSemaphoreAllowSz)
	--self.semaphoreAllowSz.tip = "Oznacza możliwość wyświetlenia sygnału zastępczego na tym semaforze (Sz).\nNależy zaznaczyć dla większości semaforów i sygnalizatorów Sz.\nNie należy zaznaczać dla tarcz manewrowych i semaforów nieposiadających fizycznie komory białej (na posterunkach odstępowych, SBL)."
	self.semaphoreShape = self.ui:addCheckbox("picker", "semaphoreShape", "Kształ.", 30, 2, 1, 1, self, self.updateSemaphoreShape)
	--self.semaphoreShape.tip = "Oznacza semafor jako kształtowy.\nSemafory kształtowe nie mają uzależnienia od następnego semafora i potrafią wyświetlić tylko sygnały Sr1, Sr2 i Sr3.\nW chwili obecnej nie wpływa to na wygląd semafora na schemacie."
	self.semaphoreNoDanger = self.ui:addCheckbox("picker", "semaphoreNoDanger", "Brak pom.g.k.", 34, 2, 1, 1, self, self.updateSemaphoreNoDanger)
	self.semaphoreNoDanger.tip = "Oznacza semafor jako nieposiadający górnej pomarańczowej komory.\nOznacza to, że pathfinder nie będzie w stanie wyświetlić sygnału zezwalającego na jazdę\njeżeli kolejny semafor nie zezwala na jazdę z prędkością 100km/h lub Vmax."
end

---Resets all property inputs to their default values.
function UIPickerPane:resetValues()
	self.trackID.value = ""
	self.switchID.value = ""
	self.switchFlip.value = false
	self.switchFlipABCD.value = false
	self.semaphoreType.value = ""
	self.semaphoreNoW24.value = false
	self.semaphoreNoDanger.value = false
	self.semaphoreID.value = ""
	self.itineraryEndID.value = ""
	self.electrified2.value = false
	self.targetW24.value = false
	self.trainTarget.value = false
	self.shuntTarget.value = false
	self.forbidTrain.value = false
	self.forbidShunt.value = false
	self.speed.value = ""
	self.speedPlus.value = ""
	self.speedMinus.value = ""
	self.semaphoreAllowTrain.value = false
	self.semaphoreAllowShunt.value = false
	self.semaphoreAllowSz.value = false
	self.semaphoreShape.value = false
	self.semaphoreShortSpeed.value = ""
	self.semaphoreFourPhase.value = false
	self.warp.value = ""
	self.command.value = ""
end

---Sets all property inputs to values from the specified tile.
---@param tile Tile The tile for which to set the input values.
function UIPickerPane:setValuesForTile(tile)
	self.trackID.value = tile.trackID or ""
	self.switchID.value = tile.switchID or ""
	self.switchFlip.value = tile.switchFlip
	self.switchFlipABCD.value = tile.switchFlipABCD
	self.semaphoreType.value = tile:isSemaphore() and tostring(tile.semaphoreType) or ""
	self.semaphoreNoW24.value = tile.semaphoreNoW24
	self.semaphoreNoDanger.value = tile.semaphoreNoDanger
	self.semaphoreID.value = tile.semaphoreID or ""
	self.itineraryEndID.value = tile.itineraryEndID or ""
	self.electrified2.value = tile.electrified
	self.targetW24.value = tile.targetW24
	self.trainTarget.value = tile.trainTarget
	self.shuntTarget.value = tile.shuntTarget
	self.forbidTrain.value = tile.forbidTrain
	self.forbidShunt.value = tile.forbidShunt
	self.speed.value = tile.maxSpeed ~= math.huge and tostring(tile.maxSpeed) or ""
	self.speedPlus.value = tile.maxSpeedPlus ~= math.huge and tostring(tile.maxSpeedPlus) or ""
	self.speedMinus.value = tile.maxSpeedMinus ~= math.huge and tostring(tile.maxSpeedMinus) or ""
	self.semaphoreAllowTrain.value = tile.semaphoreAllowTrain
	self.semaphoreAllowShunt.value = tile.semaphoreAllowShunt
	self.semaphoreAllowSz.value = tile.semaphoreAllowSz
	self.semaphoreShape.value = tile.semaphoreShape
	self.semaphoreShortSpeed.value = tile.semaphoreShortSpeed and tostring(tile.semaphoreShortSpeed) or ""
	self.semaphoreFourPhase.value = tile.semaphoreFourPhase
	self.warp.value = tile.warp or ""
	self.command.value = tile.command or ""
end

function UIPickerPane:updateElectrified(checkbox)
	_Picker.electrified = checkbox.value
end

---Executes a function for each selected tile.
---@param f fun(tile: Tile) The function to be executed.
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
	self:forEachTile(function(tile) tile.trackID = input.value ~= "" and input.value or nil end)
end

function UIPickerPane:updateSwitchID(input)
	self:forEachTile(function(tile) tile.switchID = input.value ~= "" and input.value or nil end)
end

function UIPickerPane:updateSemaphoreID(input)
	self:forEachTile(function(tile) tile.semaphoreID = input.value ~= "" and input.value or nil end)
end

function UIPickerPane:updateItineraryEndID(input)
	self:forEachTile(function(tile) tile.itineraryEndID = input.value ~= "" and input.value or nil end)
end

function UIPickerPane:updateElectrified2(checkbox)
	self:forEachTile(function(tile) tile.electrified = checkbox.value end)
end

function UIPickerPane:updateTargetW24(checkbox)
	self:forEachTile(function(tile) tile.targetW24 = checkbox.value end)
end

function UIPickerPane:updateSwitchFlip(checkbox)
	self:forEachTile(function(tile) tile.switchFlip = checkbox.value end)
end

function UIPickerPane:updateSwitchFlipABCD(checkbox)
	self:forEachTile(function(tile) tile.switchFlipABCD = checkbox.value end)
end

function UIPickerPane:updateSemaphoreType(input)
	self:forEachTile(function(tile) tile.semaphoreType = tonumber(input.value) end)
end

function UIPickerPane:updateSemaphoreNoW24(checkbox)
	self:forEachTile(function(tile) tile.semaphoreNoW24 = checkbox.value end)
end

function UIPickerPane:updateSemaphoreNoDanger(checkbox)
	self:forEachTile(function(tile) tile.semaphoreNoDanger = checkbox.value end)
end

function UIPickerPane:updateMaxSpeed(input)
	self:forEachTile(function(tile) tile.maxSpeed = tonumber(input.value) or math.huge end)
end

function UIPickerPane:updateMaxSpeedPlus(input)
	self:forEachTile(function(tile) tile.maxSpeedPlus = tonumber(input.value) or math.huge end)
end

function UIPickerPane:updateMaxSpeedMinus(input)
	self:forEachTile(function(tile) tile.maxSpeedMinus = tonumber(input.value) or math.huge end)
end

function UIPickerPane:updateTrainTarget(checkbox)
	self:forEachTile(function(tile) tile.trainTarget = checkbox.value end)
end

function UIPickerPane:updateShuntTarget(checkbox)
	self:forEachTile(function(tile) tile.shuntTarget = checkbox.value end)
end

function UIPickerPane:updateForbidTrain(checkbox)
	self:forEachTile(function(tile) tile.forbidTrain = checkbox.value end)
end

function UIPickerPane:updateForbidShunt(checkbox)
	self:forEachTile(function(tile) tile.forbidShunt = checkbox.value end)
end

function UIPickerPane:updateSemaphoreAllowTrain(checkbox)
	self:forEachTile(function(tile) tile.semaphoreAllowTrain = checkbox.value end)
end

function UIPickerPane:updateSemaphoreAllowShunt(checkbox)
	self:forEachTile(function(tile) tile.semaphoreAllowShunt = checkbox.value end)
end

function UIPickerPane:updateSemaphoreAllowSz(checkbox)
	self:forEachTile(function(tile) tile.semaphoreAllowSz = checkbox.value end)
end

function UIPickerPane:updateSemaphoreShape(checkbox)
	self:forEachTile(function(tile) tile.semaphoreShape = checkbox.value end)
end

function UIPickerPane:updateSemaphoreShortSpeed(input)
	self:forEachTile(function(tile) tile.semaphoreShortSpeed = tonumber(input.value) end)
end

function UIPickerPane:updateSemaphoreFourPhase(checkbox)
	self:forEachTile(function(tile) tile.semaphoreFourPhase = checkbox.value end)
end

function UIPickerPane:updateWarp(input)
	self:forEachTile(function(tile) tile.warp = input.value end)
end

function UIPickerPane:updateCommand(input)
	self:forEachTile(function(tile) tile.command = input.value end)
end

return UIPickerPane