local Class = require("lua.core.class")
local Severity = require("lua.core.Utils.LogSeverity")
local SemaphoreType = require("lua.core.Enums.SemaphoreType")
local Speed = require("lua.core.Enums.Speed")

---@class Semaphore
local Semaphore = Class:derive("Semaphore")

---Tworzy semafor.
---@param id string Pełna nazwa semafora, np. `"sta1_C"`.
---@param data table Dane semafora, wczytywane z pliku.
function Semaphore:new(id, data)
	self.id = id
	self.type = data.type or SemaphoreType.SEM
	---@type Semaphore|integer
	self.next = Speed.STOP
	self.speed = self:getStopSpeed()
	self.image = self.speed == Speed.STOP and "s1" or "ms1"
	---@type boolean
	self.w24 = false
end

function Semaphore:__tostring()
	return string.format("S[%s : image=%s]", self.id, self.image)
end

---Sends an information about this semaphore to the log.
---@param text string The message.
---@param severity LogSeverity? Severity.
---@param weight integer? Weight.
function Semaphore:say(text, severity, weight)
	_Log.write(tostring(self.id) .. ": " .. text, severity, weight)
end

---Sets the speed on this semaphore.
---@param speed integer Speed on this semaphore.
function Semaphore:setSpeed(speed)
	self.speed = speed
end

---Sets the next semaphore, if any.
---@param next Semaphore|Speed The next semaphore or speed to be linked with.
function Semaphore:setNext(next)
	self.next = next
end

---Sets the image on this semaphore.
---@param image string The semaphore image.
function Semaphore:setImage(image)
	self.image = image
end

---Dims the semaphore so that no signal is displayed on it at all.
function Semaphore:dim()
	self.w24 = false
	self:setSpeed(Speed.DIM)
end

---Ustawia czy następne wywołanie `Semaphore:setSpeed()` wyświetli wskaźnik W24.
---Wskaźniki są kasowane po wywołaniu `Semaphore:stop()`.
---@param w24 boolean Czy ma być wyświetlony wskaźnik W24.
function Semaphore:setW24(w24)
	self.w24 = w24
end

---Returns the stop speed, `Ms1` if this is a shunting semaphore, or `S1` otherwise.
---@private
---@return Speed
function Semaphore:getStopSpeed()
	return self.type == SemaphoreType.TM and Speed.MS1 or Speed.STOP
end

---Returns whether this semaphore is currently displaying a stop signal.
---@return boolean
function Semaphore:isStop()
	return self.speed == Speed.STOP or self.speed == Speed.S1A or self.speed == Speed.MS1
end

---Returns whether this semaphore is currently not displaying anything.
---@return boolean
function Semaphore:isDim()
	return self.speed == Speed.DIM
end

return Semaphore