//
//  AnonCredsRequestedAttributeMatch.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsRequestedAttributeMatch: Codable {
    public var credentialId: String
    public var timestamp: UInt64?
    public var revealed: Bool
    public var credentialInfo: AnonCredsCredentialInfo
    public var revoked: Bool?

    enum CodingKeys: String, CodingKey {
        case credentialId
        case timestamp
        case revealed
        case credentialInfo
        case revoked
    }

    public init(
        credentialId: String,
        timestamp: UInt64? = nil,
        revealed: Bool,
        credentialInfo: AnonCredsCredentialInfo,
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
        credentialInfo = try container.decode(AnonCredsCredentialInfo.self, forKey: .credentialInfo)
        
        if let intValue = try? container.decode(UInt64.self, forKey: .timestamp) {
            timestamp = intValue
        }
        
        if let boolValue = try? container.decode(Bool.self, forKey: .revoked) {
            revoked = boolValue
        } else if let strValue = try? container.decode(String.self, forKey: .revoked) {
            revoked = (strValue as NSString).boolValue
        } else {
            revoked = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(credentialId, forKey: .credentialId)
        try container.encodeIfPresent(timestamp, forKey: .timestamp)
        try container.encode(revealed, forKey: .revealed)
        try container.encode(credentialInfo, forKey: .credentialInfo)
        try container.encodeIfPresent(revoked, forKey: .revoked)
    }
}
