import Foundation
import os.log

public struct LedgerCacheConfig {
    public let credDefTtlDaysById: [String: Int64]
    public let credDefDefaultDays: Int64
    public let schemaTtlDays: Int64
    public let revRegTtlDays: Int64
    public let tailsTtlDays: Int64

    private static let log = Logger(subsystem: "org.hyperledger.ariesframework", category: "LedgerCacheConfig")

    public static func loadFromInfoPlist(bundle: Bundle = .main) -> LedgerCacheConfig {
        func get(_ key: String) -> String? {
            (bundle.object(forInfoDictionaryKey: key) as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let defaultDays = parseInt64(get("CACHE_DEFAULT_TTL_DAYS"), fallback: 1)
        let schemaDays  = parseInt64(get("CACHE_SCHEMA_TTL_DAYS"), fallback: 30)
        let revRegDays  = parseInt64(get("CACHE_REVREG_TTL_DAYS"), fallback: 30)
        let tailsDays   = parseInt64(get("CACHE_TAILS_TTL_DAYS"), fallback: 30)

        let rawMap = get("CREDDEF_TTL_MAP") ?? ""
        let parsedMap = parseCredDefTtlMap(rawMap)

        log.info("[CACHE CONFIG][PLIST] defaultDays=\(defaultDays) | credDefOverrides=\(parsedMap.count) | schemaDays=\(schemaDays) | revRegDays=\(revRegDays) | tailsDays=\(tailsDays)")

        return LedgerCacheConfig(
            credDefTtlDaysById: parsedMap,
            credDefDefaultDays: defaultDays,
            schemaTtlDays: schemaDays,
            revRegTtlDays: revRegDays,
            tailsTtlDays: tailsDays
        )
    }

    private static func parseInt64(_ s: String?, fallback: Int64) -> Int64 {
        guard let s, !s.isEmpty else { return fallback }
        return Int64(s) ?? fallback
    }

    /// raw format: "id,days;id,days;"
    private static func parseCredDefTtlMap(_ raw: String) -> [String: Int64] {
        let raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if raw.isEmpty { return [:] }

        var result: [String: Int64] = [:]
        for entrySub in raw.split(separator: ";", omittingEmptySubsequences: true) {
            let entry = entrySub.trimmingCharacters(in: .whitespacesAndNewlines)
            if entry.isEmpty { continue }

            let parts = entry.split(separator: ",", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count == 2 else {
                log.warning("[CACHE CONFIG] Invalid ttl entry ignored: '\(entry)'")
                continue
            }

            let id = parts[0]
            guard let days = Int64(parts[1]), days > 0 else {
                log.warning("[CACHE CONFIG] Invalid ttl days for '\(id)': '\(parts[1])'")
                continue
            }

            result[id] = days
        }
        return result
    }
}
