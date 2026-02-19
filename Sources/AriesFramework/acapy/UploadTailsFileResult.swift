//
//  UploadTailsFileResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

public struct UploadTailsFileResult: Codable {
    public let revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition
    public let revocationRegistryDefinitionId: String?

    public init(
        revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition,
        revocationRegistryDefinitionId: String?
    ) {
        self.revocationRegistryDefinition = revocationRegistryDefinition
        self.revocationRegistryDefinitionId = revocationRegistryDefinitionId
    }
}
