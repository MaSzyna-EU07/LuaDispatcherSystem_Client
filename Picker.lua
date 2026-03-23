local Class = require("class")

---@class Picker : Class
---@overload fun(): Picker
local Picker = Class:derive("Picker")

function Picker:new()
    self.x, self.y = 20, 500
    self.margin = 10
	self.tiles = {"", "track-", "track+", "platformP", "platformF", "curve3", "switchL3", "switchR3", "switchD2", "switchW6", "switchT6", "buffer7", "derailer3", "semaphore3", "arrow7", "arrow3", "arrow-", "loco", "square"}
    self.tileScale = 2
    self.tileMargin = 2

    self.tileSize = self.tileScale * 14 + self.tileMargin * 2
    self.boxX, self.boxY = self.x - self.margin, self.y - self.margin
    self.boxW, self.boxH = #self.tiles * self.tileSize + self.margin * 2, self.tileSize + self.margin * 2
	self.tmpRot = {
		{"track-", "track\\", "track|", "track/"},
		{"track+", "trackX"},
		{"curve1", "curve2", "curve3", "curve4", "curve5", "curve6", "curve7", "curve8"},
		{"switchL1", "switchL2", "switchL3", "switchL4", "switchL5", "switchL6", "switchL7", "switchL8"},
		{"switchR1", "switchR2", "switchR3", "switchR4", "switchR5", "switchR6", "switchR7", "switchR8"},
		{"switchD1", "switchD2", "switchD3", "switchD4"},
		{"switchW1", "switchW2", "switchW3", "switchW4", "switchW5", "switchW6", "switchW7", "switchW8"},
		{"switchT1", "switchT2", "switchT3", "switchT4", "switchT5", "switchT6", "switchT7", "switchT8"},
		{"buffer1", "buffer2", "buffer3", "buffer4", "buffer5", "buffer6", "buffer7", "buffer8"},
		{"derailer1", "derailer2", "derailer3", "derailer4", "derailer5", "derailer6", "derailer7", "derailer8"},
		{"semaphore1", "semaphore2", "semaphore3", "semaphore4", "semaphore5", "semaphore6", "semaphore7", "semaphore8"},
		{"arrow3", "arrow7", "arrow-"}
	}
	self.tmpFlip = {
		["switchL1"] = "switchR1", ["switchR1"] = "switchL1",
		["switchL2"] = "switchR2", ["switchR2"] = "switchL2",
		["switchL3"] = "switchR3", ["switchR3"] = "switchL3",
		["switchL4"] = "switchR4", ["switchR4"] = "switchL4",
		["switchL5"] = "switchR5", ["switchR5"] = "switchL5",
		["switchL6"] = "switchR6", ["switchR6"] = "switchL6",
		["switchL7"] = "switchR7", ["switchR7"] = "switchL7",
		["switchL8"] = "switchR8", ["switchR8"] = "switchL8",
		["arrow3"] = "arrow7", ["arrow7"] = "arrow3"
	}

	self.buttons = {
		{x = 20, y = 655, tileX = 1, action = "addRow"},
		{x = 65, y = 655, tileX = 2, action = "delRow"},
		{x = 110, y = 655, tileX = 3, action = "addColumn"},
		{x = 155, y = 655, tileX = 4, action = "delColumn"},
		{x = 200, y = 655, tileX = 5, action = "properties"},
		--{x = 245, y = 655, tileX = 8, action = "electrify"},
		--{x = 290, y = 655, tileX = 9, action = "deelectrify"}
	}

	self.mode = nil
	---@type string
    self.selection = ""
	self.selectionV = 0
	self.modeHover = nil
	---@type string?
    self.hover = nil
	self.hoverV = nil
    self.electrified = true
end

function Picker:getTilePos(i)
	return self.x + (i - 1) * self.tileSize, self.y
end

function Picker:update(dt)
	self.modeHover = nil
	self.hover = nil
	self.hoverV = nil
	if _Utils.isPointInsideBox(_MouseX, _MouseY, self.boxX, self.boxY, self.boxW, self.boxH) and not _UI:isMouseInUI() then
		self.hover = ""
		self.hoverV = 0
		for i = 1, #self.tiles do
			local x, y = self:getTilePos(i)
			if _Utils.isPointInsideBox(_MouseX, _MouseY, x, y, self.tileSize, self.tileSize) then
				self.hover = self.tiles[i]
				self.hoverV = i
				break
			end
		end
	end
	for i, button in ipairs(self.buttons) do
		if _Utils.isPointInsideBox(_MouseX, _MouseY, button.x, button.y, 40, 28) then
			self.modeHover = button.action
		end
	end
end

function Picker:tmpRotateSelection(notches)
	if self.mode then
		return
	end
	local groupMember = nil
	local groupMemberN = nil
	for i, group in ipairs(self.tmpRot) do
		for j, tileID in ipairs(group) do
			if self.selection == tileID then
				groupMember = group
				groupMemberN = j
				break
			end
		end
		if groupMember then
			break
		end
	end
	if not groupMember or not groupMemberN then
		return
	end
	local newMemberN = (groupMemberN + notches - 1) % #groupMember + 1
	self.selection = groupMember[newMemberN]
end

function Picker:flipSelection()
	if self.mode then
		return
	end
	self.selection = self.tmpFlip[self.selection] or self.selection
end

function Picker:draw()
	love.graphics.setColor(0, 0, 1)
	love.graphics.rectangle("fill", self.boxX, self.boxY, self.boxW, self.boxH)
	for i = 1, #self.tiles do
		local x, y = self:getTilePos(i)
		if self.selectionV == i then
			love.graphics.setColor(1, 1, 1)
			love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)
		elseif self.hoverV == i then
			love.graphics.setColor(0, 1, 1)
			love.graphics.rectangle("fill", x, y, self.tileSize, self.tileSize)
		end
		if self.tiles[i] == 0 then
			local tx, ty = x + self.tileMargin * self.tileScale, y + self.tileMargin * self.tileScale
			local size = self.tileSize - self.tileMargin * self.tileScale * 2
			love.graphics.setColor(0.4, 0.4, 0.4)
			love.graphics.rectangle("fill", tx, ty, size, size)
			love.graphics.setColor(0.2, 0.2, 0.2)
			love.graphics.setLineWidth(2)
			love.graphics.rectangle("line", tx, ty, size, size)
		else
			_DrawTile(x + self.tileMargin, y + self.tileMargin, self.tiles[i], _Picker.electrified, false, false, false, 0, "s1", self.tileScale)
		end
	end

	for i, button in ipairs(self.buttons) do
		local tileY = self.mode == button.action and 2 or 1
		_Buttons:drawTile(button.tileX, tileY, button.x, button.y, 2)
	end
end

-- The following function is kept here just in case I ever need to check all of the tile possibilities again.
--[[
function Picker:drawDebug()
	love.graphics.setColor(0.5, 0.5, 0.5)
	love.graphics.rectangle("fill", 0, 0, 500, 200)
	for i, data in ipairs(_TileDB.tiles) do
		local x, y = (i - 1) % 16, math.floor((i - 1) / 16)
		_DrawTile(x * 28, y * 28 + 28, i, true, false, false, false, 0, nil, 2)
	end
end
]]

function Picker:keypressed(key)
	if key == "a" then
		--self.mode = "addRow"
	elseif key == "s" then
		--self.mode = "addColumn"
	elseif key == "z" then
		--self.mode = "delRow"
	elseif key == "x" then
		--self.mode = "delColumn"
	end
end

function Picker:mousepressed(x, y, button)
	if button == 1 then
		if self.hover then
			self.mode = nil
			self.selection = self.hover
			self.selectionV = self.hoverV
		elseif self.modeHover then
			self.mode = self.modeHover
		end
	end
end

function Picker:wheelmoved(x, y)
	self:tmpRotateSelection(-y)
end

return Picker