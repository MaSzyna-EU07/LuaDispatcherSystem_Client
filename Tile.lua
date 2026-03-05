local class = require "class"

---@class Tile : Class
---@overload fun(id, electrified): Tile
local Tile = class:derive("Tile")

function Tile:new(id, electrified)
	id = id or 0

	self.size = 14
	self.offset = 0
	if type(id) == "table" then
		self:deserialize(id)
		return
	end

	-- Tile IDs:
	-- 0 - blank/decoration
	-- 1, 2, 5, 6 - straight tracks
	-- 3, 7 - crossings
	-- 4, 8 - platforms/tracks inside station
	-- 9-16 - curves
	-- 17-24, 29-40. 49-52 - simple junctions
	-- 25-28 - double junctions "anglik"
	-- 41-48 - 3-way junctions
	-- 53-56 - buffers
	-- 57-60 - derailers
	-- 61-68 - signals/semaphores
	-- 69-71 - entrances/exits
	-- 72 - depo
	-- 73 - tory postojowe

	self.id = id
	self.electrified = electrified ~= false

	self.trackID = nil
	self.switchID = nil
	self.switchFlip = false
	self.switchFlipABCD = false
	self.semaphoreID = nil
	self.itineraryEndID = nil
end

---Returns whether this Tile is a switch, regardless of its type.
---@return boolean
function Tile:isSwitch()
	return self.id >= 17 and self.id <= 48
end

---Returns whether this Tile is a double switch ("rozjazd krzyżowy").
---@return boolean
function Tile:isDoubleSwitch()
	return self.id >= 25 and self.id <= 28
end

---Returns whether this Tile is a semaphore.
---@return boolean
function Tile:isSemaphore()
	return self.id >= 61 and self.id <= 68
end

---Returns the track ID for this Tile. Returns `nil` if no track ID has been specified for this tile.
---@return string?
function Tile:getTrackID()
	return self.trackID
end

---Sets a new track ID for this Tile. Passing `nil` or an empty string will clear the track ID from this tile.
---@param trackID string? The new track ID.
function Tile:setTrackID(trackID)
	self.trackID = trackID ~= "" and trackID or nil
end

---Returns the switch ID for this Tile. Returns `nil` if no switch ID has been specified for this tile.
---@return string?
function Tile:getSwitchID()
	return self.switchID
end

---Sets a new switch ID for this Tile. Passing `nil` or an empty string will clear the switch ID from this tile.
---@param switchID string? The new switch ID.
function Tile:setSwitchID(switchID)
	self.switchID = switchID ~= "" and switchID or nil
end

---Returns whether the switch's sides are flipped ("+" means straight, "-" means left/right).
---@return boolean
function Tile:getSwitchFlip()
	return self.switchFlip
end

---Sets whether the switch's sides are flipped ("+" means straight, "-" means left/right).
---@param switchFlip boolean The new flip state.
function Tile:setSwitchFlip(switchFlip)
	self.switchFlip = switchFlip
end

---Returns whether the double switch's sides are flipped (`ab` is on the right side, `cd` is on the left side).
---@return boolean
function Tile:getSwitchFlipABCD()
	return self.switchFlipABCD
end

---Sets whether the double switch's sides are flipped (`ab` is on the right side, `cd` is on the left side).
---@param switchFlipABCD boolean The new flip state.
function Tile:setSwitchFlipABCD(switchFlipABCD)
	self.switchFlipABCD = switchFlipABCD
end

---Returns the semaphore ID for this Tile. Returns `nil` if no semaphore ID has been specified for this tile.
---@return string?
function Tile:getSemaphoreID()
	return self.semaphoreID
end

---Sets a new semaphore ID for this Tile. Passing `nil` or an empty string will clear the semaphore ID from this tile.
---@param semaphoreID string? The new semaphore ID.
function Tile:setSemaphoreID(semaphoreID)
	self.semaphoreID = semaphoreID ~= "" and semaphoreID or nil
end

---Returns the itinerary end ID for this Tile. Returns `nil` if no such ID is specified.
---@return string?
function Tile:getItineraryEndID()
	return self.itineraryEndID
end

---Sets a new itinerary end ID for this Tile. Passing `nil` or an empty string will clear this ID from this tile.
---@param itineraryEndID string? The new itinerary end ID.
function Tile:setItineraryEndID(itineraryEndID)
	self.itineraryEndID = itineraryEndID ~= "" and itineraryEndID or nil
end

---Returns the current track state in the simulation.
---If no track ID is specified for this tile, the function will return `nil`.
---@return TrackState?
function Tile:getTrackState()
	return self.trackID and _Obj.getTrackState(self.trackID)
end

---Returns whether this tile's track is occupied, or `nil` if no track is specified for this tile.
---@return boolean?
function Tile:isTrackOccupied()
	local state = self:getTrackState()
	return state and state.occupied
end

---Returns whether this tile's track is reserved, or `nil` if no track is specified for this tile.
---@return boolean?
function Tile:isTrackReserved()
	local state = self:getTrackState()
	return state and state.reserved
end

---Returns the state for this tile's switch, or `nil` if no switch is specified for this tile.
---@param suffix "ab"|"cd"? Used for double switches, where the suffix determines which subswitch state should be returned.
---@return boolean?
function Tile:getSwitchState(suffix)
	local state = self.switchID and _Obj.getSwitchState(self.switchID .. (suffix or ""))
	return state and state.state
end

---Returns this tile's semaphore image, or `nil` if no semaphore is specified for this tile.
---@return string?
function Tile:getSemaphoreState()
	local state = self.semaphoreID and _Obj.getSemaphoreState(self.semaphoreID)
	return state and state.image
end

---Returns a flipped double switch suffix if the `switchFlipABCD` property is set on this tile.
---@param suffix "ab"|"cd"? The switch suffix to be flipped.
---@return string?
function Tile:flipSwitchSuffix(suffix)
	if not suffix or not self.switchFlipABCD then
		return suffix
	end
	return suffix == "ab" and "cd" or "ab"
end

---Sends a command to the server to change the state of this tile's track.
---@param state "free"|"busy"|"res" The new state for this track to be set.
function Tile:sendTrackState(state)
	if self.trackID then
		_Com.sendCommand("t " .. self.trackID .. " " .. state)
	end
end

---Sends a command to the server to change this tile's switch state.
---@param state boolean `false` is the "-" position, `true` is the "+" position.
---@param suffix "ab"|"cd"? Used for double switches, where the suffix determines which subswitch state should be changed.
function Tile:sendSwitchState(state, suffix)
	if self.switchID then
		_Com.sendCommand("j " .. self.switchID .. (suffix or "") .. " " .. (state and "+" or "-"))
	end
end

---Sends a command to the server to set the speeds on this tile's semaphore.
---@param this integer The current speed to be displayed.
---@param next integer? The next speed to be displayed.
function Tile:sendSemaphoreState(this, next)
	if self.semaphoreID then
		_Com.sendCommand("s " .. self.semaphoreID .. " " .. this .. (next and (" " .. next) or ""))
	end
end

---Sends a command to the server to dispatch an itinerary from this tile's semaphore.
---@param name string The itinerary name to be dispatched.
function Tile:sendItinerary(name)
	if self.semaphoreID then
		_Com.sendCommand("i " .. self.semaphoreID .. " " .. name)
	end
end

---Draws this Tile at the specified position.
---@param x number The X coordinate of the top left corner of this tile's position.
---@param y number The Y coordinate of the top left corner of this tile's position.
function Tile:draw(x, y)
	local track = _TileDB.tiles[self.id]
	if not track then
		return
	end
	-- Calculate switch dim bits
	local switchDimBits = 0
	if track.tracks then
		for i = 1, 8 do
			local dim = false
			if track.dirs then
				local dirData = track.dirs[i]
				if dirData then
					local switchState = self:getSwitchState(self:flipSwitchSuffix(dirData:sub(1, #dirData - 1)))
					local expectedState = dirData:sub(#dirData) == "+"
					dim = switchState ~= nil and (switchState ~= self.switchFlip) ~= expectedState
				end
			end
			if dim then
				switchDimBits = switchDimBits + 2 ^ (i - 1)
			end
		end
	end
	_DrawTile(x + self.offset, y + self.offset, self.id, self.electrified, self:isTrackOccupied(), self:isTrackReserved(), switchDimBits, self:getSemaphoreState())
end

---Draws this Tile's background at the specified position.
---@param x number The X coordinate of the top left corner of this tile's position.
---@param y number The Y coordinate of the top left corner of this tile's position.
function Tile:drawBackground(x, y)
	local green = _Picker.selection == "properties" and self.trackID
	if green then
		love.graphics.setColor(0.2, 0.8, 0.2)
	else
		love.graphics.setColor(0.4, 0.4, 0.4)
	end
	love.graphics.rectangle("fill", x, y, self.size, self.size)
	if green then
		love.graphics.setColor(0.1, 0.4, 0.1)
	else
		love.graphics.setColor(0.2, 0.2, 0.2)
	end
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x, y, self.size, self.size)
end

local FRAME_COLORS = {
	hover = {0, 1, 1},
	selection = {0, 1, 0},
	active = {1, 0, 1},
	clickable = {1, 1, 0}
}

---Draws this Tile's frame at the specified position.
---@private
---@param x number The X coordinate of the top left corner of this tile's position.
---@param y number The Y coordinate of the top left corner of this tile's position.
---@param color [number, number, number] The frame color.
function Tile:drawFrame(x, y, color)
	love.graphics.setColor(color[1], color[2], color[3], 0.2)
	love.graphics.rectangle("fill", x, y, self.size, self.size)
	love.graphics.setColor(color)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x, y, self.size, self.size)
end

---Draws this Tile's hover frame at the specified position.
---@param x number The X coordinate of the top left corner of this tile's position.
---@param y number The Y coordinate of the top left corner of this tile's position.
function Tile:drawHover(x, y)
	self:drawFrame(x, y, FRAME_COLORS.hover)
end

---Draws this Tile's selection frame at the specified position.
---@param x number The X coordinate of the top left corner of this tile's position.
---@param y number The Y coordinate of the top left corner of this tile's position.
function Tile:drawSelection(x, y)
	self:drawFrame(x, y, FRAME_COLORS.selection)
end

---Draws this Tile's active frame at the specified position.
---@param x number The X coordinate of the top left corner of this tile's position.
---@param y number The Y coordinate of the top left corner of this tile's position.
function Tile:drawActive(x, y)
	self:drawFrame(x, y, FRAME_COLORS.active)
end

---Draws this Tile's clickable frame at the specified position.
---@param x number The X coordinate of the top left corner of this tile's position.
---@param y number The Y coordinate of the top left corner of this tile's position.
function Tile:drawClickable(x, y)
	self:drawFrame(x, y, FRAME_COLORS.clickable)
end

---Serializes this Tile's data to be saved. If this Tile is empty, `nil` is returned to save space.
---@return table?
function Tile:serialize()
	if self.id == 0 then
		return nil
	end
	return {
		id = self.id,
		electrified = self.electrified,
		trackID = self.trackID,
		switchID = self.switchID,
		switchFlip = self.switchFlip or nil,
		switchFlipABCD = self.switchFlipABCD or nil,
		semaphoreID = self.semaphoreID,
		itineraryEndID = self.itineraryEndID
	}
end

---Deserializes previously saved Tile's data and loads it into this tile.
---@param t table Data to be deserialized. `nil` is not permitted even though it can be returned by `:serialize()`.
function Tile:deserialize(t)
	self.id = t.id or 0
	self.electrified = t.electrified
	self.trackID = t.trackID
	self.switchID = t.switchID
	self.switchFlip = t.switchFlip == true
	self.switchFlipABCD = t.switchFlipABCD == true
	self.semaphoreID = t.semaphoreID
	self.itineraryEndID = t.itineraryEndID
end

return Tile
