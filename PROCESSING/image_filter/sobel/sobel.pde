PImage img;
int w = 160;

// It's possible to perform a convolution
// the image with different matrices

//float[][] matrix = { { -1, -1, -1 },
//                     { -1,  9, -1 },
//                     { -1, -1, -1 } 

float[][] kernel_X = { { -1,  0, 1 },
                       { -2,  0, 2 },
                       { -1,  0, 1 } };

float[][] kernel_Y = { { -1, -2, -1 },
                       {  0,  0,  0 },
                       {  1, 2, 1 } };

void setup() {
  size(500, 500);
  frameRate(30);
  img = loadImage("steam.png");
  img.resize(500, 500);
  img.filter(GRAY);
}

void draw() {
  // We're only going to process a portion of the image
  // so let's set the whole image as the background first
  image(img,0,0);
  //img.filter(THRESHOLD, 0.5);

  // Where is the small rectangle we will process
  //int xstart = constrain(mouseX-w/2,0,img.width);
  //int ystart = constrain(mouseY-w/2,0,img.height);
  //int xend = constrain(mouseX+w/2,0,img.width);
  //int yend = constrain(mouseY+w/2,0,img.height);
  int xstart = 0;
  int ystart = 0;
  int xend = img.width;
  int yend = img.height;
  int matrixsize = 3;
  loadPixels();
  // Begin our loop for every pixel
  for (int x = xstart; x < xend; x++) {
    for (int y = ystart; y < yend; y++ ) {
      // Each pixel location (x,y) gets passed into a function called convolution()
      // which returns a new color value to be displayed.
      float mag = sobel(x,y,kernel_X,kernel_Y,matrixsize,img);
      int loc = x + y*img.width;
      color c = color(mag, mag, mag);
      
      pixels[loc] = c;
    }
  }
  updatePixels();

  stroke(0);
  noFill();
  rect(xstart,ystart,w,w);
}

float sobel(int x, int y, float[][] kernel_X, float[][] kernel_Y, int matrixsize, PImage img) {
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
      
      //println(mag);
      
      //rtotal += (red(img.pixels[loc]) * matrix[i][j]);
      //gtotal += (green(img.pixels[loc]) * matrix[i][j]);
      //btotal += (blue(img.pixels[loc]) * matrix[i][j]);      
    }
  }
  
  float mag = sqrt(sq(magX) + sq(magY));
  return mag;
}
