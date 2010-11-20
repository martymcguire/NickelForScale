import hypermedia.video.*;
import java.awt.*;
import processing.video.*;

OpenCV opencv;

PImage img;

int w = 640;
int h = 480;
int whole_img_thresh = 80;
int roi_thresh = 80;

boolean find=true;

PFont font;

void setup() {

    size( w*2+30, h*2+30 );

    img = loadImage("amy-tests/1nickel-hand-C-naturalLight-1.jpg");

    opencv = new OpenCV( this );
    opencv.allocate(img.width,img.height);

    //opencv.capture(w,h,2);
    //println(Capture.list());
    
    font = loadFont( "SansSerif-18.vlw" );
    textFont( font, 18 );

    println( "Drag mouse inside sketch window to change threshold" );
    println( "Press space bar to record background image" );

}

void draw() {

    background(0);
    opencv.copy(img);
    //opencv.read();
    //opencv.flip( OpenCV.FLIP_HORIZONTAL );

    //image( opencv.image(), 10, 10 );	            // RGB image
    //image( opencv.image(OpenCV.GRAY), 20+w, 10 );   // GRAY image
    image( opencv.image(OpenCV.GRAY), 10, 10 ); // GRAY image
    //image( opencv.image(OpenCV.MEMORY), 10, 20+h ); // image in memory

    //opencv.absDiff();
    opencv.threshold(whole_img_thresh, 255, OpenCV.THRESH_TOZERO_INV | OpenCV.THRESH_OTSU);
    image( opencv.image(OpenCV.GRAY), 20+w, 10 ); // absolute difference image

    // working with blobs
    Blob[] blobs = opencv.blobs( 100, w*h/3, 20, true );

    noFill();

    pushMatrix();
    translate(20+w,10);

    Blob hand = findHandBlob(blobs);
    if(hand != null){
      //drawBlob(hand);
      // do an ROI thing
      opencv.copy(img);
      opencv.ROI( hand.rectangle.x, hand.rectangle.y, hand.rectangle.width, hand.rectangle.height );
      opencv.threshold(roi_thresh, 255, OpenCV.THRESH_TOZERO_INV | OpenCV.THRESH_OTSU);
      blobs = opencv.blobs( 100, w*h/3, 20, true );
      for( int i=0; i<blobs.length; i++ ){
        drawBlob(blobs[i]);
      }
    }

    popMatrix();

    opencv.ROI( null );
}

Blob findHandBlob(Blob[] blobs){
    for( int i=0; i<blobs.length; i++ ) {
        float area = blobs[i].area;
        float perimeter = blobs[i].length;
        float a_c_ratio = area / perimeter;
        if(a_c_ratio > 20.0) { return blobs[i]; }
    }
    return null;
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
    if ( key==' ' ) opencv.remember();
}

void mouseDragged() {
    whole_img_thresh = int( map(mouseX,0,width,0,255) );
    roi_thresh = int( map(mouseY,0,height,0,255) );
    println(whole_img_thresh + ", " + roi_thresh + " (" + mouseX + ", " + mouseY + ")");
}

public void stop() {
    opencv.stop();
    super.stop();
}
