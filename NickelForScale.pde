import hypermedia.video.*;
import java.awt.*;
import java.util.*;
import processing.video.*;

PApplet app;

///// UI sizes
int PADDING = 10;
int INFO_H = 300;
int TEXT_H = 20;

///// UI STATE
boolean showOrig = true;
boolean showBlobs = true;
boolean isDrawing = false;
boolean isCapturing = true;
// line drawing
Point ls = new Point();
Point le = new Point();
ArrayList<Line> lines = new ArrayList<Line>();

OpenCV opencv;
PImage img;
PImage orig_img;
int w = 640;
int h = 480;

Capture cam;

PrintWriter output;

PFont font;

float mm_per_px = 0;
float nickel_diam_mm = 21.21;
float nickel_diam_px = 0;

Blob[] blobs;
Blob hand;
Blob nickel;

UIController controller;
void setup() {
  app = this;
  size( w+PADDING*2, h+INFO_H+PADDING*3 );
  font = loadFont( "SansSerif-18.vlw" );
  textFont( font, 18 );
  controller = new CaptureController();
  controller.setup();
}

void draw() {
  controller.draw();
}

///// INTERACTIVITY!!!

void keyPressed() {
  controller.keyPressed();
}

void mousePressed() {
  controller.mousePressed();
}

void mouseDragged() {
  controller.mouseDragged();
}

void mouseReleased(){
  controller.mouseReleased();
}

///// CLEAN UP
public void stop() {
    if(opencv != null) { opencv.stop(); }
    super.stop();
}
