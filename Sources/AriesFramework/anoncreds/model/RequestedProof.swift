//
//  RequestedProof.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct RequestedProof: Codable {
    public var revealedAttrs: [String: RevealedAttr]
    public var revealedAttrGroups: [String: RevealedAttrGroup]?
    public var unrevealedAttrs: [String: SubProofIndexOnly]
    public var selfAttestedAttrs: [String: String]
    public var predicates: [String: SubProofIndexOnly]

    enum CodingKeys: String, CodingKey {
        case revealedAttrs = "revealed_attrs"
        case revealedAttrGroups = "revealed_attr_groups"
        case unrevealedAttrs = "unrevealed_attrs"
        case selfAttestedAttrs = "self_attested_attrs"
        case predicates
    }
}

public struct RevealedAttr: Codable {
    public var subProofIndex: Int
    public var raw: String
    public var encoded: String

    enum CodingKeys: String, CodingKey {
        case subProofIndex = "sub_proof_index"
        case raw
        case encoded
    }
}

public struct RevealedAttrGroup: Codable {
    public var subProofIndex: Int
    public var values: [String: AttrValue]

    enum CodingKeys: String, CodingKey {
        case subProofIndex = "sub_proof_index"
        case values
    }
}

public struct AttrValue: Codable {
    public var raw: String
    public var encoded: String
}

public struct SubProofIndexOnly: Codable {
    public var subProofIndex: Int

    enum CodingKeys: String, CodingKey {
        case subProofIndex = "sub_proof_index"
    }
}

public struct Identifier: Codable {
    public var schemaId: String
    public var credDefId: String
    public var revRegId: String?
    public var timestamp: UInt64?

    enum CodingKeys: String, CodingKey {
        case schemaId = "schema_id"
        case credDefId = "cred_def_id"
        case revRegId = "rev_reg_id"
        case timestamp
    }
    
    
}
