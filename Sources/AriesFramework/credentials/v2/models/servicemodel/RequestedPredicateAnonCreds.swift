//
//  RequestedPredicateAnonCreds.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable

public struct RequestedPredicateAnonCreds: Codable {
    public var credentialId: String
    public var timestamp: Int?
    public var credentialInfo: AnonCredsCredentialInfo?
    public var revoked: Bool?

    enum CodingKeys: String, CodingKey {
        case credentialId
        case timestamp
        case credentialInfo
        case revoked
    }

    public func toStringAnyCodable() -> [String: AnyCodable] {
        var json: [String: AnyCodable] = [
            "credentialId": AnyCodable(credentialId)
        ]

        if let revoked = revoked {
            json["revoked"] = AnyCodable(revoked)
        }

        if let credentialInfo = credentialInfo {
            json["credentialInfo"] = AnyCodable(credentialInfo.toJsonElement())
        }

        if let timestamp = timestamp {
            json["timestamp"] = AnyCodable(timestamp)
        }

        return json
    }
}
