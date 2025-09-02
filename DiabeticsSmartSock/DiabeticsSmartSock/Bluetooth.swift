//
//  Bluetooth.swift
//  DiabeticsSmartSock
//
//  Created by Ujesh Sakariya on 30/08/2025.
//
import CoreBluetooth
import SwiftUI

// class is a delegate for both connecting and managing data from devices

class BluetoothManager:NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var centralManager: CBCentralManager!
    // service UUID for HM-10
    let sockServiceUUID = CBUUID(string:"0000ffe1-0000-1000-8000-00805f9b34fb" )
    // store the devices to connect to
    var discoveredPeripheral: [CBPeripheral] = []
    
    
    override init() {
        super.init()
        // act as the delegate
        centralManager = CBCentralManager(delegate: self, queue:nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            print("Bluetooth is on")
            centralManager.scanForPeripherals(withServices:[sockServiceUUID], options: nil)
        default:
            print("Bluetooth not started")
        }
    }
    
    func centralManager(_ central: CBCentralManager,didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered: \(peripheral.name ?? "Unknown")")
        // add the device to the array so we can show it on the frontend
        discoveredPeripheral.append(peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Connected to: \(peripheral.name ?? "Unknown")")
        // this class will now handle the commuication with the device
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                print("Found service: \(service.uuid)")
            }
        }
    }
}
    
