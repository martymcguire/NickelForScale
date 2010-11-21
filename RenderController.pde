import unlekker.data.*;
import unlekker.geom.*;

public class RenderController extends UIController {
    
  boolean isRendering = true;
  boolean isMakingBinary = true;
  
  FaceList origSTL;
  FaceList destSTL;
  
  public void setup(){}
  
  public void takeControl(){
    origSTL = loadSTL(origStlForModel(modelName));
    renderCustomModel(modelName);
  }
  
  public void draw(){
    background(0);
    if(isRendering){
      pushMatrix();
      translate(width/2,240+PADDING);
      rotateY(deg*(PI/180));
      rotateX(215*(PI/180));
      fill(128,128,128);
      stroke(255,255,255);
      origSTL.draw(app);
      popMatrix();
      textAlign(CENTER);
      text("Please Wait...", width/2, 240+PADDING*2+INFO_H+TEXT_H*2.2);
      text("We are making your customizations.", width/2, 240+PADDING*2+INFO_H+TEXT_H*3.2);
      textAlign(LEFT);
    } else {
      pushMatrix();
      translate(width/2,240+PADDING);
      rotateY(deg*(PI/180));
      rotateX(215*(PI/180));
      fill(128,128,128);
      stroke(255,255,255);
      origSTL.draw(app);
      popMatrix();
      textAlign(CENTER);
      text("Your object is complete!", width/2, 240+PADDING*2+INFO_H+TEXT_H*2.2);
      text("Go print that thing!", width/2, 240+PADDING*2+INFO_H+TEXT_H*3.2);
      textAlign(LEFT);
    }
    deg++; if(deg > 359) { deg = 0; }
    
    checkRenderingState();  
  }
  
  public void keyPressed(){}
  public void mousePressed(){}
  public void mouseReleased(){}
  public void mouseDragged(){}
  public void controlEvent(ControlEvent theEvent){}
  
  void checkRenderingState(){
  File stl_file = new File(destStlForModel(modelName));
  File stl_bin_file = new File(destBinStlForModel(modelName));
  if(isRendering && stl_file.exists()){
    isRendering = false;
    convertStlToBinary(modelName);
  } else if (isMakingBinary && stl_bin_file.exists()){
    isMakingBinary = false;
    destSTL = loadSTL(stl_bin_file.getAbsolutePath());
  }
}

  void convertStlToBinary(String modelName){
    File stl_file = new File(destStlForModel(modelName));
    File stl_bin_file = new File(destBinStlForModel(modelName));
    String conv_script = sketchPath + "/scripts/stl_ascii_to_bin.pl";
    String[] exec = {"/bin/sh", "-c", conv_script + " "
                     + stl_file.getAbsolutePath() + " " + stl_bin_file.getAbsolutePath()};
    println("Converting to binary...");
    println(exec);
    exec(exec);
  }
  
  void renderCustomModel(String modelName){
    isRendering = true;
    isMakingBinary = true;
  
    File scad_file = new File(scadForModel(modelName));
    File stl_file = new File(destStlForModel(modelName));
    File stl_bin_file = new File(destBinStlForModel(modelName));
    String[] exec = {"/usr/bin/open","/Applications/OpenSCAD.app","--args",
                     "-s",
                     stl_file.getAbsolutePath(),
                     scad_file.getAbsolutePath()
                     };
  
    if(stl_file.exists()){
      stl_file.delete();
    }
    if(stl_bin_file.exists()){
      stl_bin_file.delete();
    }
    println("Rendering w/ OpenSCAD...");
    println(exec);
    exec(exec);
  }
  
  FaceList loadSTL(String filename){
    STL stl = new STL(app, filename);
    FaceList fl = stl.getPolyData();
    fl.normalize(MODEL_SIZE);
    fl.center();
    return fl;
  }
  
  String scadForModel(String modelName){
    return sketchPath + "/data/objects/" + modelName + "/" + modelName + ".scad";
  }
  
  String origStlForModel(String modelName){
    return sketchPath + "/data/objects/" + modelName + "/" + modelName + "-bin.stl";
  }
  
  String destStlForModel(String modelName){
    return sketchPath + "/data/" + modelName + ".stl";
  }
  
  String destBinStlForModel(String modelName){
    return sketchPath + "/data/" + modelName + "-bin.stl";
  }
}
