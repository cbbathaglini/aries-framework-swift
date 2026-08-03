//
//  RecoverFromLedger.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation
import Anoncreds

class RecoverFromLedger {

    static func getSchemas(schemaIds: Set<String>, agent: Agent) async throws -> [String: Schema] {
        var schemas = [String: Schema]()

        for schemaId in schemaIds {
            let (schema, _) = try await agent.ledgerService.getSchema(schemaId: schemaId)
            schemas[schemaId] = try Schema(json: schema)
        }

        return schemas
    }

    static func getCredentialDefinitions(credentialDefinitionIds: Set<String>, agent: Agent) async throws -> [String: CredentialDefinition] {
        var credentialDefinitions = [String: CredentialDefinition]()

        for credDefId in credentialDefinitionIds {
            let def = try await agent.ledgerService.getCredentialDefinition(id: credDefId)
            credentialDefinitions[credDefId] = try CredentialDefinition(json: def)
        }

        return credentialDefinitions
    }
}
