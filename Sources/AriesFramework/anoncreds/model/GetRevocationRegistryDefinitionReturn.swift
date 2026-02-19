//
//  GetRevocationRegistryDefinitionReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable

public struct GetRevocationRegistryDefinitionReturn: Codable {
    public let revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition?
    public let revocationRegistryDefinitionId: String
    public let resolutionMetadata: AnonCredsResolutionMetadata?
    public let revocationRegistryDefinitionMetadata: [String: AnyCodable]

    public init(
        revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition? = nil,
        revocationRegistryDefinitionId: String,
        resolutionMetadata: AnonCredsResolutionMetadata? = nil,
        revocationRegistryDefinitionMetadata: [String: AnyCodable] = [:]
    ) {
        self.revocationRegistryDefinition = revocationRegistryDefinition
        self.revocationRegistryDefinitionId = revocationRegistryDefinitionId
        self.resolutionMetadata = resolutionMetadata
        self.revocationRegistryDefinitionMetadata = revocationRegistryDefinitionMetadata
    }
}
