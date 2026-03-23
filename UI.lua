local class = require "class"
local gui = require("Gspot")
local UIStationList = require("UIStationList")
local UITopPane = require "UITopPane"
local UIRightPane = require("UIRightPane")
local UIPickerPane = require("UIPickerPane")
local UITrainPane = require("UITrainPane")
local UIBottomPane = require("UIBottomPane")

---@class UI : Class
---@overload fun(): UI
local UI = class:derive("UI")

function UI:new()
	self.U = 24
	self.elements = {}
end

function UI:getCenteredWindowDimensions(w, h)
	return {(_WWIDTH - w) / 2, (_WHEIGHT - h) / 2, w, h}
end

function UI:tilesToPos(tx, ty, tw, th, margin)
	margin = margin or 0
	return {x = tx * self.U + margin, y = ty * self.U + margin, w = tw * self.U - margin * 2, h = th * self.U - margin * 2}
end

---Creates a new centered window.
---After all window widgets have been created, you should call `:hide()` on the window to hide all of its children.
---@param id string The ID of the window.
---@param title string The title of the window.
---@param tw number Window width in tiles.
---@param th number Window height in tiles.
function UI:createCenteredWindow(id, title, tw, th)
	local window = gui:group(title, self:getCenteredWindowDimensions(tw * self.U, th * self.U))
	window.drag = true
	local x = gui:button("X", {x = window.pos.w - self.U, y = 0, w = self.U, h = self.U}, window)
	x.click = function(this) this.parent:hide() end
	self.elements[id] = window
end

---Adds a pane to the element list.
---@param parent string? The parent element ID.
---@param id string? The ID of the element. If not specified, the element will be inaccessible.
---@param title string? Text to be written on the pane.
---@param tx number X coordinate of the top left corner of the element.
---@param ty number Y coordinate of the top left corner of the element.
---@param tw number Width of the element in tiles.
---@param th number Height of the element in tiles.
function UI:addPane(parent, id, title, tx, ty, tw, th)
	local pos = self:tilesToPos(tx, ty, tw, th)
	local pane = gui:group(title, pos, parent and self.elements[parent])
	pane.style.bg = {0.2, 0.2, 0.2}
	if id then
		self.elements[id] = pane
	end
end

---Adds a label to the element list.
---@param parent string? The parent element ID.
---@param id string? The ID of the element. If not specified, the element will be inaccessible.
---@param text string Text to be written on the label.
---@param tx number X coordinate of the top left corner of the element.
---@param ty number Y coordinate of the top left corner of the element.
---@param tw number Width of the element in tiles.
---@param th number Height of the element in tiles.
function UI:addLabel(parent, id, text, tx, ty, tw, th)
	local pos = self:tilesToPos(tx, ty, tw, th)
	local label = gui:text(text, pos, parent and self.elements[parent])
	if id then
		self.elements[id] = label
	end
end

---Adds a button to the element list.
---@param parent string? The parent element ID.
---@param id string? The ID of the element. If not specified, the element will be inaccessible.
---@param text string Text to be written on the button.
---@param tx number X coordinate of the top left corner of the element.
---@param ty number Y coordinate of the top left corner of the element.
---@param tw number Width of the element in tiles.
---@param th number Height of the element in tiles.
---@param executor any Class instance which will execute the subsequent functions.
---@param onClick function? If specified, this function will be executed when the button is clicked.
function UI:addButton(parent, id, text, tx, ty, tw, th, executor, onClick)
	local pos = self:tilesToPos(tx, ty, tw, th, 1)
	local button = gui:button(text, pos, parent and self.elements[parent])
	if id then
		self.elements[id] = button
	end
	if onClick then
		-- example:
		--self.elements.top_bLoad.click = function(this) self:loadProject() end
		button.click = function(this)
			onClick(executor, this)
		end
	end
end

---Adds a checkbox to the element list.
---@param parent string? The parent element ID.
---@param id string? The ID of the element. If not specified, the element will be inaccessible.
---@param text string Text to be written on the checkbox.
---@param tx number X coordinate of the top left corner of the element.
---@param ty number Y coordinate of the top left corner of the element.
---@param tw number Width of the element in tiles. This should be always 1.
---@param th number Height of the element in tiles. This should be always 1.
---@param executor any Class instance which will execute the subsequent functions.
---@param onClick function? If specified, this function will be executed when the checkbox is clicked.
function UI:addCheckbox(parent, id, text, tx, ty, tw, th, executor, onClick)
	local pos = self:tilesToPos(tx, ty, tw, th, 1)
	local checkbox = gui:checkbox(text, pos, parent and self.elements[parent])
	if id then
		self.elements[id] = checkbox
	end
	if onClick then
		checkbox.click = function(this)
			gui[this.elementtype].click(this)
			onClick(executor, this)
		end
	end
end

---Adds an input box to the element list.
---@param parent string? The parent element ID.
---@param id string? The ID of the element. If not specified, the element will be inaccessible.
---@param tx number X coordinate of the top left corner of the element.
---@param ty number Y coordinate of the top left corner of the element.
---@param tw number Width of the element in tiles.
---@param th number Height of the element in tiles.
---@param executor any Class instance which will execute the subsequent functions.
---@param onChange function? If specified, this function will be executed when the text has changed.
---@param onSubmit function? If specified, this function will be executed when Enter is pressed while typing in this text box.
function UI:addInput(parent, id, tx, ty, tw, th, executor, onChange, onSubmit)
	local pos = self:tilesToPos(tx, ty, tw, th, 1)
	local input = gui:input(nil, pos, parent and self.elements[parent])
	if id then
		self.elements[id] = input
	end
	if onChange then
		input.keypress = function(this, key)
			gui[this.elementtype].keypress(this, key)
			onChange(executor, this)
		end
		input.textinput = function(this, key)
			gui[this.elementtype].textinput(this, key)
			onChange(executor, this)
		end
	end
	if onSubmit then
		input.done = function(this)
			onSubmit(executor, this)
		end
	end
end

---Adds a combo box to the element list.
---@param parent string? The parent element ID.
---@param id string? The ID of the element. If not specified, the element will be inaccessible.
---@param tx number X coordinate of the top left corner of the element.
---@param ty number Y coordinate of the top left corner of the element.
---@param tw number Width of the element in tiles.
---@param th number Height of the element in tiles.
function UI:addComboBox(parent, id, tx, ty, tw, th)
	local pos = self:tilesToPos(tx, ty, tw - 1, th)
	local box = gui:scrollgroup(nil, pos, parent and self.elements[parent])
	box.style.bg = {0.2, 0.2, 0.2}
	if id then
		self.elements[id] = box
	end
end

---Returns the focused Gspot element, if any.
---@return table?
function UI:getFocus()
	return gui.focus
end

---Returns the whole GUI class. This is a temporary function as all GUI interactions should happen through this class.
---@deprecated
---@return table
function UI:getGUI()
	return gui
end

--######################################--
---------------- S E T U P ---------------
--######################################--

function UI:setup()
	gui.style.font = _Font
	gui.style.unit = self.U

	self.stationList = UIStationList(self)
	self.topPane = UITopPane(self)
	self.rightPane = UIRightPane(self)
	self.pickerPane = UIPickerPane(self)
	self.trainPane = UITrainPane(self)
	self.bottomPane = UIBottomPane(self)
end

--######################################--
---------------- L O G I C ---------------
--######################################--

function UI:showStationList()
	self.elements.sl:show()
	self.elements.sl:setlevel()
	self.elements.sl_stations.scrollh:hide()
	self.stationList:update()
end

function UI:isMouseInUI()
	return gui.mousein
end

--################################################--
---------------- U I   A C T I O N S ---------------
--################################################--

function UI:drawGrid()
	love.graphics.setColor(0, 1, 1)
	love.graphics.setLineWidth(1)
	for x = 0, _WWIDTH, self.U do
		love.graphics.line(x, 0, x, _WHEIGHT)
	end
	for y = 0, _WHEIGHT, self.U do
		love.graphics.line(0, y, _WWIDTH, y)
	end
end

--################################################################--
---------------- I N T E R N A L   C A L L B A C K S ---------------
--################################################################--

---Executed when in the Station a tile is selected.
---@param tile Tile The tile that has just been selected.
function UI:onTileSelected(tile)
	self.pickerPane:setValuesForTile(tile)
end

---Executed when all tiles in the Station are unselected.
function UI:onAllTilesUnselected()
	self.pickerPane:resetValues()
end

---Executed when a log file is loaded.
function UI:onComInit()
	self.elements.bottom_comStatus.value = "Załadowano log z pliku"
end

---Executed each time a log file is read by the communication module.
function UI:onComUpdated()
	self.elements.bottom_comStatus.value = "Komunikacja aktywnie z pliku: " .. _Com.path
end

--##############################################--
---------------- C A L L B A C K S ---------------
--##############################################--

function UI:update(dt)
	gui:update(dt)
end

function UI:draw()
	gui:draw()
	--self:drawGrid()
end

function UI:keypressed(key)
	gui:keypress(key)
end

function UI:textinput(t)
	if gui.focus then
		gui:textinput(t)
	end
end

function UI:mousepressed(x, y, button)
	gui:mousepress(x, y, button)
end

function UI:mousereleased(x, y, button)
	gui:mouserelease(x, y, button)
end

function UI:wheelmoved(x, y)
	gui:mousewheel(x, y)
end

return UI
