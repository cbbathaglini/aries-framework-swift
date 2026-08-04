//
//  CredentialOfferJson.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

struct CredentialOfferJson: Codable {
    let schemaId: String
    let credDefId: String
    let keyProof: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case schemaId = "schema_id"
        case credDefId = "cred_def_id"
        case keyProof = "key_proof"
    }
}
