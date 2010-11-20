import hypermedia.video.*;
import java.awt.*;
import java.util.*;
import processing.video.*;

///// UI sizes
int PADDING = 10;
int INFO_H = 300;
int TEXT_H = 20;

///// UI STATE
boolean showOrig = true;
boolean showBlobs = true;
boolean isDrawing = false;
// line drawing
Point ls = new Point();
Point le = new Point();
ArrayList<Line> lines = new ArrayList<Line>();

OpenCV opencv;
PImage img;
PImage orig_img;
int w = 640;
int h = 480;

PFont font;

float mm_per_px = 0;
float nickel_diam_mm = 21.21;
float nickel_diam_px = 0;

Blob[] blobs;
Blob hand;
Blob nickel;

void setupOpenCV(String imgFilename) {
   orig_img = loadImage(imgFilename);
   w = orig_img.width;
   h = orig_img.height;
   img = new PImage(w,h);
   img.copy(orig_img,0,0,w,h,0,0,w,h);
   opencv = new OpenCV( this );
   opencv.allocate(w,h);
}

void setup() {

    setupOpenCV("amy-tests/1nickel-hand-C-naturalLight-1.jpg");

    size( w+PADDING*2, h+INFO_H+PADDING*3 );
    font = loadFont( "SansSerif-18.vlw" );
    textFont( font, 18 );
}

void draw() {

    findBlobs();
    getPixelsPerMM();
    drawBlob(hand);

    background(0);

    if(showOrig) { image( orig_img, PADDING, PADDING ); }
    if(showBlobs) { drawBlobs(); }
    //image( opencv.image(OpenCV.GRAY), PADDING, PADDING ); // Grayscale image

    drawInfo();
    
    // Draw Lines
    pushMatrix();
    translate(PADDING,PADDING);
    for(Line l : lines){
      stroke(230, 230, 250);
      strokeWeight(2);
      drawLine(l);
      strokeWeight(1);
    }
    popMatrix();
    
    // Draw current line, if any
    if(isDrawing){
      stroke(255,255,255);
      strokeWeight(2);
      line(ls.x,ls.y,le.x,le.y);
      strokeWeight(1);
    }
}

void drawLine(Line l){
  line(l.p1.x, l.p1.y, l.p2.x, l.p2.y);
  Point r = (l.p1.x > l.p2.x) ? l.p1 : l.p2;
  noStroke();
  String lbl = String.format("%.02fmm", l.length() * mm_per_px);
  fill(0,0,0);
  text(lbl, r.x+1, r.y + TEXT_H+1);
  fill(255,255,255);
  text(lbl, r.x, r.y + TEXT_H);
}

void drawInfo(){
  pushMatrix();
  translate(PADDING, PADDING*2+h);
  fill(255,255,255);
  text("MM/PX: " + mm_per_px, 0, TEXT_H);
  if(lines.size() > 0){
    Line l = lines.get(lines.size()-1);
    text("Last Length: " + (l.length() * mm_per_px), 0, TEXT_H*2.2);
  }
  popMatrix(); 
}

void drawBlobs(){
    noFill();
    pushMatrix();
    translate(PADDING,PADDING);

    if(hand != null){
      for( int i=0; i<blobs.length; i++ ){
        drawBlob(blobs[i]);
      }
    }

    popMatrix();  
}

/**
 * Two-pass blob finding to find hand and nickel blobs.
 *  1. Threshold and blob find to find "interesting, big" blob which is the hand.
 *  2. Use hand bounding box to set ROI and re-threshold to find hand, w/ nickel on top as hole.
 * Sets globals:
 *   - blobs
 *   - hand
 *   - nickel
 */
void findBlobs(){
  opencv.copy(img);
  opencv.threshold(0, 255, OpenCV.THRESH_TOZERO_INV | OpenCV.THRESH_OTSU);
  blobs = opencv.blobs( 100, w*h/3, 20, true );
  hand = findHandBlob(blobs);
  if(hand != null){
      // do an ROI thing
      opencv.copy(img);
      opencv.ROI( hand.rectangle.x, hand.rectangle.y, hand.rectangle.width, hand.rectangle.height );
      opencv.threshold(0, 255, OpenCV.THRESH_TOZERO_INV | OpenCV.THRESH_OTSU);
      blobs = opencv.blobs( 100, w*h/3, 20, true );
      hand = findHandBlob(blobs);
      nickel = findNickelBlob(blobs);
  }
  opencv.ROI( null );
}

// Looks for "interesting" blob w/ area:perimeter ratio > 20
// ... I don't know why this finds a hand.
Blob findHandBlob(Blob[] blobs){
    for( int i=0; i<blobs.length; i++ ) {
        float area = blobs[i].area;
        float perimeter = blobs[i].length;
        float a_c_ratio = area / perimeter;
        if(a_c_ratio > 20.0) { return blobs[i]; }
    }
    return null;
}

// Find the first blob that is inside of another blob.
// Pretty much only works when there is a hand with a nickel on it and nothing else.
//  Failure modes: painted fingernails, jewelry, ...
Blob findNickelBlob(Blob[] blobs){
  for(  int i=0; i < blobs.length; i++ ){
    if(blobs[i].isHole == true){
      return blobs[i];
    }
  }
  return null;
}

/**
 * Using the nickel blob, find the diameter of it in pixels and use that to set
 * mm_per_px for the image.
 *
 * Uses larger of blob bounding box width and height.
 *
 * Uses globals
 *   - Blob nickel
 *   - float nickel_diam_mm
 * Sets globals
 *   - float mm_per_px = 0;
 *   - float nickel_diam_px = 0;
 */
void getPixelsPerMM(){
  Rectangle bounds = nickel.rectangle;
  nickel_diam_px = (float) ((bounds.width > bounds.height) ? bounds.width : bounds.height);
  mm_per_px = nickel_diam_mm / nickel_diam_px;
}

Line trimLineToHand(Line l){
  if((l == null) || (hand == null)){ return l; }
  
  Point[] hpts = hand.points;
  if(hpts.length < 2){ return l; }

  Point m1 = l.p1;
  double m1d = 10000.0;
  Point m2 = l.p2;
  double m2d = 10000.0;
  Point p1 = hpts[0];
  Point p2 = hpts[1];
  for(int i = 1; i < hpts.length; i++){
    p2 = hpts[i];
    Point ix = findIntersection(p1,p2,l.p1,l.p2);
    if(ix != null){
      double ix1d = l.p1.distance(ix);
      double ix2d = l.p2.distance(ix);
      if(ix1d < m1d) {
        m1 = ix; m1d = ix1d;
        println("Moving towards P1: " + p_to_s(ix) + " " + l_to_s(l));
      }
      if(ix2d < m2d) {
        m2 = ix; m2d = ix2d; 
        println("Moving towards P2: " + p_to_s(ix) + " " + l_to_s(l));
      }
    }
    p1 = hpts[i];
  }
  return new Line(m1,m2);
}

String p_to_s(Point p){
  return "(" + p.x +"," + p.y + ")";
}

String l_to_s(Line l){
  return "[" + p_to_s(l.p1) + "," + p_to_s(l.p2) + "]";
}

// calculates intersection and checks for parallel lines.  
// also checks that the intersection point is actually on  
// the line segment p1-p2  
Point findIntersection(Point p1, Point p2, Point p3, Point p4) {
  float xD1,yD1,xD2,yD2,xD3,yD3;  
  float dot,deg,len1,len2;  
  float segmentLen1,segmentLen2;  
  float ua,ub,div;  
  
  // calculate differences  
  xD1=p2.x-p1.x;  
  xD2=p4.x-p3.x;  
  yD1=p2.y-p1.y;  
  yD2=p4.y-p3.y;  
  xD3=p1.x-p3.x;  
  yD3=p1.y-p3.y;    
  
  // calculate the lengths of the two lines  
  len1=sqrt(xD1*xD1+yD1*yD1);  
  len2=sqrt(xD2*xD2+yD2*yD2);  
  
  // calculate angle between the two lines.  
  dot=(xD1*xD2+yD1*yD2); // dot product  
  deg=dot/(len1*len2);  
  
  // if abs(angle)==1 then the lines are parallell,  
  // so no intersection is possible  
  if(abs(deg)==1) return null;  
  
  // find intersection Pt between two lines  
  Point pt=new Point(0,0);  
  div=yD2*xD1-xD2*yD1;  
  ua=(xD2*yD3-yD2*xD3)/div;  
  ub=(xD1*yD3-yD1*xD3)/div;  
  pt.x=p1.x+(int)(ua*xD1);
  pt.y=p1.y+(int)(ua*yD1);
  
  // calculate the combined length of the two segments  
  // between Pt-p1 and Pt-p2  
  xD1=pt.x-p1.x;  
  xD2=pt.x-p2.x;  
  yD1=pt.y-p1.y;  
  yD2=pt.y-p2.y;  
  segmentLen1=sqrt(xD1*xD1+yD1*yD1)+sqrt(xD2*xD2+yD2*yD2);  
  
  // calculate the combined length of the two segments  
  // between Pt-p3 and Pt-p4  
  xD1=pt.x-p3.x;  
  xD2=pt.x-p4.x;  
  yD1=pt.y-p3.y;  
  yD2=pt.y-p4.y;  
  segmentLen2=sqrt(xD1*xD1+yD1*yD1)+sqrt(xD2*xD2+yD2*yD2);  
  
  // if the lengths of both sets of segments are the same as  
  // the lenghts of the two lines the point is actually  
  // on the line segment.  
  
  // if the point isn't on the line, return null  
  if(abs(len1-segmentLen1)>0.01 || abs(len2-segmentLen2)>0.01)  
    return null;  
  
  // if we got a NaN, return null
  if(Float.isNaN(pt.x) || Float.isNaN(pt.y))
    return null;
    
  // return the valid intersection  
  return pt;  
}  

void drawBlob(Blob blob){
        Rectangle bounding_rect	= blob.rectangle;
        float area = blob.area;
        float perimeter = blob.length;
        Point centroid = blob.centroid;
        Point[] points = blob.points;
        float a_c_ratio = area / perimeter;

        // rectangle
        noFill();
        stroke( blob.isHole ? 128 : 64 );
        rect( bounding_rect.x, bounding_rect.y, bounding_rect.width, bounding_rect.height );

        // centroid
        stroke(0,0,255);
        line( centroid.x-5, centroid.y, centroid.x+5, centroid.y );
        line( centroid.x, centroid.y-5, centroid.x, centroid.y+5 );
        
        //noStroke();
        //fill(0,0,255);
        //text( area,centroid.x+5, centroid.y+5 );

        fill(255,0,255,64);
        if(blob.isHole){
          fill(255,0,0,64);
        }
        stroke(255,255,0);
        if ( points.length>0 ) {
            beginShape();
            for( int j=0; j<points.length; j++ ) {
                vertex( points[j].x, points[j].y );
            }
            endShape(CLOSE);
        }

        /*
        noStroke();
        fill(255,0,255);
        text( perimeter, centroid.x+5, centroid.y+5+TEXT_H );

        // area : perimeter ratio
        fill(0,255,0);
        text( area / perimeter, centroid.x+5, centroid.y+5+(TEXT_H*2) );
        */
}

///// INTERACTIVITY!!!

void keyPressed() {
  switch(key){
    case 'o':
      showOrig = showOrig ? false : true;
      break;
    case 'b':
      showBlobs = showBlobs ? false : true;
      break;
  }
}

void mousePressed() {
  isDrawing = true;
  ls.x = mouseX;
  ls.y = mouseY;
  le.x = ls.x;
  le.y = ls.y;
}

void mouseDragged() {
  le.x = mouseX;
  le.y = mouseY;
}

void mouseReleased(){
  if(isDrawing){
    isDrawing = false;
    ls.x -= PADDING;
    ls.y -= PADDING;
    le.x -= PADDING;
    le.y -= PADDING;
    Line l = new Line(ls,le);
    Line trimmed = trimLineToHand(l);
    if( (trimmed != null) && !(trimmed.equals(l)) && (trimmed.length() > 0) ){
      lines.add(trimmed);
    }
  }
}

///// CLEAN UP
public void stop() {
    opencv.stop();
    super.stop();
}
