//
//  ProofFormatCoordinatorProtocol.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

import Foundation

public protocol ProofFormatCoordinatorProtocol: AnyObject {

    var agent: Agent { get }
    var formatServices: [any ProofFormatService] { get }

    func createProposal(
        params: CreateProofProposalParams
    ) async throws -> ProposePresentationMessageV2

    func processProposal(
        proofRecord: ProofExchangeRecord,
        message: ProposePresentationMessageV2,
        formatServices: [any ProofFormatService]
    ) async throws

    func acceptProposal(
        params: AcceptProofProposalParams
    ) async throws -> RequestPresentationMessageV2

    func createRequest(
        params: RequestProofRequestParams
    ) async throws -> RequestPresentationMessageV2

    func processRequest(
        proofRecord: ProofExchangeRecord,
        message: RequestPresentationMessageV2,
        formatServices: [any ProofFormatService]
    ) async throws

    func acceptRequest(
        params: AcceptProofRequestParams
    ) async throws -> PresentationMessageV2

    func processPresentation(
        proofRecord: inout ProofExchangeRecord,
        presentationMessage: PresentationMessageV2,
        requestMessage: RequestPresentationMessageV2,
        formatServices: [any ProofFormatService]
    ) async throws -> ProcessPresentationReturn
}
