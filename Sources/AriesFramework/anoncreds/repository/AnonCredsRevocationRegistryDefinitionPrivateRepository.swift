//
//  AnonCredsRevocationRegistryDefinitionPrivateRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

public class AnonCredsRevocationRegistryDefinitionPrivateRepository: Repository<AnonCredsRevocationRegistryDefinitionPrivateRecord> {

    func getByRevocationRegistryDefinitionId(
        revocationRegistryDefinitionId: String
    ) async throws -> AnonCredsRevocationRegistryDefinitionPrivateRecord {
        return try await getSingleByQuery(revocationRegistryDefinitionId)
    }
    
    func findByRevocationRegistryDefinitionId(_ revocationRegistryDefinitionId: String) async throws -> AnonCredsRevocationRegistryDefinitionPrivateRecord? {
        return try await findSingleByQuery(revocationRegistryDefinitionId)
    }

    func findAllByCredentialDefinitionIdAndState(
        credentialDefinitionId: String,
        state: AnonCredsRevocationRegistryState?
    ) async throws -> [AnonCredsRevocationRegistryDefinitionPrivateRecord] {
        let statePart = state != nil ? "\"state\": \"\(state!.rawValue)\"" : ""
        let query = "{\"credentialDefinitionId\": \"\(credentialDefinitionId)\"\(statePart.isEmpty ? "" : ", \(statePart)")}"
        return await findByQuery(query)
    }
}
