//
//  StoreCredentialOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct StoreCredentialOptions {
    let credential: Any
    let credentialRequestMetadata: AnonCredsCredentialRequestMetadata
    let credentialDefinition: AnonCredsCredentialDefinition
    let schema: AnonCredsSchema
    let schemaId: String?
    let credentialDefinitionId: String
    let credentialId: String?
    let revocationRegistry: RevocationRegistryInfo?
}
