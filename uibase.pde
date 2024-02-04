import java.math.BigDecimal;

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
  public float borderWeight = 1;
  public Boolean borderVisible = false;
  public color textColor = color(255);
  
  String oscId;
  Boolean oscEnabled = false;
  Boolean useDefaultOsc = false; // enable base class OSC messaging - touchePositions array
  String label;
  ArrayList<Integer> touchIds;
  PVector[] touchPositions = new PVector[10];
  int gridRows = 4;
  int gridCols = 4;

  public UIBase(float x, float y, float w, float h, String oscId, int layout ) {
    this.bounds = new Rect(x, y, w, h);
    this.oscId = oscId;
    this.label = "";
    this.layout = layout;
    this.children = new ArrayList<UIBase>();
    this.touchIds = new ArrayList<Integer>();
  }

  public UIBase(String _oscId, int _layout ) {
    this(0, 0, 100, 100, _oscId, _layout);
  }

  public UIBase(String oscId) {
    this(0, 0, 100, 100, oscId, UIBase.LAYOUT_NONE);
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
          child.bounds.set(this.bounds.x + pad + i * (w+pad), this.bounds.y+pad, w, h);
          child.recalcLayout();
        }
      }
      else if (this.layout == LAYOUT_VERTICAL) {
        w = this.bounds.w - pad*2;        
        h = (this.bounds.h - pad*(nchild+1)) / nchild;
        for (int i=0; i<nchild; i++) {
          UIBase child = children.get(i);
          child.bounds.set(this.bounds.x+pad, this.bounds.y + pad + i * (h+pad), w, h);
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
          child.bounds.set(x, y, w, h);
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
    if (useDefaultOsc) {
      sendDefaultOsc();
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
    for (int c=0; c<children.size(); c++) {
      this.children.get(c).touchEnded(id);
    }
    this.touchIds.remove(Integer.valueOf(id));
    touchPositions[id] = null;
    if (useDefaultOsc) {
      sendDefaultOsc();
    }
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
    if (useDefaultOsc) {
      sendDefaultOsc();
    }

  }

  public void sendDefaultOsc() {
    ArrayList<PVector> positions = new ArrayList();
    for (int i = 0; i < touchPositions.length; i++) {
      if (touchPositions[i] != null) {
        positions.add(touchPositions[i]);
      }
    }
    int numPoints = positions.size();
    float[] points;
    if (numPoints == 0) {
      points = new float[]{ 0, 0, 0, 0, 0 };
    }
    else {
      points = new float[numPoints*5];
      //points = new float[(numPoints+1)*5];  // plus one for center blank point
      
      int idx = 0;
      //points[idx++] = 0.0f;
      //points[idx++] = 0.0f;
      //points[idx++] = 0.0f;
      //points[idx++] = 0.0f;
      //points[idx++] = 0.0f;      
     
      float ar = bounds.w / bounds.h;
      for (PVector p : positions) {
        float nx = (p.x - bounds.x) / bounds.w;
        float ny = (p.y - bounds.y) / bounds.h;
        nx = (nx-0.5) * 2.0;
        ny = (ny-0.5) * 2.0;
        nx *= -1.0;
        //ny *= -1.0;
        nx *= ar;
        
        points[idx++] = nx;
        points[idx++] = ny;
        points[idx++] = 1.0f;
        points[idx++] = 1.0f;
        points[idx++] = 1.0f;      
      }
    
    }
    
    queueOscSendArray(points, oscId + "/points");
  }

  public void drawBounds() {
    stroke(borderColor);
    strokeWeight(borderWeight);
    noFill();
    rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h, 32 );

  }

  public void drawLabel() {
      fill(textColor);
      String info = this.label;
      textSize(LARGETEXT);
      textAlign(BASELINE);
      text(info, this.bounds.x+16, this.bounds.y+40);  
  }

  public void draw() {
    if (touchIds.size() > 0 && children.size() == 0) {
      strokeWeight(10);
    }
    else {
      strokeWeight(1);
    }
    if (borderVisible) {
      drawBounds();
    }
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
  
  public void setValue(Object value) {
  }

  color hsvToRgb(float h, float s, float v) {
    float r, g, b;

    int i = (int) Math.floor(h * 6);
    float f = h * 6 - i;
    float p = v * (1 - s);
    float q = v * (1 - f * s);
    float t = v * (1 - (1 - f) * s);

    switch (i % 6) {
        case 0: r = v; g = t; b = p; break;
        case 1: r = q; g = v; b = p; break;
        case 2: r = p; g = v; b = t; break;
        case 3: r = p; g = q; b = v; break;
        case 4: r = t; g = p; b = v; break;
        case 5: r = v; g = p; b = q; break;
        default: throw new IllegalArgumentException("Something went wrong in the HSV to RGB conversion.");
    }
    return color(r * 255, g * 255, b * 255);
  }  

} // End UIBase


class TabContainer extends UIBase {
  int activeTabIndex = 0;
  int tabBarHeight = 120;
  //color activeTabTextColor = color(255);
  //color inactiveTabTextColor = color(128);
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
    b.requireSingleTouch = true;
    b.onFillColor = color(32);
    b.offBorderColor = color(64);
    b.label = child.label;
    //b.borderColor = child.borderColor;
    tabBar.addChild(b);
    tabBar.recalcLayout();
    //contentArea.recalcLayout();
    recalcLayout();
  }

  @Override
  void recalcLayout() {
    tabBar.bounds.set(bounds.x, bounds.y, bounds.w, tabBarHeight);
    //tabBar.bounds.x = bounds.x;
    //tabBar.bounds.y = bounds.y;
    //tabBar.bounds.w = bounds.w;
    //tabBar.bounds.h = tabBarHeight;
    tabBar.recalcLayout();
    contentArea.bounds.set(bounds.x, bounds.y + tabBarHeight+pad,
                           bounds.w, bounds.h - tabBarHeight-pad);
    //contentArea.bounds.x = bounds.x;
    //contentArea.bounds.y = bounds.y + tabBarHeight+pad;
    //contentArea.bounds.w = bounds.w;
    //contentArea.bounds.h = bounds.h - tabBarHeight-pad;
    if (contentArea.children.size() > 0) {
      UIBase activeTab = contentArea.children.get(activeTabIndex);
      activeTab.bounds.set(contentArea.bounds.x, contentArea.bounds.y,
                           contentArea.bounds.w, contentArea.bounds.h);
      //activeTab.bounds.x = contentArea.bounds.x;
      //activeTab.bounds.y = contentArea.bounds.y;
      //activeTab.bounds.w = contentArea.bounds.w;
      //activeTab.bounds.h = contentArea.bounds.h;
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
  private Runnable onPressCallback;

  color onBorderColor = color(96);
  color offBorderColor = color(64);
  color onFillColor = color(0, 255, 32, 128);
  color offFillColor = color(0, 255, 32, 32);
  color onTextColor = color(255);
  color offTextColor = color(142);
  
  float recentTouchCountdown = 0;
  float releaseFadeSecs = 0.5;
  float oscValue = 0.0;

  int buttonMode = 0;
  Boolean toggleState = false;
  Boolean requireSingleTouch = false;

  public Button(int x, int y, int w, int h, String oscId, int mode, Runnable onPressCallback) {
    super(x, y, w, h, oscId, UIBase.LAYOUT_NONE);
    this.buttonMode = mode;
    this.onPressCallback = onPressCallback;
  }

  public Button(String oscId, int buttonMode) {
    this(0, 0, 100, 100, oscId, buttonMode, null);
  }
  
  public Button(String oscId, int buttonMode, Runnable onPressCallback) {
    this(0, 0, 100, 100, oscId, buttonMode, onPressCallback);
  }



  @Override
  public void touchStarted(int id) {
    super.touchStarted(id);
    if (requireSingleTouch && touches.length != 1) {
      return;
    }
    
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

      // ensure screen redraw while button fading
      int pendingFrameCount;
      if (buttonMode == TOGGLE) {
        if (oscEnabled) {
          queueOscSend(toggleState? 1.0:0.0, oscId);
        }
        if (toggleState) {
          pendingFrameCount = 1;

        }
        else {
          pendingFrameCount = (int)(gTargetFrameRate * releaseFadeSecs);
        }
      }
      else if (buttonMode == TOUCH_DOWN) {
        if (oscEnabled) {
          queueOscSend(1.0, oscId);
        }
        pendingFrameCount = (int)(gTargetFrameRate * releaseFadeSecs);
      }
      else {
        pendingFrameCount = 0;
      }
      recentTouchCountdown = pendingFrameCount;
      if (pendingFrameCount > gPendingAnimFrames) {
        gPendingAnimFrames = pendingFrameCount;
      }
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
        
        if (oscEnabled) {
          queueOscSend(1.0, oscId);
        }
        // ensure screen redraw while button fading
        int pendingFrameCount = (int)(gTargetFrameRate * releaseFadeSecs);
        recentTouchCountdown = pendingFrameCount;
        if (pendingFrameCount > gPendingAnimFrames) {
          gPendingAnimFrames = pendingFrameCount;
        }
      }
    }
    super.touchEnded(id);
  }

  @Override
  public void setValue(Object value) {
    float floatValue = (float)value;
        if (buttonMode == TOGGLE) {
          toggleState = floatValue == 0.0? false: true;
    }
  }
    
  @Override
  public void drawLabel() {
      fill(textColor);
      String info = this.label;
      textSize(LARGETEXT);
      textAlign(CENTER,CENTER);
      text(info, bounds.x+bounds.w/2, bounds.y+bounds.h/2);  
      //text(info, bounds.x+bounds.w/2-textWidth(info)/2, bounds.y+bounds.h/2 + LARGETEXT/3);  
      //text(info, this.bounds.x+16, this.bounds.y+40);  
  }
  
  @Override
  public void draw() {
    if (this.buttonMode == TOGGLE && this.toggleState) {
      noStroke();
      stroke(borderColor);
      fill(onFillColor);
      rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h, 16 );
    }
    else if (recentTouchCountdown >= 0) {
      fill(onFillColor, recentTouchCountdown * 255.0/gTargetFrameRate/releaseFadeSecs);
      noStroke();
      rect(this.bounds.x, this.bounds.y, this.bounds.w, this.bounds.h, 32 );
      recentTouchCountdown--;
    }

    borderColor = toggleState? onBorderColor: offBorderColor;
    drawBounds();

    textColor = toggleState? onTextColor: offTextColor;
    drawLabel();
    //super.draw();
  }
  
  public void setOnPressCallback(Runnable callback) {
    this.onPressCallback = callback;
  } 
   
}


class ButtonGroup extends UIBase {
  int activeButtonIndex = -1;
  private Runnable onStateChangeCallback;
  public static final int BUTTONMODE_TRIGGER = 0;
  public static final int BUTTONMODE_MUTEX = 1;
  public static final int BUTTONMODE_TOGGLE = 2;
  int buttonMode = BUTTONMODE_TRIGGER;
  
  
  public ButtonGroup(String oscId, int buttonMode, int layout) {
    super(oscId, layout);
    this.layout = layout;
    this.buttonMode = buttonMode;
  }
  
  @Override
  void draw() {
    super.draw();
    //children.get(0).draw();
  }  
  
  void setActiveButton(int index) {
    if (buttonMode != BUTTONMODE_MUTEX) {
      return;
    }
    println("setActiveButton:", index);
    if (index < children.size()) {
      this.activeButtonIndex = index;
      for (int i=0; i<children.size(); i++) {
        UIBase c = children.get(i);
        if (c instanceof Button) {
          Button button = (Button)c;
          if (this.activeButtonIndex == i) {
            button.toggleState = true;
          }
          else {
            button.toggleState = false;
          }
        }
      }
      recalcLayout();
    }
  }
  
  @Override
  void addChild(UIBase child) {
    if (child instanceof Button) {
      Button newButton = (Button)child;
      int tabIndex = children.size();
      // Set up the button
      if (buttonMode == BUTTONMODE_MUTEX || buttonMode == BUTTONMODE_TOGGLE) {
        newButton.buttonMode = Button.TOGGLE;
      }
      else {
        newButton.buttonMode = Button.TOUCH_DOWN;      
      }
      
      //if (buttonMode == BUTTONMODE_MUTEX) {
      newButton.setOnPressCallback(new Runnable() {
        public void run() {
          setActiveButton(tabIndex);
          if (onStateChangeCallback != null) {
            onStateChangeCallback.run();
          }
        }
      });
    //}
      children.add(newButton);
    }
    else {
      children.add(child);
    }
    recalcLayout();
  }
  
  public void setOnStateChangeCallback (Runnable callback) {
    this.onStateChangeCallback = callback;
  }

}

class Slider extends UIBase {
  public static final int VERTICAL = 0;
  public static final int HORIZONTAL = 1;
  int direction = 0;
  float value = 0.0;
  float pValue = 0.0;
  float rangeMin = 0.0;
  float rangeMax = 1.0;
  String numberFormat = "%.3f";
  float hpad = 200; // used with horizontal slider only
  float vpad = 200; // used with vertical slider only
  color sliderColor = color(0, 255, 32, 192);
  private float sliderMinX = 0.0;
  private float sliderMaxX = 1.0;
  private float sliderMinY = 0.0;
  private float sliderMaxY = 1.0;
  float sliderHandleSize = 25;
  int primaryTouchId = -1;
  Boolean forceInteger = false; 
 
  public Slider(String oscId, int direction) {
    super(oscId, UIBase.LAYOUT_NONE);
    this.direction = direction;
  }

  @Override
  void recalcLayout() {
    super.recalcLayout();
    sliderMinX = bounds.x+hpad;
    sliderMaxX = bounds.x+bounds.w-hpad/2;
    sliderMinY = bounds.y+vpad;
    sliderMaxY = bounds.y+bounds.h-vpad/2;
    
  }  

  @Override
  public void draw() {
    
    if (this.direction == VERTICAL) {
      drawVertical();
    }
    else {
      drawHorizontal();
    }
    strokeWeight(1);
    if (borderVisible) {
      drawBounds();
    }
    drawLabel();
    // this is to allow sending if the slider is changed by one of the 
    // buttons instead of a direct touch event
    //if (value != pValue && oscEnabled) {
    //  float mappedValue = rangeMin + value * (rangeMax - rangeMin);
    //  queueOscSend(mappedValue, oscId);
    //  pValue = value;
    //}
  }

  @Override
  public void drawLabel() {
    Boolean useLabel = this.label.length() > 0;
    String info = useLabel? label : oscId;  
    int txtSize = useLabel? LARGETEXT : SMALLTEXT;
    fill(255);
    textSize(txtSize);
    textAlign(BASELINE, TOP);
    if (direction == VERTICAL) {
      text(info, this.bounds.x+pad, this.bounds.y+pad);  
    }
    else {
      if (useLabel) {
        text(info, this.bounds.x+pad*2, this.bounds.y+pad*1);          
      }
      else {
        text(info, this.bounds.x+pad, this.bounds.y+pad);                  
      }
    }   
  }

  void drawHorizontal() {
    float cy = bounds.y + bounds.h/2;
    float valx = sliderMinX + this.value * (sliderMaxX - sliderMinX);
    
    // slider range line
    strokeWeight(8);
    stroke(48);
    line(valx+sliderHandleSize/2, cy, max(sliderMaxX+sliderHandleSize/2, sliderMaxX), cy);
    // value indicator line
    stroke(sliderColor);
    line(sliderMinX, cy, valx, cy);
    // draw slider handle
    noStroke();
    fill(sliderColor);
    ellipse(valx, cy, sliderHandleSize, sliderHandleSize);
    // draw value text
    textAlign(BASELINE, CENTER);
    textSize(LARGETEXT*1.2);
    fill(0,255,0);
    float mappedValue = rangeMin + value * (rangeMax-rangeMin);

    String valText = String.format(numberFormat, mappedValue);
    text(valText, bounds.x + pad*4, cy);
  }

  void drawVertical() {
    float cx = bounds.x + bounds.w/2;
    float valy = sliderMaxY - this.value * (sliderMaxY - sliderMinY);
    
    // slider range line
    strokeWeight(8);
    stroke(48);
    line(cx, min(sliderMinY-sliderHandleSize/2, sliderMinY), cx, valy-sliderHandleSize/2);
    // value indicator line
    stroke(sliderColor);
    line(cx, valy, cx, sliderMaxY);
    // draw slider handle
    noStroke();
    fill(sliderColor);
    ellipse(cx, valy, sliderHandleSize, sliderHandleSize);
    // draw value text
    textAlign(BASELINE);
    textSize(LARGETEXT*1.2);
    fill(0,255,0);
    float mappedValue = rangeMin + value * (rangeMax-rangeMin);
    String valText = String.format("%.3f", mappedValue);
    text(valText, cx - textWidth(valText)/2, bounds.y + vpad/2 + LARGETEXT);
  }


  @Override
  public void touchMoved(MotionEvent e) {
    super.touchMoved(e);

    if (touchIds.size() > 0) {
      int id = touchIds.get(0);
      if (touchPositions[id] != null) {
        primaryTouchId = id;
        PVector p = touchPositions[id];
        float range = rangeMax - rangeMin;
        if (this.direction == VERTICAL) {
          float ny = 1.0 - (p.y - this.bounds.y - vpad*1) / (sliderMaxY-sliderMinY) * range;
          setValue(ny);
          //value = 1.0 - max(0.0, min(1.0, ny));
          //value = forceInteger? ((float)Math.floor(value*range) / range) : value;
        }
        else {
          float nx = (p.x - this.bounds.x - hpad*1) / (sliderMaxX-sliderMinX) * range;
          setValue(nx);
          //value = max(0.0, min(1.0, nx));
          //value = forceInteger? ((float)Math.floor(value*range) / range) : value;
        }

        if (value != pValue && oscEnabled) {
          float mappedValue = rangeMin + value * (rangeMax - rangeMin);
          queueOscSend(mappedValue, oscId);
          pValue = value;
        }
      }
      else {
        primaryTouchId = -1;
      }
    }
  }
  
  public void setValue(Object value) {
    
    if (value instanceof Float) {
      float floatValue = (float)value;
      float range = rangeMax - rangeMin;
      floatValue = max(rangeMin, min(rangeMax, floatValue)) / range;
      //if (this.direction == VERTICAL) {
      //  floatValue = (rangeMax - max(rangeMin, min(rangeMax, floatValue))) / range;
      //}
      //else {
      //  floatValue = max(rangeMin, min(rangeMax, floatValue)) / range;
      //}
      floatValue = forceInteger? ((float)Math.floor(floatValue*range) / range) : floatValue;
      this.value = floatValue;
    }
  }

}


class Label extends UIBase {
  public static final int HALIGN_LEFT = 0;
  public static final int HALIGN_CENTER = 1;
  public static final int HALIGN_RIGHT = 2;
  int halign = HALIGN_LEFT;
  float textPosX, textPosY;
  public Label(String label) {
    super("label");
    this.label = label;
  }
  
  @Override
  void draw() {
    //super.draw();
    textAlign(BASELINE, CENTER);
    textSize(LARGETEXT);
    fill(textColor);
    text(label, textPosX, textPosY);
  }
  
  @Override
  void recalcLayout() {
    super.recalcLayout();
    textSize(LARGETEXT);
    float textw = textWidth(label);
    textPosY = bounds.y + (bounds.h/2);
    if(halign == HALIGN_LEFT) {
      textPosX = bounds.x + pad;
    }
    else if (halign == HALIGN_CENTER) {
      textPosX = bounds.x + bounds.w/2;
    }
    else if (halign == HALIGN_RIGHT) {
      textPosX = bounds.x + bounds.w - pad - textw;
    }
  }
  
  @Override
  void setValue(Object value) {
    if (value instanceof String) {
      this.label = (String)value;
    }
  }
}

class DragNumberT2 extends UIBase {
  float initialValue;
  float currentValue;
  PVector initialTouchPoint;
  boolean isAdjusting = false;
  float rangeMin = 0.0;
  float rangeMax = 1.0;
  float sensitivity = 0.1;
 
  DragNumberT2(String oscId, String label) {
    super(oscId, UIBase.LAYOUT_HORIZONTAL);
    this.initialValue = 0.0;
    this.currentValue = 0.0;
    this.label = label;
    this.borderVisible = false;
    addChild(new Label(label));
    
    DragNumberControlT2 numCtrl = new DragNumberControlT2(oscId);
    numCtrl.borderVisible = true;    
    addChild(numCtrl);
  }
}

class DragNumber extends UIBase {
  float initialValue;
  float currentValue;
  PVector initialTouchPoint;
  boolean isAdjusting = false;
  float rangeMin = 0.0;
  float rangeMax = 1.0;
  float sensitivity = 0.1;
  DragNumberControl numCtrl;
 
  DragNumber(String oscId, String label, double value, double rangeMin, double rangeMax) {
    super(oscId, UIBase.LAYOUT_HORIZONTAL);
    this.initialValue = 0.0;
    //this.currentValue = 0.0;
    this.label = label;
    this.borderVisible = false;
    addChild(new Label(label));
    
    numCtrl = new DragNumberControl(oscId);
    numCtrl.rangeMin = rangeMin;
    numCtrl.rangeMax = rangeMax;
    numCtrl.currentValue = value;
    numCtrl.borderVisible = false;    
    addChild(numCtrl);
  }
}

class DragNumber2 extends UIBase {
  float initialValue;
  float currentValue;
  PVector initialTouchPoint;
  boolean isAdjusting = false;
  float rangeMin = 0.0;
  float rangeMax = 1.0;
  float sensitivity = 0.1;
  DragNumberControl numCtrl1;
  DragNumberControl numCtrl2;
 
  DragNumber2(String oscId1, String oscId2, String label, double value1,
              double value2, double rangeMin, double rangeMax) {
    super("", UIBase.LAYOUT_HORIZONTAL);
    this.initialValue = 0.0;
    //this.currentValue = 0.0;
    this.label = label;
    this.borderVisible = false;
    addChild(new Label(label));
    
    numCtrl1 = new DragNumberControl(oscId1);
    numCtrl1.rangeMin = rangeMin;
    numCtrl1.rangeMax = rangeMax;
    numCtrl1.currentValue = value1;
    numCtrl1.borderVisible = false;    
    numCtrl2 = new DragNumberControl(oscId2);
    numCtrl2.rangeMin = rangeMin;
    numCtrl2.rangeMax = rangeMax;
    numCtrl2.currentValue = value2;
    numCtrl2.borderVisible = false;    
    addChild(numCtrl1);
    addChild(numCtrl2);
  }
}


class DragNumberControl extends UIBase {
  double initialValue = 0.0;
  double currentValue = 0.0;
  double prevValue = 0.0;
  PVector initialTouchPoint;
  PVector adjustDelta = new PVector(0,0);
  boolean isAdjusting = false;
  boolean isCalibrating = false;
  double rangeMin = 0.0;
  double rangeMax = 1.0;
  float sensitivity = 0.1;
  int numDecimals = 3;
  int numInts = 5;
  int precisionIndex = 1;
  double adjustIncrement = 1.0;
  Rect[] digitHitboxes;

  public DragNumberControl(String oscId) {
    super(oscId);
    this.textColor = color(0, 255,0);
    digitHitboxes = makeDigitHitboxes();
  }


  void draw() {
    textSize(LARGETEXT*1.5);
    String format = String.format("%% .%df", numDecimals);
    String valueText = String.format(format, currentValue);
    float textw = textWidth(valueText);
    float xpos = bounds.x + bounds.w - pad*2 - textw;
    float ypos = bounds.y + bounds.h/2;
    
    stroke(borderColor);
    //drawBounds();
    
    fill(textColor);
    textAlign(BASELINE, CENTER);
    text(valueText, xpos, ypos);
    
    // draw precision indicator
    if (digitHitboxes != null && precisionIndex < digitHitboxes.length && precisionIndex >= 0) {
      Rect hb = digitHitboxes[precisionIndex];
      stroke(0, 255,0);
      rect(hb.x+5, hb.y+hb.h/2+LARGETEXT*1.5/2, 20, 2);
    }
    
    if (prevValue != currentValue) {
      queueOscSend((float)currentValue, oscId);
      prevValue = currentValue;
    }
    
    //if (digitHitboxes != null) {
    //  for(int i=0; i < digitHitboxes.length; i++) {
    //    Rect r = digitHitboxes[i];
    //    stroke(255,255,0);
    //    noFill();
    //    rect(r.x, r.y, r.w, r.h);
    //  }
    //}
  }
  
  private Rect[] makeDigitHitboxes() {
    textSize(LARGETEXT*1.5);
    int numBoxes = numDecimals + numInts;
    Rect[] boxes = new Rect[numBoxes];
    float charWidth = textWidth("3");
    float x = bounds.x+bounds.w-pad*2 - charWidth;
    for (int i=0; i< numBoxes; i++) {
      float bx = x+2;
      Rect r = new Rect(bx, bounds.y, charWidth-4, bounds.h);
      boxes[i] = r;
      
      if (i == numDecimals-1) {
        x -= charWidth * 1.5;
      }
      else {
        x -= charWidth;
      }
    }
    return boxes;
  }
  
  @Override
  public void touchStarted(int id) {
    super.touchStarted(id);
    
    TouchEvent.Pointer p = getTouchById(id);
    if (! this.bounds.containsPoint(p.x, p.y)) {
      return;
    }

    initialTouchPoint = touchPositions[id].copy();

    for(int i=0; i < digitHitboxes.length; i++) {
      Rect hb = digitHitboxes[i];
      if (hb.containsPoint(initialTouchPoint.x, initialTouchPoint.y)) {
        precisionIndex = Math.max(0, Math.min(i, numDecimals+numInts-1));
        float adjustPow = precisionIndex-numDecimals;
        adjustIncrement = (float)Math.pow(10, adjustPow);
        println("adjustIncrement", adjustIncrement);

        initialValue = currentValue;
        isAdjusting = true;
        break;
      }
    }
  }

  @Override
  public void touchEnded(int id) {
    super.touchEnded(id);
    isAdjusting = false;
    isCalibrating = false;
  }

  @Override
  public void touchMoved(MotionEvent e) {
    super.touchMoved(e);
    if (touchIds.size() > 0) {
      int id = touchIds.get(0);
      if (touchPositions[id] != null) {
        PVector p = touchPositions[id];
        if (isAdjusting) {
          float deltaY = p.y - initialTouchPoint.y;
          currentValue = initialValue - (int)(deltaY * sensitivity) * adjustIncrement;
          currentValue = quantize(currentValue, adjustIncrement);
          currentValue = Math.max(rangeMin, Math.min(currentValue, rangeMax));
        }
      }
    }
  }

  @Override
  void recalcLayout() {
    super.recalcLayout();
    digitHitboxes = makeDigitHitboxes();
  }

  private double quantize(double value, double roundTo) {
      return Math.round(value / roundTo) * roundTo;
  }
  
  @Override
  public void setValue(Object value) {
    println("DragNum setValue: " + (float) value);
    if (value instanceof Float) {
      currentValue = (float)value;
      //currentValue = quantize(currentValue, adjustIncrement);
      currentValue = Math.max(rangeMin, Math.min(currentValue, rangeMax));
    }
  }
} // END DragNumberControl


class PresetControl extends UIBase {
  public PresetControl(String oscId) {
    super(0, 0, 100, 100, oscId, UIBase.LAYOUT_HORIZONTAL);
    //this.oscId = oscId;
    UIBase buttonPanel = new UIBase("buttons", UIBase.LAYOUT_HORIZONTAL);
      Button prevButton = new Button(oscId+"/prev", Button.TOUCH_DOWN);
        prevButton.label = "<";
        prevButton.offTextColor = color(255,255,255);
        prevButton.oscEnabled = true;
      Button nextButton = new Button(oscId+"/next", Button.TOUCH_DOWN);
        nextButton.label = ">";
        nextButton.offTextColor = color(255,255,255);
        nextButton.oscEnabled = true;
      buttonPanel.addChild(prevButton);
      buttonPanel.addChild(nextButton);
      buttonPanel.recalcLayout();
    
    Label lbl = new Label("<no preset>");
      lbl.oscId = oscId + "/name";
      lbl.oscEnabled = true;
      lbl.textColor = color(0, 255, 0);
      println("LABEL", lbl.oscId);
    this.addChild(lbl);
    this.addChild(new UIBase("spacer"));
    this.addChild(buttonPanel);
    recalcLayout();    
  }
  
}

class Touch10 extends UIBase {
  static final int numhandles = 10;
  PVector[] handles = new PVector[numhandles];
  color[] handleColors = new color[numhandles];
  
  public Touch10(String _oscId) {
    super(0, 0, 100, 100, _oscId, UIBase.LAYOUT_NONE);
    //for (int i=0; i< numhandles; i++) {
    //  handles[i] = new PVector(bounds.x+bounds.w/2, bounds.y+bounds.h/2); 
    //}
    initColors();
  }

  void initColors() {
    //float maxt = 1 - 1.0/(numhandles);
    float step = 1.0/numhandles;
    
    for (int i=0; i< numhandles; i++) {
      float t = i * step;
      handleColors[i] = sinebow(t);
    }
  }

  @Override
  public void touchStarted(int id) {
    super.touchStarted(id);
    print(String.format("10Fingers %s pressed (TOUCH_DOWN)", this.oscId));
  }
  
  
  @Override
  void recalcLayout() {
    super.recalcLayout();
    float edgespace = 200;
    for (int i=0; i< numhandles; i++) {
      float x = edgespace + bounds.x + random(bounds.w - 2*edgespace);
      float y = edgespace + bounds.y + random(bounds.h - 2*edgespace);
      if (handles[i] == null) {
        handles[i] = new PVector(x, y);
        //handles[i] = new PVector(
        //  edgespace + bounds.x + random(bounds.w - 2*edgespace),
        //  edgespace + bounds.y + random(bounds.h - 2*edgespace)
        //);
      }
      else {
        handles[i].x = x;
        handles[i].y = y;
      }
    }
  }
  
  int findClosestHandleIndex(PVector t) {
    float minDist = 99999;
    int minIdx = -1;
    for (int i=0; i < numhandles; i++) {
      float dist = handles[i].dist(t);
      if (dist < minDist && dist < 150) {
        minDist = dist;
        minIdx = i;
      }
    }
    return minIdx;
  }
  
  @Override
  void draw() {
    //super.draw();
    noStroke();
    
    //for (int i=0; i<touchIds.size(); i++) {
    //  int tid = touchIds.get(i);
    //  TouchEvent.Pointer p = getTouchById(tid);
    //  if (p != null) {
    //    float px = bounds.x + p.x;
    //    float py = bounds.y + p.y;

    //    // touch point
    //    int d = 150;
    //    noStroke();
    //    fill(handleColors[tid]);
    //    ellipse(px, py, d, d);
    //  }
    //}
    
    for (int i=0; i< numhandles; i++) {
      if (touchPositions[i] != null) {
        PVector p = touchPositions[i];
        int closestHandleIdx = findClosestHandleIndex(p);
        if (closestHandleIdx > -1) {
          handles[closestHandleIdx] = p;
        }
      }
      PVector p = handles[i];
      fill(handleColors[i]);
      ellipse(p.x, p.y, 150, 150);
      
    }
  }  
}



class XYPad extends UIBase {
  public static final int CARTESIAN = 0;
  public static final int POLAR = 1;
  public static final int KNOB = 2;
  
  public static final int ORIGIN_BOTTOMLEFT = 0;
  public static final int ORIGIN_CENTER = 1;
  
  int coordSys = CARTESIAN;
  int originMode = ORIGIN_CENTER;
  Boolean flipX = true;
  Boolean flipY = true;
  

  PVector pos;
  float tx, ty, ta, tr;
  float ptx, pty;
  color textColor = color(0, 255, 32);
  UIBase buttonPanel;
  Boolean isAdjusting = false;

  public XYPad(String oscId, int _coordSys) {
    super(0, 0, 100, 100, oscId, UIBase.LAYOUT_NONE);
    this.coordSys = _coordSys;
    this.pad = 64;
    tx = 0.0;
    ty = 0.0;
    ta = 0.0;
    tr = 1.0;
    pos = new PVector(0,0);
    buttonPanel = new UIBase(bounds.x+pad, bounds.y, bounds.w/4, 72, "", UIBase.LAYOUT_HORIZONTAL);
      Button modeButton = new Button("", Button.TOGGLE, new Runnable() {
        public void run() {
          coordSys = 1 - coordSys;
        }
      });
      
      modeButton.label = "C";
      
      Button originButton = new Button("", Button.TOGGLE, new Runnable() {
        public void run() {
          coordSys = 1 - coordSys;
        }
      });
      
      originButton.label = "L";
      
      buttonPanel.addChild(modeButton);
      buttonPanel.addChild(originButton);
      this.addChild(buttonPanel);
  }

  @Override
  public void draw() {
    float dim = min(this.bounds.w, this.bounds.h) - pad*2;
    float ctlx = this.bounds.x + pad;
    float ctly = this.bounds.y+this.bounds.h - dim - pad;
    float ctlcx = ctlx + dim/2;
    float ctlcy = ctly + dim/2;
    
    if (borderVisible) {
      strokeWeight(1);
      drawBounds();
    }
    buttonPanel.draw();
    
    //drawGradsX(ctlx, ctlx+dim, ctly,     0, 3, -1);
    //drawGradsX(ctlx, ctlx+dim, ctly+dim, 0, 3,  1);

    strokeWeight(2);
    stroke(192);
    noFill();
    rect(ctlx, ctly, dim, dim);

    PVector p;
    if (isAdjusting && touchIds.size() > 0) {
      int id = touchIds.get(0);
      p = touchPositions[id];
      if (p == null) {
        print("no position");
        return;
      }
      this.pos.x = p.x;
      this.pos.y = p.y;

      tx = (p.x - ctlx) / dim;
      ty = 1.0 - (p.y - ctly) / dim;
      tx = max(0, min(1.0, tx));
      ty = max(0, min(1.0, ty));
      float cx = tx - 0.5;
      float cy = ty - 0.5;
      ta = atan2(cx, cy);
      tr = (float)Math.sqrt(cx*cx+cy*cy);

      if (originMode == ORIGIN_CENTER) {
          tx = tx * 2.0 - 1.0;
          ty = ty * 2.0 - 1.0;
      }

      if (ptx != tx || pty != tx) {
        float sendX=tx, sendY=ty;
        if (flipX) {
          if (originMode == ORIGIN_BOTTOMLEFT) {
            sendX = 1.0 - sendX;
          }
          else {
            sendX *= -1.0;
          }
        }
        if (flipY) {
          if (originMode == ORIGIN_BOTTOMLEFT) {
            sendY = 1.0 - sendY;
          }
          else {
            sendY *= -1.0;
          }
        }
        
        float[] arr = {sendX, sendY, 1.0f, 1.0f, 1.0f};
        queueOscSendArray(arr, oscId + "/p1");
        
        ptx = tx;
        pty = ty;
      }
      
    }
    else {
      p = this.pos;
    }

    float dotx = max(ctlx, min(ctlx+dim, p.x));
    float doty = max(ctly, min(ctly+dim, p.y));

    if (coordSys == CARTESIAN || coordSys == POLAR) {
      // touch point
      noStroke();
      fill(0,255,32);
      if (touchIds.size() > 0) {
        ellipse(dotx, doty, 100, 100);
      }
      else {
        ellipse(dotx, doty, 20, 20);
      }
    }
    
    // unit circle
    strokeWeight(1);
    //stroke(128);
    stroke(64);
    noFill();
    ellipse(ctlx+dim/2, ctly+dim/2, dim, dim);

    line(ctlx+dim/2, ctly, ctlx+dim/2, ctly+dim);
    line(ctlx, ctly+dim/2, ctlx+dim, ctly+dim/2);
    
    if (coordSys == CARTESIAN) {
      // crosshair
      if (this.bounds.containsPoint(p.x, p.y)) {
        strokeWeight(1);
        stroke(0,255,32,128);
        line(p.x, ctly, p.x, ctly+dim-1);
        line(ctlx, p.y, ctlx+dim-1, p.y);
      }
      stroke(192);
      drawGraduations(ctlx, ctlx+dim, ctly,  0, 3, true, -1);
      drawGraduations(ctlx, ctlx+dim, ctly+dim, 0, 3, true, 1);  
      drawGraduations(ctly, ctly+dim, ctlx,  0, 3, false, 1);
      drawGraduations(ctly, ctly+dim, ctlx+dim, 0, 3, false, -1);
    }
    stroke(0, 255,32);
    strokeWeight(8);
    float ang = ta + PI*1.5;
    if (ta >= 0) {
      arc(ctlx+dim/2, ctly+dim/2, dim, dim, PI*1.5, ang);
    }
    else {
      arc(ctlx+dim/2, ctly+dim/2, dim, dim, ang, PI*1.5);    
    }
    
    PVector pn = new PVector(p.x, p.y).sub(new PVector(ctlcx, ctlcy)).normalize().mult(dim/2);
    
    if (coordSys == POLAR) {
      // angle radius line
      strokeWeight(4);
      stroke(0,255,32);
      line(ctlcx, ctlcy, dotx, doty);
    }
    
    stroke(240);
    fill(255);
    ellipse(ctlcx+pn.x, ctlcy+pn.y, 16, 16);
    ellipse(ctlcx, ctlcy, 16, 16);

    //line(ctlcx, ctlcy, ctlcx+pn.x, ctlcy+pn.y);

    fill(textColor);
    noStroke();
    textSize(LARGETEXT);
    textAlign(BASELINE);

    String xytext = String.format("[%.2f, %.2f]", tx, ty);
    String artext = String.format("[%.2f, %.2f]", degrees(ta), tr);
    text(xytext, bounds.x+bounds.w/3+0, bounds.y+60);
    text(artext, bounds.x+bounds.w - 40 - textWidth(artext), bounds.y+60);

  }
  
  @Override
  void recalcLayout() {
    super.recalcLayout();
    buttonPanel.bounds.set(bounds.x+pad, bounds.y+pad/4, bounds.w/4, 64);
    //buttonPanel.bounds.x = bounds.x+pad;
    //buttonPanel.bounds.y = bounds.y+pad/4;
    //buttonPanel.bounds.w = bounds.w/4;
    //buttonPanel.bounds.h = 64;
    buttonPanel.recalcLayout();
  }
  
  
  void drawGraduations(float start, float end, float offset,
                       int level, int maxLevel, boolean isHorizontal, int tickDir) {
    if (level > maxLevel) {
      return;
    }
  
    float mid = (start + end) / 2;
    float lineLength = 100 * pow(0.5, level);
  
    if (isHorizontal) {
      float y1 = offset;
      float y2 = y1 - lineLength * tickDir;
      line(mid, y1, mid, y2);
    } else {
      float x1 = offset;
      float x2 = x1 + lineLength * tickDir;
      line(x1, mid, x2, mid);
    }
  
    drawGraduations(start, mid, offset, level + 1, maxLevel, isHorizontal, tickDir);
    drawGraduations(mid, end, offset, level + 1, maxLevel, isHorizontal, tickDir);
  }


  void drawGradsX(float xstart, float xend, float yoffset, int level, int maxLevel, int tickDir) {
    if (level > maxLevel) {
      return;
    }

    float mid = (xstart + xend) / 2;
    float lineLength = 100 * pow(0.667, level);
    float y1 = yoffset;
    float y2 = y1 - lineLength*tickDir;
    
    line(mid, y1, mid, y2);

    drawGradsX(xstart, mid, yoffset, level + 1, maxLevel, tickDir);
    drawGradsX(mid, xend, yoffset, level + 1, maxLevel, tickDir);
  }
  
    @Override
  public void touchStarted(int id) {
    super.touchStarted(id);
    //TouchEvent.Pointer p = getTouchById(id);
    //if (! this.bounds.containsPoint(p.x, p.y)) {
    //  return;
    //}    
    isAdjusting = true;
  }

  @Override
  public void touchEnded(int id) {
    super.touchEnded(id);
    isAdjusting = false;
  }

} // End class XYPad


class ColorChooserHSV extends UIBase {
  private PShader hueRingShader;
  private PGraphics hueRingPg;
  float margin = 50;
  int dim; // = 100.0;
  float hueHandleAngle = 0.0;
  float hueRingInnerRadius = 0.7;
  float hueRingOuterRadius = 0.96;
  float ssControlOriginX;
  float ssControlOriginY;
  float ssControlCenterX;
  float ssControlCenterY;
  PVector svHandlePosition = new PVector(0,0);
  
  Boolean isAdjustingHue = false;
  Boolean isAdjustingSV = false;
  
  PVector[] svTriangleVerts = new PVector[3];
  float H=0, S=1, V=1;

  public ColorChooserHSV(String label, int layout) {
    super(label, layout);
    this.label = label;
    hueRingShader = loadShader("hue_ring.glsl");
  }
  
  void updateHSTriangle() {
    float ang;
    for (int i=0; i < 3; i++) {
      ang = hueHandleAngle + i * 2.0*PI / 3.0;
      svTriangleVerts[i].x = ssControlCenterX + cos(ang) * hueRingInnerRadius * dim/2.0;
      svTriangleVerts[i].y = ssControlCenterY + sin(ang) * hueRingInnerRadius * dim/2.0;
    }
  }

  void drawHSTriangle() {
    float hue = - hueHandleAngle;
    hue %= (2.0*PI);
    hue = (hue < 0)? hue+2.0*PI : hue;
    hue = (hue >= (2.0*PI))? hue - 2.0*PI : hue;
    
    noStroke();
    colorMode(HSB, 2.0*PI, 100, 100);
    beginShape(TRIANGLES);
      fill(hue, 100, 100);
      vertex(svTriangleVerts[0].x, svTriangleVerts[0].y);
      fill(0, 0, 100);
      vertex(svTriangleVerts[1].x, svTriangleVerts[1].y);
      fill(0, 0, 0);
      vertex(svTriangleVerts[2].x, svTriangleVerts[2].y);
    endShape();
    colorMode(RGB, 255);
  }
  
  @Override
  void draw() {
    //super.draw();
    drawBounds();
    renderHueRing(hueRingPg);
    image(hueRingPg, bounds.x+margin, bounds.y+margin, dim, dim);
    
    
    color currentHueRingColor = hsvToRgb(H/(2.0*PI), 1, 1);
    Boolean isLight = isColorLight(currentHueRingColor);
    drawHueHandle(isLight);
    drawHSTriangle();
    color currentColor = hsvToRgb(H/(2.0*PI), S, V);
    isLight = isColorLight(currentColor);
    if (isLight) {
      fill(0);
    }
    else {
      fill(255);
    }
    ellipse(svHandlePosition.x, svHandlePosition.y, 30, 30);
    
    debugDrawColor();
    
    //ellipse(ssControlCenterX, ssControlCenterY, 30, 30);
    textAlign(BASELINE, LEFT);
    String info = String.format("H=%.2f, S=%.2f, V=%.2f", H, S, V);
    fill(255);
    text(info, bounds.x+margin, bounds.y+pad+30);
  }
  
  void renderHueRing(PGraphics g) {
    float ar = 1.0;
    g.beginDraw();
      g.background(59);
      hueRingShader.set("inner_radius", hueRingInnerRadius);
      hueRingShader.set("outer_radius", hueRingOuterRadius);
      g.shader(hueRingShader);
      g.beginShape(QUADS);
        g.vertex(0, 0,  0, 0);
        g.vertex(g.width, 0, ar, 0);
        g.vertex(g.width, g.height, ar, 1);
        g.vertex(0, g.height,  0, 1);
      g.endShape();
    g.endDraw();
  }
  
  void drawHueHandle(Boolean isLight) {
    PVector hueDir = new PVector(cos(hueHandleAngle), sin(hueHandleAngle));
    float innerX = ssControlCenterX + hueDir.x * hueRingInnerRadius * (dim/2.0);
    float innerY = ssControlCenterY + hueDir.y * hueRingInnerRadius * (dim/2.0);
    float outerX = ssControlCenterX + hueDir.x * hueRingOuterRadius * (dim/2.0);
    float outerY = ssControlCenterY + hueDir.y * hueRingOuterRadius * (dim/2.0);
    strokeWeight(10);
    if (isLight) {
      stroke(0);      
    }
    else {
      stroke(255);
    }
    line(innerX, innerY, outerX, outerY);
  }
  
  void debugDrawColor() {
    float bgx = bounds.x + margin;
    float bgy = bounds.y + margin*2 + dim;
    float bgw = dim;
    float bgh = bounds.h - margin*3 - dim;
    fill(59);
    rect(bgx, bgy, bgw, bgh);
    
    //float 
    float swatchDim = bgh - margin*2;
    float sx = bgx + bgw/2 - swatchDim/2;
    float sy = bgy + bgh/2 - swatchDim/2;
    
    colorMode(HSB, 2.0*PI, 1.0, 1.0);
      fill(H, S, V);
      rect(sx, sy, swatchDim, swatchDim, 32);
    colorMode(RGB, 255);
  }
  
  @Override
  void recalcLayout() {
    super.recalcLayout();
    println("ColorChooserHSV.recalcLayout(): ", this.bounds.toString());
    dim = (int) (min(bounds.w, bounds.h) - margin * 2.0);
    ssControlOriginX = bounds.x + margin;
    ssControlOriginY = bounds.y + margin;
    ssControlCenterX = ssControlOriginX + dim / 2.0;
    ssControlCenterY = ssControlOriginY + dim / 2.0;
    
    if (svTriangleVerts[0] == null || svTriangleVerts[1] == null || svTriangleVerts[2] == null) {
      for (int i=0; i < 3; i++) {
        svTriangleVerts[i] = new PVector(0.0, 0.0);
      }
    }
    updateHSTriangle();

    if (hueRingPg == null || hueRingPg.width != dim || hueRingPg.height != dim) {
      hueRingPg = createGraphics(dim, dim, P2D);
    }
  }
  
    @Override
  public void touchStarted(int id) {
    super.touchStarted(id);
    TouchEvent.Pointer p = getTouchById(id);
    PVector pv = new PVector(p.x, p.y);
    PVector c = new PVector(ssControlCenterX, ssControlCenterY);
    float cdist = c.dist(pv) / (dim/2);
    
    if (cdist > hueRingInnerRadius && cdist < hueRingOuterRadius) {
      isAdjustingHue = true;
    }
    else if (triangleContains(pv)) {
      isAdjustingSV = true;
    }
  }
  
  @Override
  public void touchMoved(MotionEvent e) {
    super.touchMoved(e);
    if (isAdjustingHue && touchIds.size() > 0) {
      //print("isAdjustingHue");
      int id = touchIds.get(0);
      PVector p = touchPositions[id];
      if (p == null) {
        print("no position");
        return;
      }
      float tx, ty, ta, tr, cx, cy;
      tx = (p.x - ssControlCenterX) / dim;
      ty = (p.y - ssControlCenterY) / dim;
      tx = max(-1.0, min(1.0, tx));
      ty = max(-1.0, min(1.0, ty));
      cx = tx - 0.5;
      cy = ty - 0.5;
      ta = atan2(ty, tx);      
      tr = (float)Math.sqrt(cx*cx+cy*cy);
      hueHandleAngle = (2.0 * PI + ta); // % (2.0 * PI);
      H = - hueHandleAngle;
      H %= (2.0*PI);
      H = (H < 0)? H+2.0*PI : H;
      H = (H >= (2.0*PI))? H - 2.0*PI : H;

      updateHSTriangle();
      sendOsc();
    }
    else if (isAdjustingSV && touchIds.size() > 0) {
      //print("isAdjustingSV");
      int id = touchIds.get(0);
      PVector p = touchPositions[id];
      if (p == null) {
        print("no position");
        return;
      }
      if (triangleContains(p)) {
        svHandlePosition.x = p.x;
        svHandlePosition.y = p.y;
      }
      else {
        PVector cp = closestPointInTriangle(p, svTriangleVerts);
          svHandlePosition.x = cp.x;
          svHandlePosition.y = cp.y; 
      }
      PVector bary = computeBarycentric(svHandlePosition, svTriangleVerts);
      S = 1.0 - bary.y;
      V = 1.0 - bary.z;
      sendOsc();
    }
  }
  
  @Override
  public void touchEnded(int id) {
    super.touchEnded(id);
    isAdjustingHue = false;
    isAdjustingSV = false;

  }  

  public void sendOsc() {
    color hsvColor = hsvToRgb(H/(2.0*PI), S, V);
    float[] arr = new float[3];
    arr[0] = red(hsvColor) / 255.0; 
    arr[1] = green(hsvColor) / 255.0; 
    arr[2] = blue(hsvColor) / 255.0; 
    queueOscSendArray(arr, oscId);
  
  }


  boolean isColorLight(color c) {
    // Extract RGB components
    float r = red(c) / 255.0;
    float g = green(c) / 255.0;
    float b = blue(c) / 255.0;

    // Calculate luminance
    float luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;

    // Determine if the color is light or dark
    return luminance > 0.5;
  }


  Boolean triangleContains(PVector point) {
      PVector bary = computeBarycentric(point, svTriangleVerts);
      // Check if the point's barycentric coordinates are within the triangle
      return bary.x >= 0 && bary.x <= 1 && bary.y >= 0 && bary.y <= 1 && bary.z >= 0 && bary.z <= 1;
  }

  PVector computeBarycentric(PVector point, PVector[] triangleVerts) {
    PVector A = triangleVerts[0];
    PVector B = triangleVerts[1];
    PVector C = triangleVerts[2];
  
    // Using determinant method to calculate areas for barycentric coordinates
    float detT = (B.y - C.y) * (A.x - C.x) + (C.x - B.x) * (A.y - C.y);
    float alpha = ((B.y - C.y) * (point.x - C.x) + (C.x - B.x) * (point.y - C.y)) / detT;
    float beta = ((C.y - A.y) * (point.x - C.x) + (A.x - C.x) * (point.y - C.y)) / detT;
    float gamma = 1.0f - alpha - beta;
  
    return new PVector(alpha, beta, gamma);
  }
  
  PVector closestPointInTriangle(PVector point, PVector[] triangleVerts) {
    // Compute barycentric coordinates for the point
    PVector bary = computeBarycentric(point, triangleVerts);

    // Clamp barycentric coordinates to the range [0, 1]
    float alpha = constrain(bary.x, 0, 1);
    float beta = constrain(bary.y, 0, 1);
    float gamma = constrain(bary.z, 0, 1);

    // Normalize the clamped coordinates so they sum to 1
    float total = alpha + beta + gamma;
    alpha /= total;
    beta /= total;
    gamma /= total;

    // Interpolate back to Cartesian coordinates using the clamped barycentric coordinates
    PVector A = triangleVerts[0];
    PVector B = triangleVerts[1];
    PVector C = triangleVerts[2];
    float x = alpha * A.x + beta * B.x + gamma * C.x;
    float y = alpha * A.y + beta * B.y + gamma * C.y;

    return new PVector(x, y);
  }

}
