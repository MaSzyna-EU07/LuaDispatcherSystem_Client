local Class = require("class")

---@class TileDatabase : Class
---@overload fun(): TileDatabase
local TileDatabase = Class:derive("TileDatabase")

function TileDatabase:new()
    -- Tracks:
    --[[
    128  1   2        8  1  2
       \ | /           \ | /
    64 - * -  4      7 - * - 3
       / | \           / | \
    32  16   8        6  5  4
    ]]

    -- Properties for each tile:
    -- tracks - Bitmask of tracks rendered on this tile (see above for values per direction)
    -- background - Sprite (n, 1) rendered as the tile background.
    -- foreground - Sprite (n, 2) rendered on top of the background. Colored based on track color.
    -- dirs - Table of direction -> state associations.
    --        Use "-" and "+" for states in single switches and "ab-", "ab+", "cd-" and "cd+" for states in double switches.
    -- buffer - Sprite (n, 3) rendered alongside tracks.
    -- derailer - Sprite (n, 7) rendered on top of the tracks.
    -- semaphore - Sprites (n, 4), (n, 5) and (n, 6) used as semaphore body, first and second lamps respectively.
    ---@alias TileData {tracks: integer?, background: integer?, foreground: integer?, dirs: table<integer, "-"|"+"|"ab-"|"ab+"|"cd-"|"cd+">?, buffer: integer?, derailer: integer?, semaphore: integer?, doubleSwitch: boolean?}
    ---@type table<string, TileData>
    self.tiles = {
        [""] = {},
        ["track-"] = {tracks = 68},
        ["track\\"] = {tracks = 136},
        ["track|"] = {tracks = 17},
        ["track/"] = {tracks = 34},
        ["track+"] = {tracks = 85},
        ["trackX"] = {tracks = 170},
        ["platformP"] = {tracks = 68, background = 9},
        ["platformF"] = {tracks = 68, background = 10},
        ["curve1"] = {tracks = 33},
        ["curve2"] = {tracks = 66},
        ["curve3"] = {tracks = 132},
        ["curve4"] = {tracks = 9},
        ["curve5"] = {tracks = 18},
        ["curve6"] = {tracks = 36},
        ["curve7"] = {tracks = 72},
        ["curve8"] = {tracks = 144},
        ["switchL1"] = {tracks = 25, dirs = {[5] = "-", [4] = "+"}},
        ["switchL2"] = {tracks = 50, dirs = {[6] = "-", [5] = "+"}},
        ["switchL3"] = {tracks = 100, dirs = {[7] = "-", [6] = "+"}},
        ["switchL4"] = {tracks = 200, dirs = {[8] = "-", [7] = "+"}},
        ["switchL5"] = {tracks = 145, dirs = {[1] = "-", [8] = "+"}},
        ["switchL6"] = {tracks = 35, dirs = {[2] = "-", [1] = "+"}},
        ["switchL7"] = {tracks = 70, dirs = {[3] = "-", [2] = "+"}},
        ["switchL8"] = {tracks = 140, dirs = {[4] = "-", [3] = "+"}},
        ["switchR1"] = {tracks = 49, dirs = {[5] = "-", [6] = "+"}},
        ["switchR2"] = {tracks = 98, dirs = {[6] = "-", [7] = "+"}},
        ["switchR3"] = {tracks = 196, dirs = {[7] = "-", [8] = "+"}},
        ["switchR4"] = {tracks = 137, dirs = {[8] = "-", [1] = "+"}},
        ["switchR5"] = {tracks = 19, dirs = {[1] = "-", [2] = "+"}},
        ["switchR6"] = {tracks = 38, dirs = {[2] = "-", [3] = "+"}},
        ["switchR7"] = {tracks = 76, dirs = {[3] = "-", [4] = "+"}},
        ["switchR8"] = {tracks = 152, dirs = {[4] = "-", [5] = "+"}},
        ["switchW1"] = {tracks = 41, dirs = {[4] = "-", [6] = "+"}},
        ["switchW2"] = {tracks = 82, dirs = {[5] = "-", [7] = "+"}},
        ["switchW3"] = {tracks = 164, dirs = {[6] = "-", [8] = "+"}},
        ["switchW4"] = {tracks = 73, dirs = {[7] = "-", [1] = "+"}},
        ["switchW5"] = {tracks = 146, dirs = {[8] = "-", [2] = "+"}},
        ["switchW6"] = {tracks = 37, dirs = {[1] = "-", [3] = "+"}},
        ["switchW7"] = {tracks = 74, dirs = {[2] = "-", [4] = "+"}},
        ["switchW8"] = {tracks = 148, dirs = {[3] = "-", [5] = "+"}},
        ["switchD1"] = {tracks = 51, dirs = {[1] = "ab-", [2] = "ab+", [5] = "cd-", [6] = "cd+"}, doubleSwitch = true},
        ["switchD2"] = {tracks = 102, dirs = {[3] = "ab-", [2] = "ab+", [7] = "cd-", [6] = "cd+"}, doubleSwitch = true},
        ["switchD3"] = {tracks = 204, dirs = {[3] = "ab-", [4] = "ab+", [7] = "cd-", [8] = "cd+"}, doubleSwitch = true},
        ["switchD4"] = {tracks = 153, dirs = {[1] = "ab-", [8] = "ab+", [5] = "cd-", [4] = "cd+"}, doubleSwitch = true},
        ["switchT1"] = {tracks = 57},
        ["switchT2"] = {tracks = 114},
        ["switchT3"] = {tracks = 228},
        ["switchT4"] = {tracks = 201},
        ["switchT5"] = {tracks = 147},
        ["switchT6"] = {tracks = 39},
        ["switchT7"] = {tracks = 78},
        ["switchT8"] = {tracks = 156},
        ["buffer1"] = {tracks = 1, buffer = 1},
        ["buffer2"] = {tracks = 2, buffer = 2},
        ["buffer3"] = {tracks = 4, buffer = 3},
        ["buffer4"] = {tracks = 8, buffer = 4},
        ["buffer5"] = {tracks = 16, buffer = 5},
        ["buffer6"] = {tracks = 32, buffer = 6},
        ["buffer7"] = {tracks = 64, buffer = 7},
        ["buffer8"] = {tracks = 128, buffer = 8},
        ["derailer1"] = {tracks = 17, derailer = 7},
        ["derailer2"] = {tracks = 34, derailer = 8},
        ["derailer3"] = {tracks = 68, derailer = 1},
        ["derailer4"] = {tracks = 136, derailer = 2},
        ["derailer5"] = {tracks = 17, derailer = 3},
        ["derailer6"] = {tracks = 34, derailer = 4},
        ["derailer7"] = {tracks = 68, derailer = 5},
        ["derailer8"] = {tracks = 136, derailer = 6},
        ["semaphore1"] = {tracks = 17, semaphore = 3},
        ["semaphore2"] = {tracks = 34, semaphore = 2},
        ["semaphore3"] = {tracks = 68, semaphore = 1},
        ["semaphore4"] = {tracks = 136, semaphore = 8},
        ["semaphore5"] = {tracks = 17, semaphore = 7},
        ["semaphore6"] = {tracks = 34, semaphore = 6},
        ["semaphore7"] = {tracks = 68, semaphore = 5},
        ["semaphore8"] = {tracks = 136, semaphore = 4},
        ["arrow3"] = {background = 12, foreground = 12},
        ["arrow7"] = {background = 11, foreground = 11},
        ["arrow-"] = {background = 13, foreground = 13},
        ["loco"] = {background = 14, foreground = 14},
        ["square"] = {background = 15, foreground = 15},
    }

    -- Name convention:
    -- Tile type can be:
    -- - track - Track shape as a character of -/|\+X
    -- - platform - P - passenger, F - freight
    -- - curve - Starting direction, turning left
    -- - switch - Starting direction (where two tracks converge), with a letter beforehand:
    --   - L - left switch, R - right switch, W - wye switch, D - double switch, T - triple switch
    -- - buffer - Starting direction (from which we are approaching the buffer)
    -- - derailer - Exit direction (which way we need to go to be affected by it)
    -- - semaphore - Exit direction (which way we need to go to be affected by it)
    -- - arrow - Direction it is pointing to, or -/|\ for double arrows
    -- - loco, square - Images
    -- - letter - Capital character
    self.compatibilityList = {
        [0] = "",
        "track-", "track|", "track+", "platformP", "track/", "track\\", "trackX", "platformF",
        "curve6", "curve3", "curve7", "curve2", "curve1", "curve8", "curve4", "curve5",
        "switchL3", "switchR3", "switchR7", "switchL7", "switchR1", "switchL5", "switchL1", "switchR5",
        "switchD2", "switchD3", "switchD4", "switchD1", "switchR2", "switchR6", "switchL6", "switchL2",
        "switchL8", "switchL4", "switchR4", "switchR8", "switchW6", "switchW8", "switchW4", "switchW2",
        "switchT6", "switchT8", "switchT4", "switchT2", "switchT7", "switchT3", "switchT1", "switchT5",
        "switchW7", "switchW3", "switchW1", "switchW5", "buffer7", "buffer3", "buffer1", "buffer5",
        "derailer3", "derailer7", "derailer5", "derailer1", "semaphore3", "semaphore7", "semaphore5", "semaphore1",
        "semaphore2", "semaphore6", "semaphore4", "semaphore8", "arrow7", "arrow3", "arrow-", "loco", "square",
        "buffer2", "buffer4", "buffer6", "buffer8", "derailer6", "derailer2", "derailer4", "derailer8"
    }
end

---Returns the data of the specified tile, or `nil` if it doesn't exist.
---@param id integer|string The tile ID.
---@return TileData
function TileDatabase:getTile(id)
    return assert(self.tiles[id] or self.tiles[self.compatibilityList[id]], "Invalid tile ID: " .. tostring(id))
end

---Returns the string ID from the integer ID, or the ID itself if it is already string ID.
---@param id integer|string The tile ID.
---@return string
function TileDatabase:idToString(id)
    return self.compatibilityList[id] or tostring(id)
end

return TileDatabase