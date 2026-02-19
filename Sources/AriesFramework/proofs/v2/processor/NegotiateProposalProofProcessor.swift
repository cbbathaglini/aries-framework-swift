//
//  NegotiateProposalProofProcessor.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 08/10/25.
//


import Foundation
import AnyCodable

/// Handles the negotiation flow for proof proposals by creating a counter RequestPresentationMessageV2.
final class NegotiateProposalProofProcessor {

    // MARK: - Dependencies
    private let agent: Agent
    private let proofFormatCoordinator: ProofFormatCoordinator
    private let common: CommonFunctions

    // MARK: - Initializer
    init(
        agent: Agent,
        proofFormatCoordinator: ProofFormatCoordinator,
        common: CommonFunctions
    ) {
        self.agent = agent
        self.proofFormatCoordinator = proofFormatCoordinator
        self.common = common
    }

    // MARK: - Public API
    /// Negotiates a received proof proposal by creating a new proof request message.
    ///
    /// - Parameter params: The parameters containing the proof record, formats, and optional metadata.
    /// - Returns: A tuple containing the created request message and updated proof record.
    func negotiateProposal(params: NegotiateProofProposalOptions) async throws -> (RequestPresentationMessageV2, ProofExchangeRecord) {
        logDebug("[init] Negotiating proof proposal in NegotiateProposalProofProcessor")

        var proofRecord = params.proofRecord
        try validate(proofRecord: proofRecord)

        try validateConnection(for: proofRecord)
        let formatServices = try resolveFormatServices(from: params.proofFormats)

        let requestParams = buildRequestParams(from: params, proofRecord: proofRecord, formatServices: formatServices)

        let requestMessage = try await proofFormatCoordinator.createRequest(params: requestParams)

        proofRecord.autoAcceptProof = params.autoAcceptProof ?? proofRecord.autoAcceptProof
        try await common.updateState(proofRecord: &proofRecord, newState: .RequestSent)

        logDebug("[end] Negotiation complete for proof \(proofRecord.id)")
        return (requestMessage, proofRecord)
    }
}

// MARK: - Private Helpers
private extension NegotiateProposalProofProcessor {

    /// Validates that the proof record is in the correct state and protocol version.
    func validate(proofRecord: ProofExchangeRecord) throws {
        try proofRecord.assertProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        try proofRecord.assertState(.ProposalReceived)
    }

    /// Ensures that negotiation is supported only when a connection exists.
    func validateConnection(for proofRecord: ProofExchangeRecord) throws {
        guard !proofRecord.connectionId.isEmpty else {
            throw CredoError("No connectionId found for proof record '\(proofRecord.id)'. Connection-less verification does not support negotiation.")
        }
    }

    /// Retrieves format services based on provided proof formats.
    func resolveFormatServices(from proofFormats: [String: AnyCodable]) throws -> [any ProofFormatService] {
        let services = common.getFormatServices(proofFormats)
        guard !services.isEmpty else {
            throw CredoError("Unable to create proof request. No supported formats found.")
        }
        return services
    }

    /// Builds the parameters needed to create a proof request for negotiation.
    func buildRequestParams(
        from params: NegotiateProofProposalOptions,
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
            presentMultiple: false,
            willConfirm: params.willConfirm
        )
    }
}
