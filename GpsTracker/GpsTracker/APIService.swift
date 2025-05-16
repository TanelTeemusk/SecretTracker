import Foundation
import CoreLocation

final class APIService {
    static let shared = APIService()
    
    private var accessToken: String?
    private var tokenExpirationDate: Date?
    
    private init() {}
    
    // MARK: - OAuth Token Management
    
    func getValidToken() async throws -> String {
        // If we have a valid token, return it
        if let token = accessToken,
           let expirationDate = tokenExpirationDate,
           expirationDate > Date() {
            return token
        }
        
        // Otherwise, fetch a new token
        return try await fetchNewToken()
    }
    
    private func fetchNewToken() async throws -> String {
        guard let url = URL(string: AppConfig.API.baseURL + AppConfig.API.Endpoints.oauth) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let parameters = [
            "grant_type": AppConfig.API.OAuth.grantType,
            "client_id": AppConfig.API.OAuth.clientId,
            "client_secret": AppConfig.API.OAuth.clientSecret
        ]
        
        request.httpBody = parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: String.Encoding.utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        struct TokenResponse: Codable {
            let access_token: String
            let expires_in: Int
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        
        // Store the token and its expiration
        accessToken = tokenResponse.access_token
        tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
        
        return tokenResponse.access_token
    }
    
    // MARK: - API Endpoints
    
    func sendCoordinates(_ coordinates: [Coordinate]) async throws {
        let token = try await getValidToken()
        
        guard let url = URL(string: AppConfig.API.baseURL + AppConfig.API.Endpoints.coordinates) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(coordinates)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
    }
}

// MARK: - Supporting Types

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let accuracy: Double?
    
    init(from location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
        self.accuracy = location.horizontalAccuracy
    }
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
} 