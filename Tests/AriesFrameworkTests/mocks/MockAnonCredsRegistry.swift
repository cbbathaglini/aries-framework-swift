//
//  MockAnonCredsRegistry.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 06/01/26.
//
@testable import AriesFramework
import Foundation
import AnyCodable

final class MockAnonCredsRegistry: AnonCredsRegistry {

    let methodName: String = "mock"
    let supportedIdentifier: NSRegularExpression =
        try! NSRegularExpression(pattern: ".*", options: [])

    var schemaToReturn: AnonCredsSchema?

    init(schema: AnonCredsSchema) {
        self.schemaToReturn = schema
    }

    func getSchema(
        agent: Agent,
        schemaId: String
    ) async throws -> GetSchemaReturn {

        guard let schema = schemaToReturn else {
            throw CredoError("Mock schema not configured")
        }

        return GetSchemaReturn(
            schema: schema,
            schemaId: schemaId,
            resolutionMetadata: AnonCredsResolutionMetadata(),
            schemaMetadata: [
                "didIndyNamespace": AnyCodable("test")
            ]
        )
    }

    func getCredentialDefinition(
        agent: Agent,
        credentialDefinitionId: String
    ) async throws -> GetCredentialDefinitionReturn {
        fatalError("Not needed for acceptProposal test")
    }

    func getRevocationRegistryDefinition(
        agent: Agent,
        revocationRegistryDefinitionId: String
    ) async throws -> GetRevocationRegistryDefinitionReturn {
        fatalError("Not needed for acceptProposal test")
    }

    func getRevocationStatusList(
        agent: Agent,
        revocationRegistryId: String,
        timestamp: UInt64
    ) async throws -> GetRevocationStatusListReturn {
        fatalError("Not needed for acceptProposal test")
    }
}
