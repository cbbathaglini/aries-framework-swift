//
//  AnonCredsRevocationRegistryEntry.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 26/09/25.
//

import Foundation

public struct AnonCredsRevocationRegistryEntry: Codable {
    public var tailsFilePath: String
    public var tailsHash: String?
    public var definition: AnonCredsRevocationRegistryDefinition
    public var revocationStatusLists: [UInt64: AnonCredsRevocationStatusList]? // Map<Long, ...> vira [Int64: ...]

    init(
        tailsFilePath: String,
        tailsHash: String? = nil,
        definition: AnonCredsRevocationRegistryDefinition,
        revocationStatusLists: [UInt64: AnonCredsRevocationStatusList]? = nil
    ) {
        self.tailsFilePath = tailsFilePath
        self.tailsHash = tailsHash
        self.definition = definition
        self.revocationStatusLists = revocationStatusLists
    }
}

public typealias AnonCredsRevocationRegistries = [String: AnonCredsRevocationRegistryEntry]
