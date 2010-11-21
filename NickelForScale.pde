import hypermedia.video.*;
import java.awt.*;
import java.util.*;
import processing.video.*;
import controlP5.*;
import processing.opengl.*;

PApplet app;
ControlP5 controlP5;

///// UI sizes
int MODEL_SIZE=420;
int PADDING = 10;
int TEXT_H = 20;
int INFO_H = 200;

///// UI STATE
int deg;
String modelName = null;
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
HashMap<String,UIController> controllers = new HashMap<String,UIController>();


void setup() {
  app = this;
  font = createFont( "SansSerif", 20 );
  textFont( font, 20 );
  size( w+PADDING*2, h+INFO_H+PADDING*3, P3D );
  frame.setResizable(true);
  controlP5 = new ControlP5(this);
  controllers.put("object_chooser", new ObjectChooserController());
  controllers.put("capture", new CaptureController());
  controllers.put("render", new RenderController());
  controller = controllers.get("object_chooser");
  controller.setup();
  controller.takeControl();
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


public void controlEvent(ControlEvent theEvent) {
  controller.controlEvent(theEvent);
}

public void changeController(UIController ctrlr){
  if(!ctrlr.isInitialized()){ ctrlr.setup(); }
  controller = ctrlr;
  controller.takeControl();
}

///// CLEAN UP
public void stop() {
    if(opencv != null) { opencv.stop(); }
    super.stop();
}
