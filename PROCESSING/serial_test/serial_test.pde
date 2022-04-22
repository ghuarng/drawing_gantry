import processing.serial.*;

Serial sPort;
char val;

void setup(){
  String portName = Serial.list()[0]; 
  sPort = new Serial(this, portName, 9600);
  val = 0;
}

void draw(){
  while(sPort.available() <= 0);
  
    if(val > 180)
      val = 0;
    
    delay(500);
    sPort.write(val);
    val += 20;
    
    char msg = (char) sPort.read();
    print(msg);
  
}
