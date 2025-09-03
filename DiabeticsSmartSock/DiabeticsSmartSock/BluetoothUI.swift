//
//  BluetoothUI.swift
//  DiabeticsSmartSock
//
//  Created by Ujesh Sakariya on 03/09/2025.
//

import SwiftUI
import CoreBluetooth

struct BluetoothListView: View {
    
    // ensure the object lives as long as on this view
    @StateObject var bluetoothManager = BluetoothManager()
    
    var body: some View {
        // List makes its scrollable
        List(bluetoothManager.discoveredPeripheral,id: \.identifier) {
            // for all the devices in the list
            peripheral in
            Button(action: {bluetoothManager.centralManager.connect(peripheral, options: nil)}) {Text(peripheral.name ?? "Unknown Device")}
        }
        .navigationTitle("Select Device")
    }
   
}
