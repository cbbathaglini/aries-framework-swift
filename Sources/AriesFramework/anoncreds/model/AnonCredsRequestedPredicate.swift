//
//  AnonCredsRequestedPredicate.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsRequestedPredicate: Codable {
    public var name: String
    
    public var pType: PredicateType
    public var pValue: Int64
    public var restrictions: [AnonCredsProofRequestRestriction]?
    public var nonRevoked: AnonCredsNonRevokedInterval?

    enum CodingKeys: String, CodingKey {
        case name
        case pType = "p_type"
        case pValue = "p_value"
        case restrictions
        case nonRevoked = "non_revoked"
    }

    public init(
        name: String,
        pType: PredicateType,
        pValue: Int64,
        restrictions: [AnonCredsProofRequestRestriction]? = nil,
        nonRevoked: AnonCredsNonRevokedInterval? = nil
    ) {
        self.name = name
        self.pType = pType
        self.pValue = pValue
        self.restrictions = restrictions
        self.nonRevoked = nonRevoked
    }

    public func asAnonCredsRequestedAttribute() -> AnonCredsRequestedAttribute {
        return AnonCredsRequestedAttribute(
            name: name,
            names: nil,
            restrictions: restrictions,
            nonRevoked: nonRevoked
        )
    }
}
