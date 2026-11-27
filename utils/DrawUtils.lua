local Tileset = require("Tileset")
local BlockadeDirection = require("lua.core.Enums.BlockadeDirection")

---Functions for dealing with tile drawing.
local DrawUtils = {}

DrawUtils.tracks = Tileset("data/tracks.png", 18, 10, 14, 14)

---Turns the track flags into the track color to be displayed on the tile.
---@param electrified boolean? Whether the track is electrified.
---@param occupied boolean? Whether the track is occupied.
---@param reserved boolean? Whether the track is reserved.
---@param alarm boolean? Whether the track should flash red (for example when a switch is forced).
---@return TrackColor
function DrawUtils.getTrackColor(electrified, occupied, reserved, alarm)
	if alarm or occupied then
		return TrackColor.OCCUPIED
	elseif reserved then
		return TrackColor.RESERVED
	elseif electrified then
		return TrackColor.ELECTRIFIED
	end
	return TrackColor.BASE
end

---Turns the blockade state into the blockade color to be displayed on the tile.
---@param blockadeState Blockade|BlockadeDirection? The blockade state to be displayed.
---@return BlockadeColor
function DrawUtils.getBlockadeColor(blockadeState)
	if not blockadeState then
		return BlockadeColor.NONE
	elseif blockadeState == BlockadeDirection.BACKWARD then
		return BlockadeColor.BACKWARD
	elseif blockadeState == BlockadeDirection.FORWARD then
		return BlockadeColor.FORWARD
	elseif blockadeState.direction == BlockadeDirection.BACKWARD then
		return BlockadeColor.BACKWARD
	elseif blockadeState.direction == BlockadeDirection.FORWARD then
		return BlockadeColor.FORWARD
	end
	return BlockadeColor.OFF
end

---Draws tile graphics.
---@param x number Top left corner X screen coordinate.
---@param y number Top left corner Y screen coordinate.
---@param id string Tile ID in the database.
---@param electrified boolean? Whether the track is electrified.
---@param occupied boolean? Whether the track is occupied.
---@param reserved boolean? Whether the track is reserved.
---@param alarm boolean? Whether the track should flash red (for example when a switch is forced).
---@param switchDimBits integer Bitmask of directions which should be dark on track tiles.
---@param semaphore Semaphore|string? Semaphore, or its image directly.
---@param blockade Blockade|BlockadeDirection? Blockade, or its state directly.
---@param scale number? Tile scale.
---@param opacity number? Tile opacity, from 0 to 1.
function DrawUtils.drawTile(x, y, id, electrified, occupied, reserved, alarm, switchDimBits, semaphore, blockade, scale, opacity)
	local data = _TileDB:getTile(id)
	-- Background
	love.graphics.setColor(1, 1, 1, opacity)
	if data.background then
		DrawUtils.tracks:drawTile(data.background, 1, x, y, scale)
	end
	if data.backgroundXY then
		DrawUtils.tracks:drawTile(data.backgroundXY[1], data.backgroundXY[2], x, y, scale)
	end
	if data.tracks and not data.exit and not data.blockade then
		for i = 1, 8 do
			if _Utils.getBit(data.tracks, i) then
				DrawUtils.tracks:drawTile(i, 1, x, y, scale)
			end
		end
	end
	if data.buffer then
		DrawUtils.tracks:drawTile(data.buffer, 3, x, y, scale)
	end
	if data.blockade then
		DrawUtils.tracks:drawTile(data.blockade, 9, x, y, scale)
	end
	-- Blockade
	if data.blockade then
		local blockadeColor = DrawUtils.getBlockadeColor(blockade)
		love.graphics.setColor(blockadeColor[1], blockadeColor[2], blockadeColor[3], opacity)
		DrawUtils.tracks:drawTile(data.blockade, 10, x, y, scale)
	end
	-- Track
	local color = DrawUtils.getTrackColor(electrified, occupied, reserved, alarm)
	love.graphics.setColor(color[1], color[2], color[3], opacity)
	if data.tracks and not data.exit and not data.blockade then
		for i = 1, 8 do
			local dim = _Utils.getBit(switchDimBits, i)
			if _Utils.getBit(data.tracks, i) and not dim and (not alarm or _T % 0.4 < 0.2) then
				DrawUtils.tracks:drawTile(i, 2, x, y, scale)
			end
		end
	end
	if data.foreground then
		DrawUtils.tracks:drawTile(data.foreground, 2, x, y, scale)
	end
	-- Derailer
	love.graphics.setColor(1, 1, 1, opacity)
	if data.derailer then
		DrawUtils.tracks:drawTile(data.derailer, 7, x, y, scale)
	end
	if data.derailerL then
		DrawUtils.tracks:drawTile(data.derailerL, 8, x, y, scale)
	end
	-- Semaphore
	if data.semaphore then
		DrawUtils.tracks:drawTile(data.semaphore, 4, x, y, scale)
		local image = semaphore and SemaphoreImage[type(semaphore) == "string" and semaphore or semaphore.image]
		if image then
			if image.color1 and (not image.blink1 or _T % 1 < 0.5) then
				love.graphics.setColor(image.color1[1], image.color1[2], image.color1[3], opacity)
				DrawUtils.tracks:drawTile(data.semaphore, 5, x, y, scale)
			end
			if image.color2 and (not image.blink2 or _T % 1 < 0.5) then
				love.graphics.setColor(image.color2[1], image.color2[2], image.color2[3], opacity)
				DrawUtils.tracks:drawTile(data.semaphore, 6, x, y, scale)
			end
		end
	end
end

---Draws tile's background graphics.
---@param x number Top left corner X screen coordinate.
---@param y number Top left corner Y screen coordinate.
---@param scale number? Tile scale.
---@param opacity number? Tile opacity, from 0 to 1.
function DrawUtils.drawTileBackground(x, y, scale, opacity)
	love.graphics.setColor(1, 1, 1, opacity)
    DrawUtils.tracks:drawTile(18, 3, x, y, scale)
end

return DrawUtils