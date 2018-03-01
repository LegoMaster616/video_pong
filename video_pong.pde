import processing.video.*;
import gab.opencv.*; 
import java.awt.Rectangle;

//Parameters:
color leftGloveColor = color(171, 103, 54);
color rightGloveColor = color(78, 90, 127);
int leftGloveTolerance = 40;
int rightGloveTolerance = 40;

int cvScale = 8; //Should be power of two

int minArea = 4096/(cvScale*cvScale);

//Variables
float leftPaddleHeight = 0.5;
float rightPaddleHeight = 0.5;

boolean debug = true;

//Objects:
Capture webcam;
PImage webcamCopy;
OpenCV cv;

void setup() {
  size(1280, 1080); //normally 1280x720
  
  webcam = new Capture(this, "name=Logitech HD Webcam C270,size=1280x720,fps=30");
  webcam.start();
  
  while(!webcam.available()) {
    delay(100);
  }
  
  webcam.read();
  cv = new OpenCV(this, webcam.width/cvScale, webcam.height/cvScale);
}

void draw() {
  if(webcam.available()) {
    webcam.read();
    
    pushMatrix();
      scale(-1, 1);
      image(webcam, -webcam.width, 0);
    popMatrix();
    //image(webcam, 0, 0);
    
    
    
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
    //Draw left threshold output
    if(debug) {
      pushMatrix();
        scale(-cvScale/2, cvScale/2);
        image(webcamCopy, -webcam.width/cvScale, webcam.height*2/cvScale);
      popMatrix();
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
    //Draw right threshold output
    if(debug) {
      pushMatrix();
        scale(-cvScale/2, cvScale/2);
        image(webcamCopy, -webcam.width*2/cvScale, webcam.height*2/cvScale);
      popMatrix();
    }
    
    //Draw paddles
    fill(leftGloveColor);
    stroke(0);
    strokeWeight(2);
    rect(70, leftPaddleHeight*webcam.height-100, 40, 200);
    
    fill(rightGloveColor);
    stroke(0);
    strokeWeight(2);
    rect(1170, rightPaddleHeight*webcam.height-100, 40, 200);
    
    
    
    if(debug || !debug)
    {
      stroke(0, 0, 0);
      strokeWeight(1);
      fill(255, 255, 255);
      textSize(24);
      text("fps: "+nf(frameRate, 0,2), 20, 20);
    }
  }
}

void keyPressed() {
  if(key == 'd') debug = !debug;
  
  println(key);
  
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

  ArrayList<Contour> blobs = cv.findContours();
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


  