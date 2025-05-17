//
//  GpsTrackerApp.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import SwiftUI

@main
struct GpsTrackerApp: App {
    private let locationService = LocationService()
    private let storageService = StorageService()
    private let apiService = APIService()

    private var viewModel: TrackerViewModel {
        TrackerViewModel(locationService: locationService,
                         storageService: storageService,
                         apiService: apiService)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
