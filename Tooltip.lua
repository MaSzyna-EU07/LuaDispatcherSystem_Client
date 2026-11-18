local Class = require("lua.core.class")

---@class Tooltip : Class
---@overload fun(): Tooltip
local Tooltip = Class:derive("Tooltip")

---Creates a global tooltip.
function Tooltip:new()
    self.text = nil
    self.x, self.y = nil, nil
    self.anchorX, self.anchorY = 0, 0
    self.offset = 10
    self.marginX, self.marginY = 6, 3
    self.shadowOffset = 2
end

---Sets the tooltip text.
---@param text string? New tooltip text.
function Tooltip:setText(text)
    self.text = text
end

---Sets the tooltip position. If not specified, it will be displayed at mouse position.
---@param x number? X position of the tooltip.
---@param y number? Y position of the tooltip.
function Tooltip:setPos(x, y)
    self.x, self.y = x, y
end

---Sets the tooltip's anchor position.
---@param x number Horizontal anchor. 0 is at the left, 1 is at the right, 0.5 is at the middle.
---@param y number Vertical anchor. 0 is at the top, 1 is at the bottom, 0.5 is at the middle.
function Tooltip:setAnchor(x, y)
    self.anchorX, self.anchorY = x, y
end

---Sets the tooltip's margin.
---@param x number Horizontal margin.
---@param y number Vertical margin.
function Tooltip:setMargin(x, y)
    self.marginX, self.marginY = x, y
end

---Resets this Tooltip's state.
function Tooltip:reset()
    self:setText()
    self:setPos()
    self:setAnchor(0, 0)
    self:setMargin(6, 3)
end

---Draws the tooltip.
function Tooltip:draw()
    if not self.text then
        return
    end
    local x, y = self.x or _MouseX + self.offset, self.y or _MouseY + self.offset
    local w, h = _Font:getWidth(self.text), _Font:getHeight() * #_Utils.strSplit(self.text, "\n")
    w, h = w + self.marginX * 2, h + self.marginY * 2
    -- Reposition to the anchor
    x, y = math.floor(x - w * self.anchorX), math.floor(y - h * self.anchorY)
    -- Don't draw outside the screen
    x, y = _Utils.clamp(x, 0, _WWIDTH - w), _Utils.clamp(y, 0, _WHEIGHT - h)
    -- Background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", x, y, w, h)
    -- Border
    love.graphics.setLineWidth(2)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("line", x, y, w, h)
    -- Text
    love.graphics.setFont(_Font)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.print(self.text, x + self.marginX + self.shadowOffset, y + self.marginY + self.shadowOffset)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.text, x + self.marginX, y + self.marginY)
    -- Anchor
    --love.graphics.setColor(1, 1, 0)
    --love.graphics.rectangle("fill", self.x - 1, self.y - 1, 3, 3)
end

return Tooltip