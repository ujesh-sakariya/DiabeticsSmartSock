//
//  ContentView.swift
//  DiabeticsSmartSock
//
//  Created by Ujesh Sakariya on 25/08/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Foot Health")
                .font(.system(size: 50, weight: .bold))
                .foregroundColor(Color("PrimaryColour"))
                .padding(.top,-20)
                .padding(.bottom,10)
            
            Button(action: {print("button")}) {
                Text("Connect Device")
                    .padding(.horizontal,20)
                    .padding(.vertical,10)
                    .font(.system(size: 20, weight: .bold))
                    .background(Color.gray)
                    .foregroundColor(Color("PrimaryColour"))
                    .cornerRadius(25)
            }
            
    
            Image("footprint")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 500, height: 500)
            
                Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
