_Utils = require("utils")
_Com = require("communication")
_Obj = require("objects")
local UI = require("UI")
local Tileset = require("Tileset")
local Project = require("Project")
local Picker = require("Picker")
local TileDatabase = require("TileDatabase")

_WWIDTH, _WHEIGHT = 1600, 900
_MouseX, _MouseY = 0, 0
_Time = 0
_SIM_PATH = "/run/media/jakub/LaCie/(Pliki)/Gry i programy/Symulatory/MaSzyna/SVN working/"

-- tory nie powinny sie niektore podswietlac jezeli rozjazd nie jest ustawiony w ta strone
-- definiowanie maksymalnych predkosci na rozjazdach

_UI = UI()
_Tracks = Tileset("data/tracks.png", 15, 7, 14, 14)
_Buttons = Tileset("data/buttons.png", 5, 2, 21, 14)
_Project = Project()
_Picker = Picker()
_TileDB = TileDatabase()

local TRACK_COLORS = {
	base = {0, 1, 0},
	electrified = {1, 1, 0},
	occupied = {1, 0, 0},
	reserved = {0, 0, 1}
}

function _GetTrackColor(electrified, occupied, reserved)
	if occupied then
		return TRACK_COLORS.occupied
	elseif reserved then
		return TRACK_COLORS.reserved
	elseif electrified then
		return TRACK_COLORS.electrified
	end
	return TRACK_COLORS.base
end

local SEM_COLORS = {
	{1, 0, 0},  -- 1: red
	{0, 1, 0},  -- 2: green
	{1, 0.5, 0},-- 3: orange
	{1, 1, 1},  -- 4: white
	{0.2, 0.4, 1}   -- 5: blue
}
local SEM_IMAGES = {
	s1 = {color1 = 1}, s1a = {color1 = 1, color2 = 1, blink2 = true},
	s2 = {color1 = 2}, s3 = {color1 = 2, blink1 = true}, s4 = {color1 = 3, blink1 = true}, s5 = {color1 = 3},
	s6 = {color1 = 2, color2 = 3, bar = 2}, s7 = {color1 = 2, blink1 = true, color2 = 3, bar = 2}, s8 = {color1 = 3, blink1 = true, color2 = 3, bar = 2}, s9 = {color1 = 3, color2 = 3, bar = 2},
	s10 = {color1 = 2, color2 = 3}, s11 = {color1 = 2, blink1 = true, color2 = 3}, s12 = {color1 = 3, blink1 = true, color2 = 3}, s13 = {color1 = 3, color2 = 3},
	s10a = {color1 = 2, color2 = 3, bar = 3}, s11a = {color1 = 2, blink1 = true, color2 = 3, bar = 3}, s12a = {color1 = 3, blink1 = true, color2 = 3, bar = 3}, s13a = {color1 = 3, color2 = 3, bar = 3},
	ms1 = {color1 = 5}, ms2 = {color2 = 4},
	sz = {color1 = 1, color2 = 4, blink2 = true}
}

function _DrawTile(x, y, id, electrified, occupied, reserved, switchDimBits, semaphoreState, scale, opacity)
	local track = _TileDB.tiles[id]
	if not track then
		return
	end
	-- Background
	love.graphics.setColor(1, 1, 1, opacity)
	if track.background then
		_Tracks:drawTile(track.background, 1, x, y, scale)
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
	local color = _GetTrackColor(electrified, occupied, reserved)
	love.graphics.setColor(color[1], color[2], color[3], opacity)
	if track.tracks then
		for i = 1, 8 do
			local dim = _Utils.getBit(switchDimBits, i)
			if _Utils.getBit(track.tracks, i) and not dim then
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
		local image = semaphoreState and SEM_IMAGES[semaphoreState]
		if image then
			if image.color1 and (not image.blink1 or _Time % 1 < 0.5) then
				local color = SEM_COLORS[image.color1]
				love.graphics.setColor(color[1], color[2], color[3], opacity)
				_Tracks:drawTile(track.semaphore, 5, x, y, scale)
			end
			if image.color2 and (not image.blink2 or _Time % 1 < 0.5) then
				local color = SEM_COLORS[image.color2]
				love.graphics.setColor(color[1], color[2], color[3], opacity)
				_Tracks:drawTile(track.semaphore, 6, x, y, scale)
			end
		end
	end
end

function love.load()
	_UI:setup()
	_Com.init(_SIM_PATH, true)
	_Project:load()
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
	-- Debug
	local station = _Project:getCurrentStation()
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Hovered ID: " .. tostring(_Picker.hover), 0, 700)
	love.graphics.print("Hovered Tile: " .. tostring(station.hoverX) .. ", " .. tostring(station.hoverY), 0, 720)
	love.graphics.print("UI Focus: " .. tostring(_UI:getFocus()), 0, 740)
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
	_UI:mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
	_Picker:wheelmoved(x, y)
	_UI:wheelmoved(x, y)
end

-- Legacy code
local verboseValue = 3
local severityTable = {"INFO", "ERROR", "SUCCESS", "FAIL"}

function _LogWrite(text, severity, weight)
	if verboseValue >= weight then
		print("[" .. severityTable[severity] .. "] " .. text)
	end
end

function _Ternary(v, a, b)
	if v then return a else return b end
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