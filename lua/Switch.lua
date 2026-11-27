local Class = require("lua.core.class")
local Severity = require("lua.core.Utils.LogSeverity")

---@class Switch
local Switch = Class:derive("Switch")

---Creates a switch.
---@param id string Full switch name, e.g. `"sta1_3"`.
function Switch:new(id)
	self.id = id
	self.state = false
	self.forced = false
end

function Switch:__tostring()
	return string.format("J[%s : state=%s forced=%s]", self.id, self.state, self.forced)
end

---Sends an information about this switch to the log.
---@param text string The message.
---@param severity LogSeverity? Severity.
---@param weight integer? Weight.
function Switch:say(text, severity, weight)
	_Log.write(tostring(self.id) .. ": " .. text, severity, weight)
end

---Sets the Switch state.
---@param state boolean `true` for `+`, `false` for `-`.
function Switch:setState(state)
	self.state = state
end

function Switch:setForced(forced)
	self.forced = forced
end

function Switch:forceState(state)
	self.state = state
	self:setForced(true)
end

return Switch