//
//  AnonCredsCredentialInfo.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public typealias AnonCredsClaimRecord = [String: String]

public struct AnonCredsCredentialInfo: Codable, CustomStringConvertible {
    public var credentialId: String
    public var attributes: [String: String]
    public var schemaId: String
    public var credentialDefinitionId: String
    public var revocationRegistryId: String?
    public var credentialRevocationId: String?
    public var methodName: String
    public var createdAt: FlexibleDate
    public var updatedAt: FlexibleDate
    public var linkSecretId: String

    public init(
            credentialId: String,
            attributes: [String: String],
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
            self.createdAt = FlexibleDate(createdAt)
            self.updatedAt = FlexibleDate(updatedAt)
            self.linkSecretId = linkSecretId
        }

    public var description: String {
        return """
        AnonCredsCredentialInfo(
            credentialId: "\(credentialId)",
            attributes: \(attributes),
            schemaId: "\(schemaId)",
            credentialDefinitionId: "\(credentialDefinitionId)",
            revocationRegistryId: \(String(describing: revocationRegistryId)),
            credentialRevocationId: \(String(describing: credentialRevocationId)),
            methodName: "\(methodName)",
            createdAt: \(createdAt.date),
            updatedAt: \(updatedAt.date),
            linkSecretId: "\(linkSecretId)"
        )
        """
    }

    public func toJsonElement() -> [String: AnyCodable] {
        var json: [String: AnyCodable] = [:]
        json["credentialId"] = AnyCodable(credentialId)
        json["attributes"] = AnyCodable(attributes)
        json["schemaId"] = AnyCodable(schemaId)
        json["credentialDefinitionId"] = AnyCodable(credentialDefinitionId)
        json["revocationRegistryId"] = AnyCodable(revocationRegistryId)
        json["credentialRevocationId"] = AnyCodable(credentialRevocationId)
        json["methodName"] = AnyCodable(methodName)
        json["createdAt"] = AnyCodable(ISO8601DateFormatter().string(from: createdAt.date))
        json["updatedAt"] = AnyCodable(ISO8601DateFormatter().string(from: updatedAt.date))
        json["linkSecretId"] = AnyCodable(linkSecretId)
        return json
    }
}
