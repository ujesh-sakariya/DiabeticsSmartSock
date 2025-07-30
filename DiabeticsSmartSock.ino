// temp sensor libraries 
#include <OneWire.h> // protocal class
#include <DallasTemperature.h> // helps read temp values easily
#include <SoftwareSerial.h> // for the bluetooth 

// bluetooth serial on D10 (RX), D11 (TX)
SoftwareSerial bluetooth(10,11); 
// Set up pressure sensors
const int sensorPins[] = {A0,A1,A2,A3};
int sensorValues[4];

#define ONE_WIRE_BUS_1 2 // D2
OneWire oneWire1(ONE_WIRE_BUS_1); // create object of type oneWire
DallasTemperature tempSensor(&oneWire1);

  


void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600); // set up serial communication
  bluetooth.begin(9600) // defualt baud rate
}

void loop() {
  int pressure = analogRead(A0);
  float temperature = tempSensor.getTempCByIndex(0);

  // Send over Bluetooth
  bluetooth.print("Pressure: ");
  bluetooth.print(pressure);
  bluetooth.print(", Temperature: ");
  bluetooth.println(temperature);

  // print pressure values
  for (int i =0; i<4;i++) {
    sensorValues[i] = analogRead(sensorPins[i]);
    Serial.print("Pressure Reading P");
    Serial.print(i+1);
    Serial.print(':');
    Serial.println(sensorValues[i]);
  }
  
  tempSensor.requestTemperatures(); // call the get temp method
  float tempC = tempSensor.getTempCByIndex(0); // get the temp
  Serial.print("Temperature: ");
  Serial.print(tempC);
  Serial.println(" °C");

  delay(1000);
}
