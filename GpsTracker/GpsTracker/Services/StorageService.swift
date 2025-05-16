import Foundation
import CoreLocation

final class StorageService {
    static let shared = StorageService()

    // MARK: - Public Variables
    var savedLocations: [LocationData] {
        if let data = UserDefaults.standard.data(forKey: locationsKey),
           let locations = try? JSONDecoder().decode([LocationData].self, from: data) {
            return locations
        }
        return []
    }

    // MARK: - Private Variables
    private let locationsKey = "savedLocations"
    private let maxLocations = 100

    private init() {}

    func saveLocation(_ location: CLLocation) {
        let newLocation = LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            createdDateTime: location.timestamp
        )
        
        var locations = savedLocations
        locations.append(newLocation)
        
        // Keep only the last maxLocations entries
        if locations.count > maxLocations {
            locations = Array(locations.suffix(maxLocations))
        }
        
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: locationsKey)
        }

        print("Saved location: \(newLocation.latitude), \(newLocation.longitude) at \(newLocation.createdDateTime), locations saved: \(locations.count)")
    }
    
    func removeFirstLocation() {
        var locations = savedLocations
        guard !locations.isEmpty else { return }
        
        locations.removeFirst()
        
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: locationsKey)
        }
    }
} 
