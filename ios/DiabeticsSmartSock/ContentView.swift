//
//  ContentView.swift
//  DiabeticsSmartSock
//
//  Created by Ujesh Sakariya on 25/08/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                Text("Foot Health")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(Color("PrimaryColour"))
                    .padding(.top, -20)
                    .padding(.bottom, 4)
                
                NavigationLink(destination: BluetoothListView(bluetoothManager: bluetoothManager)) {
                    Text("Connect Device")
                        .padding(.horizontal,20)
                        .padding(.vertical,10)
                        .font(.system(size: 20, weight: .bold))
                        .background(Color.gray)
                        .foregroundColor(Color("PrimaryColour"))
                        .cornerRadius(25)
                }

                Text(bluetoothManager.connectionStatus)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                
                FootRiskMap(risks: bluetoothManager.risks)
                    .frame(maxWidth: 500)
                    .aspectRatio(1080 / 1350, contentMode: .fit)
                
                Spacer()
            }
            .padding()
        }
    }
}

private struct FootRiskMap: View {
    let risks: FootRiskState

    private let ledPositions: [FootRiskLocation: CGPoint] = [
        .leftHeel: CGPoint(x: 0.34, y: 0.79),
        .leftBall: CGPoint(x: 0.31, y: 0.44),
        .rightHeel: CGPoint(x: 0.63, y: 0.70),
        .rightBall: CGPoint(x: 0.68, y: 0.32)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image("footprint")
                    .resizable()
                    .aspectRatio(contentMode: .fit)

                ForEach(FootRiskLocation.allCases) { location in
                    if let position = ledPositions[location] {
                        RiskLED(risk: risks[location])
                            .position(
                                x: position.x * proxy.size.width,
                                y: position.y * proxy.size.height
                            )
                    }
                }
            }
        }
    }
}

private struct RiskLED: View {
    let risk: Int

    var body: some View {
        Circle()
            .fill(risk.riskColor)
            .frame(width: 34, height: 34)
            .overlay(
                Circle()
                    .stroke(.white, lineWidth: 4)
            )
            .shadow(color: risk.riskColor.opacity(0.8), radius: 12)
            .accessibilityLabel("Risk \(risk)")
    }
}

#Preview {
    ContentView()
}
