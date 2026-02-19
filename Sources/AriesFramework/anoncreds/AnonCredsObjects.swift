//
//  AnonCredsObjects.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

class AnonCredsObjects {

    static func fetchCredentialDefinition(
        agent: Agent,
        credentialDefinitionId: String
    ) async throws -> CredentialDefinitionResult {
        let registry = try agent.anonCredsRegistryService
            .getRegistryForIdentifier(for: credentialDefinitionId)
        let result = try await registry.getCredentialDefinition(agent: agent, credentialDefinitionId: credentialDefinitionId)

        guard let credentialDefinition = result.credentialDefinition else {
            let message = result.resolutionMetadata?.message as? String ?? "Unknown error"
            throw CredoError("Credential definition not found for id \(credentialDefinitionId): \(message)")
        }

        let indyNamespace = result.credentialDefinitionMetadata["didIndyNamespace"] as? String

        return CredentialDefinitionResult(
            credentialDefinition: credentialDefinition,
            credentialDefinitionId: credentialDefinitionId,
            indyNamespace: indyNamespace
        )
    }

    static func fetchRevocationStatusList(
        agent: Agent,
        revocationRegistryId: String,
        timestamp: UInt64
    ) async throws -> AnonCredsRevocationStatusList {
        let registry : AnonCredsRegistry = try agent.anonCredsRegistryService.getRegistryForIdentifier(for: revocationRegistryId)
        let result = try await registry.getRevocationStatusList(agent: agent, revocationRegistryId: revocationRegistryId, timestamp: timestamp)

        guard let list = result.revocationStatusList else {
            let message = result.resolutionMetadata?.message as? String ?? "Unknown error"
            throw CredoError("Could not retrieve revocation status list for revocation registry \(revocationRegistryId): \(message)")
        }

        return list
    }

}
