local Class = require("lua.core.class")

---@class UIBottomPane : Class
---@overload fun(ui): UIBottomPane
local UIBottomPane = Class:derive("UIBottomPane")

---Constructs the UI bottom pane.
---@param ui UI UI which owns this pane.
function UIBottomPane:new(ui)
    self.ui = ui

	self.ui:addPane(nil, "bottom", nil, 0, _WHEIGHT / self.ui.U - 1, (_WWIDTH - 280) / self.ui.U, 1)
	self.ui:addLabel("bottom", nil, "Komunikacja:", 0, 0, 5, 1)
	self.comStatus = self.ui:addLabel("bottom", "comStatus", "", 5, 0, 6, 1)
	self.ui:addButton("bottom", nil, "Reset", 11, 0, 3, 1, self, self.comReset)
	self.ui:addButton("bottom", nil, "S1", 15, 0, 2, 1, self, function() self:sendToCurrentSemaphore(Speed.STOP) end)
	self.ui:addButton("bottom", nil, "S2", 17, 0, 2, 1, self, function() self:sendToCurrentSemaphore(math.huge) end)
	self.ui:addButton("bottom", nil, "S5", 19, 0, 2, 1, self, function() self:sendToCurrentSemaphore(math.huge, Speed.STOP) end)
	self.ui:addButton("bottom", nil, "S10", 21, 0, 2, 1, self, function() self:sendToCurrentSemaphore(40) end)
	self.ui:addButton("bottom", nil, "S13", 23, 0, 2, 1, self, function() self:sendToCurrentSemaphore(40, Speed.STOP) end)
	self.ui:addButton("bottom", nil, "Sz", 25, 0, 2, 1, self, function() self:sendToCurrentSemaphore(Speed.SZ) end)
	self.ui:addButton("bottom", nil, "Ms1", 27, 0, 2, 1, self, function() self:sendToCurrentSemaphore(Speed.MS1) end)
	self.ui:addButton("bottom", nil, "Ms2", 29, 0, 2, 1, self, function() self:sendToCurrentSemaphore(Speed.MS2) end)
	self.ui:addButton("bottom", nil, "Uszk", 31, 0, 2, 1, self, function() self:sendToCurrentSemaphore(Speed.DIM) end)
	self.ui:addButton("bottom", nil, "Ures", 34, 0, 2, 1, self, function() self:sendToCurrentSemaphoreUnreserve() end)
	self.ui:addButton("bottom", nil, "Free", 36, 0, 2, 1, self, function() self:sendToCurrentTrack("free") end)
	self.ui:addButton("bottom", nil, "Busy", 38, 0, 2, 1, self, function() self:sendToCurrentTrack("busy") end)
	self.ui:addLabel("bottom", nil, "Komenda:", 41, 0, 4, 1)
	self.ui:addInput("bottom", "command", 45, 0, 7, 1, self, nil, self.sendCommand)

	self:setStatus("Nieaktywna...", {0.6, 0.6, 0.6})
end

---Sets the displayed communication status on the bottom UI pane.
---@param text string The text to be displayed.
---@param color [number, number, number] The text color.
---@param tooltip string? What should appear when the status text is hovered.
function UIBottomPane:setStatus(text, color, tooltip)
	self.comStatus.label = text
	self.comStatus.tip = tooltip
	self.comStatus.style.fg = color
end

function UIBottomPane:comReset()
	if _Settings.simPath then
		_Com.init(_Settings.simPath, true)
	end
end

---Sends this and next speeds to the selected semaphore.
---@param this integer Speed on this semaphore.
---@param next integer|string? Speed on next semaphore, or the semaphore ID.
function UIBottomPane:sendToCurrentSemaphore(this, next)
	local station = _Project:getCurrentStation()
	if station then
		station:forEachSelectedTile(function(tile) tile:sendSemaphoreState(this, next) end)
	end
end

function UIBottomPane:sendToCurrentSemaphoreUnreserve()
	local station = _Project:getCurrentStation()
	if station then
		station:forEachSelectedTile(function(tile) tile:sendSemaphoreUnreserve() end)
	end
end

function UIBottomPane:sendToCurrentTrack(command)
	local station = _Project:getCurrentStation()
	if station then
		station:forEachSelectedTile(function(tile) tile:sendTrackState(command) end)
	end
end

function UIBottomPane:sendCommand(input)
	_Com.sendCommand(input.value)
	input.value = ""
end

return UIBottomPane