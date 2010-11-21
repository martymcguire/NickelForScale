abstract class UIController {
  boolean initialized = false;
  public boolean isInitialized(){ return initialized; }
  public abstract void setup();
  public abstract void takeControl();
  public abstract void draw();
  public abstract void keyPressed();
  public abstract void mousePressed();
  public abstract void mouseReleased();
  public abstract void mouseDragged();
  public abstract void controlEvent(ControlEvent theEvent);
}
