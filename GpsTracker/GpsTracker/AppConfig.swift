import Foundation
import CoreLocation

enum AppConfig {
    // MARK: - API Configuration
    enum API {
        static let baseURL = "https://demo-api.invendor.com" // Replace with your actual API base URL
        
        enum Endpoints: String {
            case oauth = "/connect/token"
            case coordinates = "/api/GPSEntries"
        }
        
        enum OAuth {
            static let clientId = "test-app"
            static let clientSecret = "388D45FA-B36B-4988-BA59-B187D329C207"
            static let grantType = "client_credentials"
        }
    }
    
    // MARK: - Location Configuration
    enum Location {
        static let minimumAccuracy: Double = 10.0 // meters
        static let minimumTimeInterval: TimeInterval = 10.0 // seconds
        static let desiredAccuracy: Double = kCLLocationAccuracyBest
        static let distanceFilter: Double = 10.0 // meters
    }
    
    // MARK: - Storage Configuration
    enum Storage {
        static let maxStoredLocations = 1000
        static let locationDataKey = "savedLocations"
        static let retryStateKey = "lastRetryAttempt"
    }
    
    // MARK: - UI Configuration
    enum UI {
        static let mapZoomLevel: Double = 15.0
        static let mapSpan: Double = 0.01
    }
} 
