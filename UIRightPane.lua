local Class = require("class")

---@class UIRightPane : Class
---@overload fun(ui): UIRightPane
local UIRightPane = Class:derive("UIRightPane")

---Constructs the UI right pane.
---@param ui UI UI which owns this pane.
function UIRightPane:new(ui)
    self.ui = ui
    local gui = ui:getGUI()

	self.ui:addPane(nil, "right", "Informacje o stacji", _WWIDTH / self.ui.U - 14, 0, 14, _WHEIGHT / self.ui.U)
	--group.tip = "You hovered at me!"

	-- Station name and list button
	self.ui:addLabel("right", "right_header", "", 0, 1, 11, 1)
	self.ui:addButton("right", "right_bStationList", "Lista", 11, 1, 3, 1, self.ui, self.ui.showStationList)

	-- List all stuff
    local h = self.ui.elements.right:getmaxh()
	local rightPaneContents = gui:scrollgroup(nil, {y = h, w = 350 - self.ui.U, h = _WHEIGHT - h}, self.ui.elements.right)
	rightPaneContents.scrollh:hide()
	rightPaneContents:addchild(gui:text("Semafory:", {x = 8}, nil, true), "vertical")
	local semTest = {"A", "B", "C", "E3", "E1", "E2", "E4", "F", "X", "Y", "Z", "A", "B", "C", "E3", "E1", "E2", "E4", "F", "X", "Y", "Z", "A", "B", "C", "E3", "E1", "E2", "E4", "F", "X", "Y", "Z"}
	for i = 1, #semTest do
		local semGroup = gui:group(nil, {x = 16}, rightPaneContents)
		gui:text(semTest[i], {x = 0}, semGroup, true)
		gui:text("S1", {x = 150}, semGroup, true)
		rightPaneContents:addchild(semGroup, "vertical")
	end

	rightPaneContents:addchild(gui:text("Stacja: Test1 [Te]", {x = 8}, nil, true), "vertical")
	rightPaneContents:addchild(gui:text("Stacja: Test1 [Te]", {x = 8}, nil, true), "vertical")
	rightPaneContents:addchild(gui:text("Stacja: Test1 [Te]", {x = 8}, nil, true), "vertical")

	self:update()
end

function UIRightPane:update()
	self.ui.elements.right_header.label = string.format("Stacja: %s", _Project:getCurrentStation():getFullName())
end

return UIRightPane