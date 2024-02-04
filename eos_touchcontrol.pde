import android.view.MotionEvent;
import netP5.*;
import oscP5.*;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

ExecutorService executor = Executors.newSingleThreadExecutor();

public final String OSCID_BASE = "/touch";
UIBase root;
ArrayList<Integer> touchMap;
int gTargetFrameRate = 120;
int gPendingAnimFrames = 0;

int LARGETEXT;
int SMALLTEXT;

PFont fixedFont;


String HELIOS_SERVER_IP = "192.168.1.102";
int HELIOS_SERVER_PORT = 12000;

int LISTEN_PORT = 12001;

OscP5 oscP5;
NetAddress heliosServerAddr;
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
    XYPad xypad1 = new XYPad("/xypad1", XYPad.CARTESIAN);
    tab1.addChild(xypad1);
    tab1.addChild(buttonGrid1);

  UIBase tab2 = new UIBase("/uibase", UIBase.LAYOUT_HORIZONTAL);
    tab2.label = "UIBase";
    tab2.borderColor = color(10, 255, 10);
    tab2.useDefaultOsc = true;

  UIBase tab21 = new UIBase("tab2.1", UIBase.LAYOUT_HORIZONTAL);
    tab21.label = "Color";
    ColorChooserHSV color1 = new ColorChooserHSV("/colorhsv1/rgb", UIBase.LAYOUT_HORIZONTAL);
    color1.label = "Color 1";
    color1.borderVisible = true;
    ColorChooserHSV color2 = new ColorChooserHSV("/colorhsv2/rgb", UIBase.LAYOUT_HORIZONTAL);
    color2.label = "Color 2";
    color2.borderVisible = true;
    UIBase spacer = new UIBase("spacer", UIBase.LAYOUT_HORIZONTAL);
    tab21.addChild(color1);
    tab21.addChild(color2);
    tab21.addChild(spacer);
    
    

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
    tabs.addChild(tab21);
    tabs.addChild(tab3);
    tabs.addChild(tab4);
    tabs.addChild(tab5);
    tabs.setActiveTab(0);
  
  root = new UIBase(1, infoHeight, width-1, height-1 - infoHeight, "root", UIBase.LAYOUT_HORIZONTAL);
    root.borderColor = color(0);
    root.addChild(tabs);
    root.recalcLayout();
  
  oscProps = new OscProperties();
  heliosServerAddr = new NetAddress(HELIOS_SERVER_IP, HELIOS_SERVER_PORT);
  oscProps.setRemoteAddress(heliosServerAddr);
  oscProps.setDatagramSize(65536);
  oscProps.setListeningPort(LISTEN_PORT);
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
    s.rangeMax = 10.6;
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
  UIBase heliosPanel = new UIBase("heliosctl", UIBase.LAYOUT_HORIZONTAL);
  heliosPanel.label = "Helios";
  
  UIBase dacPanel = makeHeliosDACPanel();
  UIBase transformPanel = makeHeliosTransformPanel();
  UIBase geocorrectPanel = makeGeocorrectPanel();
  
  //UIBase panel3 = new UIBase("panel3", UIBase.LAYOUT_VERTICAL);
  //  XYPad pad2 = new XYPad("pad2", XYPad.KNOB);
  //  pad2.borderVisible = true;
  //  panel3.addChild(pad2);
  
  heliosPanel.addChild(dacPanel);
  heliosPanel.addChild(transformPanel);
  heliosPanel.addChild(geocorrectPanel);
  //heliosPanel.addChild(panel3);
  
  return heliosPanel;  
}

UIBase makeHeliosDACPanel() {
  String oscId = "/heliosctl/dac";
  UIBase dacPanel = new UIBase(oscId, UIBase.LAYOUT_VERTICAL);
    //dacPanel.borderVisible = true;

    Button laserActiveButton = new Button(String.format("%s/laseron", oscId), Button.TOGGLE);
      laserActiveButton.label = "LASER ON";
      laserActiveButton.onFillColor = color(128, 0, 0);
      laserActiveButton.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+laserActiveButton.oscId, laserActiveButton);
    Slider intensitySlider = new Slider(String.format("%s/intensity", oscId), Slider.HORIZONTAL);
      intensitySlider.label = "Intensity";
      intensitySlider.rangeMin = 0;
      intensitySlider.rangeMax = 255;
      intensitySlider.numberFormat = "%.0f";
      intensitySlider.oscEnabled = true;
      intensitySlider.forceInteger = true;
      OscListenerRegistry.register(OSCID_BASE+intensitySlider.oscId, intensitySlider);
    
    Slider ppsSlider = new Slider(String.format("%s/pps", oscId), Slider.HORIZONTAL);
      ppsSlider.label = "KPPS";
      ppsSlider.rangeMin = 1;
      ppsSlider.rangeMax = 65.535;
      ppsSlider.numberFormat = "%.3f";
      ppsSlider.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+ppsSlider.oscId, ppsSlider);
    
    ButtonGroup ppsButtons = makePPSButtons();
      ppsButtons.setOnStateChangeCallback(new Runnable() {
        public void run() {
          if (ppsButtons.activeButtonIndex > -1) {
            float value = ((Button)ppsButtons.children.get(ppsButtons.activeButtonIndex)).oscValue;
            float range = (ppsSlider.rangeMax - ppsSlider.rangeMin);
            float normValue = value / range - ppsSlider.rangeMin/range;
            ppsSlider.value = normValue;
          }
        }
      });

    oscId = "/eosctl";
    Button playButton = new Button(String.format("%s/clockenable", oscId), Button.TOGGLE);
      playButton.label = "PLAY";
      //laserActiveButton.onFillColor = color(128, 0, 0);
      playButton.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+playButton.oscId, playButton);
    
    DragNumber targetFPSNum = new DragNumber(String.format("%s/targetfps", oscId), "Target FPS", 90.0, 1, 200);
      targetFPSNum.numCtrl.numDecimals = 0;
      targetFPSNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+targetFPSNum.oscId, targetFPSNum.numCtrl);


    //DragNumberT2 dn2 = new DragNumberT2("dragnum2", "DragNum Type 2");

    UIBase spacer = new UIBase("spacer", UIBase.LAYOUT_NONE);
    spacer.borderVisible = false;
    
    dacPanel.addChild(laserActiveButton);
    dacPanel.addChild(intensitySlider);
    dacPanel.addChild(ppsSlider);
    dacPanel.addChild(ppsButtons);
    dacPanel.addChild(spacer);
    dacPanel.addChild(playButton);
    dacPanel.addChild(targetFPSNum);
    //dacPanel.addChild(dn2);
    dacPanel.addChild(spacer);
  
  return dacPanel;
}


UIBase makeHeliosTransformPanel() {
  String oscId = "/heliosctl/transform";
  UIBase panel = new UIBase(oscId, UIBase.LAYOUT_VERTICAL);
    //panel.borderColor = color(128,128,128);
    PresetControl psControl = new PresetControl(String.format("%s/preset", oscId));
      psControl.borderVisible = true;
      OscListenerRegistry.register(OSCID_BASE+psControl.children.get(0).oscId, psControl.children.get(0));
    DragNumber scaleNum = new DragNumber(String.format("%s/scale", oscId), "Scale", 20.0, 0.001, 400);
      scaleNum.numCtrl.numDecimals = 1;
      scaleNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+scaleNum.oscId, scaleNum.numCtrl);
    DragNumber2 translateXYNum = new DragNumber2(String.format("%s/translatex", oscId),
                                                 String.format("%s/translatey", oscId), "Translate",
                                                 -50.0, -677.0, -1024, 1024);
      translateXYNum.numCtrl1.numDecimals = 1;
      translateXYNum.numCtrl2.numDecimals = 1;
      translateXYNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+translateXYNum.numCtrl1.oscId, translateXYNum.numCtrl1);
      OscListenerRegistry.register(OSCID_BASE+translateXYNum.numCtrl2.oscId, translateXYNum.numCtrl2);
    DragNumber rotateNum = new DragNumber(String.format("%s/rotate", oscId), "Rotate", 0.0, -180, 180);
      rotateNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+rotateNum.oscId, rotateNum.numCtrl);
    ButtonGroup flipButtons = new ButtonGroup("flip", ButtonGroup.BUTTONMODE_TOGGLE, UIBase.LAYOUT_HORIZONTAL);
      Button bflipx = new Button(String.format("%s/flipx", oscId), Button.TOGGLE);
      bflipx.label = "X";
      bflipx.oscEnabled = true;
      Button bflipy = new Button(String.format("%s/flipy", oscId), Button.TOGGLE);
      bflipy.label = "Y";
      bflipy.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+bflipx.oscId, bflipx);
      OscListenerRegistry.register(OSCID_BASE+bflipy.oscId, bflipy);
      flipButtons.addChild(new Label("Flip"));
      flipButtons.addChild(new UIBase("spacer"));       
      flipButtons.addChild(bflipx);
      flipButtons.addChild(bflipy);
    UIBase spacer = new UIBase("spacer", UIBase.LAYOUT_NONE);
      spacer.borderVisible = false;

    panel.addChild(psControl);
    panel.addChild(scaleNum);
    panel.addChild(translateXYNum);
    panel.addChild(rotateNum);
    panel.addChild(flipButtons);
    panel.addChild(spacer);
    panel.addChild(spacer);
    panel.addChild(spacer);
    //panel.addChild(spacer);
    
  return panel;
}

UIBase makeGeocorrectPanel() {
  String oscId = "/heliosctl/geocorrect";
  UIBase panel = new UIBase(oscId, UIBase.LAYOUT_VERTICAL);
    DragNumber2 scaleNum = new DragNumber2(String.format("%s/scalex", oscId),
                                           String.format("%s/scaley", oscId), "Scale",
                                           100.0, 100.0, 0.001, 1000.0);
      scaleNum.numCtrl1.numDecimals = 1;
      scaleNum.numCtrl2.numDecimals = 1;
      scaleNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+scaleNum.numCtrl1.oscId, scaleNum.numCtrl1);
      OscListenerRegistry.register(OSCID_BASE+scaleNum.numCtrl2.oscId, scaleNum.numCtrl2);
    DragNumber2 shearNum = new DragNumber2(String.format("%s/shearx", oscId),
                                           String.format("%s/sheary", oscId), "Shear",
                                           0.0, 0.0, -1000.0, 1000.0);
      shearNum.numCtrl1.numDecimals = 1;
      shearNum.numCtrl2.numDecimals = 1;
      shearNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+shearNum.numCtrl1.oscId, shearNum.numCtrl1);
      OscListenerRegistry.register(OSCID_BASE+shearNum.numCtrl2.oscId, shearNum.numCtrl2);
    DragNumber2 keystoneNum = new DragNumber2(String.format("%s/keystonex", oscId),
                                              String.format("%s/keystoney", oscId), "Keystone",
                                              0.0, 0.0, -1000.0, 1000.0);
      keystoneNum.numCtrl1.numDecimals = 1;
      keystoneNum.numCtrl2.numDecimals = 1;
      keystoneNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+keystoneNum.numCtrl1.oscId, keystoneNum.numCtrl1);
      OscListenerRegistry.register(OSCID_BASE+keystoneNum.numCtrl2.oscId, keystoneNum.numCtrl2);
    DragNumber2 linearityNum = new DragNumber2(String.format("%s/linearityx", oscId),
                                               String.format("%s/linearityy", oscId), "Linearity",
                                               0.0, 0.0, -1000.0, 1000.0);
      linearityNum.numCtrl1.numDecimals = 1;
      linearityNum.numCtrl2.numDecimals = 1;
      linearityNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+linearityNum.numCtrl1.oscId, linearityNum.numCtrl1);
      OscListenerRegistry.register(OSCID_BASE+linearityNum.numCtrl2.oscId, linearityNum.numCtrl2);
    DragNumber2 bowNum = new DragNumber2(String.format("%s/bowx", oscId),
                                         String.format("%s/bowy", oscId), "Bow",
                                         0.0, 0.0, -1000.0, 1000.0);
      bowNum.numCtrl1.numDecimals = 1;
      bowNum.numCtrl2.numDecimals = 1;
      bowNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+bowNum.numCtrl1.oscId, bowNum.numCtrl1);
      OscListenerRegistry.register(OSCID_BASE+bowNum.numCtrl2.oscId, bowNum.numCtrl2);
    DragNumber2 pinNum = new DragNumber2(String.format("%s/pincushionx", oscId),
                                         String.format("%s/pincushiony", oscId), "Pincushion",
                                         0.0, 0.0, -1000.0, 1000.0);
      pinNum.numCtrl1.numDecimals = 1;
      pinNum.numCtrl2.numDecimals = 1;
      pinNum.oscEnabled = true;
      OscListenerRegistry.register(OSCID_BASE+pinNum.numCtrl1.oscId, pinNum.numCtrl1);
      OscListenerRegistry.register(OSCID_BASE+pinNum.numCtrl2.oscId, pinNum.numCtrl2);
    panel.addChild(new UIBase("spacer"));
    panel.addChild(scaleNum);
    panel.addChild(shearNum);
    panel.addChild(keystoneNum);
    panel.addChild(linearityNum);
    panel.addChild(bowNum);
    panel.addChild(pinNum);
    panel.addChild(new UIBase("spacer"));

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
  String fullOscId = String.format("%s%s", OSCID_BASE, oscid);
  println(String.format("eos_touchcontrol.oscSend(): %s ==> %f", fullOscId, val1));
  OscMessage msg = new OscMessage(fullOscId);
  msg.add(val1);
  oscP5.send(msg, heliosServerAddr);
}


void queueOscSendArray(final float[] val1, final String oscid) {
  if (gOscEnabled) {
    executor.execute(new Runnable() {
        @Override
        public void run() {
            oscSendArray(val1, oscid);
        }
    });
  }
}

void oscSendArray(float[] val1, String oscid) {
  String fullOscId = String.format("%s%s", OSCID_BASE, oscid);
  println(String.format("eos_touchcontrol.oscSendArray(): %s ==> float[%d]",
                        fullOscId, val1.length));
  OscMessage msg = new OscMessage(fullOscId);
  msg.add(val1);
  oscP5.send(msg, heliosServerAddr);
}



void oscEvent(OscMessage message) {
  String oscId = message.addrPattern();
  //println ("\tAddress: " + oscId);
  
  if (! oscId.startsWith(OSCID_BASE)) {
    print("eos_touchcontrol.oscEvent(): unknown address: " + oscId);
    return;
  }
  UIBase widget = OscListenerRegistry.getByOscId(oscId);
  if (widget == null) {
    println("eos_touchcontrol.oscEvent(): listener not found: " + oscId);
    return;
  }
  
  for (int i = 0; i < message.typetag().length(); i++) {
    char type = message.typetag().charAt(i);
    if (type == 'f') {
      //println("Float value: " + message.get(i).floatValue());
      float floatValue = message.get(i).floatValue();
      println(String.format("eos_touchcontrol.oscEvent(): received float %s: %f", oscId, floatValue));
      widget.setValue(floatValue);
      gPendingAnimFrames+=2;
      loop();
    } else if (type == 'i') { // Check if the argument is an int
      println("Int value: " + message.get(i).intValue());
    }
    else if (type == 's') { // String value
      String stringValue = message.get(i).stringValue();
      println(String.format("eos_touchcontrol.oscEvent(): received string %s: %s", oscId, stringValue));
      widget.setValue(stringValue);
      gPendingAnimFrames+=2;
      loop();
    }
    // Add more checks here for other data types (e.g., 's' for String)
  }
  
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
  
  public void set(float _x, float _y, float _w, float _h) {
    this.x = _x;
    this.y = _y;
    this.w = _w;
    this.h = _h;
  }

  public Boolean containsPoint(float px, float py) {
    return !((px<x) || (px>x+w) || (py<y) || (py>y+h));
  }
  public String toString() {
    return String.format("x: %f, y: %f, w: %f, h: %f", x,y,w,h); 
  }
}
