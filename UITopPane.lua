local Class = require("class")

---@class UITopPane : Class
---@overload fun(ui): UITopPane
local UITopPane = Class:derive("UITopPane")

---Constructs the UI top pane.
---@param ui UI UI which owns this pane.
function UITopPane:new(ui)
    self.ui = ui

	self.ui:addPane(nil, "top", nil, 0, 0, (_WWIDTH - 320) / self.ui.U, 1)
	self.ui:addButton("top", "bSave", "Zapisz", 0, 0, 4, 1, self, self.saveProject)
	self.ui:addButton("top", "bLoad", "Wczytaj", 4, 0, 4, 1, self, self.loadProject)
end

function UITopPane:saveProject()
	_Project:save()
end

function UITopPane:loadProject()
	_Project:load()
end

return UITopPane