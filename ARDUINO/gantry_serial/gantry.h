#define MOTOR_STEPS 200 //1.8 deg/step; Each rotation ~2cm
#define STEPPER_FAST 300 //rpm
#define STEPPER_SLOW 250 //rpm

//X Motor (+ RIGHT, - LEFT)
#define X_DIR  3
#define X_STEP 4

//Y Motor (+ DOWN, - UP)
#define Y_DIR  6
#define Y_STEP 7

//Servo 
#define SERVO 2
#define UP    153 //servo angles
#define DOWN  157
#define DONE  90

void handlePenInstr(byte buffer[]);
void handleStepperInstr(byte buffer[]);
void penDown();
void penUp();
void moveX();
void moveY();
void sendGantryToDraw();
void sendGantryToOrigin();
