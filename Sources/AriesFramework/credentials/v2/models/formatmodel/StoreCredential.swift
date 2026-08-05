//
//  StoreCredential.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct StoreCredential {
    
    static func getStoreCredentialOptions(
        options: StoreCredentialOptions,
        indyNamespace: String? = nil
    ) throws -> StoreCredentialOptions {
        
        let revocationRegistry = options.revocationRegistry
        let credentialDefinitionId = options.credentialDefinitionId
        let schema = options.schema
        let credential = options.credential
        var credentialDefinition = options.credentialDefinition
        
        let credDefId: String = try {
            if IndyIdentifiers.isUnqualifiedCredentialDefinitionId(credentialDefinitionId),
               let namespace = indyNamespace {
                return try IndyIdentifiers.getQualifiedDidIndyDid(identifier: credentialDefinitionId, namespace: namespace)
            } else {
                return credentialDefinitionId
            }
        }()
        
        credentialDefinition = try {
            if IndyIdentifiers.isUnqualifiedDidIndyCredentialDefinition(credentialDefinition),
               let namespace = indyNamespace {
                return try IndyIdentifiers.getQualifiedDidIndyCredentialDefinition(
                    credentialDefinition: credentialDefinition,
                    namespace: namespace
                )
            } else {
                return credentialDefinition
            }
        }()
        
        let schemaParam: AnonCredsSchema = try {
            if IndyIdentifiers.isUnqualifiedDidIndySchema(schema),
               let namespace = indyNamespace {
                return try IndyIdentifiers.getQualifiedDidIndySchema(schema: schema, namespace: namespace)
            } else {
                return schema
            }
        }()
        
        if let revocationRegistry = revocationRegistry {
            let definition = revocationRegistry.definition

            if IndyIdentifiers.isUnqualifiedDidIndyRevocationRegistryDefinition(definition) {
                print("getQualifiedDidIndyRevocationRegistryDefinition(1): \(try IndyIdentifiers.getQualifiedDidIndyRevocationRegistryDefinition(definition, namespace: indyNamespace ?? ""))")
            } else {
                print("getQualifiedDidIndyRevocationRegistryDefinition(2): \(definition)")
            }

            if IndyIdentifiers.isUnqualifiedRevocationRegistryId(revocationRegistry.id) {
                print("getQualifiedDidIndyDid(1): \(try IndyIdentifiers.getQualifiedDidIndyDid(identifier: revocationRegistry.id, namespace: indyNamespace ?? ""))")
            } else {
                print("getQualifiedDidIndyDid(2): \(revocationRegistry.id)")
            }

            let qualifiedDefinition = IndyIdentifiers.isUnqualifiedDidIndyRevocationRegistryDefinition(definition)
                ? try IndyIdentifiers.getQualifiedDidIndyRevocationRegistryDefinition(definition, namespace: indyNamespace ?? "")
                : definition

            let qualifiedId = IndyIdentifiers.isUnqualifiedRevocationRegistryId(revocationRegistry.id)
                ? try IndyIdentifiers.getQualifiedDidIndyDid(identifier: revocationRegistry.id, namespace: indyNamespace ?? "")
                : revocationRegistry.id

            let revocationRegistryInfo = RevocationRegistryInfo(
                id: qualifiedId,
                definition: qualifiedDefinition
            )

        }

        return StoreCredentialOptions(
            credential: credential,
            credentialRequestMetadata: options.credentialRequestMetadata,
            credentialDefinition: credentialDefinition,
            schema: schemaParam,
            schemaId: options.schemaId,
            credentialDefinitionId: credDefId,
            credentialId: UUID().uuidString,
            revocationRegistry: revocationRegistry
        )
    }
}
