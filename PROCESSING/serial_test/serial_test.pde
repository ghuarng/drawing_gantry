import processing.serial.*;

Serial sPort;
char val;

void setup(){
  String portName = Serial.list()[0]; 
  sPort = new Serial(this, portName, 9600);
  val = 0;
}

void draw(){
  if(sPort.available() > 0){
    sPort.read();
  
    if(val == 0){
      sPort.write("DRAW");
      val++;
      delay(2000);
    }
    else if(val == 1){
      sPort.write("DONE");
      val++;
    }
  }
}
