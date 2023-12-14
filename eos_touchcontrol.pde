import android.view.MotionEvent;
import netP5.*;
import oscP5.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

ExecutorService executor = Executors.newSingleThreadExecutor();

public final String OSCID_BASE = "touch";
UIBase root;
ArrayList<Integer> touchMap;
int gTargetFrameRate = 120;
int gPendingAnimFrames = 0;

int LARGETEXT;
int SMALLTEXT;

PFont fixedFont;

OscP5 oscP5;
NetAddress network;
OscProperties oscProps;
Boolean gOscEnabled = true;

void setup() {
  fullScreen(P3D, 1);
  orientation(LANDSCAPE);
  frameRate(gTargetFrameRate);
  fixedFont = loadFont("SourceCodeProForPowerline-Regular-48.vlw");
  LARGETEXT = (int)(36 * displayDensity);
  SMALLTEXT = (int)(24 * displayDensity);
  
  textSize(SMALLTEXT);
  
  touchMap = new ArrayList<Integer>();
  
  UIBase helios = makeHeliosControl();
  
  UIBase tab1 = new UIBase("tab1", UIBase.LAYOUT_HORIZONTAL);
    tab1.borderColor = color(0);
    tab1.label = "XY Pad  |  Grid";
    UIBase buttonGrid1 = makeButtonGrid(5, 5, "g1");
    XYPad xypad1 = new XYPad("pad1", XYPad.CARTESIAN);
    tab1.addChild(xypad1);
    tab1.addChild(buttonGrid1);

  UIBase tab2 = new UIBase("tab2", UIBase.LAYOUT_HORIZONTAL);
    tab2.label = "UIBase";
    tab2.borderColor = color(10, 255, 10);


  UIBase tab3 = new UIBase("tab3", UIBase.LAYOUT_HORIZONTAL);
    tab3.borderColor = color(0);
    tab3.label = "Sliders";
    tab3.borderColor = color(0);
    UIBase bank1 = makeSliderBank(6, Slider.VERTICAL, "b1");
    UIBase bank2 = makeSliderBank(6, Slider.HORIZONTAL, "b2");
    tab3.addChild(bank1);
    tab3.addChild(bank2);
    

  //UIBase tab3 = makeSliderBank(12, Slider.VERTICAL, "b1");
  //  tab3.borderColor = color(0);
  //  tab3.label = "Slider Bank 1";

  UIBase tab4 = new UIBase("tab4", UIBase.LAYOUT_HORIZONTAL);
    tab4.label = "Button Test";
    tab4.borderColor = color(0);
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
    tab4.addChild(buttonPanel1);
    tab4.addChild(new UIBase("", UIBase.LAYOUT_HORIZONTAL));

  Touch10 tab5 = new Touch10("tab5");
    tab5.label = "Grabbable";

  int infoHeight = 24;
  TabContainer tabs = new TabContainer(0, infoHeight, 100, 100);
    tabs.addChild(helios);
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
  textAlign(BASELINE);

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
  UIBase bank;
  if (direction == Slider.VERTICAL) {
    bank = new UIBase(oscId, UIBase.LAYOUT_HORIZONTAL);
  }
  else {
    bank = new UIBase(oscId, UIBase.LAYOUT_VERTICAL);
  }
  bank.pad = 16;
  bank.borderVisible = false;
  for (int i=0; i < numSliders; i++) {
    Slider s = new Slider(String.format("%ss%d", oscId, i), direction);
    s.label = String.format("Slider %d", i);
    s.borderVisible = false;
    
    bank.addChild(s);
  }
  return bank;
  
}


UIBase makeButtonGrid(int rows, int cols, String oscId) {
  UIBase grid = new UIBase(0, 0, width-1, height-1, oscId, UIBase.LAYOUT_GRID);
  grid.borderVisible = false;
  grid.pad = 24;
  int numchild = rows * cols;
  grid.gridRows = rows;
  grid.gridCols = cols;
  for (int i=0; i < numchild; i++) {
    Button b = new Button(String.format("%sb%d", oscId, i), Button.TOGGLE);
    b.borderWeight = 4;
    b.label = b.oscId;
    //b.offBorderColor = color(0, 64, 0);
    grid.addChild(b);
  }
  return grid;
}


ButtonGroup makePPSButtons() {
  float[] ppsValues = {12.5, 30, 45, 50, 55, 60, 65.535};
  ButtonGroup bgroup = new ButtonGroup("ppsbuttons", ButtonGroup.BUTTONMODE_TRIGGER, UIBase.LAYOUT_HORIZONTAL);
  bgroup.borderVisible = false;  
  for (int i=0; i<ppsValues.length; i++) {
    Button b = new Button(String.format("kpps%d", (int)ppsValues[i]), Button.TOGGLE);
    b.oscValue = ppsValues[i];
    b.label = String.format("%d", (int)ppsValues[i]);
    bgroup.addChild(b);
  }
  
  return bgroup;
}

UIBase makeHeliosControl() {
  UIBase heliosPanel = new UIBase("helios", UIBase.LAYOUT_HORIZONTAL);
  heliosPanel.label = "Helios";
  
  UIBase dacPanel = makeHeliosDACPanel();
  UIBase transformPanel = makeHeliosTransformPanel();
  UIBase panel3 = new UIBase("panel3", UIBase.LAYOUT_VERTICAL);
    XYPad pad2 = new XYPad("pad2", XYPad.KNOB);
    pad2.borderVisible = true;
    panel3.addChild(pad2);
    //panel3.addChild(new UIBase("spacer"));
  heliosPanel.addChild(dacPanel);
  heliosPanel.addChild(transformPanel);
  heliosPanel.addChild(panel3);
  
  return heliosPanel;  
}

UIBase makeHeliosDACPanel() {
  String oscId = "helios/dac";
  //UIBase heliosPanel = new UIBase(oscId, UIBase.LAYOUT_HORIZONTAL);
  //heliosPanel.label = "Helios";
  UIBase dacPanel = new UIBase(oscId, UIBase.LAYOUT_VERTICAL);
    Button laserActiveButton = new Button(String.format("%s/laseron", oscId), Button.TOGGLE);
    laserActiveButton.label = "LASER ON";
    laserActiveButton.onFillColor = color(128, 0, 0);
    laserActiveButton.oscEnabled = true;
    Slider intensitySlider = new Slider(String.format("%s/intensity", oscId), Slider.HORIZONTAL);
    intensitySlider.label = "Intensity";
    intensitySlider.rangeMin = 0;
    intensitySlider.rangeMax = 255;
    intensitySlider.numberFormat = "%.0f";
    intensitySlider.oscEnabled = true;
    intensitySlider.forceInteger = true;
    
    Slider ppsSlider = new Slider(String.format("%s/pps", oscId), Slider.HORIZONTAL);
    ppsSlider.label = "KPPS";
    ppsSlider.rangeMin = 1;
    ppsSlider.rangeMax = 65.535;
    ppsSlider.numberFormat = "%.3f";
    ppsSlider.oscEnabled = true;
    
    ButtonGroup ppsButtons = makePPSButtons();
    ppsButtons.setOnStateChangeCallback(new Runnable() {
      public void run() {
        float value = ((Button)ppsButtons.children.get(ppsButtons.activeButtonIndex)).oscValue;
        float range = (ppsSlider.rangeMax - ppsSlider.rangeMin);
        float normValue = value / range - ppsSlider.rangeMin/range;
        ppsSlider.value = normValue;
      }
    });

    DragNumber dn1 = new DragNumber("dragnum1", "Drag Number 1");
    DragNumber dn2 = new DragNumber("dragnum2", "Drag Number 2");
    DragNumber dn3 = new DragNumber("dragnum3", "Drag Number 3");

    UIBase spacer = new UIBase("spacer", UIBase.LAYOUT_NONE);
    spacer.borderVisible = false;
    
    dacPanel.addChild(laserActiveButton);
    dacPanel.addChild(intensitySlider);
    dacPanel.addChild(ppsSlider);
    dacPanel.addChild(ppsButtons);
    dacPanel.addChild(dn1);
    dacPanel.addChild(dn2);
    dacPanel.addChild(dn3);
    //dacPanel.addChild(spacer);
    
  //UIBase panel2 = makeTransformPanel();
  ////UI Base panel3 = new UIBase(oscId, UIBase.LAYOUT_VERTICAL);
  //heliosPanel.addChild(panel1);
  //heliosPanel.addChild(panel2);
  ////heliosPanel.addChild(panel3);
  
  return dacPanel;
}


UIBase makeHeliosTransformPanel() {
  String oscId = "helios/transform";
  UIBase panel = new UIBase(oscId, UIBase.LAYOUT_VERTICAL);
    Slider scaleSlider = new Slider(String.format("%s/scale", oscId), Slider.HORIZONTAL);
    scaleSlider.label = "Scale";
    scaleSlider.rangeMin = 0.001;
    scaleSlider.rangeMax = 200;
    scaleSlider.numberFormat = "%.3f";
    scaleSlider.value = 0.2;
    scaleSlider.oscEnabled = true;

    Slider translateXSlider = new Slider(String.format("%s/translatex", oscId), Slider.HORIZONTAL);
    translateXSlider.label = "Translate X";
    translateXSlider.rangeMin = -1024;
    translateXSlider.rangeMax = 1024;
    translateXSlider.numberFormat = "%.0f";
    translateXSlider.value = map(-50, translateXSlider.rangeMin, translateXSlider.rangeMax, 0, 1); 
    translateXSlider.oscEnabled = true;

    Slider translateYSlider = new Slider(String.format("%s/translatey", oscId), Slider.HORIZONTAL);
    translateYSlider.label = "Translate Y";
    translateYSlider.rangeMin = -1024;
    translateYSlider.rangeMax = 1024;
    translateYSlider.numberFormat = "%.0f";
    //translateYSlider.value = -677;
    translateYSlider.value = map(-677, translateYSlider.rangeMin, translateYSlider.rangeMax, 0, 1); 
    translateYSlider.oscEnabled = true;

    Slider rotateSlider = new Slider(String.format("%s/rotate", oscId), Slider.HORIZONTAL);
    rotateSlider.label = "Rotate";
    rotateSlider.rangeMin = -180;
    rotateSlider.rangeMax = 180;
    rotateSlider.numberFormat = "%.0f";
    rotateSlider.value = 0.5;
    rotateSlider.oscEnabled = true;

    
    ButtonGroup flipButtons = new ButtonGroup("flip", ButtonGroup.BUTTONMODE_TOGGLE, UIBase.LAYOUT_HORIZONTAL);
    Button bflipx = new Button("flipx", Button.TOGGLE);
    bflipx.label = "Flip X";
    Button bflipy = new Button("flipy", Button.TOGGLE);
    bflipy.label = "Flip Y";
    flipButtons.addChild(bflipx);
    flipButtons.addChild(bflipy);
 
    UIBase spacer = new UIBase("spacer", UIBase.LAYOUT_NONE);
    spacer.borderVisible = false;

    panel.addChild(scaleSlider);
    panel.addChild(translateXSlider);
    panel.addChild(translateYSlider);
    panel.addChild(rotateSlider);
    panel.addChild(flipButtons);
    //panel.addChild(dn1);
    panel.addChild(spacer);
    
    return panel;
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

void queueOscSend(final float val1, final String oscid) {
  if (gOscEnabled) {
    executor.execute(new Runnable() {
        @Override
        public void run() {
            oscSend(val1, oscid);
        }
    });
  }
}

void oscSend(float val1, String oscid) {
  String fullOscId = String.format("/%s/%s", OSCID_BASE, oscid);
  println(String.format("oscSend(): %s ==> %f", fullOscId, val1));
  OscMessage msg = new OscMessage(fullOscId);
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
