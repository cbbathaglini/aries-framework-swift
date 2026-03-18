//
//  AcceptProposalProofProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//


import Foundation

/// Handles the acceptance of a proof proposal and creation of a corresponding proof request (RequestPresentationMessageV2).
final class AcceptProposalProofProcessor {

    // MARK: - Dependencies
    private let agent: Agent
    private let didCommMessageRepository: DidCommMessageRepository
    private let proofFormatCoordinator: ProofFormatCoordinatorProtocol
    private let common: CommonFunctions

    // MARK: - Initializer
    init(
        agent: Agent,
        didCommMessageRepository: DidCommMessageRepository,
        proofFormatCoordinator: ProofFormatCoordinatorProtocol,
        common: CommonFunctions
    ) {
        self.agent = agent
        self.didCommMessageRepository = didCommMessageRepository
        self.proofFormatCoordinator = proofFormatCoordinator
        self.common = common
    }

    // MARK: - Public API
    /// Accepts a received proof proposal and generates a RequestPresentationMessageV2.
    ///
    /// - Parameter params: The parameters for accepting the proof proposal.
    /// - Returns: A tuple containing the request message and updated proof record.
    func acceptProposal(params: AcceptProofProposalServiceParams) async throws -> (RequestPresentationMessageV2, ProofExchangeRecord) {
        logDebug("[init] Accepting proof proposal in AcceptProposalProofProcessor")

        var proofRecord = params.proofRecord
        try validate(proofRecord: proofRecord)

        var formatServices = common.getFormatServices(params.proofFormats)
        if formatServices.isEmpty {
            formatServices = try await resolveFormatServicesFromStoredMessage(for: proofRecord)
        }

        guard !formatServices.isEmpty else {
            throw CredoError("Unable to accept proposal. No supported formats found in parameters or proposal message.")
        }

        let acceptParams = buildAcceptParams(from: params, proofRecord: proofRecord, formatServices: formatServices)

        let requestMessage = try await proofFormatCoordinator.acceptProposal(params: acceptParams)

        proofRecord.autoAcceptProof = params.autoAcceptProof ?? proofRecord.autoAcceptProof
        try await common.updateState(proofRecord: &proofRecord, newState: .RequestSent)

        logDebug("[end] Proposal accepted and request message created for proof ID: \(proofRecord.id)")
        return (requestMessage, proofRecord)
    }
}

// MARK: - Private Helpers
private extension AcceptProposalProofProcessor {

    /// Validates that the proof record is in the correct protocol version and state before processing.
    func validate(proofRecord: ProofExchangeRecord) throws {
        try proofRecord.assertProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        try proofRecord.assertState(.ProposalReceived)
    }

    /// Attempts to resolve format services from a previously stored proposal message.
    func resolveFormatServicesFromStoredMessage(for proofRecord: ProofExchangeRecord) async throws -> [any ProofFormatService] {
        guard let proposalMessageJson = try await didCommMessageRepository.getAgentMessage(
            associatedRecordId: proofRecord.id,
            messageType: ProposePresentationMessageV2.type,
            role: .Receiver
        ) else {
            throw CredoError("Proposal message not found for proof record \(proofRecord.id)")
        }

        guard let proposalMessage = MessageSerializer.decodeFromString(proposalMessageJson) as? ProposePresentationMessageV2 else {
            throw CredoError("Unable to decode stored proposal message")
        }

        return common.getFormatServicesFromMessage(proposalMessage.formats)
    }

    /// Builds parameters for the ProofFormatCoordinator to accept a proposal.
    func buildAcceptParams(
        from params: AcceptProofProposalServiceParams,
        proofRecord: ProofExchangeRecord,
        formatServices: [any ProofFormatService]
    ) -> AcceptProofProposalParams {
        return AcceptProofProposalParams(
            proofRecord: proofRecord,
            proofFormats: params.proofFormats,
            formatServices: formatServices,
            comment: params.comment,
            goalCode: params.goalCode,
            goal: params.goal,
            presentMultiple: false,
            willConfirm: params.willConfirm
        )
    }
}
