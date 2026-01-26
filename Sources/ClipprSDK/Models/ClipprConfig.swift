import Foundation

public struct ClipprConfig {
    public let apiKey: String
    public let debug: Bool
    public let timeout: TimeInterval
    public let baseURL: URL

    public static let defaultBaseURL = URL(string: "https://api.clppr.xyz/v1")!
    
    public init(
        apiKey: String,
        debug: Bool = false,
        timeout: TimeInterval = 10.0,
        baseURL: URL = ClipprConfig.defaultBaseURL
    ) {
        self.apiKey = apiKey
        self.debug = debug
        self.timeout = timeout
        self.baseURL = baseURL
    }
}
