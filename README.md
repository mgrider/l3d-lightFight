# l3d-lightFight
Light Fight is a game for the L3D created by Martin Grider. More info about the L3D at http://l3dcube.com/ or http://cubetube.org/

Video here: [![https://www.youtube.com/watch?v=cUGXW8xV4vw](http://img.youtube.com/vi/cUGXW8xV4vw/0.jpg)](https://www.youtube.com/watch?v=cUGXW8xV4vw) 

# controllers
This project requires XBox 360 controllers (or equivalent) to run propperly.

On OSX, you'll need to make sure a driver is installed. (For example: https://github.com/d235j/360Controller/ -- Other platforms are as yet untested.)

# setup
1. This is a streaming app, so you'll need to setup the listener on your L3D.
2. You'll need to change the accessToken and coreName variables to those for your L3D.
3. For now, change the isPlaying[] true/false variables in setup() to match the number of Xbox controllers you have plugged into your computer.

# todo
* port to native code for better light variations and control (requires USB shield)

# credits

Light Fight uses the L3D Processing library: https://github.com/enjrolas/L3D-library/

It also uses the Game Control Plus Processing Library: http://lagers.org.uk/gamecontrol/

