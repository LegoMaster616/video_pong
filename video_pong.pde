import processing.video.*;
import gab.opencv.*; 
import java.awt.Rectangle;

//Parameters:
color leftGloveColor = color(196,62,44);
color rightGloveColor = color(64,127,76);
int leftGloveTolerance = 40;
int rightGloveTolerance = 30;

int paddleDistanceFromSide = 40;
int paddleWidth = 25;
int paddleHeight = 200;
int ballRadius = 20;

int cvScale = 8; //Should be power of two

int minArea = 2500;

int maxSpeed = 1000;

//Variables
float leftPaddleHeight = 0.5;
float rightPaddleHeight = 0.5;

boolean debug = false;
boolean printCamera = false;
boolean calibrateRight = false;
boolean calibrateLeft = false;

float ballX = width/2;
float ballY = height/2;
int ballVelX = 200;
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

void setup() {
  size(1280, 720, P2D);
   
  if(printCamera)
  {
    printArray(Capture.list());
  }
   
  webcam = new Capture(this, "name=Logitech HD Webcam C270,size=1280x720,fps=30");
  webcam.start();
  

  
  while(!webcam.available()) {
    delay(100);
    println("waiting for camera");
  }
  

  
  cv = new OpenCV(this, width/cvScale, height/cvScale);
  lastTime = millis();
}

void draw() {
  if(webcam.available()) {
    delta = (int)(millis() - lastTime);
    lastTime = millis();



    webcam.read();

    webcam.updatePixels();
    
    pushMatrix();
      scale(-1, 1);
      image(webcam, -webcam.width, 0);
    popMatrix();
    //image(webcam, 0, 0);
    
    stroke(255);
    strokeWeight(10);
    line(width/2, 0, width/2, height);
    
    //Get heights
    Contour blob = findBiggestBlobColor(leftGloveColor, leftGloveTolerance);
    if(blob != null && blob.area() > minArea)
    {
      Rectangle r = blob.getBoundingBox();
      leftPaddleHeight = (r.y+r.height/2)*cvScale/(float)(webcam.height);
      
      if(debug)
      {
        noFill();
        stroke(leftGloveColor);
        strokeWeight(3);
        pushMatrix();
          scale(-1, 1);
          rect(r.x*cvScale-webcam.width, r.y*cvScale, r.width*cvScale, r.height*cvScale);
        popMatrix();
      }
    }
    
    blob = findBiggestBlobColor(rightGloveColor, rightGloveTolerance);
    if(blob != null && blob.area() > minArea)
    {
      Rectangle r = blob.getBoundingBox();
      rightPaddleHeight = (r.y+r.height/2)*cvScale/(float)(webcam.height);
      
      if(debug)
      {
        noFill();
        stroke(rightGloveColor);
        strokeWeight(3);
        pushMatrix();
          scale(-1, 1);
          rect(r.x*cvScale-webcam.width, r.y*cvScale, r.width*cvScale, r.height*cvScale);
        popMatrix();
      }
    }
    
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
    
    
    
    if(debug)
    {
      fill(0);
      rect(20, 20, 50, 40);
      fill(255);
      textSize(24);
      text("fps: "+nf(frameRate, 0,2), 20, 20);
      if(calibrateLeft || calibrateRight){
        fill(webcam.pixels[webcam.pixels.length/2-width/2]);
        stroke(0);
        strokeWeight(2);
        ellipse(1280/2, 720/2, 30, 30);
        
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
      if(calibrateRight) text("calibrate right", 20, 40);
    }
    
    

        
    fill(color(255, 255, 255));
    stroke(0);
    strokeWeight(2);
    ellipse(ballX, ballY, ballRadius*2, ballRadius*2);
    
    fill(255);
    textAlign(RIGHT);
    textSize(40);
    text(leftScore, width/2-50, 60);
    textAlign(LEFT);
    textSize(40);
    text(rightScore, width/2+50, 60);
    
    
  }
    ballX += ballVelX * delta/1000.0;
    ballY += ballVelY * delta/1000.0;
    
    if(ballX + ballRadius > width - paddleDistanceFromSide - paddleWidth/2 && ballY + ballRadius > rightPaddleHeight*height - paddleHeight/2 && ballY - ballRadius < rightPaddleHeight*height + paddleHeight/2){
      ballX = width - paddleDistanceFromSide - paddleWidth/2 - ballRadius;
      if(ballVelX < maxSpeed)
        ballVelX += 30;
      ballVelX *= -1;
    }
    if(ballX - ballRadius < paddleDistanceFromSide + paddleWidth/2 && ballY + ballRadius > leftPaddleHeight*height - paddleHeight/2 && ballY - ballRadius < leftPaddleHeight*height + paddleHeight/2){
      ballX = paddleDistanceFromSide + ballRadius + paddleWidth/2;
      if(-ballVelX < maxSpeed)
        ballVelX -= 30;
      println(ballVelX);
      ballVelX *= -1;
    }
    if(ballX < 0 || ballX > width)
    {
      ballVelY = (int)random(200) + 200;
      ballVelX = 300;
      if(ballX < 0)
      {
        rightScore++;
      }
      else
      {
        leftScore++;
        ballVelX *= -1;
      }
      ballX = 640;
      ballY = 360;
    }
    if(ballY + ballRadius > height){
      ballY = height - ballRadius;
      ballVelY *= -1;
    }
    if(ballY - ballRadius < 0){
      ballY = ballRadius;
      ballVelY *= -1;
    }
}

void keyPressed() {
  if(key == 'd') debug = !debug;
  if(key == ','){
    if(calibrateLeft)
    {
      println("new left color: "+(leftGloveColor >> 16 & 0xFF)+","+(leftGloveColor >> 8 & 0xFF)+","+(leftGloveColor & 0xFF));
    }
    calibrateLeft = !calibrateLeft;
    calibrateRight = false;
  }
  if(key == '.'){
    if(calibrateRight){
      println("new right color: "+(rightGloveColor >> 16 & 0xFF)+","+(rightGloveColor >> 8 & 0xFF)+","+(rightGloveColor & 0xFF));
    }
    calibrateRight = !calibrateRight;
    calibrateLeft = false;
  }  
  
  if(key == 'r'){
    ballX = 640;
    ballY = 360;
  }
}

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
  
Contour findBiggestBlobColor(color gloveColor, int gloveTolerance)
{
  webcamCopy = webcam.get();
  webcamCopy.resize(webcam.width/cvScale, 0);
  thresholdColor(gloveColor, gloveTolerance, webcamCopy);
  
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

//void find2BiggestBlobsColor(color gloveColor, int gloveTolerance)
//{
//  webcamCopy = webcam.get();
//  webcamCopy.resize(webcam.width/cvScale, 0);
//  thresholdColor(gloveColor, gloveTolerance, webcamCopy);
  
//  cv.loadImage(webcamCopy);
//  cv.dilate();
//  cv.erode();

//  ArrayList<Contour> blobs = cv.findContours();
//  if(!blobs.isEmpty())
//  {
//    Contour biggest = blobs.get(0);
//    for (Contour blob : blobs) {
//      if(blob.area() > biggest.area())
//      {
//        biggest = blob;
//      }
//    }
    
//    return biggest;
//  }
//  return null;
//}


  