//
//  ContentView.swift
//  SwiftUIVerify
//
//  Created by guanren on 2026/1/15.
//

import SwiftUI

@available(iOS 15.0, *)
struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

@available(iOS 15.0, *)
#Preview {
    ContentView()
}
