//
//  NegotiateProofRequestProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//


import Foundation
import AnyCodable

/// Handles the negotiation of incoming proof requests (by creating and sending a new proof proposal).
final class NegotiateProofRequestProcessor {

    // MARK: - Dependencies
    private let proofFormatCoordinator: ProofFormatCoordinatorProtocol
    private let common: CommonFunctions

    // MARK: - Initializer
    init(proofFormatCoordinator: ProofFormatCoordinatorProtocol, common: CommonFunctions) {
        self.proofFormatCoordinator = proofFormatCoordinator
        self.common = common
    }

    // MARK: - Public API
    /// Negotiates an incoming proof request by creating a proposal message.
    ///
    /// - Parameter params: The parameters for negotiation, including the proof record and formats.
    /// - Returns: A tuple with the proposal message and updated proof record.
    func negotiateRequest(params: NegotiateProofRequestParams) async throws -> (ProposePresentationMessageV2, ProofExchangeRecord) {
        logDebug("[init] Negotiating proof request for record \(params.proofRecord.id)")

        var proofRecord = params.proofRecord
        let proofFormats = params.proofFormats
        let comment = params.comment
        let goalCode = params.goalCode
        let goal = params.goal
        let autoAcceptProof = params.autoAcceptProof

        try validate(proofRecord: proofRecord)

        try validateConnection(for: proofRecord)

        let formatServices = try resolveFormatServices(proofFormats)

        let createProposalParams = CreateProofProposalParams(
            formatServices: formatServices,
            proofFormats: proofFormats,
            proofRecord: proofRecord,
            comment: comment,
            goalCode: goalCode,
            goal: goal
        )

        let proposalMessage = try await proofFormatCoordinator.createProposal(params: createProposalParams)

        proofRecord.autoAcceptProof = autoAcceptProof ?? proofRecord.autoAcceptProof
        try await common.updateState(proofRecord: &proofRecord, newState: .ProposalSent)

        logDebug("[end] Negotiation completed — proposal sent for proof \(proofRecord.id)")
        return (proposalMessage, proofRecord)
    }


    /// Validates the proof record protocol and state.
    private func validate(proofRecord: ProofExchangeRecord) throws {
        try proofRecord.assertProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        try proofRecord.assertState(.RequestReceived)
    }

    /// Ensures the proof record has a valid connection (negotiation is not supported for connectionless proofs).
    private func validateConnection(for proofRecord: ProofExchangeRecord) throws {
        guard !proofRecord.connectionId.isEmpty else {
            throw CredoError(
                "No connectionId found for proof record '\(proofRecord.id)'. " +
                "Connection-less verification does not support negotiation."
            )
        }
    }

    /// Resolves the proof format services to be used for negotiation.
    private func resolveFormatServices(_ proofFormats: [String: AnyCodable]) throws -> [any ProofFormatService] {
        let services = common.getFormatServices(proofFormats)
        guard !services.isEmpty else {
            throw CredoError("Unable to create proposal. No supported formats.")
        }
        return services
    }
}
