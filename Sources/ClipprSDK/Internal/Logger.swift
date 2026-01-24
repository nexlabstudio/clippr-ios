import Foundation
import os.log

final class Logger {
    static var isEnabled: Bool = false
    
    private static let subsystem = "xyz.clppr.sdk"
    private static let log = OSLog(subsystem: subsystem, category: "ClipprSDK")
    
    static func debug(_ message: String) {
        guard isEnabled else { return }
        os_log("[Clippr] %{public}@", log: log, type: .debug, message)
    }
    
    static func info(_ message: String) {
        guard isEnabled else { return }
        os_log("[Clippr] %{public}@", log: log, type: .info, message)
    }
    
    static func error(_ message: String) {
        os_log("[Clippr] ERROR: %{public}@", log: log, type: .error, message)
    }
}
