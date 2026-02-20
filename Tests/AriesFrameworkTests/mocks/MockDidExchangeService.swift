//
//  MockDidExchangeService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

@testable import AriesFramework

final class MockDidExchangeService: DidExchangeServiceProtocol {

    // MARK: - Call tracking

    private(set) var createRequestCalled = false
    private(set) var receivedCreateRequestConnectionId: String?

    private(set) var createResponseCalled = false
    private(set) var createCompleteCalled = false

    // MARK: - Stubbed returns

    var outboundMessageToReturn: OutboundMessage!
    var connectionRecordToReturn: ConnectionRecord!
    var waitForConnectionResult: Bool = true

    // MARK: - Protocol methods

    func createRequest(
        connectionId: String,
        label: String?,
        autoAcceptConnection: Bool?
    ) async throws -> OutboundMessage {
        createRequestCalled = true
        receivedCreateRequestConnectionId = connectionId
        return outboundMessageToReturn
    }

    func processRequest(
        messageContext: InboundMessageContext
    ) async throws -> ConnectionRecord {
        return connectionRecordToReturn
    }

    func createResponse(
        connectionId: String
    ) async throws -> OutboundMessage {
        createResponseCalled = true
        return outboundMessageToReturn
    }

    func processResponse(
        messageContext: InboundMessageContext
    ) async throws -> ConnectionRecord {
        return connectionRecordToReturn
    }

    func createComplete(
        connectionId: String
    ) async throws -> OutboundMessage {
        createCompleteCalled = true
        return outboundMessageToReturn
    }

    func waitForConnection() async throws -> Bool {
        return waitForConnectionResult
    }
}
