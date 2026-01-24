import Foundation

public enum ClipprError: Error, LocalizedError {
    case notInitialized
    case invalidResponse
    case networkError(Error)
    case serverError(Int, String?)
    case decodingError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Clippr SDK not initialized. Call Clippr.initialize() first."
        case .invalidResponse:
            return "Invalid response from server"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown")"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

final class APIClient {
    private let config: ClipprConfig
    private let session: URLSession
    
    init(config: ClipprConfig) {
        self.config = config
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = config.timeout
        sessionConfig.timeoutIntervalForResource = config.timeout * 2
        self.session = URLSession(configuration: sessionConfig)
    }
    
    func match(payload: [String: Any]) async throws -> MatchResponse? {
        let endpoint = config.baseURL.appendingPathComponent("/v1/sdk/match")
        let response: MatchResponseDTO = try await post(endpoint: endpoint, body: payload)
        
        guard response.matched else {
            return nil
        }
        
        return MatchResponse(
            deepLinkPath: response.deepLinkPath ?? "",
            metadata: response.metadata,
            matchType: MatchType(rawValue: response.matchType ?? "none") ?? .none,
            confidence: response.confidence,
            attribution: response.attribution.map { attr in
                Attribution(
                    campaign: attr.campaign,
                    source: attr.source,
                    medium: attr.medium
                )
            }
        )
    }
    
    func trackInstall(payload: [String: Any]) async throws {
        let endpoint = config.baseURL.appendingPathComponent("/v1/sdk/install")
        let _: MessageResponseDTO = try await post(endpoint: endpoint, body: payload)
        Logger.debug("Install tracked successfully")
    }
    
    func trackEvent(deviceId: String, eventName: String, params: [String: Any]?, revenue: Double?, currency: String?) async throws {
        let endpoint = config.baseURL.appendingPathComponent("/v1/sdk/events")
        
        var body: [String: Any] = [
            "device_id": deviceId,
            "event_name": eventName
        ]
        
        if let params = params {
            body["event_params"] = params
        }
        
        if let revenue = revenue {
            body["revenue"] = revenue
        }
        
        if let currency = currency {
            body["currency"] = currency
        }
        
        let _: MessageResponseDTO = try await post(endpoint: endpoint, body: body)
        Logger.debug("Event '\(eventName)' tracked successfully")
    }
    
    private func post<T: Decodable>(endpoint: URL, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        Logger.debug("POST \(endpoint.path)")
        if config.debug {
            if let bodyStr = String(data: jsonData, encoding: .utf8) {
                Logger.debug("Body: \(bodyStr)")
            }
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClipprError.invalidResponse
        }
        
        Logger.debug("Response status: \(httpResponse.statusCode)")
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode(ErrorResponseDTO.self, from: data).error
            throw ClipprError.serverError(httpResponse.statusCode, errorMessage)
        }
        
        do {
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
        } catch {
            Logger.error("Decoding error: \(error)")
            throw ClipprError.decodingError(error)
        }
    }
}

struct MatchResponse {
    let deepLinkPath: String
    let metadata: [String: AnyCodable]?
    let matchType: MatchType
    let confidence: Double?
    let attribution: Attribution?
}

private struct MatchResponseDTO: Decodable {
    let matched: Bool
    let matchType: String?
    let confidence: Double?
    let deepLinkPath: String?
    let metadata: [String: AnyCodable]?
    let attribution: AttributionDTO?
    
    enum CodingKeys: String, CodingKey {
        case matched
        case matchType = "match_type"
        case confidence
        case deepLinkPath = "deep_link_path"
        case metadata
        case attribution
    }
}

private struct AttributionDTO: Decodable {
    let campaign: String?
    let source: String?
    let medium: String?
}

private struct MessageResponseDTO: Decodable {
    let message: String
}

private struct ErrorResponseDTO: Decodable {
    let error: String
}
