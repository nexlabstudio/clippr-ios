import Foundation
import UIKit

public final class Clippr {
    public static let shared = Clippr()
    
    private var config: ClipprConfig?
    private var apiClient: APIClient?
    private var storage: Storage?
    private var deviceInfo: DeviceInfo?
    private var skanManager: SKANManager?

    public private(set) var isInitialized: Bool = false
    public var onLink: ((ClipprLink) -> Void)?
    private var pendingInitialLink: ClipprLink?
    private var initialLinkRetrieved: Bool = false
    private var deferredLinkTask: Task<ClipprLink?, Error>?
    
    private init() {}
    
    @discardableResult
    public static func initialize(
        apiKey: String,
        debug: Bool = false,
        timeout: TimeInterval = 10.0
    ) -> Clippr {
        return initialize(config: ClipprConfig(
            apiKey: apiKey,
            debug: debug,
            timeout: timeout
        ))
    }
    
    @discardableResult
    public static func initialize(config: ClipprConfig) -> Clippr {
        let instance = shared
        
        instance.config = config
        instance.storage = Storage()
        instance.deviceInfo = DeviceInfo(storage: instance.storage!)
        instance.apiClient = APIClient(config: config)
        instance.skanManager = SKANManager(storage: instance.storage!)
        instance.isInitialized = true

        Logger.isEnabled = config.debug
        Logger.info("Clippr SDK initialized")
        instance.loadSKANConfig()
        instance.startDeferredLinkCheck()

        return instance
    }

    private func loadSKANConfig() {
        guard let apiClient = apiClient, let skanManager = skanManager else { return }
        Task {
            do {
                let cfg = try await apiClient.fetchSKANConfig()
                skanManager.update(config: cfg)
            } catch {
                Logger.error("Failed to load SKAN config: \(error)")
            }
        }
    }
    
    public func getInitialLink() async -> ClipprLink? {
        guard isInitialized else {
            Logger.error("SDK not initialized")
            return nil
        }
        initialLinkRetrieved = true

        if let directLink = pendingInitialLink {
            Logger.debug("Returning direct link: \(directLink.path)")
            pendingInitialLink = nil
            return directLink
        }

        Logger.debug("Waiting for deferred link check...")
        do {
            return try await deferredLinkTask?.value
        } catch {
            Logger.error("Deferred link check failed: \(error)")
            return nil
        }
    }
    
    public func getInitialLink(completion: @escaping (ClipprLink?) -> Void) {
        Task {
            let link = await getInitialLink()
            await MainActor.run {
                completion(link)
            }
        }
    }

    public func createLink(_ parameters: LinkParameters) async throws -> ShortLink {
        guard isInitialized, let apiClient = apiClient else {
            throw ClipprError.notInitialized
        }
        
        return try await apiClient.createLink(parameters)
    }
    
    public func track(_ eventName: String, params: [String: Any]? = nil) async throws {
        guard isInitialized, let apiClient = apiClient, let deviceInfo = deviceInfo else {
            throw ClipprError.notInitialized
        }

        try await apiClient.trackEvent(
            deviceId: deviceInfo.deviceId,
            eventName: eventName,
            params: params,
            revenue: nil,
            currency: nil
        )
        skanManager?.recordEvent(name: eventName, revenue: nil)
    }

    public func trackRevenue(
        _ eventName: String,
        revenue: Double,
        currency: String,
        params: [String: Any]? = nil
    ) async throws {
        guard isInitialized, let apiClient = apiClient, let deviceInfo = deviceInfo else {
            throw ClipprError.notInitialized
        }

        try await apiClient.trackEvent(
            deviceId: deviceInfo.deviceId,
            eventName: eventName,
            params: params,
            revenue: revenue,
            currency: currency
        )
        skanManager?.recordEvent(name: eventName, revenue: revenue)
    }
    
    public func track(_ eventName: String, params: [String: Any]? = nil, completion: ((Error?) -> Void)? = nil) {
        Task {
            do {
                try await track(eventName, params: params)
                await MainActor.run { completion?(nil) }
            } catch {
                await MainActor.run { completion?(error) }
            }
        }
    }
    
    @discardableResult
    public func handleUniversalLink(_ url: URL) -> Bool {
        guard isInitialized else {
            Logger.error("SDK not initialized")
            return false
        }

        Logger.debug("Handling Universal Link: \(url)")

        guard let localLink = parseUniversalLink(url) else {
            Logger.debug("URL not a Clippr link")
            return false
        }

        // Try to enrich with backend-stored attribution + canonical deep-link
        // path. Fall back to the local parse on any failure so onLink always
        // fires exactly once per delivery.
        Task { [weak self] in
            guard let self = self else { return }
            let final = (await self.enrich(localLink)) ?? localLink
            self.deliver(final)
        }

        return true
    }

    /// Looks up the short code on the backend and merges its attribution +
    /// deep-link path into the locally-parsed link. URL query params win over
    /// stored metadata.
    private func enrich(_ link: ClipprLink) async -> ClipprLink? {
        guard let apiClient = apiClient, let shortCode = link.shortCode else {
            return nil
        }
        do {
            let resolved = try await apiClient.resolveLink(identifier: shortCode)
            var merged: [String: AnyCodable] = [:]
            if let stored = resolved.metadata {
                merged.merge(stored, uniquingKeysWith: { _, new in new })
            }
            if let urlMeta = link.metadata {
                merged.merge(urlMeta, uniquingKeysWith: { _, new in new })
            }
            return ClipprLink(
                path: resolved.deepLinkPath,
                url: link.url,
                shortCode: link.shortCode,
                metadata: merged.isEmpty ? nil : merged,
                attribution: resolved.attribution,
                matchType: link.matchType,
                confidence: link.confidence
            )
        } catch {
            Logger.error("Failed to resolve link \(shortCode): \(error)")
            return nil
        }
    }

    private func deliver(_ link: ClipprLink) {
        if !initialLinkRetrieved {
            Logger.debug("Storing as initial link")
            pendingInitialLink = link
        } else {
            Logger.debug("Delivering via onLink callback")
            DispatchQueue.main.async {
                self.onLink?(link)
            }
        }
    }
    
    @discardableResult
    public func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        return handleUniversalLink(url)
    }
    
    private func startDeferredLinkCheck() {
        guard let storage = storage else { return }

        if storage.hasCheckedDeferredLink {
            Logger.debug("Already checked for deferred link this install")
            deferredLinkTask = Task { nil }
            return
        }
        
        deferredLinkTask = Task {
            await checkForDeferredLink()
        }
    }
    
    private func checkForDeferredLink() async -> ClipprLink? {
        guard let apiClient = apiClient,
              let deviceInfo = deviceInfo,
              let storage = storage else {
            return nil
        }
        
        Logger.debug("Checking for deferred deep link...")
        
        do {
            let payload = deviceInfo.buildMatchPayload()
            
            guard let match = try await apiClient.match(payload: payload) else {
                Logger.debug("No deferred link found")
                storage.hasCheckedDeferredLink = true
                return nil
            }
            
            Logger.debug("Deferred link found: \(match.deepLinkPath)")

            if match.deepLinkPath == storage.lastDeferredLinkPath {
                Logger.debug("Same link as last time, skipping")
                return nil
            }
            
            storage.hasCheckedDeferredLink = true
            storage.lastDeferredLinkPath = match.deepLinkPath
            try? await apiClient.trackInstall(payload: deviceInfo.buildInstallPayload())
            
            return ClipprLink(
                path: match.deepLinkPath,
                metadata: match.metadata,
                attribution: match.attribution,
                matchType: match.matchType,
                confidence: match.confidence
            )
        } catch {
            Logger.error("Failed to check deferred link: \(error)")
            return nil
        }
    }
    
    private func parseUniversalLink(_ url: URL) -> ClipprLink? {
        let path = url.path

        if path.isEmpty || path == "/" {
            return nil
        }

        var metadata: [String: AnyCodable]? = nil
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems, !queryItems.isEmpty {
            var meta: [String: AnyCodable] = [:]
            for item in queryItems {
                meta[item.name] = AnyCodable(item.value ?? "")
            }
            metadata = meta
        }

        // Short code is the first path segment ("/dtjo6okc" → "dtjo6okc").
        let shortCode = path
            .split(separator: "/", omittingEmptySubsequences: true)
            .first
            .map(String.init)

        return ClipprLink(
            path: path,
            url: url.absoluteString,
            shortCode: shortCode,
            metadata: metadata,
            attribution: nil,
            matchType: .direct,
            confidence: 1.0
        )
    }
    
    internal func reset() {
        config = nil
        apiClient = nil
        storage?.clear()
        storage = nil
        deviceInfo = nil
        isInitialized = false
        pendingInitialLink = nil
        initialLinkRetrieved = false
        deferredLinkTask?.cancel()
        deferredLinkTask = nil
        onLink = nil
    }
}

public extension Clippr {
    static func getInitialLink() async -> ClipprLink? {
        await shared.getInitialLink()
    }

    static func getInitialLink(completion: @escaping (ClipprLink?) -> Void) {
        shared.getInitialLink(completion: completion)
    }

    static func createLink(_ parameters: LinkParameters) async throws -> ShortLink {
        try await shared.createLink(parameters)
    }

    static func track(_ eventName: String, params: [String: Any]? = nil) async throws {
        try await shared.track(eventName, params: params)
    }

    static func track(_ eventName: String, params: [String: Any]? = nil, completion: ((Error?) -> Void)? = nil) {
        shared.track(eventName, params: params, completion: completion)
    }

    static func trackRevenue(
        _ eventName: String,
        revenue: Double,
        currency: String,
        params: [String: Any]? = nil
    ) async throws {
        try await shared.trackRevenue(eventName, revenue: revenue, currency: currency, params: params)
    }

    @discardableResult
    static func handleUniversalLink(_ url: URL) -> Bool {
        shared.handleUniversalLink(url)
    }

    @discardableResult
    static func handleUniversalLink(_ userActivity: NSUserActivity) -> Bool {
        shared.handleUniversalLink(userActivity)
    }

    static var onLink: ((ClipprLink) -> Void)? {
        get { shared.onLink }
        set { shared.onLink = newValue }
    }
}
