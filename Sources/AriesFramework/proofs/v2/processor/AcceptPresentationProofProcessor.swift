//
//  AcceptPresentationProofProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation

/// Handles acknowledgment (ACK) of received presentations.
final class AcceptPresentationProofProcessor {

    // MARK: - Dependencies
    private let agent: Agent
    private let common: CommonFunctions

    init(agent: Agent, common: CommonFunctions) {
        self.agent = agent
        self.common = common
    }

    // MARK: - Public API
    /// Accepts a received proof presentation and creates an acknowledgment (ACK) message.
    ///
    /// - Parameter proofRecord: The proof exchange record to acknowledge.
    /// - Returns: A tuple containing the ACK message and the updated proof record.
    func acceptPresentation(proofRecord: inout ProofExchangeRecord) async throws -> (PresentationAckMessageV2, ProofExchangeRecord) {
        logDebug("[init] Accepting presentation for proof \(proofRecord.id)")

        try validate(proofRecord: proofRecord)
        let presentation: PresentationMessageV2 = try await fetchPresentation(for: proofRecord)

        try validateLastPresentation(presentation)
        let ackMessage = buildAckMessage(for: proofRecord)

        try await common.updateState(proofRecord: &proofRecord, newState: .Done)

        logDebug("[end] Presentation \(presentation.id) accepted — proof \(proofRecord.id) is now Done")
        return (ackMessage, proofRecord)
    }

    /// Ensures the proof record is in a valid state to send an acknowledgment.
    private func validate(proofRecord: ProofExchangeRecord) throws {
        try proofRecord.assertProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        try proofRecord.assertState(.PresentationReceived)
    }

    /// Retrieves the last PresentationMessageV2 related to the proof record.
    private func fetchPresentation(for proofRecord: ProofExchangeRecord) async throws -> PresentationMessageV2 {
        guard let presentation: PresentationMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: proofRecord.id,
            messageType: PresentationMessageV2.type,
            role: .Sender
        ) else {
            throw CredoError("Presentation message not found for record \(proofRecord.id)")
        }
        return presentation
    }

    /// Ensures the presentation being acknowledged is marked as the last one.
    private func validateLastPresentation(_ presentation: PresentationMessageV2) throws {
        guard presentation.lastPresentation == true else {
            throw CredoError(
                "Trying to send an ack message while presentation with id \(presentation.id) " +
                "indicates this is not the last presentation (presentation.last_presentation == false)"
            )
        }
    }

    /// Builds the PresentationAckMessageV2 based on the proof record.
    private func buildAckMessage(for proofRecord: ProofExchangeRecord) -> PresentationAckMessageV2 {
        var message = PresentationAckMessageV2(
            threadId: proofRecord.threadId,
            status: AckStatus.OK
        )
        message.setThread(
            threadId: proofRecord.threadId,
            parentThreadId: proofRecord.parentThreadId
        )
        return message
    }
}
