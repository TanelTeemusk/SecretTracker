import CoreLocation
import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

struct ApiRequest {
    let endpoint: AppConfig.API.Endpoints
    let method: HTTPMethod
    let body: Codable
}

struct APIResponse {
    let isSuccess: Bool
    let statusCode: Int
    let message: String?
    
    var description: String {
        let status = isSuccess ? "✅ Success" : "❌ Failure"
        let statusCodeInfo = "Status Code: \(statusCode)"
        let messageInfo = message.map { "Message: \($0)" } ?? "No message"
        
        return """
        \(status)
        \(statusCodeInfo)
        \(messageInfo)
        """
    }
    
    static func success(statusCode: Int, message: String? = nil) -> APIResponse {
        return APIResponse(isSuccess: true, statusCode: statusCode, message: message)
    }
    
    static func failure(statusCode: Int, message: String? = nil) -> APIResponse {
        return APIResponse(isSuccess: false, statusCode: statusCode, message: message)
    }
}

final class APIService {
    static let shared = APIService()

    private var accessToken: String?
    private var tokenExpirationDate: Date?

    private init() {}

    // MARK: - Request Handler

    private func performRequest(_ request: URLRequest) async throws -> APIResponse {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            return APIResponse.success(statusCode: httpResponse.statusCode)
        } else {
            return APIResponse.failure(statusCode: httpResponse.statusCode)
        }
    }

    private func performRequestWithoutResponse(_ request: URLRequest) async throws -> APIResponse {
        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            return APIResponse.success(statusCode: httpResponse.statusCode)
        } else {
            return APIResponse.failure(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - OAuth Token Management

    func getValidToken() async throws -> String {
        if let token = accessToken,
            let expirationDate = tokenExpirationDate,
            expirationDate > Date()
        {
            return token
        }

        return try await fetchNewToken()
    }

    private func fetchNewToken() async throws -> String {
        guard let url = URL(string: AppConfig.API.baseURL + AppConfig.API.Endpoints.oauth.rawValue) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters = [
            "grant_type": AppConfig.API.OAuth.grantType,
            "client_id": AppConfig.API.OAuth.clientId,
            "client_secret": AppConfig.API.OAuth.clientSecret,
        ]

        request.httpBody =
            parameters
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: String.Encoding.utf8)

        struct TokenResponse: Codable {
            let access_token: String
            let expires_in: Int
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        accessToken = tokenResponse.access_token
        tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))

        return tokenResponse.access_token
    }

    // MARK: - API Endpoints

    func call(with request: ApiRequest) async throws -> APIResponse {
        let token = try await getValidToken()
        
        guard let url = URL(string: AppConfig.API.baseURL+request.endpoint.rawValue) else {
            throw APIError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if request.method == .post {
            let encoder = JSONEncoder()
            urlRequest.httpBody = try encoder.encode(request.body)
        }
        
        return try await performRequest(urlRequest)
    }
}
