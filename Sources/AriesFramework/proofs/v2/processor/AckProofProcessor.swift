//
//  AckProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation

/// Responsible for processing proof acknowledgment messages — PresentationAckMessageV2.
final class AckProofProcessor {

    private let agent: Agent
    private let proofRepository: ProofRepository
    private let common: CommonFunctions

    init(agent: Agent, proofRepository: ProofRepository, common: CommonFunctions) {
        self.agent = agent
        self.proofRepository = proofRepository
        self.common = common
    }

    /// Processes an acknowledgment message (ACK) and updates the proof record state.
    func process(messageContext: InboundMessageContext) async throws -> ProofExchangeRecord {
        logDebug("[init] Processing proof acknowledgment in AckProcessor")

        let presentationAckMessage : PresentationAckMessageV2 = try decodeAckMessage(from: messageContext)
        logDebug("Processing proof ack with id \(presentationAckMessage.id)")

        guard let connection : ConnectionRecord = messageContext.connection else {
            throw CredoError("Connection not found in message context")
        }

        guard var proofRecord : ProofExchangeRecord = try await proofRepository.findByThreadRoleAndConnection(
            threadId: presentationAckMessage.threadId,
            role: .prover,
            connectionId: connection.id
        ) else {
            throw CredoError("Proof record not found for thread \(presentationAckMessage.threadId)")
        }

        proofRecord.connectionId = connection.id

        try await common.updateState(proofRecord: &proofRecord, newState: .Done)

        logDebug("[end] ACK processed successfully — proof \(proofRecord.id) is now \(proofRecord.state.rawValue)")
        return proofRecord
    }

    /// Decodes a PresentationAckMessageV2 acknowledgment message.
    private func decodeAckMessage(from context: InboundMessageContext) throws -> PresentationAckMessageV2 {
        guard let message = MessageSerializer.decodeFromString(context.plaintextMessage) as? PresentationAckMessageV2 else {
            throw CredoError("Unable to decode PresentationAckMessageV2")
        }
        return message
    }

    /// Validates that the proof record is in a valid state before marking it as complete.
    private func validate(proofRecord: ProofExchangeRecord) throws {
        try proofRecord.assertProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        try proofRecord.assertState(.PresentationSent)
    }
}
