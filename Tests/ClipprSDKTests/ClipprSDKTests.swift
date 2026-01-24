import XCTest
@testable import ClipprSDK

final class ClipprSDKTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Clippr.shared.reset()
    }
    
    override func tearDown() {
        Clippr.shared.reset()
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertFalse(Clippr.shared.isInitialized)
        
        Clippr.initialize(apiKey: "test_api_key")
        
        XCTAssertTrue(Clippr.shared.isInitialized)
    }
    
    func testInitializationWithDebug() {
        Clippr.initialize(apiKey: "test_api_key", debug: true)
        
        XCTAssertTrue(Clippr.shared.isInitialized)
        XCTAssertTrue(Logger.isEnabled)
    }
    
    func testClipprLinkModel() {
        let link = ClipprLink(
            path: "/product/123",
            metadata: ["key": AnyCodable("value")],
            attribution: Attribution(campaign: "summer_sale", source: "facebook", medium: "cpc"),
            matchType: .direct,
            confidence: 1.0
        )
        
        XCTAssertEqual(link.path, "/product/123")
        XCTAssertEqual(link.matchType, .direct)
        XCTAssertEqual(link.confidence, 1.0)
        XCTAssertEqual(link.attribution?.campaign, "summer_sale")
        XCTAssertEqual(link.attribution?.source, "facebook")
        XCTAssertEqual(link.attribution?.medium, "cpc")
    }
    
    func testAnyCodableString() {
        let value = AnyCodable("test")
        XCTAssertEqual(value.value as? String, "test")
    }
    
    func testAnyCodableInt() {
        let value = AnyCodable(42)
        XCTAssertEqual(value.value as? Int, 42)
    }
    
    func testAnyCodableDouble() {
        let value = AnyCodable(3.14)
        XCTAssertEqual(value.value as? Double, 3.14)
    }
    
    func testAnyCodableBool() {
        let value = AnyCodable(true)
        XCTAssertEqual(value.value as? Bool, true)
    }
    
    func testMatchTypeRawValues() {
        XCTAssertEqual(MatchType.direct.rawValue, "direct")
        XCTAssertEqual(MatchType.deterministic.rawValue, "deterministic")
        XCTAssertEqual(MatchType.probabilistic.rawValue, "probabilistic")
        XCTAssertEqual(MatchType.none.rawValue, "none")
    }
    
    func testConfigDefaults() {
        let config = ClipprConfig(apiKey: "test_key")
        
        XCTAssertEqual(config.apiKey, "test_key")
        XCTAssertEqual(config.debug, false)
        XCTAssertEqual(config.timeout, 10.0)
        XCTAssertEqual(config.baseURL.absoluteString, "https://api.clppr.xyz")
    }
    
    func testConfigCustomValues() {
        let customURL = URL(string: "https://custom.api.com")!
        let config = ClipprConfig(
            apiKey: "test_key",
            debug: true,
            timeout: 30.0,
            baseURL: customURL
        )
        
        XCTAssertEqual(config.debug, true)
        XCTAssertEqual(config.timeout, 30.0)
        XCTAssertEqual(config.baseURL, customURL)
    }
}
