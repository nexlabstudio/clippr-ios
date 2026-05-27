import Foundation

public struct ClipprLink: Equatable, Codable {
    /// Deep link path the app should route on (e.g., "/product/123").
    /// For direct deliveries this is resolved from the backend; if resolution
    /// fails, it falls back to the URL path.
    public let path: String

    /// Full short URL that triggered the delivery (e.g.,
    /// "https://example.clppr.xyz/dtjo6okc"). Nil for deferred-match deliveries
    /// where the server doesn't know which short URL was clicked.
    public let url: String?

    /// Just the short-code or alias from the URL (e.g., "dtjo6okc").
    /// Nil for deferred matches.
    public let shortCode: String?

    public let metadata: [String: AnyCodable]?
    public let attribution: Attribution?
    public let matchType: MatchType
    public let confidence: Double?

    public init(
        path: String,
        url: String? = nil,
        shortCode: String? = nil,
        metadata: [String: AnyCodable]? = nil,
        attribution: Attribution? = nil,
        matchType: MatchType = .direct,
        confidence: Double? = nil
    ) {
        self.path = path
        self.url = url
        self.shortCode = shortCode
        self.metadata = metadata
        self.attribution = attribution
        self.matchType = matchType
        self.confidence = confidence
    }
}

public struct Attribution: Equatable, Codable {
    public let campaign: String?
    public let source: String?
    public let medium: String?
    
    public init(campaign: String? = nil, source: String? = nil, medium: String? = nil) {
        self.campaign = campaign
        self.source = source
        self.medium = medium
    }
}

public enum MatchType: String, Codable {
    case direct
    case deterministic
    case probabilistic
    case none
}

public struct AnyCodable: Equatable, Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
    
    public static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        switch (lhs.value, rhs.value) {
        case (let l as Bool, let r as Bool): return l == r
        case (let l as Int, let r as Int): return l == r
        case (let l as Double, let r as Double): return l == r
        case (let l as String, let r as String): return l == r
        default: return false
        }
    }
}
