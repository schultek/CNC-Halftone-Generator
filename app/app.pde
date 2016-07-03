/* KEYS
enter: prerender image
w,a,s,d: move image
q,e: scale image
y, x, c, v: num of lines
left, right: distance between lines
+, -: size of milling-bit
l, j, i, k: size of border
up, down: steps per line (for dotted images choose a low number and set "dotted = true"
p: print gcode
f: show overlap of lines
z: export settings
t: inport settings
*/

//uncomment following line for dotted rendering
//boolean dotted = true;
//uncomment folliwing line for line rendering
boolean dotted = false;

//set dimensions of your milling-bit
//use a cone-shaped bit
float bitW = 3.125; //widest diameter (mm)
float bitH = 4.9; //height between apex of the cone and place of widest diameter (mm)
float bitMin = 0.15; //diameter at apex of the cone (mm)

//set dimensions of your material
float materialW = 300; // width of material (mm)
float materialH = 200; // height of material (mm)
float borderW = 20; // width of border (mm)
float borderH = 20; // height of border (mm)

//set milling-speed
float hOut = 2.0; // offset to material
float sIn = 150; // Feedrate
float sOut = 700; // Seekrate



PImage image;
int linesL = 10;
int linesR = 10;
float distance = 4;
ArrayList<ArrayList<Point>> avgs = new ArrayList<ArrayList<Point>>();
ArrayList<Point[]> errors = new ArrayList<Point[]>();
int steps = 200;
float maxRad = 3.1;
float angle = 0;
boolean aH = false;
boolean render = false;
float minFree = 0;
float imgW;
float imgF = 1;
float imgX = 0;
float imgY = 0;
boolean imgHo = false;
float[] ms = {0,0};
float scF;
float materialX;
float materialY;
Point[] curve = new Point[4];

void keyPressed() {
  if (key == CODED) {
    switch(keyCode) {
    case UP: 
      steps++; 
      break;
    case DOWN: 
      steps--; 
      break;
    case LEFT:
      distance -= 0.1;
      break;
    case RIGHT:
      distance += 0.1;
      break;
    }
    if (render) {
      imgFilter();
    }
  } else {
    if (key == '+') {
      maxRad += 0.1;
      if (maxRad > bitW) {
        maxRad = bitW;
      }
    }
    if (key == '-') {
      maxRad -= 0.1;
    }
    if (key == 'w') {
      imgY--;
    }
    if (key == 's') {
      imgY++;
    }
    if (key == 'a') {
      imgX--;
    }
    if (key == 'd') {
      imgX++;
    }
    if (key == 'q') {
      imgW-=5;
    }
    if (key == 'e') {
      imgW+=5;
    }
    if (key == 'l') {
      borderW++;
    }
    if (key == 'j') {
      borderW++;
    }
    if (key == 'i') {
      borderH++;
    }
    if (key == 'k') {
      borderH--;
    }
    if (key == 'y') {
      linesL++;
    }
    if (key == 'x') {
      linesL--;
    }
    if (key == 'c') {
      linesR--;
    }
    if (key == 'v') {
      linesR++;
    }
    if (key == 'p') {
      selectOutput("Select a file to write to:", "printGcode");
    }
    if (key == 'f') {
      getErrors();
    }
    if (key == 'z') {
      selectOutput("Select a file to write to:", "exportSettings");
    }
    if (key == 't') {
      selectInput("Select a file to import:", "importSettings");
    }
    
    if (key == ENTER) {
      render = true;
    }
    
    if (render) {
      imgFilter();
    }
  }
}


void setup() {
  size(1700, 800);
  curve[0] = new Point(materialW/2-20, materialH/2-20);
  curve[1] = new Point(materialW/2-10, 5);
  curve[2] = new Point(materialW/2+10, materialH-5);
  curve[3] = new Point(materialW/2+20, materialH/2+20);

  
  scF = min((float)width/materialW, (float)height/materialH);
  materialX = ((width/scF)-materialW)/2;
  materialY = ((height/scF)-materialH)/2;
  
  if (dotted) {
    hOut = 0.7;
    sIn = 500;
    sOut = 1200;
  }
  selectInput("Select a file to process:", "fileSelected");
}

void draw() {
  background(255);
  translate(materialX,materialY);
  
  if (!render && image != null) {
    image(image, imgX*scF, imgY*scF, imgW*scF, imgW*scF*imgF);
  }
   
  if (render) {
    
    fill(0);
    noStroke();
    for (int i = 0; i < avgs.size(); i++) {
      for (int j = 0; j < avgs.get(i).size(); j++) {
        ellipse(avgs.get(i).get(j).x*scF, avgs.get(i).get(j).y*scF, avgs.get(i).get(j).data*scF, avgs.get(i).get(j).data*scF);
      }
    }
    
    stroke(255,0,0);
    for (int i = 0; i < errors.size(); i++) {
      line(errors.get(i)[0].x*scF, errors.get(i)[0].y*scF, errors.get(i)[1].x*scF, errors.get(i)[1].y*scF);
    }
    
    
  }

  fill(255);
  noStroke();
  rect(0,0,(int)borderW/2, height);
  rect(0,0,width, (int)borderH/2);
  rect(width-(borderW/2),0,(int)borderW/2, height);
  rect(0,height-(borderH/2),width, (int)borderH/2);
  
  
  translate(-materialX,-materialY);
  fill(30);
  rect(0,0,materialX,height);
  rect(0,0,width,materialY);
  rect(0,height-materialY,width,materialY);
  rect(width-materialX,0,materialX,height);
  
  translate(materialX,materialY);
  if (!render) {
    noFill();
    stroke(0);
    beginShape();
    vertex(curve[1].x*scF, curve[1].y*scF);
    bezierVertex(curve[0].x*scF,curve[0].y*scF,curve[3].x*scF,curve[3].y*scF,curve[2].x*scF,curve[2].y*scF);
    endShape();
   
    stroke(255, 0, 0);
    curve[0].draw(scF);
    curve[1].draw(scF);
    curve[2].draw(scF);
    curve[3].draw(scF);
    
    float mx = curve[1].x + (curve[2].x - curve[1].x)/2;
    float my = curve[1].y + (curve[2].y - curve[1].y)/2;
    ellipse(mx*scF, my*scF, 50, 50);
    line(mx*scF, my*scF, mx*scF + (cos(radians(angle))*25), my*scF - (sin(radians(angle))*25));
 
  } else {
    
    stroke(0);
    fill(0);
    text(minFree,5,10);
    text(steps,50,10);
    text(distance,90,10);
    text(maxRad, 130,10);
  }
  translate(-materialX,-materialY);
}

void imgFilter() {
  avgs = new ArrayList<ArrayList<Point>>();
  avgs.add(new ArrayList<Point>());
  for (float i = 0; i <= 1; i += (float)1/steps) {
    Point p = getCurvePoint(i);
    avgs.get(0).add(new Point(p.x, p.y, getAVG(p)));
  }
  for (int i = 1; i < linesR; i++) {
    float offsetx = i*distance*cos(radians(angle));
    float offsety = i*distance*(-sin(radians(angle)));
    avgs.add(new ArrayList<Point>());
    for (float j = 0; j <= 1; j += (float)1/steps) {
      Point p = getCurvePoint(j);
      Point p1 = new Point(p.x+offsetx, p.y+offsety);
      if (p1.x > 0 && p1.x < width && p1.y > 0 && p1.y < height) {
        avgs.get(avgs.size()-1).add(new Point(p1.x, p1.y, getAVG(p1)));
      }
    }
  }
  for (int i = 1; i < linesL; i++) {
    float offsetx = i*distance*cos(radians(angle));
    float offsety = i*distance*(-sin(radians(angle)));
    avgs.add(0, new ArrayList<Point>());
    for (float j = 0; j <= 1; j += (float)1/steps) {
      Point p = getCurvePoint(j);
      Point p2 = new Point(p.x-offsetx, p.y-offsety);
      if (p2.x > 0 && p2.x < width && p2.y > 0 && p2.y < height) {
        avgs.get(0).add(new Point(p2.x, p2.y, getAVG(p2)));
      }
    }
  }
}

float getAVG(Point p) {
  float sum = 0;
  float count = 0;
  float rad = maxRad/2;
  float factor = image.width/imgW;
  image.loadPixels();
  for (int x = (int)(p.x*factor - rad*factor - imgX*factor); x < p.x*factor + rad*factor - imgX*factor; x += 1) {
    if (x < 0 || x >= image.width) { 
      continue;
    }
    for (int y = (int)(p.y*factor -rad*factor -imgY*factor); y<p.y*factor +rad*factor -imgY*factor; y += 1) {
      if (y < 0 || y >= image.height) { 
        continue;
      }
      sum += red(image.pixels[y*image.width+x]);
      count+=1;
    }
  }
  image.updatePixels();
  
  float data = (255-(sum / count))/255*maxRad;
  if (data < bitMin) {data = 0;}
  return data;
}


Point getCurvePoint(float f) {  

  float xa = curve[1].x + (f * (curve[0].x - curve[1].x));
  float ya = curve[1].y + (f * (curve[0].y - curve[1].y));
  float xb = curve[0].x + (f * (curve[3].x - curve[0].x));
  float yb = curve[0].y + (f * (curve[3].y - curve[0].y));
  float xc = curve[3].x + (f * (curve[2].x - curve[3].x));
  float yc = curve[3].y + (f * (curve[2].y - curve[3].y));

  float xab = xa + (f * (xb - xa));
  float yab = ya + (f * (yb - ya));
  float xbc = xb + (f * (xc - xb));
  float ybc = yb + (f * (yc - yb));

  float xabc = xab + (f * (xbc - xab));
  float yabc = yab + (f * (ybc - yab));

  return new Point(xabc, yabc);
}

void printGcode(File selection) {
  if (selection == null) {
    return;
  }
  ArrayList<String> output = new ArrayList<String>();
  boolean in = false;
  output.add("G92 X0 Y0 Z0");
  output.add("G21");
  output.add("G90");
  output.add("G1 Z5.0 F180.0");
  for (int i = 0; i < avgs.size(); i++) {
    for (int j = 0; j < avgs.get(i).size(); j++) {
      Point p = new Point(avgs.get(i).get(j).x, avgs.get(i).get(j).y, avgs.get(i).get(j).data);
      p.y = materialH-p.y;
      if (p.x < borderW/2 || p.x > materialW-(borderW/2) || p.y < materialH/2 || p.y > materialH-(borderH/2)) {
        if (in) {
          output.add("G1 Z"+hOut+" F"+sIn);
          in = false;
        }
        continue;
      }
      if (dotted) {
        if (p.data > 0) {
          output.add("G0 X"+p.x+" Y"+p.y+" F"+sOut);
          output.add("G1 Z"+(-(p.data/bitW)*bitH)+" F"+sIn);
          output.add("G1 Z"+hOut+" F"+sIn);
        }
      } else {
        if (in) {
          if (p.data > 0) {
            output.add("G1 X"+p.x+" Y"+p.y+" Z"+(-(p.data/bitW)*bitH)+" F"+sIn);
          } else {
            output.add("G1 Z"+hOut+" F"+sIn);
            in = false;
          }
        } else {
          if (p.data > 0) {
            output.add("G0 X"+p.x+" Y"+p.y+" F"+sOut);
            output.add("G1 Z"+(-(p.data/bitW)*bitH)+" F"+sIn);
            in = true;
          }
        }
      }
    }
    if (in) {
      output.add("G1 Z"+hOut+" F"+sIn);
      in = false;
    }
  }
  if (in) {
    output.add("G1 Z"+hOut+" F"+sIn);
    in = false;
  }
  output.add("G0 X0.000 Y0.000 F"+sOut);
  String[] gcode = output.toArray(new String[output.size()]);
  saveStrings(selection.getAbsolutePath(), gcode);
}

void getErrors() {
  minFree = 0;
  errors = new ArrayList<Point[]>();
  for (int i = 0; i < avgs.size(); i++) {
    for (int i2 = 0; i2 < avgs.get(i).size(); i2++) {
      for (int j = 0; j < avgs.size(); j++) {
        for (int j2 = 0; j2 < avgs.get(j).size(); j2++) {
          float r = sqrt(sq(avgs.get(i).get(i2).x - avgs.get(j).get(j2).x) + sq(avgs.get(i).get(i2).y - avgs.get(j).get(j2).y));
          if ((dotted && (i != j || i2 != j2)) || (!dotted && (i != j && i2 != j2))) {
            if (r <= (avgs.get(i).get(i2).data/2) + (avgs.get(j).get(j2).data/2)) {
              errors.add(new Point[]{avgs.get(i).get(i2), avgs.get(j).get(j2)});
            }
            float free = r - ((avgs.get(i).get(i2).data/2) + (avgs.get(j).get(j2).data/2));
            if (minFree == 0 || free < minFree) {
              minFree = free;
            }
          }
        }
      }
    }
  }
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    String file = selection.getAbsolutePath();
    image = loadImage(file);
    imgW = materialW;
    imgF = (float)image.height/image.width;
    image.filter(GRAY);
  }
}

void exportSettings(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    return;
  }
  ArrayList<String> output = new ArrayList<String>();
  output.add(str(linesL));
  output.add(str(linesR));
  output.add(str(distance));
  output.add(str(steps));
  output.add(str(maxRad));
  output.add(str(angle));
  output.add(str(dotted));
  output.add(str(materialW));
  output.add(str(materialH));
  output.add(str(bitW));
  output.add(str(bitH));
  output.add(str(bitMin));
  output.add(str(borderW));
  output.add(str(borderH));
  output.add(str(hOut));
  output.add(str(sIn));
  output.add(str(sOut));
  output.add(str(curve[0].x));
  output.add(str(curve[0].y));
  output.add(str(curve[1].x));
  output.add(str(curve[1].y));
  output.add(str(curve[2].x));
  output.add(str(curve[2].y));
  output.add(str(curve[3].x));
  output.add(str(curve[3].y));  
  String[] settings = output.toArray(new String[output.size()]);
  saveStrings(selection.getAbsolutePath(), settings);
}

void importSettings(File selection) {
  String[] settings = loadStrings(selection.getAbsolutePath());
  linesL = Integer.parseInt(settings[0]);
  linesR = Integer.parseInt(settings[1]);
  distance = Float.parseFloat(settings[2]);
  steps = Integer.parseInt(settings[3]);
  maxRad = Float.parseFloat(settings[4]);
  angle = Float.parseFloat(settings[5]);
  dotted = Boolean.parseBoolean(settings[6]);
  materialW = Float.parseFloat(settings[7]);
  materialH = Float.parseFloat(settings[8]);
  bitW = Float.parseFloat(settings[9]);
  bitH = Float.parseFloat(settings[10]);
  bitMin = Float.parseFloat(settings[11]);
  borderW = Float.parseFloat(settings[12]);
  borderH = Float.parseFloat(settings[13]);
  hOut = Float.parseFloat(settings[14]);
  sIn = Float.parseFloat(settings[15]);
  sOut = Float.parseFloat(settings[16]);
  curve[0].x = Float.parseFloat(settings[17]);
  curve[0].y = Float.parseFloat(settings[18]);
  curve[1].x = Float.parseFloat(settings[19]);
  curve[1].y = Float.parseFloat(settings[20]);
  curve[2].x = Float.parseFloat(settings[21]);
  curve[2].y = Float.parseFloat(settings[22]);
  curve[3].x = Float.parseFloat(settings[23]);
  curve[3].y = Float.parseFloat(settings[24]);
  
  surface.setSize((int)materialW, (int)materialH);
  if (render) {
    imgFilter();
  }
}

void mouseMoved() {
  int refX = (int)(mouseX/scF - materialX);
  int refY = (int)(mouseY/scF - materialY);
  for (int i = 0; i < curve.length; i++) {
    if (curve[i].hover(refX, refY)) {
      return;
    }
  }
  float mx = curve[1].x + (curve[2].x - curve[1].x)/2;
  float my = curve[1].y + (curve[2].y - curve[1].y)/2;
  if (refX > mx - 10 && refX < mx + 10 && refY > my - 10 && refY < my + 10) {
    aH = true;
    return;
  } else {
    aH = false;
  }
  if (refX > imgX && refX < imgX + imgW*scF && refY > imgY && refY < imgY + (imgW*imgF*scF)) {
    imgHo = true;
    ms[0] = refX;
    ms[1] = refY;
    return;
  } else {
    imgHo = false;
  }
}

void mouseDragged() {
  int refX = (int)(mouseX/scF - materialX);
  int refY = (int)(mouseY/scF - materialY);
  for (int i = 0; i < curve.length; i++) {
    if (curve[i].press(refX, refY)) {
      //imgFilter();
      return;
    }
  }
  float mx = curve[1].x + (curve[2].x - curve[1].x)/2;
  float my = curve[1].y + (curve[2].y - curve[1].y)/2;
  if (aH) {
    float r = sqrt(sq(mx - refX) + sq(my - refY));
    if (refY - my > 0) { 
      angle = degrees(acos((float)(refX - mx)/(-r))) + 180;
    } else {
      angle = degrees(acos((float)(refX - mx)/r));
    }
    return;
    //imgFilter();
  }
  if (imgHo) {
    imgX += refX - ms[0];
    imgY += refY - ms[1];
    ms[0] = refX;
    ms[1] = refY;
    return;
  }
}

public class Point {

  public float x, y, data;
  public boolean hovered;
  public int size = 10;

  public Point(float xPos, float yPos) {
    x = xPos;
    y = yPos;
    hovered = false;
  }

  public Point(float xPos, float yPos, float d) {
    this(xPos, yPos);
    data = d;
  }

  public void draw() {
    noFill();
    ellipse(x, y, size, size);
  }
  
  public void draw(float scale) {
    noFill();
    ellipse(x*scale, y*scale, size, size);
  }

  public boolean press(int mx, int my) {
    if (hovered) {
      x = mx;
      y = my;
      return true;
    } else {
      return false;
    }
  }

  public boolean hover(int mx, int my) {
    if (mx > x-size && mx < x+size && my > y-size && my < y+size) {
      hovered = true;
      size = 20;
    } else {
      hovered = false;
      size = 10;
    }
    return hovered;
  }
}