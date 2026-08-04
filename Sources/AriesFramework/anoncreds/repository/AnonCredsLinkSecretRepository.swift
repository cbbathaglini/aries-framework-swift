//
//  AnonCredsLinkSecretRepository.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation

public class AnonCredsLinkSecretRepository: Repository<AnonCredsLinkSecretRecord> {

    public func getByLinkSecretId(_ linkSecretId: String) async throws -> AnonCredsLinkSecretRecord {
        let query = "{\"linkSecretId\": \"\(linkSecretId)\"}"
        return try await getSingleByQuery(query)
    }

    public func findByLinkSecretId(_ linkSecretId: String) async throws -> AnonCredsLinkSecretRecord? {
        let query = "{\"linkSecretId\": \"\(linkSecretId)\"}"
        return try await findSingleByQuery(query)
    }

    public func findDefault() async throws -> AnonCredsLinkSecretRecord? {
        let query = "{\"isDefault\": \"true\"}"
        return try await findSingleByQuery(query)
    }
}
