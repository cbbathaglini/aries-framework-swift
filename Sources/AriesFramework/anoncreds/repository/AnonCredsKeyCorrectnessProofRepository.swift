//
//  AnonCredsKeyCorrectnessProofRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public class AnonCredsKeyCorrectnessProofRepository: Repository<AnonCredsKeyCorrectnessProofRecord> {

    func getByCredentialDefinitionId(_ credentialDefinitionId: String) async throws -> AnonCredsKeyCorrectnessProofRecord {
        let query = "{\"credentialDefinitionId\": \"\(credentialDefinitionId)\"}"
        return try await getSingleByQuery(query)
    }

    func findByCredentialDefinitionId(_ credentialDefinitionId: String) async throws -> AnonCredsKeyCorrectnessProofRecord? {
        let query = "{\"credentialDefinitionId\": \"\(credentialDefinitionId)\"}"
        return try await findSingleByQuery(query)
    }
}
