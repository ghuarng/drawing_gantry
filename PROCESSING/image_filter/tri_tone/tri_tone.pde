import processing.serial.*;
import java.io.File;

PImage img;
PImage filtered;
int w = 160;
int DIMENSION = 200;
int SPACING = 5;
float THRESH_LVL = 0.5;
Serial sPort;
PrintWriter output;
int val = 0;

void setup() {
  size(200, 200);
  frameRate(30);
  
  sPort = new Serial(this, "COM5", 9600);
  String fileName = dataPath("gantry_instr.txt"); //delete file if exists
  File f = new File(fileName);
  if (f.exists()) {
    f.delete();
  }
  output = createWriter("gantry_instr.txt");
  
  //Main image
  img = loadImage("penrose_shaded.png");
  img.resize(DIMENSION, DIMENSION);
  img.filter(POSTERIZE, 3);
  img.filter(GRAY);
  image(img, 0, 0);
  
  drawLogo(DIMENSION, 0.3);
  save("unfiltered.jpg");

  //Processed Image
  PImage unfiltered = loadImage("unfiltered.jpg");
  processImage(unfiltered);
  save("filtered.jpg");
  
  filtered = loadImage("filtered.jpg");
}

void draw() {
  if(val == 0){
    val++;
  }

  if(val == 1){
    generateInstr();
    parseInstr();
    val++;
  }
}

void generateInstr(){
  //Draw bounds
  output.println("STR, DRAW");
  
  drawBounds();
  //drawBoundsPaper();
  drawGray();
  //drawBlack();
  
  output.println("STR, DONE");
  output.close();
}

void drawGray(){
  final int GRAY = 85;
  final int WHITE = 255;
  int curBlock = colorThresh(int(red(filtered.pixels[0]))); //BLACK, GRAY, WHITE
  int curColor; //BLACK, GRAY, WHITE
  int colOffset = 0;
  int px = 0;
  boolean penIsDown = false;
  boolean skip = false;
  int rowStart = 0;
  
  for(int i = 0; i < filtered.height; i+=5){ //skip some rows
    for(int j = rowStart; j < filtered.width; j++){
      if(skip == true){
        break;
      }
      int loc = j + filtered.width*i;
      curColor = colorThresh(int(red(filtered.pixels[loc])));
      
      if(j == filtered.width - 1){  //end of row
        if(curBlock == GRAY){  //draw
          px = j - colOffset;
          output.println("STR, SLOW");
          output.println("INS, P, D, 0");
          output.println("INS, S, R, " + str(px * SPACING));
          penIsDown=true;
          break;
        }
        else if(curBlock == WHITE){  //skip
          if(penIsDown == true){
             output.println("INS, P, U, 0");
             penIsDown=false;
          }
          break;  //no need to draw empty space
        }
      }
    
      else if(curColor != curBlock){  //new color block
        px = j - colOffset;
        colOffset = j;

        if(curBlock == WHITE){  //skip
          output.println("STR, FAST");
          output.println("INS, P, U, 0");
          penIsDown = false;
          curBlock = GRAY;
        }
        else if(curBlock == GRAY){  //draw
          output.println("STR, SLOW");
          output.println("INS, P, D, 0");
          penIsDown = true;
          curBlock = WHITE;
        }
        output.println("INS, S, R, " + str(px * SPACING));
      }
     
    }  
    
    if(penIsDown == true){
      output.println("INS, P, U, 0");
      penIsDown = false;
    }
    
    //Row optimizaiton, skip empty row / leading space
    if(colOffset > 0){
      output.println("STR, FAST");
      //output.println("INS, S, L, " + str(colOffset * X_SPACING));
      
      if(i < filtered.height-5){
        rowStart = findFirst(filtered, i+5);
        
        if(rowStart == 0){
          curBlock = WHITE; //skip
          skip = true;
        }
        else{
          curBlock = GRAY;
          skip = false;
          int diff = colOffset - rowStart;
          if(diff > 0){
            output.println("INS, S, L, " + str(diff * SPACING));
          }
          else if(diff < 0){
            output.println("INS, S, R, " + str(-diff * SPACING));
          }
          colOffset = rowStart;
        }
      }
    }
    
    output.println("INS, S, D, " + str(5 * SPACING));
  }
}
void parseInstr(){
  BufferedReader reader = createReader("gantry_instr.txt");
  String line = null;
    
  try{
    while((line = reader.readLine()) != null){
      String[] args = split(line, ", ");
      
      if(args[0].equals("STR")){
        println("sendStr(" + args[1] + ")");
        sendStr(args[1]);
      }
      else if(args[0].equals("INS")){
        println("sendInstr(" + args[1].charAt(0) + ", " + args[2].charAt(0) + ", " + args[3] + ")");
        sendInstr(args[1].charAt(0), args[2].charAt(0), int(args[3]));
      }
    } 
    reader.close();
  }
  catch(IOException e){
    e.printStackTrace();
  }
}

void processImage(PImage img){
  int xstart = 0;
  int ystart = 0;
  int xend = img.width;
  int yend = img.height;
  
  loadPixels();
  // Begin our loop for every pixel
  for (int x = xstart; x < xend; x++) {
    for (int y = ystart; y < yend; y++ ) {
      int loc = x + y*img.width;
      int rgbVal = colorThresh(int(red(img.pixels[loc])));
      color c = color(rgbVal, rgbVal, rgbVal); //placeholder
      
      pixels[loc] = c;
    }
  }

  updatePixels();
}

void sendInstr(char device, char dir, int steps){
  byte[] buffer = new byte[4];
  buffer[0] = byte(device);  //Stepper or Pen
  buffer[1] = byte(dir);     //Direction
  
  buffer[2] = byte(steps >> 8);
  buffer[3] = byte(steps & 0xFF);
  
  while(true){
    if(sPort.available() > 0){
      sPort.clear();
      for(int i=0; i<buffer.length; i++){
        sPort.write(buffer[i]);
      }
      return;
    }
    delay(1);
  }
}

void sendStr(String cmd){
  while(true){
    if(sPort.available() > 0){
      sPort.clear();
      sPort.write(cmd);
      return;
    }
    delay(1);
  }
}

int colorThresh(int val){
  if(val > 170){
    return 255;
  }
  else if(val >= 80){
    return 85;
  }
  else{
    return 0;
  }
}

int findFirst(PImage filtered, int i){
  int tempLoc;
  int tempColor;
  //find first DARK pixel of next row
  for(int k = 0; k < filtered.width; k++){ 
    tempLoc = k + filtered.width*i;
    tempColor = colorThresh(int(red(filtered.pixels[tempLoc])));
    
    if(tempColor < 170)
      return k;   

  }
  return 0;
}

void drawBounds(){
  output.println("INS, P, D, 0");
  
  output.println("INS, S, R, " + DIMENSION * SPACING);
  output.println("INS, S, D, " + DIMENSION * SPACING);
  output.println("INS, S, L, " + DIMENSION * SPACING);
  output.println("INS, S, U, " + DIMENSION * SPACING);
  
  output.println("INS, P, U, 0");
}

void drawBoundsPaper(){
  output.println("INS, P, D, 0");
  output.println("INS, S, R, " + DIMENSION * SPACING);
  output.println("INS, S, D, " + DIMENSION * SPACING);
  
  output.println("INS, P, U, 0");
  output.println("INS, S, L, " + DIMENSION * SPACING);
  output.println("INS, S, U, " + DIMENSION * SPACING);
  
  output.println("INS, P, D, 0");
  output.println("INS, S, D, " + DIMENSION * SPACING);
  output.println("INS, S, R, " + DIMENSION * SPACING);
  
  output.println("INS, P, U, 0");
  output.println("INS, S, L, " + DIMENSION * SPACING);
  output.println("INS, S, U, " + DIMENSION * SPACING);
}

void drawLogo(int DIMENSION, float thresh){
  PImage logo = loadImage("dapi.png");
  logo.filter(THRESHOLD, thresh);
  
  switch(DIMENSION){
    case(300):
      logo.resize(80, 80);
      image(logo, 225, 217);
      //image(logo, 240, 240);
      break;
    case(400):
      logo.resize(100, 100);
      image(logo, 307, 295);
      //image(logo, 310, 310);
      break;
  }
}
