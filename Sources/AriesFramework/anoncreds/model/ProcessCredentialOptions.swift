//
//  ProcessCredentialOptions.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//
import Foundation

public struct ProcessCredentialOptions: Codable {
    public let credentialRequestMetadata: AnonCredsCredentialRequestMetadata
    public let linkSecret: String
    public let revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition?
    public let credentialDefinition: AnonCredsCredentialDefinition

    public init(
        credentialRequestMetadata: AnonCredsCredentialRequestMetadata,
        linkSecret: String,
        revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition? = nil,
        credentialDefinition: AnonCredsCredentialDefinition
    ) {
        self.credentialRequestMetadata = credentialRequestMetadata
        self.linkSecret = linkSecret
        self.revocationRegistryDefinition = revocationRegistryDefinition
        self.credentialDefinition = credentialDefinition
    }
}
