//
//  AnonCredsCredentialRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

public class AnonCredsCredentialRepository: Repository<AnonCredsCredentialRecord> {


    public func getByCredentialDefinitionId(_ credentialDefinitionId: String) async throws -> AnonCredsCredentialRecord {
        return try await getSingleByQuery("""
        {"credentialDefinitionId": "\(credentialDefinitionId)"}
        """)
    }

    public func findByCredentialDefinitionId(_ credentialDefinitionId: String) async throws -> AnonCredsCredentialRecord? {
        return try await findSingleByQuery("""
        {"credentialDefinitionId": "\(credentialDefinitionId)"}
        """)
    }

    public func getByCredentialId(_ credentialId: String) async throws -> AnonCredsCredentialRecord {
        return try await getSingleByQuery("""
        {"credentialId": "\(credentialId)"}
        """)
    }

    public func findByCredentialId(_ credentialId: String) async throws -> AnonCredsCredentialRecord? {
        return try await findSingleByQuery("""
        {"credentialId": "\(credentialId)"}
        """)
    }
}
