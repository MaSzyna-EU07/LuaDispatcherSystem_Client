local class = require "class"
local Tileset = class:derive("Tileset")

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

function Tileset:drawTile(tileX, tileY, x, y, scale)
	love.graphics.draw(self.img, self.tiles[tileX][tileY], x, y, 0, scale or 1)
end

return Tileset
