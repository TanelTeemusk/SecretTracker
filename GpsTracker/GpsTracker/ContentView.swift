//
//  ContentView.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var viewModel = TrackerViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("GPS Tracker")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("This is a super secret and candid location tracking app that will send your location secretly to an obscure server. Press START button below to start the tracking process.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                if viewModel.isTracking {
                    viewModel.stopTracking()
                } else {
                    viewModel.startTracking()
                }
            }) {
                Text(viewModel.isTracking ? "STOP TRACKING" : "START")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(viewModel.isTracking ? Color.red : Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
