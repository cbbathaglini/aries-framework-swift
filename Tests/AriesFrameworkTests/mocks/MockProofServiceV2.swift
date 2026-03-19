//
//  MockProofServiceV2.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 18/03/26.
//

@testable import AriesFramework
import Foundation
import AnyCodable

final class MockProofServiceV2: ProofServiceV2 {

    var errorToThrow: Error?

    private(set) var processAckCallCount = 0
    private(set) var receivedMessageContext: InboundMessageContext?

    private(set) var processPresentationCallCount = 0
    private(set) var receivedProcessPresentationMessageContext: InboundMessageContext?

    private(set) var createAckCallCount = 0
    private(set) var receivedCreateAckProofRecord: ProofExchangeRecord?

    private(set) var processRequestCallCount = 0
    private(set) var receivedProcessRequestMessageContext: InboundMessageContext?
    private(set) var receivedProcessRequestMessage: RequestPresentationMessageV2?

    private(set) var autoSelectCredentialsCallCount = 0
    private(set) var receivedRetrievedCredentials: RetrievedCredentials?

    private(set) var acceptRequestCallCount = 0
    private(set) var receivedAcceptRequestParams: AcceptProofRequestOptions?
    
    private(set) var createRequestCallCount = 0
    private(set) var receivedCreateRequestParams: CreateProofRequestOptions?
    
    private(set) var processOfflineAckCallCount = 0
    private(set) var receivedProcessOfflineAckProofRecord: ProofExchangeRecord?

    private(set) var processPresentationOfflineCallCount = 0
    private(set) var receivedProcessPresentationOfflineMessage: PresentationMessageV2?
    
    var processOfflineAckReturnMessage = PresentationAckMessageV2Builder()
        .setThreadId("thread-id")
        .setStatus(.OK)
        .build()

    var processOfflineAckReturnRecord = ProofExchangeRecordBuilder()
        .setState(.Done)
        .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        .build()

    var processOfflineAckErrorToThrow: Error?

    var processPresentationOfflineRecordToReturn: ProofExchangeRecord? = nil

    var createRequestReturnMessage = RequestPresentationMessageV2Builder().build()
    var createRequestReturnRecord = ProofExchangeRecordBuilder()
        .setState(.RequestSent)
        .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        .build()

    var createRequestErrorToThrow: Error?

    var proofRecordToReturn = ProofExchangeRecordBuilder()
        .setState(.Done)
        .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        .build()

    var processPresentationRecordToReturn = ProofExchangeRecordBuilder()
        .setState(.PresentationReceived)
        .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        .build()

    var processRequestRecordToReturn = ProofExchangeRecordBuilder()
        .setState(.RequestReceived)
        .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        .build()

    var createAckReturnMessage = PresentationAckMessageV2Builder()
        .setThreadId("thread-id")
        .setStatus(.OK)
        .build()

    var createAckReturnRecord = ProofExchangeRecordBuilder()
        .setState(.Done)
        .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        .build()

    var acceptRequestReturnMessage = PresentationMessageV2Builder().build()
    var acceptRequestReturnRecord = ProofExchangeRecordBuilder()
        .setState(.PresentationSent)
        .setProtocolVersion(ProofConstants.PROTOCOL_VERSION_V2)
        .build()

    var autoSelectedRequestedCredentialsToReturn = RequestedCredentialsAnoncreds()

    var processPresentationErrorToThrow: Error?
    var createAckErrorToThrow: Error?
    var processRequestErrorToThrow: Error?
    var autoSelectCredentialsErrorToThrow: Error?
    var acceptRequestErrorToThrow: Error?

    override init(agent: Agent) {
        super.init(agent: agent)
    }

    override func processAck(messageContext: InboundMessageContext) async throws -> ProofExchangeRecord {
        processAckCallCount += 1
        receivedMessageContext = messageContext

        if let errorToThrow {
            throw errorToThrow
        }

        return proofRecordToReturn
    }

    override func processPresentation(messageContext: InboundMessageContext) async throws -> ProofExchangeRecord {
        processPresentationCallCount += 1
        receivedProcessPresentationMessageContext = messageContext

        if let processPresentationErrorToThrow {
            throw processPresentationErrorToThrow
        }

        return processPresentationRecordToReturn
    }

    override func createAck(proofRecord: inout ProofExchangeRecord) async throws -> (PresentationAckMessageV2, ProofExchangeRecord) {
        createAckCallCount += 1
        receivedCreateAckProofRecord = proofRecord

        if let createAckErrorToThrow {
            throw createAckErrorToThrow
        }

        return (createAckReturnMessage, createAckReturnRecord)
    }

    override func processRequest(
        messageContext: InboundMessageContext?,
        requestMessage: RequestPresentationMessageV2?
    ) async throws -> ProofExchangeRecord {
        processRequestCallCount += 1
        receivedProcessRequestMessageContext = messageContext
        receivedProcessRequestMessage = requestMessage

        if let processRequestErrorToThrow {
            throw processRequestErrorToThrow
        }

        return processRequestRecordToReturn
    }

    func autoSelectCredentialsForProofRequest(
        retrievedCredentials: RetrievedCredentials
    ) async throws -> RequestedCredentialsAnoncreds {
        autoSelectCredentialsCallCount += 1
        receivedRetrievedCredentials = retrievedCredentials

        if let autoSelectCredentialsErrorToThrow {
            throw autoSelectCredentialsErrorToThrow
        }

        return autoSelectedRequestedCredentialsToReturn
    }

    override func acceptRequest(
        params: AcceptProofRequestOptions
    ) async throws -> (PresentationMessageV2, ProofExchangeRecord) {
        acceptRequestCallCount += 1
        receivedAcceptRequestParams = params

        if let acceptRequestErrorToThrow {
            throw acceptRequestErrorToThrow
        }

        return (acceptRequestReturnMessage, acceptRequestReturnRecord)
    }
    
    override func createRequest(
        params: CreateProofRequestOptions
    ) async throws -> (RequestPresentationMessageV2, ProofExchangeRecord) {
        print("✅ MockProofServiceV2.createRequest chamado")
        createRequestCallCount += 1
        receivedCreateRequestParams = params

        if let createRequestErrorToThrow {
            throw createRequestErrorToThrow
        }

        return (createRequestReturnMessage, createRequestReturnRecord)
    }
    
    override func processOfflineAck(
        proofRecord: ProofExchangeRecord
    ) async throws -> (PresentationAckMessageV2, ProofExchangeRecord) {
        processOfflineAckCallCount += 1
        receivedProcessOfflineAckProofRecord = proofRecord

        if let processOfflineAckErrorToThrow {
            throw processOfflineAckErrorToThrow
        }

        return (processOfflineAckReturnMessage, processOfflineAckReturnRecord)
    }

    override func processPresentationOffline(message: PresentationMessageV2) async throws -> ProofExchangeRecord? {
        processPresentationOfflineCallCount += 1
        receivedProcessPresentationOfflineMessage = message
        return processPresentationOfflineRecordToReturn
    }
}
