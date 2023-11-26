
import android.view.MotionEvent;


UIBase root;
ArrayList<Integer> touchMap;

int LARGETEXT;
int SMALLTEXT;


void setup() {
  fullScreen(P3D, 1);
  orientation(LANDSCAPE);
  frameRate(60);
  LARGETEXT = (int)(36 * displayDensity);
  SMALLTEXT = (int)(24 * displayDensity);
  
  textSize(SMALLTEXT);
  
  touchMap = new ArrayList<Integer>();
  
  //  UIBase buttonPanel1 = new UIBase(0, 0, 100, 100, "buttonpanel1", UIBase.LAYOUT_HORIZONTAL);
  //    Button button1 = new Button("Button1", Button.TOUCH_DOWN);
  //    button1.borderColor = color(255, 10, 10);
  //    Button button2 = new Button("Button2", Button.TOUCH_UP);
  //    button2.borderColor = color(10, 255, 10);
  //    Button button3 = new Button("Button3", Button.TOGGLE);
  //    button3.borderColor = color(10, 0, 255);

  //    buttonPanel1.addChild(button1);
  //    buttonPanel1.addChild(button2);
  //    buttonPanel1.addChild(button3);

  UIBase panel1 = new UIBase("panel1", UIBase.LAYOUT_HORIZONTAL);
  panel1.label = "XY Control  |  Button Grid";
  UIBase panel2 = new UIBase("panel2", UIBase.LAYOUT_HORIZONTAL);
  panel2.label = "10 Fingers";
  panel2.borderColor = color(10, 255, 10);
  UIBase panel3 = makeSliderBank(16, Slider.VERTICAL, "b1");
  panel3.label = "Slider Bank 1";
  UIBase panel4 = new UIBase("panel4", UIBase.LAYOUT_HORIZONTAL);
  
  UIBase buttonGrid1 = makeButtonGrid(5, 5, "g1");
  XYPad xypad1 = new XYPad(0, 0, 100, 100, "xypad1", XYPad.CARTESIAN);
  panel1.addChild(xypad1);
  panel1.addChild(buttonGrid1);
  
  //panel1.addChild(buttonPanel1);
  //panel1.addChild(buttonGrid1);

  int infoHeight = 32;

  TabContainer tabs = new TabContainer(0, infoHeight, 100, 100);
  
  tabs.addChild(panel1);
  tabs.addChild(panel2);
  tabs.addChild(panel3);
  tabs.addChild(panel4);
  tabs.setActiveTab(0);
  
  root = new UIBase(1, infoHeight, width-1, height-1 - infoHeight, "root", UIBase.LAYOUT_HORIZONTAL);
  root.borderColor = color(0);
  root.addChild(tabs);
  root.recalcLayout();
}



void draw() {
  background(0);
  root.draw();

  fill(255);
  noStroke();
  textSize(SMALLTEXT);
  text((int)frameRate, 7, 26);
  //drawTouches();
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
  for (int i=0; i < numSliders; i++) {
    Slider s = new Slider(String.format("%ss%d", oscId, i), direction);
    
    bank.addChild(s);
  }
  return bank;
  
}

UIBase makeButtonGrid(int rows, int cols, String oscId) {
  UIBase grid = new UIBase(0, 0, width-1, height-1, oscId, UIBase.LAYOUT_GRID);
  int numchild = rows * cols;
  grid.gridRows = rows;
  grid.gridCols = cols;
  for (int i=0; i < numchild; i++) {
    Button b = new Button(String.format("%sb%d", oscId, i), Button.TOGGLE);
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
