require("main_enums")
_Utils = require("utils")
_Com = require("communication")
local Settings = require("Settings")
local Objects = require("Objects")
local UI = require("UI")
local Notifications = require("Notifications")
local Tileset = require("Tileset")
local Project = require("Project")
local Picker = require("Picker")
local TileDatabase = require("TileDatabase")

_WWIDTH, _WHEIGHT = 1600, 900
_MouseX, _MouseY = 0, 0
_Time = 0
_Font = love.graphics.newFont("data/dejavusans.ttf", 16)

_Settings = Settings()
_Obj = Objects()
_UI = UI()
_Notifications = Notifications()
_Tracks = Tileset("data/tracks.png", 17, 8, 14, 14)
_Buttons = Tileset("data/buttons.png", 11, 2, 21, 14)
_Project = Project()
_Picker = Picker()
_TileDB = TileDatabase()

_DIRS = {
	{x = 0, y = -1},
	{x = 1, y = -1},
	{x = 1, y = 0},
	{x = 1, y = 1},
	{x = 0, y = 1},
	{x = -1, y = 1},
	{x = -1, y = 0},
	{x = -1, y = -1}
}

---Inverts the provided direction, 1 becomes 5, 2 becomes 6, 7 becomes 3, and so on.
---@param dir integer The direction to invert.
---@return integer
function _InvertDir(dir)
	return (dir + 3) % 8 + 1
end

---Turns speed in km/h into speed to be displayed on the semaphore.
---@param speed number? Desired speed.
---@return Speed
function _SpeedToID(speed)
	if not speed or speed == math.huge then
		return Speed.VMAX
	end
	if speed >= 100 then
		return Speed["100"]
	elseif speed >= 60 then
		return Speed["60"]
	end
	-- TODO: What about less than 40 km/h?
	return Speed["40"]
end

---Turns the track flags into the track color to be displayed on the tile.
---@param electrified boolean? Whether the track is electrified.
---@param occupied boolean? Whether the track is occupied.
---@param reserved boolean? Whether the track is reserved.
---@param alarm boolean? Whether the track should flash red (for example when a switch is forced).
---@return TrackColor
function _GetTrackColor(electrified, occupied, reserved, alarm)
	if alarm or occupied then
		return TrackColor.OCCUPIED
	elseif reserved then
		return TrackColor.RESERVED
	elseif electrified then
		return TrackColor.ELECTRIFIED
	end
	return TrackColor.BASE
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
---@param semaphoreState SemaphoreState|string? State of the semaphore, or its image directly.
---@param scale number? Tile scale.
---@param opacity number? Tile opacity, from 0 to 1.
function _DrawTile(x, y, id, electrified, occupied, reserved, alarm, switchDimBits, semaphoreState, scale, opacity)
	local track = _TileDB:getTile(id)
	-- Background
	love.graphics.setColor(1, 1, 1, opacity)
	if track.background then
		_Tracks:drawTile(track.background, 1, x, y, scale)
	end
	if track.backgroundXY then
		_Tracks:drawTile(track.backgroundXY[1], track.backgroundXY[2], x, y, scale)
	end
	if track.tracks then
		for i = 1, 8 do
			if _Utils.getBit(track.tracks, i) then
				_Tracks:drawTile(i, 1, x, y, scale)
			end
		end
	end
	if track.buffer then
		_Tracks:drawTile(track.buffer, 3, x, y, scale)
	end
	-- Track
	local color = _GetTrackColor(electrified, occupied, reserved, alarm)
	love.graphics.setColor(color[1], color[2], color[3], opacity)
	if track.tracks then
		for i = 1, 8 do
			local dim = _Utils.getBit(switchDimBits, i)
			if _Utils.getBit(track.tracks, i) and not dim and (not alarm or _Time % 0.4 < 0.2) then
				_Tracks:drawTile(i, 2, x, y, scale)
			end
		end
	end
	if track.foreground then
		_Tracks:drawTile(track.foreground, 2, x, y, scale)
	end
	-- Derailer
	love.graphics.setColor(1, 1, 1, opacity)
	if track.derailer then
		_Tracks:drawTile(track.derailer, 7, x, y, scale)
	end
	-- Semaphore
	if track.semaphore then
		_Tracks:drawTile(track.semaphore, 4, x, y, scale)
		local image = semaphoreState and SemaphoreImage[type(semaphoreState) == "string" and semaphoreState or semaphoreState.image]
		if image then
			if image.color1 and (not image.blink1 or _Time % 1 < 0.5) then
				love.graphics.setColor(image.color1[1], image.color1[2], image.color1[3], opacity)
				_Tracks:drawTile(track.semaphore, 5, x, y, scale)
			end
			if image.color2 and (not image.blink2 or _Time % 1 < 0.5) then
				love.graphics.setColor(image.color2[1], image.color2[2], image.color2[3], opacity)
				_Tracks:drawTile(track.semaphore, 6, x, y, scale)
			end
		end
	end
end

function love.load()
	_Settings:load()
	_UI:setup()
	_Com.init(_Settings.simPath, true)
	if _Settings.project then
		_Project:load(_Settings.project)
	end
	if _Settings.station then
		_Project:setCurrentStation(_Settings.station)
	end
end

function love.update(dt)
	_MouseX, _MouseY = love.mouse.getPosition()
	_Time = _Time + dt

	_Picker:update(dt)
	_Project:update(dt)
	_UI:update(dt)
	_Com.update(dt)
end

function love.draw()
	_Picker:draw()
	_Project:draw()
	_UI:draw()
	_Notifications:draw()
	-- Debug
	local station = _Project:getCurrentStation()
	if station then
		local tile = station:getHoveredTile()
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Hovered ID: " .. tostring(_Picker.hover), 0, 740)
		love.graphics.print("UI Focus: " .. tostring(_UI:getFocus()), 0, 760)
		if tile then
			love.graphics.print(string.format("Hovered Tile: %s, %s (%s)", tile.x, tile.y, tile.id), 0, 780)
			love.graphics.print("Current Tile Speed: " .. tostring(tile:getSpeed()), 0, 800)
			love.graphics.print("Semaphore pointing: " .. tostring(tile:getSemaphoreDirection()), 0, 820)
		end
	end
end

function love.keypressed(key)
	_Picker:keypressed(key)
	_Project:keypressed(key)
	_UI:keypressed(key)
end

function love.textinput(t)
	_UI:textinput(t)
end

function love.mousepressed(x, y, button)
	_Picker:mousepressed(x, y, button)
	_Project:mousepressed(x, y, button)
	_UI:mousepressed(x, y, button)
end

function love.mousereleased(x, y, button)
	_Project:mousereleased(x, y, button)
	_UI:mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
	_Picker:wheelmoved(x, y)
	_UI:wheelmoved(x, y)
end

function love.quit()
	_Settings.project = _Project.name
	_Settings.station = _Project.currentStationID
	_Settings:save()
end

-- Legacy code
local verboseValue = 3
local severityTable = {"INFO", "ERROR", "SUCCESS", "FAIL"}

function _LogWrite(text, severity, weight)
	if verboseValue >= weight then
		print("[" .. severityTable[severity] .. "] " .. text)
	end
end

function _GetMaxLessThan(l, v)
	table.sort(l)
	for i, n in ipairs(l) do if n > v then return l[i-1] end end
	return l[#l]
end

function _GetTableKeys(l)
	local r = {}
	for k, v in pairs(l) do table.insert(r, k) end
	return r
end