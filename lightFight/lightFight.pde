import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;

import L3D.*;

// controller stuff
ControlIO control;
Configuration config;
ControlDevice[] gpads;

// L3D stuff
L3D cube;
String accessToken = "2d3fda69fc6af796a1bdd2ae849de2cb292268e4";
String coreName = "L3D";
boolean drawToScreen = true;

// game stuff
int playersMax = 4; // (really for this game it is 3, but we support 4 controllers, and 4 is hard-coded many places)
boolean isGameOver = false;
PVector[] playerCoord = new PVector[4];
boolean[] isPlaying = new boolean[4];
color[] playerColor = new color[4];
float[] playerBoardPercent = new float[4];
float totalBoardPercent = 0.0;
int framesForAnimation = 10;
int totalAnimationDistance = 4;
boolean[] isPlayerAnimating = new boolean[4];
int[] playerAnimationFrameCount = new int[4];
PVector[] playerAnimationCoord = new PVector[4];
PVector space = new PVector(0,0,0);
PVector[] tempSpace = new PVector[4];
byte animationColorIncrement = (byte)128;


void setup()
{
  // processing
  if (drawToScreen) {
    size(600, 600, P3D);
  }

  // game related setup
  setupForNewGame();

  // l3d
  setupL3D();

  // controllers
  setupControllers();
}

public void draw()
{
  //set the processing sketch bg and cube bg to black
  if (drawToScreen) {
    this.background(0);
  }

  if (isGameOver)
  {
    updatePlayerCoordFromInput();
    return;
  }

  // draw background (TODO: make this fancier than just black, undulating water effect maybe?)
  drawCubeBackground();

  // check for input every X frame
  if ((frameCount%2) == 0) {
    updatePlayerCoordFromInput();
  }

  drawPlayers();
  drawPlayerAnimations();

  setPlayerPercentAndCheckForGameOver();
  drawGamePercentIndicator();
}


// game setup

void setupForNewGame()
{
  playersMax = 4;
  isPlaying = new boolean[playersMax];
  isGameOver = false;
  // is this player currently playing?
  isPlaying[0] = true;
  isPlaying[1] = true;
  isPlaying[2] = false;
  isPlaying[3] = false;
  // player colors
  playerColor[0] = color(255, 0, 0);
  playerColor[1] = color(0, 255, 0);
  playerColor[2] = color(0, 0, 255);
  playerColor[3] = color(255, 255, 0);
  // state
  for (int i=0; i<playersMax; i++)
  {
    isPlayerAnimating[i] = false;
    playerAnimationCoord[i] = new PVector(0,0,0);
    playerCoord[i] = new PVector(0,0,0);
    playerBoardPercent[i] = 0.0;
    if (isPlaying[i]) {
      setPlayerToStartingPosition(i);
    }
  }
  for (int i=0; i<4; i++)
  {
    tempSpace[i] = new PVector(0,0,0);
  }
}


// game over stuff

void setPlayerPercentAndCheckForGameOver()
{
  int p1=0, p2=0, p3=0, pTotal=0;
  float r=0.0, g=0.0, b=0.0;
  color current;
  for (int x=1; x<7; x++) {
    for (int z=1; z<7; z++) {
      for (int y=0; y<8; y++)
      {
        space.x = x;
        space.z = z;
        space.y = y;
        current = cube.getVoxel(space);
        if (current == 0) {
          continue;
        }
        r = red(current);
        g = green(current);
        b = blue(current);
        if (r > 0) {
          p1++;
        }
        if (g > 0) {
          p2++;
        }
        if (b > 0) {
          p3++;
        }
        if (r>0 || g>0 || b>0) {
          pTotal++;
        }
      }
    }
  }
  // calculate percentages
  float totalPlayingField = 6.0 * 6.0 * 8.0;
  if (isPlaying[0] && p1 > 0) {
    playerBoardPercent[0] = p1 / totalPlayingField;
  }
  if (isPlaying[1] && p2 > 0) {
    playerBoardPercent[1] = p2 / totalPlayingField;
  }
  if (isPlaying[2] && p3 > 0) {
    playerBoardPercent[2] = p3 / totalPlayingField;
  }
  if (pTotal > 0) {
    totalBoardPercent = pTotal / totalPlayingField;
  }
  println("percent for p1=" + playerBoardPercent[0] + " p2=" + playerBoardPercent[1] + " p3=" + playerBoardPercent[2] + " total=" + totalBoardPercent);
  if (totalBoardPercent == 1.0) {
    isGameOver = true;
  }
}

void drawGamePercentIndicator()
{
  color winningColor = color(255,255,255);
  float bestPercent = 0.0;
  for (int player = 0; player < playersMax; player++)
  {
    if ( ! isPlaying[player] ) {
      continue;
    }
    if (playerBoardPercent[player] > bestPercent)
    {
      winningColor = playerColor[player];
      bestPercent = playerBoardPercent[player];
    }
    else if (playerBoardPercent[player] == bestPercent)
    {
      winningColor = color(255,255,255);
    }
  }
  for (int x=0; x<8; x+=7) {
    for (int z=0; z<8; z+=7) {
      for (int y=0; y<8; y++)
      {
        space.x = x;
        space.y = y;
        space.z = z;
        if (y==0 || frameCount%8 == y)
        {
          cube.setVoxel(space,winningColor);
        }
        else {
          cube.setVoxel(space,0);
        }
      }
    }
  }
  if (isGameOver)
  {
    cube.background(winningColor);
  }
}

// not used
void drawGameOver()
{
  color winningColor = color(255,255,255);
  float bestPercent = 0.0;
  for (int player = 0; player < playersMax; player++)
  {
    if ( ! isPlaying[player]) {
      continue;
    }
    if (playerBoardPercent[player] > bestPercent)
    {
      winningColor = playerColor[player];
      bestPercent = playerBoardPercent[player];
    }
    else if (playerBoardPercent[player] == bestPercent)
    {
      winningColor = color(255,255,255);
    }
  }
  cube.background(winningColor);
}


// drawing random stuff

void drawPlayers()
{
  // set the playerCoord on the cube
  for ( int player = 0; player < playersMax; player = player + 1)
  {
    if (isPlaying[player]) {
      cube.setVoxel(playerCoord[player], playerColor[player]);
    }
  }
}

void drawPlayerAnimations()
{
  for ( int player = 0; player < playersMax; player++)
  {
    if (isPlayerAnimating[player] &&
        (frameCount % framesForAnimation) == 0)
    {
      // increment first (we started at zero)
      playerAnimationFrameCount[player] = playerAnimationFrameCount[player] + 1;
      // how many frames "into" the animation are we?
      int depth = playerAnimationFrameCount[player];
      // get the space to modify
      space.x = playerAnimationCoord[player].x;
      space.y = playerAnimationCoord[player].y;
      space.z = playerAnimationCoord[player].z;
      // we only want to change the space at the current depth
      // switch on direction
      if (playerAnimationCoord[player].x == 0)
      {
        // right
        space.x = space.x + depth;
        tempSpace[0].set( space.x, space.y, space.z-1);
        tempSpace[1].set( space.x, space.y, space.z+1);
        tempSpace[2].set( space.x, space.y+1, space.z);
        tempSpace[3].set( space.x, space.y-1, space.z);
      }
      else if (playerAnimationCoord[player].x == 7)
      {
        // left
        space.x = space.x - depth;
        tempSpace[0].set( space.x, space.y, space.z-1);
        tempSpace[1].set( space.x, space.y, space.z+1);
        tempSpace[2].set( space.x, space.y+1, space.z);
        tempSpace[3].set( space.x, space.y-1, space.z);
      }
      else if (playerAnimationCoord[player].z == 0)
      {
        // back
        space.z = space.z + depth;
        tempSpace[0].set( space.x-1, space.y, space.z);
        tempSpace[1].set( space.x+1, space.y, space.z);
        tempSpace[2].set( space.x, space.y+1, space.z);
        tempSpace[3].set( space.x, space.y-1, space.z);
      }
      else if (playerAnimationCoord[player].z == 7)
      {
        // forward
        space.z = space.z - depth;
        tempSpace[0].set( space.x-1, space.y, space.z);
        tempSpace[1].set( space.x+1, space.y, space.z);
        tempSpace[2].set( space.x, space.y+1, space.z);
        tempSpace[3].set( space.x, space.y-1, space.z);
      }
      // change the color at the current space
      //System.out.println("ready to save new color at space x:" + space.x + " y:" + space.y + " z:" + space.z);
      cube.setVoxel(space, playerColor[player]);
      // change the colors at the immediately surrounding spaces
      for ( int i=0; i<4; i++)
      {
        if (tempSpace[i].x < 0 ||
            tempSpace[i].x > 7 ||
            tempSpace[i].y < 0 ||
            tempSpace[i].y > 7 ||
            tempSpace[i].z < 0 ||
            tempSpace[i].z > 7)
        {
          continue;
        }
        cube.addVoxel(tempSpace[i].x,tempSpace[i].y,tempSpace[i].z,playerColor[player]);
      }
      // check for done
      if (depth >= totalAnimationDistance)
      {
        isPlayerAnimating[player] = false;
      }
    }
  }
}

void drawCubeBackground()
{
//  cube.background(0);
//  cube.background(color(255,255,255));

  // draw outside black
  for ( int x=0; x<8; x++ ) {
    for (int z=0; z<8; z++) {
      for (int y=0; y<8; y++){
        if (x == 0 ||
            x == 7 ||
            z == 0 ||
            z == 7)
        {
          space.x = x;
          space.y = y;
          space.z = z;
          cube.setVoxel(space,0);
        }
        else
        {
          z = 6;
          continue;
        }
      }
    }
  }
}

// check position for player
boolean positionContainsPlayer(PVector position)
{
  for ( int player = 0; player < playersMax; player++)
  {
    if ( ! isPlaying[player])
    {
      continue;
    }
    if (position.x == 99)
    {
      continue;
    }
    if (playerCoord[player].x == position.x && playerCoord[player].y == position.y && playerCoord[player].z == position.z)
    {
      return true;
    }
  }
  return false;
}

// set player to starting position (defaults)
void setPlayerToStartingPosition(int player)
{
  switch(player)
  {
    case 0: {
      space.set(2,2,7);
      break;
    }
    case 1: {
      space.set(5,5,7);
      break;
    }
    case 2: {
      space.set(5,2,7);
      break;
    }
    case 3: {
      space.set(2,5,7);
      break;
    }
  }
  playerCoord[player].set(space);
}

// input
void updatePlayerCoordFromInput()
{
  // only used if the game is over
  boolean wantsNewGame = true;

  // loop through and get input
  for ( int player = 0; player < playersMax; player++)
  {
    if ( ! isPlaying[player])
    {
      // do nothing
      // check for start button pressed
//      if (gpads[player].getButton("START").pressed())
//      {
//        setPlayerToStartingPosition(player);
//      }
    }
    else
    {
      // init possible space to playerCoord for player
      space.x = playerCoord[player].x;
      space.y = playerCoord[player].y;
      space.z = playerCoord[player].z;

      // first check for player pressing the attack button
      if (gpads[player].getButton("BOTTOMBUTTON").pressed())
      {
        if (isGameOver)
        {
          wantsNewGame = (wantsNewGame && true);
        }
        else if ( ! isPlayerAnimating[player])
        {
          playerAnimationFrameCount[player] = 0;
          isPlayerAnimating[player] = true;
          playerAnimationCoord[player].x = space.x;
          playerAnimationCoord[player].y = space.y;
          playerAnimationCoord[player].z = space.z;
        }
      }
      else if (isGameOver)
      {
        wantsNewGame = false;
        continue;
      }

      // left
      switch ((int)space.x)
      {
        case 0: { // left side
          if (space.z == 1) {
            space.z = 0;
            space.x = 1;
          }
          else {
            space.z = space.z - 1;
          }
          break;
        }
        case 1: { // round the corner?
          if (space.z == 7) {
            space.z = 6;
            space.x = 0;
          }
          else if (space.z == 0) {
            space.x = 2;
          }
          break;
        }
        case 6: { /// round the corner?
          if (space.z == 7) {
            space.x = 5;
          }
          else if (space.z == 0) {
            space.x = 7;
            space.z = 1;
          }
          break;
        }
        case 7: {
          if (space.z == 6) {
            space.x = 6;
            space.z = 7;
          }
          else {
            space.z = space.z + 1;
          }
          break;
        }
        default: {
          if (space.z == 0) {
            // back wall (reverse)
            space.x = space.x + 1;
          }
          else {
            space.x = space.x - 1;
          }
          break;
        }
      }
      if (gpads[player].getButton("LEFT").pressed() &&
          ( ! positionContainsPlayer(space)))
      {
        playerCoord[player].x = space.x;
        playerCoord[player].y = space.y;
        playerCoord[player].z = space.z;
      }
      else {
        space.x = playerCoord[player].x;
        space.y = playerCoord[player].y;
        space.z = playerCoord[player].z;
      }
      // right
      switch ((int)space.x)
      {
        case 0: { // left side
          if (space.z == 6) {
            space.z = 7;
            space.x = 1;
          }
          else {
            space.z = space.z + 1;
          }
          break;
        }
        case 1: { // round the corner?
          if (space.z == 0) {
            space.z = 1;
            space.x = 0;
          }
          else {
            space.x = 2;
          }
          break;
        }
        case 6: { /// round the corner?
          if (space.z == 7) {
            space.x = 7;
            space.z = 6;
          }
          else if (space.z == 0) {
            space.x = 5;
          }
          break;
        }
        case 7: {
          if (space.z == 1) {
            space.x = 6;
            space.z = 0;
          }
          else {
            space.z = space.z - 1;
          }
          break;
        }
        default: {
          if (space.z == 0) {
            // back wall (reverse)
            space.x = space.x - 1;
          }
          else {
            space.x = space.x + 1;
          }
          break;
        }
      }
      if (gpads[player].getButton("RIGHT").pressed() &&
          ( ! positionContainsPlayer(space)))
      {
        playerCoord[player].x = space.x;
        playerCoord[player].y = space.y;
        playerCoord[player].z = space.z;
      }
      else {
        space.x = playerCoord[player].x;
        space.y = playerCoord[player].y;
        space.z = playerCoord[player].z;
      }
      // up
      space.y = space.y + 1;
      if (gpads[player].getButton("UP").pressed() &&
          space.y < 8 &&
          ( ! positionContainsPlayer(space)))
      {
        playerCoord[player].y = space.y;
      }
      else {
        space.y = playerCoord[player].y;
      }
      // down
      space.y = space.y - 1;
      if (gpads[player].getButton("DOWN").pressed() &&
          space.y >= 0 &&
          ( ! positionContainsPlayer(space)))
      {
        playerCoord[player].y = space.y;
      }
      else {
        // don't need this, because it's the last thing we're checking
      }
    }
  }

  // check for all players pressing the button
  if (isGameOver && wantsNewGame)
  {
    setupForNewGame();
    cube.background(0);
  }
}

void setupControllers()
{
  control = ControlIO.getInstance(this);
  gpads = new ControlDevice[4];
  if (isPlaying[0]) {
    gpads[0] = control.getMatchedDevice("controller");
    if (gpads[0] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  if (isPlaying[1]) {
    gpads[1] = control.getMatchedDevice("controller2");
    if (gpads[1] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  if (isPlaying[2]) {
    gpads[2] = control.getMatchedDevice("controller3");
    if (gpads[2] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  if (isPlaying[3]) {
    gpads[3] = control.getMatchedDevice("controller4");
    if (gpads[3] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
}

void setupL3D()
{
  cube = new L3D(this, accessToken);

  if (drawToScreen) {
    cube.enableDrawing();  //draw the virtual cube
    cube.enablePoseCube();
  }

// note, disabling multicastStreaming gives MUCH better performance
//  cube = new L3D(this);
//  cube.enableMulticastStreaming();  //stream the data over UDP to any L3D cubes that are listening on the local network

  // stream directly to the L3D here (note, requires internet connection for setup)
  cube.streamToCore(coreName);
//  cube.background(color(255,255,255));
}
