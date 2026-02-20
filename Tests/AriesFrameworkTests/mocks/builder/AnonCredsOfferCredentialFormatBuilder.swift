//
//  AnonCredsOfferCredentialFormatBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework

final class AnonCredsOfferCredentialFormatBuilder {

    // MARK: - Defaults seguros para teste

    private var credentialDefinitionId: String = "creddef:test"
    private var revocationRegistryDefinitionId: String? = nil
    private var revocationRegistryIndex: Int? = nil
    private var attributes: [CredentialPreviewAttribute] = []
    private var linkedAttachments: [LinkedAttachment]? = []

    // MARK: - Fluent API

    func withCredentialDefinitionId(_ id: String) -> Self {
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
        mimeType: String? = nil
    ) -> Self {
        let attribute = CredentialPreviewAttribute(
            name: name,
            mimeType: mimeType ?? "application/json",
            value: value
        )
        self.attributes.append(attribute)
        return self
    }

    func withAttributes(_ attributes: [CredentialPreviewAttribute]) -> Self {
        self.attributes.append(contentsOf: attributes)
        return self
    }

    func withLinkedAttachments(_ attachments: [LinkedAttachment]?) -> Self {
        self.linkedAttachments = attachments
        return self
    }

    // MARK: - Build

    func build() -> AnonCredsOfferCredentialFormat {
        AnonCredsOfferCredentialFormat(
            credentialDefinitionId: credentialDefinitionId,
            revocationRegistryDefinitionId: revocationRegistryDefinitionId,
            revocationRegistryIndex: revocationRegistryIndex,
            attributes: attributes,
            linkedAttachments: linkedAttachments
        )
    }
}
