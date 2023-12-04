import android.view.MotionEvent;
import netP5.*;
import oscP5.*;


UIBase root;
ArrayList<Integer> touchMap;
int gTargetFrameRate = 120;
int gPendingAnimFrames = 0;

int LARGETEXT;
int SMALLTEXT;

OscP5 oscP5;
NetAddress network;
OscProperties oscProps;
Boolean gOscEnabled = false;

void setup() {
  fullScreen(P3D, 1);
  orientation(LANDSCAPE);
  frameRate(gTargetFrameRate);
  LARGETEXT = (int)(36 * displayDensity);
  SMALLTEXT = (int)(24 * displayDensity);
  
  textSize(SMALLTEXT);
  
  touchMap = new ArrayList<Integer>();
  
  UIBase buttonPanel1 = new UIBase(0, 0, 100, 100, "buttonpanel1", UIBase.LAYOUT_VERTICAL);
    Button button1 = new Button("Touch Down", Button.TOUCH_DOWN);
    button1.borderColor = color(255, 10, 10);
    Button button2 = new Button("Touch Up", Button.TOUCH_UP);
    button2.borderColor = color(10, 255, 10);
    Button button3 = new Button("Toggle", Button.TOGGLE);
    button3.borderColor = color(10, 0, 255);
    buttonPanel1.addChild(button1);
    buttonPanel1.addChild(button2);
    buttonPanel1.addChild(button3);

  UIBase tab1 = new UIBase("tab1", UIBase.LAYOUT_HORIZONTAL);
    tab1.borderColor = color(0);
    tab1.label = "XY Pad  |  Grid";
    UIBase buttonGrid1 = makeButtonGrid(5, 5, "g1");
    XYPad xypad1 = new XYPad(0, 0, 100, 100, "xypad1", XYPad.CARTESIAN);
    tab1.addChild(xypad1);
    tab1.addChild(buttonGrid1);

  UIBase tab2 = new UIBase("tab2", UIBase.LAYOUT_HORIZONTAL);
    tab2.label = "10 Fingers";
    tab2.borderColor = color(10, 255, 10);

  UIBase tab3 = makeSliderBank(12, Slider.VERTICAL, "b1");
    tab3.borderColor = color(0);
    tab3.label = "Slider Bank 1";

  UIBase tab4 = new UIBase("Button Test", UIBase.LAYOUT_HORIZONTAL);
    tab4.borderColor = color(0);
    tab4.addChild(buttonPanel1);
    tab4.addChild(new UIBase("", UIBase.LAYOUT_HORIZONTAL));

  Touch10 tab5 = new Touch10("Touch10");

  int infoHeight = 24;
  TabContainer tabs = new TabContainer(0, infoHeight, 100, 100);
    tabs.addChild(tab1);
    tabs.addChild(tab2);
    tabs.addChild(tab3);
    tabs.addChild(tab4);
    tabs.addChild(tab5);
    tabs.setActiveTab(0);
  
  root = new UIBase(1, infoHeight, width-1, height-1 - infoHeight, "root", UIBase.LAYOUT_HORIZONTAL);
    root.borderColor = color(0);
    root.addChild(tabs);
    root.recalcLayout();
  
  oscProps = new OscProperties();
  network = new NetAddress("192.168.1.102", 12000);
  oscProps.setRemoteAddress(network);
  oscProps.setDatagramSize(65536);
  oscP5 = new OscP5(this, oscProps);
  
}



void draw() {
  background(0);
  root.draw();

  fill(255);
  noStroke();

  textSize(SMALLTEXT);

  String framecountStr = String.format("%d", frameCount);
  text(framecountStr, width - textWidth(framecountStr)-7, 26);
  
  // only draw framerate if updating
  if (touchMap.size() > 0 || gPendingAnimFrames > 0) {
    text((int)frameRate, 7, 26);
  }  
  
  
  //drawTouches();
  
  gPendingAnimFrames--;
  if (touchMap.size() == 0 && gPendingAnimFrames < 0) {
    noLoop();
  }
}


void touchStarted() {
  println(String.format("=================\ntouchStarted: %s",  formatTouches()));
  for (TouchEvent.Pointer p : touches) {
    if (!touchMap.contains(p.id)) {
      touchMap.add(p.id);
      println(String.format("\tid: %d", p.id));
      root.touchStarted(p.id);
    }
  }
  if (touchMap.size() == 1) {
    loop();
  }
}


void touchEnded() {
  println(String.format("touchEnded:   %s",  formatTouches()));
  for (int i=touchMap.size()-1; i>=0; i--) {
    boolean found=false;
    for (TouchEvent.Pointer p : touches) {
      if (touchMap.get(i)==p.id) {
        found=true;
        break;
      }
    }
    if (!found) {
      println(String.format("\tid: %d", touchMap.get(i)));
      root.touchEnded(touchMap.get(i));
      touchMap.remove(i);
    }
  }
}


void touchMoved(TouchEvent e) {
  MotionEvent me = (MotionEvent) e.getNative();
   root.touchMoved(me);
}


void drawTouches() {
  for (int i = 0; i < touches.length; i++) {
    float d = 100 * displayDensity;
    fill(255, 0, 0);
    ellipse(touches[i].x, touches[i].y, d, d);
    fill(20, 255, 20);
    text(touches[i].id, touches[i].x + d/2, touches[i].y - d/2);
  } 
}


TouchEvent.Pointer getTouchById(int id) {
  for (TouchEvent.Pointer p : touches) {
    if (p.id == id) {
      return p;
    }
  }
  return null;
}



UIBase makeSliderBank(int numSliders, int direction, String oscId) {
  UIBase bank = new UIBase(oscId, UIBase.LAYOUT_HORIZONTAL);
  bank.pad = 16;
  for (int i=0; i < numSliders; i++) {
    Slider s = new Slider(String.format("%ss%d", oscId, i), direction);
    
    bank.addChild(s);
  }
  return bank;
  
}

UIBase makeButtonGrid(int rows, int cols, String oscId) {
  UIBase grid = new UIBase(0, 0, width-1, height-1, oscId, UIBase.LAYOUT_GRID);
  grid.pad = 24;
  int numchild = rows * cols;
  grid.gridRows = rows;
  grid.gridCols = cols;
  for (int i=0; i < numchild; i++) {
    Button b = new Button(String.format("%sb%d", oscId, i), Button.TOGGLE);
    b.borderWeight = 4;
    //b.offBorderColor = color(0, 64, 0);
    grid.addChild(b);
  }
  return grid;
}



String formatTouchIds(ArrayList<Integer> touchIds) {
  if (touchIds == null || touchIds.isEmpty()) {
    return "[]";
  }
  StringBuilder sb = new StringBuilder("[");
  for (int i = 0; i < touchIds.size(); i++) {
    sb.append(touchIds.get(i));
    if (i < touchIds.size() - 1) {
      sb.append(", ");
    }
  }
  sb.append("]");
  return sb.toString();
}


String formatTouches() {
  if (touches == null || touches.length == 0) {
    return "[]";
  }
  StringBuilder sb = new StringBuilder("[");
  for (int i = 0; i < touches.length; i++) {
    sb.append(touches[i].id);
    if (i < touches.length - 1) {
      sb.append(", ");
    }
  }
  sb.append("]");
  return sb.toString();
}


void oscSend(float val1, String oscid) {
  OscMessage msg = new OscMessage(oscid);
  msg.add(val1);
  oscP5.send(msg, network);
}

color sinebow(float t) {
  t = 0.5 - t;
  float r = (float)Math.pow(Math.sin(Math.PI * (t + 0.0 / 3)), 2);
  float g = (float)Math.pow(Math.sin(Math.PI * (t + 1.0 / 3)), 2);
  float b = (float)Math.pow(Math.sin(Math.PI * (t + 2.0 / 3)), 2);
  
  // Convert the floats to a range 0-255 for Processing color function
  int red = (int)(r * 255);
  int green = (int)(g * 255);
  int blue = (int)(b * 255);
  
  return color(red, green, blue);
}

class Rect {
  float x=0, y=0, w=0, h=0;

  public Rect() {}

  public Rect(int _x, int _y, int _w, int _h) {
    this.x = _x;
    this.y = _y;
    this.w = _w;
    this.h = _h;
  }
  public Rect(float _x, float _y, float _w, float _h) {
    this.x = _x;
    this.y = _y;
    this.w = _w;
    this.h = _h;
  }
  
  public void set(int _x, int _y, int _w, int _h) {
    this.x = _x;
    this.y = _y;
    this.w = _w;
    this.h = _h;
  }

  public Boolean containsPoint(float px, float py) {
    return !((px<x) || (px>x+w) || (py<y) || (py>y+h));
  }
}
