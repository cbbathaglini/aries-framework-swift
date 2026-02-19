//
//  AnonCredsCredentialDefinitionRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public class AnonCredsCredentialDefinitionRepository: Repository<AnonCredsCredentialDefinitionRecord> {
    public func getByCredentialDefinitionId(_ credentialDefinitionId: String) async throws -> AnonCredsCredentialDefinitionRecord {
        let query = "{\"credentialDefinitionId\": \"\(credentialDefinitionId)\"}"
        return try await getSingleByQuery(query)
    }
}
