
import android.view.MotionEvent;

UIBase root;
ArrayList<Integer> touchMap;

int LARGETEXT;
int SMALLTEXT;


void setup() {
  fullScreen();
  orientation(LANDSCAPE);
  LARGETEXT = (int)(36 * displayDensity);
  SMALLTEXT = (int)(24 * displayDensity);
  
  textSize(SMALLTEXT);
  
  touchMap = new ArrayList<Integer>();
  
  UIBase panel1 = new UIBase(0, 0, width-1, height-1, "0.1", UIBase.LAYOUT_HORIZONTAL);
  panel1.borderColor = color(255,10, 10);
  
  UIBase panel2 = new UIBase(0, 0, width-1, height-1, "0.2", UIBase.LAYOUT_VERTICAL);
  panel2.borderColor = color(10, 255, 10);
  
    UIBase panel21 = new UIBase(0, 0, width-1, height-1, "0.2.1", UIBase.LAYOUT_HORIZONTAL);
    panel21.borderColor = color(255, 255, 10);

      Button button1 = new Button(0, 0, width-1, height-1, "Button1", Button.TOUCH_DOWN);
      button1.borderColor = color(255, 10, 10);
      Button button2 = new Button(0, 0, width-1, height-1, "Button2", Button.TOUCH_UP);
      button2.borderColor = color(10, 255, 10);
      Button button3 = new Button(0, 0, width-1, height-1, "Button3", Button.TOGGLE);
      button3.borderColor = color(10, 0, 255);
      //UIBase panel213 = new UIBase(0, 0, width-1, height-1, "0.2.1.3", UIBase.LAYOUT_HORIZONTAL);
      //panel213.borderColor = color(10, 255, 10);
      //UIBase panel214 = new UIBase(0, 0, width-1, height-1, "0.2.1.4", UIBase.LAYOUT_HORIZONTAL);
      //panel214.borderColor = color(10, 10, 255);

      panel21.addChild(button1);
      panel21.addChild(button2);
      panel21.addChild(button3);

      //panel21.addChild(panel213);
      //panel21.addChild(panel214);

    UIBase panel22 = new UIBase(0, 0, width-1, height-1, "0.2.2", UIBase.LAYOUT_HORIZONTAL);
    panel22.borderColor = color(10, 255, 255);
  
    UIBase panel23 = new UIBase(0, 0, width-1, height-1, "0.2.3", UIBase.LAYOUT_HORIZONTAL);
    panel23.borderColor = color(255, 10, 255);

      UIBase panel231 = new UIBase(0, 0, width-1, height-1, "0.2.3.1", UIBase.LAYOUT_HORIZONTAL);
      panel231.borderColor = color(255, 10, 10);
      UIBase panel232 = new UIBase(0, 0, width-1, height-1, "0.2.3.2", UIBase.LAYOUT_HORIZONTAL);
      panel232.borderColor = color(255, 128, 10);
      UIBase panel233 = new UIBase(0, 0, width-1, height-1, "0.2.3.3", UIBase.LAYOUT_HORIZONTAL);
      panel233.borderColor = color(10, 255, 10);
      UIBase panel234 = new UIBase(0, 0, width-1, height-1, "0.2.3.4", UIBase.LAYOUT_HORIZONTAL);
      panel234.borderColor = color(10, 10, 255);

      panel23.addChild(panel231);
      panel23.addChild(panel232);
      panel23.addChild(panel233);
      panel23.addChild(panel234);

  panel2.addChild(panel21);
  panel2.addChild(panel22);
  panel2.addChild(panel23);

  UIBase panel3 = new UIBase(0, 0, width-1, height-1, "0.3", UIBase.LAYOUT_HORIZONTAL);
  panel3.borderColor = color(10, 10, 255);
  
  int infoHeight = 100;
  root = new UIBase(0, infoHeight, width-1, height-1 - infoHeight, "0", UIBase.LAYOUT_HORIZONTAL);
  root.addChild(panel1);
  root.addChild(panel2);
  root.addChild(panel3);
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




class UIBase {
  public int mode;
  public static final int LAYOUT_NONE = 0;
  public static final int LAYOUT_HORIZONTAL = 1;
  public static final int LAYOUT_VERTICAL = 2;
  public static final int LAYOUT_GRID = 3;
  public int layout;
  public Rect bounds;
  public ArrayList<UIBase> children;
  public int pad = 30;
  public Boolean lockAspectRatio = false; // TODO
  public color borderColor = color(128);
  String oscId;
  private ArrayList<Integer> touchIds;
  PVector[] touchPositions = new PVector[10];


  public UIBase(int _x, int _y, int _w, int _h, String _oscId, int _layout ) {
    this.bounds = new Rect(_x, _y, _w, _h);
    this.oscId = _oscId;
    this.layout = _layout;
    this.children = new ArrayList<UIBase>();
    this.touchIds = new ArrayList<Integer>();
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
         // TODO 
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

  public void draw() {
    stroke(64);
    noFill();
    // bounds
    stroke(this.borderColor);
    if (touchIds.size() > 0) {
      strokeWeight(10);
    }
    else {
      strokeWeight(1);
    }
    rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h, 16 );
    fill(255);
    String info = String.format("%s:  %s",
                   this.oscId, formatTouchIds(this.touchIds));
    //String info = String.format("%s: t: %d: %s",
    //               this.oscId, this.touchIds.size(), formatTouchIds(this.touchIds));

    //if (textWidth(info) < this.bounds.w) {
      textSize(SMALLTEXT);
      text(info, this.bounds.x+7, this.bounds.y+26);
    //}
    if (children.size() == 0) {
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

    int buttonMode = 0;
    Boolean toggleState = false;

    public Button(int _x, int _y, int _w, int _h, String _oscId, int _mode) {
      super(_x, _y, _w, _h, _oscId, UIBase.LAYOUT_NONE);
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
        print(String.format("%s pressed (TOUCH_DOWN)", this.oscId));
      }
    }

    @Override
    public void touchEnded(int id) {
        PVector p = touchPositions[id];
        if (p != null) {
          if (buttonMode == TOUCH_UP && this.bounds.containsPoint(p.x, p.y)) {
            // Trigger button action
            print(String.format("%s pressed (TOUCH_UP) id=%d", this.oscId, id));
          }
        }
        super.touchEnded(id);
    }

    @Override
    public void draw() {
      if (this.buttonMode == TOGGLE && this.toggleState) {
        noStroke();
        fill(64);
        rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h, 16 );
      }
      super.draw();
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
