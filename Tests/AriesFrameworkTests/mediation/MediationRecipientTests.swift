//
//  MediationRecipientTests.swift
//  aries-framework-swift
//
//  Created by Carine Bertagnolli Bathaglini on 23/02/26.
//


import XCTest
@testable import AriesFramework

//final class MediationRecipientTests: XCTestCase {
//    
//    func test_assertInvitationUrl_whenDefaultExistsAndUrlDiff_deletesRecord() async throws {
//        // given
//        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
//        agent.agentConfig.mediatorConnectionsInvite = "invite-new"
//
//        let repo = MockMediationRepository(agent: agent)
//        let old = MediationRecord(
//            state: .Granted,
//            role: .Mediator,
//            connectionId: "c1",
//            threadId: "t1",
//            invitationUrl: "invite-old"
//        )
//        repo.store = [old]
//
//        let dispatcher = MockDispatcher()
//        let sut = MediationRecipient(agent: agent,
//                                     dispatcher: dispatcher,
//                                     repository: repo)
//
//        // when
//        try await sut.assertInvitationUrl()
//
//        // then
//        XCTAssertTrue(repo.getDefaultCalled)
//        XCTAssertTrue(repo.deleteCalled)
//        XCTAssertTrue(repo.deleted.contains(where: { $0.id == old.id }))
//    }
//    
//    func test_requestMediationIfNecessary_whenDefaultReady_startsPickupAndInitializes() async throws {
//        let agent = Agent(agentConfig: .test(), agentDelegate: SpyAgentDelegate())
//        let repo = MockMediationRepository(agent: agent)
//
//        let mediator = MediationRecord(
//            state: .Granted,
//            role: .Mediator,
//            connectionId: "conn-1",
//            threadId: "conn-1",
//            endpoint: "https://mediator",
//            invitationUrl: "invite"
//        )
//        repo.store = [mediator]
//
//        agent.connectionRepository = MockConnectionRepository(agent: agent, stubConnection: ConnectionRecordTestFactory.readyConnection(id: "conn-1"))
//
//        let sut = TestableMediationRecipient(agent: agent, dispatcher: MockDispatcher(), repository: repo)
//
//        let conn = ConnectionRecordTestFactory.readyConnection(id: "conn-1")
//
//        try await sut.requestMediationIfNecessry(connection: conn)
//
//        XCTAssertTrue(sut.initiatePickupCalled)
//        // se tu tiver como verificar agent.setInitialized(), valida aqui
//    }
//    
//    func test_processMediationGrant_updatesRecordToGranted_finishesWaiter_andStartsPickup() async throws {
//        let delegate = SpyAgentDelegate()
//        let agent = Agent(agentConfig: .test(), agentDelegate: delegate)
//
//        let repo = MockMediationRepository(agent: agent)
//        let conn = ConnectionRecordTestFactory.readyConnection(id: "conn-1")
//
//        var rec = MediationRecord(
//            state: .Requested,
//            role: .Mediator,
//            connectionId: conn.id,
//            threadId: conn.id,
//            invitationUrl: "invite"
//        )
//        repo.store = [rec]
//
//        let sut = TestableMediationRecipient(agent: agent, dispatcher: MockDispatcher(), repository: repo)
//
//        let grant = MediationGrantMessage(
//            endpoint: "https://mediator-endpoint",
//            routingKeys: ["did:key:z6Mk..."] // se tu não quer depender do DIDParser, usa verkey puro
//        )
//
//        let ctx = try InboundMessageContextTestFactory.make(
//            plaintextMessage: grant.toJsonString(),
//            connection: conn
//        )
//
//        try await sut.processMediationGrant(messageContext: ctx)
//
//        XCTAssertTrue(repo.updateCalled)
//        XCTAssertTrue(delegate.onMediationStateChangedCalled)
//        XCTAssertTrue(sut.initiatePickupCalled)
//
//        let updated = repo.store.first!
//        XCTAssertEqual(updated.state, .Granted)
//        XCTAssertEqual(updated.endpoint, "https://mediator-endpoint")
//    }
//    
//    func test_pickupMessages_whenPickupV1_sendsBatchPickup() async throws {
//        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
//        agent.agentConfig.mediatorPickupStrategy = .PickUpV1
//
//        let sender = MockMessageSender()
//        agent.messageSender = sender
//
//        let sut = MediationRecipient(agent: agent, dispatcher: MockDispatcher(), repository: MockMediationRepository(agent: agent))
//        let conn = ConnectionRecordTestFactory.readyConnection()
//
//        try await sut.pickupMessages(mediatorConnection: conn)
//
//        XCTAssertTrue(sender.sendCalled)
//        // valida payload tipo BatchPickupMessage se conseguir cast:
//        let payload = sender.sent.last?.payload
//        XCTAssertTrue(payload is BatchPickupMessage)
//    }
//    
//    func test_pickupMessages_whenImplicit_sendsTrustPingWithWsPrefix() async throws {
//        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
//        agent.agentConfig.mediatorPickupStrategy = .Implicit
//
//        let sender = MockMessageSender()
//        agent.messageSender = sender
//
//        let sut = MediationRecipient(agent: agent, dispatcher: MockDispatcher(), repository: MockMediationRepository(agent: agent))
//        let conn = ConnectionRecordTestFactory.readyConnection()
//
//        try await sut.pickupMessages(mediatorConnection: conn)
//
//        XCTAssertTrue(sender.sendCalled)
//        XCTAssertEqual(sender.lastEndpointPrefix, "ws")
//        XCTAssertTrue(sender.sent.last?.payload is TrustPingMessage)
//    }
//    
//    func test_init_registersAllHandlers() {
//        let agent = Agent(agentConfig: .test(), agentDelegate: nil)
//        let dispatcher = MockDispatcher()
//
//        _ = MediationRecipient(agent: agent, dispatcher: dispatcher)
//
//        XCTAssertEqual(dispatcher.handlers.count, 4)
//    }
//}
