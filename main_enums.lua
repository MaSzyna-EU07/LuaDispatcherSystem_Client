---@enum Speed
Speed = {
    DIM = -1,
	STOP = 0,
	MS1 = 5,
	MS2 = 6,
	SZ = 7,
	S1A = 8
}

---@enum SemaphoreType
SemaphoreType = {
	SEM = 0,
	TM = 1
}

---@enum PathMode
PathMode = {
	TRAIN = 0,
	SHUNT = 1
}

---@enum BlockadeDirection
BlockadeDirection = {
	FORWARD = 0,
	BACKWARD = 1,
	OFF = 255
}

---@enum TrackColor
TrackColor = {
	BASE = {0, 1, 0},
	ELECTRIFIED = {1, 1, 0},
	OCCUPIED = {1, 0, 0},
	RESERVED = {0, 0, 1}
}

---@enum BlockadeColor
BlockadeColor = {
	NONE = {0, 0, 0},
	FORWARD = {1, 1, 0},
	BACKWARD = {1, 0, 0},
	OFF = {0.5, 0.5, 0.5}
}

---@enum SemaphoreColor
SemaphoreColor = {
	RED = {1, 0, 0},
	GREEN = {0, 1, 0},
	ORANGE = {1, 0.6, 0},
	WHITE = {1, 1, 1},
	BLUE = {0.2, 0.4, 1}
}

---@enum SemaphoreImage
SemaphoreImage = {
	uszk = {},
	s1 = {color1 = SemaphoreColor.RED},
	s1a = {color1 = SemaphoreColor.RED, color2 = SemaphoreColor.RED, blink2 = true},
	s2 = {color1 = SemaphoreColor.GREEN},
	s3 = {color1 = SemaphoreColor.GREEN, blink1 = true},
	s4 = {color1 = SemaphoreColor.ORANGE, blink1 = true},
	s5 = {color1 = SemaphoreColor.ORANGE},
	s6 = {color1 = SemaphoreColor.GREEN, color2 = SemaphoreColor.ORANGE, bar = SemaphoreColor.GREEN},
	s7 = {color1 = SemaphoreColor.GREEN, blink1 = true, color2 = SemaphoreColor.ORANGE, bar = SemaphoreColor.GREEN},
	s8 = {color1 = SemaphoreColor.ORANGE, blink1 = true, color2 = SemaphoreColor.ORANGE, bar = SemaphoreColor.GREEN},
	s9 = {color1 = SemaphoreColor.ORANGE, color2 = SemaphoreColor.ORANGE, bar = SemaphoreColor.GREEN},
	s10 = {color1 = SemaphoreColor.GREEN, color2 = SemaphoreColor.ORANGE},
	s11 = {color1 = SemaphoreColor.GREEN, blink1 = true, color2 = SemaphoreColor.ORANGE},
	s12 = {color1 = SemaphoreColor.ORANGE, blink1 = true, color2 = SemaphoreColor.ORANGE},
	s13 = {color1 = SemaphoreColor.ORANGE, color2 = SemaphoreColor.ORANGE},
	s10a = {color1 = SemaphoreColor.GREEN, color2 = SemaphoreColor.ORANGE, bar = SemaphoreColor.ORANGE},
	s11a = {color1 = SemaphoreColor.GREEN, blink1 = true, color2 = SemaphoreColor.ORANGE, bar = SemaphoreColor.ORANGE},
	s12a = {color1 = SemaphoreColor.ORANGE, blink1 = true, color2 = SemaphoreColor.ORANGE, bar = SemaphoreColor.ORANGE},
	s13a = {color1 = SemaphoreColor.ORANGE, color2 = SemaphoreColor.ORANGE, bar = SemaphoreColor.ORANGE},
	ms1 = {color1 = SemaphoreColor.BLUE},
	ms2 = {color2 = SemaphoreColor.WHITE},
	sz = {color1 = SemaphoreColor.RED, color2 = SemaphoreColor.WHITE, blink2 = true}
}

---@enum TileHighlightMode
TileHighlightMode = {
	OFF = 0,
	TRACK = 1,
	SWITCH = 2,
	SEMAPHORE = 3
}

---@alias TileColorEntry {border: [number, number, number, number?]?, fill: [number, number, number, number?]?}

---@type table<string, TileColorEntry>
---@enum TileBackgroundColor
TileBackgroundColor = {
	REGULAR = {border = {0.2, 0.2, 0.2}, fill = {0.4, 0.4, 0.4}},
	OK = {border = {0.1, 0.4, 0.1}, fill = {0.2, 0.8, 0.2}},
	WARNING = {border = {0.5, 0.5, 0.1}, fill = {1, 1, 0.2}},
	ERROR = {border = {0.5, 0.1, 0.1}, fill = {1, 0.2, 0.2}},
	MISSING = {border = {0.5, 0.1, 0.5}, fill = {1, 0.2, 1}}
}

---@type table<string, TileColorEntry>
---@enum TileFrameColor
TileFrameColor = {
	HOVER = {fill = {1, 1, 1, 0.4}},
	SELECTION = {border = {0, 1, 0}, fill = {0, 1, 0, 0.2}},
	ACTIVE = {border = {1, 0, 1}, fill = {1, 0, 1, 0.2}},
	ACTIVE_SHUNT = {border = {1, 1, 1}, fill = {1, 1, 1, 0.2}},
	CLICKABLE = {border = {1, 1, 0}, fill = {1, 1, 0, 0.2}},
	RECT_SELECTION = {border = {0, 1, 1}, fill = {0, 1, 1, 0.2}},
	RAILDRAG_AFFECTED = {border = {0, 1, 0}, fill = {0, 1, 0, 0.2}},
	RAILDRAG_CONFLICT = {border = {1, 0, 0}, fill = {1, 0, 0, 0.2}}
}

---@enum NotificationColor
NotificationColor = {
	GREEN = {0.15, 0.6, 0.05},
	RED = {0.9, 0.1, 0},
	GRAY = {0.4, 0.4, 0.4},
	ORANGE = {0.9, 0.5, 0}
}

---@enum NotificationColorID
NotificationColorID = {
	NotificationColor.GREEN,
	NotificationColor.RED,
	NotificationColor.GRAY,
	NotificationColor.ORANGE
}

---@enum PickerMode
PickerMode = {
	TILE = 0,
	ADD_ROW = 1,
	DEL_ROW = 2,
	ADD_COLUMN = 3,
	DEL_COLUMN = 4,
	PROPERTIES = 5,
	ELECTRIFY = 6,
	DEELECTRIFY = 7,
	RAILS = 8
}