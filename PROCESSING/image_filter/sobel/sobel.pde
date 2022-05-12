import processing.serial.*;
import java.io.File;

PImage img;
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
  size(200, 200);
  frameRate(30);
  
  sPort = new Serial(this, "COM5", 9600);
  String fileName = dataPath("gantry_instr.txt"); //delete file if exists
  File f = new File(fileName);
  if (f.exists()) {
    f.delete();
  }
  output = createWriter("gantry_instr.txt");
  
  img = loadImage("bike.jpg");
  img.resize(200, 200);
  img.filter(GRAY);
  
  //processImage();
  //generateInstr();
  //parseInstr();
}

void draw() {
  image(img, 0, 0);
  processImage();

  if(val == 0){
    generateInstr();
    parseInstr();
    val++;
  }
}

void generateInstr(){
  final int BLACK = 0;
  final int WHITE = 255;
  final int X_SPACING = 10;
  final int Y_SPACING = 10;
  int curColor; //BLACK or WHITE
  int colOffset = 0;
  int px = 0;
  
  //output.println("BEGIN DRAWING");
  output.println("STR, DRAW");
  //sendStr("DRAW");
  
  for(int i = 0; i < img.height; i++){
    colOffset = 0;
    curColor = int(red(img.pixels[img.width*i]));

    for(int j = 0; j < img.width; j++){
      int loc = j + img.width*i;
      
      if(j == img.width - 1){  //end of row
        px = j - colOffset;
      
        if(curColor == WHITE){  //draw
          //output.println("DRAW " + str(steps));
          output.println("STR, SLOW");
          output.println("INS, P, D, 0");
          output.println("INS, S, R, " + str(px * X_SPACING));
          //sendStr("SLOW");
          //sendInstr('P', 'D', 0);
          //sendInstr('S', 'R', steps * X_SPACING);
        }
        else if(curColor == BLACK){  //skip
          break;  //no need to draw empty space
        }
      }
    
      else if(int(red(img.pixels[loc])) != curColor){  //new color block
        px = j - colOffset;
        colOffset = j;

        if(curColor == WHITE){  //draw
          //output.println("DRAW " + str(steps));
          output.println("STR, SLOW");
          output.println("INS, P, D, 0");
          //sendStr("SLOW");
          //sendInstr('P', 'D', 0);
          curColor = BLACK;
        }
        else if(curColor == BLACK){  //skip
          //output.println("SKIP " + str(steps));
          output.println("STR, FAST");
          output.println("INS, P, U, 0");
          //sendStr("FAST");
          //sendInstr('P', 'U', 0);
          curColor = WHITE;
        }
        output.println("INS, S, R, " + str(px * X_SPACING));
        //sendInstr('S', 'R', steps * X_SPACING);
      }
     
    }  
    
    //output.println("NEW ROW");
    output.println("STR, FAST");
    output.println("INS, P, U, 0");
    output.println("INS, S, L, " + str(colOffset * X_SPACING));
    output.println("INS, S, D, " + str(Y_SPACING));
    //sendInstr('P', 'U', 0);
    //sendInstr('S', 'L', colOffset * X_SPACING);
    //sendInstr('S', 'D', Y_SPACING);
  }
  
  //output.println("FINISHED DRAWING");
  output.println("STR, DONE");
  //sendStr("DONE");
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
