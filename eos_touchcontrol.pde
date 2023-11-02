
UIBase root;

void setup() {
  fullScreen();
  orientation(LANDSCAPE); 
  textSize(36 * displayDensity);
  
  UIBase panel1 = new UIBase(0, 0, width-1, height-1, "panel1", UIBase.LAYOUT_HORIZONTAL);
  panel1.borderColor = color(255,10, 10);
  UIBase panel2 = new UIBase(0, 0, width-1, height-1, "panel2", UIBase.LAYOUT_HORIZONTAL);
  panel2.borderColor = color(10, 255, 10);
  
  int infoHeight = 100;
  root = new UIBase(0, infoHeight, width-1, height-1 - infoHeight, "root", UIBase.LAYOUT_HORIZONTAL);
  root.addChild(panel1);
  root.addChild(panel2);
  root.recalcLayout();
  
}

void draw() {
  background(0);
  if (touches.length > 0) {
    root.update(touches);
  }
  root.draw();

  fill(255);
  noStroke();
  text(String.format("%.2f", frameRate), 20, 75);
  drawTouches();
}

void drawTouches() {
  for (int i = 0; i < touches.length; i++) {
    float d = 100 * displayDensity;
    //fill(0, 255 * touches[i].pressure);
    fill(255, 0, 0);
    ellipse(touches[i].x, touches[i].y, d, d);
    fill(20, 255, 20);
    text(touches[i].id, touches[i].x + d/2, touches[i].y - d/2);
  } 


}

class UIBase {
  public int mode;
  public static final int LAYOUT_HORIZONTAL = 0;
  public static final int LAYOUT_VERTICAL = 1;
  public static final int LAYOUT_GRID = 2;
  public int layout;
  public Rect bounds;
  public ArrayList<UIBase> children;
  public int pad = 50;
  public Boolean lockAspectRatio = false; // TODO
  public color borderColor = color(128);
  String oscId;

  public UIBase(int _x, int _y, int _w, int _h, String _oscId, int _layout ) {
    this.bounds = new Rect(_x, _y, _w, _h);
    this.oscId = _oscId;
    this.layout = _layout;
    this.children = new ArrayList();

  }
  
  
  public void addChild(UIBase child) {
    children.add(child);
  }
  
  
  void recalcLayout() {
    int w, h;
    int nchild = this.children.size();
    if (nchild > 0) {
      if (this.layout == LAYOUT_HORIZONTAL) {  
        w = (this.bounds.w - pad*3)  / nchild; // - pad*(nchild-1);
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
        // TODO
      }
    }
  }


  public void update(TouchEvent.Pointer[] t) {
    float mx = t[0].x;
    float my = t[0].y;
    
    if (! this.bounds.containsPoint(mx, my)) return;

    // Do stuff
    // ...
  }


  public void draw() {
    stroke(64);
    noFill();
    // bounds
    stroke(this.borderColor);
    rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h);
    fill(255);
    text(this.oscId, this.bounds.x+5, this.bounds.y+36);
    for (int i=0; i<children.size(); i++) {
      UIBase child = children.get(i);
      child.draw();
    }

  }
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
