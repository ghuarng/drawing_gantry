import processing.serial.*;

final int MOTOR_STEPS = 200;
Serial sPort;
char val;

void setup(){
  sPort = new Serial(this, "COM5", 9600);
  val = 0;
  
  while(true){  
    if(val == 0){
      sendStr("DRAW");
    }
    else if(val == 1){
      println("DRAW " + str(MOTOR_STEPS));
      sendInstr('P', 'D', 0);
      sendInstr('S', 'R', MOTOR_STEPS);
      
      println("NEW ROW");
      sendInstr('P', 'U', 0);
      sendInstr('S', 'L', MOTOR_STEPS);
      sendInstr('S', 'D', 10);
    }
    else if(val == 2){
      for(int i = 1; i<10; i++){
        println("DRAW " + str(i*MOTOR_STEPS));
        sendInstr('P', 'D', 0);
        sendInstr('S', 'R', i*MOTOR_STEPS);
        
        println("NEW ROW");
        sendInstr('P', 'U', 0);
        sendInstr('S', 'L', i*MOTOR_STEPS);
        sendInstr('S', 'D', 10);
      }
    }
    else if(val == 3){
      sendStr("DONE");
      break;
    }
    val++;
  }
}

void draw(){
  //if(sPort.available() > 0){
  //  sPort.read(); //clear read buffer
  
  //  if(val == 0){
  //    sPort.write("DRAW");
  //    val++;
  //  }
  //  else if(val == 1){
  //    sendInstr('S', 'R', MOTOR_STEPS);
  //    val++;
  //  }
  //  else if(val == 2){
  //    sPort.write("DONE");
  //    val++;
  //  }
  //}
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
