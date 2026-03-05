local Class = require("class")

---@class TileDatabase : Class
---@overload fun(): TileDatabase
local TileDatabase = Class:derive("TileDatabase")

function TileDatabase:new()
    -- Tracks:
    --[[
    128  1   2
       \ | /
    64 - * -  4
       / | \
    32  16   8
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

    self.tiles = {
        {tracks = 68}, {tracks = 17}, {tracks = 85}, {tracks = 68, background = 9},
        {tracks = 34}, {tracks = 136}, {tracks = 170}, {tracks = 68, background = 10},
        {tracks = 36}, {tracks = 132}, {tracks = 72}, {tracks = 66},
        {tracks = 33}, {tracks = 144}, {tracks = 9}, {tracks = 18},

        {tracks = 100, dirs = {[7] = "-", [6] = "+"}},
        {tracks = 196, dirs = {[7] = "-", [8] = "+"}},
        {tracks = 76, dirs = {[3] = "-", [4] = "+"}},
        {tracks = 70, dirs = {[3] = "-", [2] = "+"}},

        {tracks = 49, dirs = {[5] = "-", [6] = "+"}},
        {tracks = 145, dirs = {[1] = "-", [8] = "+"}},
        {tracks = 25, dirs = {[5] = "-", [4] = "+"}},
        {tracks = 19, dirs = {[1] = "-", [2] = "+"}},

        {tracks = 102, dirs = {[3] = "ab-", [2] = "ab+", [7] = "cd-", [6] = "cd+"}},
        {tracks = 204, dirs = {[3] = "ab-", [4] = "ab+", [7] = "cd-", [8] = "cd+"}},
        {tracks = 153, dirs = {[1] = "ab-", [8] = "ab+", [5] = "cd-", [4] = "cd+"}},
        {tracks = 51, dirs = {[1] = "ab-", [2] = "ab+", [5] = "cd-", [6] = "cd+"}},

        {tracks = 98, dirs = {[6] = "-", [7] = "+"}},
        {tracks = 38, dirs = {[2] = "-", [3] = "+"}},
        {tracks = 35, dirs = {[2] = "-", [1] = "+"}},
        {tracks = 50, dirs = {[6] = "-", [5] = "+"}},

        {tracks = 140, dirs = {[4] = "-", [3] = "+"}},
        {tracks = 200, dirs = {[8] = "-", [7] = "+"}},
        {tracks = 137, dirs = {[8] = "-", [1] = "+"}},
        {tracks = 152, dirs = {[4] = "-", [5] = "+"}},

        {tracks = 37}, {tracks = 148}, {tracks = 73}, {tracks = 82},
        {tracks = 39}, {tracks = 156}, {tracks = 201}, {tracks = 114},
        {tracks = 78}, {tracks = 228}, {tracks = 57}, {tracks = 147},
        {tracks = 74}, {tracks = 164}, {tracks = 41}, {tracks = 146},

        {tracks = 64, buffer = 7},
        {tracks = 4, buffer = 3},
        {tracks = 1, buffer = 1},
        {tracks = 16, buffer = 5},

        {tracks = 68, derailer = 1},
        {tracks = 68, derailer = 5},
        {tracks = 17, derailer = 3},
        {tracks = 17, derailer = 7},

        {tracks = 68, semaphore = 1},
        {tracks = 68, semaphore = 5},
        {tracks = 17, semaphore = 7},
        {tracks = 17, semaphore = 3},

        {tracks = 34, semaphore = 2},
        {tracks = 34, semaphore = 6},
        {tracks = 136, semaphore = 8},
        {tracks = 136, semaphore = 4},

        {background = 11, foreground = 11},
        {background = 12, foreground = 12},
        {background = 13, foreground = 13},
        {background = 14, foreground = 14},
        {background = 15, foreground = 15},
    }
end

return TileDatabase