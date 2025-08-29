# Diabetics Smart Sock

## 📌 Overview
A wearable smart sock prototype that uses temperature and pressure sensors embedded in the insole to monitor different regions of the foot. Data is then collected via an Arduino and transmitted over Bluetooth to a mobile app where it is fed into a ML model that predictd **foot ulcer risk** and provides real-time analysis

---
## 🧩 ML Pipeline
1. Data Acquisition
    - Collect temperature and pressure time-series from sensors at ~100 Hz.
2. Preprocessing & Feature Extraction
    - Segment data into sliding windows
    - Compute mean, standard deviation, and cross-foot differences
3. Labeling Risk
    - Assign 0–4 risk categories based on domain-inspired temperature & pressure rules
4. Model Training
    - Train a Random Forest classifier on extracted features
5. Model Evaluation
    - Generate classification reports and confusion matrices
6. Real-Time Deployment
    - Stream live sensor data via Bluetooth → predict risk → display on app

---
## 🔧 Hardware Setup
The smart sock prototype is built using Arduino-compatible sensors embedded into an insole.

### Sensors
- Temperature Sensors (4 total, 2 per foot)
    - Type:Analog thermistor or digital temperature sensor (DS18B20)
    - Positioned at heel and ball regions of each foot
    - Measures skin temperature at ~1 Hz
- Pressure Sensors (4 total, 2 per foot)
    - Type: Force Sensitive Resistor (FSR)
    - Positioned at heel and ball regions of each foot
    - Measures plantar pressure (arbitrary units) at ~1 Hz
## Electronics
- Microcontroller: Arduino Nano for sensor acquisition
- Bluetooth Module: HM-10 for wireless data transmission
- Resistors: Voltage divider resistors for analog sensors (thermistors, FSRs)
- Power: 5V from Arduino regulated supply



## 🧪 Science 

**High blood sugar** results in:

1. **poor circulation** (wounds heal slowly)
2. **nerve damage** (can't feel much)

A cut on the foot could easily get infected due to poor healing and spread uncontrollably. The only way to stop it in some cases is through **amputation**.If identified early, preventative methods can be put in place, however due to nerve damage, many don't catch this early enough.

Research shows that a **difference > 2.2C** between feet is a strong indicator of ulcer formation. In addition, pressure is a key indicator of the damage to the foot, as excessive amounts can damage the tissue further, reducing the likelihood of recovery.


By combining data from the sensors, we can automatically classify the level of risk for different parts of the foot (e.g., heel, ball).  
This project demonstrates how **wearable IoT sensors + ML** can provide early warnings, potentially preventing ulcer formation.

---

## 📂 Dataset
- Data collected from **temperature and pressure sensors** embedded in insoles.
- Data simulated for an individual at risk of foot ulcers, informed by established scientific evidence  
- Each foot is divided into **4 regions**:
  - Left Heel  
  - Left Ball  
  - Right Heel  
  - Right Ball  

- Raw data:  
  - Sampling frequency: ~100 Hz  
  - Collected for ~60 s per class  
  - Stored in CSV format  

- Features extracted per window:
  - **Mean & standard deviation** of pressure  
  - **Mean & standard deviation** of temperature  
  - **Cross-foot differences** (temperature & pressure imbalance)  

---

## 🏷 Risk Labelling
Risk categories were assigned using **domain-inspired rules**:

```python
if temp_diff > 2.2:
    if risk_pressure > 900:
        if risk_pressure - compare_pressure > 100:
            return 3  # imbalance + high temp difference
        else:
            return 4  # high pressure + significant temp difference
    else:
        return 3      # temp difference but pressure low
elif temp_diff > 1.1:
    if risk_pressure > 900:
        if risk_pressure - compare_pressure > 100:
            return 1  # moderate diff + imbalance
        else:
            return 2  # moderate diff + high pressure
    else:
        return 1      # moderate temp diff but low pressure
else:
    return 0          # no significant risk
