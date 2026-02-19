//
//  AnonCredsRegistry.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation

public protocol AnonCredsRegistry {
    var methodName: String { get }
    var supportedIdentifier: NSRegularExpression { get }

    func getSchema(agent: Agent, schemaId: String) async throws -> GetSchemaReturn

    func getCredentialDefinition(agent: Agent, credentialDefinitionId: String) async throws -> GetCredentialDefinitionReturn

    func getRevocationRegistryDefinition(agent: Agent,
                                         revocationRegistryDefinitionId: String) async throws -> GetRevocationRegistryDefinitionReturn

    func getRevocationStatusList(
        agent: Agent,
        revocationRegistryId: String,
        timestamp: UInt64
    ) async throws -> GetRevocationStatusListReturn

    // Descomentar futuramente, se for implementar:
    /*
    func registerRevocationStatusList(options: RegisterRevocationStatusListOptions) async throws -> RegisterRevocationStatusListReturn

    func registerCredentialDefinition(options: RegisterCredentialDefinitionOptions) async throws -> RegisterCredentialDefinitionReturn

    func registerRevocationRegistryDefinition(options: RegisterRevocationRegistryDefinitionOptions) async throws -> RegisterRevocationRegistryDefinitionReturn

    func registerSchema(options: RegisterSchemaOptions) async throws -> RegisterSchemaReturn
    */
}
