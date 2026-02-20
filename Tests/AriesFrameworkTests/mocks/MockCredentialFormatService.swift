//
//  MockCredentialFormatService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 02/01/26.
//

@testable import AriesFramework

final class MockCredentialFormatService: CredentialFormatService {

    // MARK: - Identidade do formato

    let formatKey: String
    let credentialRecordType: String

    init(
        formatKey: String = "anoncreds",
        credentialRecordType: String = "anoncreds"
    ) {
        self.formatKey = formatKey
        self.credentialRecordType = credentialRecordType
    }

    // MARK: - Spies (chamadas)

    private(set) var createProposalCalled = false
    private(set) var processProposalCalled = false
    private(set) var acceptProposalCalled = false
    private(set) var createOfferCalled = false
    private(set) var processOfferCalled = false
    private(set) var acceptOfferCalled = false
    private(set) var createRequestCalled = false
    private(set) var processRequestCalled = false
    private(set) var acceptRequestCalled = false
    private(set) var processCredentialCalled = false

    // MARK: - Controle de auto-accept

    var autoRespondProposalResult = true
    var autoRespondOfferResult = true
    var autoRespondRequestResult = true
    var autoRespondCredentialResult = true

    // MARK: - Helpers

    private func makeFormat(attachId: String) -> Format {
        Format(
            attachId: attachId,
            format: "anoncreds/credential@v1.0"
        )
    }

    private func makeAttachment(id: String) -> Attachment {
        AttachmentTestFactory.json(
            id: id,
            jsonObject: [:]
        )
    }

    // MARK: - Proposal

    func createProposal(
        credentialFormats: [String : Any]?,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws -> CredentialFormatCreateProposalReturn {

        createProposalCalled = true

        let attachId = formatKey

        return CredentialFormatCreateProposalReturn(
            format: makeFormat(attachId: attachId),
            attachment: makeAttachment(id: attachId),
            appendAttachment: nil,
            previewAttribute: nil
        )
    }

    func processProposal(
        attachment: Attachment,
        credentialRecord: CredentialExchangeRecord
    ) async throws {
        processProposalCalled = true
    }

    func acceptProposal(
        attachmentId: String?,
        credentialFormats: [String : Any]?,
        credentialRecord: CredentialExchangeRecord,
        proposalAttachments: Attachment
    ) async throws -> CredentialFormatCreateOfferReturn {

        acceptProposalCalled = true

        let attachId = attachmentId ?? formatKey

        return CredentialFormatCreateOfferReturn(
            attachment: makeAttachment(id: attachId),
            format: makeFormat(attachId: attachId),
            previewAttributes: []
        )
    }

    // MARK: - Offer

    func createOffer(
        credentialFormats: [String : Any]?,
        credentialExchangeRecord: CredentialExchangeRecord,
        attachmentId: String?
    ) async throws -> CredentialFormatCreateOfferReturn {

        createOfferCalled = true

        let attachId = attachmentId ?? formatKey

        return CredentialFormatCreateOfferReturn(
            attachment: makeAttachment(id: attachId),
            format: makeFormat(attachId: attachId),
            previewAttributes: []
        )
        
    }

    func processOffer(
        attachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws {
        processOfferCalled = true
    }

    func acceptOffer(
        attachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord,
        credentialFormats: [Format]?,
        attachmentId: String?,
        offerCredentialMessageV2: OfferCredentialMessageV2
    ) async throws -> CredentialFormatCreateReturn {

        acceptOfferCalled = true

        let attachId = attachmentId ?? formatKey

        return CredentialFormatCreateReturn(
            attachment: makeAttachment(id: attachId),
            format: makeFormat(attachId: attachId),
            appendAttachment: []
        )
    }

    // MARK: - Request

    func createRequest(
        credentialFormats: [Format]?,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws -> CredentialFormatCreateReturn {

        createRequestCalled = true

        let attachId = formatKey

        return CredentialFormatCreateReturn(
            attachment: makeAttachment(id: attachId),
            format: makeFormat(attachId: attachId),
            appendAttachment: []
        )
    }

    func processRequest(
        attachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws {
        processRequestCalled = true
    }

    func acceptRequest(
        requestAttachment: Attachment,
        offerAttachment: Attachment?,
        credentialExchangeRecord: CredentialExchangeRecord,
        credentialFormats: [String : Any]?,
        requestAppendAttachments: [Attachment]?,
        attachmentId: String?
    ) async throws -> CredentialFormatCreateReturn {

        acceptRequestCalled = true

        let attachId = attachmentId ?? formatKey

        return CredentialFormatCreateReturn(
            attachment: makeAttachment(id: attachId),
            format: makeFormat(attachId: attachId),
            appendAttachment: []
        )
    }

    // MARK: - Credential

    func processCredential(
        attachment: Attachment,
        offerAttachment: Attachment,
        requestAttachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord,
        requestAppendAttachments: [Attachment]?
    ) async throws {
        processCredentialCalled = true
    }

    // MARK: - Auto Accept

    func shouldAutoRespondToProposal(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        autoRespondProposalResult
    }

    func shouldAutoRespondToOffer(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        autoRespondOfferResult
    }

    func shouldAutoRespondToRequest(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        requestAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        autoRespondRequestResult
    }

    func shouldAutoRespondToCredential(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        issueAttachment: Attachment,
        requestAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        autoRespondCredentialResult
    }

    // MARK: - Outros

    func deleteCredentialById(credentialId: String) async throws {
        // no-op
    }

    func supportsFormat(_ formatIdentifier: String) -> Bool {
        formatIdentifier.contains(formatKey)
    }
}
