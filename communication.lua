local com = {}

local COM_READ_DELAY = 1

---@type [integer, integer, integer, integer]
local COM_VALIDATION_KEY = {0x70, 0xA0, 0xE0, 0x07}

---@alias ComFunctionParam {name: string, type: "string"|"int", bytes: integer?}
---@alias ComFunction {name: string, params: ComFunctionParam[], silent: boolean?}
---@type table<integer, ComFunction>
local COM_FUNCTIONS = {
	[0x01] = {
		name = "debugPrint",
		params = {
			{name = "message", type = "string"}
		}
	},
	[0x02] = {
		name = "debugNotify",
		params = {
			{name = "color", type = "int", bytes = 1},
			{name = "message", type = "string"}
		}
	},
	[0x03] = {
		name = "debugHighlightTile",
		params = {
			{name = "stationID", type = "int", bytes = 2},
			{name = "x", type = "int", bytes = 1},
			{name = "y", type = "int", bytes = 1},
			{name = "type", type = "int", bytes = 1}
		}
	},
	[0x12] = {
		name = "setTrack",
		params = {
			{name = "trackID", type = "int", bytes = 2},
			{name = "state", type = "int", bytes = 1}
		}
	},
	[0x13] = {
		name = "setSwitch",
		params = {
			{name = "switchID", type = "int", bytes = 2},
			{name = "state", type = "int", bytes = 1}
		}
	},
	[0x14] = {
		name = "setSemaphore",
		params = {
			{name = "semaphoreID", type = "int", bytes = 2},
			{name = "speed", type = "int", bytes = 1},
			{name = "nextSpeed", type = "int", bytes = 1},
			{name = "state", type = "int", bytes = 1}
		}
	},
	[0x15] = {
		name = "setBlockade",
		params = {
			{name = "blockadeID", type = "int", bytes = 2},
			{name = "direction", type = "int", bytes = 1}
		}
	},
	[0x21] = {
		name = "setTrackReservation",
		params = {
			{name = "trackID", type = "int", bytes = 2},
			{name = "semaphoreID", type = "int", bytes = 2}
		}
	},
	[0xF0] = {
		name = "initStation",
		params = {
			{name = "stationN", type = "string"}
		}
	},
	[0xF2] = {
		name = "initTrack",
		params = {
			{name = "trackN", type = "string"}
		}
	},
	[0xF3] = {
		name = "initSwitch",
		params = {
			{name = "switchN", type = "string"}
		}
	},
	[0xF4] = {
		name = "initSemaphore",
		params = {
			{name = "semaphoreN", type = "string"},
			{name = "type", type = "int", bytes = 1}
		}
	},
	[0xF5] = {
		name = "initBlockade",
		params = {
			{name = "blockadeN", type = "string"}
		}
	},
	[0xFF] = {
		name = "nextTick",
		params = {},
		silent = true
	}
}
local COM_IMAGES = {
	[0x00] = "uszk",
	[0x01] = "s1",
	[0x02] = "s2",
	[0x03] = "s3",
	[0x04] = "s4",
	[0x05] = "s5",
	[0x06] = "s6",
	[0x07] = "s7",
	[0x08] = "s8",
	[0x09] = "s9",
	[0x0A] = "s10",
	[0x0B] = "s11",
	[0x0C] = "s12",
	[0x0D] = "s13",
	[0x21] = "s1a",
	[0x2A] = "s10a",
	[0x2B] = "s11a",
	[0x2C] = "s12a",
	[0x2D] = "s13a",
	[0x41] = "s1", -- TODO: Shape signals should have their own sprites
	[0x42] = "s2",
	[0x43] = "s10",
	[0x80] = "ms1",
	[0x81] = "ms2",
	[0xFF] = "sz"
}

local COM_BLOCKADES = {
	[0x00] = false,
	[0x01] = true,
	[0xFF] = nil
}

---@type string?
com.path = nil -- Full path to the log file that is being read
com.fail = false -- `true` if in failure state
com.pos = 0 -- Total amount of read bytes
com.readTime = 0 -- Time since last read
com.timeTicks = 0 -- How many ticks have elapsed since the beginning of the log file

---Contains all byte parsing state.
---
---`step` is one of the following:
--- - `"validate"` - Checks the header (bytes 1-4)
--- - `"version"` - Fetches the version (bytes 5-8) and puts them into `com.version`
--- - `"function"` - Fetches the function byte (`COM_FUNCTIONS`)
--- - `"param"` - Fetches the function parameters based on the list of parameters
---@type {step: "validate"|"version"|"function"|"param", byteCounter: integer, funcID: integer?, params: integer[]|string[]?, paramCounter: integer?}
com.readData = {step = "validate", byteCounter = 0}

---@type [integer, integer, integer, integer]
com.version = {0, 0, 0, 0} -- Version data as read from the log file
---@alias ComIDToName table<integer, string>
---@type {stations: ComIDToName, tracks: ComIDToName, switches: ComIDToName, semaphores: ComIDToName, blockades: ComIDToName}
com.ids = {stations = {}, tracks = {}, switches = {}, semaphores = {}, blockades = {}} -- Maps IDs to object names
---@type {stations: integer, tracks: integer, switches: integer, semaphores: integer}
com.counters = {} -- How many objects of each type have been initialized

---Initializes the communication with the server.
---@param path string Path to the MaSzyna's main directory where the server runs. if `findRecent` is true. Must have a trailing slash if `findRecent` is `true`. If `findRecent` is `false`, specifies the path to the `.dsl` log file.
---@param findRecent boolean If `true`, `path` is the path to the main MaSzyna directory. From there, the DSL log file path is extracted from the `log.txt` file which should be the current simulator session.
function com.init(path, findRecent)
	_Obj:clear()
	com.pos = 0
	com.readData = {step = "validate", byteCounter = 0}
	com.ids = {stations = {}, tracks = {}, switches = {}, semaphores = {}, blockades = {}}
	com.counters = {}
	com.timeTicks = 0
	com.fail = false
	if findRecent then
		com.path = com.findMostRecentLogFile(path)
		if com.path then
			_LogWrite("[COMMUNICATION] Log file: " .. com.path, Severity.INFO, 1)
			_UI.bottomPane:setStatus("Połączono!", {0, 1, 0}, com.path)
		else
			com.fail = true
			_LogWrite("[COMMUNICATION] Log file: " .. path .. "log.txt does not contain log file information. Are you starting the simulator right now?", Severity.ERROR, 1)
			_UI.bottomPane:setStatus("Błąd! (Log)", {1, 0, 0})
			return
		end
	else
		com.path = path
	end
	com.readBytes()
	_UI:onComInit()
end

function com.update(dt)
	if com.fail then
		return
	end
	com.readTime = com.readTime + dt
	if com.readTime >= COM_READ_DELAY then
		com.readTime = 0
		com.readBytes()
		_UI:onComUpdated()
	end
end

function com.findMostRecentLogFile(path)
	local log = _Utils.loadFile(path .. "log.txt")
	assert(log, "File not found: " .. path .. "log.txt")
	local line = _Utils.strFindLine(log, "lua: log: LuaDispatcher -> [INFO] [COMMUNICATION] File Name:")
	if line then
		local s = _Utils.strSplit(line, " ")
		local filename = s[#s]
		-- The last character is a 0x0d, because log.txt contains Windows-esque \r\n line endings. But only sometimes.
		if string.sub(filename, #filename) == string.char(0x0d) then
			filename = filename:sub(1, #filename - 1)
		end
		return path .. filename
	end
end

function com.readBytes()
	assert(com.path, "Call `com.init()` first.")
	local file = io.open(com.path, "rb")
	if not file then
		print("Log file not found, trying again next time")
		return
	end
	io.input(file)
	local length = file:seek("end")
	file:seek("set", com.pos) -- Start from where the file ended previously
	for i = com.pos, length - 1 do
		com.readByte(io.read(1))
	end

	io.close(file)
	com.pos = length
end

function com.readByte(b)
	local bv = string.byte(b)

	if com.readData.step == "validate" then
		com.readData.byteCounter = com.readData.byteCounter + 1
		-- check if the byte is correct
		local expectedByte = COM_VALIDATION_KEY[com.readData.byteCounter]
		if bv ~= expectedByte then
			_LogWrite("[COMMUNICATION] Verification failed! (" .. bv .. " != " .. expectedByte .. ")", Severity.ERROR, 1)
			-- Start the file over next time.
			com.pos = 0
			com.readData.byteCounter = 0
			return
		end
		-- end validation once 4 bytes were read
		if com.readData.byteCounter == 4 then
			_LogWrite("[COMMUNICATION] Verification successful!", Severity.INFO, 1)
			com.readData.step = "version"
			com.readData.byteCounter = 0
		end
	elseif com.readData.step == "version" then
		com.readData.byteCounter = com.readData.byteCounter + 1
		com.version[com.readData.byteCounter] = bv
		-- end once 4 bytes were read
		if com.readData.byteCounter == 4 then
			_LogWrite(string.format("[COMMUNICATION] Server version: %s.%s.%s/%s", com.version[1], com.version[2], com.version[3], com.version[4]), Severity.INFO, 1)
			com.readData.step = "function"
		end
	elseif com.readData.step == "function" then
		local func = COM_FUNCTIONS[bv]
		if not func then
			_LogWrite("[COMMUNICATION] Unknown function code: " .. tostring(bv) .. ", skipping to the next byte. Beware, this may break the whole program!", Severity.FAIL, 1)
			return
		end

		if #func.params > 0 then -- don't read parameters if they don't exist
			com.readData.funcID = bv
			com.readData.step = "param"
			com.readData.params = {}
			com.readData.paramCounter = 1
			com.readData.byteCounter = 0
		else
			com.readCall(func.name, {}, func.silent)
		end
	elseif com.readData.step == "param" then
		local func = COM_FUNCTIONS[com.readData.funcID]
		local param = func.params[com.readData.paramCounter]
		local paramFinish = false

		if param.type == "int" then
			com.readData.byteCounter = com.readData.byteCounter + 1
			if not com.readData.params[com.readData.paramCounter] then
				com.readData.params[com.readData.paramCounter] = 0
			end
			com.readData.params[com.readData.paramCounter] = com.readData.params[com.readData.paramCounter] + (bv * (256 ^ (param.bytes - com.readData.byteCounter)))
			if com.readData.byteCounter == param.bytes then
				paramFinish = true -- if read all the bytes, finish
			end

		elseif param.type == "string" then
			if not com.readData.params[com.readData.paramCounter] then
				com.readData.params[com.readData.paramCounter] = ""
			end
			if bv == 0 then
				paramFinish = true -- if noticed a string terminator, finish
			else
				com.readData.params[com.readData.paramCounter] = com.readData.params[com.readData.paramCounter] .. b
			end
		end

		if paramFinish then
			if com.readData.paramCounter == #func.params then -- check if this was the last parameter
				com.readData.step = "function"
				-- now pack all that together and execute in a separate function
				local params = {}
				for i, param in ipairs(func.params) do
					params[param.name] = com.readData.params[i]
				end
				com.readCall(func.name, params, func.silent)
			else
				com.readData.paramCounter = com.readData.paramCounter + 1
				com.readData.byteCounter = 0
			end
		end
	end
end

function com.readCall(name, params, silent)
	local t = ""
	for paramN, param in pairs(params) do
		if t ~= "" then
			t = t .. ", "
		end
		t = t .. paramN .. "=" .. tostring(param)
	end
	if not silent then
		_LogWrite("[COMMUNICATION] Called function: " .. name .. "(" .. t .. ")", Severity.INFO, 3)
	end

	if name == "nextTick" then
		com.nextTimeTick()
	elseif name == "debugPrint" then
		print("[LOG] " .. params.message)
	elseif name == "debugNotify" then
		if com.pos > 0 then
			_Notifications:post(params.message, NotificationColorID[params.color])
		else
			-- Do not display the notification if this is the initial read, as we might read a lot
			-- and we don't want to flood the user each time with trash content. This is not TikTok.
			print("[NOTIFICATION] " .. params.message)
		end
	elseif name == "debugHighlightTile" then
		-- Do not display the highlight when this is the initial read.
		if com.pos > 0 then
			com.highlightTile(params.stationID, params.x, params.y, params.type)
		end
	elseif name == "initStation" then
		com.initObject(com.ids.stations, "station", params.stationN)
		_Obj:initStation(params.stationN)
	elseif name == "initTrack" then
		com.initObject(com.ids.tracks, "track", params.trackN)
		_Obj:initTrack(params.trackN)
	elseif name == "initSwitch" then
		com.initObject(com.ids.switches, "switch", params.switchN)
		_Obj:initSwitch(params.switchN)
	elseif name == "initSemaphore" then
		com.initObject(com.ids.semaphores, "semaphore", params.semaphoreN)
		_Obj:initSemaphore(params.semaphoreN, params.type)
	elseif name == "initBlockade" then
		com.initObject(com.ids.blockades, "blockade", params.blockadeN)
		_Obj:initBlockade(params.blockadeN)
	elseif name == "setTrack" then
		local trackID = com.ids.tracks[params.trackID]
		_Obj:setTrackState(trackID, com.timeTicks, _Utils.getBit(params.state, 1), _Utils.getBit(params.state, 2))
	elseif name == "setSwitch" then
		local switchID = com.ids.switches[params.switchID]
		_Obj:setSwitchState(switchID, com.timeTicks, _Utils.getBit(params.state, 1), _Utils.getBit(params.state, 5))
	elseif name == "setSemaphore" then
		local semaphoreID = com.ids.semaphores[params.semaphoreID]
		_Obj:setSemaphoreState(semaphoreID, com.timeTicks, params.speed, params.nextSpeed, COM_IMAGES[params.state])
	elseif name == "setBlockade" then
		local blockadeID = com.ids.blockades[params.blockadeID]
		_Obj:setBlockadeState(blockadeID, com.timeTicks, com.blockadeDirFromHex(params.direction))
	elseif name == "setTrackReservation" then
		local trackID = com.ids.tracks[params.trackID]
		_Obj:setTrackReservationState(trackID, com.timeTicks, params.semaphoreID and com.ids.semaphores[params.semaphoreID])
	end
end

function com.nextTimeTick()
	com.timeTicks = com.timeTicks + 1
end

function com.initObject(idTable, counter, name)
	com.counters[counter] = (com.counters[counter] or 0) + 1
	idTable[com.counters[counter]] = name
end

function com.blockadeDirFromHex(direction)
	return COM_BLOCKADES[direction]
end

function com.blockadeDirToHex(direction)
	return direction and 0x01 or (direction == false and 0x00 or 0xFF)
end

function com.highlightTile(stationID, x, y, type)
	local station = _Project:getStation(com.ids.stations[stationID])
	if station then
		station:highlightTile(x, y, type)
	end
end

function com.isConnected()
	return com.path ~= nil
end

function com.sendCommand(command)
	if not com.isConnected() then
		--_Notifications:post("Command not sent - initialize connection first!", NotificationColor.RED)
		return
	end
	_LogWrite("[COMMUNICATION] Command: " .. command, Severity.INFO, 3)
	local spl = _Utils.strSplit(com.path, "/")
	spl[#spl] = nil
	local commandFilePath = _Utils.strJoin(spl, "/") .. "/command.txt"
	_Utils.saveFile(commandFilePath, command .. "\n", true)
end

return com