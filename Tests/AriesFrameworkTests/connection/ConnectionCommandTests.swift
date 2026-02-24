//
//  ConnectionCommandTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import XCTest
@testable import AriesFramework

final class ConnectionCommandTests: XCTestCase {
    
   let URL = "https://example.com/endpoint?oob=eyJAdHlwZSI6ICJodHRwczovL2RpZGNvbW0ub3JnL291dC1vZi1iYW5kLzEuMS9pbnZpdGF0aW9uIiwgIkBpZCI6ICIwMmVjMjg4Ny0xNjg4LTRkZWEtOWFjMS1hMTdkYmUwYWQ5M2MiLCAibGFiZWwiOiAiU0VSUFJPIElzc3VlciIsICJoYW5kc2hha2VfcHJvdG9jb2xzIjogWyJodHRwczovL2RpZGNvbW0ub3JnL2RpZGV4Y2hhbmdlLzEuMSJdLCAic2VydmljZXMiOiBbeyJpZCI6ICIjaW5saW5lIiwgInR5cGUiOiAiZGlkLWNvbW11bmljYXRpb24iLCAicmVjaXBpZW50S2V5cyI6IFsiZGlkOmtleTp6Nk1rcjJQd1pXazF4SktwbTQ1dFJqSzJtTEt0dk54Z2Jyc25iU205SlZCS3hmSjQjejZNa3IyUHdaV2sxeEpLcG00NXRSaksybUxLdHZOeGdicnNuYlNtOUpWQkt4Zko0Il0sICJzZXJ2aWNlRW5kcG9pbnQiOiAiaHR0cHM6Ly9hcmllcy5pZGQuc2VycHJvLmdvdi5ici9lbmRwb2ludCJ9XX0"
    
   var mediationRecipient: MockMediationRecipient!
   var connectionService: MockConnectionService!
   var didExchangeService: MockDidExchangeService!
   var messageSender: MockMessageSender!
   var agent: MockConnectionCommandAgent!
   var dispatcher: MockDispatcher!
   var command: ConnectionCommand!
   
   var connectionRepository: MockConnectionRepository!
    
    override func setUp() {
        super.setUp()

        connectionRepository = MockConnectionRepository()
        
        mediationRecipient = MockMediationRecipient()
        mediationRecipient.routingToReturn = Routing(
            endpoints: ["https://example.com"],
            verkey: "verkey",
            did: "did:test",
            routingKeys: [],
            mediatorId: nil
        )

        connectionService = MockConnectionService(connectionRepository: connectionRepository)
        didExchangeService = MockDidExchangeService()
        messageSender = MockMessageSender()
        dispatcher = MockDispatcher()

        
        agent = MockConnectionCommandAgent(
            agentConfig: AgentConfigTestFactory.minimal(
                autoAcceptConnections: false
            ),
            mediationRecipient: mediationRecipient,
            connectionService: connectionService,
            didExchangeService: didExchangeService,
            messageSender: messageSender
        )

        command = ConnectionCommand(
            agent: agent,
            dispatcher: dispatcher
        )
    }
    
    override func tearDown() {
       mediationRecipient = nil
       connectionService = nil
       didExchangeService = nil
       messageSender = nil
       dispatcher = nil
       agent = nil
       command = nil

       super.tearDown()
   }
    
    func test_createConnection_callsCreateInvitation_andReturnsOutboundMessage() async throws {
        let routing = Routing(
            endpoints: ["https://example.com"],
            verkey: "verkey",
            did: "did",
            routingKeys: [],
            mediatorId: nil
        )

        mediationRecipient.routingToReturn = routing

        let connection = ConnectionRecordTestFactory.notReadyConnection(state: .Invited)

        let expectedOutboundMessage = OutboundMessage(
            payload: ConnectionInvitationMessage(label: "test"),
            connection: connection
        )

        connectionService.outboundMessageToReturn = expectedOutboundMessage

        let result = try await command.createConnection(
            autoAcceptConnection: true,
            alias: "alias",
            multiUseInvitation: false,
            label: "label",
            imageUrl: nil
        )

        XCTAssertTrue(mediationRecipient.getRoutingCalled)
        XCTAssertTrue(connectionService.createInvitationCalled)
        XCTAssertEqual(result.payload.type, ConnectionInvitationMessage.type)
        XCTAssertEqual(
            (result.payload as? ConnectionInvitationMessage)?.label,
            "test"
        )
        XCTAssertEqual(result.connection.state, .Invited)
    }
    
    func test_receiveInvitation_withoutAutoAccept_returnsConnection() async throws {
        
        let connection = ConnectionRecordTestFactory.notReadyConnection()
        connectionService.processInvitationResult = connection

        mediationRecipient.routingToReturn = Routing(
            endpoints: ["https://example.com"],
            verkey: "verkey",
            did: "did",
            routingKeys: [],
            mediatorId: nil
        )

        
        let result = try await command.receiveInvitation(
            ConnectionInvitationMessage(label: "test"),
            autoAcceptConnection: false
        )

        
        XCTAssertTrue(connectionService.processInvitationCalled)
        XCTAssertFalse(connectionService.createRequestCalled)
        XCTAssertTrue(messageSender.sentMessages.isEmpty)
        XCTAssertEqual(result.id, connection.id)
    }
    
    func test_receiveInvitation_withAutoAccept_sendsRequest() async throws {
        var connection = ConnectionRecordTestFactory.notReadyConnection()
        connection.autoAcceptConnection = true

        connectionService.processInvitationResult = connection
        connectionService.createRequestResult = OutboundMessage(
            payload: ConnectionRequestMessageTestFactory.minimal(),
            connection: ConnectionRecordTestFactory.readyConnection()
        )

        let result = try await command.receiveInvitation(
            ConnectionInvitationMessage(label: "test"),
            autoAcceptConnection: true
        )

        XCTAssertTrue(connectionService.createRequestCalled)
        XCTAssertEqual(messageSender.sentMessages.count, 1)
        XCTAssertEqual(result.id, connectionService.createRequestResult.connection.id)
    }
    
    func test_receiveInvitationFromUrl_delegatesToReceiveInvitation() async throws {
       
        let invitation = ConnectionInvitationMessageTestFactory.minimal()

        let jsonData = try JSONEncoder().encode(invitation)
        let b64 = jsonData.base64EncodedString()
        let b64url = b64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        let url = "http://example.com/ssi?c_i=\(b64url)"

        let connection = ConnectionRecordTestFactory.notReadyConnection()
        connectionService.processInvitationResult = connection

        let result = try await command.receiveInvitationFromUrl(url)

        XCTAssertTrue(connectionService.processInvitationCalled)
        XCTAssertEqual(result.id, connection.id)
    }
    
    func test_acceptInvitation_createsRequestAndSendsMessage() async throws {
        let outbound = OutboundMessage(
            payload: ConnectionRequestMessageTestFactory.minimal(),
            connection: ConnectionRecordTestFactory.readyConnection()
        )

        connectionService.createRequestResult = outbound

        let result = try await command.acceptInvitation(
            connectionId: "conn-id",
            autoAcceptConnection: true
        )

        XCTAssertTrue(connectionService.createRequestCalled)
        XCTAssertEqual(messageSender.sentMessages.count, 1)
        XCTAssertEqual(result.id, outbound.connection.id)
    }
    
    func test_acceptOutOfBandInvitation_withoutHandshake_completesConnection() async throws {
        let connection = ConnectionRecordTestFactory.notReadyConnection()
        connectionService.processInvitationResult = connection

        let outOfBandRecord = OutOfBandRecordTestFactory.make()

        let result = try await command.acceptOutOfBandInvitation(
            outOfBandRecord: outOfBandRecord,
            handshakeProtocol: nil,
            config: nil
        )

        XCTAssertTrue(connectionService.updateStateCalled)
        XCTAssertEqual(result.state, .Complete)
        XCTAssertTrue(messageSender.sentMessages.isEmpty)
    }
    
    func test_acceptOutOfBandInvitation_withDidExchange_sendsRequest() async throws {
        let connection = ConnectionRecordTestFactory.notReadyConnection()
        connectionService.processInvitationResult = connection

        let outbound = OutboundMessage(
            payload: DidExchangeRequestMessageTestFactory.minimal(label: "test"),
            connection: ConnectionRecordTestFactory.readyConnection()
        )

        didExchangeService.outboundMessageToReturn = outbound

        let outOfBandRecord = OutOfBandRecordTestFactory.make()

        let result = try await command.acceptOutOfBandInvitation(
            outOfBandRecord: outOfBandRecord,
            handshakeProtocol: .DidExchange10,
            config: ReceiveOutOfBandInvitationConfig(label: "test")
        )

        XCTAssertTrue(didExchangeService.createRequestCalled)
        XCTAssertEqual(messageSender.sentMessages.count, 1)
        XCTAssertEqual(result.id, outbound.connection.id)
    }
}
