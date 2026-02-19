//
//  AnonCredsClaimRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 29/09/25.
//

import Foundation



public struct AnonCredsCredentialInfo: Codable, CustomStringConvertible {
    public var credentialId: String
    public var attributes: AnonCredsClaimRecord
    public var schemaId: String
    public var credentialDefinitionId: String
    public var revocationRegistryId: String?
    public var credentialRevocationId: String?
    public var methodName: String
    public var createdAt: Date
    public var updatedAt: Date
    public var linkSecretId: String

    public init(
        credentialId: String,
        attributes: AnonCredsClaimRecord,
        schemaId: String,
        credentialDefinitionId: String,
        revocationRegistryId: String? = nil,
        credentialRevocationId: String? = nil,
        methodName: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        linkSecretId: String
    ) {
        self.credentialId = credentialId
        self.attributes = attributes
        self.schemaId = schemaId
        self.credentialDefinitionId = credentialDefinitionId
        self.revocationRegistryId = revocationRegistryId
        self.credentialRevocationId = credentialRevocationId
        self.methodName = methodName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.linkSecretId = linkSecretId
    }

    public var description: String {
        return """
        AnonCredsCredentialInfo(
            credentialId: "\(credentialId)",
            attributes: \(attributes),
            schemaId: "\(schemaId)",
            credentialDefinitionId: "\(credentialDefinitionId)",
            revocationRegistryId: \(revocationRegistryId ?? "nil"),
            credentialRevocationId: \(credentialRevocationId ?? "nil"),
            methodName: "\(methodName)",
            createdAt: \(createdAt),
            updatedAt: \(updatedAt),
            linkSecretId: "\(linkSecretId)"
        )
        """
    }

    public func toJson() -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
}
