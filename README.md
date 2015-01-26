# Light Fight and Match-L3D
Light Fight and Match-L3D are games made for the L3D, and designed/developed/created by Martin Grider. More info about the L3D at http://l3dcube.com/ or http://cubetube.org/

[![https://www.youtube.com/watch?v=cUGXW8xV4vw](http://img.youtube.com/vi/cUGXW8xV4vw/0.jpg)](https://www.youtube.com/watch?v=cUGXW8xV4vw) 

# How to play

LightFight must be played with controllers (see below). During the game, you move your pixel around the cube, firing bolts of your color into center. When a good portion of the center (90% or so) is full, the game ends and whoever had the most of their color in the center is the winner. (The L3D should flash the color of the winning player.) The game supports and plays best with 3 players, although it is sorta fun with 2 also.

Match-L3D is a turn-based game where you drop 2x2x2 cubes of random colors into the gameboard. At first, three like-colored pixels that are adjacent will be removed from the gameboard, but subsequent groups must be 4 and then 5 and then 6 pixels in size. After six, the level is increased, (adding another color to the random new cube), and the number of pixels needed for a match resets back to 3. You can play with keyboard or controllers. (Note that Match-L3D may be played without the L3D in the Processing simulator sketch.)

# Controllers
This project requires XBox 360 controllers (or equivalent) to run propperly.

On OSX, you'll need to make sure a driver is installed. (For example: https://github.com/d235j/360Controller/ -- Other platforms are as yet untested.)

# Setup
1. This is a streaming app, so you'll need to setup the listener on your L3D.
2. Change the accessToken and coreName variables at the top of lightFight/lightFight.pde to those for your L3D.
3. For now, change the isPlaying[] true/false variables in setup() to match the number of Xbox controllers you have plugged into your computer.

# Todo
* fix bugs with game over reporting in LightFight
* port to native code for better light variations and control (requires USB shield)
* communicate better with the users (scrolling text?)

# Credits

* These games use the L3D Processing library: https://github.com/enjrolas/L3D-library/
* They also use the Game Control Plus Processing Library: http://lagers.org.uk/gamecontrol/
* Both were originally created by Martin Grider ([gamedev blog](http://chesstris.com/)) of ([Abstract Puzzle](http://abstractpuzzle.com/))
* Match-L3D was created for the 2015 ([Global Game Jam](http://globalgamejam.org/2015/games/match-l3d))

