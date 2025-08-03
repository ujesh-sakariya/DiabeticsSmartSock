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
#define ONE_WIRE_BUS_2 3 // D3
#define ONE_WIRE_BUS_3 4 // D4
#define ONE_WIRE_BUS_4 5 // D5
OneWire oneWire1(ONE_WIRE_BUS_1); // create object of type oneWire
OneWire oneWire2(ONE_WIRE_BUS_2); 
OneWire oneWire3(ONE_WIRE_BUS_3); 
OneWire oneWire4(ONE_WIRE_BUS_4); 
// create DallasTemp object
DallasTemperature tempSensor[] = {
                          DallasTemperature (&oneWire1),
                          DallasTemperature (&oneWire2),
                          DallasTemperature (&oneWire3),
                          DallasTemperature (&oneWire4)
                          };

  


void setup() {
  Serial.begin(9600); // set up serial communication
  bluetooth.begin(9600) ;// defualt baud rate
  // Initialise all temp sensors
  for (int i = 0; i < 4; i++) {
    tempSensor[i].begin();
  }
}

void loop() {
    // print pressure values
  for (int i =0; i<4;i++) {
    sensorValues[i] = analogRead(sensorPins[i]);
    bluetooth.print("Pressure Reading P");
    bluetooth.print(i+1);
    bluetooth.print(':');
    bluetooth.println(sensorValues[i]);
  }
  // request temp values
  for(int i =0;i<4;i++) {
    tempSensor[i].requestTemperatures(); // call the get temp method
  }

  delay(750); // ensure temperature conversion is completed

  for(int i =0;i<4;i++) {
    float tempC = tempSensor[i].getTempCByIndex(0); // get the temp
    bluetooth.print("Temperature: ");
    bluetooth.print(tempC);
    bluetooth.println(" °C");
  }
  delay(1000);
}
