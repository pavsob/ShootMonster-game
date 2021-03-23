import processing.serial.*;
// The serial port: 
Serial myPort;
int lf = 10;

// Images
PImage headline;
PImage monster;
PImage monsterDead;
PImage bullets;
PImage gameOver;

// Window size
int sizeX = 1300;
int sizeY = 900;
float posX = 600;
float posY = 450;

// For easing
float x;
float y;
float easing = 0.05;

// For smoothing
ArrayList<Float> xSmoothing = new ArrayList<Float>();

//Monster setup, bullets and score
String[] monsterXStr;
ArrayList<Float> monsterX = new ArrayList<Float>();
String[] monsterYStr;
ArrayList<Float> monsterY = new ArrayList<Float>();
ArrayList<Boolean> monsterLive = new ArrayList<Boolean>();
float bulletsNum = 5;
boolean startGame = false;
int score = 0;

// Low range of the map - used for correct positioning
float lRange;

void setup() {
  size(1400, 1000);
  // List all the available serial ports: 
  printArray(Serial.list());

  // Open the port you are using at the rate you want: 
  myPort = new Serial(this, Serial.list()[0], 115200);
  myPort.bufferUntil(lf);

  //start of new program
  println("program starting");
  
  //initialize arraylist
  float in = 50.0;
  xSmoothing.add(in);
  xSmoothing.add(in);

  // Image setup
  monster = loadImage("monster.jpg");
  headline = loadImage("headline.JPG");
  bullets = loadImage("bullet.jpg");
  monsterDead = loadImage("deadmonster.jpg");
  gameOver = loadImage("gameover.jpg");
}

void draw() {

  background(0);
  image(headline,270,0);

  // If the game has started it displays the monsters
  if (startGame == true) {
    for (int i = 0; i < monsterX.size(); i++) {
      if(monsterLive.get(i)) {
        image(monster,monsterX.get(i)-30,monsterY.get(i)-35, 60,70);
      }
      else {
        image(monsterDead, monsterX.get(i)-30, monsterY.get(i)-35,60,70);
      }
    }

    // Displays the bullets
    int shiftX = 1150;
    for (int j = 0; j < bulletsNum; j++) {
      image(bullets,shiftX,920,25,60);
      shiftX += 30;
    }
  }
  else {
    image(gameOver,400,350);
    fill(255,255,0);
    textSize(40);
    text(score,680,520);
  }

  // Easing for aiming cross
  x += (posX - x) * easing;
  y += (posY - y) * easing;

  // Draws the aiming cross
  stroke(255,0,0);
  strokeWeight(4);
  line(x,y, x+40,y);
  line(x,y, x,y+40);
  line(x,y, x-40,y);
  line(x,y, x,y-40);
  noFill();
  strokeWeight(6);
  ellipse (x, y, 30, 30);
}

void serialEvent(Serial p) {

  // Receiving data from the gun prototype
  String inString = p.readString();
  println("inString: " + inString);

  // Stops the game
  if (inString.charAt(0) == '!') {
    startGame = false;
  }
  
  // reaction to shooting
  if (inString.charAt(0) == '&') {
    inString = inString.substring(1);
    inString = trim(inString);
    bulletsNum = Float.parseFloat(inString);
  }
  
  // Hit the target
  if (inString.charAt(0) == '#') {
    inString = inString.substring(1);
    inString = trim(inString);
    //println("received string: " + inString);
    int index = Integer.parseInt(inString);
    //println("index of monster: " + index);
    monsterLive.set(index, false);
    score += 10;
  }

  // Setups a new game
  if (inString.charAt(0) == '@') {
    startGame = false;
    score = 0;
    bulletsNum = 5;
    monsterX.clear();
    monsterY.clear();
    monsterLive.clear();
    inString = inString.substring(1);
    inString = trim(inString);
    String setupString[] = inString.split(";");
    lRange = Float.parseFloat(setupString[0]); 
    monsterXStr = setupString[1].split(",");
    monsterYStr = setupString[2].split(",");
    
    // Transfer from string to float data and transforming values for the screen
    for (int i = 0; i < monsterXStr.length; i++) {
      float xF = Float.parseFloat(monsterXStr[i]);
      float xT;
      // Transfer to (0,100) range
      if (lRange+100 > 359) {
        if (xF > 259) {
          xT = xF - lRange;
        } 
        else {
          xT = xF + (360 - lRange);
        }
      }
      else {
        xT = xF - lRange;
      }
      xT = map(xT,0,100,100, sizeX);
      monsterX.add(xT);
      float yF = Float.parseFloat(monsterYStr[i]);
      float yT = map(yF,-60,60,sizeY,100);
      monsterY.add(yT);
      monsterLive.add(true);
    }
    startGame = true;
  }

  // Receiving target position
  if (inString.charAt(0) == '*') {
    inString = inString.substring(1);
    inString = trim(inString);
    String[] receivedPosition = inString.split(";");   
    // received position in X
    float posXRec;
    // Used to keep transformed position
    float posXT;
    posXRec = Float.parseFloat(receivedPosition[0]);
    // Transfer to (0,100) range
    if (lRange+100 > 359) {
      if (posXRec > 259) {
        posXT = posXRec - lRange;
      } 
      else {
        posXT = posXRec + (360 - lRange);
      }
    }
    else {
      posXT = posXRec - lRange;
    }
    //Smoothing by averaging was not helpful in this case since it needs real-time information
    /*
    xSmoothing.add(posXT);
    xSmoothing.remove(0);
    float sumX = 0;
    for (int x = 0; x < xSmoothing.size(); x++) {
      sumX += xSmoothing.get(0);
      println(sumX);
    }
    float avrPosX = sumX/xSmoothing.size(); 
    */
    posX = map(posXT,0,100,100, sizeX);
    
    // received position in Y
    float posYRec;
    posYRec = Float.parseFloat(receivedPosition[1]);
    posY = map(posYRec,-60,60,sizeY,100);   
  }
} 
