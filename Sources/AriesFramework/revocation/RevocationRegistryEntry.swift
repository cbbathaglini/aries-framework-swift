//
//  RevocationRegistryEntry.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

import Foundation

public struct RevocationRegistryEntry: Codable, CustomStringConvertible {
    let definition: AnonCredsRevocationRegistryDefinition
    var revocationStatusLists: [UInt64: AnonCredsRevocationStatusList]?

    init(
        definition: AnonCredsRevocationRegistryDefinition,
        revocationStatusLists: [UInt64: AnonCredsRevocationStatusList]? = [:]
    ) {
        self.definition = definition
        self.revocationStatusLists = revocationStatusLists
    }

    public var description: String {
        return "RevocationRegistryEntry(definition: \(definition), revocationStatusLists: \(String(describing: revocationStatusLists)))"
    }
}
