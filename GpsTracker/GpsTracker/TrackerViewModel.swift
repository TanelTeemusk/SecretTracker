//
//  TrackerViewModel.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import Foundation
import CoreLocation
import BackgroundTasks

final class TrackerViewModel: NSObject, ObservableObject {
    // MARK: - Public Variables

    @Published var isTracking = false
    var savedLocations: [StorageService.LocationData] {
        StorageService.shared.savedLocations
    }

    // MARK: - Private Variables
    private var locationManager: CLLocationManager?
    private let apiService = APIService.shared
    
    private var retryTimer: Timer?
    private let retryStateKey = "com.gpstracker.retryState"
    private let trackingStateKey = "com.gpstracker.trackingState"
    
    override init() {
        super.init()
        setupLocationManager()
        isTracking = UserDefaults.standard.bool(forKey: trackingStateKey)
        checkAndRescheduleRetry()
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
            UserDefaults.standard.set(true, forKey: trackingStateKey)
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
        UserDefaults.standard.set(false, forKey: trackingStateKey)
        retryTimer?.invalidate()
        UserDefaults.standard.removeObject(forKey: retryStateKey)
        scheduleRetryTask(after: 10)
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
        guard let location = savedLocations.first else {
            print("No more locations to post")
            retryTimer?.invalidate()
            UserDefaults.standard.removeObject(forKey: retryStateKey)
            return
        }

        let request = ApiRequest(endpoint: .coordinates, method: .post, body: location)
        Task {
            do {
                let response = try await apiService.call(with: request)
                print("Response: \(response.description)")
                if response.isSuccess {
                    StorageService.shared.removeFirstLocation()
                    postSavedLocation()
                } else {
                    scheduleRetryTask(after: 600)
                }
            } catch {
                print("Failed to send coordinates: \(error.localizedDescription)")
                scheduleRetryTask(after: 600)
            }
        }
    }
}

// MARK: - Scheduled retry functionality
extension TrackerViewModel {
    private func checkAndRescheduleRetry() {
        if let retryDate = UserDefaults.standard.object(forKey: retryStateKey) as? Date {
            let timeInterval = retryDate.timeIntervalSinceNow
            if timeInterval > 0 {
                scheduleRetryTask(after: Int(timeInterval))
            } else {
                postSavedLocation()
            }
        }
    }
    
    func scheduleRetryTask(after seconds: Int) {
        retryTimer?.invalidate()
        
        // Store the retry time
        let retryDate = Date().addingTimeInterval(TimeInterval(seconds))
        UserDefaults.standard.set(retryDate, forKey: retryStateKey)
        
        retryTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(seconds), repeats: false) { [weak self] _ in
            self?.postSavedLocation()
        }
    }
}
