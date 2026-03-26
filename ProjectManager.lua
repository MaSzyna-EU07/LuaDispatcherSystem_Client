local Class = require("class")

---@class ProjectManager : Class
---@overload fun(): ProjectManager
local ProjectManager = Class:derive("ProjectManager")

function ProjectManager:new()
    
end

---Returns the list of project names.
---@return string[]
function ProjectManager:getProjectList()
    local names = _Utils.getDirListing("projects", "file", ".json")
    for i, name in ipairs(names) do
        names[i] = name:sub(1, name:len() - 5)
    end
    return names
end

return ProjectManager