//
//  ProcessOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct ProcessOptions: Codable {
    public let credentialDefinition: AnonCredsCredentialDefinition
    public let credentialRequestMetadata: AnonCredsCredentialRequestMetadata
    public let revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition?

    public init(
        credentialDefinition: AnonCredsCredentialDefinition,
        credentialRequestMetadata: AnonCredsCredentialRequestMetadata,
        revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition? = nil
    ) {
        self.credentialDefinition = credentialDefinition
        self.credentialRequestMetadata = credentialRequestMetadata
        self.revocationRegistryDefinition = revocationRegistryDefinition
    }
}
