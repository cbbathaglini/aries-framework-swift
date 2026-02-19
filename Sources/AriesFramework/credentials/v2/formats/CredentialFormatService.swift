//
//  CredentialFormatService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/09/25.
//

import Foundation

public protocol CredentialFormatService  {
    //associatedtype CF: CredentialFormat

    var formatKey: String { get }
    var credentialRecordType: String { get }

    // MARK: - Proposal
    func createProposal(
        credentialFormats: [String: Any]?,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws -> CredentialFormatCreateProposalReturn

    func processProposal(
        attachment: Attachment,
        credentialRecord: CredentialExchangeRecord
    ) async throws

    func acceptProposal(
        attachmentId: String?,
        credentialFormats: [String: Any]?,
        credentialRecord: CredentialExchangeRecord,
        proposalAttachments: Attachment
    ) async throws -> CredentialFormatCreateOfferReturn

    // MARK: - Offer
    func createOffer(
        credentialFormats: [String: Any]?,
        credentialExchangeRecord: CredentialExchangeRecord,
        attachmentId: String?
    ) async throws -> CredentialFormatCreateOfferReturn

    func processOffer(
        attachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws

    func acceptOffer(
        attachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord,
        credentialFormats: [Format]?,
        attachmentId: String?,
        offerCredentialMessageV2: OfferCredentialMessageV2
    ) async throws -> CredentialFormatCreateReturn

    func createRequest(
        credentialFormats: [Format]?,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws -> CredentialFormatCreateReturn

    func processRequest(
        attachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord
    ) async throws

    func acceptRequest(
        requestAttachment: Attachment,
        offerAttachment: Attachment?,
        credentialExchangeRecord: CredentialExchangeRecord,
        credentialFormats: [String: Any]?,
        requestAppendAttachments: [Attachment]?,
        attachmentId: String?
    ) async throws -> CredentialFormatCreateReturn

    func processCredential(
        attachment: Attachment,
        offerAttachment: Attachment,
        requestAttachment: Attachment,
        credentialExchangeRecord: CredentialExchangeRecord,
        requestAppendAttachments: [Attachment]?
    ) async throws

    // MARK: - Auto accept
    func shouldAutoRespondToProposal(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool

    func shouldAutoRespondToOffer(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool

    func shouldAutoRespondToRequest(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        requestAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool

    func shouldAutoRespondToCredential(
        credentialRecord: CredentialExchangeRecord,
        offerAttachment: Attachment,
        issueAttachment: Attachment,
        requestAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool

    func deleteCredentialById(credentialId: String) async throws

    func supportsFormat(_ formatIdentifier: String) -> Bool
}
