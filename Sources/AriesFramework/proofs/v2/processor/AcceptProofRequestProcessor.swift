//
//  AcceptRequestProcessorTwo.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation

final class AcceptProofRequestProcessor {
    private let agent: Agent
    private let proofFormatCoordinator: ProofFormatCoordinator
    private let proofRepository: ProofRepository
    private let historyService: HistoryService
    private let common: CommonFunctions
    
    init(
        agent: Agent,
        proofFormatCoordinator: ProofFormatCoordinator,
        proofRepository: ProofRepository,
        historyService: HistoryService,
        common: CommonFunctions
    ) {
        self.agent = agent
        self.proofFormatCoordinator = proofFormatCoordinator
        self.proofRepository = proofRepository
        self.historyService = historyService
        self.common = common
    }

    func acceptRequest(params: AcceptProofRequestOptions) async throws -> (PresentationMessageV2, ProofExchangeRecord) {
        logDebug("[init] Accepting proof request in AcceptRequestProcessorTwo")

        var proofRecord = params.proofRecord
        try validate(proofRecord: proofRecord)

        let formatServices = try await resolveFormatServices(
            proofRecord: proofRecord,
            inputFormats: params.proofFormats
        )

        let acceptParams = buildAcceptParams(from: params, proofRecord: proofRecord, formatServices: formatServices, chosenCredentialId: params.chosenCredentialId)
        let presentationMessage = try await proofFormatCoordinator.acceptRequest(params: acceptParams)

        proofRecord.chosenCredentialId = params.chosenCredentialId
        proofRecord.autoAcceptProof = params.autoAcceptProof ?? proofRecord.autoAcceptProof
        proofRecord.presentationMessage = presentationMessage
        try await common.updateState(proofRecord: &proofRecord, newState: .PresentationSent)

        logDebug("[end] Proof request accepted successfully in AcceptProofRequestProcessorTwo")
        return (presentationMessage, proofRecord)
    }

    private func validate(proofRecord: ProofExchangeRecord) throws {
        try proofRecord.assertProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        try proofRecord.assertState(ProofState.RequestReceived)
    }

    private func resolveFormatServices(
        proofRecord: ProofExchangeRecord,
        inputFormats: [ProofFormatSpec]?
    ) async throws -> [any ProofFormatService] {
        var services = common.getFormatServicesByList(inputFormats ?? [])

        if services.isEmpty {
            if let requestMessage: RequestPresentationMessageV2 = try await agent.didCommMessageRepository.getTypedAgentMessage(
                associatedRecordId: proofRecord.id,
                messageType: RequestPresentationMessageV2.type,
                role: .Receiver
            ) {
                services = common.getFormatServicesFromMessage(requestMessage.formats)
            }
        }

        guard !services.isEmpty else {
            throw CredoError("Unable to accept request. No supported formats provided as input or in request message")
        }

        return services
    }

    private func buildAcceptParams(
        from options: AcceptProofRequestOptions,
        proofRecord: ProofExchangeRecord,
        formatServices: [any ProofFormatService],
        chosenCredentialId: String? = nil
    ) -> AcceptProofRequestParams {
        return AcceptProofRequestParams(
            proofRecord: proofRecord,
            proofFormats: options.requestedCredentials,
            formatServices: formatServices,
            comment: options.comment,
            lastPresentation: true,
            goalCode: options.goalCode,
            goal: options.goal,
            chosenCredentialId: chosenCredentialId
        )
    }
}
