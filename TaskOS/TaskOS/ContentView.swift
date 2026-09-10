//
//  ContentView.swift
//  TaskOS
//
//  Created by ADITYA SINGH on 10/09/26.
//

import SwiftUI
import TaskOSCore

struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "command")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(TaskOSInfo.displayName)
                .font(.title2)
            Text("Core \(TaskOSInfo.coreVersion)")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
