require("main_enums")
_Utils = require("utils")
_V = require("vectorutils")
_Com = require("communication")
local Settings = require("Settings")
local Objects = require("Objects")
local Commands = require("Commands")
local UI = require("UI")
local Tooltip = require("Tooltip")
local Notifications = require("Notifications")
local Tileset = require("Tileset")
local ProjectManager = require("ProjectManager")
local Project = require("Project")
local Picker = require("Picker")
local TileDatabase = require("TileDatabase")

_WWIDTH, _WHEIGHT = 1600, 900
_MouseX, _MouseY = 0, 0
_Time = 0
_Font = love.graphics.newFont("data/dejavusans.ttf", 12)

_Settings = Settings()
_Obj = Objects()
_Commands = Commands()
_UI = UI()
_Tooltip = Tooltip()
_Notifications = Notifications()
_Tracks = Tileset("data/tracks.png", 17, 10, 14, 14)
_Buttons = Tileset("data/buttons.png", 14, 2, 42, 28)
_ProjectManager = ProjectManager()
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

---Returns the angle of the provided direction, where 0 is to the right, and moving clockwise.
---@param dir integer The direction to calculate the angle from.
---@return number
function _DirToAngle(dir)
	return (3 - dir) % 8 * math.pi / 4
end

---Returns the angles of the provided directions, similarly to `_DirToAngle()`.
---@param dirs integer[] The directions to calculate the angles from.
---@return number[]
function _DirsToAngles(dirs)
	local angles = {}
	for i, dir in ipairs(dirs) do
		table.insert(angles, _DirToAngle(dir))
	end
	return angles
end

---Returns the closest direction to the specified angle in radians.
---@param angle number The angle to be considered.
---@return integer
function _AngleToDir(angle)
	return (2 - math.floor((angle + math.pi / 8) % (math.pi * 2) * 4 / math.pi)) % 8 + 1
end

---Turns a list of directions into their bitsum.
---@param dirs integer[] The list of directions.
---@return integer
function _DirsToBitsum(dirs)
	local sum = 0
	for i, dir in ipairs(dirs) do
		sum = sum + 2 ^ (dir - 1)
	end
	return sum
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
	local data = _TileDB:getTile(id)
	-- Background
	love.graphics.setColor(1, 1, 1, opacity)
	if data.background then
		_Tracks:drawTile(data.background, 1, x, y, scale)
	end
	if data.backgroundXY then
		_Tracks:drawTile(data.backgroundXY[1], data.backgroundXY[2], x, y, scale)
	end
	if data.tracks and not data.exit and not data.blockade then
		for i = 1, 8 do
			if _Utils.getBit(data.tracks, i) then
				_Tracks:drawTile(i, 1, x, y, scale)
			end
		end
	end
	if data.buffer then
		_Tracks:drawTile(data.buffer, 3, x, y, scale)
	end
	if data.blockade then
		_Tracks:drawTile(data.blockade, 9, x, y, scale)
	end
	-- Track
	local color = _GetTrackColor(electrified, occupied, reserved, alarm)
	love.graphics.setColor(color[1], color[2], color[3], opacity)
	if data.tracks and not data.exit and not data.blockade then
		for i = 1, 8 do
			local dim = _Utils.getBit(switchDimBits, i)
			if _Utils.getBit(data.tracks, i) and not dim and (not alarm or _Time % 0.4 < 0.2) then
				_Tracks:drawTile(i, 2, x, y, scale)
			end
		end
	end
	if data.foreground then
		_Tracks:drawTile(data.foreground, 2, x, y, scale)
	end
	if data.blockade then
		_Tracks:drawTile(data.blockade, 10, x, y, scale)
	end
	-- Derailer
	love.graphics.setColor(1, 1, 1, opacity)
	if data.derailer then
		_Tracks:drawTile(data.derailer, 7, x, y, scale)
	end
	if data.derailerL then
		_Tracks:drawTile(data.derailerL, 8, x, y, scale)
	end
	-- Semaphore
	if data.semaphore then
		_Tracks:drawTile(data.semaphore, 4, x, y, scale)
		local image = semaphoreState and SemaphoreImage[type(semaphoreState) == "string" and semaphoreState or semaphoreState.image]
		if image then
			if image.color1 and (not image.blink1 or _Time % 1 < 0.5) then
				love.graphics.setColor(image.color1[1], image.color1[2], image.color1[3], opacity)
				_Tracks:drawTile(data.semaphore, 5, x, y, scale)
			end
			if image.color2 and (not image.blink2 or _Time % 1 < 0.5) then
				love.graphics.setColor(image.color2[1], image.color2[2], image.color2[3], opacity)
				_Tracks:drawTile(data.semaphore, 6, x, y, scale)
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
	_Tooltip:reset()

	_Picker:update(dt)
	_Project:update(dt)
	_UI:update(dt)
	_Com.update(dt)
end

function love.draw()
	_Picker:draw()
	_Project:draw()
	_UI:draw()
	_Tooltip:draw()
	_Notifications:draw()
	-- Debug
	local station = _Project:getCurrentStation()
	if station then
		local tile = station:getHoveredTile()
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("UI Focus: " .. tostring(_UI:getFocus()), 820, 740)
		if tile then
			love.graphics.print(string.format("Hovered Tile: %s, %s (%s)", tile.x, tile.y, tile.id), 820, 760)
			love.graphics.print("Current Tile Speed: " .. tostring(tile:getSpeed()), 820, 780)
			love.graphics.print("Semaphore pointing: " .. tostring(tile:getSemaphoreDirection()), 820, 800)
		end
	end
end

function love.keypressed(key)
	_Picker:keypressed(key)
	_Project:keypressed(key)
	_UI:keypressed(key)

	-- Spawn a trainset contained in the clipboard when Ctrl+V is pressed.
	-- TODO: Contextualize this cute workflow somehow so that it remains cute while not running unnecessarily.
	if _Utils.isCtrlPressed() and key == "v" then
		_Com.sendCommand("st " .. _Utils.strJoin(_Utils.strSplit(love.system.getClipboardText(), "\n"), " "))
		_Notifications:post("Wyslano trainset", NotificationColor.GREEN)
	end
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
	_Project:wheelmoved(x, y)
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