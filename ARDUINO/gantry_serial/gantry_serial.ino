#include <Arduino.h>
#include <Servo.h>
#include "BasicStepperDriver.h"
#include "gantry.h"

BasicStepperDriver stepperX(MOTOR_STEPS, X_DIR, X_STEP);
BasicStepperDriver stepperY(MOTOR_STEPS, Y_DIR, Y_STEP);

Servo penServo;

int offsetX = 0;
int offsetY = 0;
char penIsDown = 0;
char idle = 1;
byte buffer[5] = {0};
byte testBuffer[2] = {0x02, 0x37};

void setup() {
  Serial.begin(9600);

  //Set stepper speed to 200
  stepperX.begin(STEPPER_SLOW,1);  
  stepperY.begin(STEPPER_SLOW,1);

  penServo.attach(SERVO);
  Serial.println(int(testBuffer));
}

void loop() {
  //IDLE STATE -- WAIT FOR NEW DRAWING
  if(idle == 1){
    if(Serial.available() >= 4){
      Serial.readBytes(buffer, 4);
     
      if(strcmp(buffer, "DRAW") == 0){
        sendGantryToDraw();
        idle = 0;
      }
    }
  }

  //ACTIVE STATE -- DRAWING IMAGE
  else{
    if(Serial.available() >= 4){
      //Read instruction into buffer
      Serial.readBytes(buffer, 4);

      //Drawing finished
      if(strcmp(buffer, "DONE") == 0){
        sendGantryToOrigin();
        idle = 1;
      }

      //Set X Stepper to FAST
      else if(strcmp(buffer, "FAST") == 0){
        stepperX.setRPM(STEPPER_FAST);
      }

      //set X Stepper to SLOW
      else if(strcmp(buffer, "SLOW") == 0){
        stepperX.setRPM(STEPPER_SLOW);
      }

      //Pen servo
      else if(buffer[0] == 'P'){
        handlePenInstr(buffer);
      }

      //Stepper motor
      else if(buffer[0] == 'S'){
        handleStepperInstr(buffer);
      }
    }
  }
  delay(1);
  Serial.print('+'); //ready for next instruction
}

void handlePenInstr(byte buffer[]){
  //Pen up
  if(buffer[1] == 'U'){
    penUp();
  }
  else if(buffer[1] == 'D'){
    penDown();
  }
}

void handleStepperInstr(byte buffer[]){
  //steps to take
  unsigned int steps = 0;
  steps ^= buffer[3];
  steps ^= (buffer[2] << 8);

  char dir = char(buffer[1]);
  switch(dir){
    case 'U': //up
      moveY(-steps);
      break;
    case 'D': //down
      moveY(steps);
      break;
    case 'L': //left
      moveX(-steps);
      break;
    case 'R': //right
      moveX(steps);
      break;
  }
}

void penDown(){
  penServo.write(DOWN);
  stepperX.setRPM(200);
  delay(100);
}

void penUp(){
  penServo.write(UP);
  delay(100);
}

void moveX(int steps){
  stepperX.move(steps);
  offsetX += steps;
  delay(50);
}

void moveY(int steps){
  stepperY.move(steps);
  offsetY += steps;
  delay(50);
}

void drawBlack(int steps){
  penDown();
  stepperX.setRPM(200);
  moveX(steps);
}

void drawWhite(int steps){
  penUp();
  stepperX.setRPM(500);
  moveX(steps);
}

void sendGantryToDraw(){
  moveX(-11*MOTOR_STEPS);
  moveY(1*MOTOR_STEPS);
  penServo.write(UP);
  delay(1000);
}

void sendGantryToOrigin(){
  stepperX.setRPM(200);
  penServo.write(DONE);
  moveX(-offsetX);
  moveY(-offsetY);
}
