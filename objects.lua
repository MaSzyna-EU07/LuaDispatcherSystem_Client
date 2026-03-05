local obj = {stations = {}, tracks = {}, switches = {}, semaphores = {}}

function obj.clear()
	obj = {stations = {}, tracks = {}, switches = {}, semaphores = {}}
end



function obj.initStation(stationN)
    -- Do we need this?
	obj.stations[stationN] = {}
end

function obj.initTrack(trackID)
	obj.tracks[trackID] = {[0] = {occupied = false, reserved = false}}
end

function obj.initSwitch(switchID)
	obj.switches[switchID] = {[0] = {state = false}}
end

function obj.initSemaphore(semaphoreID, type)
    local startingImage = type == 1 and "ms1" or "s1"
	obj.semaphores[semaphoreID] = {[0] = {image = startingImage}}
end



function obj.setTrackState(trackID, tick, occupied, reserved)
	obj.tracks[trackID][tick] = {occupied = occupied, reserved = reserved}
    print(string.format("[t=%s] %s : occupied=%s reserved=%s", tick, trackID, occupied, reserved))
end

function obj.setSwitchState(switchID, tick, state)
	obj.switches[switchID][tick] = {state = state}
    print(string.format("[t=%s] %s : state=%s", tick, switchID, state))
end

function obj.setSemaphoreState(semaphoreID, tick, image)
	obj.semaphores[semaphoreID][tick] = {image = image}
    print(string.format("[t=%s] %s : image=%s", tick, semaphoreID, image))
end



local function getObjectState(tableID, objectID, tick)
	local history = obj[tableID][objectID]
	return history and history[_GetMaxLessThan(_GetTableKeys(history), tick)]
end



function obj.getTrackState(trackID, tick)
    return getObjectState("tracks", trackID, tick)
end

function obj.getSwitchState(switchID, tick)
    return getObjectState("switches", switchID, tick)
end

function obj.getSemaphoreState(semaphoreID, tick)
    return getObjectState("semaphores", semaphoreID, tick)
end

return obj