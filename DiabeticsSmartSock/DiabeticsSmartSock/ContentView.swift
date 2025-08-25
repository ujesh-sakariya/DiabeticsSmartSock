//
//  ContentView.swift
//  DiabeticsSmartSock
//
//  Created by Ujesh Sakariya on 25/08/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // vertical stack components
        VStack {
            // image
            Image(systemName: "pencil")
                .imageScale(.large)
                .foregroundStyle(.primaryColour)
            // text
            Text("Hello, world1!")
                .bold()
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
