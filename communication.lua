local com = {}

local COM_READ_DELAY = 1
local COM_VALIDATION_KEY = {0x70, 0xA0, 0xE0, 0x07}
local COM_FUNCTIONS = {
	[0x01] = {
		name = "debugPrint",
		params = {
			{name = "message", type = "string"}
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
	[0xF0] = {
		name = "initStation",
		params = {
			{name = "stationN", type = "string"}
		}
	},
	[0xF1] = {
		name = "initRoute",
		params = {
			{name = "routeN", type = "string"}
		}
	},
	[0xF2] = {
		name = "initTrack",
		params = {
			{name = "stationID", type = "int", bytes = 2},
			{name = "trackN", type = "string"}
		}
	},
	[0xF3] = {
		name = "initSwitch",
		params = {
			{name = "stationID", type = "int", bytes = 2},
			{name = "switchN", type = "string"}
		}
	},
	[0xF4] = {
		name = "initSemaphore",
		params = {
			{name = "stationID", type = "int", bytes = 2},
			{name = "semaphoreN", type = "string"},
			{name = "type", type = "int", bytes = 1}
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

local logError = 0
local timeTicks = 0

com.path = nil
com.fail = false
local com_pos = 0
local com_readTime = 0
local com_readData = {step = "validate", byteCounter = 0}

local com_version = {0, 0, 0, 0}
local com_ids = {stations = {}, tracks = {}, switches = {}, semaphores = {}}
local com_counters = {}

function com.init(path, findRecent)
	_Obj:clear()
	com_pos = 0
	com_ids = {stations = {}, tracks = {}, switches = {}, semaphores = {}}
	com_counters = {}
	com.fail = false
	if findRecent then
		com.path = com.findMostRecentLogFile(path)
		if com.path then
			_LogWrite("[COMMUNICATION] Log file: " .. com.path, 1, 1)
			_UI.bottomPane:setStatus("Połączono!", {0, 1, 0}, com.path)
		else
			com.fail = true
			_LogWrite("[COMMUNICATION] Log file: " .. path .. "log.txt does not contain log file information. Are you starting the simulator right now?", 2, 1)
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
	com_readTime = com_readTime + dt
	if com_readTime >= COM_READ_DELAY then
		com_readTime = 0
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
	file:seek("set", com_pos) -- Start from where the file ended previously
	for i = com_pos, length - 1 do
		if logError ~= 0 then
			print("logError found, breaking")
			break
		end
		com.readByte(io.read(1))
	end

	io.close(file)
	com_pos = length
end

function com.readByte(b)
	local bv = string.byte(b)

	if com_readData.step == "validate" then
		com_readData.byteCounter = com_readData.byteCounter + 1
		-- check if the byte is correct
		local expectedByte = COM_VALIDATION_KEY[com_readData.byteCounter]
		if bv ~= expectedByte then
			_LogWrite("[COMMUNICATION] Verification failed! (" .. bv .. " != " .. expectedByte .. ")", 2, 1)
			-- Start the file over next time.
			com_pos = 0
			com_readData.byteCounter = 0
			return
		end
		-- end validation once 4 bytes were read
		if com_readData.byteCounter == 4 then
			_LogWrite("[COMMUNICATION] Verification successful!", 1, 1)
			com_readData.step = "version"
			com_readData.byteCounter = 0
		end
	elseif com_readData.step == "version" then
		com_readData.byteCounter = com_readData.byteCounter + 1
		com_version[com_readData.byteCounter] = bv
		-- end once 4 bytes were read
		if com_readData.byteCounter == 4 then
			_LogWrite(string.format("[COMMUNICATION] Server version: %s.%s.%s/%s", com_version[1], com_version[2], com_version[3], com_version[4]), 1, 1)
			com_readData.step = "function"
		end
	elseif com_readData.step == "function" then
		local func = COM_FUNCTIONS[bv]
		if not func then
			_LogWrite("[COMMUNICATION] Unknown function code: " .. tostring(bv) .. ", skipping to the next byte. Beware, this may break the whole program!", 4, 1)
			return
		end

		if #func.params > 0 then -- don't read parameters if they don't exist
			com_readData.funcID = bv
			com_readData.step = "param"
			com_readData.params = {}
			com_readData.paramCounter = 1
			com_readData.byteCounter = 0
		else
			com.readCall(func.name, {}, func.silent)
		end
	elseif com_readData.step == "param" then
		local func = COM_FUNCTIONS[com_readData.funcID]
		local param = func.params[com_readData.paramCounter]
		local paramFinish = false

		if param.type == "int" then
			com_readData.byteCounter = com_readData.byteCounter + 1
			if not com_readData.params[com_readData.paramCounter] then
				com_readData.params[com_readData.paramCounter] = 0
			end
			com_readData.params[com_readData.paramCounter] = com_readData.params[com_readData.paramCounter] + (bv * (256 ^ (param.bytes - com_readData.byteCounter)))
			if com_readData.byteCounter == param.bytes then
				paramFinish = true -- if read all the bytes, finish
			end

		elseif param.type == "string" then
			if not com_readData.params[com_readData.paramCounter] then
				com_readData.params[com_readData.paramCounter] = ""
			end
			if bv == 0 then
				paramFinish = true -- if noticed a string terminator, finish
			else
				com_readData.params[com_readData.paramCounter] = com_readData.params[com_readData.paramCounter] .. b
			end
		end

		if paramFinish then
			if com_readData.paramCounter == #func.params then -- check if this was the last parameter
				com_readData.step = "function"
				-- now pack all that together and execute in a separate function
				local params = {}
				for i, param in ipairs(func.params) do
					params[param.name] = com_readData.params[i]
				end
				com.readCall(func.name, params, func.silent)
			else
				com_readData.paramCounter = com_readData.paramCounter + 1
				com_readData.byteCounter = 0
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
		_LogWrite("[COMMUNICATION] Called function: " .. name .. "(" .. t .. ")", 1, 3)
	end

	if name == "nextTick" then
		com.nextTimeTick()
	elseif name == "debugPrint" then
		_Notifications:post("[LOG] " .. params.message, NotificationColor.GREEN)
	elseif name == "initStation" then
		com.initObject(com_ids.stations, "station", params.stationN, nil)
		_Obj:initStation(params.stationN)
	elseif name == "initRoute" then
		com.initObject(com_ids.stations, "station", params.routeN, nil)
		_Obj:initStation(params.routeN)
	elseif name == "initTrack" then
		local station = com_ids.stations[params.stationID]
		com.initObject(com_ids.tracks, "track", params.trackN, params.stationID)
		_Obj:initTrack(params.trackN)
	elseif name == "initSwitch" then
		local station = com_ids.stations[params.stationID]
		com.initObject(com_ids.switches, "switch", params.switchN, params.stationID)
		_Obj:initSwitch(params.switchN)
	elseif name == "initSemaphore" then
		local station = com_ids.stations[params.stationID]
		com.initObject(com_ids.semaphores, "semaphore", params.semaphoreN, params.stationID)
		_Obj:initSemaphore(params.semaphoreN, params.type)
	elseif name == "setTrack" then
		local track = com_ids.tracks[params.trackID]
		local station = com_ids.stations[track.sid]
		_Obj:setTrackState(track.name, timeTicks, _Utils.getBit(params.state, 1), _Utils.getBit(params.state, 2))
	elseif name == "setSwitch" then
		local switch = com_ids.switches[params.switchID]
		local station = com_ids.stations[switch.sid]
		_Obj:setSwitchState(switch.name, timeTicks, _Utils.getBit(params.state, 1), _Utils.getBit(params.state, 5))
	elseif name == "setSemaphore" then
		local semaphore = com_ids.semaphores[params.semaphoreID]
		local station = com_ids.stations[semaphore.sid]
		_Obj:setSemaphoreState(semaphore.name, timeTicks, params.speed, params.nextSpeed, COM_IMAGES[params.state])
	end
end

function com.nextTimeTick()
	timeTicks = timeTicks + 1
end

function com.initObject(idTable, counter, name, stationID)
	com_counters[counter] = (com_counters[counter] or 0) + 1
	idTable[com_counters[counter]] = {name = name, sid = stationID}
end

function com.isConnected()
	return com.path ~= nil
end

function com.sendCommand(command)
	if not com.isConnected() then
		--_Notifications:post("Command not sent - initialize connection first!", NotificationColor.RED)
		return
	end
	_LogWrite("[COMMUNICATION] Command: " .. command, 1, 3)
	local spl = _Utils.strSplit(com.path, "/")
	spl[#spl] = nil
	local commandFilePath = _Utils.strJoin(spl, "/") .. "/command.txt"
	_Utils.saveFile(commandFilePath, command .. "\n", true)
end

return com