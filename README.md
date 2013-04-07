# About
Tanks and Mirrors is a simple 2D-puzzle game written in FreeBASIC. It's similar to the minigame "Ghouls and Guards" (hence the the repo title) from the Nintendo 3DS game Professor Layton.

# Rules of play
The player is given a tiled board devided into areas. Each area should contain extacly one mirror. Tanks are placed on the edges and need to shoot a beam to another tile or edge on the board with a given number of reflections. All tanks will require at least one reflection. The players task is to place the diagonal mirrors ("/" or "\") and satisfy the following conditions:

* Each area contains exactly one mirror.
* All beams exit the board at the given places.
* All beams are reflected exactly as many times as denoted on the edges of the board.

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
