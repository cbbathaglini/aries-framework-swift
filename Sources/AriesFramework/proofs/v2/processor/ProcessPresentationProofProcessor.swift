//
//  ProcessPresentationProofProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation

/// Handles the processing of incoming proof presentations (PresentationMessageV2).
final class ProcessPresentationProofProcessor {

    // MARK: - Dependencies
    private let agent: Agent
    private let proofRepository: ProofRepository
    private let proofFormatCoordinator: ProofFormatCoordinator
    private let common: CommonFunctions


    // MARK: - Initializer
    init(
        agent: Agent,
        proofRepository: ProofRepository,
        proofFormatCoordinator: ProofFormatCoordinator,
        common: CommonFunctions
    ) {
        self.agent = agent
        self.proofRepository = proofRepository
        self.proofFormatCoordinator = proofFormatCoordinator
        self.common = common
    }
    
    func processOffline(message: PresentationMessageV2) async throws -> ProofExchangeRecord? {
        logDebug("[init] Processing presentation in ProcessPresentationProofProcessor")
        
        
        let presentationMessage = message
        let formatServices = try resolveFormatServices(from: presentationMessage)
        
        var proofRecord = ProofExchangeRecord(
            connectionId: "connectionless-proof-presentation",
            threadId: RecordUtils.generateId(),
            state: .ProposalReceived,
            role: .verifier,
            protocolVersion: ProofConstants.PROTOCOL_VERSION_V2
        )
        
        let threadId = presentationMessage.threadId
        
        var verifierRecord : VerifierRecord = try await agent.verifierRepository.getByGlobalThreadId(
            globalThreadId: threadId)
        
        let lastSentMessage : RequestPresentationMessageV2 = verifierRecord.requestMessage!

        let result : ProcessPresentationReturn = try await proofFormatCoordinator.processPresentation(
            proofRecord: &proofRecord,
            presentationMessage: presentationMessage,
            requestMessage: lastSentMessage,
            formatServices: formatServices
        )

            
        let presentationVerifier = PresentationVerifier(
            presentationMessage: message,
            isVerified: proofRecord.isVerified,
            isOffline: true,
            proofRecordId: proofRecord.id
        )
        
        await verifierRecord.addPresentation(presentationVerifier, agent: agent)
        try await agent.verifierRepository.update(verifierRecord)
        verifierRecord.printDetails()
        
        logDebug("[end] Finished processing presentation for proof \(proofRecord.id)")
        
        try await agent.proofRepository.save(proofRecord)
        return proofRecord
    }

   
    func process(messageContext: InboundMessageContext) async throws -> ProofExchangeRecord {
        logDebug("[init] Processing presentation in ProcessPresentationProofProcessor")
        
       let presentationMessage = try decodePresentationMessage(from: messageContext)
            logDebug("Processing presentation with id \(presentationMessage.id)")
        

        guard var proofRecord = try await findProofRecord(for: presentationMessage) else {
            throw CredoError("Proof record not found for thread \(presentationMessage.threadId)")
        }

        let lastSentMessage = try await fetchLastSentRequest(for: proofRecord)
        _ = try await fetchLastReceivedProposal(for: proofRecord)

        try validate(proofRecord: proofRecord)
        
        let formatServices = try resolveFormatServices(from: presentationMessage)
        
        try await validateConnection(for: proofRecord, context: messageContext)
        proofRecord.connectionId = messageContext.connection?.id ?? proofRecord.connectionId
        

        let result : ProcessPresentationReturn = try await proofFormatCoordinator.processPresentation(
            proofRecord: &proofRecord,
            presentationMessage: presentationMessage,
            requestMessage: lastSentMessage,
            formatServices: formatServices
        )

        try await updateProofRecord(&proofRecord, with: result)

        logDebug("[end] Finished processing presentation for proof \(proofRecord.id)")
        return proofRecord
    }
}

// MARK: - Private Helpers
private extension ProcessPresentationProofProcessor {

    func decodePresentationMessage(from context: InboundMessageContext) throws -> PresentationMessageV2 {
        logger.info(" presentation message v2: \(context.plaintextMessage)")
        guard let message = MessageSerializer.decodeFromString(context.plaintextMessage) as? PresentationMessageV2 else {
            throw CredoError("Failed to decode PresentationMessageV2")
        }
        return message
    }

    func findProofRecord(for message: PresentationMessageV2) async throws -> ProofExchangeRecord? {
        try await proofRepository.findByThreadRoleAndConnection(
            threadId: message.threadId,
            role: .verifier
        )
    }

    func fetchLastSentRequest(for record: ProofExchangeRecord) async throws -> RequestPresentationMessageV2 {
        guard let message : RequestPresentationMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: RequestPresentationMessageV2.type,
            role: .Sender
        ) else {
            throw CredoError("Last sent RequestPresentationMessageV2 not found for record \(record.id)")
        }
        return message
    }

    func fetchLastReceivedProposal(for record: ProofExchangeRecord) async throws -> ProposePresentationMessageV2? {
        try await agent.didCommMessageRepository.getTypedAgentMessage(
            associatedRecordId: record.id,
            messageType: ProposePresentationMessageV2.type,
            role: .Receiver
        )
    }

    func validate(proofRecord: ProofExchangeRecord) throws {
        try proofRecord.assertProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        try proofRecord.assertState(.RequestSent)
    }

    func validateConnection(for proofRecord: ProofExchangeRecord, context: InboundMessageContext) async throws {
        try await agent.connectionService.matchIncomingMessageToRequestMessageInOutOfBandExchange(
            messageContext: context,
            expectedConnectionId: proofRecord.connectionId
        )
    }

    func resolveFormatServices(from presentationMessage: PresentationMessageV2) throws -> [any ProofFormatService] {
        let services = common.getFormatServicesFromMessage(presentationMessage.formats)
        guard !services.isEmpty else {
            throw PresentationProblemReportErrorV2(
                message: "Unable to process presentation. No supported formats.",
                problemCode: "abandoned",
                threadId: presentationMessage.threadId
            )
        }
        return services
    }

    func updateProofRecord(_ proofRecord: inout ProofExchangeRecord, with result: ProcessPresentationReturn) async throws {
        print("🔍 DIAG updateProofRecord isValid=\(result.isValid) proofRecord.isVerified=\(String(describing: proofRecord.isVerified))")
        proofRecord.isVerified = result.isValid
        if result.isValid {
            try await common.updateState(proofRecord: &proofRecord, newState: .PresentationReceived)
        } else {
            proofRecord.errorMessage = result.message
            proofRecord.isVerified = false
            try await common.updateState(proofRecord: &proofRecord, newState: .Abandoned)

            throw PresentationProblemReportErrorV2(
                message: proofRecord.errorMessage ?? "Presentation invalid",
                problemCode: "abandoned",
                threadId: proofRecord.threadId
            )
        }
    }
}
