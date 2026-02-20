//
//  AnoncredsCredentialFormatBuilder.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework

final class AnoncredsCredentialFormatBuilder {

    private var credentialDefinitionId: String = "creddef:test"
    private var attributes: [CredentialPreviewAttribute] = []
    private var linkedAttachments: [LinkedAttachment]? = []
    private var linkSecretId: String = "default-link-secret"

    // MARK: - Fluent API

    func withCredentialDefinitionId(_ id: String) -> Self {
        self.credentialDefinitionId = id
        return self
    }

    func withAttribute(_ attribute: CredentialPreviewAttribute) -> Self {
        attributes.append(attribute)
        return self
    }


    func withAttribute(
        name: String,
        value: String,
        mimeType: String? = nil
    ) -> Self {
        attributes.append(
            CredentialPreviewAttribute(
                name: name,
                mimeType: mimeType ?? "application/json",
                value: value
            )
        )
        return self
    }

    func withLinkSecretId(_ id: String) -> Self {
        self.linkSecretId = id
        return self
    }

    // MARK: - Build

    func build() -> AnoncredsCredentialFormat {
        AnoncredsCredentialFormat(
            credentialFormats: makeCredentialFormatsStub(),
            formatData: makeFormatDataStub(),
            credentialDefinitionId: credentialDefinitionId,
            attributes: attributes,
            linkedAttachments: linkedAttachments,
            linkSecretId: linkSecretId
        )
    }

    // MARK: - Stubs (TEST ONLY)

//    private func makeCredentialFormatsStub() -> CredentialFormatAnonCreds {
//        try! CredentialFormatAnonCreds(
//            createProposal: AnonCredsProposeCredentialFormat(),
//            acceptProposal: AnonCredsAcceptProposalFormat(),
//            createOffer: AnonCredsOfferCredentialFormat(),
//            acceptOffer: AnonCredsAcceptOfferFormat(),
//            acceptRequest: AnonCredsAcceptRequestFormat()
//        )
//    }
    
    private func makeCredentialFormatsStub() -> CredentialFormatAnonCreds {
        try! CredentialFormatAnonCreds(
            createProposal: AnonCredsProposeCredentialFormatBuilder().build(),
            acceptProposal: AnonCredsAcceptProposalFormatBuilder().build(),
            createOffer: AnonCredsOfferCredentialFormatBuilder()
                .withCredentialDefinitionId("creddef:test")
                .withAttribute(name: "name", value: "Alice")
                .build(),
            acceptOffer: AnonCredsAcceptOfferFormatBuilder().build(),
            acceptRequest: AnonCredsAcceptRequestFormatBuilder().build()
        )
    }

    private func makeFormatDataStub() -> FormatDataAnonCreds {

        let proposal = AnonCredsCredentialProposalFormatBuilder()
            .withCredentialDefinitionId(credentialDefinitionId)
            .minimal()
            .build()

        let offer = AnonCredsCredentialOfferBuilder()
            .withSchemaId("schema:test")
            .withCredentialDefinitionId(credentialDefinitionId)
            .build()

        let request = AnonCredsCredentialRequestBuilder()
            .withCredentialDefinitionId(credentialDefinitionId)
            .build()

        let credential = AnonCredsCredentialBuilder()
            .withSchemaId("schema:test")
            .withCredentialDefinitionId(credentialDefinitionId)
            .build()

        return FormatDataAnonCreds(
            proposal: proposal,
            offer: offer,
            request: request,
            credential: credential
        )
    }
}
