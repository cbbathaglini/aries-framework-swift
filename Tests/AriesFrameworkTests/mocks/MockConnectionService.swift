//
//  MockConnectionService.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import Foundation
@testable import AriesFramework

final class MockConnectionService: ConnectionServiceProtocol {

   private(set) var createInvitationCalled = false
   private(set) var processInvitationCalled = false
   private(set) var createRequestCalled = false
   private(set) var updateStateCalled = false
    
   private(set) var receivedCreateRequestConnectionId: String?
   private(set) var receivedAutoAcceptConnection: Bool?
    
   private(set) var receivedUpdateStateConnectionId: String?
   private(set) var receivedNewState: ConnectionState?

   // MARK: - Captured inputs

   private(set) var receivedRouting: Routing?
   private(set) var receivedConnectionId: String?
   private(set) var createConnectionCalled = false
   private(set) var receivedThreadId: String?

   // MARK: - Stubbed results

   var outboundMessageToReturn: OutboundMessage!
   var processInvitationResult: ConnectionRecord!
   var createRequestResult: OutboundMessage!
    
    
   private(set) var matchIncomingCalled = false
   private(set) var receivedExpectedConnectionId: String?
   var errorToThrow: Error?
    
    private let repo: ConnectionRepositoryProtocol

    init(connectionRepository: ConnectionRepositoryProtocol) {
        self.repo = connectionRepository
    }

    func createInvitation(
        routing: Routing,
        autoAcceptConnection: Bool?,
        alias: String?,
        multiUseInvitation: Bool?,
        label: String?,
        imageUrl: String?
    ) async throws -> OutboundMessage {
        createInvitationCalled = true
        receivedRouting = routing
        return outboundMessageToReturn
    }

    func processRequest(messageContext: InboundMessageContext) async throws -> ConnectionRecord {
        fatalError()
    }

    func processResponse(messageContext: InboundMessageContext) async throws -> ConnectionRecord {
        fatalError()
    }

    func createResponse(connectionId: String) async throws -> OutboundMessage {
        fatalError()
    }

    func createTrustPing(
        connectionId: String,
        responseRequested: Bool?,
        comment: String?
    ) async throws -> OutboundMessage {
        fatalError()
    }

    func createRequest(
        connectionId: String,
        label: String?,
        imageUrl: String?,
        autoAcceptConnection: Bool?
    ) async throws -> OutboundMessage {
       createRequestCalled = true
       receivedCreateRequestConnectionId = connectionId
       receivedAutoAcceptConnection = autoAcceptConnection
       return createRequestResult
    }
    
    

    func findByKeys(
        senderKey: String,
        recipientKey: String
    ) async throws -> ConnectionRecord? {
        fatalError()
    }

    func findByInvitationKey(_ key: String) async -> ConnectionRecord? {
        fatalError()
    }

    func findAllByInvitationKey(_ key: String) async -> [ConnectionRecord] {
        fatalError()
    }

    func processInvitation(
        _ invitation: ConnectionInvitationMessage?,
        outOfBandInvitation: OutOfBandInvitation?,
        routing: Routing,
        autoAcceptConnection: Bool?,
        alias: String?
    ) async throws -> ConnectionRecord {
        processInvitationCalled = true
        return processInvitationResult
    }

    func updateState(
        connectionRecord: inout ConnectionRecord,
        newState: ConnectionState
    ) async throws {
        updateStateCalled = true
        receivedUpdateStateConnectionId = connectionRecord.id
        receivedNewState = newState

        connectionRecord.state = newState
        connectionRecord.updatedAt = Date()
        
        try await repo.update(connectionRecord)
    }

    func matchIncomingMessageToRequestMessageInOutOfBandExchange(
        messageContext: InboundMessageContext,
        expectedConnectionId: String
    ) async throws {
        matchIncomingCalled = true
        receivedExpectedConnectionId = expectedConnectionId

        if let errorToThrow {
            throw errorToThrow
        }
    }
    
    func createConnection(
        role: ConnectionRole,
        state: ConnectionState,
        invitation: ConnectionInvitationMessage?,
        outOfBandInvitation: OutOfBandInvitation?,
        alias: String?,
        routing: Routing,
        theirLabel: String?,
        autoAcceptConnection: Bool?,
        multiUseInvitation: Bool,
        tags: Tags?,
        imageUrl: String?,
        threadId: String?
    ) async throws -> ConnectionRecord {
        
        createConnectionCalled = true
        receivedThreadId = threadId

        var builder = ConnectionRecordBuilder()
            .withRole(role)
            .withState(state)
            .withThreadId(threadId ?? "none")
            .withTheirLabel(theirLabel)

        if let oob = outOfBandInvitation {
            builder = builder.withOutOfBandInvitation(oob)
        }

        let record = builder.build()

        try await repo.save(record)
        return record
    }

    func getByThreadId(_ threadId: String) async throws -> ConnectionRecord {
        fatalError()
    }

    func fetchState(connectionRecord: ConnectionRecord) async throws -> ConnectionState {
        fatalError()
    }

    func waitForConnection() async throws -> Bool {
        fatalError()
    }

    func getById(id: String) async throws -> ConnectionRecord {
        fatalError()
    }
}

