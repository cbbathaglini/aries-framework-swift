//
//  ProofRequestProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation

final class ProofRequestProcessor {
    private let agent: Agent
    private let proofFormatCoordinator: ProofFormatCoordinatorProtocol
    private let proofRepository: ProofRepository
    private let historyService: HistoryServiceProtocol
    private let common: CommonFunctions

    init(
        agent: Agent,
        proofFormatCoordinator: ProofFormatCoordinatorProtocol,
        proofRepository: ProofRepository,
        historyService: HistoryServiceProtocol,
        common: CommonFunctions
    ) {
        self.agent = agent
        self.proofFormatCoordinator = proofFormatCoordinator
        self.proofRepository = proofRepository
        self.historyService = historyService
        self.common = common
    }

    func process(messageContext: InboundMessageContext?, requestMessage: RequestPresentationMessageV2?) async throws -> ProofExchangeRecord {
        logDebug("[init] Processing request in ProofRequestProcessor")

        var requestMessage = requestMessage
        var connection : ConnectionRecord? = nil
        if(messageContext != nil){
            requestMessage = try decodeRequest(from: messageContext!)
            logDebug("Processing proof request with id \(requestMessage!.id)")
            connection = messageContext!.connection
        }

        
        let formatServices = common.getFormatServicesFromMessage(requestMessage!.formats)

        guard !formatServices.isEmpty else {
            throw CredoError("Unable to process request. No supported formats")
        }

        if var existingRecord = try await findExistingRecord(for: requestMessage!, connection: connection) {
            return try await handleExistingRecord(
                &existingRecord,
                with: requestMessage!,
                formatServices: formatServices
            )
        } else {
            return try await handleNewRecord(
                with: requestMessage!,
                connection: connection,
                formatServices: formatServices
            )
        }
    }
    
    private func decodeRequest(from context: InboundMessageContext) throws -> RequestPresentationMessageV2 {
        guard let message = MessageSerializer.decodeFromString(context.plaintextMessage) as? RequestPresentationMessageV2 else {
            throw CredoError("Unable to decode request message")
        }
        return message
    }

    private func findExistingRecord(for message: RequestPresentationMessageV2, connection: ConnectionRecord?) async throws -> ProofExchangeRecord? {
        try await proofRepository.getByThreadAndConnectionIdAndRole(
            threadId: message.threadId,
            connectionId: connection?.id,
            role: ProofRole.prover.rawValue
        )
    }

    private func handleExistingRecord(
        _ record: inout ProofExchangeRecord,
        with message: RequestPresentationMessageV2,
        formatServices: [ProofFormatService]
    ) async throws -> ProofExchangeRecord {
        logDebug("Existing proof record found for \(message.id)")

        try record.assertProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        try record.assertState(ProofState.ProposalSent)

        try await proofFormatCoordinator.processRequest(
            proofRecord: record,
            message: message,
            formatServices: formatServices
        )
        
        record.comment = message.comment
        try await proofRepository.save(record)
        try await common.updateState(proofRecord: &record, newState: .RequestReceived)

        logDebug("[end] Updated existing proof record")
        return record
    }

    private func handleNewRecord(
        with message: RequestPresentationMessageV2,
        connection: ConnectionRecord?,
        formatServices: [ProofFormatService]
    ) async throws -> ProofExchangeRecord {
        logDebug("No proof record found. Creating new one")

        
        var newRecord = ProofExchangeRecord(
            connectionId: connection?.id ?? "connectionless",
            threadId: message.threadId,
            parentThreadId: message.thread?.parentThreadId,
            state: .RequestReceived,
            role: .prover,
            protocolVersion: ProofConstants.PROTOCOL_VERSION_V2,
            comment: message.comment
        )

        try await proofFormatCoordinator.processRequest(
            proofRecord: newRecord,
            message: message,
            formatServices: formatServices
        )

        try await proofRepository.save(newRecord)
        
        try await historyService.save(
            historyType: .proofRequestReceived,
            connection: connection,
            associatedRecordId: newRecord.id,
            content: try message.toJsonString(),
            proofRequestedCredentialsAnoncreds: nil,
            credentials: nil,
            credentialPreviewAttr: nil,
            proofRequestedCredentials: nil
        )

        agent.agentDelegate?.onProofStateChangedV2(proofRecord: newRecord)

        logDebug("[end] Saved new proof record successfully")
        return newRecord
    }
    
}
