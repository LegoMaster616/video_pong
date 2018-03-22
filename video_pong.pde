import processing.video.*;
import gab.opencv.*; 
import java.awt.Rectangle;

//Parameters:
color leftGloveColor = color(196,62,44); //Initial colors
color rightGloveColor = color(64,127,76);
int leftGloveTolerance = 40; //Color tolerance (each color channel can differ by this amount)
int rightGloveTolerance = 30;

int paddleDistanceFromSide = 20; //Pixels from edge of screen
int paddleWidth = 25;
int paddleHeight = 200;
int ballRadius = 20;

int cvScale = 8; //Should be power of two, scales the openCV buffer (high resolution not needed)

int minArea = 250; //Minimum blob area that registers as a true blob detection

int maxSpeed = 1000; //Max speed of the ball

//Variables
float leftPaddleHeight = 0.5; //Initial paddle positions
float rightPaddleHeight = 0.5;

boolean debug = false;
boolean printCameraList = false;
boolean calibrateRight = false; //If true, sets the paddle blob detection color
boolean calibrateLeft = false;

float ballX = width/2; //Initial ball position
float ballY = height/2;
int ballVelX = 200; //Initial ball velocity
int ballVelY = 300;

int rightScore = 0;
int leftScore = 0;

int delta;
long lastTime;

//Objects:
Capture webcam;
PImage webcamCopy;
OpenCV cv;
ArrayList<Contour> blobs;
Contour blob;
Rectangle r;

void setup() {
  size(1280, 720, P3D);
   
  if(printCameraList)
  {
    printArray(Capture.list());
  }
   
  webcam = new Capture(this, "name=Logitech HD Webcam C270,size=1280x720,fps=30");
  webcam.start();
  
  print("Waiting for camera");
  while(!webcam.available()) {
    delay(300);
    print(".");
  }
  println();

  cv = new OpenCV(this, width/cvScale, height/cvScale); //scale down because a high resolution isn't needed for blobs
  lastTime = millis();
  resetBall(false);
  frameRate(60);
}

void draw() {
  delta = (int)(millis() - lastTime); //calculates time it takes per loop
  lastTime = millis();
  
  if(webcam.available())
  {
    //======Get webcam feed===============
    webcam.read();
    webcam.updatePixels();    
    
    //======Get paddle Y coordinates======
    //Left
    blob = findBiggestBlobColor(leftGloveColor, leftGloveTolerance);
    if(blob != null && blob.area() > minArea)
    {
      r = blob.getBoundingBox();
      leftPaddleHeight = (r.y+r.height/2)*cvScale/(float)(webcam.height); //Set position of the left paddle to the center of the bounding box
      
      if(debug)
      {
        debugDrawBoundingBox(r, leftGloveColor);//Draw box around the left paddle
      }
    }
    //Right
    blob = findBiggestBlobColor(rightGloveColor, rightGloveTolerance);
    if(blob != null && blob.area() > minArea)
    {
      r = blob.getBoundingBox();
      rightPaddleHeight = (r.y+r.height/2)*cvScale/(float)(webcam.height); //Set position of the right paddle to the center of the bounding box
      
      if(debug)
      {
        debugDrawBoundingBox(r, rightGloveColor);//Draw box around the right paddle
      }
    }
  } //End webcam.available() if statement
  //Faster if drawing is done outside of webcam.available(), because we don't have to wait for the next camera frame
  //This makes the ball movement much smoother
  
  //======Draw objects==================  
  //Draw webcam feed
  pushMatrix();
    scale(-1, 1);
    image(webcam, -webcam.width, 0);
  popMatrix();
  
  //Draw center line
  stroke(255);
    strokeWeight(10);
    line(width/2, 0, width/2, height);
  
  //Draw paddles
  rectMode(CENTER);
    fill(leftGloveColor);
    stroke(0);
    strokeWeight(2);
    rect(paddleDistanceFromSide, leftPaddleHeight*webcam.height, paddleWidth, paddleHeight);
    
    fill(rightGloveColor);
    stroke(0);
    strokeWeight(2);
    rect(width - paddleDistanceFromSide, rightPaddleHeight*webcam.height, paddleWidth, paddleHeight);
  rectMode(CORNER);
 
  //Draw ball
  fill(255);
    stroke(0);
    strokeWeight(2);
    ellipse(ballX, ballY, ballRadius*2, ballRadius*2);
  
  //Draw scores
  fill(255);
    textAlign(RIGHT);
    textSize(40);
    text(leftScore, width/2-50, 60);
    textAlign(LEFT);
    textSize(40);
    text(rightScore, width/2+50, 60);
  
  //Draw debug info
  if(debug)
  {
    debugWriteText();
  }

  //======Physics=======================  
  //Integrate ball velocity
  ballX += ballVelX * delta/1000.0;
  ballY += ballVelY * delta/1000.0;
  
  //Collision detection
  //Left paddle collision
  if(ballX + ballRadius > width - paddleDistanceFromSide - paddleWidth/2 && ballY + ballRadius > rightPaddleHeight*height - paddleHeight/2 && ballY - ballRadius < rightPaddleHeight*height + paddleHeight/2){
    ballX = width - paddleDistanceFromSide - paddleWidth/2 - ballRadius;
    if(ballVelX < maxSpeed)
      ballVelX += 60;
    ballVelX *= -1;
  }
  //Right paddle collision
  if(ballX - ballRadius < paddleDistanceFromSide + paddleWidth/2 && ballY + ballRadius > leftPaddleHeight*height - paddleHeight/2 && ballY - ballRadius < leftPaddleHeight*height + paddleHeight/2){
    ballX = paddleDistanceFromSide + ballRadius + paddleWidth/2;
    if(-ballVelX < maxSpeed)
      ballVelX -= 60;
    ballVelX *= -1;
  }
  //Bottom wall collision
  if(ballY + ballRadius > height){
    ballY = height - ballRadius;
    ballVelY *= -1;
  }
  //Top wall collision
  if(ballY - ballRadius < 0){
    ballY = ballRadius;
    ballVelY *= -1;
  }
  //Out of bounds (left side)
  if(ballX < 0)
  {
    rightScore++;
    resetBall(true);
  }
  //Out of bounds (right side)
  if(ballX > width)
  {
    leftScore++;
    resetBall(true);
  }
}

void keyPressed() {
  //Debug mode
  if(key == 'd'){
    if(debug){
      calibrateLeft = false;
      calibrateRight = false;
    }
    debug = !debug;
  }
  //Callibrate left paddle color
  if(debug && key == ','){
    if(calibrateLeft)
    {
      println("new left color: "+(leftGloveColor >> 16 & 0xFF)+","+(leftGloveColor >> 8 & 0xFF)+","+(leftGloveColor & 0xFF));
    }
    calibrateLeft = !calibrateLeft;
    calibrateRight = false;
  }
  //Callibrate right paddle color
  if(debug && key == '.'){
    if(calibrateRight){
      println("new right color: "+(rightGloveColor >> 16 & 0xFF)+","+(rightGloveColor >> 8 & 0xFF)+","+(rightGloveColor & 0xFF));
    }
    calibrateRight = !calibrateRight;
    calibrateLeft = false;
  }  
  
  //Reset ball and score
  if(key == 'r'){
    resetBall(false);
  }
}

//Overwrites the PImage as a binary image as to whether or not each pixel is within a color tolerance of the target color
void thresholdColor(color target, int tolerance, PImage img)
{
  int matchR = target >> 16 & 0xFF;
  int matchG = target >>  8 & 0xFF;
  int matchB = target >>  0 & 0xFF;
  
  img.loadPixels();
  
  for(int y = 0; y < img.height; y++) {
    for(int x = 0; x < img.width; x++) {
      color current = img.pixels[y*img.width+x];
      int r = current >> 16 & 0xFF;
      int g = current >>  8 & 0xFF;
      int b = current >>  0 & 0xFF;
      
      if(r >= matchR-tolerance && r <= matchR+tolerance &&
        g >= matchG-tolerance && g <= matchG+tolerance &&
        b >= matchB-tolerance && b <= matchB+tolerance)
        img.pixels[y*img.width+x] = color(255, 255, 255);
      else
        img.pixels[y*img.width+x] = color(0, 0, 0); 
    }
  }
  
  img.updatePixels();
}

//Using OpenCV, find the biggest blob of color target in webcamCopy (scaled down by cvScale)
Contour findBiggestBlobColor(color target, int tolerance)
{
  webcamCopy = webcam.get();
  webcamCopy.resize(webcam.width/cvScale, 0);
  thresholdColor(target, tolerance, webcamCopy);
  
  cv.loadImage(webcamCopy);
  cv.dilate();
  cv.erode();

  blobs = cv.findContours();
  if(!blobs.isEmpty())
  {
    Contour biggest = blobs.get(0);
    for (Contour blob : blobs) {
      if(blob.area() > biggest.area())
      {
        biggest = blob;
      }
    }
    return biggest;
  }
  return null;
}

//Reset ball position and velocity. Pass true if the game is still running (do not reset score and remember past direction)
void resetBall(boolean gameNotOver){
  int lastVelX = ballVelX;
  ballX = 640;
  ballY = 360;
  if(!gameNotOver){
    leftScore = 0;
    rightScore = 0;
  }
  ballVelX = (int)random(200) + 200;
  ballVelY = (int)random(200) + 200;
  if(gameNotOver){
    if(lastVelX > 0)
      ballVelX *= -1;
  }
  else if(random(10) > 5)
    ballVelX *= -1;
  if(random(10) > 5)
    ballVelY *= -1;  
}

//Draw bounding box around a Contour with color c
void debugDrawBoundingBox(Rectangle r, color c)
{
  noFill();
  stroke(c);
  strokeWeight(3);
  pushMatrix();
    scale(-1, 1);
    rect(r.x*cvScale-webcam.width, r.y*cvScale, r.width*cvScale, r.height*cvScale);
  popMatrix();
}

//Draw FPS and calibration mode
void debugWriteText()
{
  fill(0);
  rect(20, 0, 160, 40);
  fill(255);
  textSize(24);
  text("fps: "+nf(frameRate, 0,2), 20, 20);
  if(calibrateLeft || calibrateRight){
    fill(webcam.pixels[webcam.pixels.length/2-width/2]);
    stroke(0);
    strokeWeight(2);
    ellipse(width/2, height/2, 30, 30);
    
    if(calibrateLeft) {
      leftGloveColor = webcam.pixels[webcam.pixels.length/2-width/2];
      fill(255);
      text("calibrate left", 20, 40);
    }
    else {
      rightGloveColor = webcam.pixels[webcam.pixels.length/2-width/2];
      fill(255);
      text("calibrate right", 20, 40);
    }
  }
}