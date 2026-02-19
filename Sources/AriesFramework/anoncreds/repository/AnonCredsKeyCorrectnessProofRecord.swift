//
//  AnonCredsKeyCorrectnessProofRecord.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation
import AnyCodable

public class AnonCredsKeyCorrectnessProofRecord: BaseRecord, Codable {
    public static let type = "AnonCredsKeyCorrectnessProofRecord"

    public var id: String
    public var tags: Tags?
    public var createdAt: Date
    public var updatedAt: Date?

    public var credentialDefinitionId: String
    public var value: [String: AnyCodable]
    public var metadata: [String: AnyCodable] = [:]

    enum CodingKeys: String, CodingKey {
        case id, tags = "_tags", createdAt, updatedAt, metadata
        case credentialDefinitionId, value
    }

    init(
        id: String,
        tags: Tags? = nil,
        createdAt: Date,
        updatedAt: Date? = nil,
        credentialDefinitionId: String,
        value: [String: AnyCodable]
    ) {
        self.id = id
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.credentialDefinitionId = credentialDefinitionId
        self.value = value
    }

   
    public func getTags() -> Tags {
        var tagMap = tags ?? [:]
        tagMap["credentialDefinitionId"] = credentialDefinitionId
        return tagMap
    }


}
