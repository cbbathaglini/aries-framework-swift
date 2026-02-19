//
//  AnonCredsCredentialProposalFormat.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public struct AnonCredsCredentialProposalFormat: Codable {
    let schemaIssuerId: String?
    let schemaName: String?
    let schemaVersion: String?
    let schemaId: String?
    let credDefId: String?
    let issuerId: String?
    let schemaIssuerDid: String?
    let issuerDid: String?

    enum CodingKeys: String, CodingKey {
        case schemaIssuerId = "schema_issuer_id"
        case schemaName = "schema_name"
        case schemaVersion = "schema_version"
        case schemaId = "schema_id"
        case credDefId = "cred_def_id"
        case issuerId = "issuer_id"
        case schemaIssuerDid = "schema_issuer_did"
        case issuerDid = "issuer_did"
    }
}
