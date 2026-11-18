local Class = require("lua.core.class")

---@class Commands : Class
---@overload fun(): Commands
local Commands = Class:derive("Commands")

---Creates an object to handle commands. This is a global command bus.
function Commands:new()
    ---TODO: Make a real command system. This is just a preliminary step.
end

---Saves the specified project.
---@param project Project The project to be saved.
function Commands:saveProject(project)
	project:save()
	project:sync()
end

---Synchronizes the specified station with the connected server.
---@param station Station The station to be synchronized.
function Commands:syncStation(station)
	station:sync(true)
end

return Commands