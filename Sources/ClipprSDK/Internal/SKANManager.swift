import Foundation
import StoreKit

final class SKANManager {
    private let storage: Storage
    private var fineSchema: [String: SKANFineItem] = [:]
    private var coarseSchema: [SKANCoarseItem] = []
    private var enabled: Bool = false

    init(storage: Storage) {
        self.storage = storage
    }

    func update(config: SKANConfig) {
        enabled = config.enabled
        fineSchema = Dictionary(uniqueKeysWithValues: config.conversionSchema.map { ($0.eventName, $0) })
        coarseSchema = config.coarseSchema
    }

    func recordEvent(name: String, revenue: Double?) {
        guard enabled else { return }

        var conversionValue = storage.skanConversionValue
        var totalRevenue = storage.skanTotalRevenue
        let eventCount = storage.skanEventCount + 1

        if let item = fineSchema[name] {
            let revenueOk = item.revenueThreshold.map { (revenue ?? 0) >= $0 } ?? true
            if revenueOk {
                conversionValue |= (1 << item.bitPosition)
            }
        }
        if let revenue = revenue {
            totalRevenue += revenue
        }

        storage.skanConversionValue = conversionValue
        storage.skanTotalRevenue = totalRevenue
        storage.skanEventCount = eventCount

        let coarseValue = computeCoarse(eventCount: eventCount, totalRevenue: totalRevenue)
        postUpdate(fineValue: conversionValue, coarseValue: coarseValue)
    }

    private func computeCoarse(eventCount: Int, totalRevenue: Double) -> String? {
        let priority: [String: Int] = ["high": 3, "medium": 2, "low": 1]
        var best: SKANCoarseItem?
        var bestRank = -1
        for item in coarseSchema {
            let eventsOk = item.minEvents.map { eventCount >= $0 } ?? true
            let revenueOk = item.minRevenue.map { totalRevenue >= $0 } ?? true
            guard eventsOk && revenueOk else { continue }
            let rank = priority[item.coarseValue] ?? 0
            if rank > bestRank {
                best = item
                bestRank = rank
            }
        }
        return best?.coarseValue
    }

    private func postUpdate(fineValue: Int, coarseValue: String?) {
        if #available(iOS 16.1, *), let coarseStr = coarseValue {
            let coarse: SKAdNetwork.CoarseConversionValue
            switch coarseStr {
            case "high": coarse = .high
            case "medium": coarse = .medium
            default: coarse = .low
            }
            SKAdNetwork.updatePostbackConversionValue(fineValue, coarseValue: coarse, lockWindow: false) { error in
                if let error = error {
                    Logger.error("SKAdNetwork postback update failed: \(error)")
                }
            }
        } else if #available(iOS 15.4, *) {
            SKAdNetwork.updatePostbackConversionValue(fineValue) { error in
                if let error = error {
                    Logger.error("SKAdNetwork postback update failed: \(error)")
                }
            }
        } else if #available(iOS 14, *) {
            SKAdNetwork.updateConversionValue(fineValue)
        }
    }
}

struct SKANConfig: Decodable {
    let enabled: Bool
    let conversionSchema: [SKANFineItem]
    let coarseSchema: [SKANCoarseItem]

    enum CodingKeys: String, CodingKey {
        case enabled
        case conversionSchema = "conversion_schema"
        case coarseSchema = "coarse_schema"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        enabled = try c.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        conversionSchema = try c.decodeIfPresent([SKANFineItem].self, forKey: .conversionSchema) ?? []
        coarseSchema = try c.decodeIfPresent([SKANCoarseItem].self, forKey: .coarseSchema) ?? []
    }
}

struct SKANFineItem: Decodable {
    let bitPosition: Int
    let eventName: String
    let description: String?
    let revenueThreshold: Double?

    enum CodingKeys: String, CodingKey {
        case bitPosition = "bit_position"
        case eventName = "event_name"
        case description
        case revenueThreshold = "revenue_threshold"
    }
}

struct SKANCoarseItem: Decodable {
    let coarseValue: String
    let description: String?
    let minEvents: Int?
    let minRevenue: Double?

    enum CodingKeys: String, CodingKey {
        case coarseValue = "coarse_value"
        case description
        case minEvents = "min_events"
        case minRevenue = "min_revenue"
    }
}
