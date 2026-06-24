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
    @ObservedObject var bluetoothManager: BluetoothManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(bluetoothManager.connectionStatus == "Connected" ? .green : .red)
                    .frame(width: 12, height: 12)
                
                Text(bluetoothManager.connectionStatus)
                    .font(.system(size: 16, weight: .semibold))
            }
            .padding(.horizontal)
            .padding(.top)
            
            // List makes its scrollable
            List(bluetoothManager.discoveredPeripheral,id: \.identifier) {
                // for all the devices in the list
                peripheral in
                Button(action: {bluetoothManager.centralManager.connect(peripheral, options: nil)}) {
                    HStack {
                        Text(peripheral.name ?? "Unknown Device")
                        Spacer()
                        
                        if bluetoothManager.connectedPeripheral?.identifier == peripheral.identifier {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
        }
        .onAppear {
            bluetoothManager.startScanning()
        }
        .navigationTitle("Select Device")
    }
   
}