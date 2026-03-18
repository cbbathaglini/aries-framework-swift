//
//  CreateProposalProofProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//

import Foundation
import AnyCodable

/// Handles the creation of proof proposals (ProposePresentationMessageV2).
final class CreateProposalProofProcessor {

    // MARK: - Dependencies
    private let agent: Agent
    private let proofRepository: ProofRepository
    private let proofFormatCoordinator: ProofFormatCoordinatorProtocol
    private let common: CommonFunctions

    // MARK: - Initializer
    init(
        agent: Agent,
        proofRepository: ProofRepository,
        proofFormatCoordinator: ProofFormatCoordinatorProtocol,
        common: CommonFunctions
    ) {
        self.agent = agent
        self.proofRepository = proofRepository
        self.proofFormatCoordinator = proofFormatCoordinator
        self.common = common
    }

    // MARK: - Public API
    /// Creates a proof proposal message and its associated record.
    ///
    /// - Parameter options: The configuration options for creating a proof proposal.
    /// - Returns: A tuple containing the proposal message and the created proof record.
    func createProposal(options: CreateProposalProofOptionsV2) async throws -> (ProposePresentationMessageV2, ProofExchangeRecord) {
        logDebug("[init] Starting proof proposal creation in CreateProposalProofProcessor")

        let formatServices = try resolveFormatServices(from: options.proofFormats)
        let proofRecord = buildProofRecord(from: options)
        let proposalParams = buildProposalParams(from: options, proofRecord: proofRecord, formatServices: formatServices)
        let proposalMessage = try await proofFormatCoordinator.createProposal(params: proposalParams)
        try await persistProofRecord(proofRecord)

        logDebug("[end] Proof proposal successfully created — ID: \(proofRecord.id)")
        return (proposalMessage, proofRecord)
    }
}

// MARK: - Private Helpers
private extension CreateProposalProofProcessor {

    /// Ensures that at least one supported format service is available.
    func resolveFormatServices(from proofFormats: [String: AnyCodable]) throws -> [any ProofFormatService] {
        let services = common.getFormatServices(proofFormats)
        guard !services.isEmpty else {
            throw CredoError("Unable to create proposal. No supported formats available.")
        }
        return services
    }

    /// Builds the proof exchange record that represents the proposal.
    func buildProofRecord(from options: CreateProposalProofOptionsV2) -> ProofExchangeRecord {
        return ProofExchangeRecord(
            connectionId: options.connectionRecord.id,
            threadId: RecordUtils.generateId(),
            parentThreadId: options.parentThreadId,
            state: .ProposalSent,
            role: .prover,
            autoAcceptProof: options.autoAcceptProof,
            protocolVersion: ProofConstants.PROTOCOL_VERSION_V2
        )
    }

    /// Builds the parameters required to create a proposal message.
    func buildProposalParams(
        from options: CreateProposalProofOptionsV2,
        proofRecord: ProofExchangeRecord,
        formatServices: [any ProofFormatService]
    ) -> CreateProofProposalParams {
        return CreateProofProposalParams(
            formatServices: formatServices,
            proofFormats: options.proofFormats,
            proofRecord: proofRecord,
            comment: options.comment,
            goalCode: options.goalCode,
            goal: options.goal
        )
    }

    /// Persists the proof record and notifies the agent delegate about the state change.
    func persistProofRecord(_ proofRecord: ProofExchangeRecord) async throws {
        try await proofRepository.save(proofRecord)
        agent.agentDelegate?.onProofStateChangedV2(proofRecord: proofRecord)
        logDebug("Saved proof exchange record and emitted state change event for ID \(proofRecord.id)")
    }
}
