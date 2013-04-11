# About
Tanks and Mirrors is a simple 2D-puzzle game written in FreeBASIC. It's similar to the minigame "Ghouls and Guards" (hence the the repo title) from the Nintendo 3DS game Professor Layton.

# Rules of play
The player is given a tiled board devided into areas. Each area should contain extacly one mirror. Tanks are placed on the edges and need to shoot a beam to another tile or edge on the board with a given number of reflections. All tanks will require at least one reflection. The players task is to place the diagonal mirrors ("/" or "\") and satisfy the following conditions:

* Each area contains exactly one mirror.
* All beams exit the board at the given places.
* All beams are reflected exactly as many times as denoted on the edges of the board.

# Current State
This is not an application that can be presented to end users yet. It is possible now to play a random generated puzzle but the application has no interface besides that, no menu's etc. Furthermore the pathfinding algorithm used to generate puzzles with a unique solution is somewhat 'broken'.  When trying to add quicker pruning, valid routes seem to be cut. So unique puzzles are generated that actually have multiple solutions. Of course generated puzzles should only have one unique solution.

## Imlemented

* Generation of puzzles (although not working correctly now)
* Displaying generated puzzle on the screen
* Letting the player solve the puzzle with mouse input 

## TODO

* Fix pathfinding
* Fix color scheme of the tanks so they get more distinctive colors.
* Add menu
* Add ability to load/save puzzles
* Generate harder puzzles (less routes of 1 reflection given)
* Add keyboard input for puzzle solving

# How to build
Clone this repository or download everything and extract to a folder you like. When cloning this repository a directory witht he name of the repo will be created automatically.

## Windows

* fbc main.bas
* run main.exe
	
## Linux

* fbc main.bas
* run the executable: ./main

for Ubuntu 12.10 there is an extra parameter that has to be set due to a bug:

* change compile line to: fbc -l stdc++ main.bas

# About FreeBASIC
FreeBASIC is a programming language available for multiple platforms. It's largely backwards compatible with QBASIC but adds many features of C(++) to the mix. FreeBASIC is free as in beer and freedom. Get it here: http://www.freebasic.net/
