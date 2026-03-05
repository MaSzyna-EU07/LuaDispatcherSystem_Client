local Class = require("class")

---@class Picker : Class
---@overload fun(): Picker
local Picker = Class:derive("Picker")

function Picker:new()
    self.x, self.y = 20, 500
    self.margin = 10
	self.tiles = {0, 1, 3, 4, 8, 9, 17, 18, 25, 37, 41, 53, 57, 61, 69, 70, 71, 72, 73}
    self.tileScale = 2
    self.tileMargin = 2

    self.tileSize = self.tileScale * 14 + self.tileMargin * 2
    self.boxX, self.boxY = self.x - self.margin, self.y - self.margin
    self.boxW, self.boxH = #self.tiles * self.tileSize + self.margin * 2, self.tileSize + self.margin * 2
	self.tmpRot = {
		{1, 6, 2, 5},
		{3, 7},
		{9, 11, 14, 13, 12, 10, 15, 16},
		{17, 34, 22, 31, 20, 33, 23, 32},
		{18, 35, 24, 30, 19, 36, 21, 29},
		{25, 26, 27, 28},
		{37, 49, 38, 51, 40, 50, 39, 52},
		{41, 45, 42, 47, 44, 46, 43, 48},
		{53, 55, 54, 56},
		{57, 59, 58, 60},
		{61, 67, 63, 66, 62, 68, 64, 65}
	}
	self.tmpFlip = {
		[17] = 18, [18] = 17,
		[19] = 20, [20] = 19,
		[21] = 23, [23] = 21,
		[22] = 24, [24] = 22,
		[29] = 32, [32] = 29,
		[30] = 31, [31] = 30,
		[33] = 36, [36] = 33,
		[34] = 35, [35] = 34
	}

	self.buttons = {
		{x = 20, y = 655, tileX = 1, action = "addRow"},
		{x = 65, y = 655, tileX = 2, action = "delRow"},
		{x = 110, y = 655, tileX = 3, action = "addColumn"},
		{x = 155, y = 655, tileX = 4, action = "delColumn"},
		{x = 200, y = 655, tileX = 5, action = "properties"}
	}

    self.selection = 0
	self.selectionV = 0
    self.hover = nil
	self.hoverV = nil
    self.electrified = true
end

function Picker:getTilePos(i)
	return self.x + (i - 1) * self.tileSize, self.y
end

function Picker:update(dt)
	self.hover = nil
	self.hoverV = nil
	if _Utils.isPointInsideBox(_MouseX, _MouseY, self.boxX, self.boxY, self.boxW, self.boxH) and not _UI:isMouseInUI() then
		self.hover = 0
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
			self.hover = button.action
		end
	end
end

function Picker:tmpRotateSelection(notches)
	if type(self.selection) ~= "number" then
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
	if not self.selection then
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
			_DrawTile(x + self.tileMargin, y + self.tileMargin, self.tiles[i], _Picker.electrified, false, false, 0, "s1", self.tileScale)
		end
	end

	for i, button in ipairs(self.buttons) do
		local tileY = self.selection == button.action and 2 or 1
		_Buttons:drawTile(button.tileX, tileY, button.x, button.y, 2)
	end
end

function Picker:keypressed(key)
	if key == "a" then
		--self.selection = "addRow"
	elseif key == "s" then
		--self.selection = "addColumn"
	elseif key == "z" then
		--self.selection = "delRow"
	elseif key == "x" then
		--self.selection = "delColumn"
	end
end

function Picker:mousepressed(x, y, button)
	if button == 1 then
		if self.hover then
			self.selection = self.hover
			self.selectionV = self.hoverV
		end
	end
end

function Picker:wheelmoved(x, y)
	self:tmpRotateSelection(-y)
end

return Picker