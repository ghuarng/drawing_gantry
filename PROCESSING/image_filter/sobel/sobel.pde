import processing.serial.*;
import java.io.File;

PImage img;
PImage filtered;
int w = 160;
Serial sPort;
PrintWriter output;
int val = 0;

float[][] kernel_X = { { -1,  0, 1 },
                       { -2,  0, 2 },
                       { -1,  0, 1 } };

float[][] kernel_Y = { { -1, -2, -1 },
                       {  0,  0,  0 },
                       {  1, 2, 1 } };

void setup() {
  size(400, 400);
  frameRate(30);
  
  sPort = new Serial(this, "COM5", 9600);
  String fileName = dataPath("gantry_instr.txt"); //delete file if exists
  File f = new File(fileName);
  if (f.exists()) {
    f.delete();
  }
  output = createWriter("gantry_instr.txt");
  
  img = loadImage("chungus.png");
  img.resize(400, 400);
  img.filter(GRAY);
  image(img, 0, 0);
  processImage();
  save("filtered.jpg");
  
  filtered = loadImage("filtered.jpg");
  image(filtered, 0, 0);

  //generateInstr();
  //parseInstr();
}

void draw() {
  //image(img, 0, 0);
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
  //PImage filtered = loadImage("filtered.jpg");
  final int BLACK = 0;
  final int WHITE = 255;
  final int X_SPACING = 5;
  final int Y_SPACING = 5;
  int curBlock; //BLACK or WHITE
  int curColor; //BLACK or WHITE
  int colOffset = 0;
  int px = 0;
  boolean penIsDown = false;
  
  output.println("STR, DRAW");
  
  for(int i = 0; i < filtered.height; i++){
    colOffset = 0;
    curBlock = colorThresh(int(red(filtered.pixels[filtered.width*i])));

    for(int j = 0; j < filtered.width; j++){
      int loc = j + filtered.width*i;
      curColor = colorThresh(int(red(filtered.pixels[loc])));
      
      if(j == filtered.width - 1){  //end of row
        if(curBlock == WHITE){  //draw
          px = j - colOffset;
          output.println("STR, SLOW");
          output.println("INS, P, D, 0");
          output.println("INS, S, R, " + str(px * X_SPACING));
          penIsDown=true;
          break;
        }
        else if(curBlock == BLACK){  //skip
          //colOffset = j;
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


        if(curBlock == BLACK){  //skip
          output.println("STR, FAST");
          output.println("INS, P, U, 0");
          penIsDown = false;
          curBlock = WHITE;
        }
        else if(curBlock == WHITE){  //draw
          output.println("STR, SLOW");
          output.println("INS, P, D, 0");
          penIsDown = true;
          curBlock = BLACK;
        }
        output.println("INS, S, R, " + str(px * X_SPACING));
      }
     
    }  
    
    if(penIsDown == true){
      output.println("INS, P, U, 0");
      penIsDown = false;
    }
    if(colOffset > 0){
      output.println("STR, FAST");
      output.println("INS, S, L, " + str(colOffset * X_SPACING));
    }
    
    output.println("INS, S, D, " + str(Y_SPACING));
  }
  
  output.println("STR, DONE");
  output.close();
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

void processImage(){
  int xstart = 0;
  int ystart = 0;
  int xend = img.width;
  int yend = img.height;
  int matrixsize = 3;
  
  loadPixels();
  // Begin our loop for every pixel
  for (int x = xstart; x < xend; x++) {
    for (int y = ystart; y < yend; y++ ) {
      float mag = sobelFilter(x,y,kernel_X,kernel_Y,matrixsize,img);
      int loc = x + y*img.width;
      color c = color(mag, mag, mag);
      
      pixels[loc] = c;
    }
  }
  img.filter(THRESHOLD, 0.5);

  updatePixels();
}

float sobelFilter(int x, int y, float[][] kernel_X, float[][] kernel_Y, int matrixsize, PImage img) {
  float magX = 0.0;
  float magY = 0.0;
  
  int offset = matrixsize / 2;
  // Loop through convolution matrix
  for (int i = 0; i < matrixsize; i++){
    for (int j= 0; j < matrixsize; j++){
      // What pixel are we testing
      int xloc = x+i-offset;
      int yloc = y+j-offset;
      int loc = xloc + img.width*yloc;
      // Make sure we have not walked off the edge of the pixel array
      loc = constrain(loc,0,img.pixels.length-1);
      // Calculate the convolution
      // We sum all the neighboring pixels multiplied by the values in the convolution matrix.
     
      magX += red(img.pixels[loc]) * kernel_X[i][j];
      magY += red(img.pixels[loc]) * kernel_Y[i][j];
    }

  }
  
  float mag = sqrt(sq(magX) + sq(magY));
  return mag;
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
  if(val > 128){
    return 255;
  }
  else{
    return 0;
  }
}
