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

---@enum TrackColor
TrackColor = {
	BASE = {0, 1, 0},
	ELECTRIFIED = {1, 1, 0},
	OCCUPIED = {1, 0, 0},
	RESERVED = {0, 0, 1}
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

---@alias TileBackgroundColorEntry {fill: [number, number, number], border: [number, number, number]}
---@type table<string, TileBackgroundColorEntry>
---@enum TileBackgroundColor
TileBackgroundColor = {
	REGULAR = {fill = {0.4, 0.4, 0.4}, border = {0.2, 0.2, 0.2}},
	OK = {fill = {0.2, 0.8, 0.2}, border = {0.1, 0.4, 0.1}},
	WARNING = {fill = {1, 1, 0.2}, border = {0.5, 0.5, 0.1}},
	ERROR = {fill = {1, 0.2, 0.2}, border = {0.5, 0.1, 0.1}}
}

---@enum TileFrameColor
TileFrameColor = {
	HOVER = {1, 1, 1},
	SELECTION = {0, 1, 0},
	ACTIVE = {1, 0, 1},
	ACTIVE_SHUNT = {1, 1, 1},
	CLICKABLE = {1, 1, 0},
	RECT_SELECTION = {0, 1, 1},
	RAILDRAG_AFFECTED = {0, 1, 0},
	RAILDRAG_CONFLICT = {1, 0, 0}
}

---@enum NotificationColor
NotificationColor = {
	GREEN = {0.15, 0.6, 0.05},
	RED = {0.9, 0.1, 0},
	GRAY = {0.4, 0.4, 0.4}
}

---@enum NotificationColorID
NotificationColorID = {
	NotificationColor.GREEN,
	NotificationColor.RED,
	NotificationColor.GRAY
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