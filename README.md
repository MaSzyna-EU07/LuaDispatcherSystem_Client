# Was ist das

This is a client application for the Lua Dispatcher System for MaSzyna.

This is an application which serves as an editor and previewer of the current simualation state.
It is not necessary for playing the scenarios which use the Lua Dispatcher System.

# How to run

The code shared with the server is in the `lua/core` directory, which is a git submodule
([LuaDispatcherSystem_CORE](https://github.com/MaSzyna-EU07/LuaDispatcherSystem_CORE)).
Clone this repository with `git clone --recurse-submodules`, or run `git submodule update --init` in an existing clone.
Without it the `lua/core` directory is empty and the application does not start.

You must install LOVE2D (tested against 11.5): https://love2d.org/

Next, run this application like any other LOVE2D application from its main directory from the command line.
It is wise to make a `.bat` or `.sh` script to launch it. I am not providing it because the LOVE2D installation path can change.

Find more information here: https://love2d.org/wiki/Getting_Started#Running_Games

# Quick primer

The interface is something I will not really describe. It's really complicated, barebones and buggy.

Before launching, you must create a `settings.json` file with the following contents:

```json
{
	"scale": 1.5,
	"simPath": "C:/PATH/TO/MASZYNA/MAIN/DIRECTORY"
}
```

Otherwise the program will crash. There is no dialog for selecting the simulator's root directory.

Then click the Load button and select the project you wish to open. There is no "New Project" button yet.

At the bottom pane you have an option to refresh the debugging state.
When you launch the simulator, you can refresh the state and see changes in the simulation happen in real time in the schematic window.

This is not a well detailed description! Good luck figuring the rest out for yourself! Everything will change anyway.

## Credits
This repository contains code from external sources:
- Class implementation from https://github.com/bncastle/love2d-tutorial/blob/Episode4/class.lua (MIT license)
- JSON decoder/encoder implementation from https://github.com/rxi/json.lua (MIT license)
- Modified GSpot library (added luadoc) from... I actually don't know! Has the repo it was on been deleted? (custom license?)

The schematic graphics are modified graphics from Kolejarz and are free to use everywhere! They're basic 14x14 sprites, so why would I care about going after you for that lol