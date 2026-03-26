local Class = require("class")

---@class UIProjectList : Class
---@overload fun(ui): UIProjectList
local UIProjectList = Class:derive("UIProjectList")

---Constructs the UI project list.
---@param ui UI UI which owns this window.
function UIProjectList:new(ui)
    self.ui = ui

    self.window = self.ui:createCenteredWindow("pl", "Lista projektów", 12, 20)
	self.ui:addLabel("pl", nil, "Projekty", 0, 1, 12, 1)
	self.projects = self.ui:addComboBox("pl", "projects", 0, 2, 12, 17)
	self.ui:addButton("pl", "bGo", "Wczytaj", 0, 19, 12, 1, self, self.loadProject)
end

---Shows this window.
function UIProjectList:show()
	self.window:show()
	self.window:setlevel()
	self.projects.scrollh:hide()
	self:updateList()
end

---Hides this window.
function UIProjectList:hide()
    self.window:hide()
end

---Updates the list contents.
function UIProjectList:updateList()
	self.ui:removeElementChildren("pl/projects")
	for i, project in ipairs(_ProjectManager:getProjectList()) do
		self.ui:addEntry("pl/projects", project, project, 0, i - 1, 11, 1, self, self.onEntrySelected, self.loadProject)
	end
	-- Automatically select the current station.
	self:select(_Project.name)
end

function UIProjectList:onEntrySelected(entry)
	self:select(entry.value)
end

function UIProjectList:select(name)
	self.projects.value = name
end

function UIProjectList:loadProject()
    _Project:load(self.projects.value)
    self:hide()
end

return UIProjectList