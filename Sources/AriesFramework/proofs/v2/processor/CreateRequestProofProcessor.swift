//
//  CreateRequestProofProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation

/// Handles creation of a new proof request (RequestPresentationMessageV2).
final class CreateRequestProofProcessor {


    private let agent: Agent
    private let proofFormatCoordinator: ProofFormatCoordinatorProtocol
    private let common: CommonFunctions

    init(agent: Agent, proofFormatCoordinator: ProofFormatCoordinatorProtocol, common: CommonFunctions) {
        self.agent = agent
        self.proofFormatCoordinator = proofFormatCoordinator
        self.common = common
    }

    /// Creates a new proof request and returns both the request message and proof record.
    func createRequest(params: CreateProofRequestOptions) async throws -> (RequestPresentationMessageV2, ProofExchangeRecord) {
        logDebug("[init] Starting proof request creation in CreateRequestProofProcessor")

        try validateInput(params)
        let connectionRecord = params.connectionRecord

        let formatServices = try resolveFormatServices(from: params.formats)
        let proofRecord = buildProofRecord(from: params, connectionRecord: connectionRecord)
        let requestParams = buildRequestParams(from: params, proofRecord: proofRecord, formatServices: formatServices)

        let requestMessage = try await proofFormatCoordinator.createRequest(params: requestParams)
        

        try await persistProofRecord(proofRecord)

        logDebug("[end] Proof request successfully created — ID: \(proofRecord.id)")
        return (requestMessage, proofRecord)
    }
}

// MARK: - Private Helpers
private extension CreateRequestProofProcessor {

    /// Validates that input parameters are coherent and usable.
    func validateInput(_ params: CreateProofRequestOptions) throws {
        guard !params.formats.isEmpty else {
            throw CredoError("Cannot create proof request: no formats provided.")
        }
    }

    /// Resolves format services from the provided list.
    func resolveFormatServices(from formats: [ProofFormatSpec]) throws -> [any ProofFormatService] {
        let services = common.getFormatServicesByList(formats)
        guard !services.isEmpty else {
            throw CredoError("Unable to create request: no supported formats found.")
        }
        return services
    }

    /// Builds a new proof exchange record for the request.
    func buildProofRecord(from params: CreateProofRequestOptions, connectionRecord: ConnectionRecord?) -> ProofExchangeRecord {
        return ProofExchangeRecord(
            connectionId: connectionRecord?.id ?? "connectionless-proof-request",
            threadId: RecordUtils.generateId(),
            state: .RequestSent,
            role: .verifier,
            autoAcceptProof: params.autoAcceptProof,
            protocolVersion: ProofConstants.PROTOCOL_VERSION_V2
        )
    }

    /// Builds the parameters for the proof format coordinator.
    func buildRequestParams(
        from params: CreateProofRequestOptions,
        proofRecord: ProofExchangeRecord,
        formatServices: [any ProofFormatService]
    ) -> RequestProofRequestParams {
        return RequestProofRequestParams(
            proofRecord: proofRecord,
            proofFormats: params.proofFormats,
            formatServices: formatServices,
            comment: params.comment,
            goalCode: params.goalCode,
            goal: params.goal,
            willConfirm: params.willConfirm,
            attachmentId: params.formats.first?.attachmentId ?? ""
        )
    }

    /// Saves the proof record and emits the proof state change.
    func persistProofRecord(_ proofRecord: ProofExchangeRecord) async throws {
        try await agent.proofRepository.save(proofRecord)
        agent.agentDelegate?.onProofStateChangedV2(proofRecord: proofRecord)
        logDebug("Saved proof exchange record with ID \(proofRecord.id)")
    }
}
