//
//  AnonCredsCredentialDefinitionRepositoryProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 20/02/26.
//

public protocol AnonCredsCredentialDefinitionRepositoryProtocol {
    func getByCredentialDefinitionId(
        _ credentialDefinitionId: String
    ) async throws -> AnonCredsCredentialDefinitionRecord
}
