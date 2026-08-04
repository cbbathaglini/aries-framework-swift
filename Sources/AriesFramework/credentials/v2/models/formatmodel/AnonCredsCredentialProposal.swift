//
//  AnonCredsCredentialProposal.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

import Foundation

public struct AnonCredsCredentialProposal: Codable {
    public var schemaIssuerDid: String?
    public var schemaIssuerId: String?
    public var schemaId: String?
    public var schemaName: String?
    public var schemaVersion: String?
    public var credentialDefinitionId: String?
    public var issuerDid: String?
    public var issuerId: String?

    enum CodingKeys: String, CodingKey {
        case schemaIssuerDid = "schema_issuer_did"
        case schemaIssuerId = "schema_issuer_id"
        case schemaId = "schema_id"
        case schemaName = "schema_name"
        case schemaVersion = "schema_version"
        case credentialDefinitionId = "cred_def_id"
        case issuerDid = "issuer_did"
        case issuerId = "issuer_id"
    }
}

extension AnonCredsCredentialProposal: CustomStringConvertible {
    public var description: String {
        return """
        AnonCredsCredentialProposal(
            schemaIssuerDid: \(schemaIssuerDid ?? "nil"),
            schemaIssuerId: \(schemaIssuerId ?? "nil"),
            schemaId: \(schemaId ?? "nil"),
            schemaName: \(schemaName ?? "nil"),
            schemaVersion: \(schemaVersion ?? "nil"),
            credentialDefinitionId: \(credentialDefinitionId ?? "nil"),
            issuerDid: \(issuerDid ?? "nil"),
            issuerId: \(issuerId ?? "nil")
        )
        """
    }
}
