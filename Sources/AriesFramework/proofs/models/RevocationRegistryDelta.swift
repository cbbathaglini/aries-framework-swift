
import Foundation

public struct VersionedRevocationRegistryDelta: Codable {
    public let ver: String
    public let value: RevocationRegistryDelta
}

public struct RevocationRegistryDelta: Codable {
    public var prevAccum: String?
    public var accum: String
    public var issued: [Int]? = nil
    public var revoked: [Int]? = nil

    public func toJsonString() -> String {
        let encoder = JSONEncoder()
        let data = try! encoder.encode(self)
        return String(data: data, encoding: .utf8)!
    }

    public func toVersionedJson() -> String {
        let versioned = VersionedRevocationRegistryDelta(ver: "1.0", value: self)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(versioned)
        return String(data: data, encoding: .utf8)!
    }
}
