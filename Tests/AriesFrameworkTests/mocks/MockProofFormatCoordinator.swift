//
//  MockProofFormatCoordinator.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 16/03/26.
//

@testable import AriesFramework
import Foundation

final class MockProofFormatCoordinator: ProofFormatCoordinatorProtocol {

    var agent: Agent
    var formatServices: [any ProofFormatService]

    var acceptRequestCallCount = 0
    var errorToThrow: Error?
    var acceptProposalErrorToThrow: Error?
    
    var createProposalCalled = false
    private(set) var processPresentationCalled = false
    private(set) var acceptProposalCallCount = 0
    
    
    var proposalMessageToReturn = ProposePresentationMessageV2Builder().build()
    var requestMessageToReturn = RequestPresentationMessageV2Builder().build()
    var presentationMessageToReturn = PresentationMessageV2Builder().build()
    var processPresentationReturnToReturn = ProcessPresentationReturn(isValid: true)

    private(set) var receivedCreateProposalParams: CreateProofProposalParams?
    private(set) var receivedCreateRequestParams: RequestProofRequestParams?
    private(set) var receivedAcceptRequestParams: AcceptProofRequestParams?
    private(set) var receivedAcceptProposalParams: AcceptProofProposalParams?

    private(set) var receivedProcessPresentationMessage: PresentationMessageV2?
    private(set) var receivedProcessRequestMessage: RequestPresentationMessageV2?
    private(set) var receivedProcessFormatServices: [any ProofFormatService] = []

    private(set) var processProposalCalled = false
    private(set) var receivedProcessProposalRecord: ProofExchangeRecord?
    private(set) var receivedProcessProposalMessage: ProposePresentationMessageV2?
    private(set) var receivedProcessProposalFormatServices: [any ProofFormatService] = []

    private(set) var processRequestCalled = false
    private(set) var receivedProcessRequestRecord: ProofExchangeRecord?
    private(set) var receivedProcessRequestFormatServices: [any ProofFormatService] = []
    
    init(
        agent: Agent,
        formatServices: [any ProofFormatService] = []
    ) {
        self.agent = agent
        self.formatServices = formatServices
    }

    func createProposal(params: CreateProofProposalParams) async throws -> ProposePresentationMessageV2 {
        createProposalCalled = true
        receivedCreateProposalParams = params

        if let errorToThrow {
            throw errorToThrow
        }

        return proposalMessageToReturn
    }


    func acceptProposal(params: AcceptProofProposalParams) async throws -> RequestPresentationMessageV2 {
        acceptProposalCallCount += 1
        receivedAcceptProposalParams = params

        if let error = acceptProposalErrorToThrow {
            throw error
        }

        return requestMessageToReturn
    }

    func createRequest(params: RequestProofRequestParams) async throws -> RequestPresentationMessageV2 {
        receivedCreateRequestParams = params
        return requestMessageToReturn
    }

    func processRequest(
        proofRecord: ProofExchangeRecord,
        message: RequestPresentationMessageV2,
        formatServices: [any ProofFormatService]
    ) async throws {
        processRequestCalled = true
        receivedProcessRequestRecord = proofRecord
        receivedProcessRequestMessage = message
        receivedProcessRequestFormatServices = formatServices

        if let errorToThrow {
            throw errorToThrow
        }
    }

    func acceptRequest(
        params: AcceptProofRequestParams
    ) async throws -> PresentationMessageV2 {
        acceptRequestCallCount += 1
        receivedAcceptRequestParams = params

        if let errorToThrow {
            throw errorToThrow
        }

        return presentationMessageToReturn
    }

    func processPresentation(
            proofRecord: inout ProofExchangeRecord,
            presentationMessage: PresentationMessageV2,
            requestMessage: RequestPresentationMessageV2,
            formatServices: [any ProofFormatService]
    ) async throws -> ProcessPresentationReturn {
        processPresentationCalled = true
        receivedProcessPresentationMessage = presentationMessage
        receivedProcessRequestMessage = requestMessage
        receivedProcessFormatServices = formatServices
        return processPresentationReturnToReturn
    }
    
    func processProposal(
        proofRecord: ProofExchangeRecord,
        message: ProposePresentationMessageV2,
        formatServices: [any ProofFormatService]
    ) async throws {
        processProposalCalled = true
        receivedProcessProposalRecord = proofRecord
        receivedProcessProposalMessage = message
        receivedProcessProposalFormatServices = formatServices

        if let errorToThrow {
            throw errorToThrow
        }
    }
}
