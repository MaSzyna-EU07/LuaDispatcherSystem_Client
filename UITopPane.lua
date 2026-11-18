local Class = require("lua.core.class")

---@class UITopPane : Class
---@overload fun(ui): UITopPane
local UITopPane = Class:derive("UITopPane")

---Constructs the UI top pane.
---@param ui UI UI which owns this pane.
function UITopPane:new(ui)
    self.ui = ui

	self.ui:addPane(nil, "top", nil, 0, 0, (_WWIDTH - 280) / self.ui.U, 1)
	self.ui:addButton("top", "bSave", "Zapisz", 0, 0, 4, 1, self, self.saveProject)
	self.ui:addButton("top", "bLoad", "Wczytaj", 4, 0, 4, 1, self, self.loadProject)
	self.ui:addButton("top", "bReload", "Synchronizuj stację", 8, 0, 8, 1, self, self.syncStation)
	self.projectLabel = self.ui:addLabel("top", "lProject", "", 16, 0, 20, 1)

	self:update()
end

function UITopPane:update()
	self.projectLabel.label = _Project and string.format("Projekt: %s%s", _Project:getSavePath() or "(Bez nazwy)", _Project:isUnsaved() and " *" or "") or "(Brak otwartego projektu)"
end

function UITopPane:saveProject()
	_Commands:saveProject(_Project)
end

function UITopPane:loadProject()
	self.ui:showProjectList()
end

function UITopPane:syncStation()
	local station = _Project:getCurrentStation()
	if station then
		_Commands:syncStation(station)
	end
end

return UITopPane