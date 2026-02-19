//
//  GetSchemaReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable

public struct GetSchemaReturn: Codable {
    let schema: AnonCredsSchema?
    let schemaId: String
    let resolutionMetadata: AnonCredsResolutionMetadata?
    let schemaMetadata: [String: AnyCodable]
    let issuerId: String?

    enum CodingKeys: String, CodingKey {
        case schema
        case schemaId
        case resolutionMetadata
        case schemaMetadata
        case issuerId
    }

    init(
        schema: AnonCredsSchema? = nil,
        schemaId: String,
        resolutionMetadata: AnonCredsResolutionMetadata? = nil,
        schemaMetadata: [String: AnyCodable] = [:],
        issuerId: String? = nil
    ) {
        self.schema = schema
        self.schemaId = schemaId
        self.resolutionMetadata = resolutionMetadata
        self.schemaMetadata = schemaMetadata
        self.issuerId = issuerId
    }
}
