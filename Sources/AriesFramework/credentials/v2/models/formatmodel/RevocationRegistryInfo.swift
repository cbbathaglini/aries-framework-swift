//
//  RevocationRegistryInfo.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

public struct RevocationRegistryInfo: Codable {
    let id: String
    let definition: AnonCredsRevocationRegistryDefinition
}
