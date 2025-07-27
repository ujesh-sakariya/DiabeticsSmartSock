
int P1 = A0;
  int P1Val;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600); // speed of serial communication
}

void loop() {
  // put your main code here, to run repeatedly:
  P1Val = analogRead(P1); // read the value
  Serial.print("Pressure reading: ");
  Serial.println(P1Val);
  delay(200);
}
i