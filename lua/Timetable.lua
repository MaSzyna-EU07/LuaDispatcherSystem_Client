local Class = require("lua.core.class")

---@class Timetable : Class
---@overload fun(id: string, data: table, startTime: string): Timetable
local Timetable = Class:derive("Timetable")

---@class TimetableEntry
---@field name string Station name.
---@field track string? Track this train should stop on or go through. The train is not guaranteed to go exactly there, though.
---@field arrival Time? The arrival time. May be absent if the train is not stopping there.
---@field arrivalAct Time? The actual arrival time. Counted when the train enters the station track.
---@field departure Time? The departure time. May be absent if this is the final stop.
---@field departureAct Time? The actual departure time. Counted when the train leaves the station track.
---@field speed integer? Specifies a new maximum speed. Due to how MaSzyna works, this applies BEFORE the station, not after it.
---@field km number? Kilometer this station is on.
---@field tracks 1|2? If specified, specifies the new amount of tracks on the route past this station.
-- TODO: Add a line number
-- TODO: Add radio channel number
-- TODO: Add blockade type
-- TODO: Add station type
-- TODO: Add station description

---Creates a new Timetable.
---@param id string Timetable ID (train number).
---@param data table Timetable data.
---@param startTime string The starting timetable time, e.g. `"10:30"`. Fractions are allowed, like `"10:30.5"`.
function Timetable:new(id, data, startTime)
    _Log.write(string.format("Creating timetable for train `%s`, starting at %s...", id, startTime))
    self.id = id

    -- TODO: Add loco type, loco haul and required brake force to the timetable data
    ---@type string?
    self.category = data.category
    ---@type string?
    self.name = data.name
    ---@type string?
    self.line = data.line

    ---@type TimetableEntry[]
    self.stations = {}
    self.currentStation = 1 -- Index of the current station, or the next station.

    -- Generate actual data.
    local time = _Time.timeToObj(startTime)
    for i, stationData in ipairs(data.stations) do
        ---@type TimetableEntry
        local station = {
            name = stationData.name,
            track = stationData.track,
            speed = stationData.speed,
            km = stationData.km,
            tracks = stationData.tracks
        }

        -- Calculate arrival and departure times
        time = time + (stationData.travelTime or 0) * 60
        -- Arrival time is present if the train is stopping on the station, and also on the first and last stop
        station.arrival = (stationData.stopTime or i == 1 or i == #data.stations) and time or nil
        time = time + (stationData.stopTime or 0) * 60
        -- Departure time is present if this is not the final stop
        station.departure = i < #data.stations and time or nil

        self.stations[i] = station
    end

    _Log.write("- Stations:")
    self:examine()

    _Log.write(string.format("Created timetable `%s`!", id))
end

---Returns the name of the first station in this timetable.
---@return string
function Timetable:getFirstStationName()
    return self.stations[1].name
end

---Returns the name of the final station in this timetable.
---@return string
function Timetable:getFinalStationName()
    return self.stations[#self.stations].name
end

---Prints the current state of this timetable to the simulation log file.
function Timetable:examine()
    _Log.write("========================================================================================================")
    _Log.write("        > Timetable for train: " .. self.id)
    _Log.write("                         | Arrival             | Departure           |       |       |       |       ")
    _Log.write("     Station             | Plan  | Act   | +/- | Plan  | Act   | +/- | Track | Speed | Km    | Tracks")
    _Log.write("-------------------------|-------|-------|-----|-------|-------|-----|-------|-------|-------|-------")
    for i, station in ipairs(self.stations) do
        local strCurrent = self.currentStation == i and ">>>" or "   "
        local strStation = _Utils.strPad(station.name, 20)
        local strArr = _Utils.strPad(station.arrival and _Time.timeToStrRJ(station.arrival) or "  |  ", 7)
        local strArrAct = _Utils.strPad(station.arrivalAct and _Time.timeToStrRJ(station.arrivalAct) or "", 7)
        local arrDelay = station.arrival and station.arrivalAct and (station.arrivalAct - station.arrival):getInt()
        local strArrDelay = _Utils.strPad(arrDelay and (arrDelay >= 60 and "+" .. math.floor(arrDelay / 60) or tostring(math.floor(arrDelay / 60))) or "", 5)
        local strDep = _Utils.strPad(station.departure and _Time.timeToStrRJ(station.departure) or "", 7)
        local strDepAct = _Utils.strPad(station.departureAct and _Time.timeToStrRJ(station.departureAct) or "", 7)
        local depDelay = station.departure and station.departureAct and (station.departureAct - station.departure):getInt()
        local strDepDelay = _Utils.strPad(depDelay and (depDelay >= 60 and "+" .. math.floor(depDelay / 60) or tostring(math.floor(depDelay / 60))) or "", 5)
        local strTrack = _Utils.strPad(station.track or "", 5)
        local strSpeed = _Utils.strPad(station.speed and tostring(station.speed) or "", 5)
        local strKm = _Utils.strPad(station.km and tostring(station.km) or "", 7)
        local strTracks = _Utils.strPad(station.tracks and tostring(station.tracks) or "", 5)
        _Log.write(string.format("%s %s |%s|%s|%s|%s|%s|%s| %s | %s |%s| %s", strCurrent, strStation, strArr, strArrAct, strArrDelay, strDep, strDepAct, strDepDelay, strTrack, strSpeed, strKm, strTracks))
    end
    _Log.write("========================================================================================================")
end

---Sends an information about this timetable to the log.
---@param text string The message to be written.
---@param severity LogSeverity? The message severity.
---@param weight integer? The message weight.
function Timetable:say(text, severity, weight)
	_Log.write(string.format("%s: %s", self.id, text), severity, weight)
end

return Timetable