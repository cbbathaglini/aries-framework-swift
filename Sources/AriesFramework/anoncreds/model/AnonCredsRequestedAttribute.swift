//
//  AnonCredsRequestedAttribute.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsRequestedAttribute: Codable {
    
    public var name: String?
    public var names: [String]?
    public var restrictions: [AnonCredsProofRequestRestriction]?
    public var nonRevoked: AnonCredsNonRevokedInterval?

    enum CodingKeys: String, CodingKey {
        case name
        case names
        case restrictions
        case nonRevoked = "non_revoked"
    }

    public init(
        name: String? = nil,
        names: [String]? = nil,
        restrictions: [AnonCredsProofRequestRestriction]? = nil,
        nonRevoked: AnonCredsNonRevokedInterval? = nil
    ) {
        self.name = name
        self.names = names
        self.restrictions = restrictions
        self.nonRevoked = nonRevoked
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(names, forKey: .names)
        try container.encodeIfPresent(nonRevoked, forKey: .nonRevoked)
        
        if let restrictions = restrictions, !restrictions.isEmpty {
            try container.encode(restrictions, forKey: .restrictions)
        }
    }
}
