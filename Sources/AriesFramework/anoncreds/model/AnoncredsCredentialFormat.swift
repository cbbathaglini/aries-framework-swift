//
//  AnoncredsCredentialFormat.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 25/09/25.
//

public class AnoncredsCredentialFormat: Codable ,CredentialFormat{
    public var formatKey: String
    public var credentialRecordType: String
    public var credentialFormats: CredentialFormatOperations
    public var formatData: FormatData

    public var credentialDefinitionId: String
    public var revocationRegistryDefinitionId: String?
    public var revocationRegistryIndex: Int64?
    public var attributes: [CredentialPreviewAttribute]
    public var linkedAttachments: [LinkedAttachment]?
    public var linkSecretId: String

    public init(
        formatKey: String = "anoncreds",
        credentialRecordType: String = "w3c",
        credentialFormats: CredentialFormatAnonCreds,
        formatData: FormatDataAnonCreds,
        credentialDefinitionId: String,
        revocationRegistryDefinitionId: String? = nil,
        revocationRegistryIndex: Int64? = nil,
        attributes: [CredentialPreviewAttribute],
        linkedAttachments: [LinkedAttachment]? = [],
        linkSecretId: String
    ) {
        self.formatKey = formatKey
        self.credentialRecordType = credentialRecordType
        self.credentialFormats = credentialFormats
        self.formatData = formatData
        self.credentialDefinitionId = credentialDefinitionId
        self.revocationRegistryDefinitionId = revocationRegistryDefinitionId
        self.revocationRegistryIndex = revocationRegistryIndex
        self.attributes = attributes
        self.linkedAttachments = linkedAttachments
        self.linkSecretId = linkSecretId
    }
}
