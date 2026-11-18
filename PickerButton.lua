local Class = require("lua.core.class")

---@class PickerButton : Class
---@overload fun(data): PickerButton
local PickerButton = Class:derive("PickerButton")

---Creates a new Button.
---@param data {x: integer, y: integer, tileX: integer, action: PickerMode} The button data.
function PickerButton:new(data)
    self.x, self.y = data.x, data.y
    self.tileX = data.tileX
    self.action = data.action
    self.pressed = false
end

---Returns whether this button is hovered.
---@return boolean
function PickerButton:isHovered()
    return _Utils.isPointInsideBox(_MouseX, _MouseY, self.x, self.y, 40, 28)
end

---Sets whether the button is pressed.
---@param pressed boolean Whether the button should be displayed as pressed.
function PickerButton:setPressed(pressed)
    self.pressed = pressed
end

---Draws the button.
function PickerButton:draw()
    local tileY = self.pressed and 2 or 1
    _Buttons:drawTile(self.tileX, tileY, self.x, self.y)
end

return PickerButton