//
//  ProofFormatService.swift
//  wallet-app-ios
//
//  Created by Carine Bertagnolli Bathaglini on 02/10/25.
//

import Foundation
import AnyCodable

public protocol ProofFormatService {

    var formatKey: String { get }

    func createProposal(
        profRecord: ProofExchangeRecord,
        attachmentId: String?,
        proofFormats: [String: AnyCodable]
    ) async throws -> ProofFormatCreateReturn

    func processProposal(
        attachment: Attachment,
        proofRecord: ProofExchangeRecord
    ) async throws

    func acceptProposal(
        proofRecord: ProofExchangeRecord,
        attachmentId: String?,
        proposalAttachment: Attachment,
        proofFormats: [String: AnyCodable]
    ) async throws -> ProofFormatCreateReturn

    func createRequest(
        proofRecord: ProofExchangeRecord,
        attachmentId: String?,
        proofFormats: [String: AnyCodable]
    ) async throws -> ProofFormatCreateReturn

    func processRequest(
        options: ProofFormatProcessOptions
    ) async throws

    func acceptRequest(
        requestMessage: RequestPresentationMessageV2,
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable],
        attachmentId: String,
        requestAttachment: Attachment,
        proposalAttachment: Attachment?,
        chosenCredentialId: String?
    ) async throws -> ProofFormatCreateReturn

    func processPresentation(
        requestAttachment: Attachment,
        presentationAttachment: Attachment,
        proofRecord: inout ProofExchangeRecord,
        presentationMessage: PresentationMessageV2,
        requestMessage: RequestPresentationMessageV2,
    ) async throws -> Bool

    func getCredentialsForRequest(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable],
        requestAttachment: Attachment,
        proposalAttachment: Attachment?
    ) async throws -> AnonCredsCredentialsForProofRequest

    func selectCredentialsForRequest(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String: AnyCodable],
        requestAttachment: Attachment,
        proposalAttachment: Attachment?
    ) async throws -> AnonCredsSelectedCredentials

    func shouldAutoRespondToProposal(
        proofRecord: ProofExchangeRecord,
        proposalAttachment: Attachment,
        requestAttachment: Attachment
    ) async throws -> Bool

    func shouldAutoRespondToRequest(
        proofRecord: ProofExchangeRecord,
        requestAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool

    func shouldAutoRespondToPresentation(
        proofRecord: ProofExchangeRecord,
        proposalAttachment: Attachment?,
        requestAttachment: Attachment,
        presentationAttachment: Attachment
    ) async throws -> Bool

    func supportsFormat(formatIdentifier: String) -> Bool
}
