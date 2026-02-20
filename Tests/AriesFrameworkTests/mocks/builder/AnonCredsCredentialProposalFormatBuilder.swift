//
//  AnonCredsCredentialProposalFormatBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework

final class AnonCredsCredentialProposalFormatBuilder {

    private var schemaIssuerId: String? = "issuer:schema"
    private var schemaName: String? = "TestSchema"
    private var schemaVersion: String? = "1.0"
    private var schemaId: String? = "schema:test:1"
    private var credDefId: String? = "creddef:test:1"
    private var issuerId: String? = "issuer:test"
    private var schemaIssuerDid: String? = "did:test:schema-issuer"
    private var issuerDid: String? = "did:test:issuer"

    // MARK: - Fluent API

    func withSchemaIssuerId(_ value: String?) -> Self {
        self.schemaIssuerId = value
        return self
    }

    func withSchemaName(_ value: String?) -> Self {
        self.schemaName = value
        return self
    }

    func withSchemaVersion(_ value: String?) -> Self {
        self.schemaVersion = value
        return self
    }

    func withSchemaId(_ value: String?) -> Self {
        self.schemaId = value
        return self
    }

    func withCredentialDefinitionId(_ value: String?) -> Self {
        self.credDefId = value
        return self
    }

    func withIssuerId(_ value: String?) -> Self {
        self.issuerId = value
        return self
    }

    func withSchemaIssuerDid(_ value: String?) -> Self {
        self.schemaIssuerDid = value
        return self
    }

    func withIssuerDid(_ value: String?) -> Self {
        self.issuerDid = value
        return self
    }
    
    func minimal() -> Self {
       self.schemaIssuerId = nil
       self.schemaName = nil
       self.schemaVersion = nil
       self.schemaId = nil
       self.issuerId = nil
       self.schemaIssuerDid = nil
       self.issuerDid = nil
       return self
   }

    // MARK: - Build

    func build() -> AnonCredsCredentialProposalFormat {
        AnonCredsCredentialProposalFormat(
            schemaIssuerId: schemaIssuerId,
            schemaName: schemaName,
            schemaVersion: schemaVersion,
            schemaId: schemaId,
            credDefId: credDefId,
            issuerId: issuerId,
            schemaIssuerDid: schemaIssuerDid,
            issuerDid: issuerDid
        )
    }
}
