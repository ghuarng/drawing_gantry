#include <Servo.h>

#define SERVO 12

Servo myServo;

void setup() {
  Serial.begin(9600);
  myServo.attach(SERVO);
}

void loop() {
  // put your main code here, to run repeatedly:
  if(Serial.available() > 0){
    int msg = Serial.read();
    myServo.write(msg);
    Serial.println(msg);
  }
}
