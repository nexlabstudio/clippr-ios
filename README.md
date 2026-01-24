# Clippr iOS SDK

Deep linking and mobile attribution SDK for iOS.

## Installation

### Swift Package Manager (Recommended)

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nexlabstudio/clippr-ios.git", from: "0.0.1")
]
```

Or in Xcode: File → Add Packages → Enter the repository URL.

### CocoaPods

```ruby
pod 'ClipprSDK', '~> 0.0.1'
```

## Quick Start

### 1. Initialize the SDK

```swift
import ClipprSDK

@main
struct MyApp: App {
    init() {
        Clippr.initialize(apiKey: "your_api_key_here")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

Or in AppDelegate:

```swift
import ClipprSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        Clippr.initialize(apiKey: "your_api_key_here")
        
        return true
    }
}
```

### 2. Handle Deep Links

```swift
import SwiftUI
import ClipprSDK

struct ContentView: View {
    @State private var deepLinkPath: String?
    
    var body: some View {
        NavigationStack {
            // Your content
        }
        .task {
            // Get the link that opened the app (direct or deferred)
            if let link = await Clippr.getInitialLink() {
                handleDeepLink(link)
            }
            
            // Listen for links while app is running
            Clippr.onLink = { link in
                handleDeepLink(link)
            }
        }
    }
    
    func handleDeepLink(_ link: ClipprLink) {
        print("Deep link path: \(link.path)")
        print("Metadata: \(link.metadata ?? [:])")
        print("Campaign: \(link.attribution?.campaign ?? "none")")
        
        // Navigate based on path
        deepLinkPath = link.path
    }
}
```

### 3. Configure Universal Links

Add your Associated Domains entitlement:

1. In Xcode, select your target → Signing & Capabilities
2. Click "+ Capability" and add "Associated Domains"
3. Add: `applinks:yourapp.clppr.xyz`

Your AASA file is automatically hosted by Clippr at:
`https://yourapp.clppr.xyz/.well-known/apple-app-site-association`

### 4. Handle Universal Links in SceneDelegate

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        Clippr.handleUniversalLink(userActivity)
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            Clippr.handleUniversalLink(url)
        }
    }
}
```

Or in SwiftUI:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    Clippr.handleUniversalLink(url)
                }
        }
    }
}
```

### 5. Track Events (Optional)

```swift
// Track a simple event
try await Clippr.track("signup_completed")

// Track with parameters
try await Clippr.track("add_to_cart", params: [
    "product_id": "12345",
    "price": 29.99
])

// Track revenue
try await Clippr.trackRevenue(
    "purchase",
    revenue: 99.99,
    currency: "USD",
    params: ["product_id": "12345"]
)

// Using completion handler
Clippr.track("button_clicked", params: nil) { error in
    if let error = error {
        print("Failed to track: \(error)")
    }
}
```

## API Reference

### Clippr

| Method | Description |
|--------|-------------|
| `initialize(apiKey:debug:timeout:)` | Initialize the SDK |
| `getInitialLink()` | Get the link that opened the app |
| `onLink` | Callback for links received while app is running |
| `handleUniversalLink(_:)` | Handle incoming Universal Links |
| `track(_:params:)` | Track a custom event |
| `trackRevenue(_:revenue:currency:params:)` | Track a revenue event |

### ClipprLink

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | The deep link path (e.g., "/product/123") |
| `metadata` | `[String: Any]?` | Custom metadata attached to the link |
| `attribution` | `Attribution?` | Campaign attribution data |
| `matchType` | `MatchType` | How the link was matched |
| `confidence` | `Double?` | Match confidence (0.0 - 1.0) |

### MatchType

| Value | Description |
|-------|-------------|
| `.direct` | User clicked link with app installed |
| `.probabilistic` | Matched via device fingerprinting |
| `.none` | No match found |

## Debug Mode

Enable debug logging during development:

```swift
Clippr.initialize(apiKey: "your_api_key", debug: true)
```

## Requirements

- iOS 13.0+
- Swift 5.7+
- Xcode 14.0+

## License

MIT License. See LICENSE for details.
