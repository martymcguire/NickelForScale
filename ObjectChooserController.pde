import unlekker.data.*;
import unlekker.geom.*;

ArrayList<FaceList> stls;
ArrayList<String> names;
int curr_model = 1;
int deg = 150;

int modelSize_w = 480;
int modelSize_h = 480;

ControlFont cfont;
ControlFont arrowFont;
ControlFont continueFont;
ControlFont instructionsFont;

class ObjectChooserController extends UIController {
  
  public void setup(){
    File dir = new File(sketchPath + "/data/objects");
    File[] obj_dirs = dir.listFiles();
    stls = new ArrayList<FaceList>();
    names = new ArrayList<String>();
    for(int i = 0; i < obj_dirs.length; i++){
      File obj = obj_dirs[i];
      String name = obj.getName();
      STL stl = new STL(app, new File(obj,name + "-bin.stl").getAbsolutePath());
      FaceList poly = stl.getPolyData();
      poly.normalize(420);
      poly.center();
      stls.add(poly);
      names.add(name);
    }
  
    font = createFont( "SansSerif", 20);
    textFont( font, 20 );

    cfont = new ControlFont(createFont("SansSerif",18));
    arrowFont = new ControlFont(createFont("SansSerif",40));
    continueFont = new ControlFont(createFont("SansSerif",30));
    instructionsFont = new ControlFont(createFont("SansSerif",40));
  }
  
  public void takeControl(){
    //frame.setSize(350,350 + PADDING*2 + TEXT_H);
    //frame.setSize(w+PADDING*2, h+INFO_H+PADDING*3+50);

    //controlP5.addButton(" Continue >>",0,(width/2) - 80,480,160,35);
    controlP5.addButton(" Continue >>",0, width - 220 - PADDING, h+(INFO_H)-40, 220, 45);
    controlP5.Label lbl = controlP5.controller(" Continue >>").captionLabel();
    lbl.setControlFont(continueFont);
    lbl.setControlFontSize(30);
    
    controlP5.addButton("<", 1, PADDING, PADDING, 50,480);
    lbl = controlP5.controller("<").captionLabel();
    lbl.setControlFont(arrowFont);
    lbl.setControlFontSize(35);
    
    controlP5.addButton(">", 2, width - 50 - PADDING, PADDING, 50,480);
    lbl = controlP5.controller(">").captionLabel();
    lbl.setControlFont(arrowFont);
    lbl.setControlFontSize(35);
    
    controlP5.addTextlabel("info1"," ",480,290);
    lbl.setControlFont(instructionsFont);
    lbl.setControlFontSize(35);
  }
  
  public void controlEvent(ControlEvent theEvent) {
    String name = theEvent.controller().name();
    if(name.equals(" Continue >>")){
      moveOn();
    } else if(name.equals("<")) {
      prevModel();
    } else if(name.equals(">")) {
      nextModel();
    }
  }


  void drawInfo(){
    pushMatrix();
    translate(PADDING, PADDING*2+h);
    fill(255,255,255);
    textFont(createFont("SansSerif",25));
    text("Choose the model you want to customize!", PADDING + 50, TEXT_H + (PADDING*2));
    text("Browse models using the arrow buttons, ",PADDING + 50, (TEXT_H + 50)+(PADDING*2));
    text("then click on the CONTINUE button.",PADDING + 50, (TEXT_H + 80)+(PADDING*2));
    popMatrix(); 
  }
  
  public void draw(){
    background(0);
    
    drawInfo();
    
    pushMatrix();
    //translate(175,150);
    translate(width/2,240+PADDING);
    rotateY(deg*(PI/180));
    rotateX(170*(PI/180));
    fill(128,128,128);
    stroke(255,255,255);
    stls.get(curr_model).draw(app);
    popMatrix();
    deg++; if(deg > 359) { deg = 0; }
    textAlign(CENTER);
    fill(255,255,255);
    text(name_to_readable(names.get(curr_model)), width/2, 480+TEXT_H-PADDING);
    textAlign(LEFT);
    controlP5.draw();
  }
  
  public void keyPressed(){
    if(keyCode == LEFT){
      prevModel();
    } else if(keyCode == RIGHT){
      nextModel();
    } else if(keyCode == ENTER){
      moveOn();
    }
    
  }
  public void mousePressed(){}
  public void mouseReleased(){}
  public void mouseDragged(){}
  
  void prevModel(){
    curr_model--;
    if(curr_model < 0) { curr_model = stls.size()-1; }
  }
  
  void nextModel(){
      curr_model++;
      if(curr_model > stls.size()-1) { curr_model = 0; }
  }
  
  void moveOn(){
    modelName = names.get(curr_model);

    controlP5.remove(" Continue >>");
    controlP5.remove("<");
    controlP5.remove(">");
    changeController(controllers.get("capture"));
  }
  
  String name_to_readable(String name){
    return name.replaceAll("_"," ");
  }
}
