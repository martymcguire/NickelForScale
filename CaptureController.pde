class CaptureController extends UIController{
  
  ArrayList<String> measureLabels;
  Controller cont_btn;
  
  public void setup(){
    measureLabels = new ArrayList<String>();
    setupOpenCVcamera();
    initialized = true;
  }
  
  public void takeControl(){
    String confFile = sketchPath 
                      + "/data/objects/"
                      + modelName
                      + "/measurements.txt";
    String[] lbls = loadStrings(confFile);
    for(int i = 0; i < lbls.length; i++){
      measureLabels.add(lbls[i]);
    }
    frame.setSize(w+PADDING*2, h+INFO_H+PADDING*3+50);
    
    controlP5.addButton("<< Back",0, 20, h+INFO_H, 160, 35);
    controlP5.Label lbl = controlP5.controller("<< Back").captionLabel();
    lbl.setControlFont(cfont);
    lbl.setControlFontSize(20);
    controlP5.addButton(" Continue >>",1, w-180, h+INFO_H, 160, 35);
    cont_btn = controlP5.controller(" Continue >>");
    lbl = cont_btn.captionLabel();
    lbl.setControlFont(cfont);
    lbl.setControlFontSize(20);
    cont_btn.hide();
    isCapturing = true;
  }
  
  public void draw(){
    cam.read();
    opencv.copy(cam);
    
    findBlobs();
    getPixelsPerMM();
    drawBlob(hand);

    background(0);

    if(isCapturing) { image (cam, PADDING, PADDING); }
    if(!isCapturing && showOrig) { image( orig_img, PADDING, PADDING ); }
    if(showBlobs) { drawBlobs(); }

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
    
    if(lines.size() == measureLabels.size()){
      cont_btn.show();
    } else {
      cont_btn.hide();
    }
    controlP5.draw();
  }
  
  public void keyPressed(){
   
    switch(key){
      case 'o':
        showOrig = showOrig ? false : true;
        break;
      case 'b':
        showBlobs = showBlobs ? false : true;
        break;
      case 'd':
        if(lines.size() > 0){
          lines.remove(lines.size()-1);
        }
        break;
      case ' ':
        if(isCapturing){
          isCapturing = false;
          img = new PImage(w,h);
          img.copy(cam,0,0,w,h,0,0,w,h);
          orig_img = new PImage(w,h);
          orig_img.copy(cam,0,0,w,h,0,0,w,h);
        }
        else{
         //turn video back on and clear any lines that were drawn
         isCapturing = true; 
         lines = new ArrayList<Line>();
        }
        break;
      case 'x':
        writeMeasurements();
      break;
    } 
  }
  public void mousePressed(){
    isDrawing = true;
    ls.x = mouseX;
    ls.y = mouseY;
    le.x = ls.x;
    le.y = ls.y; 
  }
  
  public void mouseReleased(){
    if(isDrawing){
      isDrawing = false;
      ls.x -= PADDING;
      ls.y -= PADDING;
      le.x -= PADDING;
      le.y -= PADDING;
      Line l = new Line(ls,le);
      Line trimmed = trimLineToHand(l);
      if( (trimmed != null) && !(trimmed.equals(l)) && (trimmed.length() > 5) ){
        lines.add(trimmed);
      }
    } 
  }
  
  public void mouseDragged(){
    le.x = mouseX;
    le.y = mouseY; 
  }
  
  public void controlEvent(ControlEvent theEvent) {
    String name = theEvent.controller().name();
    if(name.equals("<< Back")){
      lines = new ArrayList<Line>();
      changeController(controllers.get("object_chooser"));
      controlP5.remove("<< Back");
      controlP5.remove(" Continue >>");
    }
    if(name.equals(" Continue >>")){
      writeMeasurements();
      controlP5.remove("<< Back");
      controlP5.remove(" Continue >>");
      //changeController(controllers.get("render"));
    }
  }
  
  void setupOpenCVcamera(){
     String[] devices = Capture.list();
     println(Capture.list());
     cam = new Capture(app, w, h, devices[5]);
     opencv = new OpenCV( app );
     opencv.allocate(w,h);
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
    /* text("MM/PX: " + mm_per_px, 0, TEXT_H); */
    if(isCapturing){
      text("Place your hand on the paper with a nickel on top.", 0, TEXT_H);
      text("Press [SPACE BAR] when your hand and the nickel are found.",0, TEXT_H*2.2);
    } else {
      int txtLines = 1;
      for(int i = 0; i < measureLabels.size(); i++){
        String measurement = "[MEASURE ME NOW!]";
        if((lines.size() > i) && (lines.get(i) != null)){
          measurement = "" 
                        + String.format("%.03f",lines.get(i).length() * mm_per_px)
                        + "mm";
        }
        text(measureLabels.get(i) + ": " + measurement, 0, TEXT_H*(txtLines + .2));
      }
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
    opencv.copy(isCapturing ? cam : img);
    opencv.threshold(0, 255, OpenCV.THRESH_TOZERO_INV | OpenCV.THRESH_OTSU);
    blobs = opencv.blobs( 100, w*h/3, 20, true );
    hand = findHandBlob(blobs);
    if(hand != null){
        // do an ROI thing
        opencv.copy(isCapturing ? cam : img);
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
    if(nickel != null){
      Rectangle bounds = nickel.rectangle;
      nickel_diam_px = (float) ((bounds.width > bounds.height) ? bounds.width : bounds.height);
      mm_per_px = nickel_diam_mm / nickel_diam_px;
    }
  }

  Line trimLineToHand(Line l){
  
    println("\n trimming line");
    if((l == null) || (hand == null)){ return l; }

    //hpts is an array of all points in the outline of the hand
    Point[] hpts = hand.points;
    if(hpts.length < 2){ return l; }

    Point m1 = l.p2;
    double m1d = l.length();
    Point m2 = l.p1;
    double m2d = l.length();
    Point p1 = hpts[0];
    Point p2 = hpts[1];
    for(int i = 1; i < hpts.length; i++){
      p2 = hpts[i];
      //println("p1 " + p_to_s(p1) + " p2 " + p_to_s(p2));
      //ix is the intersection of p1,p2 and a line's start and end points
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

  //convert a point to a string
  String p_to_s(Point p){
    return "(" + p.x +"," + p.y + ")";
  }
  
  //convert a line to a string
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
          if(blob == null) { return; }
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
  
  ////saving
  
  
  void writeMeasurements(){
    //create output file
    output = createWriter("data/current_measurements.scad");
    
    double measurement = 0.0;
    
    output.println("//All measurements in mm "); 
  
    //write the data stored in lines 
    int i = 1;
    for(Line l : lines){
      measurement = l.length() * mm_per_px;
      println(l.length() * mm_per_px);
      output.println("measurement_" + i + " = " + measurement + ";");
      i++;
    }
    output.flush();  
  }

}
