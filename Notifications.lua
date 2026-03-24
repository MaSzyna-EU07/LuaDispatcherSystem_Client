local Class = require("class")

---@class Notifications : Class
---@overload fun(): Notifications
local Notifications = Class:derive("Notifications")

function Notifications:new()
    self.font = _Font
    ---@type {text: string, color: NotificationColor, time: number}[]
    self.notifications = {}

    self.duration = 5
    self.fadeInTime = 0.15
    self.fadeOutTime = 0.2
end

---Posts a new notification.
---@param text string The notification text.
---@param color NotificationColor? The notification color, green by default.
function Notifications:post(text, color)
    table.insert(self.notifications, {text = text, color = color or NotificationColor.GREEN, time = _Time})
    print("[NOTIFICATION] " .. text)
end

---Draws the notifications on the screen.
function Notifications:draw()
    local y = 50
    for i, notification in ipairs(self.notifications) do
        local time = _Time - notification.time
        if time <= self.duration then
            y = y + 27
        end
    end
    for i, notification in ipairs(self.notifications) do
        local time = _Time - notification.time
        if time <= self.duration then
            y = y - 27
            local w = self.font:getWidth(notification.text)
            local x = 0
            if time < self.fadeInTime then
                x = _Utils.map(w + 55, 0, 0, self.fadeInTime, time)
            elseif time > self.duration - self.fadeOutTime then
                x = _Utils.map(0, w + 55, self.duration - self.fadeOutTime, self.duration, time)
            end
            love.graphics.setColor(0, 0, 0)
            love.graphics.polygon("fill", _WWIDTH + x + 2, y + 2, _WWIDTH + x + 2, y + 25 + 2, _WWIDTH - w - 30 + x + 2, y + 25 + 2, _WWIDTH - w - 55 + x + 2, y + 2)
            love.graphics.setColor(notification.color[1], notification.color[2], notification.color[3])
            love.graphics.polygon("fill", _WWIDTH + x, y, _WWIDTH + x, y + 25, _WWIDTH - w - 30 + x, y + 25, _WWIDTH - w - 55 + x, y)
            love.graphics.setFont(self.font)
            love.graphics.setColor(0, 0, 0)
            love.graphics.print(notification.text, _WWIDTH - w - 23 + x, y + 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(notification.text, _WWIDTH - w - 25 + x, y + 3)
        end
    end
end

return Notifications