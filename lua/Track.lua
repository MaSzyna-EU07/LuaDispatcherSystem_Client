local Class = require("lua.core.class")
local Severity = require("lua.core.Utils.LogSeverity")

---@class Track
local Track = Class:derive("Track")

---Tworzy tor.
---@param id string Pełna nazwa toru, np. `"sta1_Iz1"`.
function Track:new(id)
	self.id = id
	self.occupied = false
	self.reserved = false
	---@type Semaphore?
	self.semaphore = nil
	---@type table<string, integer>
	self.vehicles = {}
end

function Track:__tostring()
	return string.format("T[%s : occupied=%s reserved=%s]", self.id, self.occupied, self.reserved)
end

---Returns whether this track is neither reserved nor occupied.
---@return boolean
function Track:isClear()
	return not (self.occupied or self.reserved)
end

---Sends an information about this track to the log.
---@param text string The message.
---@param severity LogSeverity? Severity.
---@param weight integer? Weight.
function Track:say(text, severity, weight)
	_Log.write(tostring(self.id) .. ": " .. text, severity, weight)
end

function Track:setOccupied(occupied)
	self.occupied = occupied
end

function Track:setReserved(reserved)
	self.reserved = reserved
end

function Track:incVehicle(vehicle)
	self.vehicles[vehicle] = (self.vehicles[vehicle] or 0) + 1
end

function Track:decVehicle(vehicle)
	self.vehicles[vehicle] = self.vehicles[vehicle] ~= 1 and self.vehicles[vehicle] - 1 or nil
end

---Assigns or unassigns this Track from a semaphore.
---@param semaphore Semaphore? Which Semaphore this Track should belong to right now.
function Track:setSemaphore(semaphore)
	self.semaphore = semaphore
end

return Track