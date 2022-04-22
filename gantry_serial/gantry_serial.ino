#include <Arduino.h>
#include <Servo.h>
#include "BasicStepperDriver.h"
#include "gantry.h"

BasicStepperDriver stepperX(MOTOR_STEPS, X_DIR, X_STEP);
BasicStepperDriver stepperY(MOTOR_STEPS, Y_DIR, Y_STEP);

Servo penServo;

int offsetX = 0;
int offsetY = 0;
char idle = 1;
byte buffer[5] = {0};

void setup() {
  Serial.begin(9600);

  //Set stepper speed to 200
  stepperX.begin(200,1);  
  stepperY.begin(200,1);

  penServo.attach(SERVO);
}

void loop() {
  if(idle == 1){
    delay(10);
    
    if(Serial.available() > 0){
      Serial.readBytes(buffer, 5);
     
      if(strcmp(buffer, "DRAW") == 0){
        sendGantryToDraw();
        idle = 0;
      }
    }
  }
  
  else{
    if(Serial.available() > 0){
      Serial.readBytes(buffer, 5);
     
      if(strcmp(buffer, "DONE") == 0){
        sendGantryToOrigin();
        idle = 1;
      }
      //else
        //if Pen
          //if up,down
          
        //if Stepper
          //if up, down, left, right 
    }
  }

  Serial.print('+'); //ready for next instruction
}

void penDown(){
  penServo.write(DOWN);
  delay(300);
}

void penUp(){
  penServo.write(UP);
  delay(300);
}

void moveX(int steps){
  stepperX.move(steps);
  offsetX += steps;
  delay(200);
}

void moveY(int steps){
  stepperY.move(steps);
  offsetY += steps;
  delay(200);
}

void sendGantryToDraw(){
  moveX(-10*MOTOR_STEPS);
  moveY(2*MOTOR_STEPS);
  penServo.write(DOWN);
  delay(2000);
}

void sendGantryToOrigin(){
  penServo.write(DONE);
  moveX(-offsetX);
  moveY(-offsetY);
}
