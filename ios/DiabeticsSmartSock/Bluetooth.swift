//
//  Bluetooth.swift
//  DiabeticsSmartSock
//
//  Created by Ujesh Sakariya on 30/08/2025.
//
import CoreBluetooth
import SwiftUI

// class is a delegate for both connecting and managing data from devices

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!
    // service UUID that the HM-10 has
    let ServiceUUID = CBUUID(string:"FFE0")
    let CharacteristicUUID = CBUUID(string:"FFE1")
    // store the devices to connect to
    @Published var discoveredPeripheral: [CBPeripheral] = []
    // store the device it is connected to
    @Published var connectedPeripheral: CBPeripheral!
    @Published var connectionStatus = "Not connected"
    @Published var risks: FootRiskState = .clear
    // store the chatacteristics
    var dataCharacteristic: CBCharacteristic?
    // create a single ML model object when the device connects
    var riskPredictor: PredictRisk?
    
    private var receiveBuffer = ""
    private var samples: [SmartSockSensorSample] = []
    private var samplesSincePrediction = 0
    
    override init() {
        super.init()
        // act as the delegate
        centralManager = CBCentralManager(delegate: self, queue:nil)
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            return
        }
        
        connectionStatus = "Scanning"
        centralManager.scanForPeripherals(withServices:[ServiceUUID], options: nil)
    }
    
    // function to hanndle if bluetooth is turned on
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is on")
            // scan for devices that contain the specific service UUID
            startScanning()
        default:
            print("Bluetooth not started")
            connectionStatus = "Bluetooth not started"
        }
    }
    
    // function to find devices
    func centralManager(_ central: CBCentralManager,didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered: \(peripheral.name ?? "Unknown")")
        // add the device to the array so we can show it on the frontend
        if !discoveredPeripheral.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripheral.append(peripheral)
        }
    }
    
    // function to handle when a user selects the device
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to: \(peripheral.name ?? "Unknown")")
        connectionStatus = "Connected"
        // this class will now handle the commuication with the device
        peripheral.delegate = self
        peripheral.discoverServices([ServiceUUID])
        connectedPeripheral = peripheral
        do {
            riskPredictor = try PredictRisk()
            print("ML model loaded")
        }
        catch {
            print("Failed to load ML models \(error)")
        }
    }
    
    // function to find the service UUID
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                print("Found service: \(service.uuid)")
                // locate the service UUID to acquire the sensor data (only one for HM-10 but convnetion to go through all)
                if service.uuid == ServiceUUID {
                    // show all the characteristics in that service
                    peripheral.discoverCharacteristics([CharacteristicUUID], for: service)
                }
            }
        }
    }
    // function to find the characteristic UUID
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error:Error?) {
        // return if no characteristics were found
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Found characteristic: \(characteristic.uuid)")
            // if it is the charactersitic of interest
            if characteristic.uuid == CharacteristicUUID {
                print("Found HM-10 characteristic")
                dataCharacteristic = characteristic
                // set up notifications when the values in the characteristic UUID changes
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    // function to handle incoming data
    func peripheral(_ peripheral: CBPeripheral,
                        didUpdateValueFor characteristic: CBCharacteristic,
                        error: Error?) {
            if let value = characteristic.value {
                let str = String(data: value, encoding: .utf8) ?? "?"
                print("Received: \(str)")
                handleIncomingString(str)
            }
        }
    
    private func handleIncomingString(_ str: String) {
        receiveBuffer += str
        
        while let newlineRange = receiveBuffer.range(of: "\n") {
            var line = String(receiveBuffer[..<newlineRange.lowerBound])
            receiveBuffer.removeSubrange(...newlineRange.lowerBound)
            parseSensorLine(line)
        }
        
        // Some HM-10/Arduino sends arrive without a newline, but with a trailing comma.
        // In that case, consume one 8-value sensor row once all 8 comma separators arrive.
        while let rowEnd = receiveBuffer.indexAfterNthComma(8) {
            let line = String(receiveBuffer[..<receiveBuffer.index(before: rowEnd)])
            receiveBuffer.removeSubrange(..<rowEnd)
            parseSensorLine(line)
        }
    }
    
    private func parseSensorLine(_ rawLine: String) {
        var line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if line.hasSuffix(",") {
            line.removeLast()
        }
        
        let values = line
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        
        guard let sample = SmartSockSensorSample(values: values) else {
            print("Skipping incomplete row: \(line)")
            return
        }
        
        print("Parsed sample: \(values)")
        runPrediction(sample)
    }
    
    private func runPrediction(_ sample: SmartSockSensorSample) {
        samples.append(sample)
        samplesSincePrediction += 1
        
        if samples.count > SmartSockFeatureExtractor.windowSize {
            samples.removeFirst(samples.count - SmartSockFeatureExtractor.windowSize)
        }
        
        print("Prediction window samples: \(samples.count)/\(SmartSockFeatureExtractor.windowSize)")
        
        guard samples.count == SmartSockFeatureExtractor.windowSize,
              samplesSincePrediction >= SmartSockFeatureExtractor.stepSize else {
            return
        }
        
        guard let features = SmartSockFeatureExtractor.extract(from: samples) else {
            print("Failed to extract features")
            return
        }
        
        guard let prediction = riskPredictor?.predict(features: features) else {
            print("Failed to run Core ML prediction")
            return
        }
        
        samplesSincePrediction = 0
        risks = prediction
        print("Predicted risks: L_heel=\(prediction.leftHeel), L_ball=\(prediction.leftBall), R_heel=\(prediction.rightHeel), R_ball=\(prediction.rightBall)")
    }
}

private extension String {
    func indexAfterNthComma(_ commaCount: Int) -> String.Index? {
        var foundCommas = 0
        
        for index in indices {
            if self[index] == "," {
                foundCommas += 1
                
                if foundCommas == commaCount {
                    return self.index(after: index)
                }
            }
        }
        
        return nil
    }
}
