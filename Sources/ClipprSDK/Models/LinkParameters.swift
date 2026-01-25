import Foundation

/// Parameters for creating a short link
public struct LinkParameters {
    /// Deep link path (e.g., "/product/123")
    public let path: String
    
    /// Custom metadata to attach to the link
    public var metadata: [String: Any]?
    
    /// Campaign name for attribution
    public var campaign: String?
    
    /// Traffic source (e.g., "facebook", "twitter")
    public var source: String?
    
    /// Marketing medium (e.g., "social", "email")
    public var medium: String?
    
    /// Social meta tags for link previews
    public var socialTags: SocialMetaTags?
    
    /// Custom alias for the short link (e.g., "summer-sale" → yourapp.clppr.xyz/summer-sale)
    public var alias: String?
    
    public init(
        path: String,
        metadata: [String: Any]? = nil,
        campaign: String? = nil,
        source: String? = nil,
        medium: String? = nil,
        socialTags: SocialMetaTags? = nil,
        alias: String? = nil
    ) {
        self.path = path
        self.metadata = metadata
        self.campaign = campaign
        self.source = source
        self.medium = medium
        self.socialTags = socialTags
        self.alias = alias
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