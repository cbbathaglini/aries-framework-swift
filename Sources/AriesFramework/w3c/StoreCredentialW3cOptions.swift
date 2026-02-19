//
//  StoreCredentialW3cOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation

struct StoreCredentialW3cOptions: Codable {
    let credential: W3cJsonLdVerifiableCredential
    let credentialDefinitionId: String
    let schema: AnonCredsSchema
    let schemaId: String?
    let credentialDefinition: AnonCredsCredentialDefinition
    let revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition?
    let revocationRegistryId: String?
    let credentialRequestMetadata: AnonCredsCredentialRequestMetadata

    init(
        credential: W3cJsonLdVerifiableCredential,
        credentialDefinitionId: String,
        schema: AnonCredsSchema,
        schemaId: String? = nil,
        credentialDefinition: AnonCredsCredentialDefinition,
        revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition? = nil,
        revocationRegistryId: String? = nil,
        credentialRequestMetadata: AnonCredsCredentialRequestMetadata
    ) {
        self.credential = credential
        self.credentialDefinitionId = credentialDefinitionId
        self.schema = schema
        self.schemaId = schemaId
        self.credentialDefinition = credentialDefinition
        self.revocationRegistryDefinition = revocationRegistryDefinition
        self.revocationRegistryId = revocationRegistryId
        self.credentialRequestMetadata = credentialRequestMetadata
    }
}
