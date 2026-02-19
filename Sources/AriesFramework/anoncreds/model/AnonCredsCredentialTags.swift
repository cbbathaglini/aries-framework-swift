//
//  AnonCredsCredentialTags.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation

public struct AnonCredsCredentialTags: Codable {
    let linkSecretId: String
    let credentialRevocationId: String?
    let methodName: String
    let schemaName: String
    let schemaVersion: String
    let schemaId: String
    let schemaIssuerId: String
    let credentialDefinitionId: String
    let revocationRegistryId: String?
    let unqualifiedIssuerId: String?
    let unqualifiedSchemaId: String?
    let unqualifiedSchemaIssuerId: String?
    let unqualifiedCredentialDefinitionId: String?
    let unqualifiedRevocationRegistryId: String?
    let dynamicAttributes: [String: String?]

    enum CodingKeys: String, CodingKey {
        case linkSecretId = "anonCredsLinkSecretId"
        case credentialRevocationId = "anonCredsCredentialRevocationId"
        case methodName = "anonCredsMethodName"
        case schemaName = "anonCredsSchemaName"
        case schemaVersion = "anonCredsSchemaVersion"
        case schemaId = "anonCredsSchemaId"
        case schemaIssuerId = "anonCredsSchemaIssuerId"
        case credentialDefinitionId = "anonCredsCredentialDefinitionId"
        case revocationRegistryId = "anonCredsRevocationRegistryId"
        case unqualifiedIssuerId = "anonCredsUnqualifiedIssuerId"
        case unqualifiedSchemaId = "anonCredsUnqualifiedSchemaId"
        case unqualifiedSchemaIssuerId = "anonCredsUnqualifiedSchemaIssuerId"
        case unqualifiedCredentialDefinitionId = "anonCredsUnqualifiedCredentialDefinitionId"
        case unqualifiedRevocationRegistryId = "anonCredsUnqualifiedRevocationRegistryId"
        case dynamicAttributes
    }

    init(
        linkSecretId: String,
        credentialRevocationId: String? = nil,
        methodName: String,
        schemaName: String,
        schemaVersion: String,
        schemaId: String,
        schemaIssuerId: String,
        credentialDefinitionId: String,
        revocationRegistryId: String? = nil,
        unqualifiedIssuerId: String? = nil,
        unqualifiedSchemaId: String? = nil,
        unqualifiedSchemaIssuerId: String? = nil,
        unqualifiedCredentialDefinitionId: String? = nil,
        unqualifiedRevocationRegistryId: String? = nil,
        dynamicAttributes: [String: String?] = [:]
    ) {
        self.linkSecretId = linkSecretId
        self.credentialRevocationId = credentialRevocationId
        self.methodName = methodName
        self.schemaName = schemaName
        self.schemaVersion = schemaVersion
        self.schemaId = schemaId
        self.schemaIssuerId = schemaIssuerId
        self.credentialDefinitionId = credentialDefinitionId
        self.revocationRegistryId = revocationRegistryId
        self.unqualifiedIssuerId = unqualifiedIssuerId
        self.unqualifiedSchemaId = unqualifiedSchemaId
        self.unqualifiedSchemaIssuerId = unqualifiedSchemaIssuerId
        self.unqualifiedCredentialDefinitionId = unqualifiedCredentialDefinitionId
        self.unqualifiedRevocationRegistryId = unqualifiedRevocationRegistryId
        self.dynamicAttributes = dynamicAttributes
    }
}
