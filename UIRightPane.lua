local Class = require("class")

---@class UIRightPane : Class
---@overload fun(ui): UIRightPane
local UIRightPane = Class:derive("UIRightPane")

---Constructs the UI right pane.
---@param ui UI UI which owns this pane.
function UIRightPane:new(ui)
    self.ui = ui
	self.pane = self.ui:addPane(nil, "right", "Informacje o stacji", _WWIDTH / self.ui.U - 14, 0, 14, _WHEIGHT / self.ui.U)

	-- Station name and list button
	self.header = self.ui:addLabel("right", "header", "", 0, 1, 11, 1)
	self.ui:addButton("right", "bStationList", "Lista", 11, 1, 3, 1, self.ui, self.ui.showStationList)

	-- Tile Settings
	self.stationAutofill = self.ui:addCheckbox("right", "stationAutofill", "Autouzupełnianie ID stacji", 0, 3, 1, 1, self, self.updateStationAutofill)
	self.stationAutofill.value = true
	---@type (Gspot.group|Gspot.text)[]
	self.headers = {}
	---@type table<string, any>
	self.widgets = {}

	self.uiGenY = 4

	self:update()
end

---Adds a header to the property list.
---@param name string Header contents.
---@param color [number, number, number]? Header's background color, accent color by default.
function UIRightPane:addHeader(name, color)
	local text = "  "
	local chars = _Utils.strSplitChars(name)
	for i, char in ipairs(chars) do
		text = text .. " " .. char
	end
	local header = self.ui:addPane("right", nil, nil, 0, self.uiGenY, 14, 1)
	local headerLabel = self.ui:addLabel("right", nil, text, 0, self.uiGenY, 14, 1)
	header.style.bg = color or self.ui.accentColor
	table.insert(self.headers, header)
	table.insert(self.headers, headerLabel)
	self.uiGenY = self.uiGenY + 1
end

---Adds track settings to the property list.
function UIRightPane:addTrackSettings()
	self:addHeader("Tor")

	self.widgets.trackID_l = self.ui:addLabel("right", nil, "Nazwa toru:", 0, self.uiGenY, 5, 1)
	self.widgets.trackID = self.ui:addInput("right", "trackID", 5, self.uiGenY, 9, 1, self, self.updateTrackID, self.confirmTrackID)
	self.uiGenY = self.uiGenY + 1

	self.widgets.electrified2 = self.ui:addCheckbox("right", "electrified2", "Zelektryfikowany", 0, self.uiGenY, 1, 1, self, self.updateElectrified2)
	self.uiGenY = self.uiGenY + 1

	self.widgets.target_l = self.ui:addLabel("right", nil, "Punkt końcowy jazd:", 0, self.uiGenY, 8, 1)
	self.widgets.trainTarget = self.ui:addCheckbox("right", "trainTarget", "poc.", 8, self.uiGenY, 1, 1, self, self.updateTrainTarget)
	self.widgets.shuntTarget = self.ui:addCheckbox("right", "shuntTarget", "man.", 11, self.uiGenY, 1, 1, self, self.updateShuntTarget)
	self.uiGenY = self.uiGenY + 1

	self.widgets.forbid_l = self.ui:addLabel("right", nil, "Zakaz jazdy:", 0, self.uiGenY, 8, 1)
	self.widgets.forbidTrain = self.ui:addCheckbox("right", "forbidTrain", "poc.", 8, self.uiGenY, 1, 1, self, self.updateForbidTrain)
	self.widgets.forbidShunt = self.ui:addCheckbox("right", "forbidShunt", "man.", 11, self.uiGenY, 1, 1, self, self.updateForbidShunt)
	self.uiGenY = self.uiGenY + 1

	self.widgets.speed_l = self.ui:addLabel("right", nil, "Vmax [km/h]", 0, self.uiGenY, 8, 1)
	self.widgets.speed = self.ui:addInput("right", "speed", 8, self.uiGenY, 6, 1, self, self.updateMaxSpeed)
	self.uiGenY = self.uiGenY + 1

	self.widgets.itineraryEndID_l = self.ui:addLabel("right", nil, "ID punktu końcowego:", 0, self.uiGenY, 8, 1)
	self.widgets.itineraryEndID = self.ui:addInput("right", "itineraryEndID", 8, self.uiGenY, 6, 1, self, self.updateItineraryEndID)
	self.uiGenY = self.uiGenY + 1

	self.widgets.targetW24 = self.ui:addCheckbox("right", "targetW24", "W24", 0, self.uiGenY, 1, 1, self, self.updateTargetW24)
	self.widgets.targetW24.tip = "Odnosi się do punktu docelowego.\nJeżeli przebieg kończy się na tym punkcie, to na semaforze wyświetlony zostanie wskaźnik W24."
	self.uiGenY = self.uiGenY + 1
end

---Adds switch settings to the property list.
function UIRightPane:addSwitchSettings()
	self:addHeader("Rozjazd")

	self.widgets.switchID_l = self.ui:addLabel("right", nil, "Nazwa rozjazdu:", 0, self.uiGenY, 8, 1)
	self.widgets.switchID = self.ui:addInput("right", "switchID", 8, self.uiGenY, 6, 1, self, self.updateSwitchID, self.confirmSwitchID)
	self.uiGenY = self.uiGenY + 1

	self.widgets.switchFlip_l = self.ui:addLabel("right", nil, "Zamień stronami:", 0, self.uiGenY, 8, 1)
	self.widgets.switchFlip = self.ui:addCheckbox("right", "switchFlip", "+/-", 8, self.uiGenY, 1, 1, self, self.updateSwitchFlip)
	self.widgets.switchFlipABCD = self.ui:addCheckbox("right", "switchFlipABCD", "ab/cd", 11, self.uiGenY, 1, 1, self, self.updateSwitchFlipABCD)
	self.uiGenY = self.uiGenY + 1

	self.widgets.speedPlus_l = self.ui:addLabel("right", nil, "V+", 0, self.uiGenY, 2, 1)
	self.widgets.speedPlus = self.ui:addInput("right", "speedPlus", 2, self.uiGenY, 5, 1, self, self.updateMaxSpeedPlus)
	self.widgets.speedMinus_l = self.ui:addLabel("right", nil, "V-", 7, self.uiGenY, 2, 1)
	self.widgets.speedMinus = self.ui:addInput("right", "speedMinus", 9, self.uiGenY, 5, 1, self, self.updateMaxSpeedMinus)
	self.uiGenY = self.uiGenY + 1
end

---Adds semaphore settings to the property list.
function UIRightPane:addSemaphoreSettings()
	self:addHeader("Semafor")

	self.widgets.semaphoreID_l = self.ui:addLabel("right", nil, "Nazwa semafora:", 0, self.uiGenY, 8, 1)
	self.widgets.semaphoreID = self.ui:addInput("right", "semaphoreID", 8, self.uiGenY, 6, 1, self, self.updateSemaphoreID, self.confirmSemaphoreID)
	self.uiGenY = self.uiGenY + 1

	self.widgets.semaphoreType_l = self.ui:addLabel("right", nil, "Typ:", 0, self.uiGenY, 8, 1)
	self.widgets.semaphoreType = self.ui:addInput("right", "semaphoreType", 8, self.uiGenY, 6, 1, self, self.updateSemaphoreType)
	self.widgets.semaphoreType.tip = "Typ semafora:\n0 = semafor\n1 = tarcza manewrowa"
	self.uiGenY = self.uiGenY + 1

	self.widgets.semaphoreNoW24 = self.ui:addCheckbox("right", "semaphoreNoW24", "Brak W24", 0, self.uiGenY, 1, 1, self, self.updateSemaphoreNoW24)
	self.widgets.semaphoreNoW24.tip = "Odnosi się do semafora.\nOznacza, że dany semafor NIE posiada wskaźnika W24.\nTaki semafor nie może podać przebiegu wymagającego wyświetlenia tego wskaźnika."
	self.uiGenY = self.uiGenY + 1

	self.widgets.semaphoreShortSpeed_l = self.ui:addLabel("right", nil, "V dla skr. drogi ham.", 0, self.uiGenY, 8, 1)
	self.widgets.semaphoreShortSpeed = self.ui:addInput("right", "semaphoreShortSpeed", 8, self.uiGenY, 6, 1, self, self.updateSemaphoreShortSpeed)
	self.widgets.semaphoreShortSpeed.tip = "Prędkość dla skróconej drogi hamowania w km/h.\nJeżeli wielostopniowa, to można wpisać dane w poniższym formacie:\n0:40,40:100\n- Przy następnym Stój, ogranicz do 40 km/h\n- Przy następnym 40 km/h, ogranicz do 100 km/h\n- Powyżej 40 km/h, nie ograniczaj"
	self.uiGenY = self.uiGenY + 1

	self.widgets.semaphoreAllow_l = self.ui:addLabel("right", nil, "Możl. podania:", 0, self.uiGenY, 6, 1)
	self.widgets.semaphoreAllowTrain = self.ui:addCheckbox("right", "semaphoreAllowTrain", "poc.", 6, self.uiGenY, 1, 1, self, self.updateSemaphoreAllowTrain)
	self.widgets.semaphoreAllowTrain.tip = "Możliwość wyświetlenia sygnału zezwalającego na jazdę na tym semaforze (np. S2, S5, S13).\nNależy zaznaczyć dla sygnalizatorów półsamoczynnych i sygnalizatorów SBL.\nNie należy zaznaczać dla tarcz manewrowych, semaforów zaporowych i sygnalizatorów Sz."
	self.widgets.semaphoreAllowShunt = self.ui:addCheckbox("right", "semaphoreAllowShunt", "man.", 9, self.uiGenY, 1, 1, self, self.updateSemaphoreAllowShunt)
	self.widgets.semaphoreAllowShunt.tip = "Możliwość wyświetlenia sygnału zezwalającego na manewry na tym semaforze (Ms2).\nNależy zaznaczyć dla większości semaforów, tarcz manewrowych i tarcz zaporowych.\nNie należy zaznaczać dla semaforów wjazdowych, semaforów bez indeksu \"m\", sygnalizatorów SBL i Sz."
	self.widgets.semaphoreAllowSz = self.ui:addCheckbox("right", "semaphoreAllowSz", "Sz", 12, self.uiGenY, 1, 1, self, self.updateSemaphoreAllowSz)
	self.widgets.semaphoreAllowSz.tip = "Możliwość wyświetlenia sygnału zastępczego na tym semaforze (Sz).\nNależy zaznaczyć dla większości semaforów i sygnalizatorów Sz.\nNie należy zaznaczać dla tarcz manewrowych i semaforów nieposiadających fizycznie komory białej (na posterunkach odstępowych, SBL)."
	self.uiGenY = self.uiGenY + 1

	self.widgets.semaphoreShape = self.ui:addCheckbox("right", "semaphoreShape", "Kształtowy", 0, self.uiGenY, 1, 1, self, self.updateSemaphoreShape)
	self.widgets.semaphoreShape.tip = "Oznacza semafor jako kształtowy.\nSemafory kształtowe nie mają uzależnienia od następnego semafora i potrafią wyświetlić tylko sygnały Sr1, Sr2 i Sr3.\nW chwili obecnej nie wpływa to na wygląd semafora na schemacie."
	self.widgets.semaphoreFourPhase = self.ui:addCheckbox("right", "semaphoreFourPhase", "4-stawny", 7, self.uiGenY, 1, 1, self, self.updateSemaphoreFourPhase)
	self.widgets.semaphoreFourPhase.tip = "Gdy zaznaczony i za dwa semafory jest S1, to zamiast S2 wyświetlony zostanie S3, zamiast S10 - S11, itp."
	self.uiGenY = self.uiGenY + 1

	self.widgets.semaphoreNoDanger = self.ui:addCheckbox("right", "semaphoreNoDanger", "Brak górnej pomarańczowej komory", 0, self.uiGenY, 1, 1, self, self.updateSemaphoreNoDanger)
	self.widgets.semaphoreNoDanger.tip = "Oznacza semafor jako nieposiadający górnej pomarańczowej komory.\nOznacza to, że pathfinder nie będzie w stanie wyświetlić sygnału zezwalającego na jazdę\njeżeli kolejny semafor nie zezwala na jazdę z prędkością 100km/h lub Vmax."
	self.uiGenY = self.uiGenY + 1

	self.widgets.semaphoreOwnShield = self.ui:addCheckbox("right", "semaphoreOwnShield", "Własna tarcza ostrzegawcza", 0, self.uiGenY, 1, 1, self, self.updateSemaphoreOwnShield)
	self.widgets.semaphoreOwnShield.tip = "Gdy zaznaczone, semafor posiada własną tarczę ostrzegawczą, czyli poprzedni semafor nie będzie od niego uzależniony."
	self.uiGenY = self.uiGenY + 1

	self.widgets.semaphoreNext_l = self.ui:addLabel("right", nil, "Następny semafor:", 0, self.uiGenY, 8, 1)
	self.widgets.semaphoreNext = self.ui:addInput("right", "semaphoreNext", 8, self.uiGenY, 6, 1, self, self.updateSemaphoreNext)
	self.widgets.semaphoreNext.tip = "Wskazuje następną prędkość w km/h (puste = Vmax) lub ID następnego semafora ze znakiem ':' na początku."
	self.uiGenY = self.uiGenY + 1
end

---Adds warp settings to the property list.
function UIRightPane:addWarpSettings()
	self:addHeader("Punkt końcowy")

	self.widgets.warpID_l = self.ui:addLabel("right", nil, "ID:", 0, self.uiGenY, 2, 1)
	self.widgets.warpID = self.ui:addInput("right", "warpID", 2, self.uiGenY, 3, 1, self, self.updateWarpID)
	self.widgets.warpID.tip = "Wskaż unikalny dla tej stacji identyfikator punktu końcowego, do którego można się jednoznacznie odnieść z innej stacji, np. `MMz_N`."
	self.widgets.warp_l = self.ui:addLabel("right", nil, "Cel:", 5, self.uiGenY, 2, 1)
	self.widgets.warp = self.ui:addInput("right", "warp", 7, self.uiGenY, 4, 1, self, self.updateWarp)
	self.widgets.warp.tip = "Wskaż skrót stacji lub szlaku do której prowadzi strzałka, np. `Mrz`."
	self.widgets.warpTargetID = self.ui:addInput("right", "warpTargetID", 11, self.uiGenY, 3, 1, self, self.updateWarpTargetID)
	self.widgets.warpTargetID.tip = "Wskaż identyfikator punktu końcowego, do którego prowadzi ta strzałka na wskazanej stacji, np. `MMz_N`."
	self.uiGenY = self.uiGenY + 1
end

---Adds blockade settings to the property list.
function UIRightPane:addBlockadeSettings()
	self:addHeader("Blokada liniowa")

	self.widgets.blockadeID_l = self.ui:addLabel("right", nil, "Nazwa blokady:", 0, self.uiGenY, 8, 1)
	self.widgets.blockadeID = self.ui:addInput("right", "blockadeID", 8, self.uiGenY, 6, 1, self, self.updateBlockadeID)
	self.uiGenY = self.uiGenY + 1
end

---Adds miscellaneous settings to the property list.
function UIRightPane:addMiscSettings()
	self:addHeader("Różne")

	self.widgets.command_l = self.ui:addLabel("right", nil, "Komenda:", 0, self.uiGenY, 8, 1)
	self.widgets.command = self.ui:addInput("right", "command", 8, self.uiGenY, 6, 1, self, self.updateCommand)
	self.widgets.command.tip = "Komenda jaka zostanie wykonana po kliknięciu tej kostki prawym przyciskiem myszy."
	self.uiGenY = self.uiGenY + 1
end

---Removes all tile setting groups from the UI panel.
function UIRightPane:removeAllSettings()
	for i, header in ipairs(self.headers) do
		self.ui:removeElement(header)
	end
	_Utils.emptyTable(self.headers)
	for name, widget in pairs(self.widgets) do
		self.ui:removeElement(widget)
	end
	_Utils.emptyTable(self.widgets)
	-- Prepare for next additions (start from scratch)
	self.uiGenY = 4
end

function UIRightPane:update()
	local station = _Project:getCurrentStation()
	self.header.label = string.format("Stacja: %s", station and station:getFullName() or "(brak)")
end

---Resets all property inputs to their default values.
function UIRightPane:resetValues()
	self:removeAllSettings()
end

---Sets all property inputs to values from the specified tile.
---@param tile Tile The tile for which to set the input values.
function UIRightPane:setValuesForTile(tile)
	-- Spawn appropriate sections for the tile
	if tile:isTrack() or self.ui.showAllTileProperties then
		self:addTrackSettings()
		self.widgets.trackID.value = tile.trackID or ""
		self.widgets.electrified2.value = tile.electrified
		self.widgets.trainTarget.value = tile.trainTarget
		self.widgets.shuntTarget.value = tile.shuntTarget
		self.widgets.forbidTrain.value = tile.forbidTrain
		self.widgets.forbidShunt.value = tile.forbidShunt
		self.widgets.speed.value = tile.maxSpeed ~= math.huge and tostring(tile.maxSpeed) or ""
		self.widgets.itineraryEndID.value = tile.itineraryEndID or ""
		self.widgets.targetW24.value = tile.targetW24
	end
	if tile:isSwitch() or self.ui.showAllTileProperties then
		self:addSwitchSettings()
		self.widgets.switchID.value = tile.switchID or ""
		self.widgets.switchFlip.value = tile.switchFlip
		self.widgets.switchFlipABCD.value = tile.switchFlipABCD
		self.widgets.speedPlus.value = tile.maxSpeedPlus ~= math.huge and tostring(tile.maxSpeedPlus) or ""
		self.widgets.speedMinus.value = tile.maxSpeedMinus ~= math.huge and tostring(tile.maxSpeedMinus) or ""
	end
	if tile:isSemaphore() or self.ui.showAllTileProperties then
		self:addSemaphoreSettings()
		self.widgets.semaphoreID.value = tile.semaphoreID or ""
		self.widgets.semaphoreType.value = tile:isSemaphore() and (tile.semaphoreType and tostring(tile.semaphoreType) or "0") or ""
		self.widgets.semaphoreNoW24.value = tile.semaphoreNoW24
		self.widgets.semaphoreShortSpeed.value = tile.semaphoreShortSpeed and self:shortSpeedToText(tile.semaphoreShortSpeed) or ""
		self.widgets.semaphoreAllowTrain.value = tile.semaphoreAllowTrain
		self.widgets.semaphoreAllowShunt.value = tile.semaphoreAllowShunt
		self.widgets.semaphoreAllowSz.value = tile.semaphoreAllowSz
		self.widgets.semaphoreShape.value = tile.semaphoreShape
		self.widgets.semaphoreFourPhase.value = tile.semaphoreFourPhase
		self.widgets.semaphoreNoDanger.value = tile.semaphoreNoDanger
		self.widgets.semaphoreOwnShield.value = tile.semaphoreOwnShield
		self.widgets.semaphoreNext.value = tile.semaphoreNext and self:nextToText(tile.semaphoreNext) or ""
	end
	if tile:isExitPoint() or self.ui.showAllTileProperties then
		self:addWarpSettings()
		self.widgets.warpID.value = tile.warpID or ""
		self.widgets.warp.value = tile.warp or ""
		self.widgets.warpTargetID.value = tile.warpTargetID or ""
	end
	if tile:isBlockadeGenerator() or self.ui.showAllTileProperties then
		self:addBlockadeSettings()
		self.widgets.blockadeID.value = tile.blockadeID or ""
	end
	self:addMiscSettings()
	self.widgets.command.value = tile.command or ""
end

---Turns short speed data into text format.
---@param shortSpeed table<integer, integer> Short speed information.
---@return string
function UIRightPane:shortSpeedToText(shortSpeed)
	local keys = _Utils.tableGetSortedKeys(shortSpeed)
	if #keys == 0 then
		return ""
	elseif #keys == 1 and keys[1] == 0 then
		return tostring(shortSpeed[0])
	end
	local text = ""
	for i, key in ipairs(keys) do
		text = text .. (text ~= "" and "," or "") .. tostring(key) .. ":" .. tostring(shortSpeed[key])
	end
	return text
end

---Turns short speed in text format into its native format.
---@param text string Short speed input.
---@return table<integer, integer>
function UIRightPane:textToShortSpeed(text)
	if text == "" then
		return {}
	elseif tonumber(text) then
		return {[0] = tonumber(text)}
	end
	local entries = _Utils.strSplit(text, ",")
	local shortSpeed = {}
	for i, entry in ipairs(entries) do
		local spl = _Utils.strSplit(entry, ":")
		if #spl == 2 then
			local nextSpeed = tonumber(spl[1])
			local speed = tonumber(spl[2])
			if nextSpeed and speed then
				shortSpeed[nextSpeed] = speed
			end
		end
	end
	return shortSpeed
end

---Turns next semaphore indicator to its string representation, with a `:` if it is a string.
---@param next string|integer? Semaphore or speed.
---@return string
function UIRightPane:nextToText(next)
	if type(next) == "number" then
		return tostring(next)
	elseif type(next) == "string" then
		return ":" .. next
	end
	return ""
end

---Turns the string representation of the next semaphore to its full representation (`nil`, integer or string).
---@param text string Input text.
---@return string|integer?
function UIRightPane:textToNext(text)
	if text == "" then
		return nil
	elseif text:sub(1, 1) == ":" then
		return text:sub(2)
	end
	return tonumber(text) or text
end

function UIRightPane:updateStationAutofill(checkbox)
end

---Executes a function for each selected tile.
---@param f fun(tile: Tile) The function to be executed.
function UIRightPane:forEachTile(f)
	local station = _Project:getCurrentStation()
	if station then
		station:forEachSelectedTile(f)
		station:markUnsaved()
	end
end

---Prepares a device ID, turning it to `nil` if empty and prefilling station shortcut if enabled.
---@param id string The entered ID.
---@return string?
function UIRightPane:prepareID(id)
	if id == "" then
		return nil
	end
	if self.stationAutofill.value and not _Utils.strContains(id, "_") and not _Utils.strContains(id, "@") then
		local station = _Project:getCurrentStation()
		if station then
			return station.shortcut .. "_" .. id
		end
	end
	return id
end

---Prepares a semaphore ID. In addition to what `:prepareID()` does, entering a number by itself will prefix it with "Tm".
---@param id string The entered ID.
function UIRightPane:prepareSemaphoreID(id)
	if self.stationAutofill.value and tonumber(id) then
		return self:prepareID("Tm" .. id)
	end
	return self:prepareID(id)
end

function UIRightPane:updateTrackID(input)
	local value = self:prepareID(input.value)
	self:forEachTile(function(tile) tile.trackID = value end)
end

function UIRightPane:confirmTrackID(input)
	local value = self:prepareID(input.value)
	self:forEachTile(function(tile) tile.trackID = value end)
	input.value = value or ""
	self.ui:unfocus()
end

function UIRightPane:updateSwitchID(input)
	local value = self:prepareID(input.value)
	self:forEachTile(function(tile) tile.switchID = value end)
end

function UIRightPane:confirmSwitchID(input)
	local value = self:prepareID(input.value)
	self:forEachTile(function(tile) tile.switchID = value end)
	input.value = value or ""
	self.ui:unfocus()
end

function UIRightPane:updateSemaphoreID(input)
	local value = self:prepareSemaphoreID(input.value)
	self:forEachTile(function(tile) tile.semaphoreID = value end)
end

function UIRightPane:confirmSemaphoreID(input)
	local value = self:prepareSemaphoreID(input.value)
	self:forEachTile(function(tile) tile.semaphoreID = value end)
	input.value = value or ""
	self.ui:unfocus()
end

function UIRightPane:updateBlockadeID(input)
	self:forEachTile(function(tile) tile.blockadeID = input.value end)
end

function UIRightPane:updateItineraryEndID(input)
	self:forEachTile(function(tile) tile.itineraryEndID = input.value ~= "" and input.value or nil end)
end

function UIRightPane:updateElectrified2(checkbox)
	self:forEachTile(function(tile) tile.electrified = checkbox.value end)
end

function UIRightPane:updateTargetW24(checkbox)
	self:forEachTile(function(tile) tile.targetW24 = checkbox.value end)
end

function UIRightPane:updateSwitchFlip(checkbox)
	self:forEachTile(function(tile) tile.switchFlip = checkbox.value end)
end

function UIRightPane:updateSwitchFlipABCD(checkbox)
	self:forEachTile(function(tile) tile.switchFlipABCD = checkbox.value end)
end

function UIRightPane:updateSemaphoreType(input)
	self:forEachTile(function(tile) tile.semaphoreType = tonumber(input.value) end)
end

function UIRightPane:updateSemaphoreNoW24(checkbox)
	self:forEachTile(function(tile) tile.semaphoreNoW24 = checkbox.value end)
end

function UIRightPane:updateSemaphoreNoDanger(checkbox)
	self:forEachTile(function(tile) tile.semaphoreNoDanger = checkbox.value end)
end

function UIRightPane:updateSemaphoreOwnShield(checkbox)
	self:forEachTile(function(tile) tile.semaphoreOwnShield = checkbox.value end)
end

function UIRightPane:updateMaxSpeed(input)
	self:forEachTile(function(tile) tile.maxSpeed = tonumber(input.value) or math.huge end)
end

function UIRightPane:updateMaxSpeedPlus(input)
	self:forEachTile(function(tile) tile.maxSpeedPlus = tonumber(input.value) or math.huge end)
end

function UIRightPane:updateMaxSpeedMinus(input)
	self:forEachTile(function(tile) tile.maxSpeedMinus = tonumber(input.value) or math.huge end)
end

function UIRightPane:updateTrainTarget(checkbox)
	self:forEachTile(function(tile) tile.trainTarget = checkbox.value end)
end

function UIRightPane:updateShuntTarget(checkbox)
	self:forEachTile(function(tile) tile.shuntTarget = checkbox.value end)
end

function UIRightPane:updateForbidTrain(checkbox)
	self:forEachTile(function(tile) tile.forbidTrain = checkbox.value end)
end

function UIRightPane:updateForbidShunt(checkbox)
	self:forEachTile(function(tile) tile.forbidShunt = checkbox.value end)
end

function UIRightPane:updateSemaphoreAllowTrain(checkbox)
	self:forEachTile(function(tile) tile.semaphoreAllowTrain = checkbox.value end)
end

function UIRightPane:updateSemaphoreAllowShunt(checkbox)
	self:forEachTile(function(tile) tile.semaphoreAllowShunt = checkbox.value end)
end

function UIRightPane:updateSemaphoreAllowSz(checkbox)
	self:forEachTile(function(tile) tile.semaphoreAllowSz = checkbox.value end)
end

function UIRightPane:updateSemaphoreShape(checkbox)
	self:forEachTile(function(tile) tile.semaphoreShape = checkbox.value end)
end

function UIRightPane:updateSemaphoreShortSpeed(input)
	self:forEachTile(function(tile) tile.semaphoreShortSpeed = self:textToShortSpeed(input.value) end)
end

function UIRightPane:updateSemaphoreNext(input)
	self:forEachTile(function(tile) tile.semaphoreNext = self:textToNext(input.value) end)
end

function UIRightPane:updateSemaphoreFourPhase(checkbox)
	self:forEachTile(function(tile) tile.semaphoreFourPhase = checkbox.value end)
end

function UIRightPane:updateWarp(input)
	self:forEachTile(function(tile) tile.warp = input.value end)
end

function UIRightPane:updateWarpID(input)
	self:forEachTile(function(tile) tile.warpID = input.value end)
end

function UIRightPane:updateWarpTargetID(input)
	self:forEachTile(function(tile) tile.warpTargetID = input.value end)
end

function UIRightPane:updateCommand(input)
	self:forEachTile(function(tile) tile.command = input.value end)
end

return UIRightPane