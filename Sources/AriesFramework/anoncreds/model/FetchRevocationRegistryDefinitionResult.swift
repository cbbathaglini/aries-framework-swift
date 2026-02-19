//
//  FetchRevocationRegistryDefinitionResult.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 30/09/25.
//

import Foundation

struct FetchRevocationRegistryDefinitionResult: Codable {
    let revocationRegistryDefinition: AnonCredsRevocationRegistryDefinition?
    let revocationRegistryDefinitionId: String
    let indyNamespace: String?
}
