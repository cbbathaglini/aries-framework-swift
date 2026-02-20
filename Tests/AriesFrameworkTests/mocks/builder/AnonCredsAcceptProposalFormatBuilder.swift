//
//  AnonCredsAcceptProposalFormatBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework

final class AnonCredsAcceptProposalFormatBuilder {

    private var credentialDefinitionId: String? = "creddef:test"
    private var revocationRegistryDefinitionId: String? = nil
    private var revocationRegistryIndex: Int? = nil
    private var attributes: [CredentialPreviewAttribute]? = []
    private var linkedAttachments: [LinkedAttachment]? = []

    // MARK: - Fluent setters

    func withCredentialDefinitionId(_ id: String?) -> Self {
        self.credentialDefinitionId = id
        return self
    }

    func withRevocationRegistryDefinitionId(_ id: String?) -> Self {
        self.revocationRegistryDefinitionId = id
        return self
    }

    func withRevocationRegistryIndex(_ index: Int?) -> Self {
        self.revocationRegistryIndex = index
        return self
    }

    func withAttribute(
        name: String,
        value: String,
        mimeType: String? = "text/plain"
    ) -> Self {
        let attribute = CredentialPreviewAttribute(
            name: name,
            mimeType: mimeType ?? "application/json",
            value: value
        )

        if attributes == nil {
            attributes = []
        }
        attributes?.append(attribute)
        return self
    }

    func withAttributes(_ attributes: [CredentialPreviewAttribute]?) -> Self {
        self.attributes = attributes
        return self
    }

    func withLinkedAttachment(_ attachment: LinkedAttachment) -> Self {
        if linkedAttachments == nil {
            linkedAttachments = []
        }
        linkedAttachments?.append(attachment)
        return self
    }

    func withLinkedAttachments(_ attachments: [LinkedAttachment]?) -> Self {
        self.linkedAttachments = attachments
        return self
    }

    // MARK: - Build

    func build() -> AnonCredsAcceptProposalFormat {
        AnonCredsAcceptProposalFormat(
            credentialDefinitionId: credentialDefinitionId,
            revocationRegistryDefinitionId: revocationRegistryDefinitionId,
            revocationRegistryIndex: revocationRegistryIndex,
            attributes: attributes,
            linkedAttachments: linkedAttachments
        )
    }
}
