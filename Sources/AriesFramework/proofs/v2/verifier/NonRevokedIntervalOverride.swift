//
//  NonRevokedIntervalOverride.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

public struct NonRevokedIntervalOverride: Codable, CustomStringConvertible {
    public var revocationRegistryDefinitionId: String
    public var requestedFromTimestamp: UInt64
    public var overrideRevocationStatusListTimestamp: UInt64

    public init(
        revocationRegistryDefinitionId: String,
        requestedFromTimestamp: UInt64,
        overrideRevocationStatusListTimestamp: UInt64
    ) {
        self.revocationRegistryDefinitionId = revocationRegistryDefinitionId
        self.requestedFromTimestamp = requestedFromTimestamp
        self.overrideRevocationStatusListTimestamp = overrideRevocationStatusListTimestamp
    }

    public var description: String {
        return "NonRevokedIntervalOverride(revocationRegistryDefinitionId: \(revocationRegistryDefinitionId), requestedFromTimestamp: \(requestedFromTimestamp), overrideRevocationStatusListTimestamp: \(overrideRevocationStatusListTimestamp))"
    }
}
