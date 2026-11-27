local Class = require("lua.core.class")
local BlockadeDirection = require("lua.core.Enums.BlockadeDirection")

-- Represents a blockade (C, Eap or Eac (SBL)) between two stations.
---@class Blockade : Class
---@overload fun(id: string, data: BlockadeData): Blockade
local Blockade = Class:derive("Blockade")

---@alias BlockadeBlockData {track: Track, semaphore: Semaphore?, semaphoreN: Semaphore?}
---@alias BlockadeData {type: "sbl", bidirectional: boolean, blocks: BlockadeBlockData[]}

---Creates a new Blockade.
---@param id string The blockade ID.
---@param data BlockadeData The blockade data.
function Blockade:new(id, data)
    self.id = id
    self.direction = BlockadeDirection.FORWARD
end

---Sends an information about this blockade to the log.
---@param text string The message.
---@param severity LogSeverity? Severity.
---@param weight integer? Weight.
function Blockade:say(text, severity, weight)
	_Log.write("Blockade(" .. tostring(self.id) .. "): " .. text, severity, weight)
end

---Sets the direction on this blockade.
---@param direction BlockadeDirection The new blockade direction.
function Blockade:setDirection(direction)
    self.direction = direction
end

return Blockade