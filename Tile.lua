local class = require "class"

---@class Tile : Class
---@overload fun(station: Station, x: integer, y: integer): Tile
local Tile = class:derive("Tile")

---Creates a new Tile.
---@param station Station The station this Tile is a part of.
---@param x integer The X coordinate of this tile.
---@param y integer The Y coordinate of this tile.
function Tile:new(station, x, y)
	self.station = station
	self.x, self.y = x, y
	self.size = 14
	self.offset = 0

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

	self.id = 0
	self.electrified = false
	self.trackID = nil
	self.switchID = nil
	self.switchFlip = false
	self.switchFlipABCD = false
	self.semaphoreID = nil
	self.semaphoreType = nil
	self.semaphoreAllowTrain = false
	self.semaphoreAllowShunt = false
	self.semaphoreAllowSz = false
	self.semaphoreShape = false
	self.semaphoreNoW24 = false
	self.semaphoreNoDanger = false
	self.itineraryEndID = nil -- TODO: Later on, check whether we need this. The only reason we would need this is for dispatcher algorithms.
	self.maxSpeed = math.huge
	self.maxSpeedPlus = math.huge
	self.maxSpeedMinus = math.huge
	self.trainTarget = false
	self.shuntTarget = false
	self.targetW24 = false
	self.forbidTrain = false
	self.forbidShunt = false
	self.warp = nil
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

---Sets a new tile ID for this tile.
---@param id integer The new ID.
function Tile:setID(id)
	self.id = id
end

---Returns whether this Tile is electrified.
---@return boolean
function Tile:isElectrified()
	return self.electrified
end

---Sets whether this Tile is electrified.
---@param electrified boolean Whether this Tile should be electrified.
function Tile:setElectrified(electrified)
	self.electrified = electrified
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

---Returns the semaphore type assigned for this Tile.
---@return SemaphoreType
function Tile:getSemaphoreType()
	return self.semaphoreType or SemaphoreType.SEM
end

---Sets a new semaphore type for this Tile.
---@param semaphoreType SemaphoreType? The new semaphore type to be assigned.
function Tile:setSemaphoreType(semaphoreType)
	self.semaphoreType = semaphoreType
end

---Returns whether this tile's semaphore can display a train signal.
---@return boolean
function Tile:getSemaphoreAllowTrain()
	return self.semaphoreAllowTrain
end

---Sets whether this tile's semaphore can display a train signal.
---@param semaphoreAllowTrain boolean
function Tile:setSemaphoreAllowTrain(semaphoreAllowTrain)
	self.semaphoreAllowTrain = semaphoreAllowTrain
end

---Returns whether this tile's semaphore can display a shunting signal.
---@return boolean
function Tile:getSemaphoreAllowShunt()
	return self.semaphoreAllowShunt
end

---Sets whether this tile's semaphore can display a shunting signal.
---@param semaphoreAllowShunt boolean
function Tile:setSemaphoreAllowShunt(semaphoreAllowShunt)
	self.semaphoreAllowShunt = semaphoreAllowShunt
end

---Returns whether this tile's semaphore can display an Sz signal.
---@return boolean
function Tile:getSemaphoreAllowSz()
	return self.semaphoreAllowSz
end

---Sets whether this tile's semaphore can display an Sz signal.
---@param semaphoreAllowSz boolean
function Tile:setSemaphoreAllowSz(semaphoreAllowSz)
	self.semaphoreAllowSz = semaphoreAllowSz
end

---Returns whether this tile's semaphore is a shape semaphore.
---@return boolean
function Tile:getSemaphoreShape()
	return self.semaphoreShape
end

---Sets whether this tile's semaphore is a shape semaphore.
---@param semaphoreShape boolean
function Tile:setSemaphoreShape(semaphoreShape)
	self.semaphoreShape = semaphoreShape
end

---Returns whether this tile's semaphore has NO W24 sign.
---@return boolean
function Tile:getSemaphoreNoW24()
	return self.semaphoreNoW24
end

---Sets whether this tile's semaphore has NO W24 sign.
---@param semaphoreNoW24 boolean
function Tile:setSemaphoreNoW24(semaphoreNoW24)
	self.semaphoreNoW24 = semaphoreNoW24
end

---Returns whether this tile's semaphore has no danger (next semaphore must be displaying a >=100 speed).
---@return boolean
function Tile:getSemaphoreNoDanger()
	return self.semaphoreNoDanger
end

---Sets whether this tile's semaphore has no danger (next semaphore must be displaying a >=100 speed).
---@param semaphoreNoDanger boolean
function Tile:setSemaphoreNoDanger(semaphoreNoDanger)
	self.semaphoreNoDanger = semaphoreNoDanger
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

---Returns the maximum speed for this Tile. Returns `math.huge` if no limit is specified.
---@return number
function Tile:getMaxSpeed()
	return self.maxSpeed
end

---Sets a new maximum speed for this Tile, or clears it if `nil` is provided.
---@param speed number? New speed.
function Tile:setMaxSpeed(speed)
	self.maxSpeed = speed or math.huge
end

---Returns the maximum speed for this Tile when the switch on this Tile is set to `true` ("+"). Returns `math.huge` if no limit is specified.
---@return number
function Tile:getMaxSpeedPlus()
	return self.maxSpeedPlus
end

---Sets a new maximum speed for this Tile when the switch on this Tile is set to `true` ("+"), or clears it if `nil` is provided.
---@param speed number? New speed.
function Tile:setMaxSpeedPlus(speed)
	self.maxSpeedPlus = speed or math.huge
end

---Returns the maximum speed for this Tile when the switch on this Tile is set to `false` ("-"). Returns `math.huge` if no limit is specified.
---@return number
function Tile:getMaxSpeedMinus()
	return self.maxSpeedMinus
end

---Sets a new maximum speed for this Tile when the switch on this Tile is set to `false` ("-"), or clears it if `nil` is provided.
---@param speed number? New speed.
function Tile:setMaxSpeedMinus(speed)
	self.maxSpeedMinus = speed or math.huge
end

---Returns whether this Tile can be used as a target for train paths.
---@return boolean
function Tile:isTrainTarget()
	return self.trainTarget
end

---Sets whether this Tile can be used as a target for train paths.
---@param trainTarget boolean Whether this Tile can be used as a target for train paths.
function Tile:setTrainTarget(trainTarget)
	self.trainTarget = trainTarget
end

---Returns whether this Tile can be used as a target for shunting paths.
---@return boolean
function Tile:isShuntTarget()
	return self.shuntTarget
end

---Sets whether this Tile can be used as a target for shunting paths.
---@param shuntTarget boolean
function Tile:setShuntTarget(shuntTarget)
	self.shuntTarget = shuntTarget
end

---Returns whether this Tile's target will make its pathfinding semaphore display a W24 signal.
---@return boolean
function Tile:isTargetW24()
	return self.targetW24
end

---Sets whether this Tile's target will make its pathfinding semaphore display a W24 signal.
---@param targetW24 boolean
function Tile:setTargetW24(targetW24)
	self.targetW24 = targetW24
end

---Returns whether this Tile is excluded from pathfinding train signals.
---@return boolean
function Tile:isTrainForbidden()
	return self.forbidTrain
end

---Sets whether this Tile is excluded from pathfinding train signals.
---@param forbidTrain boolean Whether to exclude trains.
function Tile:setForbidTrain(forbidTrain)
	self.forbidTrain = forbidTrain
end

---Returns whether this Tile is excluded from pathfinding shunting signals.
---@return boolean
function Tile:isShuntForbidden()
	return self.forbidShunt
end

---Sets whether this Tile is excluded from pathfinding shunting signals.
---@param forbidShunt boolean Whether to exclude shunting trains.
function Tile:setForbidShunt(forbidShunt)
	self.forbidShunt = forbidShunt
end

---Returns an index (shortcut) of the station to jump to when this tile is clicked, if any.
---@return string?
function Tile:getWarp()
	return self.warp
end

---Sets an index (shortcut) of the station to jump to when this tile is clicked.
---@param warp string? A new station. Pass `nil` to remove warp.
function Tile:setWarp(warp)
	self.warp = warp
end

--######################################--
---------------- L O G I C ---------------
--######################################--

---Returns the neighbor tile in the provided direction, or `nil` if we're out of bounds.
---@param dir integer The direction for which the tile should be returned.
function Tile:getNeighbor(dir)
	return self.station:getTile(self.x + _DIRS[dir].x, self.y + _DIRS[dir].y)
end

---Returns `true` if this Tile has a track in that direction.
---@param dir integer The direction for the track to be looked for.
---@return boolean
function Tile:hasTrackInDirection(dir)
	local track = _TileDB.tiles[self.id]
	return track and track.tracks and _Utils.getBit(track.tracks, dir) or false
end

---Returns `true` if this Tile has a track in the specified direction, taking the switch state into account.
---@param dir integer The direction for the track to be looked for.
---@return boolean
function Tile:hasTraversibleTrackInDirection(dir)
	if not self:hasTrackInDirection(dir) then
		return false
	end
	local track = _TileDB.tiles[self.id]
	if not track.dirs then
		-- No switch.
		return true
	end
	local dirData = track.dirs[dir]
	if not dirData then
		-- This direction is not governed by the switch.
		return true
	end
	local switchState = self:getSwitchState(self:flipSwitchSuffix(dirData:sub(1, #dirData - 1)))
	local expectedState = dirData:sub(#dirData) == "+"
	return switchState == nil or (switchState.state ~= self.switchFlip) == expectedState
end

---Returns a list of directions for pathfinders to be able to go towards, starting from this tile.
---@return integer[]
function Tile:getTrackDirections()
	local results = {}
	for i = 1, 8 do
		if self:hasTrackInDirection(i) then
			table.insert(results, i)
		end
	end
	return results
end

---Returns a list of 0 to 3 directions for pathfinders to be able to go towards, when going from the specified direction.
---@param sourceDir integer The direction from which we are going from.
---@return integer[]
function Tile:getPossibleTrackDirections(sourceDir)
	local straight = _InvertDir(sourceDir)
	local left = (straight - 2) % 8 + 1
	local right = straight % 8 + 1
	local results = {}
	if self:hasTrackInDirection(straight) then
		table.insert(results, straight)
	end
	if self:hasTrackInDirection(left) then
		table.insert(results, left)
	end
	if self:hasTrackInDirection(right) then
		table.insert(results, right)
	end
	return results
end

---Returns a direction for pathfinders to go towards, when going from the specified direction, depending on the switch states.
---Returns `nil` if we hit a dead end.
---@param sourceDir integer The direction from which we are going from.
---@return integer?
function Tile:getNextTrackDirection(sourceDir)
	for i = 1, 8 do
		if i ~= sourceDir and self:hasTraversibleTrackInDirection(i) then
			return i
		end
	end
end

---Returns whether this Tile is a target for the specified path mode.
---@param mode PathMode The path mode to be checked against.
---@return boolean
function Tile:isTargetForMode(mode)
	if mode == PathMode.TRAIN then
		return self:isTrainTarget()
	elseif mode == PathMode.SHUNT then
		return self:isShuntTarget()
	end
	return false
end

---Returns whether this Tile is a valid target for whether the semaphore pathfinding to it has a W24 signal.
---@param w24 boolean Whether the initial semaphore can display the W24 signal.
---@return boolean
function Tile:isTargetForW24(w24)
	return w24 or not self:isTargetW24()
end

---Returns whether this Tile is traversible by the specified path mode.
---@param mode PathMode The path mode to be checked against.
---@return boolean
function Tile:isPathModeAllowed(mode)
	if mode == PathMode.TRAIN then
		return not self:isTrainForbidden()
	elseif mode == PathMode.SHUNT then
		return not self:isShuntForbidden()
	end
	return true
end

---Returns the current track state in the simulation.
---If no track ID is specified for this tile, the function will return `nil`.
---@return TrackState?
function Tile:getTrackState()
	return self.trackID and _Obj:getTrackState(self.trackID)
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

---Returns whether this tile's track is neither occupied nor reserved, or `nil` if no track is specified for this tile.
---@return boolean?
function Tile:isTrackClear()
	local state = self:getTrackState()
	return state and not (state.occupied or state.reserved)
end

---Returns the state for this tile's switch, or `nil` if no switch is specified for this tile.
---@param suffix "ab"|"cd"? Used for double switches, where the suffix determines which subswitch state should be returned.
---@return SwitchState?
function Tile:getSwitchState(suffix)
	return self.switchID and _Obj:getSwitchState(self.switchID .. (suffix or ""))
end

---Returns whether this tile's switch has been forcefully switched, or `nil` if no switch is specified for this tile.
---@return boolean?
function Tile:isSwitchForced()
	local main = self:getSwitchState()
	local ab = self:getSwitchState("ab")
	local cd = self:getSwitchState("cd")
	return (main and main.forced) or (ab and ab.forced) or (cd and cd.forced)
end

---Returns the direction towards which this tile's semaphore is pointing, or `nil` if there's no semaphore.
---@return integer?
function Tile:getSemaphoreDirection()
	local track = _TileDB.tiles[self.id]
	return track and track.semaphore and (3 - track.semaphore) % 8 + 1
end

---Returns this tile's semaphore state, or `nil` if no semaphore is specified for this tile.
---@return SemaphoreState?
function Tile:getSemaphoreState()
	return self.semaphoreID and _Obj:getSemaphoreState(self.semaphoreID)
end

---Returns whether this tile's semaphore is displaying a stop signal (S1 or Ms1), or `nil` if there's no semaphore.
---@return boolean?
function Tile:isSemaphoreStop()
	local state = self:getSemaphoreState()
	return state and (state.speed == Speed.STOP or state.speed == Speed.MS1)
end

---Returns the current maximum speed on this Tile, or `nil` if there is no speed limit.
---@return number
function Tile:getSpeed()
	local main = self:getSwitchState()
	local ab = self:getSwitchState("ab")
	local cd = self:getSwitchState("cd")
	return self:getSpeedForSwitchStates({[""] = main and main.state, ab = ab and ab.state, cd = cd and cd.state})
end

---Returns the maximum speed on this Tile were the switches in the specified states, or `nil` if there is no speed limit.
---@param states table<""|"ab"|"cd", boolean?>
---@return number
function Tile:getSpeedForSwitchStates(states)
	local speed = self.maxSpeed
	if self:isSwitch() then
		local switchSpeed
		if self:isDoubleSwitch() then
			-- Straight = "-", curve = "+"
			switchSpeed = states["ab"] ~= states["cd"] and self.maxSpeedPlus or self.maxSpeedMinus
		else
			switchSpeed = states[""] and self.maxSpeedPlus or self.maxSpeedMinus
		end
		speed = math.min(speed, switchSpeed)
	end
	return speed
end

---Returns the maximum speed on this Tile when going from dir1 to dir2, or `nil` if no speed limit exists for that relation.
---@param dir1 integer? First direction.
---@param dir2 integer? Second direction.
---@return number
function Tile:getSpeedForDirections(dir1, dir2)
	return self:getSpeedForSwitchStates(self:getSwitchStatesForDirections(dir1, dir2))
end

---Given two directions, if this Tile is a switch tile, returns a table mapping switch suffixes to their states for this Tile.
---@param dir1 integer? First direction.
---@param dir2 integer? Second direction.
---@return table<""|"ab"|"cd", boolean?>
function Tile:getSwitchStatesForDirections(dir1, dir2)
	local switchStates = {}
	local track = _TileDB.tiles[self.id]
	if not track or not track.dirs then
		return switchStates
	end
	if dir1 then
		local dirData1 = track.dirs[dir1]
		if dirData1 then
			local state = (dirData1:sub(#dirData1) == "+") ~= self.switchFlip
			switchStates[self:flipSwitchSuffix(dirData1:sub(1, dirData1:len() - 1))] = state
		end
	end
	if dir2 then
		local dirData2 = track.dirs[dir2]
		if dirData2 then
			local state = (dirData2:sub(#dirData2) == "+") ~= self.switchFlip
			switchStates[self:flipSwitchSuffix(dirData2:sub(1, dirData2:len() - 1))] = state
		end
	end
	return switchStates
end

---Returns a flipped double switch suffix if the `switchFlipABCD` property is set on this tile.
---@param suffix ""|"ab"|"cd"? The switch suffix to be flipped.
---@return string?
function Tile:flipSwitchSuffix(suffix)
	if not suffix or suffix == "" or not self.switchFlipABCD then
		return suffix
	end
	return suffix == "ab" and "cd" or "ab"
end

--################################################--
---------------- S I M U L A T I O N ---------------
--################################################--

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

---Sends a command to the server to unforce tile's switch. ("kasowanie rozprucia rozjazdu")
function Tile:sendSwitchUnforce()
	if self.switchID then
		_Com.sendCommand("ju " .. self.switchID)
		_Com.sendCommand("ju " .. self.switchID .. "ab")
		_Com.sendCommand("ju " .. self.switchID .. "cd")
	end
end

---Sends a command to the server to set the speeds on this tile's semaphore.
---@param this Speed The current speed to be displayed.
---@param next Speed|string? The next speed or the next semaphore ID to be displayed.
---@param extras "w24"? An additional token to be sent, for example to show W24.
function Tile:sendSemaphoreState(this, next, extras)
	if self.semaphoreID then
		_Com.sendCommand("s " .. self.semaphoreID .. " " .. this .. (next and (" " .. next) or "") .. (extras and (" " .. extras) or ""))
	end
end

---Sends a command to the server to cancel this tile's semaphore's itinerary.
function Tile:sendSemaphoreUnreserve()
	if self.semaphoreID then
		_Com.sendCommand("su " .. self.semaphoreID)
	end
end

--##########################################--
---------------- D R A W I N G ---------------
--##########################################--

---Returns the position of the top left corner of this tile on the station canvas.
---@return number, number
function Tile:getPos()
	return self.station:coordsToCanvasPos(self.x, self.y)
end

---Draws this Tile at the specified position.
function Tile:draw()
	local track = _TileDB.tiles[self.id]
	if not track then
		return
	end
	local x, y = self:getPos()
	-- Calculate switch dim bits
	local switchDimBits = 0
	if track.tracks then
		for i = 1, 8 do
			if not self:hasTraversibleTrackInDirection(i) then
				switchDimBits = switchDimBits + 2 ^ (i - 1)
			end
		end
	end
	_DrawTile(x + self.offset, y + self.offset, self.id, self.electrified, self:isTrackOccupied(), self:isTrackReserved(), self:isSwitchForced(), switchDimBits, self:getSemaphoreState())
end

---Draws this Tile's background at the specified position.
function Tile:drawBackground()
	local x, y = self:getPos()
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
	clickable = {1, 1, 0},
	rectSelection = {0, 1, 1}
}

---Draws this Tile's frame at the specified position.
---@private
---@param color [number, number, number] The frame color.
function Tile:drawFrame(color)
	local x, y = self:getPos()
	love.graphics.setColor(color[1], color[2], color[3], 0.2)
	love.graphics.rectangle("fill", x, y, self.size, self.size)
	love.graphics.setColor(color)
	love.graphics.setLineWidth(2)
	love.graphics.rectangle("line", x, y, self.size, self.size)
end

---Draws this Tile's hover frame at the specified position.
function Tile:drawHover()
	self:drawFrame(FRAME_COLORS.hover)
end

---Draws this Tile's selection frame at the specified position.
function Tile:drawSelection()
	self:drawFrame(FRAME_COLORS.selection)
end

---Draws this Tile's active frame at the specified position.
function Tile:drawActive()
	self:drawFrame(FRAME_COLORS.active)
end

---Draws this Tile's clickable frame at the specified position.
function Tile:drawClickable()
	self:drawFrame(FRAME_COLORS.clickable)
end

---Draws this Tile's rectangular selection frame at the specified position.
function Tile:drawRectSelection()
	self:drawFrame(FRAME_COLORS.rectSelection)
end

--####################################--
---------------- D A T A ---------------
--####################################--

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
		semaphoreType = self.semaphoreType,
		semaphoreAllowTrain = self.semaphoreAllowTrain or nil,
		semaphoreAllowShunt = self.semaphoreAllowShunt or nil,
		semaphoreAllowSz = self.semaphoreAllowSz or nil,
		semaphoreShape = self.semaphoreShape or nil,
		semaphoreNoW24 = self.semaphoreNoW24 or nil,
		semaphoreNoDanger = self.semaphoreNoDanger or nil,
		itineraryEndID = self.itineraryEndID,
		maxSpeed = self.maxSpeed ~= math.huge and self.maxSpeed or nil,
		maxSpeedPlus = self.maxSpeedPlus ~= math.huge and self.maxSpeedPlus or nil,
		maxSpeedMinus = self.maxSpeedMinus ~= math.huge and self.maxSpeedMinus or nil,
		trainTarget = self.trainTarget or nil,
		shuntTarget = self.shuntTarget or nil,
		targetW24 = self.targetW24 or nil,
		forbidTrain = self.forbidTrain or nil,
		forbidShunt = self.forbidShunt or nil,
		warp = self.warp
	}
end

---Deserializes previously saved Tile's data and loads it into this tile.
---@param t table? Data to be deserialized. `nil` will make nothing happen.
function Tile:deserialize(t)
	if not t then
		return
	end
	self.id = t.id or 0
	self.electrified = t.electrified
	self.trackID = t.trackID
	self.switchID = t.switchID
	self.switchFlip = t.switchFlip == true
	self.switchFlipABCD = t.switchFlipABCD == true
	self.semaphoreID = t.semaphoreID
	self.semaphoreType = t.semaphoreType
	self.semaphoreAllowTrain = t.semaphoreAllowTrain == true
	self.semaphoreAllowShunt = t.semaphoreAllowShunt == true
	self.semaphoreAllowSz = t.semaphoreAllowSz == true
	self.semaphoreShape = t.semaphoreShape == true
	self.semaphoreNoW24 = t.semaphoreNoW24 == true
	self.semaphoreNoDanger = t.semaphoreNoDanger == true
	self.itineraryEndID = t.itineraryEndID
	self.maxSpeed = t.maxSpeed or math.huge
	self.maxSpeedPlus = t.maxSpeedPlus or math.huge
	self.maxSpeedMinus = t.maxSpeedMinus or math.huge
	self.trainTarget = t.trainTarget == true
	self.shuntTarget = t.shuntTarget == true
	self.targetW24 = t.targetW24 == true
	self.forbidTrain = t.forbidTrain == true
	self.forbidShunt = t.forbidShunt == true
	self.warp = t.warp
end

return Tile
