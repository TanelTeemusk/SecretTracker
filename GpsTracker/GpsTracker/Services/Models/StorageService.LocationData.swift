//
//  Untitled.swift
//  GpsTracker
//
//  Created by tanel teemusk on 16.05.2025.
//

import Foundation

extension StorageService {
    struct LocationData: Codable {
        let latitude: Double
        let longitude: Double
        let createdDateTime: Date
        
        enum CodingKeys: String, CodingKey {
            case latitude
            case longitude
            case createdDateTime
        }
        
        init(latitude: Double, longitude: Double, createdDateTime: Date) {
            self.latitude = latitude
            self.longitude = longitude
            self.createdDateTime = createdDateTime
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(latitude, forKey: .latitude)
            try container.encode(longitude, forKey: .longitude)
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = dateFormatter.string(from: createdDateTime)
            try container.encode(dateString, forKey: .createdDateTime)
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            latitude = try container.decode(Double.self, forKey: .latitude)
            longitude = try container.decode(Double.self, forKey: .longitude)
            
            let dateString = try container.decode(String.self, forKey: .createdDateTime)
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = dateFormatter.date(from: dateString) {
                createdDateTime = date
            } else {
                throw DecodingError.dataCorruptedError(forKey: .createdDateTime, in: container, debugDescription: "Date string does not match format")
            }
        }
    }
}
