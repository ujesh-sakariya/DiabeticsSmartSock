//
//  Bluetooth.swift
//  DiabeticsSmartSock
//
//  Created by Ujesh Sakariya on 30/08/2025.
//
import CoreBluetooth
import SwiftUI

// class is a delegate for both connecting and managing data from devices

class BluetoothManager:NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!
    // service UUID that the HM-10 has
    let ServiceUUID = CBUUID(string:"FFE0")
    let CharacteristicUUID = CBUUID(string:"FFE1")
    // store the devices to connect to
    @Published var discoveredPeripheral: [CBPeripheral] = []
    // store the device it is connected to
    @Published var connectedPeripheral: CBPeripheral!
    // store the chatacteristics
    var dataCharacteristic: CBCharacteristic?
    // create a single ML model object when the device connects
    var riskPredictor: PredictRisk?
    
    
    override init() {
        super.init()
        // act as the delegate
        centralManager = CBCentralManager(delegate: self, queue:nil)
    }
    
    // function to hanndle if bluetooth is turned on
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is on")
            // scan for devices that contain the specific service UUID
            centralManager.scanForPeripherals(withServices:[ServiceUUID], options: nil)
        default:
            print("Bluetooth not started")
        }
    }
    
    // function to find devices
    func centralManager(_ central: CBCentralManager,didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered: \(peripheral.name ?? "Unknown")")
        // add the device to the array so we can show it on the frontend
        discoveredPeripheral.append(peripheral)
    }
    
    // function to handle when a user selects the device
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to: \(peripheral.name ?? "Unknown")")
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
            }
        }
    
}
