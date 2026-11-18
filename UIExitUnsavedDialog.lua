local Class = require("lua.core.class")

---@class UIExitUnsavdDialog : Class
---@overload fun(ui): UIExitUnsavdDialog
local UIExitUnsavdDialog = Class:derive("UIExitUnsavdDialog")

---Constructs the UI exit confirmation dialog.
---@param ui UI UI which owns this window.
function UIExitUnsavdDialog:new(ui)
    self.ui = ui

    self.window = self.ui:createCenteredWindow("eud", "Wyjście", 15, 6)
	self.ui:addLabel("eud", nil, "Czy chcesz zapisać projekt?", 1, 1, 13, 1)
	self.ui:addLabel("eud", nil, "Niezapisane zmiany zostaną utracone.", 1, 2, 13, 1)
	self.ui:addButton("eud", "bYes", "Tak", 2, 4, 3, 1, self, self.saveAndExit)
	self.ui:addButton("eud", "bNo", "Nie", 6, 4, 3, 1, self, self.dontSaveAndExit)
	self.ui:addButton("eud", "bCancel", "Anuluj", 10, 4, 3, 1, self, self.cancel)
end

---Shows this window.
function UIExitUnsavdDialog:show()
	self.window:show()
	self.window:setlevel()
end

---Hides this window.
function UIExitUnsavdDialog:hide()
    self.window:hide()
end

function UIExitUnsavdDialog:saveAndExit()
	_Commands:exitUnsavedSave()
end

function UIExitUnsavdDialog:dontSaveAndExit()
	_Commands:exitUnsavedDontSave()
end

function UIExitUnsavdDialog:cancel()
	self:hide()
end

return UIExitUnsavdDialog