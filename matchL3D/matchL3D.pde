import org.gamecontrolplus.gui.*;
import org.gamecontrolplus.*;
import net.java.games.input.*;

import L3D.*;

// controller stuff
ControlIO control;
Configuration config;
ControlDevice[] gpads;
boolean useKeyboard = true;

// L3D stuff
L3D cube;
String accessToken = "2d3fda69fc6af796a1bdd2ae849de2cb292268e4";
String coreName = "L3D";

// drawing to screen / cube
boolean drawToScreen = true;
boolean drawWithCube = false;
PFont f;

// game stuff
int playersMax = 1;
boolean[] isPlaying = new boolean[4];
boolean isGameOver = false;
PVector[] squareCoords = new PVector[8];
color[] squareColors = new color[8];
boolean isSquareAnimating = false;
int squareAnimationSpeed = 20; // number of frames between motion
int squareAnimationFrameCount = 0;
PVector tempVector = new PVector(0,0,0);
int tempColor = 0;
int colorCount = 4; // for level 1
color[] availableColors = new color[8];
int level = 1;
int score = 0;
int gameboardColor = 0;
boolean isAnimatingMatches = false;
int matchAnimationBlinkSpeed = 20;
int matchAnimationFrameCount = 0;
int matchAnimationBlinkCount = 0;
int matchAnimationBlinkTotal = 4; // actually divide by 2, since a "blink" is really only either black or the original color, not both
PVector[] animatingMatchLocations = new PVector[(8*8*8)];
int[] animatingMatchColors = new int[(8*8*8)];
PVector[] tempLocations = new PVector[(8*8*8)];
int tempIndex = 0;
PVector[] possibleDirections = new PVector[6];
int numberRequiredForMatch = 3;

// debug
boolean debugMatchRemoval = true;
boolean debugMatchDiscovery = false;
boolean debugFallingAfterAnimation = true;


void setup()
{
  // processing
  if (drawToScreen) {
    size(600, 600, P3D);
  }

  // initializing variables and one-time stuff
  setupStaticStuff();

  // game related setup
  setupForNewGame();

  // l3d
  setupL3D();
  setupL3DForNewGame();

  // controllers
  setupControllers();
  
  // drawing to the screen
  f = createFont("Arial",16,true);
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

  drawCubeBackground();

  updateGameFromInput();

  drawSquare();

  if (drawToScreen)
  {
    drawCubeOnScreen();
    drawLevelAndScore();
  }
}


// game setup

void setupForNewGame()
{
  playersMax = 1;
  isGameOver = false;
  level = 1;
  score = 0;
  colorCount = 4; // for level 1
  // is this player currently playing?
  isPlaying[0] = true;
  // single player for now
  for (int i=1; i<4; i++) {
    isPlaying[i] = false;
  }
  // square coords, and set 'em to default
  for (int i=0; i<8; i++) {
    squareCoords[i] = new PVector(0,0,0);
  }
  // possible colors
  availableColors[0] = color(190, 0, 0); // red
  availableColors[1] = color(0, 200, 0); // green
  availableColors[2] = color(0, 0, 255); // blue
  availableColors[3] = color(200, 200, 0); // yellow
  availableColors[4] = color(190, 0, 255); // pink
  availableColors[5] = color(0, 190, 190); // cyan
  availableColors[6] = color(190, 100, 0); // orange
  availableColors[7] = color(180, 180, 180); // white
  // state
  isSquareAnimating = false;
  // matches
  isAnimatingMatches = false;
  // finally, create a new square
  newSquare();
}

void setupStaticStuff()
{
  // various match-related array stuff
  for (int i = 0; i<(8*8*8); i++)
  {
    animatingMatchLocations[i] = new PVector(-1,-1,-1);
    tempLocations[i] = new PVector(-1,-1,-1);
    animatingMatchColors[i] = 0;
  }
  // temp variables
  tempVector = new PVector(0,0,0);
  tempColor = color(0);
  // possible directions
  possibleDirections[0] = new PVector(0,1,0); // up
  possibleDirections[1] = new PVector(0,-1,0); // down
  possibleDirections[2] = new PVector(-1,0,0); // left
  possibleDirections[3] = new PVector(1,0,0); // right
  possibleDirections[4] = new PVector(0,0,-1); // forward
  possibleDirections[5] = new PVector(0,0,1); // back
  // board color
  gameboardColor = color(40,40,80);
}

void setupL3DForNewGame()
{
  cube.background(gameboardColor);
}


// dealing with square variables

void setSquareCoordsToDefault()
{
  squareCoords[0].set(3,7,3);
  squareCoords[1].set(4,7,3);
  squareCoords[2].set(3,7,4);
  squareCoords[3].set(4,7,4);
  squareCoords[4].set(3,6,3);
  squareCoords[5].set(4,6,3);
  squareCoords[6].set(3,6,4);
  squareCoords[7].set(4,6,4);
}

void newSquare()
{
  setSquareCoordsToDefault();
  // random colors
  int colorIndex = 0;
  for ( int i=0; i<8; i++)
  {
    colorIndex = int(random(colorCount));
    squareColors[i] = availableColors[colorIndex];
  }
}

// note that this method doesn't move the square down, only directions supported by user input
void moveSquareDirection(PVector direction)
{
  // check we CAN move this direction
  if (direction.x < 0 &&
      (squareCoords[0].x + direction.x) < 0)
  {
    return;
  }
  else if (direction.x > 0 &&
           (squareCoords[1].x + direction.x) > 7)
  {
    return;
  }
  if (direction.z < 0 &&
      (squareCoords[0].z + direction.z) > 7)
  {
    return;
  }
  else if (direction.z > 0 &&
           (squareCoords[2].z + direction.z) > 7)
  {
    return;
  }
  // do the actual moving
  for ( int i=0; i<8; i++ )
  {
    squareCoords[i].add(direction);
  }
}

void moveSquareDown()
{
  boolean anyMoved = false;
  // check the voxels on the bottom
  // (the last 4 in the array are the "bottom" pixels in the square)
  for (int i=4; i<8; i++)
  {
    tempVector.set(squareCoords[i].x,squareCoords[i].y - 1,squareCoords[i].z);
    if (tempVector.y >= 0 &&
        positionIsEmpty(tempVector))
    {
      // set the new location color (location below squareCoords[i])
      cube.setVoxel(tempVector,squareColors[i]);
      // set the color of the square above it
      cube.setVoxel(squareCoords[i],squareColors[(i-4)]);
      // then change the squareCoords values themselves
      squareCoords[i].set(tempVector);
      squareCoords[i-4].set(tempVector.x, tempVector.y+1, tempVector.z);
      // finally, if the vector above both of those is in the gameboard, set it as well
      if (tempVector.y + 2 < 6)
      {
        tempVector.y = tempVector.y + 2;
        setPositionToEmpty(tempVector);
      }
      anyMoved = true;
    }
  }
  // if it's a "fixed" position
  if ( ! anyMoved)
  {
    // check for matches
    checkGameboardForMatches();
    isSquareAnimating = false;
    newSquare();
  }
}

void checkGameboardForMatches()
{
  // loop through the gameboard checking neighbors
  int matchIndex = 0;
  int tempFoundMatches = 0;
  emptyPVectorArray( animatingMatchLocations );
  for (int x=0; x<8; x++)
  {
    for (int z=0; z<8; z++)
    {
      for (int y=0; y<6; y++)
      {
        tempVector.set(x,y,z);
        if (( ! positionIsEmpty(tempVector)) &&
            ( ! pVectorArrayContainsPosition( animatingMatchLocations, tempVector )) )
        {
          emptyPVectorArray( tempLocations );
          tempFoundMatches = numberOfMatchesAtPosition(tempVector);
          if (tempFoundMatches > 0)
          {
            for (int i=0; i<tempFoundMatches; i++)
            {
              if (debugMatchRemoval)
              {
                println("position of tempLocation is " + tempLocations[i]);
              }
              animatingMatchLocations[matchIndex].set(tempLocations[i]);
              animatingMatchColors[matchIndex] = cube.getVoxel(tempLocations[i]);
              matchIndex++;
            }
          }
        }
      }
    }
  }
  // if we found any set this
  if (matchIndex > 0)
  {
    startAnimatingMatches();
  }
  else
  {
    // check for game over
    checkForGameOver();
  }
}

int numberOfMatchesAtPosition(PVector position)
{
  int matchesFound = 0;
  tempColor = cube.getVoxel(position);
  tempIndex = 0;
  PVector tempPosition = new PVector(position.x, position.y, position.z);
  matchesFound = recursiveCheckForColorAtPosition(tempPosition, tempColor);
  if (matchesFound < numberRequiredForMatch)
  {
    return 0;
  }
  if (debugMatchRemoval)
  {
    println("found " + matchesFound + " matches at position " + tempPosition + ".");
  }
  return matchesFound;
}

int recursiveCheckForColorAtPosition(PVector position, color colorToCheck)
{
  // return 0 if position has been checked (in tempLocations)
  if (pVectorArrayContainsPosition(tempLocations, position))
  {
    return 0;
  }
  int returnValue = 0;
  // add position to tempLocations (checked list)
  tempLocations[tempIndex].set(position);
  tempIndex++;
  returnValue++;
  if (debugMatchDiscovery) {
    println("checking position: " + position + "in recursive for index " + tempIndex + ".");
  }
  // check all directions:
  for (int d = 0; d < possibleDirections.length; d++)
  {
    tempVector.set(position.x + possibleDirections[d].x, position.y + possibleDirections[d].y, position.z + possibleDirections[d].z);
    if (positionIsInCube(tempVector) &&
        ( ! pVectorArrayContainsPosition(tempLocations, tempVector)) &&
        colorToCheck == cube.getVoxel(tempVector))
    {
      PVector tempTemp = new PVector(tempVector.x, tempVector.y, tempVector.z);
      returnValue = returnValue + recursiveCheckForColorAtPosition(tempTemp, colorToCheck);
    }
  }
  return returnValue;
}

boolean pVectorArrayContainsPosition(PVector[] array, PVector position)
{
  for (int i=0; i<array.length; i++)
  {
    // if we've reached an element that is already "empty", we can return
    if (array[i].x < 0)
    {
      return false;
    }
    else if (array[i].x == position.x &&
             array[i].y == position.y &&
             array[i].z == position.z)
    {
      if (debugMatchDiscovery) {
        println("found position: " + position + " in pVectorArrayContainsPosition");
      }
      return true;
    }
  }
  return false;
}

void emptyPVectorArray(PVector[] array)
{
  for (int i=0; i<array.length; i++)
  {
    // if we've reached an element that is already "empty", we can return
    if (array[i].x < 0)
    {
      return;
    }
    else
    {
      array[i].set(-1,-1,-1);
    }
  }
}

void emptyAnimatingMatchLocations()
{
  for (int i=0; i<(8*8*6); i++)
  {
    animatingMatchLocations[i].set(-1,-1,-1);
  }
}

void emptyTempLocations()
{
  for (int i=0; i<(8*8*6); i++)
  {
    tempLocations[i].set(-1,-1,-1);
  }
}


// game over stuff

void drawGameOver()
{
  // TODO
}

void checkForGameOver()
{
  // only need to check the "top" pieces of the square
  for (int i=4; i<8; i++)
  {
    if (squareCoords[i].y > 5)
    {
      isGameOver = true;
    }
  }
}


// drawing random stuff

void drawSquare()
{
  boolean needsToDraw = true;
  if (isSquareAnimating)
  {
    squareAnimationFrameCount++;
    // check for motion (framecount%squareAnimationSpeed) here...
    if ( squareAnimationFrameCount > squareAnimationSpeed )
    {
      // move it down
      moveSquareDown();
      squareAnimationFrameCount = 0;
      needsToDraw = false;
    }
  }
  else if (isAnimatingMatches)
  {
    // draw all the animatingMatchLocations blinky
    matchAnimationFrameCount++;
    if ( matchAnimationFrameCount > matchAnimationBlinkSpeed )
    {
      continueAnimatingMatches();
      matchAnimationFrameCount = 0;
    }
  }
  if (needsToDraw)
  {
    // do the actual drawing
    for ( int i=0; i<8; i++ )
    {
      cube.setVoxel(squareCoords[i], squareColors[i]);
    }
  }
}

void drawCubeBackground()
{
  // draw outside the gameboard black
  for (int x=0; x<8; x++ )
  {
    for (int z=0; z<8; z++)
    {
      for (int y=6; y<8; y++)
      {
        tempVector.x = x;
        tempVector.y = y;
        tempVector.z = z;
        cube.setVoxel(tempVector,0);
      }
    }
  }
}


// match animations

void startAnimatingMatches()
{
  isAnimatingMatches = true;
  matchAnimationFrameCount = 0;
  matchAnimationBlinkCount = 0;
}

void continueAnimatingMatches()
{
  if ( matchAnimationBlinkCount % 2 == 0 )
  {
    // turn them black
    for ( int i=0; i< animatingMatchLocations.length; i++)
    {
      if (animatingMatchLocations[i].x < 0)
      {
        break;
      }
      cube.setVoxel(animatingMatchLocations[i], gameboardColor);
    }
  }
  else
  {
    // turn them their original color
    for ( int i=0; i< animatingMatchLocations.length; i++)
    {
      if (animatingMatchLocations[i].x < 0)
      {
        break;
      }
      cube.setVoxel(animatingMatchLocations[i], animatingMatchColors[i]);
    }
  }
  matchAnimationBlinkCount++;
  if (matchAnimationBlinkCount > matchAnimationBlinkTotal)
  {
    // set them all to cube bg color
    for ( int i=0; i<animatingMatchLocations.length; i++ )
    {
      if (animatingMatchLocations[i].x < 0)
      {
        break;
      }
      cube.setVoxel(animatingMatchLocations[i], gameboardColor);
    }
    if (debugFallingAfterAnimation)
    {
      println("in continueAnimatingMatches, dropping things above animatingMatchLocations[].");
    }
    // move everything empty down (immediately)
    // TODO: make these fall the same as the square
    int tempY = 0;
    int yDiff = 0;
    for (int x=0; x<8; x++)
    {
      for (int z=0; z<8; z++)
      {
        for (int y=0; y<7; y++) // don't need to check the top row
        {
          tempVector.set(x,y,z);
          if (positionIsEmpty(tempVector))
          {
            if (debugFallingAfterAnimation)
            {
              println("found empty position: " + tempVector);
            }
            for (int yAbove = y+1; y<8; y++)
            {
              tempVector.set(x,yAbove,z);
              if (( ! positionIsEmpty(tempVector)) &&
                  ( ! pVectorArrayContainsPosition(squareCoords, tempVector)))
              {
                if ( debugFallingAfterAnimation)
                {
                  println("found non-empty voxel above at " + tempVector);
                }
                yDiff = yAbove - y;
                for (int aY = y; (aY+yDiff) < 8; aY++)
                {
                  tempVector.set(x,aY,z);
                  if (aY > 5)
                  {
                    cube.setVoxel(tempVector, 0);
                  }
                  else
                  {
                    if ((aY+yDiff) > 5)
                    {
                      cube.setVoxel(tempVector,gameboardColor);
                    }
                    else
                    {
                      cube.setVoxel(tempVector,cube.getVoxel(x,(aY+yDiff),z));
                    }
                  }
                }
                break;
              }
            }
          }
        }
      }
    }
    isAnimatingMatches = false;
  }
}


// check and set various position stuff

boolean positionIsInCube(PVector position)
{
  if (position.x < 0 ||
      position.x > 7 ||
      position.y < 0 ||
      position.y > 7 ||
      position.z < 0 ||
      position.z > 7)
  {
    return false;
  }
  return true;
}

boolean positionIsInGameboard(PVector position)
{
  if (position.y > 5)
  {
    return false;
  }
  return positionIsInCube(position);
}

boolean positionIsEmpty(PVector position)
{
  return (cube.getVoxel(position) == gameboardColor);
}

void setPositionToEmpty(PVector position)
{
  cube.setVoxel(position, gameboardColor);
}

boolean positionContainsColor(PVector position, color colorToCheck)
{
  return (cube.getVoxel(position) == colorToCheck);
}


// input

void keyPressed()
{
  if (isSquareAnimating || isAnimatingMatches || isGameOver)
  {
    return;
  }
  if(useKeyboard)
  {
    if(key == CODED)
    {
      switch(keyCode)
      {
        case UP:
        {
          tempVector.set(0,0,-1);
          moveSquareDirection(tempVector);
          break;
        }
        case DOWN:
        {
          tempVector.set(0,0,1);
          moveSquareDirection(tempVector);
          break;
        }
        case LEFT:
        {
          tempVector.set(-1,0,0);
          moveSquareDirection(tempVector);
          break;
        }
        case RIGHT:
        {
          tempVector.set(1,0,0);
          moveSquareDirection(tempVector);
          break;
        }
      }
    }
    else if (key == ENTER || key == RETURN)
    {
      isSquareAnimating = true;
      squareAnimationFrameCount = 0;
      // move square down
      moveSquareDown();
    }
  }
}

void updateGameFromInput()
{
  if (isSquareAnimating || isAnimatingMatches || isGameOver || useKeyboard)
  {
    return;
  }
  // check input
  int player = 0;
  if (gpads[player].getButton("BOTTOMBUTTON").pressed())
  {
    isSquareAnimating = true;
    squareAnimationFrameCount = 0;
    // move square down
    moveSquareDown();
    return;
  }

  // left
  if (gpads[player].getButton("LEFT").pressed())
  {
    tempVector.set(-1,0,0);
    moveSquareDirection(tempVector);
  }
  // right
  if (gpads[player].getButton("RIGHT").pressed())
  {
    tempVector.set(1,0,0);
    moveSquareDirection(tempVector);
  }
  // up
  if (gpads[player].getButton("UP").pressed())
  {
    tempVector.set(0,-1,0);
    moveSquareDirection(tempVector);
  }
  // down
  if (gpads[player].getButton("DOWN").pressed())
  {
    tempVector.set(0,1,0);
    moveSquareDirection(tempVector);
  }
}

void setupControllers()
{
  if (useKeyboard)
  {
    return;
  }
  control = ControlIO.getInstance(this);
  gpads = new ControlDevice[4];
  if (isPlaying[0])
  {
    gpads[0] = control.getMatchedDevice("controller");
    if (gpads[0] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  if (isPlaying[1])
  {
    gpads[1] = control.getMatchedDevice("controller2");
    if (gpads[1] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  if (isPlaying[2])
  {
    gpads[2] = control.getMatchedDevice("controller3");
    if (gpads[2] == null)
    {
      println("No suitable device configured");
      System.exit(-1); // End the program NOW!
    }
  }
  if (isPlaying[3])
  {
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
// note, disabling multicastStreaming gives MUCH better performance
//  cube = new L3D(this);
//  cube.enableMulticastStreaming();  //stream the data over UDP to any L3D cubes that are listening on the local network

  // ...so instead, let's stream directly to the L3D here (note, requires internet connection for setup)
  cube = new L3D(this, accessToken);
  cube.streamToCore(coreName);

  if (drawWithCube)
  {
    cube.enableDrawing();  //draw the virtual cube
    cube.enablePoseCube();
  }
}

void drawLevelAndScore()
{
  textFont(f,16);
  fill(color(255,255,255)); 
  textSize(22);
  text("Level: " + level,-200,-200);
  text("Score: " + score,140,-200);
}

void drawCubeOnScreen()
{
  // draw the cube
  float scale = 20;
  float doublescale = scale * 2;
  float side = 8;
  int tempColor;

  this.translate(this.width/2, this.height/2);
  this.rotateY((float)cube.xAngle);
  this.rotateX((float)-cube.yAngle);

  // draw the white "frame"
  this.stroke(255, 10);
  for (float x = 0; x < side-1; x++)
  {
    for (float y = 0; y < side-1; y++)
    {
      for (float z = 0; z < side-1; z++)
      {
        this.pushMatrix();
        this.translate(((x-(side-1)/2) * doublescale) + scale, ((side-1 - y-(side-1)/2) * doublescale) - scale, (((z-(side-1)/2))* doublescale) + scale);
        this.noFill();
        this.box(doublescale, doublescale, doublescale);
        this.popMatrix();
      }
    }
  }

  for (float x = 0; x < side; x++)
  {
    for (float y = 0; y < side; y++)
    {
      for (float z = 0; z < side; z++)
      {
        tempColor = cube.getVoxel(int(x),int(y),int(z));
        if (tempColor != 0) {
          this.pushMatrix();
          this.translate((x-(side-1)/2) * doublescale, (side-1 - y-(side-1)/2) * doublescale, ((z-(side-1)/2))* doublescale);
          this.fill(tempColor);
          this.box(scale, scale, scale);
          this.popMatrix();
        }
      }
    }
  }
}

