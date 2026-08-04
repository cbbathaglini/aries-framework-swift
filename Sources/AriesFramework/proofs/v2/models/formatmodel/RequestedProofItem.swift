//
//  RequestedProofItem.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 04/10/25.
//

public struct RequestedProofItem: Codable, CustomStringConvertible {
    public var nonRevokedInterval: AnonCredsNonRevokedInterval
    public var schemaId: String?
    public var credentialDefinitionId: String?
    public var revocationRegistryDefinitionId: String?

    public var description: String {
        return """
        RequestedItem(
            nonRevokedInterval: \(nonRevokedInterval),
            schemaId: \(schemaId ?? "nil"),
            credentialDefinitionId: \(credentialDefinitionId ?? "nil"),
            revocationRegistryDefinitionId: \(revocationRegistryDefinitionId ?? "nil")
        )
        """
    }
}
