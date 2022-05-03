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
byte testBuffer[2] = {0x02, 0x37};

void setup() {
  Serial.begin(9600);

  //Set stepper speed to 200
  stepperX.begin(200,1);  
  stepperY.begin(200,1);

  penServo.attach(SERVO);
  Serial.println(int(testBuffer));
}

void loop() {
  //IDLE STATE -- WAIT FOR NEW DRAWING
  if(idle == 1){
    delay(10);
    
    if(Serial.available() > 0){
      Serial.readBytes(buffer, 4);
     
      if(strcmp(buffer, "DRAW") == 0){
        sendGantryToDraw();
        idle = 0;
      }
    }
  }

  //ACTIVE STATE -- DRAWING IMAGE
  else{
    if(Serial.available() > 0){
      //Read instruction into buffer
      Serial.readBytes(buffer, 4);

      //Drawing finished
      if(strcmp(buffer, "DONE") == 0){
        sendGantryToOrigin();
        idle = 1;
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
      moveX(-200);
      //penServo.write(90);
      break;
    case 'R': //right
      moveX(200);
      //penServo.write(180);
      break;
  }
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
