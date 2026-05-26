import Foundation
import UIKit
import AdSupport
import AppTrackingTransparency

final class DeviceInfo {
    private let storage: Storage
    
    init(storage: Storage) {
        self.storage = storage
    }
    
    var deviceId: String {
        storage.deviceId
    }
    
    var advertisingId: String? {
        if #available(iOS 14, *) {
            guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
                return nil
            }
        }
        
        let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
        if idfa == "00000000-0000-0000-0000-000000000000" {
            return nil
        }
        return idfa
    }
    
    var vendorId: String? {
        UIDevice.current.identifierForVendor?.uuidString
    }
    
    var platform: String {
        "ios"
    }
    
    var userAgent: String {
        let osVersion = UIDevice.current.systemVersion
        let model = deviceModel
        let appName = Bundle.main.bundleIdentifier ?? "unknown"
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        return "ClipprSDK/1.0 (\(model); iOS \(osVersion)) \(appName)/\(appVersion)"
    }
    
    var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }
        return machine
    }
    
    var osVersion: String {
        UIDevice.current.systemVersion
    }
    
    var appVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    var screenResolution: String {
        let screen = UIScreen.main
        let scale = screen.scale
        let width = Int(screen.bounds.width * scale)
        let height = Int(screen.bounds.height * scale)
        return "\(width)x\(height)"
    }
    
    var timezone: String {
        TimeZone.current.identifier
    }
    
    var language: String {
        Locale.preferredLanguages.first ?? Locale.current.identifier
    }
    
    var bundleId: String? {
        Bundle.main.bundleIdentifier
    }
    
    func buildMatchPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "device_id": deviceId,
            "platform": platform,
            "user_agent": userAgent,
            "screen_resolution": screenResolution,
            "timezone": timezone,
            "language": language
        ]

        if let idfa = advertisingId {
            payload["advertising_id"] = idfa
        }

        if let clipboard = readClipboardLink() {
            payload["clipboard_url"] = clipboard
        }

        return payload
    }

    private func readClipboardLink() -> String? {
        if #available(iOS 14, *), !UIPasteboard.general.hasURLs {
            return nil
        }
        guard let url = UIPasteboard.general.url,
              let host = url.host?.lowercased() else {
            return nil
        }
        guard host == "clppr.xyz" || host.hasSuffix(".clppr.xyz") else {
            return nil
        }
        return url.absoluteString
    }
    
    func buildInstallPayload() -> [String: Any] {
        var payload: [String: Any] = [
            "device_id": deviceId,
            "platform": platform
        ]
        
        if let idfa = advertisingId {
            payload["advertising_id"] = idfa
        }
        
        if let version = osVersion as String? {
            payload["os_version"] = version
        }
        
        if let appVer = appVersion {
            payload["app_version"] = appVer
        }
        
        payload["device_model"] = deviceModel
        
        return payload
    }
}
