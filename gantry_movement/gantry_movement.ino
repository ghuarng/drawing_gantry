#include <Arduino.h>
#include <Servo.h>
#include "BasicStepperDriver.h"

#define MOTOR_STEPS 200 //1.8 deg/step; Each rotation ~2cm

//X Motor (+ RIGHT, - LEFT)
#define X_DIR  3
#define X_STEP 4

//Y Motor (+ DOWN, - UP)
#define Y_DIR  6
#define Y_STEP 7

//Servo 
#define SERVO 2
#define UP    135 //servo angles
#define DOWN  148
#define DONE  90

void penDown();
void moveX(int steps);
void moveY(int steps);
void sendGantryToDraw();
void sendGantryToOrigin();

BasicStepperDriver stepperX(MOTOR_STEPS, X_DIR, X_STEP);
BasicStepperDriver stepperY(MOTOR_STEPS, Y_DIR, Y_STEP);

Servo penServo;

int offsetX = 0;
int offsetY = 0;

void setup() {
  stepperX.begin(200,1);
  stepperY.begin(200,1);
  penServo.attach(SERVO);
  penServo.write(UP);
  
  sendGantryToDraw();

  //drawSquare();
  drawMember();
  //amogus();
  //scan();
  
  sendGantryToOrigin();
}

void loop() {
//  stepperX.move(13*MOTOR_STEPS);
//  stepperY.move(10);
//  stepperX.move(-13*MOTOR_STEPS);
//  stepperY.move(10);
}

void drawSquare(){
  penServo.write(DOWN);
  delay(300);
  stepperX.move(5*MOTOR_STEPS);
  delay(300);
  stepperY.move(5*MOTOR_STEPS);
  delay(300);
  stepperX.move(-5*MOTOR_STEPS);
  delay(300);
  stepperY.move(-5*MOTOR_STEPS);
  penServo.write(UP);
}

void drawMember(){
  penDown();

  //top nut
  moveX(MOTOR_STEPS);
  moveY(3*MOTOR_STEPS);

  //bottom nut
  moveX(-MOTOR_STEPS);
  moveY(-MOTOR_STEPS);

  //shaft
  moveX(5*MOTOR_STEPS);

  //hole
  moveY(-0.5 * MOTOR_STEPS);
  moveX(-0.5 * MOTOR_STEPS);
  penUp();
  moveX(0.5 * MOTOR_STEPS);
  penDown();
  moveY(-0.5 * MOTOR_STEPS);

  //foreskin
  moveX(-1*MOTOR_STEPS);
  moveY(MOTOR_STEPS);
  penUp();
  moveY(-MOTOR_STEPS);
  penDown();

  //finish top nut
  moveX(-4*MOTOR_STEPS);
  moveY(-MOTOR_STEPS);

  //skeet
  penUp();
  moveY(1.5 * MOTOR_STEPS);
  moveX(5 * MOTOR_STEPS);

  for(int i=0; i<4; i++){
    penDown();
    moveX(0.25 * MOTOR_STEPS);
    penUp();
    moveX(0.25 * MOTOR_STEPS);
  }

}

void amogus(){
    penDown();

  //body
  moveX(3*MOTOR_STEPS);
  moveY(MOTOR_STEPS);
  moveX(-0.5*MOTOR_STEPS);
  moveY(-0.5*MOTOR_STEPS);
  moveX(-0.5*MOTOR_STEPS);
  moveY(MOTOR_STEPS);
  moveX(0.5*MOTOR_STEPS);
  moveY(-MOTOR_STEPS);
  moveX(-0.5*MOTOR_STEPS);
  moveY(0.5*MOTOR_STEPS);
  moveX(-2*MOTOR_STEPS);
  moveY(-MOTOR_STEPS);
  
  //legs
  moveX(-MOTOR_STEPS);
  moveY(MOTOR_STEPS*0.4);
  moveX(MOTOR_STEPS);
  moveY(MOTOR_STEPS*0.2);
  moveX(-MOTOR_STEPS);
  moveY(MOTOR_STEPS*0.4);
  moveX(MOTOR_STEPS);
  moveY(-MOTOR_STEPS);
  
  //backpack
  moveX(2.5*MOTOR_STEPS);
  moveY(-MOTOR_STEPS*0.5);
  moveX(-MOTOR_STEPS);
  moveY(0.5*MOTOR_STEPS);
  penUp();
}

void scan(){
  stepperX.setRPM(400);
  for(int i=0; i<4; i++){
    penServo.write(DOWN);
    delay(200);
    stepperX.move(5*MOTOR_STEPS);
    delay(500);
    
    penServo.write(UP);
    delay(200);
    stepperY.move(40);
    delay(500);

//    penServo.write(DOWN);
//    delay(200);
    
    stepperX.move(-5*MOTOR_STEPS);
    delay(500);

    penServo.write(UP);
    delay(200);
//    stepperY.move(40);
//    delay(500);
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
  delay(2000);
}

void sendGantryToOrigin(){
  moveX(-offsetX);
  moveY(-offsetY);
  penServo.write(DONE);
}
