// Global variables
ArrayList<District> districts = new ArrayList<District>();

/*
Runs once on startup; Initializes project
*/
void setup() {
    size(1024, 1024);
    smooth();
    background(255);
    
    // City center always in the middle of the screen
    districts.add(new District(width/2, height/2, 3, false));
}

/*
Runs every frame
*/
void draw() {
  
  // Fading background (creates a trail)
  fill(255, 20); // White with transparency
  noStroke();
  rect(0, 0, width, height);
  
  // Draw the districts
  for(District district : districts) {
    district.drawDistrict();
  }
}

/*
Handle user inputs
*/

// Mouse click event (left click)
void mouseClicked() {
  
  boolean canAddDistrict = true;
  for(District district : districts) {
    
    // Do not draw districts on top of each other
    if(dist(mouseX, mouseY, district.position_x, district.position_y) <= district.diameter + district.ringCount*40 + 20) {
      canAddDistrict = false;
    }
  }
  
  if(canAddDistrict) {
    // Add a new district at the cursor location
    districts.add(new District(mouseX, mouseY, 1, true));
  } else {
    println("Cannot add new district - distance too small");
  }
}




class District {
  
  float position_x, position_y;
  int orbiterCount, ringCount, diameter;
  ArrayList<Orbiter> orbiters = new ArrayList<Orbiter>();
  ArrayList<Connector> connectors = new ArrayList<Connector>();
  ArrayList<DistrictConnector> districtConnectors = new ArrayList<DistrictConnector>();
  
  Connector connector;
  
  District(float position_x, float position_y, int ringCount, boolean drawDC) {
    this.position_x = position_x;
    this.position_y = position_y;
    this.orbiterCount = int(random(4, 6));
    this.diameter = 40;
    this.ringCount = ringCount;
    
    // Create the orbiters
    for(int i=1; i<=this.ringCount; i++) {
      for(int y=0; y<this.orbiterCount; y++) {
        this.orbiters.add(new Orbiter(this.position_x, this.position_y, i*40));
      }
    }
    
    // Create the connectors
    for(int i=1; i<this.ringCount; i++) {
      int connectorCount = int(random(4 +i, 6+i));
      float[] angles = getRandomAngles(connectorCount);
      for(int j=0; j<connectorCount; j++) {
        int trailCount = int(random(3, 4));
        for(int k=1; k<=trailCount; k++) {
          this.connectors.add(new Connector(this.position_x, this.position_y, angles[j], i));
        }
      }
    }
    
    if(drawDC){
      int connectorCount = int(random(2,4));
      for(int i=1; i <= connectorCount; i++){
        districtConnectors.add(new DistrictConnector(this.position_x, this.position_y));
      }
    }
  }
  
  float[] getRandomAngles(int length) {
    
    float minDistance = 45;
    float maxDistance = 180;
    
    float[] angles = new float[length];
    float remainingRange = 360 - (length-1) * minDistance;
    float accumulated = 0;
    
    // First angle is random within available space
    angles[0] = random(remainingRange);
    accumulated = angles[0];
    
    for (int i = 1; i < length; i++) {
      // Calculate available space for this angle
      float remainingAngles = length - i;
      float maxPossible = 360 - accumulated - remainingAngles * minDistance;
      
      // Determine the actual maximum for this step
      float thisMax = min(maxDistance, maxPossible);
      
      // Add random distance within the constraints
      float distance = random(minDistance, thisMax);
      angles[i] = angles[i-1] + distance;
      accumulated += distance;
    }
    
    return angles;
  }
  
  void drawDistrict() {
    
    // Draw the district
    noStroke();
    fill(0, 0, 0);  // Black
    circle(this.position_x, this.position_y, this.diameter);
    
    // Draw the orbiters
    for(Orbiter orbiter : this.orbiters) {
      orbiter.update();
    }
    
    // Draw the connectors
    for(Connector connector : this.connectors) {
      connector.update();
    }
    
    // Draw the district connector
    if(districtConnectors != null){
      for(DistrictConnector dc : districtConnectors){
        dc.drawConnector();
      }
    }
  }
  
}



class DistrictConnector {
  
  float startPositionX, startPositionY;
  color fillColor;
  
  ArrayList<PVector> pathPoints = new ArrayList<PVector>();
  float circlePos;
  float speed, size;
  int currentPoint;
  boolean forward;
  
  DistrictConnector(float x, float y) {
    
    int offset = 30;
    
    // Check the disticts position and adjust the offset accordingly
    if(x >= width/2){
      this.startPositionX = x - offset;
    } else {
      this.startPositionX = x + offset;
    }
    if(y >= height/2){
      this.startPositionY = y - offset;
    } else {
      this.startPositionY = y + offset;
    }
    
    this.speed = random(0.009, 0.015);
    this.size = 10;
    this.currentPoint = 0;
    this.forward = random(1) >= 0.5;
    if(this.forward){
      this.circlePos = 0;
    } else {
      this.circlePos = 1;
    }
    this.fillColor = color(255, random(200, 255), 0, 200);
  }
  
  void drawConnector() {
    
    // Reset the array list (important!)
    pathPoints.clear();
    
    float centerX, centerY;
    
    if(this.startPositionX >= width/2){
      centerX = width/2 + districts.get(0).ringCount * 30;
    } else {
      centerX = width/2 - districts.get(0).ringCount * 30;
    }
    if(this.startPositionY >= height/2){
      centerY = height/2 + districts.get(0).ringCount * 30;
    } else {
      centerY = height/2 - districts.get(0).ringCount * 30;
    }
    
    // Create right-angle turns
    int turns = 3; //int(random(2, 5));
    float lastX = this.startPositionX;
    float lastY = this.startPositionY;
    
    // Store the first point
    pathPoints.add(new PVector(lastX, lastY));
    
    for (int i = 0; i < turns; i++) {
      float progress = float(i+1)/(turns+1);
      float targetX = lerp(this.startPositionX, centerX, progress);
      float targetY = lerp(this.startPositionY, centerY, progress);
      
      // Alternate between horizontal and vertical moves
      if (i % 2 == 0) {
        pathPoints.add(new PVector(targetX, lastY)); // Horizontal move
      } else {
        pathPoints.add(new PVector(lastX, targetY)); // Vertical move
      }
      
      lastX = targetX;
      lastY = targetY;
    }
    // Store the last point
    pathPoints.add(new PVector(centerX, centerY));
    
    // Draw the path
    //drawPath();
    
    // Draw the moving circle
    animateCircle();
    
   }
    
   void drawPath() {
      
     noFill();
     stroke(this.fillColor);
     strokeWeight(this.size);
           
     beginShape();
     for (PVector point : pathPoints) {
       vertex(point.x, point.y);
     }
     endShape();
   }
    
   void animateCircle() {
     
     // Update position based on direction
     if (this.forward) {
       this.circlePos += this.speed;
       if (this.circlePos >= 1) {
         this.circlePos = 1;
         this.forward = false;
         this.fillColor = color(255, random(200, 255), 0, 200);
         this.speed = random(0.009, 0.015);
       }
     } else {
       this.circlePos -= this.speed;
       if (this.circlePos <= 0) {
         this.circlePos = 0;
         this.forward = true;
         this.fillColor = color(255, random(200, 255), 0, 200);
         this.speed = random(0.009, 0.015);
       }
     }
     
     // Calculate position along path
     float totalLength = 0;
     for (int i = 0; i < this.pathPoints.size()-1; i++) {
       totalLength += PVector.dist(this.pathPoints.get(i), this.pathPoints.get(i+1));
     }
      
     float accumulatedLength = 0;
     int segment = 0;
     float segmentStart = 0;
      
     for (int i = 0; i < this.pathPoints.size()-1; i++) {
       float segmentLength = PVector.dist(this.pathPoints.get(i), this.pathPoints.get(i+1));
       if (this.circlePos <= (accumulatedLength + segmentLength)/totalLength) {
         segment = i;
         segmentStart = accumulatedLength/totalLength;
         break;
       }
       accumulatedLength += segmentLength;
     }
      
     float segmentRatio = (this.circlePos - segmentStart) / (PVector.dist(this.pathPoints.get(segment), this.pathPoints.get(segment+1))/totalLength);
      
     float x = lerp(this.pathPoints.get(segment).x, this.pathPoints.get(segment+1).x, segmentRatio);
     float y = lerp(this.pathPoints.get(segment).y, this.pathPoints.get(segment+1).y, segmentRatio);
      
     // Draw the moving circle
     fill(this.fillColor);
     noStroke();
     circle(x, y, this.size);
   }
}



class Connector {
  
  ArrayList<PVector> trailPoints = new ArrayList<PVector>();
  PVector lineStart, lineEnd;
  float trailPosition, trailSpeed, angle, lineLength, size;
  int trailCount;
  boolean movingForward;
  color fillColor;
  
  Connector(float x, float y, float angle,int index) {
    this.angle = angle + random(0.05);
    this.trailPosition = random(1);
    this.trailSpeed = random(0.03, 0.06);
    this.lineLength = 40;
    this.size = 5;
    this.fillColor = this.getColor();
    this.movingForward = 0.5 <= random(1);
    // Define the start and end points of the base line
    this.lineStart = new PVector(x + cos(this.angle) * (index*40), y + sin(this.angle) * (index*40));
    this.lineEnd = new PVector(this.lineStart.x + cos(this.angle) * this.lineLength, this.lineStart.y + sin(this.angle) * this.lineLength);
  }
  
  void update() {
    
    // Update the trail position
    if (movingForward) {
      trailPosition += trailSpeed;
      if (trailPosition >= 1.0) {
        trailPosition = 1.0;
        movingForward = false;
      }
    } else {
      trailPosition -= trailSpeed;
      if (trailPosition <= 0.0) {
        trailPosition = 0.0;
        movingForward = true;
      }
    }
    
    // Calculate the current point along the line
    float x = lerp(lineStart.x, lineEnd.x, trailPosition);
    float y = lerp(lineStart.y, lineEnd.y, trailPosition);
    PVector currentPoint = new PVector(x, y);
    
    // Add the current point to the trail
    trailPoints.add(currentPoint);
    
    // Limit the trail length
    if (trailPoints.size() > 2) {
      trailPoints.remove(0);
    }
    
    // Draw the trail
    stroke(this.fillColor);
    strokeWeight(this.size);
    for (int i = 1; i < trailPoints.size(); i++) {
      PVector prev = trailPoints.get(i-1);
      PVector curr = trailPoints.get(i);
      line(prev.x, prev.y, curr.x, curr.y);
    }
  }
  
  // Return a random yellow-ish color
  color getColor() {
    return color(255, random(200, 255), 0, 200);
  }
  
}

class Orbiter {
  
  PVector prevPos;
  int size;
  float center_x, center_y, x ,y , speed, angle, distance;
  color fillColor;
  boolean clockwise;
  
  Orbiter(float center_x, float center_y, int distance) {
    this.size = 5;
    this.speed = random(0.08, 0.1);
    this.angle = random(360);
    this.distance = distance + random(-5, 5);
    this.fillColor = getColor();
    this.center_x = center_x;
    this.center_y = center_y;
    this.prevPos = new PVector();
    this.clockwise = random(1) >= 0.5; // 50 : 50 chance
  }
  
  void update() {
    
    // Calculate current position
    this.x = center_x + cos(this.angle) * this.distance;
    this.y = center_y + sin(this.angle) * this.distance;
    PVector currentPos = new PVector(this.x, this.y);
  
    // Draw line from previous to current position
    if (this.prevPos.x != 0 || this.prevPos.y != 0) {
      stroke(this.fillColor);
      strokeWeight(this.size);
      line(this.prevPos.x, this.prevPos.y, currentPos.x, currentPos.y);
    }
    
    this.prevPos = currentPos.copy(); // Update previous position
    
    if(this.clockwise) {
      this.angle += this.speed; // Advance rotation clockwise
    } else {
      this.angle -= this.speed; // Advance rotation counter clockwise
    }
    
  }
  
  // Return a random yellow-ish color
  color getColor() {
    return color(255, random(200, 255), 0, 200);
  }
}
