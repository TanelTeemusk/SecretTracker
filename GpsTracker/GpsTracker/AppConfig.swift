//
//  AppConfig.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import Foundation
import CoreLocation

enum AppConfig {
    // MARK: - API Configuration
    enum Main {
        // Seconds to pass before next retry when api call fails. 
        static let apiFailRetryInterval: Int = 600
    }
    enum API {
        static let baseURL = "https://demo-api.invendor.com" // Replace with your actual API base URL
        
        enum Endpoints: String {
            case oauth = "/connect/token"
            case coordinates = "/api/GPSEntries/bulk"
        }
        
        enum OAuth {
            static let clientId = "test-app"
            static let clientSecret = "388D45FA-B36B-4988-BA59-B187D329C207"
            static let grantType = "client_credentials"
        }
    }
    
    // MARK: - Storage Configuration
    enum Storage {
        static let maxStoredLocations = 1000
        static let locationDataKey = "savedLocations"
    }
} 
