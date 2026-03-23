local Class = require("class")

---@class UIPickerPane : Class
---@overload fun(ui): UIPickerPane
local UIPickerPane = Class:derive("UIPickerPane")

---Constructs the UI picker pane.
---@param ui UI UI which owns this pane.
function UIPickerPane:new(ui)
    self.ui = ui

	self.ui:addPane(nil, "picker", nil, 0, 23, 40, 4)
	-- First column
	self.ui:addCheckbox("picker", "picker_electrified", "Tory zelektryfikowane", 0, 0, 1, 1, self, self.updateElectrified)
	self.ui.elements.picker_electrified.value = true
	self.ui:addLabel("picker", nil, "Nazwa toru", 0, 1, 5, 1)
	self.ui:addInput("picker", "picker_trackID", 5, 1, 5, 1, self, self.updateTrackID)
	self.ui:addLabel("picker", nil, "Nazwa zwr.", 0, 2, 5, 1)
	self.ui:addInput("picker", "picker_switchID", 5, 2, 5, 1, self, self.updateSwitchID)
	self.ui:addLabel("picker", nil, "Nazwa sem.", 0, 3, 5, 1)
	self.ui:addInput("picker", "picker_semaphoreID", 5, 3, 5, 1, self, self.updateSemaphoreID)
	-- Second column
	self.ui:addLabel("picker", nil, "Pkt końc izol.", 10, 0, 5, 1)
	self.ui:addInput("picker", "picker_itineraryEndID", 15, 0, 5, 1, self, self.updateItineraryEndID)
	self.ui:addCheckbox("picker", "picker_electrified2", "Elektr.", 10, 1, 1, 1, self, self.updateElectrified2)
	self.ui:addCheckbox("picker", "picker_targetW24", "W24", 15, 1, 1, 1, self, self.updateTargetW24)
	self.ui.elements.picker_targetW24.tip = "Odnosi się do punktu docelowego.\nJeżeli przebieg kończy się na tym punkcie, to na semaforze wyświetlony zostanie wskaźnik W24."
	self.ui:addLabel("picker", nil, "Zamień", 10, 2, 4, 1)
	self.ui:addCheckbox("picker", "picker_switchFlip", "+/-", 13, 2, 1, 1, self, self.updateSwitchFlip)
	self.ui:addCheckbox("picker", "picker_switchFlipABCD", "ab/cd", 16, 2, 1, 1, self, self.updateSwitchFlipABCD)
	self.ui:addLabel("picker", nil, "Typ", 10, 3, 2, 1)
	self.ui:addInput("picker", "picker_semaphoreType", 12, 3, 3, 1, self, self.updateSemaphoreType)
	self.ui.elements.picker_semaphoreType.tip = "Typ semafora:\n0 = semafor\n1 = tarcza manewrowa"
	self.ui:addCheckbox("picker", "picker_semaphoreNoW24", "Brak W24", 15, 3, 1, 1, self, self.updateSemaphoreNoW24)
	self.ui.elements.picker_semaphoreNoW24.tip = "Odnosi się do semafora.\nOznacza, że dany semafor NIE posiada wskaźnika W24.\nTaki semafor nie może podać przebiegu wymagającego wyświetlenia tego wskaźnika."
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
	-- Fourth column
	self.ui:addLabel("picker", nil, "Możliwość podania:", 30, 0, 10, 1)
	self.ui:addCheckbox("picker", "picker_semaphoreAllowTrain", "poc.", 31, 1, 1, 1, self, self.updateSemaphoreAllowTrain)
	--self.ui.elements.picker_semaphoreAllowTrain.tip = "Oznacza możliwość wyświetlenia sygnału zezwalającego na jazdę na tym semaforze (np. S2, S5, S13).\nNależy zaznaczyć dla sygnalizatorów półsamoczynnych i sygnalizatorów SBL.\nNie należy zaznaczać dla tarcz manewrowych, semaforów zaporowych i sygnalizatorów Sz."
	self.ui:addCheckbox("picker", "picker_semaphoreAllowShunt", "man.", 34, 1, 1, 1, self, self.updateSemaphoreAllowShunt)
	--self.ui.elements.picker_semaphoreAllowShunt.tip = "Oznacza możliwość wyświetlenia sygnału zezwalającego na manewry na tym semaforze (Ms2).\nNależy zaznaczyć dla większości semaforów, tarcz manewrowych i tarcz zaporowych.\nNie należy zaznaczać dla semaforów wjazdowych, semaforów bez indeksu \"m\", sygnalizatorów SBL i Sz."
	self.ui:addCheckbox("picker", "picker_semaphoreAllowSz", "Sz", 37, 1, 1, 1, self, self.updateSemaphoreAllowSz)
	--self.ui.elements.picker_semaphoreAllowSz.tip = "Oznacza możliwość wyświetlenia sygnału zastępczego na tym semaforze (Sz).\nNależy zaznaczyć dla większości semaforów i sygnalizatorów Sz.\nNie należy zaznaczać dla tarcz manewrowych i semaforów nieposiadających fizycznie komory białej (na posterunkach odstępowych, SBL)."
	self.ui:addCheckbox("picker", "picker_semaphoreShape", "Kształ.", 30, 2, 1, 1, self, self.updateSemaphoreShape)
	--self.ui.elements.picker_semaphoreShape.tip = "Oznacza semafor jako kształtowy.\nSemafory kształtowe nie mają uzależnienia od następnego semafora i potrafią wyświetlić tylko sygnały Sr1, Sr2 i Sr3.\nW chwili obecnej nie wpływa to na wygląd semafora na schemacie."
	self.ui:addCheckbox("picker", "picker_semaphoreNoDanger", "Brak pom.g.k.", 34, 2, 1, 1, self, self.updateSemaphoreNoDanger)
	self.ui.elements.picker_semaphoreNoDanger.tip = "Oznacza semafor jako nieposiadający górnej pomarańczowej komory.\nOznacza to, że pathfinder nie będzie w stanie wyświetlić sygnału zezwalającego na jazdę\njeżeli kolejny semafor nie zezwala na jazdę z prędkością 100km/h lub Vmax."
	self.ui:addLabel("picker", nil, "Sąsiednia st.:", 30, 3, 5, 1)
	self.ui:addInput("picker", "picker_warp", 35, 3, 5, 1, self, self.updateWarp)
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

function UIPickerPane:updateElectrified2(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setElectrified(checkbox.value)
	end
end

function UIPickerPane:updateTargetW24(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setTargetW24(checkbox.value)
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

function UIPickerPane:updateSemaphoreType(input)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSemaphoreType(tonumber(input.value))
	end
end

function UIPickerPane:updateSemaphoreNoW24(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSemaphoreNoW24(checkbox.value)
	end
end

function UIPickerPane:updateSemaphoreNoDanger(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSemaphoreNoDanger(checkbox.value)
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

function UIPickerPane:updateSemaphoreAllowTrain(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSemaphoreAllowTrain(checkbox.value)
	end
end

function UIPickerPane:updateSemaphoreAllowShunt(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSemaphoreAllowShunt(checkbox.value)
	end
end

function UIPickerPane:updateSemaphoreAllowSz(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSemaphoreAllowSz(checkbox.value)
	end
end

function UIPickerPane:updateSemaphoreShape(checkbox)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setSemaphoreShape(checkbox.value)
	end
end

function UIPickerPane:updateWarp(input)
	local station = _Project:getCurrentStation()
	for i, coords in ipairs(station.selectedTiles) do
		local tile = assert(station:getTile(coords.x, coords.y))
		tile:setWarp(input.value)
	end
end

return UIPickerPane