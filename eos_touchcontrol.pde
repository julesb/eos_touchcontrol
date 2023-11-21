
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
  
  XYPad xypad1 = new XYPad(0, 0, 100, 100, "xypad1", XYPad.CARTESIAN);
  //xypad1.borderColor = color(10,255,10);

  UIBase panel1 = new UIBase(0, 0, 100, 100, "panel1", UIBase.LAYOUT_VERTICAL);
  //panel1.borderColor = color(10, 10, 255);

    UIBase buttonPanel1 = new UIBase(0, 0, 100, 100, "buttonpanel1", UIBase.LAYOUT_HORIZONTAL);
    //panel21.borderColor = color(255, 255, 10);

      Button button1 = new Button("Button1", Button.TOUCH_DOWN);
      button1.borderColor = color(255, 10, 10);
      Button button2 = new Button("Button2", Button.TOUCH_UP);
      button2.borderColor = color(10, 255, 10);
      Button button3 = new Button("Button3", Button.TOGGLE);
      button3.borderColor = color(10, 0, 255);

      buttonPanel1.addChild(button1);
      buttonPanel1.addChild(button2);
      buttonPanel1.addChild(button3);

    UIBase buttonGrid1 = makeButtonGrid(4, 6, "g1");

  panel1.addChild(buttonPanel1);
  panel1.addChild(buttonGrid1);

  int infoHeight = 50;

  TabContainer tabRoot = new TabContainer(0, infoHeight, 100, 100);
  tabRoot.borderColor = color(255, 10, 255);
  tabRoot.addChild(xypad1);
  tabRoot.addChild(panel1);

  root = new UIBase(1, infoHeight, width-1, height-1 - infoHeight, "root", UIBase.LAYOUT_HORIZONTAL);
  root.addChild(tabRoot);
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



UIBase makeButtonGrid(int rows, int cols, String oscId) {
  UIBase grid = new UIBase(0, 0, width-1, height-1, oscId, UIBase.LAYOUT_GRID);
  int numchild = rows * cols;
  grid.gridRows = rows;
  grid.gridCols = cols;
  for (int i=0; i < numchild; i++) {
    Button b = new Button(0, 0, width-1, height-1, String.format("%sb%d", oscId, i), Button.TOGGLE);
    grid.addChild(b);
  }
  return grid;
}


class UIBase {
  public int mode;
  public static final int LAYOUT_NONE = 0;
  public static final int LAYOUT_HORIZONTAL = 1;
  public static final int LAYOUT_VERTICAL = 2;
  public static final int LAYOUT_GRID = 3;
  public int layout;
  public Rect bounds;
  public ArrayList<UIBase> children;
  public int pad = 16;
  public Boolean lockAspectRatio = false; // TODO
  public color borderColor = color(128);
  String oscId;
  ArrayList<Integer> touchIds;
  PVector[] touchPositions = new PVector[10];
  int gridRows = 4;
  int gridCols = 4;

  public UIBase(float _x, float _y, float _w, float _h, String _oscId, int _layout ) {
    this.bounds = new Rect(_x, _y, _w, _h);
    this.oscId = _oscId;
    this.layout = _layout;
    this.children = new ArrayList<UIBase>();
    this.touchIds = new ArrayList<Integer>();
  }

  public UIBase(String _oscId, int _layout ) {
    this(0, 0, 100, 100, _oscId, _layout);
  }
  
  
  public void addChild(UIBase child) {
    children.add(child);
  }


  void recalcLayout() {
    float w, h;
    int nchild = this.children.size();
    if (nchild > 0) {
      if (this.layout == LAYOUT_HORIZONTAL) {  
        w = (this.bounds.w - pad*(nchild+1)) / nchild;
        h = this.bounds.h - pad*2;
        for (int i=0; i<nchild; i++) {
          UIBase child = children.get(i);
          child.bounds.x = this.bounds.x + pad + i * (w+pad);
          child.bounds.y = this.bounds.y+pad;
          child.bounds.w = w;
          child.bounds.h = h;
          child.recalcLayout();
        }
      }
      else if (this.layout == LAYOUT_VERTICAL) {
        w = this.bounds.w - pad*2;        
        h = (this.bounds.h - pad*(nchild+1)) / nchild;
        for (int i=0; i<nchild; i++) {
          UIBase child = children.get(i);
          child.bounds.x = this.bounds.x+pad;
          child.bounds.y = this.bounds.y + pad + i * (h+pad);
          child.bounds.w = w;
          child.bounds.h = h;
          child.recalcLayout();
        }
      }
      else if (this.layout == LAYOUT_GRID) {
        int numCells = gridRows * gridCols;
        w = (this.bounds.w - pad*(gridCols+1)) / gridCols;
        h = (this.bounds.h - pad*(gridRows+1)) / gridRows;
        for (int i=0; i<nchild; i++) {
          if (i >= numCells) {
            break;
          }
          float x = this.bounds.x + pad + (i % gridCols) * (w+pad);
          float y = this.bounds.y + pad + (i / gridCols) * (h+pad);
          UIBase child = children.get(i);
          child.bounds.x = x;
          child.bounds.y = y;
          child.bounds.w = w;
          child.bounds.h = h;
        }
      }
    }
  }

  public void touchStarted(int id) {
    TouchEvent.Pointer p = getTouchById(id);
    if (! this.bounds.containsPoint(p.x, p.y)) {
      return;
    }
    if (!touchIds.contains(id)) {
      touchIds.add(id);
    }
    this.touchPositions[id] = new PVector(p.x, p.y);

    for (int i=0; i<children.size(); i++) {
      UIBase c = children.get(i);
      if (id < touches.length &&
          c.bounds.containsPoint((int)touches[id].x, (int)touches[id].y)) {
        c.touchStarted(id);
      }
    }
  }

  public void touchEnded(int id) {
    for (int c=0; c<children.size(); c++) {
      this.children.get(c).touchEnded(id);
    }
    this.touchIds.remove(Integer.valueOf(id));
    touchPositions[id] = null;
  }
  
  public void touchMoved(MotionEvent e) {
    final int pointerCount = e.getPointerCount();
    for (int p = 0; p < pointerCount; p++) {
      try {
        int id = e.getPointerId(p);

        if (id < pointerCount && id > -1) {
          float x = e.getX(id);
          float y = e.getY(id);
          if(touchPositions[id] == null) {
            touchPositions[id] = new PVector(x, y);
          }
          else {
            touchPositions[id].x = x;
            touchPositions[id].y = y;
          }
        }
        for (UIBase child: this.children) {
          if (child.touchPositions[id] != null) {
            child.touchMoved(e);
          }
        }
      }
      catch(IllegalArgumentException ie) {
        continue;
      }
      //println(String.format("pointer %d: (%f,%f)", me.getPointerId(p), me.getX(p), me.getY(p)));
    }
  }

  public void drawBounds() {
    stroke(borderColor);
    noFill();
    rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h, 16 );

  }

  public void draw() {
    if (touchIds.size() > 0 && children.size() == 0) {
      strokeWeight(10);
    }
    else {
      strokeWeight(1);
    }
    drawBounds();

    if (children.size() == 0) {
      fill(255);
      String info = String.format("%s:  %s",
                     this.oscId, formatTouchIds(this.touchIds));
      //String info = String.format("%s: t: %d: %s",
      //               this.oscId, this.touchIds.size(), formatTouchIds(this.touchIds));
      textSize(SMALLTEXT);
      text(info, this.bounds.x+7, this.bounds.y+26);

      for (int i=0; i<touchIds.size(); i++) {
        int tid = touchIds.get(i);
        TouchEvent.Pointer p = getTouchById(tid);
        if (p != null) {
          float px = p.x;
          float py = p.y;

          // touch point
          int d = 150;
          noStroke();
          fill(borderColor);
          ellipse(px, py, d, d);

          if (this.bounds.containsPoint(px, py)) {
          // crosshair
            strokeWeight(1);
            stroke(255);
            line(px, this.bounds.y, px, this.bounds.y+this.bounds.h-1);
            line(this.bounds.x, py, this.bounds.x+this.bounds.w-1, py);
          }

          textSize(LARGETEXT);
          String touchinfo;
          PVector npos = getNormalizedTouchById(tid);
          if (npos == null) {
             touchinfo = String.format("%d [null]", p.id);
          }
          else {
            touchinfo = String.format("%d [%.2f, %.2f]", p.id, npos.x, npos.y);
          }
          fill(20, 255, 20);
          text(touchinfo, p.x - d/1.25, p.y - d/1.25);
          //text(p.id, p.x - d/2, p.y - d/2);
        }
      }
    }
    for (int i=0; i<children.size(); i++) {
      UIBase child = children.get(i);
      child.draw();
    }
  } // end draw()
  
  PVector getNormalizedTouchById(int id) {
    TouchEvent.Pointer p = getTouchById(id);
    if (p == null) {
      return null;
    }
    float nx = (p.x - this.bounds.x) / this.bounds.w;
    float ny = (p.y - this.bounds.y) / this.bounds.h;
    return new PVector(nx, ny);
  }

} // End UIBase


class Button extends UIBase {
  public static final int TOUCH_DOWN = 0; // triggers on touch
  public static final int TOUCH_UP   = 1; // triggers on touch
  public static final int TOGGLE     = 2; // triggers on touch, toggle state
  int recentTouchCountdown = 0;

  int buttonMode = 0;
  Boolean toggleState = false;

  public Button(int _x, int _y, int _w, int _h, String _oscId, int _mode) {
    super(_x, _y, _w, _h, _oscId, UIBase.LAYOUT_NONE);
    this.buttonMode = _mode;
  }

  public Button(String _oscId, int _mode) {
    super(0, 0, 100, 100, _oscId, UIBase.LAYOUT_NONE);
    this.buttonMode = _mode;
  }

  @Override
  public void touchStarted(int id) {
    super.touchStarted(id);
    if (buttonMode == TOGGLE) {
      toggleState = ! toggleState;
    }
    if (buttonMode == TOUCH_DOWN || buttonMode == TOGGLE) {
      // Trigger button action
      // TODO: OSC send
      print(String.format("%s pressed (TOUCH_DOWN)", this.oscId));

      // no need to track the touch any more
      touchPositions[id] = null;
      touchIds.remove(Integer.valueOf(id));

      recentTouchCountdown = 64;
    }
  }

  @Override
  public void touchEnded(int id) {
      PVector p = touchPositions[id];
      if (p != null) {
        if (buttonMode == TOUCH_UP && this.bounds.containsPoint(p.x, p.y)) {
          // Trigger button action
          // TODO: OSC send
          print(String.format("%s pressed (TOUCH_UP) id=%d", this.oscId, id));
          recentTouchCountdown = 64;
        }
      }
      super.touchEnded(id);
  }

  @Override
  public void draw() {
    if (this.buttonMode == TOGGLE && this.toggleState) {
      noStroke();
      fill(borderColor);
      rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h, 16 );
    }
    else if (recentTouchCountdown > 0) {
      fill(borderColor, recentTouchCountdown*4);
      noStroke();
      rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h, 16 );
      recentTouchCountdown-=1;
    }
    super.draw();
  }
}


class Slider {
  // TODO
}


class TabContainer extends UIBase {
  int activeTabIndex = 0;
  int tabBarHeight = 100;
  UIBase tabBar;
  UIBase contentArea;

  public TabContainer(int x, int y, int w, int h) {
    super(x, y, w, h, "tabs", UIBase.LAYOUT_NONE);
    tabBar = new UIBase(0, 0, 100, 100, "tabbuttons", UIBase.LAYOUT_HORIZONTAL);
    contentArea = new UIBase(0, 0, 100, 100, "contentarea", UIBase.LAYOUT_HORIZONTAL);
    recalcLayout();
  }

  @Override
  void addChild(UIBase child) {
    contentArea.addChild(child);
    Button b = new Button(child.oscId, Button.TOGGLE);
    tabBar.addChild(b);
    tabBar.recalcLayout();
    contentArea.recalcLayout();
    recalcLayout();
  }

  @Override
  void recalcLayout() {
    tabBar.bounds.x = bounds.x;
    tabBar.bounds.y = bounds.y;
    tabBar.bounds.w = bounds.w;
    tabBar.bounds.h = tabBarHeight;
    tabBar.recalcLayout();

    contentArea.bounds.x = bounds.x;
    contentArea.bounds.y = bounds.y + tabBarHeight+pad;
    contentArea.bounds.w = bounds.w;
    contentArea.bounds.h = bounds.h - tabBarHeight-pad;
    contentArea.recalcLayout();
    if (children.size() > 0) {
      for (UIBase child: children) {
        child.recalcLayout();
      }
    }
  }

  @Override
  void draw() {
    stroke(255,10,10);
    noFill();
    //rect(bounds.x+pad, bounds.y+tabBarHeight+pad, bounds.w-pad*2, tabBarHeight);
    //rect(bounds.x, bounds.y, bounds.x+bounds.w-1, bounds.y+bounds.h-1);
    tabBar.draw();
    contentArea.draw();
    // draw only the active child
    //int nchild = this.children.size();
    //if (nchild > 0 && activeTabIndex < nchild) {
    //  UIBase child = children.get(activeTabIndex);
    //  child.draw();
    //}
  }

  @Override
  public void touchStarted(int id) {
    super.touchStarted(id);
    tabBar.touchStarted(id);
    contentArea.touchStarted(id);
  }

  @Override
  public void touchEnded(int id) {
    super.touchEnded(id);
    tabBar.touchEnded(id);
    contentArea.touchEnded(id);
  }

  @Override
  public void touchMoved(MotionEvent e) {
    super.touchMoved(e);
    tabBar.touchMoved(e);
    contentArea.touchMoved(e);
  }

  void activateTab(int tabIndex) {
    if (tabIndex < children.size()) {
      this.activeTabIndex = tabIndex;
      recalcLayout();
    }
  }
}

class HeliosControl {
  // TODO - actually shouldnt be a class, just a function `UIBase makeHeliosControl(...)`
}


class XYPad extends UIBase {
  public static final int CARTESIAN = 0;
  public static final int POLAR = 0;
  int coordSys = CARTESIAN;
  PVector pos;
  float tx, ty, ta, tr;
  float ptx, pty;

  public XYPad(int _x, int _y, int _w, int _h, String _oscId, int _coordSys) {
    super(_x, _y, _w, _h, _oscId, UIBase.LAYOUT_NONE);
    this.coordSys = _coordSys;
    tx = 0.0;
    ty = 0.0;
    ta = 0.0;
    tr = 1.0;
    pos = new PVector(0,0);
  }


  public void draw() {
    float dim = min(this.bounds.w, this.bounds.h) - pad*2;
    float ctlx = this.bounds.x + pad;
    float ctly = this.bounds.y+this.bounds.h - dim - pad;
    float ctlcx = ctlx + dim/2;
    float ctlcy = ctly + dim/2;

    strokeWeight(1);
    drawBounds();
    stroke(128);
    noFill();
    rect(ctlx, ctly, dim, dim);

    PVector p;
    if (touchIds.size() > 0) {
      int id = touchIds.get(0);
      p = touchPositions[id];
      if (p == null) {
        print("no position");
        return;
      }
      this.pos.x = p.x;
      this.pos.y = p.y;

      tx = (p.x - this.bounds.x) / this.bounds.w;
      ty = 1.0 - (p.y - this.bounds.y) / this.bounds.h;
      tx = max(0, min(1.0, tx));
      ty = max(0, min(1.0, ty));
    }
    else {
      p = this.pos;
    }

    // crosshair
    if (this.bounds.containsPoint(p.x, p.y)) {
      strokeWeight(1);
      stroke(10, 255, 255);
      line(p.x, ctly, p.x, ctly+dim-1);
      line(ctlx, p.y, ctlx+dim-1, p.y);
    }

    float dotx = max(ctlx, min(ctlx+dim, p.x));
    float doty = max(ctly, min(ctly+dim, p.y));

    // touch point
    noStroke();
    fill(255,255,10);
    if (touchIds.size() > 0) {
      ellipse(dotx, doty, 100, 100);
    }
    else {
      ellipse(dotx, doty, 20, 20);
    }

    // unit circle
    strokeWeight(1);
    stroke(128);
    noFill();
    ellipse(ctlx+dim/2, ctly+dim/2, dim, dim);
    line(ctlx+dim/2, ctly, ctlx+dim/2, ctly+dim);
    line(ctlx, ctly+dim/2, ctlx+dim, ctly+dim/2);

    PVector pn = new PVector(p.x, p.y).sub(new PVector(ctlcx, ctlcy)).normalize().mult(dim/2);
    // angle radius line
    strokeWeight(4);
    stroke(255,255,10);
    line(ctlcx, ctlcy, ctlcx+pn.x, ctlcy+pn.y);

    fill(255);
    noStroke();
    textSize(LARGETEXT);
    text(String.format("[%.2f, %.2f]", tx, ty), this.bounds.x+10, this.bounds.y+40);

  }

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
