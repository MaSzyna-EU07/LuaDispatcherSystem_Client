local Class = require("class")

---@class UIBottomPane : Class
---@overload fun(ui): UIBottomPane
local UIBottomPane = Class:derive("UIBottomPane")

---Constructs the UI bottom pane.
---@param ui UI UI which owns this pane.
function UIBottomPane:new(ui)
    self.ui = ui

	self.ui:addPane(nil, "bottom", nil, 0, _WHEIGHT / self.ui.U - 1, (_WWIDTH - 320) / self.ui.U, 1)
	self.ui:addLabel("bottom", nil, "Komunikacja:", 0, 0, 5, 1)
	self.comStatus = self.ui:addLabel("bottom", "comStatus", "Łączenie...", 5, 0, 6, 1)
	self.ui:addButton("bottom", nil, "Reset", 11, 0, 3, 1, self, self.comReset)
	self.ui:addButton("bottom", nil, "S1", 15, 0, 2, 1, self, self.sendS1)
	self.ui:addButton("bottom", nil, "S2", 17, 0, 2, 1, self, self.sendS2)
	self.ui:addButton("bottom", nil, "S5", 19, 0, 2, 1, self, self.sendS5)
	self.ui:addButton("bottom", nil, "S10", 21, 0, 2, 1, self, self.sendS10)
	self.ui:addButton("bottom", nil, "S13", 23, 0, 2, 1, self, self.sendS13)
	self.ui:addButton("bottom", nil, "Sz", 25, 0, 2, 1, self, self.sendSz)
	self.ui:addButton("bottom", nil, "Ms1", 27, 0, 2, 1, self, self.sendMs1)
	self.ui:addButton("bottom", nil, "Ms2", 29, 0, 2, 1, self, self.sendMs2)
	self.ui:addButton("bottom", nil, "Uszk", 31, 0, 2, 1, self, self.sendUszk)
	self.ui:addButton("bottom", nil, "Ures", 34, 0, 2, 1, self, self.sendUnres)
	self.ui:addButton("bottom", nil, "Free", 36, 0, 2, 1, self, self.sendFree)
	self.ui:addButton("bottom", nil, "Busy", 38, 0, 2, 1, self, self.sendBusy)
	self.ui:addLabel("bottom", nil, "Komenda:", 41, 0, 4, 1)
	self.ui:addInput("bottom", "command", 45, 0, 7, 1, self, nil, self.sendCommand)
end

---Sets the displayed communication status on the bottom UI pane.
---@param text string The text to be displayed.
---@param color [number, number, number] The text color.
---@param tooltip string? What should appear when the status text is hovered.
function UIBottomPane:setStatus(text, color, tooltip)
	self.comStatus.label = text
	self.comStatus.tip = tooltip or ""
	self.comStatus.style.fg = color
end

function UIBottomPane:comReset()
	_Com.init(_SIM_PATH, true)
end

function UIBottomPane:sendToCurrentSemaphore(this, next)
	local station = _Project:getCurrentStation()
	if not station then
		return
	end
	for i, coords in ipairs(station.selectedTiles) do
		station:assertGetTile(coords.x, coords.y):sendSemaphoreState(this, next)
	end
end

function UIBottomPane:sendToCurrentSemaphoreUnreserve()
	local station = _Project:getCurrentStation()
	if not station then
		return
	end
	for i, coords in ipairs(station.selectedTiles) do
		station:assertGetTile(coords.x, coords.y):sendSemaphoreUnreserve()
	end
end

function UIBottomPane:sendToCurrentTrack(command)
	local station = _Project:getCurrentStation()
	if not station then
		return
	end
	for i, coords in ipairs(station.selectedTiles) do
		station:assertGetTile(coords.x, coords.y):sendTrackState(command)
	end
end

function UIBottomPane:sendS1()
	self:sendToCurrentSemaphore(0)
end

function UIBottomPane:sendS2()
	self:sendToCurrentSemaphore(1, 1)
end

function UIBottomPane:sendS4()
	self:sendToCurrentSemaphore(1, 2)
end

function UIBottomPane:sendS5()
	self:sendToCurrentSemaphore(1, 0)
end

function UIBottomPane:sendS10()
	self:sendToCurrentSemaphore(2, 1)
end

function UIBottomPane:sendS12()
	self:sendToCurrentSemaphore(2, 2)
end

function UIBottomPane:sendS13()
	self:sendToCurrentSemaphore(2, 0)
end

function UIBottomPane:sendSz()
	self:sendToCurrentSemaphore(7)
end

function UIBottomPane:sendMs1()
	self:sendToCurrentSemaphore(5)
end

function UIBottomPane:sendMs2()
	self:sendToCurrentSemaphore(6)
end

function UIBottomPane:sendS1a()
	self:sendToCurrentSemaphore(8)
end

function UIBottomPane:sendUszk()
	self:sendToCurrentSemaphore(-1)
end

function UIBottomPane:sendFree()
	self:sendToCurrentTrack("free")
end

function UIBottomPane:sendBusy()
	self:sendToCurrentTrack("busy")
end

function UIBottomPane:sendUnres()
	self:sendToCurrentSemaphoreUnreserve()
end

function UIBottomPane:sendCommand(input)
	_Com.sendCommand(input.value)
	input.value = ""
end

return UIBottomPane