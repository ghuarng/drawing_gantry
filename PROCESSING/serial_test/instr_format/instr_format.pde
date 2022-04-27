/*
 * Tests assembly of instruction packet
 */
void setup(){
  /*  Drawing instruction format
   *
   *  [0]  : 'P' | 'S'             -- Controlling Pen or Stepper
   *  [1]  : (U, D) | (U, D, L, R) -- Pen up/down, Stepper up/down/left/right
   *  
   *  (Only used for Stepper instructions)
   *  [2,3]: 16-bit integer stored across two bytes in big endian byte order
   */
  
  byte[] buffer = new byte[5];
  buffer[0] = 'S';  //stepper
  buffer[1] = 'R';  //right
  
  int steps = 892;
  int converted = 0;
  buffer[2] = byte(steps >> 8);
  buffer[3] = byte(steps & 0xFF);
  
  println(str(buffer));
  converted ^= buffer[3];
  converted ^= (buffer[2] << 8);
  print(converted);
}

void draw(){
}
