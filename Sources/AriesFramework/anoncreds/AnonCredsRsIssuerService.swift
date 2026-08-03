//
//  AnonCredsRsIssuerService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import Anoncreds

public class AnonCredsRsIssuerService: AnonCredsIssuerService {
    public let agent: Agent

    init(agent: Agent) {
        self.agent = agent
    }

    func createCredentialOffer(credentialDefinitionId: String) async throws -> AnonCredsCredentialOffer {
        let credentialDefinitionRecord = try await agent.anonCredsCredentialDefinitionRepository
            .getByCredentialDefinitionId(credentialDefinitionId)

        let keyCorrectnessProofRecord = try await agent.anonCredsKeyCorrectnessProofRepository
            .getByCredentialDefinitionId(credentialDefinitionRecord.credentialDefinitionId)
        
        var schemaId = credentialDefinitionRecord.credentialDefinition.schemaId

        if IndyIdentifiers.isUnqualifiedCredentialDefinitionId(credentialDefinitionId) {
            let parsed = try IndyIdentifiers.parseIndySchemaId(schemaId)
            schemaId = IndyIdentifiers.getUnqualifiedSchemaId(
                unqualifiedDid: parsed.0,
                name: parsed.1,
                version: parsed.2
            )
        }

        let offerJson = CredentialOfferJson(
            schemaId: schemaId,
            credDefId: credentialDefinitionId,
            keyProof: keyCorrectnessProofRecord.value
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let jsonData = try encoder.encode(offerJson)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw AnonCredsError("Failed to encode CredentialOfferJson")
        }
        
        let credentialOffer = try CredentialOffer(json: jsonString)
        let credentialOfferJson = credentialOffer.toJson().data(using: .utf8)!

        let decodedOffer = try JSONDecoder().decode(AnonCredsCredentialOffer.self, from: credentialOfferJson)
        return decodedOffer
    }

    func createCredential(options: CreateCredentialOptions) async throws -> CreateCredentialReturn {
        throw NSError(domain: "NotImplemented", code: 0, userInfo: [NSLocalizedDescriptionKey: "createCredential not implemented yet"])
    }
}
