//
//  AnonCredsRevocationRegistryDefinitionPrivateRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public class AnonCredsRevocationRegistryDefinitionPrivateRecord: BaseRecord, Codable {
    public static let type = "AnonCredsRevocationRegistryDefinitionPrivateRecord"

    public var id: String
    public var tags: Tags?
    public var createdAt: Date
    public var updatedAt: Date?

    public var revocationRegistryDefinitionId: String
    public var credentialDefinitionId: String
    public var value: [String: AnyCodable]
    public var state: AnonCredsRevocationRegistryState
    public var metadata: [String: AnyCodable] = [:]

    enum CodingKeys: String, CodingKey {
        case id, tags = "_tags", createdAt, updatedAt, metadata
        case revocationRegistryDefinitionId, credentialDefinitionId, value, state
    }

    init(
        id: String = UUID().uuidString,
        tags: Tags? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        revocationRegistryDefinitionId: String,
        credentialDefinitionId: String,
        value: [String: AnyCodable],
        state: AnonCredsRevocationRegistryState
    ) {
        self.id = id
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.revocationRegistryDefinitionId = revocationRegistryDefinitionId
        self.credentialDefinitionId = credentialDefinitionId
        self.value = value
        self.state = state
    }

    public func getTags() -> Tags {
        var tagMap = tags ?? [:]
        tagMap["revocationRegistryDefinitionId"] = revocationRegistryDefinitionId
        tagMap["credentialDefinitionId"] = credentialDefinitionId
        tagMap["state"] = state.rawValue
        return tagMap
    }

}
