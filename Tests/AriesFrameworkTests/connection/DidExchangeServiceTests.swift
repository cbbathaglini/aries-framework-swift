//
//  DidExchangeServiceTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 19/12/25.
//

import XCTest
@testable import AriesFramework

final class DidExchangeServiceTests: XCTestCase {
    
    func test_createRequest_updatesConnectionAndReturnsOutboundMessage() async throws {
        
        let connection = ConnectionRecordBuilder()
            .withId("c1")
            .withState(.Invited)
            .withRole(.Invitee)
            .withVerkey("vk")
            .build()

        let repo = MockConnectionRepository()
        try await repo.save(connection)

        let agent = TestAgent(
            connectionRepository: repo,
            peerDIDService: MockPeerDIDService()
        )

        let service = DidExchangeService(agent: agent)

        let outbound = try await service.createRequest(
            connectionId: "c1",
            label: "Alice"
        )

        XCTAssertEqual(outbound.connection.state, ConnectionState.Requested)
        XCTAssertEqual(outbound.payload.type, DidExchangeRequestMessage.type)
        XCTAssertNotNil(outbound.connection.threadId)
        XCTAssertEqual(outbound.connection.did, "did:peer:123")
    }
    
    func test_createResponse_createsDidRotateAndUpdatesState() async throws {
        
        let outOfBandInvitation = OutOfBandInvitationBuilder()
            .build()
        
        let connection = ConnectionRecordBuilder()
            .withId("c1")
            .withState(.Requested)
            .withRole(.Inviter)
            .withVerkey("vk")
            .withThreadId("thread1")
            .withOutOfBandInvitation(outOfBandInvitation)
            .build()
    

        let repo = MockConnectionRepository()
        try await repo.save(connection)

        let agent = TestAgent(
            connectionRepository: repo,
            peerDIDService: MockPeerDIDService(),
            jwsService: MockJwsService(),
        )

        let service = DidExchangeService(agent: agent)

        let outbound = try await service.createResponse(connectionId: "c1")

        XCTAssertEqual(outbound.connection.state, ConnectionState.Responded)
        XCTAssertNotNil((outbound.payload as? DidExchangeResponseMessage)?.didRotate)
    }
    
    func test_createComplete_movesConnectionToComplete() async throws {
        let outOfBandInvitation = OutOfBandInvitationBuilder()
            .build()
        
        let connection = ConnectionRecordBuilder()
            .withId("c1")
            .withState(.Responded)
            .withRole(.Inviter)
            .withVerkey("vk")
            .withThreadId("t1")
            .withOutOfBandInvitation(outOfBandInvitation)
            .build()

        let repo = MockConnectionRepository()
        try await repo.save(connection)

        let agent = TestAgent(connectionRepository: repo)
        let service = DidExchangeService(agent: agent)

        let outbound = try await service.createComplete(connectionId: "c1")

        XCTAssertEqual(outbound.connection.state, ConnectionState.Complete)
        XCTAssertTrue(outbound.payload is DidExchangeCompleteMessage)
    }
    
    
}
