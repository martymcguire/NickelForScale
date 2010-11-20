import hypermedia.video.*;
import java.awt.*;
import processing.video.*;

OpenCV opencv;
PImage img;
PImage orig_img;
int w = 640;
int h = 480;

PFont font;

float px_per_mm = 0;
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

    size( w*2+30, h*2+30 );
    font = loadFont( "SansSerif-18.vlw" );
    textFont( font, 18 );
}

void draw() {

    findBlobs();
    getPixelsPerMM();
    drawBlob(hand);

    background(0);

    image( orig_img, 10, 10 );
    image( opencv.image(OpenCV.GRAY), 20+w, 10 ); // absolute difference image
    noFill();
    pushMatrix();
    translate(20+w,10);

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
 * px_per_mm for the image.
 *
 * Uses larger of blob bounding box width and height.
 *
 * Uses globals
 *   - Blob nickel
 *   - float nickel_diam_mm
 * Sets globals
 *   - float px_per_mm = 0;
 *   - float nickel_diam_px = 0;
 */
void getPixelsPerMM(){
  Rectangle bounds = nickel.rectangle;
  nickel_diam_px = (float) ((bounds.width > bounds.height) ? bounds.width : bounds.height);
  px_per_mm = nickel_diam_px / nickel_diam_mm;
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
        noStroke();
        fill(0,0,255);
        text( area,centroid.x+5, centroid.y+5 );


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

        noStroke();
        fill(255,0,255);
        text( perimeter, centroid.x+5, centroid.y+25 );

        // area : perimeter ratio
        fill(0,255,0);
        text( area / perimeter, centroid.x+5, centroid.y+45 );
}

void keyPressed() {
}

void mouseDragged() {
}

public void stop() {
    opencv.stop();
    super.stop();
}
