// Set up pressure sensors
const int sensorPins[] = {A0,A1,A2,A3};
int sensorValues[4];

const int tempPins[] = {2,3,4,5};
int tempValues[4];
  


void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600); // speed of serial communication
}

void loop() {
  // put your main code here, to run repeatedly:

  // print pressure values
  for (int i =0; i<4;i++) {
    sensorValues[i] = analogRead(sensorPins[i]);
    Serial.print("Pressure Reading P");
    Serial.print(i+1);
    Serial.print(':');
    Serial.println(sensorValues[i]);
  }
  delay(200);

  // print temp values
  for (int i =0; i<4;i++) {
    sensorValues[i] = digitalRead(tempPins[i]);
    Serial.print("Temp Reading T");
    Serial.print(i+1);
    Serial.print(':');
    Serial.println(tempValues[i]);
  }
  delay(200);
}
