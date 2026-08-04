//
//  AnonCredsAcceptProposalFormat.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

public struct AnonCredsAcceptProposalFormat: Codable {
    public var credentialDefinitionId: String?
    public var revocationRegistryDefinitionId: String?
    public var revocationRegistryIndex: Int?
    public var attributes: [CredentialPreviewAttribute]?
    public var linkedAttachments: [LinkedAttachment]?

    enum CodingKeys: String, CodingKey {
        case credentialDefinitionId = "credentialDefinitionId"
        case revocationRegistryDefinitionId = "revocationRegistryDefinitionId"
        case revocationRegistryIndex = "revocationRegistryIndex"
        case attributes = "attributes"
        case linkedAttachments = "linkedAttachments"
    }
}
