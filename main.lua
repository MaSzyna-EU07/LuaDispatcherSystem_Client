require("main_enums")
_Utils = require("utils")
_Time = require("utils.TimeUtils")
_Dir = require("utils.DirUtils")
_Draw = require("utils.DrawUtils")
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
_T = 0
_Font = love.graphics.newFont("data/dejavusans.ttf", 12)
_Debug = false

_Settings = Settings()
_Obj = Objects()
_Commands = Commands()
_UI = UI()
_Tooltip = Tooltip()
_Notifications = Notifications()
_Buttons = Tileset("data/buttons.png", 14, 2, 42, 28)
_ProjectManager = ProjectManager()
_Project = Project()
_Picker = Picker()
_TileDB = TileDatabase()

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
	_T = _T + dt
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
	if _Debug then
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
end

function love.keypressed(key)
	_Picker:keypressed(key)
	_Project:keypressed(key)
	_UI:keypressed(key)

	if key == "f12" then
		_Debug = not _Debug
	end
	-- Spawn a trainset contained in the clipboard when Ctrl+V is pressed.
	-- TODO: Contextualize this cute workflow somehow so that it remains cute while not running unnecessarily.
	if _Utils.isCtrlPressed() and key == "v" then
		_Com.sendCommand("st " .. _Utils.strJoin(_Utils.strSplit(love.system.getClipboardText(), "\n"), " "))
		_Notifications:post("Wyslano trainset", NotificationColor.GREEN)
	end
end

function love.keyreleased(key)
	_Project:keyreleased(key)
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