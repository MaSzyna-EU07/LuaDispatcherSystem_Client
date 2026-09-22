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
end

function UIPickerPane:updateElectrified(checkbox)
	_Picker.electrified = checkbox.value
end

return UIPickerPane