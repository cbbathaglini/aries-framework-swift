//
//  RequestedAttributeAnonCreds.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable

public struct RequestedAttributeAnonCreds: Codable {
    public let credentialId: String
    public let timestamp: Int?
    public let revealed: Bool

    public var credentialInfo: AnonCredsCredentialInfo?
    public var revoked: Bool?

    enum CodingKeys: String, CodingKey {
        case credentialId
        case timestamp
        case revealed
    }
    
    public init(
        credentialId: String,
        timestamp: Int?,
        revealed: Bool,
        credentialInfo: AnonCredsCredentialInfo? = nil,
        revoked: Bool? = nil
    ) {
        self.credentialId = credentialId
        self.timestamp = timestamp
        self.revealed = revealed
        self.credentialInfo = credentialInfo
        self.revoked = revoked
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        credentialId = try container.decode(String.self, forKey: .credentialId)
        revealed = try container.decode(Bool.self, forKey: .revealed)

        if let intValue = try? container.decode(Int.self, forKey: .timestamp) {
            timestamp = intValue
        } else if let stringValue = try? container.decode(String.self, forKey: .timestamp),
                  let intFromString = Int(stringValue) {
            timestamp = intFromString
        } else {
            timestamp = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credentialId, forKey: .credentialId)
        try container.encode(revealed, forKey: .revealed)
        if let timestamp = timestamp {
            try container.encode(timestamp, forKey: .timestamp)
        }
    }

    public func toStringAnyCodable() -> [String: AnyCodable] {
        var json: [String: AnyCodable] = [
            "credentialId": AnyCodable(credentialId),
            "revealed": AnyCodable(revealed)
        ]

        if let timestamp = timestamp {
            json["timestamp"] = AnyCodable(timestamp)
        }

        if let credentialInfo = credentialInfo {
            json["credentialInfo"] = AnyCodable(credentialInfo.toJsonElement())
        }

        return json
    }

    public func toJsonString() throws -> String {
        let jsonObj = toStringAnyCodable()
        let data = try JSONSerialization.data(withJSONObject: jsonObj, options: [.prettyPrinted])
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
