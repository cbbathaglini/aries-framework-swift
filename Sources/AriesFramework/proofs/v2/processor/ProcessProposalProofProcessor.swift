//
//  ProcessProposalProofProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation

/// Handles the processing of proof proposals (ProposePresentationMessageV2).
final class ProcessProposalProofProcessor {

    // MARK: - Dependencies
    private let agent: Agent
    private let proofRepository: ProofRepository
    private let didCommMessageRepository: DidCommMessageRepository
    private let proofFormatCoordinator: ProofFormatCoordinator
    private let common: CommonFunctions

    init(
        agent: Agent,
        proofRepository: ProofRepository,
        didCommMessageRepository: DidCommMessageRepository,
        proofFormatCoordinator: ProofFormatCoordinator,
        common: CommonFunctions
    ) {
        self.agent = agent
        self.proofRepository = proofRepository
        self.didCommMessageRepository = didCommMessageRepository
        self.proofFormatCoordinator = proofFormatCoordinator
        self.common = common
    }

    func process(messageContext: InboundMessageContext) async throws -> ProofExchangeRecord {
        logDebug("[init] Processing proof proposal in ProcessProposalProofProcessor")

        let proposalMessage = try decodeProposalMessage(from: messageContext)
        let connection = try messageContext.assertReadyConnection()
        logDebug("Processing presentation proposal with id \(proposalMessage.id)")

        let formatServices = try resolveFormatServices(from: proposalMessage)
        
        if var existingRecord = try await findExistingRecord(for: proposalMessage, connection: connection) {
            logDebug("Existing proof record found for thread \(proposalMessage.threadId)")
            try await handleExistingRecord(
                &existingRecord,
                with: proposalMessage,
                messageContext: messageContext,
                formatServices: formatServices
            )
            return existingRecord
        }

        let newRecord = try await handleNewRecord(
            proposalMessage: proposalMessage,
            connection: connection,
            formatServices: formatServices
        )

        logDebug("[end] Processed new proof proposal successfully — ID: \(newRecord.id)")
        return newRecord
    }
}

private extension ProcessProposalProofProcessor {

    func decodeProposalMessage(from context: InboundMessageContext) throws -> ProposePresentationMessageV2 {
        guard let message = MessageSerializer.decodeFromString(context.plaintextMessage) as? ProposePresentationMessageV2 else {
            throw CredoError("Failed to decode ProposePresentationMessageV2")
        }
        return message
    }

    func resolveFormatServices(from message: ProposePresentationMessageV2) throws -> [any ProofFormatService] {
        let services = common.getFormatServicesFromMessage(message.formats)
        guard !services.isEmpty else {
            throw CredoError("Unable to process proposal. No supported formats found.")
        }
        return services
    }

    func findExistingRecord(for message: ProposePresentationMessageV2, connection: ConnectionRecord) async throws -> ProofExchangeRecord? {
        try await proofRepository.findByThreadRoleAndConnection(
            threadId: message.threadId,
            role: .verifier,
            connectionId: connection.id
        )
    }

    func handleExistingRecord(
        _ record: inout ProofExchangeRecord,
        with message: ProposePresentationMessageV2,
        messageContext: InboundMessageContext,
        formatServices: [any ProofFormatService]
    ) async throws {
        let lastReceivedMessage: ProposePresentationMessageV2 = try await didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: ProposePresentationMessageV2.type,
            role: .Receiver
        ) ?? { throw CredoError("Last received proposal message not found") }()

        let lastSentMessage: RequestPresentationMessageV2 = try await didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: RequestPresentationMessageV2.type,
            role: .Sender
        ) ?? { throw CredoError("Last sent request message not found") }()

        try record.assertProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        try record.assertState(.RequestSent)

        // (Optional) Validate connection or OOB exchange
        /*
        try await agent.connectionService.assertConnectionOrOutOfBandExchange(
            messageContext: messageContext,
            lastReceivedMessage: lastReceivedMessage,
            lastSentMessage: lastSentMessage,
            expectedConnectionId: record.connectionId
        )
        */

        try await proofFormatCoordinator.processProposal(
            proofRecord: record,
            message: message,
            formatServices: formatServices
        )

        try await common.updateState(proofRecord: &record, newState: .ProposalReceived)
        logDebug("Updated existing proof record \(record.id) to state ProposalReceived")
    }

    func handleNewRecord(
        proposalMessage: ProposePresentationMessageV2,
        connection: ConnectionRecord,
        formatServices: [any ProofFormatService]
    ) async throws -> ProofExchangeRecord {
        var newRecord = ProofExchangeRecord(
            connectionId: connection.id,
            threadId: proposalMessage.threadId,
            parentThreadId: proposalMessage.thread?.parentThreadId,
            state: .ProposalReceived,
            role: .verifier,
            protocolVersion: ProofConstants.PROTOCOL_VERSION_V2
        )

        try await proofFormatCoordinator.processProposal(
            proofRecord: newRecord,
            message: proposalMessage,
            formatServices: formatServices
        )

        try await proofRepository.save(newRecord)
        agent.agentDelegate?.onProofStateChangedV2(proofRecord: newRecord)

        logDebug("Created and saved new proof record \(newRecord.id)")
        return newRecord
    }
}
