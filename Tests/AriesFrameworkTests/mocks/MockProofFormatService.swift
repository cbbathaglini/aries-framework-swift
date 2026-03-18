//
//  MockProofFormatService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

@testable import AriesFramework
import Foundation
import AnyCodable

final class MockProofFormatService: ProofFormatService {

    let formatKey: String
    private let supportedFormats: [String]

    init(formatKey: String, supportedFormats: [String]) {
        self.formatKey = formatKey
        self.supportedFormats = supportedFormats
    }

    // MARK: - Helpers

    func supportsFormat(formatIdentifier: String) -> Bool {
        supportedFormats.contains(formatIdentifier)
    }

    // MARK: - Not needed for current tests

    func createProposal(
        profRecord: ProofExchangeRecord,
        attachmentId: String?,
        proofFormats: [String : AnyCodable]
    ) async throws -> ProofFormatCreateReturn {
        fatalError("Not needed in this test")
    }

    func processProposal(
        attachment: Attachment,
        proofRecord: ProofExchangeRecord
    ) async throws {
        fatalError("Not needed in this test")
    }

    func acceptProposal(
        proofRecord: ProofExchangeRecord,
        attachmentId: String?,
        proposalAttachment: Attachment,
        proofFormats: [String : AnyCodable]
    ) async throws -> ProofFormatCreateReturn {
        fatalError("Not needed in this test")
    }

    func createRequest(
        proofRecord: ProofExchangeRecord,
        attachmentId: String?,
        proofFormats: [String : AnyCodable]
    ) async throws -> ProofFormatCreateReturn {
        fatalError("Not needed in this test")
    }

    func processRequest(
        options: ProofFormatProcessOptions
    ) async throws {
        fatalError("Not needed in this test")
    }

    func acceptRequest(
        requestMessage: RequestPresentationMessageV2,
        proofRecord: ProofExchangeRecord,
        proofFormats: [String : AnyCodable],
        attachmentId: String,
        requestAttachment: Attachment,
        proposalAttachment: Attachment?,
        chosenCredentialId: String?
    ) async throws -> ProofFormatCreateReturn {
        fatalError("Not needed in this test")
    }

    func processPresentation(
        requestAttachment: Attachment,
        presentationAttachment: Attachment,
        proofRecord: inout ProofExchangeRecord,
        presentationMessage: PresentationMessageV2,
        requestMessage: RequestPresentationMessageV2
    ) async throws -> Bool {
        fatalError("Not needed in this test")
    }

    func getCredentialsForRequest(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String : AnyCodable],
        requestAttachment: Attachment,
        proposalAttachment: Attachment?
    ) async throws -> AnonCredsCredentialsForProofRequest {
        fatalError("Not needed in this test")
    }

    func selectCredentialsForRequest(
        proofRecord: ProofExchangeRecord,
        proofFormats: [String : AnyCodable],
        requestAttachment: Attachment,
        proposalAttachment: Attachment?
    ) async throws -> AnonCredsSelectedCredentials {
        fatalError("Not needed in this test")
    }

    func shouldAutoRespondToProposal(
        proofRecord: ProofExchangeRecord,
        proposalAttachment: Attachment,
        requestAttachment: Attachment
    ) async throws -> Bool {
        fatalError("Not needed in this test")
    }

    func shouldAutoRespondToRequest(
        proofRecord: ProofExchangeRecord,
        requestAttachment: Attachment,
        proposalAttachment: Attachment
    ) async throws -> Bool {
        fatalError("Not needed in this test")
    }

    func shouldAutoRespondToPresentation(
        proofRecord: ProofExchangeRecord,
        proposalAttachment: Attachment?,
        requestAttachment: Attachment,
        presentationAttachment: Attachment
    ) async throws -> Bool {
        fatalError("Not needed in this test")
    }
}
