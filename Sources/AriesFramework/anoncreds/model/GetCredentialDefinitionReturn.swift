//
//  GetCredentialDefinitionReturn.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation
import AnyCodable

public struct GetCredentialDefinitionReturn: Codable {
    public let credentialDefinition: AnonCredsCredentialDefinition?
    public let credentialDefinitionId: String
    public let resolutionMetadata: AnonCredsResolutionMetadata?
    public let credentialDefinitionMetadata: [String: AnyCodable]

    public init(
        credentialDefinition: AnonCredsCredentialDefinition? = nil,
        credentialDefinitionId: String,
        resolutionMetadata: AnonCredsResolutionMetadata? = nil,
        credentialDefinitionMetadata: [String: AnyCodable] = [:]
    ) {
        self.credentialDefinition = credentialDefinition
        self.credentialDefinitionId = credentialDefinitionId
        self.resolutionMetadata = resolutionMetadata
        self.credentialDefinitionMetadata = credentialDefinitionMetadata
    }
}
