//
//  TrackerViewModel.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import Foundation
import CoreLocation
import BackgroundTasks

// MARK: - Supporting Types
struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let accuracy: Double?
}

final class TrackerViewModel: NSObject, ObservableObject {
    // MARK: - Public Methods

    @Published var isTracking = false
    var savedLocations: [StorageService.LocationData] {
        StorageService.shared.savedLocations
    }

    // MARK: - Private Methods
    private var locationManager: CLLocationManager?
    private let apiService = APIService.shared
    
    override init() {
        super.init()
        setupLocationManager()
        registerBackgroundTask()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        // locationManager?.distanceFilter = 10
        locationManager?.activityType = .other
    }
    
    func startTracking() {
        guard let locationManager = locationManager else {
            fatalError("locationManager doesn't exist. Make sure you setup LocationManager before you start tracking.")
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            isTracking = true
        case .denied, .restricted:
            // TODO: Make it show in UI
            print("Location access denied or restricted")
        @unknown default:
            break
        }
    }
    
    func stopTracking() {
        locationManager?.stopUpdatingLocation()
        isTracking = false
        postSavedLocation()
        clearRetryState()
    }
}

extension TrackerViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        if let lastSavedLocation = savedLocations.last {
            let currentTime = Date()
            let timeInterval = currentTime.timeIntervalSince(lastSavedLocation.createdDateTime)
            if timeInterval < 10 {
                return
            }
        }

        StorageService.shared.saveLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            locationManager?.requestAlwaysAuthorization()
        case .denied, .restricted:
            isTracking = false
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Api access functionality
extension TrackerViewModel {
    private func postSavedLocation() {
        print("Posting saved location")
        guard let location = savedLocations.first else {
            print("No more locations to post")
            return
        }

        let request = ApiRequest(endpoint: .coordinates, method: .post, body: location)
        Task {
            do {
                let response = try await apiService.call(with: request)
                if response.isSuccess {
                    StorageService.shared.removeFirstLocation()
                    postSavedLocation()
                } else {
                    scheduleRetry(with: 600)
                }
            } catch {
                print("Failed to send coordinates: \(error.localizedDescription)")
                scheduleRetry(with: 600)
            }
        }
    }
}

// MARK: - Location backend call retry functionality
extension TrackerViewModel {
    private func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.gpstracker.retry", using: nil) { task in
            self.handleBackgroundRetry(task: task as! BGProcessingTask)
        }
    }
    
    private func handleBackgroundRetry(task: BGProcessingTask) {
        scheduleBackgroundRetry()

        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            await postSavedLocation()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func scheduleBackgroundRetry() {
        let request = BGProcessingTaskRequest(identifier: "com.gpstracker.retry")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 600)
        request.requiresNetworkConnectivity = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background retry: \(error)")
        }
    }
    
    private func scheduleRetry(with seconds: Int = 600) {
        UserDefaults.standard.set(Date(), forKey: AppConfig.Storage.retryStateKey)
        scheduleBackgroundRetry()
    }
    
    private func clearRetryState() {
        UserDefaults.standard.removeObject(forKey: AppConfig.Storage.retryStateKey)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "com.gpstracker.retry")
    }
}
