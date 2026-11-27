local Class = require("lua.core.class")

---@class Vehicle : Class
---@overload fun(id: string): Vehicle
local Vehicle = Class:derive("Vehicle")

---Creates a Vehicle.
---@param id string The vehicle ID.
function Vehicle:new(id)
    self.id = id
end

return Vehicle