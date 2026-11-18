local class = require "lua.core.class"

---@class Tileset : Class
---@overload fun(imgPath: string, w: integer, h: integer, tileW: integer, tileH: integer, antialiased: boolean?): Tileset
local Tileset = class:derive("Tileset")

---Creates a new Tileset.
---@param imgPath string Path to the tileset image file.
---@param w integer How many tiles horizontally are in the tileset.
---@param h integer How many tiles vertically are in the tileset.
---@param tileW integer Width of each tile in pixels.
---@param tileH integer Height of each tile in pixels.
---@param antialiased boolean? Whether this tileset should be antialiased.
function Tileset:new(imgPath, w, h, tileW, tileH, antialiased)
	self.img = love.graphics.newImage(imgPath)
	self.w, self.h = w, h
	self.tileW, self.tileH = tileW, tileH

	self.tiles = {}

	-- Populate the tileset with quads.
	for i = 1, self.w do
		self.tiles[i] = {}
		for j = 1, self.h do
			self.tiles[i][j] = love.graphics.newQuad(
				self.tileW * (i - 1),
				self.tileH * (j - 1),
				self.tileW,
				self.tileH,
				self.tileW * self.w,
				self.tileH * self.h
			)
		end
	end

	if not antialiased then
		self.img:setFilter("nearest")
	end
end

---Draws a tile from the tileset on the screen.
---@param tileX integer The tile index on the X axis.
---@param tileY integer The tile index on the Y axis.
---@param x number The X position on the screen.
---@param y number The Y position on the screen.
---@param scale number? Scale of the sprite, `1` by default.
function Tileset:drawTile(tileX, tileY, x, y, scale)
	love.graphics.draw(self.img, self.tiles[tileX][tileY], x, y, 0, scale or 1)
end

return Tileset
