import Foundation
import Security

final class Storage {
    private let defaults = UserDefaults.standard
    private let keychainService = "xyz.clppr.sdk"
    
    private enum Keys {
        static let deviceId = "clippr_device_id"
        static let hasCheckedDeferredLink = "clippr_checked_deferred"
        static let lastDeferredLinkPath = "clippr_last_deferred_path"
        static let skanConversionValue = "clippr_skan_conversion_value"
        static let skanEventCount = "clippr_skan_event_count"
        static let skanTotalRevenue = "clippr_skan_total_revenue"
    }
    
    var deviceId: String {
        if let keychainId = getFromKeychain(key: Keys.deviceId) {
            return keychainId
        }

        if let defaultsId = defaults.string(forKey: Keys.deviceId) {
            saveToKeychain(key: Keys.deviceId, value: defaultsId)
            return defaultsId
        }
        
        let newId = UUID().uuidString
        saveToKeychain(key: Keys.deviceId, value: newId)
        defaults.set(newId, forKey: Keys.deviceId)
        Logger.debug("Generated new device ID: \(newId)")
        return newId
    }
    
    var hasCheckedDeferredLink: Bool {
        get { defaults.bool(forKey: Keys.hasCheckedDeferredLink) }
        set { defaults.set(newValue, forKey: Keys.hasCheckedDeferredLink) }
    }
    
    var lastDeferredLinkPath: String? {
        get { defaults.string(forKey: Keys.lastDeferredLinkPath) }
        set { defaults.set(newValue, forKey: Keys.lastDeferredLinkPath) }
    }

    var skanConversionValue: Int {
        get { defaults.integer(forKey: Keys.skanConversionValue) }
        set { defaults.set(newValue, forKey: Keys.skanConversionValue) }
    }

    var skanEventCount: Int {
        get { defaults.integer(forKey: Keys.skanEventCount) }
        set { defaults.set(newValue, forKey: Keys.skanEventCount) }
    }

    var skanTotalRevenue: Double {
        get { defaults.double(forKey: Keys.skanTotalRevenue) }
        set { defaults.set(newValue, forKey: Keys.skanTotalRevenue) }
    }
    
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Logger.error("Failed to save to Keychain: \(status)")
        }
    }
    
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(query as CFDictionary)

        defaults.removeObject(forKey: Keys.deviceId)
        defaults.removeObject(forKey: Keys.hasCheckedDeferredLink)
        defaults.removeObject(forKey: Keys.lastDeferredLinkPath)
    }
}
