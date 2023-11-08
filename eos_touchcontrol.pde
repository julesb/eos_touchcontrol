

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
  public static final int LAYOUT_HORIZONTAL = 0;
  public static final int LAYOUT_VERTICAL = 1;
  public static final int LAYOUT_GRID = 2;
  public int layout;
  public Rect bounds;
  public ArrayList<UIBase> children;
  public int pad = 30;
  public Boolean lockAspectRatio = false; // TODO
  public color borderColor = color(128);
  String oscId;
  ArrayList<Integer> touchIds;

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
    int w, h;
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
    if (!touchIds.contains(id)) {
      touchIds.add(id);
    }
    for (int i=0; i<children.size(); i++) {
      UIBase c = children.get(i);
      if (id < touches.length &&
          c.bounds.containsPoint((int)touches[id].x, (int)touches[id].y)) {
        c.touchStarted(id);
      }
    }
  }
    
  
  public void touchEnded(int id) {
     this.touchIds.remove(Integer.valueOf(id));
    for (int c=0; c<children.size(); c++) {
      this.children.get(c).touchEnded(id);
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
    rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h);
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
          int d = 150;
          fill(borderColor);
          ellipse(px, py, d, d);
          
          textSize(LARGETEXT);
          fill(20, 255, 20);
          text(p.id, p.x - d/2, p.y - d/2);
        }
      }
    }
    
    for (int i=0; i<children.size(); i++) {
      UIBase child = children.get(i);
      child.draw();
    }

  }
  
} // End UIBase


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
  int x=0, y=0, w=0, h=0;

  public Rect() {}

  public Rect(int _x, int _y, int _w, int _h) {
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
