import Foundation

/// Parameters for creating a short link
public struct LinkParameters {
    public let path: String
    public var metadata: [String: Any]?
    public var campaign: String?
    public var source: String?
    public var medium: String?
    public var socialTags: SocialMetaTags?
    public var alias: String?
    public var iosFallbackUrl: String?
    public var androidFallbackUrl: String?
    public var webFallbackUrl: String?
    public var expiresAt: Date?

    public init(
        path: String,
        metadata: [String: Any]? = nil,
        campaign: String? = nil,
        source: String? = nil,
        medium: String? = nil,
        socialTags: SocialMetaTags? = nil,
        alias: String? = nil,
        iosFallbackUrl: String? = nil,
        androidFallbackUrl: String? = nil,
        webFallbackUrl: String? = nil,
        expiresAt: Date? = nil
    ) {
        self.path = path
        self.metadata = metadata
        self.campaign = campaign
        self.source = source
        self.medium = medium
        self.socialTags = socialTags
        self.alias = alias
        self.iosFallbackUrl = iosFallbackUrl
        self.androidFallbackUrl = androidFallbackUrl
        self.webFallbackUrl = webFallbackUrl
        self.expiresAt = expiresAt
    }
}

/// Social meta tags for Open Graph previews
public struct SocialMetaTags {
    /// Title shown in link preview
    public let title: String?
    
    /// Description shown in link preview
    public let description: String?
    
    /// Image URL shown in link preview
    public let imageUrl: String?
    
    public init(
        title: String? = nil,
        description: String? = nil,
        imageUrl: String? = nil
    ) {
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
    }
}

/// Response from creating a short link
public struct ShortLink {
    /// The full short URL (e.g., "https://yourapp.clppr.xyz/abc123")
    public let url: String
    
    /// The short code or alias
    public let shortCode: String
    
    /// The original deep link path
    public let path: String
}