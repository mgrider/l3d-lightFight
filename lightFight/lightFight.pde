import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;

import L3D.*;

// controller stuff
ControlIO control;
Configuration config;
ControlDevice[] gpads;
int controllerFrameRepeat = 10;
boolean[] previousLeft = new boolean[4];
boolean[] previousRight = new boolean[4];
boolean[] previousUp = new boolean[4];
boolean[] previousDown = new boolean[4];
int keyboardPlayerIndex = 3; // set to 3 to "turn off" keyboard input

// L3D stuff
L3D cube;
String accessToken = "2d3fda69fc6af796a1bdd2ae849de2cb292268e4";
String coreName = "L3D";
boolean drawToScreen = true;

// game stuff
int playersMax = 4; // (really for this game it is 3, but we support 4 controllers, and 4 is hard-coded many places)
boolean isGameOver = false;
int winningPlayer = 0;
int winningFrameCount = 0;
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
float animationColorIncrement = 128.0;


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
    drawGameOver();
    return;
  }

  // draw background (TODO: make this fancier than just black, undulating water effect maybe?)
  drawCubeBackground();

  // check for input every frame
  updatePlayerCoordFromInput();

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
  winningPlayer = -1;
  // is this player currently playing?
  isPlaying[0] = true;
  isPlaying[1] = false;
  isPlaying[2] = false;
  isPlaying[3] = false;
  // is anyone using the keyboard?
  keyboardPlayerIndex = 0;
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
  if (totalBoardPercent >= 0.9)
  {
    println("percent for p1=" + playerBoardPercent[0] + " p2=" + playerBoardPercent[1] + " p3=" + playerBoardPercent[2] + " total=" + totalBoardPercent);
    isGameOver = true;
    winningFrameCount = frameCount;
  }
}

void drawGamePercentIndicator()
{
  color winningColor = color(255,255,255);
  float bestPercent = 0.0;
  int leadingPlayer = -1;
  for (int player = 0; player < playersMax; player++)
  {
    if ( ! isPlaying[player] ) {
      continue;
    }
    if (playerBoardPercent[player] > bestPercent)
    {
      winningColor = playerColor[player];
      bestPercent = playerBoardPercent[player];
      leadingPlayer = player;
    }
    else if ((playerBoardPercent[player] - bestPercent) < 0.00001)
    {
      winningColor = color(255,255,255);
      leadingPlayer = -1;
    }
  }
  float onlyShowUpTo = 8 * bestPercent;
  for (int x=0; x<8; x+=7) {
    for (int z=0; z<8; z+=7) {
      for (int y=0; y<8; y++)
      {
        space.x = x;
        space.y = y;
        space.z = z;
        if (y>onlyShowUpTo)
        {
          cube.setVoxel(space,0);
        }
        else if (y==0 || frameCount%8 == y)
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
    winningPlayer = leadingPlayer;
  }
}

void drawGameOver()
{
  if ((frameCount - winningFrameCount) > 200)
  {
    setupForNewGame();
    cube.background(0);
    return;
  }
  // blink winning color every 10 frames
  if (frameCount%20 > 10)
  {
    cube.background(0);
    return;
  }
  color winningColor = color(255,255,255);
  if (winningPlayer != -1)
  {
    winningColor = playerColor[winningPlayer];
  }
  cube.background(winningColor);
}


// drawing random stuff

void drawPlayers()
{
  if (frameCount%20 > 10) {
    return;
  }
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
      color c;
      float r=0,g=0,b=0;
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
        c = cube.getVoxel(tempSpace[i]);
        switch (player) {
          case 0: {
            r = 255;
            g = green(c) - animationColorIncrement;
            if (g < 0.0) { g = 0; }
            b = blue(c) - animationColorIncrement;
            if (b < 0.0) { b = 0; }
            break;
          }
          case 1: {
            r = red(c) - animationColorIncrement;
            if (r < 0.0) { r = 0; }
            g = 255;
            b = blue(c) - animationColorIncrement;
            if (b < 0.0) { b = 0; }
            break;
          }
          case 2: {
            r = red(c) - animationColorIncrement;
            if (r < 0.0) { r = 0; }
            g = green(c) - animationColorIncrement;
            if (g < 0.0) { g = 0; }
            b = 255;
            break;
          }
        }
        cube.setVoxel(tempSpace[i],color(r,g,b));
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
  // loop through and get input
  for ( int player = 0; player < playersMax; player++)
  {
    if ( ! isPlaying[player] ||
        player == keyboardPlayerIndex)
    {
      // do nothing
      continue;
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
        if ( ! isPlayerAnimating[player])
        {
          playerAnimationFrameCount[player] = 0;
          isPlayerAnimating[player] = true;
          playerAnimationCoord[player].x = space.x;
          playerAnimationCoord[player].y = space.y;
          playerAnimationCoord[player].z = space.z;
        }
      }

      // left
      if (gpads[player].getButton("LEFT").pressed())
      {
        if (( ! previousLeft[player]) ||
            (frameCount%controllerFrameRepeat == 0))
        {
          previousLeft[player] = true;
          // what spot should we be checking?
          updateSpaceForPlayerCoord(player,LEFT);
        }
      }
      else
      {
        previousLeft[player] = false;
      }
      // right
      if (gpads[player].getButton("RIGHT").pressed())
      {
        if (( ! previousRight[player]) ||
            (frameCount%controllerFrameRepeat == 0))
        {
          previousRight[player] = true;
          // what spot should we be checking?
          updateSpaceForPlayerCoord(player,RIGHT);
        }
      }
      else
      {
        previousRight[player] = false;
      }
      // up
      if (gpads[player].getButton("UP").pressed())
      {
        if (( ! previousUp[player]) ||
            (frameCount%controllerFrameRepeat == 0))
        {
          previousUp[player] = true;
          // what spot should we be checking?
          updateSpaceForPlayerCoord(player,UP);
        }
      }
      else
      {
        previousUp[player] = false;
      }
      // down
      if (gpads[player].getButton("DOWN").pressed())
      {
        if (( ! previousDown[player]) ||
            (frameCount%controllerFrameRepeat == 0))
        {
          previousDown[player] = true;
          // what spot should we be checking?
          updateSpaceForPlayerCoord(player,DOWN);
        }
      }
      else
      {
        previousDown[player] = false;
      }
    }
  }
}

void keyPressed()
{
  if(keyboardPlayerIndex > -1 && keyboardPlayerIndex < 3)
  {
    if(key == CODED)
    {
      switch(keyCode)
      {
        case UP: {
          break;
        }
        case LEFT: {
          break;
        }
        case DOWN: {
          break;
        }
        case RIGHT: {
          break;
        }
      }
    }
    else if (key == ENTER || key == RETURN)
    {
      if ( ! isPlayerAnimating[keyboardPlayerIndex])
      {
        playerAnimationFrameCount[keyboardPlayerIndex] = 0;
        isPlayerAnimating[keyboardPlayerIndex] = true;
        space.x = playerCoord[keyboardPlayerIndex].x;
        space.y = playerCoord[keyboardPlayerIndex].y;
        space.z = playerCoord[keyboardPlayerIndex].z;
        playerAnimationCoord[keyboardPlayerIndex].x = space.x;
        playerAnimationCoord[keyboardPlayerIndex].y = space.y;
        playerAnimationCoord[keyboardPlayerIndex].z = space.z;
      }
    }
  }
}

void updateSpaceForPlayerCoord(int player, int direction)
{
  // this assumes space has already been initialized with playerCoord
  switch (direction)
  {
    case LEFT: {
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
      if ( ! positionContainsPlayer(space))
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
      break;
    }
    case RIGHT: {
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
      if ( ! positionContainsPlayer(space))
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
      break;
    }
    case UP: {
      space.y = space.y + 1;
      if (space.y < 8 &&
          ( ! positionContainsPlayer(space)))
      {
        playerCoord[player].y = space.y;
      }
      else {
        space.y = playerCoord[player].y;
      }
      break;
    }
    case DOWN: {
      space.y = space.y - 1;
      if (space.y >= 0 &&
          ( ! positionContainsPlayer(space)))
      {
        playerCoord[player].y = space.y;
      }
      else {
        // don't need this, because it's the last thing we're checking
      }
      break;
    }
  }
}

void setupControllers()
{
  control = ControlIO.getInstance(this);
  gpads = new ControlDevice[4];
  if (isPlaying[0] &&
      keyboardPlayerIndex != 0)
  {
    gpads[0] = control.getMatchedDevice("controller");
    if (gpads[0] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  if (isPlaying[1] &&
      keyboardPlayerIndex != 1)
  {
    gpads[1] = control.getMatchedDevice("controller2");
    if (gpads[1] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  if (isPlaying[2]
      keyboardPlayerIndex != 2)
  {
    gpads[2] = control.getMatchedDevice("controller3");
    if (gpads[2] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  if (isPlaying[3]
      keyboardPlayerIndex != 3)
  {
    gpads[3] = control.getMatchedDevice("controller4");
    if (gpads[3] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  for (int player = 0; player<playersMax; player++)
  {
    previousLeft[player] = false;
    previousRight[player] = false;
    previousUp[player] = false;
    previousDown[player] = false;
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
