
class UIBase {
  public int mode;
  public static final int LAYOUT_NONE = 0;
  public static final int LAYOUT_HORIZONTAL = 1;
  public static final int LAYOUT_VERTICAL = 2;
  public static final int LAYOUT_GRID = 3;
  public int layout;
  public int pad = 8;
  public Rect bounds;
  public ArrayList<UIBase> children;
  public Boolean lockAspectRatio = false; // TODO
  public color borderColor = color(128);
  String oscId;
  Boolean oscEnabled = false;
  String label;
  ArrayList<Integer> touchIds;
  PVector[] touchPositions = new PVector[10];
  int gridRows = 4;
  int gridCols = 4;

  public UIBase(float x, float y, float w, float h, String oscId, int layout ) {
    this.bounds = new Rect(x, y, w, h);
    this.oscId = oscId;
    this.label = oscId;
    this.layout = layout;
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

  public void drawLabel() {
      fill(255);
      String info = this.label;
      textSize(LARGETEXT);
      text(info, this.bounds.x+16, this.bounds.y+40);  
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
      drawLabel();

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


class TabContainer extends UIBase {
  int activeTabIndex = 0;
  int tabBarHeight = 120;
  UIBase tabBar;
  UIBase contentArea;

  public TabContainer(int x, int y, int w, int h) {
    super(x, y, w, h, "tabs", UIBase.LAYOUT_NONE);
    tabBar = new UIBase(0, 0, 100, 100, "tabbuttons", UIBase.LAYOUT_HORIZONTAL);
    tabBar.borderColor = color(0);
    contentArea = new UIBase(0, 0, 100, 100, "contentarea", UIBase.LAYOUT_HORIZONTAL);
    contentArea.borderColor = color(0);
    recalcLayout();
  }

  @Override
  void addChild(UIBase child) {
    int tabIndex = tabBar.children.size();
    contentArea.addChild(child);
    // Set up the button
    Button b = new Button(child.oscId, Button.TOGGLE, new Runnable() {
      public void run() {
        setActiveTab(tabIndex);
      }
    });
    b.label = child.label;
    //b.borderColor = child.borderColor;
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
    if (contentArea.children.size() > 0) {
      UIBase activeTab = contentArea.children.get(activeTabIndex);
      activeTab.bounds.x = contentArea.bounds.x;
      activeTab.bounds.y = contentArea.bounds.y;
      activeTab.bounds.w = contentArea.bounds.w;
      activeTab.bounds.h = contentArea.bounds.h;
      activeTab.recalcLayout();
    }
    
    // TabContainer doesn't use the standard `` children array. only tabBar and contentArea
  }

  void setActiveTab(int tabIndex) {
    println("setActiveTab:", tabIndex);
    if (tabIndex < tabBar.children.size()) {
      this.activeTabIndex = tabIndex;
      for (int i=0; i<tabBar.children.size(); i++) {
        Button button = (Button)tabBar.children.get(i);
        if (this.activeTabIndex == i) {
          button.toggleState = true;
        }
        else {
          button.toggleState = false;
        }
      }
      recalcLayout();
    }
  }

  @Override
  void draw() {
    tabBar.draw();
    contentArea.children.get(activeTabIndex).draw();
  }

  @Override
  public void touchStarted(int id) {
    super.touchStarted(id);
    tabBar.touchStarted(id);
    contentArea.children.get(activeTabIndex).touchStarted(id);
  }

  @Override
  public void touchEnded(int id) {
    super.touchEnded(id);
    tabBar.touchEnded(id);
    contentArea.children.get(activeTabIndex).touchEnded(id);
  }

  @Override
  public void touchMoved(MotionEvent e) {
    super.touchMoved(e);
    tabBar.touchMoved(e);
    contentArea.children.get(activeTabIndex).touchMoved(e);
  }
}


class Button extends UIBase {
  public static final int TOUCH_DOWN = 0; // triggers on touch
  public static final int TOUCH_UP   = 1; // triggers on touch
  public static final int TOGGLE     = 2; // triggers on touch, toggle state
  private final Runnable onPressCallback;

  
  int recentTouchCountdown = 0;

  int buttonMode = 0;
  Boolean toggleState = false;

  //public Button(int x, int y, int w, int h, String oscId, int mode) {
  public Button(int x, int y, int w, int h, String oscId, int mode, Runnable onPressCallback) {
    super(x, y, w, h, oscId, UIBase.LAYOUT_NONE);
    this.buttonMode = mode;
    this.onPressCallback = onPressCallback;
  }

  public Button(String oscId, int buttonMode) {
    //super(0, 0, 100, 100, _oscId, _mode, null);
    this(0, 0, 100, 100, oscId, buttonMode, null);
    //this.buttonMode = buttonMode;
  }
  
  public Button(String oscId, int buttonMode, Runnable onPressCallback) {
    //super(0, 0, 100, 100, _oscId, _mode, null);
    this(0, 0, 100, 100, oscId, buttonMode, onPressCallback);
    //this.buttonMode = buttonMode;
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
      if(this.onPressCallback != null) {
        this.onPressCallback.run();
      }
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
          if(this.onPressCallback != null) {
            this.onPressCallback.run();
          }
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
      recentTouchCountdown-=2;
    }
    super.draw();
  }
}


class Slider extends UIBase {
  public static final int VERTICAL = 0;
  public static final int HORIZONTAL = 1;
  int direction = 0;
  float value = 0.0;
  float rangeMin = 0.0;
  float rangeMax = 1.0;
  float vpad = 200;
  color sliderColor = color(0, 255, 32, 192);
  float sliderMinY = 0.0;
  float sliderMaxY = 1.0;
  float sliderHandleSize = 25;
  int primaryTouchId = -1;
 
  public Slider(String oscId, int direction) {
    super(oscId, UIBase.LAYOUT_NONE);
    this.direction = direction;
  }

  @Override
  public void draw() {
    sliderMinY = bounds.y+vpad;
    sliderMaxY = bounds.y+bounds.h-vpad/2;

    float cx = bounds.x + bounds.w/2;
    float cy = bounds.y + bounds.y/2;
    float valy = sliderMaxY - this.value * (sliderMaxY - sliderMinY);
    
    // slider range line
    strokeWeight(8);
    stroke(96);
    line(cx, sliderMinY, cx, valy-sliderHandleSize/2);
    stroke(sliderColor);
    line(cx, valy, cx, sliderMaxY);
    
    // draw slider handle
    noStroke();
    fill(sliderColor);
    ellipse(cx, valy, sliderHandleSize, sliderHandleSize);
    
    //stroke(0,255,32);
    //strokeWeight(4);
    //line(cx-25, valy, cx+25, valy);
    ////line(bounds.x+pad, valy, bounds.x+bounds.w-pad, valy);
    
    // draw value text
    textSize(LARGETEXT*1.25);
    String valText = String.format("%.2f", this.value);
    text(valText, cx - textWidth(valText)/2, bounds.y + vpad/2 + LARGETEXT);
        
    strokeWeight(2);
    stroke(96);
    float gradw = 10;
    float gradc = sliderMinY + (sliderMaxY-sliderMinY) / 2.0;
    //line(bounds.x+pad*4, sliderMinY, cx, sliderMinY);    
    //line(bounds.x+pad*4, sliderMaxY, cx, sliderMaxY);
    line(bounds.x+pad*4, gradc, cx, gradc);
    //line(cx-gradw, sliderMinY, cx+gradw, sliderMinY);    
    //line(cx-gradw, sliderMaxY, cx+gradw, sliderMaxY);
    //line(cx-gradw, gradc, cx+gradw, gradc);
    
    //fill(255);
    //noStroke();
    //textSize(SMALLTEXT);
    //text("1", bounds.x+pad, sliderMinY+SMALLTEXT);
    //text("0", bounds.x+pad, sliderMaxY+SMALLTEXT);
    //text("0.5", bounds.x+pad, gradc+SMALLTEXT);

    
    
    strokeWeight(1);
    drawBounds();
    drawLabel();
    //super.draw();
  }

  @Override
  public void touchMoved(MotionEvent e) {
    super.touchMoved(e);
    if (touchIds.size() > 0) {
      int id = touchIds.get(0);
      if (touchPositions[id] != null) {
        primaryTouchId = id;
        PVector p = touchPositions[id];
        float ny = (p.y - this.bounds.y - vpad*1) / (sliderMaxY-sliderMinY);
        value = 1.0 - max(0.0, min(1.0, ny));
      }
      else {
        primaryTouchId = -1;
      }
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
    line(ctlcx, ctlcy, dotx, doty);
    stroke(240);
    ellipse(ctlcx+pn.x, ctlcy+pn.y, 16, 16);

    //line(ctlcx, ctlcy, ctlcx+pn.x, ctlcy+pn.y);

    fill(255);
    noStroke();
    textSize(LARGETEXT);
    text(String.format("[%.2f, %.2f]", tx, ty), this.bounds.x+10, this.bounds.y+40);

  }

}
