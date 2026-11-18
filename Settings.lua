local Class = require("lua.core.class")

---@class Settings : Class
---@overload fun(): Settings
local Settings = Class:derive("Settings")

---Constructs a new Settings class.
function Settings:new()
    self.path = "settings.json"

    ---Path to the simulator. This is used to communicate with the server. It must be always specified with a trailing slash.
    ---@type string?
    self.simPath = nil
    ---Project name to open when opening the program. If not specified, a new project will be opened.
    ---@type string?
    self.project = nil
    ---Station name to open within the project when opening the program. If not specified, no station will be selected.
    ---@type string?
    self.station = nil
    ---Scale to draw stations in.
    ---@type number
    self.scale = 1.5
end

---Loads data from the settings file. If the file is not found, nothing happens.
function Settings:load()
    local data = _Utils.loadJson(self.path)
    if data then
        self:deserialize(data)
    end
end

---Saves data to the settings file.
function Settings:save()
    _Utils.saveJson(self.path, self:serialize())
end

---Serializes the settings to be saved to a file.
---@return table
function Settings:serialize()
    return {
        simPath = self.simPath,
        project = self.project,
        station = self.station,
        scale = self.scale
    }
end

---Deserializes the settings from loaded save data.
---@param t table The loaded data.
function Settings:deserialize(t)
    self.simPath = t.simPath
    self.project = t.project
    self.station = t.station
    self.scale = t.scale or self.scale
end

return Settings